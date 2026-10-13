package com.eysenck.khao_sat_v1;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
class KhaoSatV1ApplicationTests {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    void contextLoads() {
        assertNotNull(jdbcTemplate, "JdbcTemplate should be loaded");

        // Kiểm tra xem Flyway đã tạo các bảng chưa
        List<Map<String, Object>> tables = jdbcTemplate.queryForList(
                "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'"
        );
        System.out.println("=== PUBLIC TABLES IN EYSENCK_DB ===");
        tables.forEach(row -> System.out.println("Table: " + row.get("table_name")));

        // Kiểm tra số lượng câu hỏi đã seed
        Integer questionCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM survey_question", Integer.class
        );
        System.out.println("=== QUESTION COUNT IN EYSENCK_DB: " + questionCount + " ===");
        assertEquals(57, questionCount, "Database must contain exactly 57 questions");
    }
}
