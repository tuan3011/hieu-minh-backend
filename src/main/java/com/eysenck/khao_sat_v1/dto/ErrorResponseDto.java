package com.eysenck.khao_sat_v1.dto;

import java.time.OffsetDateTime;
import java.util.Map;

public record ErrorResponseDto(
        OffsetDateTime timestamp,
        int status,
        String error,
        String message,
        String path,
        Map<String, String> validationErrors
) {
    public ErrorResponseDto(int status, String error, String message, String path) {
        this(OffsetDateTime.now(), status, error, message, path, null);
    }

    public ErrorResponseDto(int status, String error, String message, String path, Map<String, String> validationErrors) {
        this(OffsetDateTime.now(), status, error, message, path, validationErrors);
    }
}
