package com.eysenck.khao_sat_v1.dto;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

public record StartSurveyResponseDto(
        UUID attemptId,
        String token,
        String versionCode,
        OffsetDateTime expiresAt,
        List<QuestionDto> questions
) {
}
