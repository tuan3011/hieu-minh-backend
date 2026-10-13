package com.eysenck.khao_sat_v1;

import com.eysenck.khao_sat_v1.dto.QuestionDto;
import com.eysenck.khao_sat_v1.dto.SaveAnswerRequestDto;
import com.eysenck.khao_sat_v1.dto.StartSurveyResponseDto;
import com.eysenck.khao_sat_v1.dto.SurveyResultResponseDto;
import com.eysenck.khao_sat_v1.dto.SurveyResumeResponseDto;
import com.eysenck.khao_sat_v1.entity.SurveyAttempt;
import com.eysenck.khao_sat_v1.entity.enums.AttemptStatus;
import com.eysenck.khao_sat_v1.repository.SurveyAttemptRepository;
import com.eysenck.khao_sat_v1.service.SurveyService;
import com.eysenck.khao_sat_v1.util.TokenGenerator;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
class SurveyIntegrationTests {

    @Autowired
    private SurveyService surveyService;

    @Autowired
    private SurveyAttemptRepository surveyAttemptRepository;

    @Test
    @DisplayName("Quy trình hoàn chỉnh: Tạo bài -> Lưu đáp án -> Khôi phục -> Nộp bài -> Tính điểm")
    void testFullSurveyWorkflow() {
        // 1. Khởi tạo khảo sát mới
        StartSurveyResponseDto startResponse = surveyService.startSurvey();
        assertNotNull(startResponse.attemptId());
        assertNotNull(startResponse.token());
        assertEquals("EYSENCK_57_V1", startResponse.versionCode());
        assertEquals(57, startResponse.questions().size());

        // Kiểm tra bảo mật: DB chỉ lưu hash, không lưu token thô
        String expectedHash = TokenGenerator.hashToken(startResponse.token());
        Optional<SurveyAttempt> savedAttemptOpt = surveyAttemptRepository.findByTokenHash(expectedHash);
        assertTrue(savedAttemptOpt.isPresent());
        assertEquals(AttemptStatus.IN_PROGRESS, savedAttemptOpt.get().getStatus());

        List<QuestionDto> questions = startResponse.questions();

        // 2. Thử lưu câu trả lời cho câu số 1
        QuestionDto q1 = questions.get(0);
        surveyService.saveAnswer(startResponse.token(), q1.id(), true);

        // 3. Khôi phục phiên làm bài
        SurveyResumeResponseDto resumeResponse = surveyService.resumeSurvey(startResponse.token());
        assertEquals(1, resumeResponse.answeredCount());
        assertTrue(resumeResponse.answers().containsKey(q1.id()));
        assertTrue(resumeResponse.answers().get(q1.id()));

        // 4. Cố tình nộp bài khi mới làm 1 câu -> Phải văng ngoại lệ IncompleteSurveyException
        assertThrows(RuntimeException.class, () -> surveyService.completeSurvey(startResponse.token()));

        // 5. Trả lời toàn bộ 57 câu hỏi (đáp án YES cho tất cả)
        for (QuestionDto q : questions) {
            surveyService.saveAnswer(startResponse.token(), q.id(), true);
        }

        // Kiểm tra đã lưu đủ 57 câu
        SurveyResumeResponseDto fullResume = surveyService.resumeSurvey(startResponse.token());
        assertEquals(57, fullResume.answeredCount());

        // 6. Nộp bài thành công
        SurveyResultResponseDto result = surveyService.completeSurvey(startResponse.token());
        assertNotNull(result);
        assertEquals(startResponse.attemptId(), result.attemptId());

        // Khi toàn bộ 57 câu đều chọn "Có" (YES):
        // Thang A có 15 câu chọn Có được điểm -> scoreA = 15 (> 12)
        // Thang B có 24 câu chọn Có được điểm -> scoreB = 24 (> 12)
        // Thang C có 3 câu chọn Có được điểm -> scoreC = 3
        // scoreA > 12 VÀ scoreB > 12 => Khí chất CHOLERIC (Nóng nảy)
        assertEquals(15, result.scoreA());
        assertEquals(24, result.scoreB());
        assertEquals(3, result.scoreC());
        assertEquals("CHOLERIC", result.temperament().name());

        // 7. Cố tình sửa câu trả lời sau khi nộp -> Phải bị chặn (AttemptCompletedException / Trigger)
        assertThrows(RuntimeException.class, () ->
                surveyService.saveAnswer(startResponse.token(), q1.id(), false)
        );

        // 8. Cố tình nộp bài lần 2 -> Phải bị chặn
        assertThrows(RuntimeException.class, () ->
                surveyService.completeSurvey(startResponse.token())
        );

        // 9. Lấy lại kết quả sau khi đã nộp
        SurveyResultResponseDto fetchedResult = surveyService.getResult(startResponse.token());
        assertEquals(result.temperament(), fetchedResult.temperament());
        assertEquals(15, fetchedResult.scoreA());
        assertEquals(24, fetchedResult.scoreB());
    }
}
