package com.eysenck.khao_sat_v1.exception;

public class AttemptExpiredException extends RuntimeException {
    public AttemptExpiredException(String message) {
        super(message);
    }
}
