package com.eysenck.khao_sat_v1;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class SurveyControllerTests {

    @Autowired
    private MockMvc mockMvc;

    @Test
    @DisplayName("REST API: Khởi tạo bài khảo sát trả về 201 Created và 57 câu hỏi")
    void testStartSurveyApi() throws Exception {
        mockMvc.perform(post("/api/surveys/start"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.attemptId").isNotEmpty())
                .andExpect(jsonPath("$.token").isNotEmpty())
                .andExpect(jsonPath("$.versionCode").value("EYSENCK_57_V1"))
                .andExpect(jsonPath("$.questions.length()").value(57))
                .andExpect(jsonPath("$.questions[0].pointAnswer").doesNotExist()); // Bảo mật: không lộ đáp án được điểm
    }

    @Test
    @DisplayName("REST API: Truy vấn resume với token không hợp lệ trả về 404 Not Found")
    void testResumeWithInvalidToken() throws Exception {
        mockMvc.perform(get("/api/surveys/resume")
                        .header("X-Survey-Token", "invalid_fake_token_123456789"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.status").value(404))
                .andExpect(jsonPath("$.message").value("Invalid or non-existent survey token"));
    }

    @Test
    @DisplayName("REST API: Lưu đáp án thiếu body trả về 400 Bad Request kèm chi tiết lỗi validation")
    void testSaveAnswerValidationFailure() throws Exception {
        mockMvc.perform(post("/api/surveys/answers")
                        .header("X-Survey-Token", "dummy_token")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value(400))
                .andExpect(jsonPath("$.validationErrors").isMap());
    }
}
