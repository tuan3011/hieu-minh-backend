package com.eysenck.khao_sat_v1.repository;

import com.eysenck.khao_sat_v1.entity.SurveyAttempt;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface SurveyAttemptRepository extends JpaRepository<SurveyAttempt, UUID> {

    Optional<SurveyAttempt> findByTokenHash(String tokenHash);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT a FROM SurveyAttempt a WHERE a.id = :id")
    Optional<SurveyAttempt> findByIdWithLock(@Param("id") UUID id);
}
