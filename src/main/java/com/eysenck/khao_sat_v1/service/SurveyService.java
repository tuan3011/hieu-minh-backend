package com.eysenck.khao_sat_v1.service;

import com.eysenck.khao_sat_v1.dto.*;
import com.eysenck.khao_sat_v1.entity.*;
import com.eysenck.khao_sat_v1.entity.enums.AttemptStatus;
import com.eysenck.khao_sat_v1.entity.enums.Temperament;
import com.eysenck.khao_sat_v1.entity.enums.VersionStatus;
import com.eysenck.khao_sat_v1.exception.*;
import com.eysenck.khao_sat_v1.repository.*;
import com.eysenck.khao_sat_v1.util.TokenGenerator;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class SurveyService {

    private final SurveyVersionRepository surveyVersionRepository;
    private final SurveyQuestionRepository surveyQuestionRepository;
    private final SurveyAttemptRepository surveyAttemptRepository;
    private final SurveyResponseRepository surveyResponseRepository;
    private final SurveyResultRepository surveyResultRepository;

    /**
     * Bắt đầu một lượt khảo sát ẩn danh mới.
     * Sinh token 32 bytes ngẫu nhiên, lưu SHA-256 hash vào DB và trả token thô cho client.
     */
    @Transactional
    public StartSurveyResponseDto startSurvey() {
        SurveyVersion publishedVersion = surveyVersionRepository.findByStatus(VersionStatus.PUBLISHED)
                .orElseThrow(() -> new ResourceNotFoundException("No published survey version found"));

        String rawToken = TokenGenerator.generateRawToken();
        String tokenHash = TokenGenerator.hashToken(rawToken);

        SurveyAttempt attempt = new SurveyAttempt(publishedVersion, tokenHash);
        attempt = surveyAttemptRepository.save(attempt);

        List<SurveyQuestion> questions = surveyQuestionRepository.findBySurveyVersionIdOrderByQuestionNoAsc(publishedVersion.getId());
        List<QuestionDto> questionDtos = questions.stream()
                .map(q -> new QuestionDto(q.getId(), q.getQuestionNo(), q.getContent(), q.getSectionCode()))
                .toList();

        return new StartSurveyResponseDto(
                attempt.getId(),
                rawToken,
                publishedVersion.getVersionCode(),
                attempt.getExpiresAt(),
                questionDtos
        );
    }

    /**
     * Khôi phục phiên làm bài bằng token thô được lưu ở trình duyệt.
     */
    @Transactional(readOnly = true)
    public SurveyResumeResponseDto resumeSurvey(String rawToken) {
        String tokenHash = TokenGenerator.hashToken(rawToken);
        SurveyAttempt attempt = surveyAttemptRepository.findByTokenHash(tokenHash)
                .orElseThrow(() -> new ResourceNotFoundException("Invalid or non-existent survey token"));

        if (!attempt.isCompleted() && attempt.isExpired()) {
            throw new AttemptExpiredException("Survey attempt has expired after 30 days");
        }

        List<SurveyQuestion> questions = surveyQuestionRepository.findBySurveyVersionIdOrderByQuestionNoAsc(attempt.getSurveyVersion().getId());
        List<QuestionDto> questionDtos = questions.stream()
                .map(q -> new QuestionDto(q.getId(), q.getQuestionNo(), q.getContent(), q.getSectionCode()))
                .toList();

        List<SurveyResponse> responses = surveyResponseRepository.findByIdAttemptId(attempt.getId());
        Map<UUID, Boolean> answers = responses.stream()
                .collect(Collectors.toMap(r -> r.getId().getQuestionId(), SurveyResponse::isAnswerYes));

        return new SurveyResumeResponseDto(
                attempt.getId(),
                attempt.getStatus(),
                attempt.getExpiresAt(),
                attempt.getCompletedAt(),
                responses.size(),
                answers,
                questionDtos
        );
    }

    /**
     * Lưu hoặc cập nhật câu trả lời cho một câu hỏi.
     * Chặn nếu attempt đã hoàn thành hoặc hết hạn.
     */
    @Transactional
    public void saveAnswer(String rawToken, UUID questionId, boolean answerYes) {
        String tokenHash = TokenGenerator.hashToken(rawToken);
        SurveyAttempt attempt = surveyAttemptRepository.findByTokenHash(tokenHash)
                .orElseThrow(() -> new ResourceNotFoundException("Invalid or non-existent survey token"));

        if (attempt.isCompleted()) {
            throw new AttemptCompletedException("Cannot modify answers for a completed survey attempt");
        }

        if (attempt.isExpired()) {
            throw new AttemptExpiredException("Survey attempt has expired");
        }

        UUID versionId = attempt.getSurveyVersion().getId();
        boolean questionBelongsToVersion = surveyQuestionRepository.findByIdAndSurveyVersionId(questionId, versionId).isPresent();
        if (!questionBelongsToVersion) {
            throw new InvalidQuestionException("Question does not belong to the survey version of this attempt");
        }

        Optional<SurveyResponse> existingResponse = surveyResponseRepository.findByIdAttemptIdAndIdQuestionId(attempt.getId(), questionId);
        if (existingResponse.isPresent()) {
            SurveyResponse response = existingResponse.get();
            response.setAnswerYes(answerYes);
            response.setAnsweredAt(OffsetDateTime.now());
        } else {
            SurveyResponse newResponse = new SurveyResponse(attempt.getId(), questionId, versionId, answerYes);
            surveyResponseRepository.save(newResponse);
        }

        attempt.touch();
        surveyAttemptRepository.save(attempt);
    }

    /**
     * Hoàn tất bài khảo sát, chấm điểm nguyên tử và lưu kết quả.
     * Sử dụng Pessimistic Lock trên dòng attempt để ngăn chặn race condition khi gọi hoàn tất đồng thời.
     */
    @Transactional
    public SurveyResultResponseDto completeSurvey(String rawToken) {
        String tokenHash = TokenGenerator.hashToken(rawToken);
        SurveyAttempt initialAttempt = surveyAttemptRepository.findByTokenHash(tokenHash)
                .orElseThrow(() -> new ResourceNotFoundException("Invalid or non-existent survey token"));

        // Khóa dòng attempt bằng PESSIMISTIC_WRITE (SELECT ... FOR UPDATE)
        SurveyAttempt attempt = surveyAttemptRepository.findByIdWithLock(initialAttempt.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Survey attempt not found"));

        if (attempt.isCompleted()) {
            throw new AttemptCompletedException("Survey attempt has already been completed");
        }

        if (attempt.isExpired()) {
            throw new AttemptExpiredException("Survey attempt has expired");
        }

        // Bắt buộc phải trả lời đủ 57 câu
        long answeredCount = surveyResponseRepository.countByIdAttemptId(attempt.getId());
        if (answeredCount != 57) {
            throw new IncompleteSurveyException("All 57 questions must be answered before completing. Current answered: " + answeredCount + "/57");
        }

        // Tải toàn bộ câu trả lời và câu hỏi để chấm điểm
        List<SurveyResponse> responses = surveyResponseRepository.findByIdAttemptId(attempt.getId());
        List<SurveyQuestion> questions = surveyQuestionRepository.findBySurveyVersionIdOrderByQuestionNoAsc(attempt.getSurveyVersion().getId());

        Map<UUID, SurveyQuestion> questionMap = questions.stream()
                .collect(Collectors.toMap(SurveyQuestion::getId, q -> q));

        short scoreA = 0;
        short scoreB = 0;
        short scoreC = 0;

        for (SurveyResponse response : responses) {
            SurveyQuestion question = questionMap.get(response.getId().getQuestionId());
            if (question != null && response.isAnswerYes() == question.isPointAnswer()) {
                switch (question.getSectionCode()) {
                    case "A" -> scoreA++;
                    case "B" -> scoreB++;
                    case "C" -> scoreC++;
                }
            }
        }

        // Xác định khí chất theo ma trận Eysenck đã chốt
        Temperament temperament;
        if (scoreA <= 12 && scoreB <= 12) {
            temperament = Temperament.PHLEGMATIC;
        } else if (scoreA <= 12 && scoreB > 12) {
            temperament = Temperament.MELANCHOLIC;
        } else if (scoreA > 12 && scoreB <= 12) {
            temperament = Temperament.SANGUINE;
        } else {
            temperament = Temperament.CHOLERIC;
        }

        // Lưu kết quả bài làm (reliabilityStatus để null chờ nghiệp vụ xác nhận)
        SurveyResult result = new SurveyResult(attempt, scoreA, scoreB, scoreC, temperament, null);
        result = surveyResultRepository.save(result);

        // Đánh dấu attempt là COMPLETED
        attempt.markCompleted();
        surveyAttemptRepository.save(attempt);

        return mapToResultDto(result);
    }

    /**
     * Lấy kết quả bài làm cho một attempt đã hoàn thành.
     */
    @Transactional(readOnly = true)
    public SurveyResultResponseDto getResult(String rawToken) {
        String tokenHash = TokenGenerator.hashToken(rawToken);
        SurveyAttempt attempt = surveyAttemptRepository.findByTokenHash(tokenHash)
                .orElseThrow(() -> new ResourceNotFoundException("Invalid or non-existent survey token"));

        if (!attempt.isCompleted()) {
            throw new IncompleteSurveyException("Survey attempt has not been completed yet");
        }

        SurveyResult result = surveyResultRepository.findByAttemptId(attempt.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Result not found for this completed attempt"));

        return mapToResultDto(result);
    }

    private SurveyResultResponseDto mapToResultDto(SurveyResult result) {
        String nameVi = switch (result.getTemperament()) {
            case PHLEGMATIC -> "Khí chất Bình thản (Phlegmatic)";
            case MELANCHOLIC -> "Khí chất Ưu tư (Melancholic)";
            case SANGUINE -> "Khí chất Hoạt bát (Sanguine)";
            case CHOLERIC -> "Khí chất Nóng nảy (Choleric)";
        };

        String description = switch (result.getTemperament()) {
            case PHLEGMATIC -> "Người hướng nội, thần kinh ổn định. Điềm tĩnh, kiên định, đáng tin cậy và có khả năng tự chủ cao.";
            case MELANCHOLIC -> "Người hướng nội, thần kinh không ổn định. Nhạy cảm, sâu sắc, chu đáo nhưng dễ lo âu và dao động tâm trạng.";
            case SANGUINE -> "Người hướng ngoại, thần kinh ổn định. Vui vẻ, hoạt bát, dễ thích nghi, cởi mở và lạc quan trong cuộc sống.";
            case CHOLERIC -> "Người hướng ngoại, thần kinh không ổn định. Năng nổ, nhiệt tình, quyết đoán nhưng dễ bốc đồng và nóng nảy.";
        };

        return new SurveyResultResponseDto(
                result.getAttemptId(),
                result.getScoreA(),
                result.getScoreB(),
                result.getScoreC(),
                result.getTemperament(),
                nameVi,
                description,
                result.getReliabilityStatus(),
                result.getCalculatedAt()
        );
    }
}
