-- =====================================================================
-- Migration: V2__seed_eysenck_57_questions.sql
-- Description: Seed Version 1.0.0 and all 57 Eysenck Questions with Strict Verification
-- Engine: PostgreSQL 17
-- =====================================================================

DO $$
DECLARE
    v_version_id UUID := 'a0000000-0000-0000-0000-000000000001'::UUID;
    v_total_questions INT;
    v_count_a INT;
    v_count_b INT;
    v_count_c INT;
    v_count_a_yes INT;
    v_count_a_no INT;
    v_count_b_yes INT;
    v_count_b_no INT;
    v_count_c_yes INT;
    v_count_c_no INT;
BEGIN
    -- 1. Khởi tạo phiên bản ở trạng thái DRAFT
    -- Không dùng ON CONFLICT DO NOTHING để tránh nuốt lỗi cấu hình môi trường
    INSERT INTO survey_version (id, version_code, status, description, created_at)
    VALUES (
        v_version_id, 
        'EYSENCK_57_V1', 
        'DRAFT', 
        'Bảng câu hỏi trắc nghiệm tính cách Eysenck (57 câu, 3 thang đo A, B, C)',
        CURRENT_TIMESTAMP
    );

    -- 2. Nạp toàn bộ 57 câu hỏi theo đúng nguyên văn và quy tắc chấm điểm
    INSERT INTO survey_question (survey_version_id, question_no, content, section_code, point_answer)
    VALUES
        (v_version_id, 1, 'Bạn có thường xuyên bị lôi cuốn vào những cảm tưởng, những ấn tượng mới mẻ hoặc đi tìm nguồn cảm xúc mạnh mẻ để giải buồn và làm cho mình phấn chấn lên không?', 'A', true),
        (v_version_id, 2, 'Bạn có thường xuyên cảm thấy cần có những người ý hợp tâm đồng để động viên và an ủi mình không?', 'B', true),
        (v_version_id, 3, 'Bạn là người vô tư không bận tâm đến điều gì phải không?', 'A', true),
        (v_version_id, 4, 'Bạn có cảm thấy khó khăn khi phải từ bỏ những ý định của mình hoặc phải trả lời “không” với người khác không?', 'B', true),
        (v_version_id, 5, 'Bạn có cân nhắc suy tính trước khi hành động không?', 'A', false),
        (v_version_id, 6, 'Khi đã hứa làm một việc gì bạn có luôn giữ lời hứa không? (bất kể lời hứa đó có thuận lợi cho mình hay không)', 'C', true),
        (v_version_id, 7, 'Bạn có thường hay thay đổi tâm trạng lúc vui, lúc buồn không?', 'B', true),
        (v_version_id, 8, 'Bạn có hay nói năng hành động một cách bột phát, vội vàng không suy nghĩ không?', 'A', true),
        (v_version_id, 9, 'Có khi nào bạn cảm thấy mình là người bất hạnh mà không có nguyên nhân rõ ràng không?', 'B', true),
        (v_version_id, 10, 'Bạn có cho mình vào loại người không bao giờ phải lúng túng, ấp úng, mà luôn sẵn sàng đối đáp với mọi nhận xét hoặc bất chấp tất cả để tranh cãi đến cùng hay không?', 'A', true),
        (v_version_id, 11, 'Bạn có cảm thấy rụt rè, ngượng ngùng khi muốn bắt chuyện với một người bạn khác giới dễ mến chưa quen biết hay không?', 'B', true),
        (v_version_id, 12, 'Đôi lúc bạn không tự kìm hãm được, nổi nóng phải không?', 'C', false),
        (v_version_id, 13, 'Bạn có hay hành động một cách nông nổi, bồng bột không?', 'A', true),
        (v_version_id, 14, 'Bạn có thường ân hận với những lời bạn đã nói, việc làm đã làm mà lẽ ra không nên nói không nên làm không?', 'B', true),
        (v_version_id, 15, 'Bạn thích đọc sách hơn là trò chuyện ai đó phải không?', 'A', false),
        (v_version_id, 16, 'Bạn có dễ phật ý không?', 'B', true),
        (v_version_id, 17, 'Bạn thích thường có những buổi gặp mặt bạn bè thân không?', 'A', true),
        (v_version_id, 18, 'Thỉnh thoảng có những ý nghĩ mà bạn muốn dấu không cho người khác biết?', 'C', false),
        (v_version_id, 19, 'Có đúng là đôi khi bạn cảm thấy mình có đầy nghị lực nhiệt tình làm mọi chuyện, nhưng cũng có lúc lại thấy hoàn toàn uể oải không?', 'B', true),
        (v_version_id, 20, 'Bạn có thích thà ít bạn còn hơn nhiều bạn mà không thân?', 'A', false),
        (v_version_id, 21, 'Bạn có hay ước mơ không?', 'B', true),
        (v_version_id, 22, 'Khi người ta quát tháo với bạn, thì bạn cũng quát tháo lại phải không?', 'A', true),
        (v_version_id, 23, 'Bạn thường day dứt khi thấy mình phạm sai lầm?', 'B', true),
        (v_version_id, 24, 'Có phải tất cả những thói quen của bạn đều tốt và hợp với mong muốn của bạn phải không?', 'C', true),
        (v_version_id, 25, 'Bạn có khả năng làm chủ được tình cảm của mình và hoàn toàn vui vẻ trong các buổi hội họp phải không?', 'A', true),
        (v_version_id, 26, 'Bạn có cho mình là người nhạy cảm và dễ bị kích thích không?', 'B', true),
        (v_version_id, 27, 'Người ta cho bạn là người vui vẻ, hoạt bát phải không?', 'A', true),
        (v_version_id, 28, 'Sau khi làm một việc quan trọng gì đó, bạn có cảm thấy rằng mình còn có thể làm tốt hơn nữa không?', 'B', true),
        (v_version_id, 29, 'Khi ở trong một tập thể đông người, bạn thường im lặng phải không?', 'A', false),
        (v_version_id, 30, 'Đôi khi bạn cũng thêu dệt những câu chuyện phải không?', 'C', false),
        (v_version_id, 31, 'Bạn có hay bị mất ngủ vì những ý nghĩ lộn xộn trong đầu không?', 'B', true),
        (v_version_id, 32, 'Khi muốn biết một điều gì đó, bạn thường thích tự đọc lấy sách hơn là đi hỏi người khác?', 'A', false),
        (v_version_id, 33, 'Có bao giờ bạn hồi hộp không?', 'B', true),
        (v_version_id, 34, 'Bạn có thích những công việc đòi hỏi sự chú ý thường xuyên không?', 'A', false),
        (v_version_id, 35, 'Bạn có bao giờ run sợ không?', 'B', true),
        (v_version_id, 36, 'Nếu như không có người kiểm tra thì khi đi tàu, đi xe bạn có mua vé không?', 'C', true),
        (v_version_id, 37, 'Bạn có thấy khó chịu khi sống trong một tập thể mà mọi người hay giễu cợt nhau không?', 'A', false),
        (v_version_id, 38, 'Bạn có hay bức tức không?', 'B', true),
        (v_version_id, 39, 'Bạn có thích những công việc phải hoàn thành gấp gáp không?', 'A', true),
        (v_version_id, 40, 'Trước những sự việc có hoặc không thể xảy ra, bạn có hay hồi hộp không?', 'B', true),
        (v_version_id, 41, 'Bạn đi đứng ung dung thong thả phải không?', 'A', false),
        (v_version_id, 42, 'Có khi nào bạn đến chỗ hẹn hoặc đi làm hay đi học muộn không?', 'C', false),
        (v_version_id, 43, 'Bạn có hay thấy những cơn ác mộng không?', 'B', true),
        (v_version_id, 44, 'Có đúng bạn là người thích nói chuyện đến mức không bao giờ bỏ lỡ cơ hội nói chuyện với những người không quen biết phải không?', 'A', true),
        (v_version_id, 45, 'Có nỗi đau nào đó làm bạn lo lắng không?', 'B', true),
        (v_version_id, 46, 'Bạn có cảm thấy mình thật bất hạnh nếu như trong một thời gian dài không được tiếp xúc rộng rãi với mọi người không?', 'A', true),
        (v_version_id, 47, 'Bạn có thể gọi mình là người dễ xúc động, dễ phản ứng không?', 'B', true),
        (v_version_id, 48, 'Trong số những người quen, có người mà bạn không thích một cách công khai không?', 'C', false),
        (v_version_id, 49, 'Bạn có cho mình là người hoàn toàn tự tin không?', 'A', true),
        (v_version_id, 50, 'Bạn có dễ phật ý khi mọi người chỉ ra những lỗi lầm của mình trong công tác hay những thiếu sót riêng tư của mình hay không?', 'B', true),
        (v_version_id, 51, 'Bạn có cho rằng khó có thể thực sự hài lòng trong buổi liên hoan gặp mặt không?', 'A', false),
        (v_version_id, 52, 'Sự cảm nhận rằng mình thấp kém hơn người khác có làm bạn khó chịu hay không?', 'B', true),
        (v_version_id, 53, 'Bạn có dễ dàng làm cho nhóm bạn bè vui vẻ của mình đang buồn chán trở nên sôi nổi vui vẻ hay không?', 'A', true),
        (v_version_id, 54, 'Có khi nào bạn nói về những điều mà bạn không am hiểu không?', 'C', false),
        (v_version_id, 55, 'Bạn có lo lắng về sức khỏe của bản thân không?', 'B', true),
        (v_version_id, 56, 'Bạn có thích trêu đùa người khác không?', 'A', true),
        (v_version_id, 57, 'Bạn có bị mất ngủ không?', 'B', true);

    -- 3. KIỂM TRA ĐỐI CHIẾU DỮ LIỆU ĐÃ SEED (STRICT ASSERTIONS)
    SELECT COUNT(*) INTO v_total_questions FROM survey_question WHERE survey_version_id = v_version_id;
    SELECT COUNT(*) INTO v_count_a FROM survey_question WHERE survey_version_id = v_version_id AND section_code = 'A';
    SELECT COUNT(*) INTO v_count_b FROM survey_question WHERE survey_version_id = v_version_id AND section_code = 'B';
    SELECT COUNT(*) INTO v_count_c FROM survey_question WHERE survey_version_id = v_version_id AND section_code = 'C';

    SELECT COUNT(*) INTO v_count_a_yes FROM survey_question WHERE survey_version_id = v_version_id AND section_code = 'A' AND point_answer = true;
    SELECT COUNT(*) INTO v_count_a_no FROM survey_question WHERE survey_version_id = v_version_id AND section_code = 'A' AND point_answer = false;

    SELECT COUNT(*) INTO v_count_b_yes FROM survey_question WHERE survey_version_id = v_version_id AND section_code = 'B' AND point_answer = true;
    SELECT COUNT(*) INTO v_count_b_no FROM survey_question WHERE survey_version_id = v_version_id AND section_code = 'B' AND point_answer = false;

    SELECT COUNT(*) INTO v_count_c_yes FROM survey_question WHERE survey_version_id = v_version_id AND section_code = 'C' AND point_answer = true;
    SELECT COUNT(*) INTO v_count_c_no FROM survey_question WHERE survey_version_id = v_version_id AND section_code = 'C' AND point_answer = false;

    IF v_total_questions <> 57 THEN
        RAISE EXCEPTION 'Seed Validation Error: Total questions must be 57, found %', v_total_questions;
    END IF;

    IF v_count_a <> 24 OR v_count_a_yes <> 15 OR v_count_a_no <> 9 THEN
        RAISE EXCEPTION 'Seed Validation Error: Scale A distribution mismatch (Expected 24 total: 15 Yes, 9 No; Found % total: % Yes, % No)',
            v_count_a, v_count_a_yes, v_count_a_no;
    END IF;

    IF v_count_b <> 24 OR v_count_b_yes <> 24 OR v_count_b_no <> 0 THEN
        RAISE EXCEPTION 'Seed Validation Error: Scale B distribution mismatch (Expected 24 total: 24 Yes, 0 No; Found % total: % Yes, % No)',
            v_count_b, v_count_b_yes, v_count_b_no;
    END IF;

    IF v_count_c <> 9 OR v_count_c_yes <> 3 OR v_count_c_no <> 6 THEN
        RAISE EXCEPTION 'Seed Validation Error: Scale C distribution mismatch (Expected 9 total: 3 Yes, 6 No; Found % total: % Yes, % No)',
            v_count_c, v_count_c_yes, v_count_c_no;
    END IF;

    -- 4. KÍCH HOẠT PHIÊN BẢN (CHUYỂN SANG PUBLISHED)
    -- Trigger fn_enforce_survey_version_lifecycle sẽ kiểm tra lại số lượng câu hỏi và tự gán published_at
    -- Trigger fn_protect_survey_question_immutability sẽ khóa cứng 57 câu hỏi này ngay lập tức
    UPDATE survey_version 
    SET status = 'PUBLISHED'
    WHERE id = v_version_id;

    RAISE NOTICE 'Migration V2: Eysenck 57 questions seeded, strictly verified and published successfully.';
END $$;
