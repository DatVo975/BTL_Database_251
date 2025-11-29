USE btl2_db;

-- Xóa voucher demo cũ trước
DELETE FROM ApplyVoucher WHERE VoucherID IN (SELECT VoucherID FROM Voucher WHERE Name LIKE 'DEMO_SALE%');
DELETE FROM Voucher WHERE Name LIKE 'DEMO_SALE%';

-- Tạo Order mới
INSERT INTO `Order` (BuyerID, AddressID, Amount, Status, DeliveryFee) VALUES
(11, 1, 0, 'Pending', 30000);
SET @test_order = LAST_INSERT_ID();

-- Tạo Payment
INSERT INTO Payment (OrderID, Amount, Status, Method, PaidAt) VALUES
(@test_order, 125000, 'Pending', 'COD', NULL);

-- Tạo Voucher mới
INSERT INTO Voucher (Name, ExpiredDate, Number, Value, ConditionText) VALUES
('DEMO_SALE10', '2025-12-31', 100, 10000, 50000),
('DEMO_SALE20', '2024-12-31', 100, 20000, 100000),
('DEMO_SALE30', '2026-01-01', 50, 30000, 150000);

SET @voucher1 = (SELECT VoucherID FROM Voucher WHERE Name = 'DEMO_SALE10' ORDER BY VoucherID DESC LIMIT 1);
SET @voucher2 = (SELECT VoucherID FROM Voucher WHERE Name = 'DEMO_SALE20' ORDER BY VoucherID DESC LIMIT 1);
SET @voucher3 = (SELECT VoucherID FROM Voucher WHERE Name = 'DEMO_SALE30' ORDER BY VoucherID DESC LIMIT 1);

-- Test 1: Hợp lệ
INSERT INTO ApplyVoucher VALUES (@test_order, @voucher1, NOW());
SELECT 'Kết quả:' AS '', OrderID, VoucherID, AppliedAt FROM ApplyVoucher WHERE OrderID = @test_order;

-- Test 2: Quá thời hạn (uncomment để test)
-- INSERT INTO ApplyVoucher VALUES (@test_order, @voucher2, NOW());

-- Test 3: Chưa đạt điều kiện (uncomment để test)
-- INSERT INTO ApplyVoucher VALUES (@test_order, @voucher3, NOW());

-- ============================================================
-- CLEANUP - Xóa dữ liệu test
-- ============================================================
DELETE FROM ApplyVoucher WHERE OrderID = @test_order;
DELETE FROM Payment WHERE OrderID = @test_order;
DELETE FROM `Order` WHERE OrderID = @test_order;
DELETE FROM Voucher WHERE Name LIKE 'DEMO_SALE%';

SELECT 'Demo hoàn thành và đã cleanup!' AS Status;