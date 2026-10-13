package com.eysenck.khao_sat_v1.entity;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.springframework.data.domain.Persistable;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "survey_response")
@Getter
@Setter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class SurveyResponse implements Persistable<SurveyResponseId> {

    @EmbeddedId
    private SurveyResponseId id;

    @Column(name = "survey_version_id", nullable = false, updatable = false)
    private UUID surveyVersionId;

    @Column(name = "answer_yes", nullable = false)
    private boolean answerYes;

    @Column(name = "answered_at", nullable = false)
    private OffsetDateTime answeredAt;

    @Transient
    private boolean isNewRecord = true;

    public SurveyResponse(UUID attemptId, UUID questionId, UUID surveyVersionId, boolean answerYes) {
        this.id = new SurveyResponseId(attemptId, questionId);
        this.surveyVersionId = surveyVersionId;
        this.answerYes = answerYes;
        this.answeredAt = OffsetDateTime.now();
        this.isNewRecord = true;
    }

    @Override
    public SurveyResponseId getId() {
        return this.id;
    }

    @Override
    public boolean isNew() {
        return this.isNewRecord;
    }

    @PostPersist
    @PostLoad
    protected void markNotNew() {
        this.isNewRecord = false;
    }
}
