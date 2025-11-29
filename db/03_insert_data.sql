-- ============================================================
-- PHẦN 1.2: INSERT DỮ LIỆU MẪU
-- ============================================================
USE btl2_db;

-- Lưu ý: Gọi sp_InsertUser sẽ được tạo sau, tạm thời INSERT trực tiếp

-- Disable tạm ForeignKey check để insert dữ liệu
SET FOREIGN_KEY_CHECKS = 0;

-- ============================================================
-- INSERT Useraccount (15 users)
-- ============================================================
-- 5 ADMIN (UserID 1–5)
CALL sp_InsertUser('Nguyễn Minh An',     'admin1@gmail.com', '$2b$10$2N9BFlUc85qzv4X0PaIvxOf9.2FH3laM2w5Gwp.BPXKgxFHZSO7tG', 'Male',   '0900000001', '1989-01-01');
CALL sp_InsertUser('Trần Hoài Bảo',      'admin2@gmail.com', 'hash', 'Male',   '0900000002', '1988-02-02');
CALL sp_InsertUser('Lê Thị Cẩm Tú',      'admin3@gmail.com', 'hash', 'Female', '0900000003', '1987-03-03');
CALL sp_InsertUser('Phạm Quang Dũng',    'admin4@gmail.com', 'hash', 'Male',   '0900000004', '1986-04-04');
CALL sp_InsertUser('Đỗ Gia Hân',         'admin5@gmail.com', 'hash', 'Female', '0900000005', '1985-05-05');

-- 5 SELLER (UserID 6–10)
CALL sp_InsertUser('Nguyễn Thanh Long',  'seller1@gmail.com', 'hash', 'Male',   '0910000001', '1990-01-01');
CALL sp_InsertUser('Phan Minh Thư',      'seller2@gmail.com', 'hash', 'Female', '0910000002', '1991-02-02');
CALL sp_InsertUser('Lê Quốc Huy',        'seller3@gmail.com', 'hash', 'Male',   '0910000003', '1992-03-03');
CALL sp_InsertUser('Võ Ngọc Trâm',       'seller4@gmail.com', 'hash', 'Female', '0910000004', '1993-04-04');
CALL sp_InsertUser('Bùi Đức Toàn',       'seller5@gmail.com', 'hash', 'Male',   '0910000005', '1994-05-05');

-- 5 BUYER (UserID 11–15)
CALL sp_InsertUser('Nguyễn Thị Mai',     'buyer1@gmail.com', 'hash', 'Female', '0920000001', '2000-01-01');
CALL sp_InsertUser('Trần Văn Khải',      'buyer2@gmail.com', 'hash', 'Male',   '0920000002', '2001-02-02');
CALL sp_InsertUser('Hoàng Gia Phúc',     'buyer3@gmail.com', 'hash', 'Male',   '0920000003', '2002-03-03');
CALL sp_InsertUser('Lý Mỹ Uyên',         'buyer4@gmail.com', 'hash', 'Female', '0920000004', '2003-04-04');
CALL sp_InsertUser('Đặng Huỳnh Nhung',   'buyer5@gmail.com', 'hash', 'Female', '0920000005', '2004-05-05');

-- ============================================================
-- INSERT Adminaccount
-- ============================================================
INSERT INTO Adminaccount (AdminID, Fullname) VALUES
(1, 'Nguyễn Minh An'),
(2, 'Trần Hoài Bảo'),
(3, 'Lê Thị Cẩm Tú'),
(4, 'Phạm Quang Dũng'),
(5, 'Đỗ Gia Hân');

-- ============================================================
-- INSERT Seller
-- ============================================================
INSERT INTO Seller (UserID, TaxNum) VALUES
(6, 'TAX001'),
(7, 'TAX002'),
(8, 'TAX003'),
(9, 'TAX004'),
(10, 'TAX005');

-- ============================================================
-- INSERT Buyer
-- ============================================================
INSERT INTO Buyer (UserID, BonusPoint) VALUES
(11, 100),
(12, 150),
(13, 200),
(14, 250),
(15, 300);

-- ============================================================
-- INSERT Event (tạo trước vì Product FK Event)
-- ============================================================
INSERT INTO `Event` (AdminID, Name, StartAt, EndAt) VALUES
(1,'Sale T1','2025-01-01 00:00:00','2025-01-31 23:59:59'),
(2,'Sale T2','2025-02-01 00:00:00','2025-02-28 23:59:59'),
(3,'Sale Hè','2025-06-01 00:00:00','2025-06-30 23:59:59'),
(4,'Flash Sale','2025-03-10 00:00:00','2025-03-15 23:59:59'),
(5,'Sale Thu','2025-09-01 00:00:00','2025-09-30 23:59:59'),
(1,'Giảm Giá Noel','2025-12-01 00:00:00','2025-12-25 23:59:59'),
(2,'Back To School','2025-08-01 00:00:00','2025-08-20 23:59:59'),
(3,'Black Friday','2025-11-20 00:00:00','2025-11-30 23:59:59'),
(4,'Cyber Monday','2025-12-01 00:00:00','2025-12-02 23:59:59'),
(5,'Tết Sale','2025-01-20 00:00:00','2025-01-30 23:59:59');

-- ============================================================
-- INSERT Shop
-- ============================================================
INSERT INTO Shop (SellerID, Name, DeliveryMethod, TotalRevenue, CancelledOrderCount) VALUES
(6,  'Long Mobile Store',         'GHTK', 0, 0),
(7,  'Thư Cosmetics & Beauty',    'VNPost', 0, 0),
(8,  'Huy Computer Parts',        'J&T', 0, 0),
(9,  'Trâm Fashion Boutique',     'GrabExpress', 0, 0),
(10, 'Toàn Home Accessories',     'ShopeeExpress', 0, 0);

-- ============================================================
-- INSERT ShopFollower
-- ============================================================
INSERT INTO ShopFollower VALUES
(1, 11, NOW()),
(1, 12, NOW()),
(2, 13, NOW()),
(2, 14, NOW()),
(3, 15, NOW()),
(3, 11, NOW()),
(4, 12, NOW()),
(4, 13, NOW()),
(5, 14, NOW()),
(5, 15, NOW());

-- ============================================================
-- INSERT Category (10 categories)
-- ============================================================
INSERT INTO Category (ClassifyCategoryID, Name, ProductCount) VALUES
(NULL, 'Điện thoại', 0),
(NULL, 'Laptop', 0),
(NULL, 'Phụ kiện', 0),
(1, 'Android', 0),
(1, 'iPhone', 0),
(2, 'Gaming', 0),
(2, 'Văn phòng', 0),
(3, 'Tai nghe', 0),
(3, 'Cáp sạc', 0),
(3, 'Sạc dự phòng', 0);

-- ============================================================
-- INSERT Product (10 products)
-- ============================================================
INSERT INTO Product (ShopID, SaleOffEventID, Name, Description, SoldCount, CancelledCount) VALUES
(1, 1, 'iPhone 15', 'Điện thoại cao cấp Apple', 5, 0),
(1, 1, 'Samsung S23', 'Android flagship Samsung', 3, 1),
(2, 2, 'Son 3CE', 'Mỹ phẩm làm đẹp 3CE', 8, 0),
(2, 2, 'Kem dưỡng HadaLabo', 'Dưỡng ẩm Hada Labo', 6, 0),
(3, 3, 'Chuột Logitech G102', 'Chuột gaming Logitech', 4, 0),
(3, 3, 'Bàn phím DareU EK87', 'Bàn phím cơ DareU', 2, 1),
(4, 4, 'Áo thun Unisex', 'Thời trang nam nữ', 7, 0),
(4, 4, 'Đầm công sở', 'Thời trang nữ cao cấp', 5, 0),
(5, 5, 'Đèn ngủ thông minh', 'Đèn cảm biến IoT', 3, 0),
(5, 5, 'Bình giữ nhiệt Lock&Lock', 'Tiện ích gia đình', 6, 0);

-- ============================================================
-- INSERT ProductCategory (10 rows)
-- ============================================================
INSERT INTO ProductCategory VALUES
(1, 5),  -- iPhone 15 → iPhone
(2, 4),  -- Samsung S23 → Android
(3, 3),  -- Son → phụ kiện
(4, 3),  -- Kem dưỡng → phụ kiện
(5, 7),  -- Chuột → văn phòng
(6, 6),  -- Bàn phím → gaming
(7, 3),  -- Áo → phụ kiện
(8, 3),  -- Đầm → phụ kiện
(9, 3),  -- Đèn → phụ kiện
(10, 3); -- Bình → phụ kiện

-- ============================================================
-- INSERT ProductVariation (10 variations)
-- ============================================================
INSERT INTO ProductVariation VALUES
(1, 1, '128GB', 23000000, 50),
(2, 1, '8GB RAM', 18000000, 40),
(3, 1, '3.5g', 150000, 200),
(4, 1, '50ml', 250000, 150),
(5, 1, 'Black', 450000, 100),
(6, 1, 'Red Switch', 790000, 80),
(7, 1, 'Size M', 120000, 60),
(8, 1, 'Size S', 250000, 70),
(9, 1, 'White', 180000, 90),
(10, 1, '500ml', 320000, 110);

-- ============================================================
-- INSERT Address
-- ============================================================
INSERT INTO Address (BuyerID, Detail, Name, PhoneNumber) VALUES
(11, 'Hà Nội', 'Mai', '0920000001'),
(11, 'TPHCM', 'Mai', '0920000001'),
(12, 'Đà Nẵng', 'Khải', '0920000002'),
(12, 'Huế', 'Khải', '0920000002'),
(13, 'Hải Phòng', 'Phúc', '0920000003'),
(13, 'Quảng Ninh', 'Phúc', '0920000003'),
(14, 'Cần Thơ', 'Uyên', '0920000004'),
(14, 'Bình Dương', 'Uyên', '0920000004'),
(15, 'Nha Trang', 'Nhung', '0920000005'),
(15, 'Đà Lạt', 'Nhung', '0920000005');

-- ============================================================
-- INSERT Order (10 orders)
-- ============================================================
INSERT INTO `Order` (BuyerID, AddressID, Amount, Status, DeliveryFee) VALUES
(11, 1, 0, 'Pending', 30000),
(11, 2, 0, 'Completed', 30000),
(12, 3, 0, 'Pending', 30000),
(12, 4, 0, 'Delivered', 30000),
(13, 5, 0, 'Pending', 25000),
(13, 6, 0, 'Cancelled', 0),
(14, 7, 0, 'Shipping', 20000),
(14, 8, 0, 'Completed', 20000),
(15, 9, 0, 'Pending', 25000),
(15, 10, 0, 'Completed', 25000);

-- ============================================================
-- INSERT OrderItem (10 items)
-- ============================================================
INSERT INTO OrderItem (OrderID, ProductID, VariationID, Quantity, UnitPrice) VALUES
(1, 1, 1, 1, 23000000),
(2, 2, 1, 1, 18000000),
(3, 3, 1, 2, 150000),
(4, 4, 1, 1, 250000),
(5, 5, 1, 1, 450000),
(6, 6, 1, 1, 790000),
(7, 7, 1, 2, 120000),
(8, 8, 1, 1, 250000),
(9, 9, 1, 1, 180000),
(10, 10, 1, 1, 320000);

-- ============================================================
-- INSERT Payment (10 payments)
-- ============================================================
INSERT INTO Payment (OrderID, Amount, Status, Method, PaidAt) VALUES
(1, 23000000, 'Paid', 'Momo', NOW()),
(2, 18000000, 'Paid', 'ZaloPay', NOW()),
(3, 300000, 'Pending', 'COD', NULL),
(4, 250000, 'Paid', 'Bank', NOW()),
(5, 450000, 'Paid', 'Momo', NOW()),
(6, 790000, 'Failed', 'Momo', NOW()),
(7, 240000, 'Pending', 'COD', NULL),
(8, 250000, 'Paid', 'Bank', NOW()),
(9, 180000, 'Pending', 'COD', NULL),
(10, 320000, 'Paid', 'ZaloPay', NOW());

-- ============================================================
-- INSERT Review (10 reviews)
-- ============================================================
INSERT INTO Review (ItemID, Rating, Spec) VALUES
(1, 5, 'Rất tốt'),
(2, 4, 'Ổn'),
(3, 5, 'Đáng tiền'),
(4, 5, 'Sản phẩm chất lượng'),
(5, 4, 'Mua lần 2 khá ổn'),
(6, 4, 'Giao nhanh'),
(7, 4, 'Hàng đẹp'),
(8, 5, 'Khuyên dùng'),
(9, 5, 'Tuyệt vời'),
(10, 4, 'Ổn định');

-- ============================================================
-- INSERT Voucher (10 vouchers)
-- ============================================================
INSERT INTO Voucher (Name, ExpiredDate, Number, Value, ConditionText) VALUES
('SALE10', '2025-12-31', 100, 10000, 50000),
('SALE20', '2025-12-31', 100, 20000, 100000),
('SALE30', '2026-01-01', 50, 30000, 150000),
('FREESHIP', '2025-06-30', 500, 30000, 0),
('VIP50', '2025-11-30', 20, 50000, 300000),
('VIP70', '2025-12-31', 10, 70000, 400000),
('FLASH5', '2025-08-20', 200, 5000, 30000),
('FLASH10', '2025-09-20', 200, 10000, 50000),
('FLASH15', '2025-10-20', 200, 15000, 75000),
('EXTRA20', '2025-12-20', 100, 20000, 200000);

-- ============================================================
-- INSERT VoucherOfBuyer
-- ============================================================
INSERT INTO VoucherOfBuyer VALUES
(11, 1, NOW()), (11, 2, NOW()),
(12, 3, NOW()), (12, 4, NOW()),
(13, 5, NOW()), (13, 6, NOW()),
(14, 7, NOW()), (14, 8, NOW()),
(15, 9, NOW()), (15, 10, NOW());

-- ============================================================
-- INSERT ApplyVoucher
-- ============================================================
INSERT INTO ApplyVoucher VALUES
(1, 1, NOW()),
(2, 2, NOW()),
(3, 3, NOW()),
(4, 4, NOW()),
(5, 5, NOW()),
(6, 6, NOW()),
(7, 7, NOW()),
(8, 8, NOW()),
(9, 9, NOW()),
(10, 10, NOW());

-- ============================================================
-- INSERT ParticipationEvent
-- ============================================================
INSERT INTO ParticipationEvent VALUES
(11, 1, NOW()), (11, 2, NOW()),
(12, 3, NOW()), (12, 4, NOW()),
(13, 5, NOW()), (13, 6, NOW()),
(14, 7, NOW()), (14, 8, NOW()),
(15, 9, NOW()), (15, 10, NOW());

-- ============================================================
-- INSERT BonusPoint
-- ============================================================
INSERT INTO BonusPoint VALUES
(1, 10), (2, 20), (3, 30), (4, 25), (5, 40),
(6, 50), (7, 60), (8, 70), (9, 80), (10, 90);

-- ============================================================
-- INSERT SaleOff
-- ============================================================
INSERT INTO SaleOff VALUES
(1, 'Giảm 10%', '2025-01-01 00:00:00', '2025-01-31 23:59:59'),
(2, 'Giảm 20%', '2025-02-01 00:00:00', '2025-02-28 23:59:59'),
(3, 'Giảm 30%', '2025-06-01 00:00:00', '2025-06-30 23:59:59'),
(4, 'Flash -40%', '2025-03-10 00:00:00', '2025-03-15 23:59:59'),
(5, 'Sale Thu -25%', '2025-09-01 00:00:00', '2025-09-30 23:59:59'),
(6, 'Noel -35%', '2025-12-01 00:00:00', '2025-12-25 23:59:59'),
(7, 'Back School -15%', '2025-08-01 00:00:00', '2025-08-20 23:59:59'),
(8, 'BF -50%', '2025-11-20 00:00:00', '2025-11-30 23:59:59'),
(9, 'CM -30%', '2025-12-01 00:00:00', '2025-12-02 23:59:59'),
(10, 'Tết -20%', '2025-01-20 00:00:00', '2025-01-30 23:59:59');

-- ============================================================
-- INSERT CartItem
-- ============================================================
INSERT INTO CartItem (BuyerID, ProductID, VariationID, Quantity) VALUES
(11, 1, 1, 1),
(11, 3, 1, 2),
(12, 2, 1, 1),
(12, 5, 1, 1),
(13, 4, 1, 3),
(13, 6, 1, 1),
(14, 7, 1, 2),
(14, 9, 1, 1),
(15, 8, 1, 1),
(15, 10, 1, 2);

-- ============================================================
-- INSERT ReportTicket
-- ============================================================
INSERT INTO ReportTicket (AdminID, UserID, Status, Detail) VALUES
(1, 6, 'Open', 'Kiểm tra gian hàng nghi ngờ.'),
(2, 7, 'InProgress', 'Xác minh thông tin thuế.'),
(3, 8, 'Closed', 'Hoàn tất kiểm tra sản phẩm.'),
(4, 9, 'Open', 'Nghi vấn vi phạm chính sách.'),
(5, 10, 'Open', 'Nghi ngờ spam sản phẩm.'),
(1, 11, 'InProgress', 'Người mua khiếu nại giao hàng.'),
(2, 12, 'Closed', 'Đã giải quyết khiếu nại.'),
(3, 13, 'Open', 'Phản ánh chất lượng hàng hóa.'),
(4, 14, 'InProgress', 'Đang liên hệ người bán.'),
(5, 15, 'Closed', 'Khiếu nại hoàn tất.');

SET FOREIGN_KEY_CHECKS = 1;

