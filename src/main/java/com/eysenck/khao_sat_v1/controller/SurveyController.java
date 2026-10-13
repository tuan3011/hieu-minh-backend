package com.eysenck.khao_sat_v1.controller;

import com.eysenck.khao_sat_v1.dto.*;
import com.eysenck.khao_sat_v1.service.SurveyService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/surveys")
@RequiredArgsConstructor
public class SurveyController {

    private final SurveyService surveyService;

    /**
     * Bắt đầu một lượt làm bài khảo sát mới.
     * POST /api/surveys/start
     */
    @PostMapping("/start")
    public ResponseEntity<StartSurveyResponseDto> startSurvey() {
        StartSurveyResponseDto response = surveyService.startSurvey();
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    /**
     * Khôi phục phiên làm bài hiện tại bằng token lưu ở client.
     * GET /api/surveys/resume
     */
    @GetMapping("/resume")
    public ResponseEntity<SurveyResumeResponseDto> resumeSurvey(
            @RequestHeader(name = "X-Survey-Token", required = false) String headerToken,
            @RequestParam(name = "token", required = false) String paramToken
    ) {
        String token = resolveToken(headerToken, paramToken);
        SurveyResumeResponseDto response = surveyService.resumeSurvey(token);
        return ResponseEntity.ok(response);
    }

    /**
     * Lưu câu trả lời cho một câu hỏi cụ thể.
     * POST /api/surveys/answers
     */
    @PostMapping("/answers")
    public ResponseEntity<Void> saveAnswer(
            @RequestHeader(name = "X-Survey-Token", required = false) String headerToken,
            @RequestParam(name = "token", required = false) String paramToken,
            @Valid @RequestBody SaveAnswerRequestDto request
    ) {
        String token = resolveToken(headerToken, paramToken);
        surveyService.saveAnswer(token, request.questionId(), request.answerYes());
        return ResponseEntity.ok().build();
    }

    /**
     * Nộp bài và tính điểm kết quả cuối cùng.
     * POST /api/surveys/complete
     */
    @PostMapping("/complete")
    public ResponseEntity<SurveyResultResponseDto> completeSurvey(
            @RequestHeader(name = "X-Survey-Token", required = false) String headerToken,
            @RequestParam(name = "token", required = false) String paramToken
    ) {
        String token = resolveToken(headerToken, paramToken);
        SurveyResultResponseDto result = surveyService.completeSurvey(token);
        return ResponseEntity.ok(result);
    }

    /**
     * Xem kết quả bài khảo sát đã hoàn thành.
     * GET /api/surveys/result
     */
    @GetMapping("/result")
    public ResponseEntity<SurveyResultResponseDto> getResult(
            @RequestHeader(name = "X-Survey-Token", required = false) String headerToken,
            @RequestParam(name = "token", required = false) String paramToken
    ) {
        String token = resolveToken(headerToken, paramToken);
        SurveyResultResponseDto result = surveyService.getResult(token);
        return ResponseEntity.ok(result);
    }

    private String resolveToken(String headerToken, String paramToken) {
        if (headerToken != null && !headerToken.isBlank()) {
            return headerToken.trim();
        }
        if (paramToken != null && !paramToken.isBlank()) {
            return paramToken.trim();
        }
        throw new IllegalArgumentException("Survey token is required (provide in X-Survey-Token header or token query parameter)");
    }
}
