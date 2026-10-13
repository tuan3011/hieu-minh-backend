package com.eysenck.khao_sat_v1.dto;

import com.eysenck.khao_sat_v1.entity.enums.AttemptStatus;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;

public record SurveyResumeResponseDto(
        UUID attemptId,
        AttemptStatus status,
        OffsetDateTime expiresAt,
        OffsetDateTime completedAt,
        int answeredCount,
        Map<UUID, Boolean> answers,
        List<QuestionDto> questions
) {
}
