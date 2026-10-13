package com.eysenck.khao_sat_v1.repository;

import com.eysenck.khao_sat_v1.entity.SurveyResponse;
import com.eysenck.khao_sat_v1.entity.SurveyResponseId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface SurveyResponseRepository extends JpaRepository<SurveyResponse, SurveyResponseId> {

    List<SurveyResponse> findByIdAttemptId(UUID attemptId);

    Optional<SurveyResponse> findByIdAttemptIdAndIdQuestionId(UUID attemptId, UUID questionId);

    long countByIdAttemptId(UUID attemptId);
}
