-- ============================================================
-- PHẦN 2.2: TRIGGERS
-- ============================================================
USE btl2_db;

-- ============================================================
-- TRIGGER 1: Kiểm tra thời hạn và điều kiện áp dụng Voucher
-- ============================================================

DROP TRIGGER IF EXISTS checkApplyVoucher;

DELIMITER $$

CREATE TRIGGER checkApplyVoucher
BEFORE INSERT ON ApplyVoucher
FOR EACH ROW
BEGIN
    DECLARE v_expired DATE;
    DECLARE v_condition DECIMAL(12,2);
    DECLARE v_amount DECIMAL(12,2);

    SELECT ExpiredDate, ConditionText INTO v_expired, v_condition
    FROM Voucher
    WHERE VoucherID = NEW.VoucherID;
    -- Kiểm tra thời hạn
    IF v_expired < NEW.AppliedAt THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Voucher đã hết hiệu lực';
    END IF;
    -- Kiểm tra điều kiện 
    SELECT Amount INTO v_amount
    FROM Payment
    WHERE OrderID = NEW.OrderID;
    IF v_condition > v_amount THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Đơn hàng chưa đạt điều kiện để áp dụng Voucher';
    END IF;

END$$

DELIMITER ;

-- ============================================================
-- TRIGGER 2: Thuộc tính dẫn xuất 'Amount' của Order
-- ============================================================
/*
    Ý nghĩa: Tổng giá trị của đơn hàng(Amount) = Tổng tiền các món hàng(Price của các OrderItem) + Phí ship(DeliveryFee)
*/
/*
    Xác định các thao tác DML ảnh hưởng đến 'Amount':

    - INSERT vào OrderItem: Khách mua thêm hàng -> Tổng tiền hàng tăng
    - UPDATE trên OrderItem: Khách đổi số lượng hàng (quantity) -> Thay đổi đơn giá
    - DELETE ở OrderItem: Khách xóa bớt đơn hàng, Admin hủy hàng (Hiếm gặp) -> Tổng tiền hàng giảm
    - UPDATE trên Order: Phí vận chuyển thay đổi (do thay đổi địa chỉ, thay đổi đơn vị vận chuyển,...) -> Tổng tiền hàng thay đổi
*/

DELIMITER //

-- --------------------------------------------------------------------------
-- TRIGGER 2.1: SNAPSHOT GIÁ
-- Tác dụng: Khi thêm hàng vào giỏ, tự động lấy giá hiện tại lưu vào OrderItem
-- để sau này Shop có tăng giá thì đơn cũ không bị ảnh hưởng.
-- --------------------------------------------------------------------------

DROP TRIGGER IF EXISTS trg_SnapshotPrice_BeforeInsert //
CREATE TRIGGER trg_SnapshotPrice_BeforeInsert
BEFORE INSERT ON OrderItem
FOR EACH ROW
BEGIN
    DECLARE current_price DECIMAL(12,2);

    -- Nếu người dùng không truyền UnitPrice hoặc truyền bằng 0
    IF NEW.UnitPrice IS NULL OR NEW.UnitPrice = 0 THEN
        -- Lấy giá từ kho (ProductVariation)
        SELECT Price INTO current_price
        FROM ProductVariation
        WHERE ProductID = NEW.ProductID AND VariationID = NEW.VariationID;

        -- Gán vào UnitPrice của OrderItem
        SET NEW.UnitPrice = current_price;
    END IF;
END //

-- --------------------------------------------------------------------------
-- TRIGGER 2.2: CẬP NHẬT AMOUNT KHI THAY ĐỔI ITEM (Dùng UnitPrice)
-- --------------------------------------------------------------------------

-- 2.2.1 Khi Thêm món (INSERT)
DROP TRIGGER IF EXISTS trg_UpdateAmount_OnItem_Insert //
CREATE TRIGGER trg_UpdateAmount_OnItem_Insert
AFTER INSERT ON OrderItem
FOR EACH ROW
BEGIN
    DECLARE total_items DECIMAL(12,2);
    DECLARE ship_fee DECIMAL(12,2);

    -- Tính tổng tiền dựa trên OrderItem (Quantity * UnitPrice)
    SELECT COALESCE(SUM(Quantity * UnitPrice), 0) INTO total_items
    FROM OrderItem
    WHERE OrderID = NEW.OrderID;

    SELECT DeliveryFee INTO ship_fee FROM `Order` WHERE OrderID = NEW.OrderID;

    UPDATE `Order` SET Amount = total_items + ship_fee WHERE OrderID = NEW.OrderID;
END //

-- 2.2.2 Khi Sửa món (UPDATE)
DROP TRIGGER IF EXISTS trg_UpdateAmount_OnItem_Update //
CREATE TRIGGER trg_UpdateAmount_OnItem_Update
AFTER UPDATE ON OrderItem
FOR EACH ROW
BEGIN
    DECLARE total_items DECIMAL(12,2);
    DECLARE ship_fee DECIMAL(12,2);

    -- Chỉ tính lại nếu số lượng hoặc đơn giá thay đổi
    IF NEW.Quantity <> OLD.Quantity OR NEW.UnitPrice <> OLD.UnitPrice THEN
        SELECT COALESCE(SUM(Quantity * UnitPrice), 0) INTO total_items
        FROM OrderItem
        WHERE OrderID = NEW.OrderID;

        SELECT DeliveryFee INTO ship_fee FROM `Order` WHERE OrderID = NEW.OrderID;

        UPDATE `Order` SET Amount = total_items + ship_fee WHERE OrderID = NEW.OrderID;
    END IF;
END //

-- 2.2.3 Khi Xóa món (DELETE)
DROP TRIGGER IF EXISTS trg_UpdateAmount_OnItem_Delete //
CREATE TRIGGER trg_UpdateAmount_OnItem_Delete
AFTER DELETE ON OrderItem
FOR EACH ROW
BEGIN
    DECLARE total_items DECIMAL(12,2);
    DECLARE ship_fee DECIMAL(12,2);

    SELECT COALESCE(SUM(Quantity * UnitPrice), 0) INTO total_items
    FROM OrderItem
    WHERE OrderID = OLD.OrderID;

    SELECT DeliveryFee INTO ship_fee FROM `Order` WHERE OrderID = OLD.OrderID;

    UPDATE `Order` SET Amount = total_items + ship_fee WHERE OrderID = OLD.OrderID;
END //

-- --------------------------------------------------------------------------
-- TRIGGER 2.3: CẬP NHẬT AMOUNT KHI THAY ĐỔI SHIP
-- --------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_UpdateAmount_OnFeeChange //
CREATE TRIGGER trg_UpdateAmount_OnFeeChange
BEFORE UPDATE ON `Order`
FOR EACH ROW
BEGIN
    IF NEW.DeliveryFee <> OLD.DeliveryFee THEN
        SET NEW.Amount = (OLD.Amount - OLD.DeliveryFee) + NEW.DeliveryFee;
    END IF;
END //

DELIMITER ;

