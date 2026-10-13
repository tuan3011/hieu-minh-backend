package com.eysenck.khao_sat_v1.dto;

import com.eysenck.khao_sat_v1.entity.enums.Temperament;

import java.time.OffsetDateTime;
import java.util.UUID;

public record SurveyResultResponseDto(
        UUID attemptId,
        short scoreA,
        short scoreB,
        short scoreC,
        Temperament temperament,
        String temperamentNameVi,
        String temperamentDescription,
        String reliabilityStatus,
        OffsetDateTime calculatedAt
) {
}
