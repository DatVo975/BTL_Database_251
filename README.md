# Database BTL3 - Hệ thống Quản lý E-commerce

## 📋 Giới thiệu

Đây là project BTL3 môn Cơ sở dữ liệu, xây dựng hệ thống quản lý sàn thương mại điện tử với đầy đủ tính năng:
- Quản lý người dùng (Buyer/Seller)
- Quản lý sản phẩm và đơn hàng
- Hệ thống voucher và thanh toán
- Báo cáo doanh thu

## 🛠️ Công nghệ sử dụng

- **Backend**: Node.js + Express.js
- **Database**: MySQL 8.0
- **Template Engine**: EJS
- **Authentication**: JWT + bcrypt
- **Containerization**: Docker + Docker Compose

## 📦 Yêu cầu hệ thống

- Docker Desktop (đã cài đặt và đang chạy)
- Node.js >= 14.x
- npm hoặc yarn
- Git

## 🚀 Hướng dẫn cài đặt và chạy

### Bước 1: Clone project

```bash
git clone <repository-url>
cd Database_BTL3
```

### Bước 2: Cài đặt dependencies

```powershell
npm install
```

### Bước 3: Tạo file .env

Tạo file `.env` trong thư mục gốc với nội dung:

```env
JWTSECRET=your_secret_key_here
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=
DB_NAME=btl2_db
DB_PORT=3307
NODE_ENV=development
```

### Bước 4: Khởi động MySQL bằng Docker

```powershell
docker-compose up -d
```

Kiểm tra container đã chạy:
```powershell
docker ps
```

### Bước 5: Khởi tạo database

Chạy script tự động để import toàn bộ database:

```powershell
powershell -ExecutionPolicy Bypass -File import-db.ps1
```

Hoặc chạy từng file SQL thủ công theo thứ tự:

```powershell
# 1. Tạo database và tables
cat db/00_create_database.sql | docker exec -i btl3_mysql mysql -uroot
cat db/01_create_tables.sql | docker exec -i btl3_mysql mysql -uroot btl2_db

# 2. Tạo stored procedures
cat db/02_procedures.sql | docker exec -i btl3_mysql mysql -uroot btl2_db

# 3. Tạo functions
cat db/03_functions.sql | docker exec -i btl3_mysql mysql -uroot btl2_db

# 4. Insert dữ liệu mẫu
cat db/04_insert_data.sql | docker exec -i btl3_mysql mysql -uroot btl2_db

# 5. Tạo triggers
cat db/05_triggers.sql | docker exec -i btl3_mysql mysql -uroot btl2_db

# 6. Tạo indexes
cat db/06_indexes.sql | docker exec -i btl3_mysql mysql -uroot btl2_db
```

**Lưu ý**: Nếu dùng Git Bash trên Windows, thay `cat` bằng `Get-Content` trong PowerShell:
```powershell
Get-Content db/00_create_database.sql | docker exec -i btl3_mysql mysql -uroot
```

### Bước 6: Khởi động ứng dụng

```powershell
npm start
```

Hoặc:
```powershell
node app.js
```

Ứng dụng sẽ chạy tại: **http://localhost:3000**

## 🎯 Demo các tính năng BTL2

### Demo Triggers (Phần 2.2)

```powershell
# Demo 2.2.1: Trigger checkApplyVoucher
cat demo/demo_2.2.1.sql | docker exec -i btl3_mysql mysql -uroot btl2_db

# Demo 2.2.2: Trigger tự động tính Amount và snapshot Price
cat demo/demo_2.2.2.sql | docker exec -i btl3_mysql mysql -uroot btl2_db
```

### Demo Stored Procedures (Phần 2.3)

```powershell
cat demo/demo_2.3.sql | docker exec -i btl3_mysql mysql -uroot btl2_db
```

### Demo tổng hợp (Triggers + Procedures + Functions)

```powershell
cat db/07_test_demo.sql | docker exec -i btl3_mysql mysql -uroot btl2_db
```

## 📱 Tính năng chính

### 1. Đăng ký/Đăng nhập
- URL: `http://localhost:3000/register` và `http://localhost:3000/login`
- Validation: Email, số điện thoại, tuổi >= 10
- Authentication: JWT token

### 2. Quản lý Profile
- URL: `http://localhost:3000/profile`
- Cập nhật thông tin cá nhân
- Xóa tài khoản

### 3. Quản lý sản phẩm
- URL: `http://localhost:3000/products`
- Tìm kiếm, lọc theo Shop
- Xóa sản phẩm (cascade)

### 4. Báo cáo doanh thu
- URL: `http://localhost:3000/revenue`
- Tính doanh thu theo Shop, tháng, năm
- Sử dụng Function với CURSOR/LOOP

## 🗄️ Database Schema

### Các bảng chính:
- **Useraccount**: Quản lý người dùng
- **Buyer/Seller**: Phân loại người dùng
- **Shop**: Cửa hàng
- **Product/ProductVariation**: Sản phẩm
- **Order/OrderItem**: Đơn hàng
- **Voucher/ApplyVoucher**: Mã giảm giá
- **Payment**: Thanh toán

### Triggers:
1. **checkApplyVoucher**: Kiểm tra voucher hợp lệ (ExpiredDate, ConditionText)
2. **Amount calculation group**: 
   - `trg_SnapshotPrice_BeforeInsert`: Lưu giá tại thời điểm đặt hàng
   - `trg_UpdateAmount_OnItem_Insert/Update/Delete`: Tự động tính Order.Amount
   - `trg_UpdateAmount_OnFeeChange`: Cập nhật Amount khi đổi phí ship

### Stored Procedures:
- **CRUD User**: `sp_InsertUser`, `sp_UpdateUser`, `sp_DeleteUser`
- **CRUD Product**: `sp_InsertProduct`, `sp_UpdateProduct`, `sp_DeleteProduct`
- **SELECT queries**: 
  - `sp_GetHighValueBuyersWithAddresses`: Lấy khách hàng VIP
  - `sp_GetUnderperformingProducts`: Sản phẩm kém hiệu suất

### Functions:
- `fn_TinhDoanhThuShop(shopID, month, year)`: Tính doanh thu Shop
- `fn_XepHangThanhVien(buyerID)`: Xếp hạng thành viên

## 🧪 Test Account

### Tài khoản Admin
```
Email: admin1@gmail.com
Password: siu
```

## ⚙️ Cấu hình Docker

File `docker-compose.yml` đã cấu hình:
- MySQL 8.0
- Port: 3307 (host) → 3306 (container)
- Root password: rỗng (MYSQL_ALLOW_EMPTY_PASSWORD: "yes")
- Database: btl2_db
- Character set: utf8mb4

## 🛑 Dừng và dọn dẹp

### Dừng ứng dụng:
```powershell
# Trong terminal đang chạy Node.js: Ctrl + C
```

### Dừng Docker:
```powershell
docker-compose down
```

### Xóa toàn bộ dữ liệu (nếu cần reset):
```powershell
docker-compose down -v
```

## 📝 Ghi chú

- **Demo files có cleanup**: Các file trong `demo/` tự động xóa dữ liệu test sau khi chạy, không ảnh hưởng database chính
- **Encoding**: Database sử dụng utf8mb4, hỗ trợ tiếng Việt đầy đủ
- **PowerShell**: Nếu thấy ký tự ??? khi chạy demo, dùng MySQL Workbench hoặc Git Bash thay thế

## 🐛 Troubleshooting

### Lỗi: "Cannot connect to MySQL"
```powershell
# Kiểm tra Docker container
docker ps

# Khởi động lại container
docker-compose restart
```

### Lỗi: "Port 3307 already in use"
```powershell
# Tìm process đang dùng port
netstat -ano | findstr :3307

# Hoặc thay đổi port trong docker-compose.yml và .env
```

### Lỗi: "Unknown column" khi chạy demo
- Chạy lại file `01_create_tables.sql` để đảm bảo schema đúng
- Kiểm tra tên cột trong demo file

## 👥 Nhóm thực hiện

- **Thành viên 1**: [Tên]
- **Thành viên 2**: [Tên]
- **Thành viên 3**: [Tên]

## 📅 Thông tin BTL

- **Môn học**: Cơ sở dữ liệu
- **Học kỳ**: 2025-1
- **Deadline**: 6/12/2025

---

**© 2025 - Database BTL3 Project**
