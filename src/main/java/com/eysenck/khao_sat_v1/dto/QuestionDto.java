package com.eysenck.khao_sat_v1.dto;

import java.util.UUID;

public record QuestionDto(
        UUID id,
        short questionNo,
        String content,
        String sectionCode
) {
}
