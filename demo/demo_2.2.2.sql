-- 1. Chuẩn bị dữ liệu test
-- Giả sử UserID 6 là Seller, UserID 11 là Buyer (đã có từ script tạo bảng)
-- Tạo Shop và Sản phẩm mẫu để test
INSERT INTO Shop (SellerID, Name, DeliveryMethod) VALUES (6, 'Shop Test Trigger', 'GHTK');
SET @ShopID = LAST_INSERT_ID();

INSERT INTO Product (ShopID, Name, Description) VALUES (@ShopID, 'Áo Test', 'Test Trigger');
SET @Prod1 = LAST_INSERT_ID();

INSERT INTO ProductVariation (ProductID, VariationID, Type, Price, Stock)
VALUES (@Prod1, 1, 'Size L', 100000, 100); -- Giá gốc 100k

INSERT INTO Address (BuyerID, Detail, Name, PhoneNumber) VALUES (11, 'HCM', 'Test', '0909999999');
SET @AddrID = LAST_INSERT_ID();


-- 2. Bắt đầu Test
-- Step 1: Tạo đơn hàng (Ship 20k)
INSERT INTO `Order` (BuyerID, AddressID, Amount, Status, DeliveryFee)
VALUES (11, @AddrID, 0, 'Pending', 20000);
SET @OrderID = LAST_INSERT_ID();

-- Step 2: Mua 2 Áo (Giá 100k/áo) -> Tổng mong đợi: 2*100 + 20 = 220k
-- Không cần truyền UnitPrice, Trigger 'trg_SnapshotPrice_BeforeInsert' sẽ tự điền 100k
INSERT INTO OrderItem (OrderID, ProductID, VariationID, Quantity)
VALUES (@OrderID, @Prod1, 1, 2);

SELECT OrderID, Amount AS 'Kết quả Step 2 (Mong đợi 220000)' FROM `Order` WHERE OrderID = @OrderID;

-- Step 3: Shop tăng giá sản phẩm lên 500k
UPDATE ProductVariation SET Price = 500000 WHERE ProductID = @Prod1 AND VariationID = 1;

-- Kiểm tra đơn hàng cũ: Giá trị PHẢI KHÔNG ĐỔI (vẫn 220k)
SELECT OrderID, Amount AS 'Kết quả Step 3 (Vẫn là 220000)' FROM `Order` WHERE OrderID = @OrderID;

-- Step 4: Mua thêm 1 cái áo nữa vào đơn hàng cũ (Lúc này sẽ lấy giá mới 500k)
INSERT INTO OrderItem (OrderID, ProductID, VariationID, Quantity)
VALUES (@OrderID, @Prod1, 1, 1);

-- Tổng mong đợi: (2 cái cũ * 100k) + (1 cái mới * 500k) + 20k ship = 720k
SELECT OrderID, Amount AS 'Kết quả Step 4 (Mong đợi 720000)' FROM `Order` WHERE OrderID = @OrderID;

-- Step 5: Kiểm tra bảng OrderItem để thấy 2 mức giá khác nhau
SELECT ItemID, Quantity, UnitPrice FROM OrderItem WHERE OrderID = @OrderID;

-- ============================================================
-- CLEANUP - Xóa dữ liệu test
-- ============================================================
DELETE FROM OrderItem WHERE OrderID = @OrderID;
DELETE FROM `Order` WHERE OrderID = @OrderID;
DELETE FROM Address WHERE AddressID = @AddrID;
DELETE FROM ProductVariation WHERE ProductID = @Prod1;
DELETE FROM Product WHERE ProductID = @Prod1;
DELETE FROM Shop WHERE ShopID = @ShopID;

SELECT 'Demo hoàn thành và đã cleanup!' AS Status;