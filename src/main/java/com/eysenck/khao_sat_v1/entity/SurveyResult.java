package com.eysenck.khao_sat_v1.entity;

import com.eysenck.khao_sat_v1.entity.enums.Temperament;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.springframework.data.domain.Persistable;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "survey_result")
@Getter
@Setter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class SurveyResult implements Persistable<UUID> {

    @Id
    @Column(name = "attempt_id", nullable = false)
    private UUID attemptId;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @MapsId
    @JoinColumn(name = "attempt_id")
    private SurveyAttempt attempt;

    @Column(name = "score_a", nullable = false)
    private short scoreA;

    @Column(name = "score_b", nullable = false)
    private short scoreB;

    @Column(name = "score_c", nullable = false)
    private short scoreC;

    @Enumerated(EnumType.STRING)
    @Column(name = "temperament", length = 20, nullable = false)
    private Temperament temperament;

    @Column(name = "reliability_status", length = 50)
    private String reliabilityStatus;

    @Column(name = "calculated_at", nullable = false, updatable = false)
    private OffsetDateTime calculatedAt;

    @Transient
    private boolean isNewRecord = true;

    public SurveyResult(SurveyAttempt attempt, short scoreA, short scoreB, short scoreC, Temperament temperament, String reliabilityStatus) {
        this.attempt = attempt;
        this.attemptId = attempt.getId();
        this.scoreA = scoreA;
        this.scoreB = scoreB;
        this.scoreC = scoreC;
        this.temperament = temperament;
        this.reliabilityStatus = reliabilityStatus;
        this.calculatedAt = OffsetDateTime.now();
        this.isNewRecord = true;
    }

    @Override
    public UUID getId() {
        return this.attemptId;
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
