-- ============================================================
-- SCRIPT CHẠY TOÀN BỘ DATABASE
-- ============================================================
-- Chạy các file SQL theo thứ tự:
-- 1. 01_create_tables.sql       (Tạo bảng)
-- 2. 02_insert_data.sql         (Insert dữ liệu mẫu)
-- 3. 03_stored_procedures.sql   (SP cho Product)
-- 4. 04_user_procedures.sql     (SP cho Useraccount)
-- 5. 05_triggers.sql            (Triggers)
-- 6. 06_functions.sql           (Functions)

-- Trong MySQL, bạn chạy lần lượt:
-- mysql -u root -p < 01_create_tables.sql
-- mysql -u root -p < 02_insert_data.sql
-- mysql -u root -p < 03_stored_procedures.sql
-- mysql -u root -p < 04_user_procedures.sql
-- mysql -u root -p < 05_triggers.sql
-- mysql -u root -p < 06_functions.sql

-- HOẶC trong MySQL client:
-- mysql> SOURCE C:/path/to/01_create_tables.sql;
-- mysql> SOURCE C:/path/to/02_insert_data.sql;
-- ... và tiếp tục

-- ============================================================
-- HOẶC chạy script tổng hợp này (copy tất cả nội dung của các file vào đây)
-- ============================================================

-- Mục đích: Nếu muốn chạy tất cả một lần, hãy SOURCE các file trên theo thứ tự.

