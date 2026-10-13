package com.eysenck.khao_sat_v1.repository;

import com.eysenck.khao_sat_v1.entity.AdminAccount;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface AdminAccountRepository extends JpaRepository<AdminAccount, UUID> {

    Optional<AdminAccount> findByUsername(String username);

    boolean existsByUsername(String username);
}
