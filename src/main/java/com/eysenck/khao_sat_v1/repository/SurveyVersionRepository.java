package com.eysenck.khao_sat_v1.repository;

import com.eysenck.khao_sat_v1.entity.SurveyVersion;
import com.eysenck.khao_sat_v1.entity.enums.VersionStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface SurveyVersionRepository extends JpaRepository<SurveyVersion, UUID> {

    Optional<SurveyVersion> findByStatus(VersionStatus status);

    Optional<SurveyVersion> findByVersionCode(String versionCode);
}
