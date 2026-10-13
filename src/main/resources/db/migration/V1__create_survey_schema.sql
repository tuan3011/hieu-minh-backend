-- =====================================================================
-- Migration: V1__create_survey_schema.sql
-- Description: Core Schema for Eysenck Personality Questionnaire System
-- Engine: PostgreSQL 17
-- =====================================================================

-- Kích hoạt extension pgcrypto để sinh UUID v4 ngẫu nhiên nếu cần
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ---------------------------------------------------------------------
-- 1. BẢNG: survey_version
-- Quản lý phiên bản và vòng đời của bảng khảo sát
-- ---------------------------------------------------------------------
CREATE TABLE survey_version (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version_code VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    published_at TIMESTAMPTZ,
    archived_at TIMESTAMPTZ,

    -- Ràng buộc giá trị hợp lệ cho status
    CONSTRAINT chk_survey_version_status 
        CHECK (status IN ('DRAFT', 'PUBLISHED', 'ARCHIVED')),

    -- Ràng buộc toàn vẹn thời gian xuất bản / lưu trữ
    CONSTRAINT chk_survey_version_lifecycle_timestamps
        CHECK (
            (status = 'DRAFT' AND published_at IS NULL AND archived_at IS NULL) OR
            (status = 'PUBLISHED' AND published_at IS NOT NULL AND archived_at IS NULL) OR
            (status = 'ARCHIVED' AND published_at IS NOT NULL AND archived_at IS NOT NULL)
        ),

    -- Unique tự nhiên theo version_code
    CONSTRAINT uq_survey_version_code 
        UNIQUE (version_code)
);

-- Partial Unique Index: Chỉ có duy nhất 1 phiên bản ở trạng thái PUBLISHED tại một thời điểm
CREATE UNIQUE INDEX uq_idx_single_published_version 
    ON survey_version (status) 
    WHERE status = 'PUBLISHED';

-- ---------------------------------------------------------------------
-- 2. BẢNG: survey_question
-- Nội dung 57 câu hỏi và quy tắc tính điểm (thang đo + đáp án được điểm)
-- ---------------------------------------------------------------------
CREATE TABLE survey_question (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    survey_version_id UUID NOT NULL,
    question_no SMALLINT NOT NULL,
    content TEXT NOT NULL,
    section_code CHAR(1) NOT NULL,
    point_answer BOOLEAN NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- FK cơ bản trỏ về survey_version
    CONSTRAINT fk_survey_question_version 
        FOREIGN KEY (survey_version_id) 
        REFERENCES survey_version (id) 
        ON DELETE RESTRICT,

    -- Số thứ tự câu hỏi bắt buộc từ 1 đến 57
    CONSTRAINT chk_survey_question_no_range 
        CHECK (question_no BETWEEN 1 AND 57),

    -- Thang đo bắt buộc thuộc 3 nhóm A, B, C
    CONSTRAINT chk_survey_question_section 
        CHECK (section_code IN ('A', 'B', 'C')),

    -- Trong một version, số thứ tự câu hỏi không được trùng lặp
    -- Constraint này tự động sinh B-Tree index trên (survey_version_id, question_no)
    CONSTRAINT uq_survey_question_version_no 
        UNIQUE (survey_version_id, question_no),

    -- Composite Unique Key phục vụ Composite FK ở bảng survey_response
    CONSTRAINT uq_survey_question_id_version 
        UNIQUE (id, survey_version_id)
);

-- ---------------------------------------------------------------------
-- 3. BẢNG: survey_attempt
-- Quản lý phiên làm bài của người dùng ẩn danh
-- ---------------------------------------------------------------------
CREATE TABLE survey_attempt (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    survey_version_id UUID NOT NULL,
    token_hash VARCHAR(64) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'IN_PROGRESS',
    started_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_activity_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMPTZ NOT NULL,
    completed_at TIMESTAMPTZ,

    -- FK trỏ về survey_version
    CONSTRAINT fk_survey_attempt_version 
        FOREIGN KEY (survey_version_id) 
        REFERENCES survey_version (id) 
        ON DELETE RESTRICT,

    -- Trạng thái attempt chỉ lưu 2 trạng thái thực tế: IN_PROGRESS hoặc COMPLETED
    CONSTRAINT chk_survey_attempt_status 
        CHECK (status IN ('IN_PROGRESS', 'COMPLETED')),

    -- Tính nhất quán giữa status và completed_at
    CONSTRAINT chk_survey_attempt_completion_state 
        CHECK (
            (status = 'IN_PROGRESS' AND completed_at IS NULL) OR
            (status = 'COMPLETED' AND completed_at IS NOT NULL)
        ),

    -- Thời hạn phải luôn lớn hơn thời điểm bắt đầu
    CONSTRAINT chk_survey_attempt_expires_valid 
        CHECK (expires_at > started_at),

    -- Token hash (SHA-256) phải duy nhất để khôi phục phiên
    CONSTRAINT uq_survey_attempt_token_hash 
        UNIQUE (token_hash),

    -- Composite Unique Key phục vụ Composite FK ở bảng survey_response
    CONSTRAINT uq_survey_attempt_id_version 
        UNIQUE (id, survey_version_id)
);

CREATE INDEX idx_survey_attempt_status_expires 
    ON survey_attempt (status, expires_at);

-- ---------------------------------------------------------------------
-- 4. BẢNG: survey_response
-- Lưu câu trả lời của từng câu trong một attempt
-- ---------------------------------------------------------------------
CREATE TABLE survey_response (
    attempt_id UUID NOT NULL,
    question_id UUID NOT NULL,
    survey_version_id UUID NOT NULL,
    answer_yes BOOLEAN NOT NULL,
    answered_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Composite Primary Key: PK tự động index trên (attempt_id, question_id)
    CONSTRAINT pk_survey_response 
        PRIMARY KEY (attempt_id, question_id),

    -- Composite FK 1: Ràng buộc attempt_id và survey_version_id
    CONSTRAINT fk_survey_response_attempt_version 
        FOREIGN KEY (attempt_id, survey_version_id) 
        REFERENCES survey_attempt (id, survey_version_id) 
        ON DELETE CASCADE,

    -- Composite FK 2: Ràng buộc question_id và survey_version_id
    -- ĐẢM BẢO TUYỆT ĐỐI KHÔNG BỊ LỆCH PHIÊN BẢN (CROSS-VERSION MISMATCH)
    CONSTRAINT fk_survey_response_question_version 
        FOREIGN KEY (question_id, survey_version_id) 
        REFERENCES survey_question (id, survey_version_id) 
        ON DELETE RESTRICT
);

-- ---------------------------------------------------------------------
-- 5. BẢNG: survey_result
-- Kết quả chấm điểm cuối cùng của một attempt (1-to-1 với survey_attempt)
-- ---------------------------------------------------------------------
CREATE TABLE survey_result (
    attempt_id UUID PRIMARY KEY,
    score_a SMALLINT NOT NULL,
    score_b SMALLINT NOT NULL,
    score_c SMALLINT NOT NULL,
    temperament VARCHAR(20) NOT NULL,
    reliability_status VARCHAR(50), -- Tạm thời NULL, chờ quyết định nghiệp vụ
    calculated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- 1-1 với attempt
    CONSTRAINT fk_survey_result_attempt 
        FOREIGN KEY (attempt_id) 
        REFERENCES survey_attempt (id) 
        ON DELETE RESTRICT,

    -- Giới hạn điểm số hợp lệ theo đúng số lượng câu hỏi của từng thang
    CONSTRAINT chk_survey_result_score_a 
        CHECK (score_a BETWEEN 0 AND 24),

    CONSTRAINT chk_survey_result_score_b 
        CHECK (score_b BETWEEN 0 AND 24),

    CONSTRAINT chk_survey_result_score_c 
        CHECK (score_c BETWEEN 0 AND 9),

    -- 4 nhóm khí chất kinh điển của Eysenck
    CONSTRAINT chk_survey_result_temperament 
        CHECK (temperament IN ('PHLEGMATIC', 'MELANCHOLIC', 'SANGUINE', 'CHOLERIC')),

    -- Ràng buộc tính nhất quán toán học giữa điểm A/B và Khí chất tương ứng
    CONSTRAINT chk_survey_result_temperament_match CHECK (
        (score_a <= 12 AND score_b <= 12 AND temperament = 'PHLEGMATIC') OR
        (score_a <= 12 AND score_b > 12  AND temperament = 'MELANCHOLIC') OR
        (score_a > 12  AND score_b <= 12 AND temperament = 'SANGUINE') OR
        (score_a > 12  AND score_b > 12  AND temperament = 'CHOLERIC')
    )
);

-- ---------------------------------------------------------------------
-- 6. BẢNG: admin_account
-- Tài khoản quản trị viên duy nhất
-- ---------------------------------------------------------------------
CREATE TABLE admin_account (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMPTZ,

    CONSTRAINT uq_admin_account_username 
        UNIQUE (username)
);

-- =====================================================================
-- DATABASE TRIGGERS: BẢO VỆ TÍNH TOÀN VẸN, BẤT BIẾN VÀ ĐỒNG BỘ KHÓA
-- =====================================================================

-- ---------------------------------------------------------------------
-- Trigger 1: Thực thi máy trạng thái vòng đời survey_version
-- DRAFT -> PUBLISHED -> ARCHIVED (Không cho phép quay lui, chỉ publish khi đủ 57 câu)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_enforce_survey_version_lifecycle()
RETURNS TRIGGER AS $$
DECLARE
    v_q_count INT;
BEGIN
    IF TG_OP = 'UPDATE' THEN
        -- Cấm sửa ID hoặc version_code
        IF OLD.id <> NEW.id OR OLD.version_code <> NEW.version_code THEN
            RAISE EXCEPTION 'Database Integrity Violation: Cannot modify id or version_code of a survey version';
        END IF;

        -- Kiểm tra chuyển đổi trạng thái hợp lệ
        IF OLD.status = 'DRAFT' AND NEW.status = 'PUBLISHED' THEN
            -- Phải có đúng 57 câu hỏi hợp lệ mới được publish
            SELECT COUNT(*) INTO v_q_count 
            FROM survey_question 
            WHERE survey_version_id = NEW.id;

            IF v_q_count <> 57 THEN
                RAISE EXCEPTION 'Database Integrity Violation: Cannot publish version with % questions (must be exactly 57)', 
                    v_q_count;
            END IF;

            IF NEW.published_at IS NULL THEN
                NEW.published_at := CURRENT_TIMESTAMP;
            END IF;

        ELSIF OLD.status = 'PUBLISHED' AND NEW.status = 'ARCHIVED' THEN
            IF NEW.archived_at IS NULL THEN
                NEW.archived_at := CURRENT_TIMESTAMP;
            END IF;

        ELSIF OLD.status = NEW.status THEN
            -- Giữ nguyên status: nếu không phải DRAFT thì không được sửa mô tả
            IF OLD.status <> 'DRAFT' AND (OLD.description IS DISTINCT FROM NEW.description) THEN
                RAISE EXCEPTION 'Database Integrity Violation: Cannot modify description of a % version', OLD.status;
            END IF;
        ELSE
            RAISE EXCEPTION 'Database Integrity Violation: Invalid state transition from % to %', 
                OLD.status, NEW.status;
        END IF;

    ELSIF TG_OP = 'DELETE' THEN
        IF OLD.status <> 'DRAFT' THEN
            RAISE EXCEPTION 'Database Integrity Violation: Cannot delete a % survey version', OLD.status;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_enforce_survey_version_lifecycle
    BEFORE UPDATE OR DELETE ON survey_version
    FOR EACH ROW
    EXECUTE FUNCTION fn_enforce_survey_version_lifecycle();

-- ---------------------------------------------------------------------
-- Trigger 2: Bảo vệ tính bất biến của câu hỏi (Kiểm tra cả OLD và NEW, khóa FOR SHARE)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_protect_survey_question_immutability()
RETURNS TRIGGER AS $$
DECLARE
    v_target_version_id UUID;
    v_status VARCHAR(20);
BEGIN
    IF TG_OP = 'UPDATE' THEN
        -- Tuyệt đối cấm đổi id hoặc survey_version_id sang version khác
        IF OLD.id <> NEW.id OR OLD.survey_version_id <> NEW.survey_version_id THEN
            RAISE EXCEPTION 'Database Integrity Violation: Cannot reassign id or survey_version_id of an existing question';
        END IF;
    END IF;

    v_target_version_id := CASE WHEN TG_OP = 'DELETE' THEN OLD.survey_version_id ELSE NEW.survey_version_id END;

    -- Khóa FOR SHARE trên survey_version:
    -- Đồng bộ hóa với transaction publish version (UPDATE survey_version vốn lấy exclusive lock).
    SELECT status INTO v_status 
    FROM survey_version 
    WHERE id = v_target_version_id
    FOR SHARE;

    IF v_status IS DISTINCT FROM 'DRAFT' THEN
        RAISE EXCEPTION 'Database Integrity Violation: Cannot % question in a % survey version', 
            TG_OP, v_status;
    END IF;

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_protect_survey_question_immutability
    BEFORE INSERT OR UPDATE OR DELETE ON survey_question
    FOR EACH ROW
    EXECUTE FUNCTION fn_protect_survey_question_immutability();

-- ---------------------------------------------------------------------
-- Trigger 3: Bảo vệ response chống ghi đè khi attempt đã COMPLETED hoặc EXPIRED
-- (Khóa FOR SHARE trên attempt để tuần tự hóa triệt để với transaction hoàn thành)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_prevent_completed_response_tampering()
RETURNS TRIGGER AS $$
DECLARE
    v_target_attempt_id UUID;
    v_attempt_status VARCHAR(20);
    v_expires_at TIMESTAMPTZ;
BEGIN
    IF TG_OP = 'UPDATE' THEN
        -- Cấm tuyệt đối thay đổi các khóa định danh của câu trả lời
        IF OLD.attempt_id <> NEW.attempt_id OR 
           OLD.question_id <> NEW.question_id OR 
           OLD.survey_version_id <> NEW.survey_version_id THEN
            RAISE EXCEPTION 'Database Integrity Violation: Cannot reassign identifiers of survey_response';
        END IF;
    END IF;

    v_target_attempt_id := CASE WHEN TG_OP = 'DELETE' THEN OLD.attempt_id ELSE NEW.attempt_id END;

    -- Khóa FOR SHARE trên attempt:
    -- Nếu một request hoàn thành bài đang chạy UPDATE survey_attempt (hoặc SELECT ... FOR UPDATE),
    -- câu lệnh FOR SHARE ở đây sẽ đợi cho đến khi transaction hoàn thành commit xong.
    -- Khi đọc ra, nếu v_attempt_status = 'COMPLETED', request ghi response này sẽ bị chặn đứng ngay!
    SELECT status, expires_at INTO v_attempt_status, v_expires_at
    FROM survey_attempt 
    WHERE id = v_target_attempt_id
    FOR SHARE;

    IF v_attempt_status = 'COMPLETED' THEN
        RAISE EXCEPTION 'Database Integrity Violation: Cannot % response for an already COMPLETED attempt', 
            TG_OP;
    END IF;

    IF CURRENT_TIMESTAMP > v_expires_at THEN
        RAISE EXCEPTION 'Database Integrity Violation: Cannot % response for an EXPIRED attempt', 
            TG_OP;
    END IF;

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_prevent_completed_response_tampering
    BEFORE INSERT OR UPDATE OR DELETE ON survey_response
    FOR EACH ROW
    EXECUTE FUNCTION fn_prevent_completed_response_tampering();
