package com.eysenck.khao_sat_v1.repository;

import com.eysenck.khao_sat_v1.entity.SurveyQuestion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface SurveyQuestionRepository extends JpaRepository<SurveyQuestion, UUID> {

    List<SurveyQuestion> findBySurveyVersionIdOrderByQuestionNoAsc(UUID surveyVersionId);

    Optional<SurveyQuestion> findBySurveyVersionIdAndQuestionNo(UUID surveyVersionId, short questionNo);

    Optional<SurveyQuestion> findByIdAndSurveyVersionId(UUID questionId, UUID surveyVersionId);

    long countBySurveyVersionId(UUID surveyVersionId);
}
