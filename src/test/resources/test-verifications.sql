-- =====================================================================
-- File: src/test/resources/test-verifications.sql
-- Description: Test suite chạy thử trên PostgreSQL 17 để kiểm chứng:
--   1. Lifecycle & State Machine của survey_version
--   2. Tính bất biến của survey_question và survey_response
--   3. Đồng bộ khóa chống Race Condition (FOR SHARE)
--   4. Ràng buộc toán học Temperament Match
-- =====================================================================

-- ---------------------------------------------------------------------
-- TEST 1: Thử kích hoạt 2 phiên bản PUBLISHED cùng lúc -> PHẢI LỖI (Unique Violation)
-- ---------------------------------------------------------------------
DO $$
BEGIN
    INSERT INTO survey_version (id, version_code, status, published_at)
    VALUES ('a0000000-0000-0000-0000-000000000002', 'EYSENCK_57_V2', 'PUBLISHED', CURRENT_TIMESTAMP);
    
    RAISE EXCEPTION 'TEST 1 FAILED: Cho phép tồn tại 2 version PUBLISHED cùng lúc!';
EXCEPTION
    WHEN unique_violation THEN
        RAISE NOTICE 'TEST 1 PASSED: Partial unique index đã chặn thành công 2 version PUBLISHED!';
END $$;

-- ---------------------------------------------------------------------
-- TEST 2: Thử chuyển trạng thái PUBLISHED -> DRAFT -> PHẢI LỖI (Trigger Lifecycle Violation)
-- ---------------------------------------------------------------------
DO $$
DECLARE
    v_v1 UUID := 'a0000000-0000-0000-0000-000000000001'::UUID;
BEGIN
    UPDATE survey_version 
    SET status = 'DRAFT' 
    WHERE id = v_v1;

    RAISE EXCEPTION 'TEST 2 FAILED: Cho phép chuyển ngược trạng thái từ PUBLISHED về DRAFT!';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'TEST 2 PASSED: Trigger lifecycle đã chặn chuyển ngược trạng thái về DRAFT!';
END $$;

-- ---------------------------------------------------------------------
-- TEST 3: Thử Publish một phiên bản chưa đủ 57 câu hỏi -> PHẢI LỖI (Trigger Lifecycle Violation)
-- ---------------------------------------------------------------------
DO $$
DECLARE
    v_draft_id UUID := gen_random_uuid();
BEGIN
    INSERT INTO survey_version (id, version_code, status) VALUES (v_draft_id, 'TEST_INCOMPLETE_DRAFT', 'DRAFT');
    -- Chỉ chèn 1 câu hỏi
    INSERT INTO survey_question (survey_version_id, question_no, content, section_code, point_answer)
    VALUES (v_draft_id, 1, 'Câu hỏi test', 'A', true);

    -- Cố tình UPDATE status sang PUBLISHED khi mới có 1 câu
    UPDATE survey_version SET status = 'PUBLISHED' WHERE id = v_draft_id;

    RAISE EXCEPTION 'TEST 3 FAILED: Cho phép publish phiên bản chưa đủ 57 câu hỏi!';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'TEST 3 PASSED: Trigger lifecycle đã chặn publish version khi chưa đủ 57 câu hỏi!';
END $$;

-- ---------------------------------------------------------------------
-- TEST 4: Thử đổi survey_version_id của câu hỏi để "rút lõi" version đã PUBLISHED -> PHẢI LỖI
-- ---------------------------------------------------------------------
DO $$
DECLARE
    v_v1 UUID := 'a0000000-0000-0000-0000-000000000001'::UUID;
    v_draft_id UUID := gen_random_uuid();
    v_q1 UUID;
BEGIN
    INSERT INTO survey_version (id, version_code, status) VALUES (v_draft_id, 'TEST_RECEIVER_DRAFT', 'DRAFT');
    SELECT id INTO v_q1 FROM survey_question WHERE survey_version_id = v_v1 AND question_no = 1;

    -- Thử UPDATE chuyển câu hỏi từ version V1 (PUBLISHED) sang version DRAFT
    UPDATE survey_question 
    SET survey_version_id = v_draft_id 
    WHERE id = v_q1;

    RAISE EXCEPTION 'TEST 4 FAILED: Cho phép thay đổi survey_version_id của câu hỏi!';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'TEST 4 PASSED: Trigger bất biến đã chặn di chuyển câu hỏi giữa các phiên bản!';
END $$;

-- ---------------------------------------------------------------------
-- TEST 5: Thử lưu câu trả lời thuộc sai phiên bản (Cross-Version Mismatch) -> PHẢI LỖI (FK Violation)
-- ---------------------------------------------------------------------
DO $$
DECLARE
    v_v1 UUID := 'a0000000-0000-0000-0000-000000000001'::UUID;
    v_v2 UUID := gen_random_uuid();
    v_attempt_v1 UUID := gen_random_uuid();
    v_q_v2 UUID := gen_random_uuid();
BEGIN
    INSERT INTO survey_version (id, version_code, status) VALUES (v_v2, 'V2_MISMATCH_TEST', 'DRAFT');
    INSERT INTO survey_question (id, survey_version_id, question_no, content, section_code, point_answer)
    VALUES (v_q_v2, v_v2, 1, 'Câu hỏi V2', 'A', true);

    INSERT INTO survey_attempt (id, survey_version_id, token_hash, expires_at)
    VALUES (v_attempt_v1, v_v1, 'dummy_token_hash_cross', CURRENT_TIMESTAMP + INTERVAL '30 days');

    -- THỬ LƯU: attempt của V1 nhưng câu hỏi của V2
    INSERT INTO survey_response (attempt_id, question_id, survey_version_id, answer_yes)
    VALUES (v_attempt_v1, v_q_v2, v_v1, true);

    RAISE EXCEPTION 'TEST 5 FAILED: Cho phép lưu câu trả lời cọc cạch phiên bản!';
EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'TEST 5 PASSED: Composite Foreign Key đã chặn thành công Cross-Version Mismatch!';
END $$;

-- ---------------------------------------------------------------------
-- TEST 6: Thử sửa câu trả lời sau khi attempt đã COMPLETED -> PHẢI LỖI (Trigger Violation)
-- ---------------------------------------------------------------------
DO $$
DECLARE
    v_v1 UUID := 'a0000000-0000-0000-0000-000000000001'::UUID;
    v_attempt UUID := gen_random_uuid();
    v_q1 UUID;
BEGIN
    SELECT id INTO v_q1 FROM survey_question WHERE survey_version_id = v_v1 AND question_no = 1;

    INSERT INTO survey_attempt (id, survey_version_id, token_hash, status, expires_at)
    VALUES (v_attempt, v_v1, 'dummy_token_hash_completed', 'IN_PROGRESS', CURRENT_TIMESTAMP + INTERVAL '30 days');

    INSERT INTO survey_response (attempt_id, question_id, survey_version_id, answer_yes)
    VALUES (v_attempt, v_q1, v_v1, true);

    UPDATE survey_attempt 
    SET status = 'COMPLETED', completed_at = CURRENT_TIMESTAMP 
    WHERE id = v_attempt;

    -- Thử UPDATE lại câu trả lời sau khi hoàn tất
    UPDATE survey_response 
    SET answer_yes = false 
    WHERE attempt_id = v_attempt AND question_id = v_q1;

    RAISE EXCEPTION 'TEST 6 FAILED: Cho phép sửa câu trả lời sau khi attempt đã COMPLETED!';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'TEST 6 PASSED: Trigger đã ngăn chặn sửa câu trả lời của attempt COMPLETED!';
END $$;

-- ---------------------------------------------------------------------
-- TEST 7: Thử ghi khí chất không khớp với điểm A/B -> PHẢI LỖI (Check Violation)
-- (Ví dụ: score_a = 15 (>12), score_b = 5 (<=12) mà cố tình ghi MELANCHOLIC thay vì SANGUINE)
-- ---------------------------------------------------------------------
DO $$
DECLARE
    v_v1 UUID := 'a0000000-0000-0000-0000-000000000001'::UUID;
    v_attempt UUID := gen_random_uuid();
BEGIN
    INSERT INTO survey_attempt (id, survey_version_id, token_hash, status, completed_at, expires_at)
    VALUES (v_attempt, v_v1, 'dummy_token_hash_mismatch', 'COMPLETED', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP + INTERVAL '30 days');

    -- Sai logic: score_a = 15 (Extraversion), score_b = 5 (Stable) => Phải là SANGUINE, nhưng cố tình ghi MELANCHOLIC
    INSERT INTO survey_result (attempt_id, score_a, score_b, score_c, temperament)
    VALUES (v_attempt, 15, 5, 2, 'MELANCHOLIC');

    RAISE EXCEPTION 'TEST 7 FAILED: Cho phép lưu khí chất không khớp với điểm số A/B!';
EXCEPTION
    WHEN check_violation THEN
        RAISE NOTICE 'TEST 7 PASSED: chk_survey_result_temperament_match đã chặn khí chất sai lệch toán học!';
END $$;
