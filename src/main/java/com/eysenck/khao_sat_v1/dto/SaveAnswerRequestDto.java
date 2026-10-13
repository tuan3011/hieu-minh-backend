package com.eysenck.khao_sat_v1.dto;

import jakarta.validation.constraints.NotNull;
import java.util.UUID;

public record SaveAnswerRequestDto(
        @NotNull(message = "questionId cannot be null")
        UUID questionId,

        @NotNull(message = "answerYes cannot be null")
        Boolean answerYes
) {
}
