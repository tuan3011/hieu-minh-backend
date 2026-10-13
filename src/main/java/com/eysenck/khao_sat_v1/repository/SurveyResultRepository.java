package com.eysenck.khao_sat_v1.repository;

import com.eysenck.khao_sat_v1.entity.SurveyResult;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface SurveyResultRepository extends JpaRepository<SurveyResult, UUID> {

    Optional<SurveyResult> findByAttemptId(UUID attemptId);
}
