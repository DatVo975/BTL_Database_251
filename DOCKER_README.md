# Database BTL3 - Docker Setup

Dự án Database E-Commerce với Node.js, Express, MySQL và Docker.

## 🚀 Cách chạy với Docker

### Yêu cầu:
- Docker Desktop đã cài đặt
- Docker Compose (đi kèm Docker Desktop)

### Bước 1: Build và khởi động containers

```powershell
# Khởi động tất cả services (MySQL + Node.js App)
docker-compose up -d

# Xem logs
docker-compose logs -f app
```

### Bước 2: Truy cập ứng dụng

Mở trình duyệt: **http://localhost:3000**

### Bước 3: Dừng containers

```powershell
# Dừng và xóa containers
docker-compose down

# Dừng và xóa cả volumes (reset database)
docker-compose down -v
```

---

## 📦 Cấu trúc Docker

### Services:

1. **mysql** (Port 3306)
   - MySQL 8.0
   - Database: `btl2_db`
   - Auto-import SQL files từ thư mục `db/`

2. **app** (Port 3000)
   - Node.js 20
   - Express server
   - Hot reload với nodemon

---

## 🔧 Lệnh hữu ích

### Kết nối MySQL trong Docker:

```powershell
docker exec -it btl3_mysql mysql -u root btl2_db
```

### Chạy lại SQL scripts:

```powershell
# Copy file vào container
docker cp db/01_create_tables.sql btl3_mysql:/tmp/

# Execute trong container
docker exec -i btl3_mysql mysql -u root btl2_db < db/01_create_tables.sql
```

### Rebuild app sau khi sửa code:

```powershell
docker-compose restart app
```

### Xem logs real-time:

```powershell
# App logs
docker-compose logs -f app

# MySQL logs
docker-compose logs -f mysql
```

---

## 🛠️ Cách chạy KHÔNG dùng Docker

### Bước 1: Cài Node.js
Download từ: https://nodejs.org/

### Bước 2: Cài dependencies

```powershell
npm install
```

### Bước 3: Setup MySQL

Chạy các file SQL trong thư mục `db/` theo thứ tự:
1. `01_create_tables.sql`
2. `04_user_procedures.sql`
3. `02_insert_data.sql`
4. `03_stored_procedures.sql`
5. `05_triggers.sql`
6. `06_functions.sql`

### Bước 4: Chạy ứng dụng

```powershell
npm run dev
```

Truy cập: http://localhost:3000

---

## 📁 Cấu trúc thư mục

```
Database_BTL3/
├── db/                    # SQL scripts
├── public/                # CSS, images
├── views/                 # EJS templates
├── app.js                 # Express server
├── package.json
├── Dockerfile
├── docker-compose.yml
├── .env                   # Config cho local
└── .env.docker            # Config cho Docker
```

---

## 🎯 Tính năng

### Phần 1: Database (10 điểm)
- ✅ 24 bảng với constraints đầy đủ
- ✅ 120+ dòng dữ liệu mẫu

### Phần 2: Procedures, Triggers, Functions (10 điểm)
- ✅ 7 Stored Procedures (CRUD + SELECT)
- ✅ 8 Triggers (Stock, Amount, Revenue, Voucher validation)
- ✅ 2 Functions (Revenue calculation, Member ranking)

### Phần 3: Ứng dụng Web (10 điểm)
- ✅ Đăng ký/Đăng nhập (JWT authentication)
- ✅ Tìm kiếm sản phẩm yếu thế
- ✅ Báo cáo doanh thu Shop

---

## 🐛 Troubleshooting

### Lỗi: Port 3306 đã được sử dụng
```powershell
# Dừng MySQL local trước
net stop MySQL80

# Hoặc đổi port trong docker-compose.yml:
ports:
  - "3307:3306"
```

### Lỗi: Database không tự động tạo
```powershell
# Xóa volume và rebuild
docker-compose down -v
docker-compose up -d --build
```

### Lỗi: App không kết nối được MySQL
```powershell
# Kiểm tra MySQL đã sẵn sàng
docker exec btl3_mysql mysqladmin ping -h localhost

# Tăng thời gian sleep trong docker-compose.yml (dòng command)
command: sh -c "sleep 60 && npm run dev"
```

---

## 📞 Hỗ trợ

Nếu gặp vấn đề, kiểm tra logs:
```powershell
docker-compose logs
```
