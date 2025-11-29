# HƯỚNG DẪN NHANH - CHẠY DATABASE

## Bước 1: Mở MySQL Command Line hoặc Workbench

```bash
# Hoặc kết nối từ App (Node.js đã cấu hình)
mysql -u root -p
```

## Bước 2: Tạo Database & Import Data

**Option A: Import lần lượt (Khuyến nghị)**

```sql
SOURCE D:/HCMUT/Database_BTL3/db/01_create_tables.sql;
SOURCE D:/HCMUT/Database_BTL3/db/02_insert_data.sql;
SOURCE D:/HCMUT/Database_BTL3/db/03_stored_procedures.sql;
SOURCE D:/HCMUT/Database_BTL3/db/04_user_procedures.sql;
SOURCE D:/HCMUT/Database_BTL3/db/05_triggers.sql;
SOURCE D:/HCMUT/Database_BTL3/db/06_functions.sql;
```

**Option B: Chạy từ PowerShell (Windows)**

```powershell
mysql -u root -p btl2_db < D:\HCMUT\Database_BTL3\db\01_create_tables.sql
mysql -u root -p btl2_db < D:\HCMUT\Database_BTL3\db\02_insert_data.sql
mysql -u root -p btl2_db < D:\HCMUT\Database_BTL3\db\03_stored_procedures.sql
mysql -u root -p btl2_db < D:\HCMUT\Database_BTL3\db\04_user_procedures.sql
mysql -u root -p btl2_db < D:\HCMUT\Database_BTL3\db\05_triggers.sql
mysql -u root -p btl2_db < D:\HCMUT\Database_BTL3\db\06_functions.sql
```

## Bước 3: Kiểm Tra

```sql
USE btl2_db;

-- Kiểm tra bảng
SHOW TABLES;  -- Phải có 16 bảng

-- Kiểm tra dữ liệu
SELECT COUNT(*) FROM Useraccount;  -- 15
SELECT COUNT(*) FROM Product;      -- 10
SELECT COUNT(*) FROM Shop;         -- 5

-- Kiểm tra Procedures
SHOW PROCEDURE STATUS WHERE Db = 'btl2_db';

-- Kiểm tra Functions
SHOW FUNCTION STATUS WHERE Db = 'btl2_db';
```

## Bước 4: Test Procedures/Functions

```sql
-- Test thêm sản phẩm
CALL sp_InsertProduct(1, 1, 'Sạc nhanh', 'Mô tả', @err, @msg);
SELECT @err AS ErrorCode, @msg AS ErrorMessage;

-- Test xem sản phẩm yếu
CALL sp_GetUnderperformingProducts(0, 4.0);

-- Test doanh thu
SELECT fn_TinhDoanhThuShop(1, 1, 2025) AS Revenue;
```

---

## DANH SÁCH FILE DATABASE

| File | Mục Đích | Dòng SQL |
|------|---------|---------|
| 01_create_tables.sql | Tạo 16 bảng | ~300 |
| 02_insert_data.sql | Insert 100+ rows | ~150 |
| 03_stored_procedures.sql | 3 SP CRUD Product + 2 SP SELECT | ~200 |
| 04_user_procedures.sql | 3 SP CRUD User | ~200 |
| 05_triggers.sql | 4 Triggers | ~150 |
| 06_functions.sql | 2 Functions | ~150 |
| 07_test_demo.sql | Test & Demo | ~100 |

**Tổng: ~1250 dòng SQL code**

---

## TROUBLESHOOTING

### Lỗi: "Access denied for user 'root'"
```powershell
mysql -u root -p
# Nhập password khi được yêu cầu
```

### Lỗi: "No database selected"
```sql
USE btl2_db;
SOURCE ...
```

### Lỗi: "Trigger already exists"
```sql
-- Xóa trigger cũ
DROP TRIGGER IF EXISTS trig_check_product_stock_before_insert;
-- Chạy lại 05_triggers.sql
```

### Lỗi: "Foreign key constraint failed"
```sql
SET FOREIGN_KEY_CHECKS = 0;
-- Chạy lệnh có vấn đề
SET FOREIGN_KEY_CHECKS = 1;
```

---

## KẾT NỐI TỬ APP.JS

Database đã sẵn sàng kết nối:

```javascript
// Trong app.js:
const pool = mysql.createPool({
  host: "localhost",
  user: "root",
  password: "",  // Điều chỉnh nếu có password
  database: "btl2_db",
});
```

---

## THAM KHẢO CHI TIẾT

Xem file `README.md` trong thư mục `db/` để hiểu rõ từng phần:
- Cấu trúc bảng
- Ràng buộc dữ liệu
- Chi tiết Procedure/Function
- Trigger logic
- Test cases
