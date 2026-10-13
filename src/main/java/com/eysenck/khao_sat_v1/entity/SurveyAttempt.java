package com.eysenck.khao_sat_v1.entity;

import com.eysenck.khao_sat_v1.entity.enums.AttemptStatus;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "survey_attempt")
@Getter
@Setter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class SurveyAttempt {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "survey_version_id", nullable = false, updatable = false)
    private SurveyVersion surveyVersion;

    @Column(name = "token_hash", length = 64, nullable = false, unique = true, updatable = false)
    private String tokenHash;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", length = 20, nullable = false)
    private AttemptStatus status;

    @Column(name = "started_at", nullable = false, updatable = false)
    private OffsetDateTime startedAt;

    @Column(name = "last_activity_at", nullable = false)
    private OffsetDateTime lastActivityAt;

    @Column(name = "expires_at", nullable = false, updatable = false)
    private OffsetDateTime expiresAt;

    @Column(name = "completed_at")
    private OffsetDateTime completedAt;

    public SurveyAttempt(SurveyVersion surveyVersion, String tokenHash) {
        this.surveyVersion = surveyVersion;
        this.tokenHash = tokenHash;
        this.status = AttemptStatus.IN_PROGRESS;
        this.startedAt = OffsetDateTime.now();
        this.lastActivityAt = this.startedAt;
        this.expiresAt = this.startedAt.plusDays(30);
    }

    public boolean isExpired() {
        return OffsetDateTime.now().isAfter(this.expiresAt);
    }

    public boolean isCompleted() {
        return this.status == AttemptStatus.COMPLETED;
    }

    public void markCompleted() {
        this.status = AttemptStatus.COMPLETED;
        this.completedAt = OffsetDateTime.now();
        this.lastActivityAt = this.completedAt;
    }

    public void touch() {
        this.lastActivityAt = OffsetDateTime.now();
    }
}
