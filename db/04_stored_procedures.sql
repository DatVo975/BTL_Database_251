USE btl2_db;

DELIMITER //

-- ============================================================
-- PHẦN 2.1 & 2.3: STORED PROCEDURES
-- ============================================================

-- ============================================================
-- PHẦN 2.1: THỦ TỤC THÊM/SỬA/XÓA - Bảng PRODUCT
-- ============================================================
-- THỦ TỤC THÊM SẢN PHẨM (INSERT)
-- Kiểm tra:
-- - ShopID tồn tại
-- - Name không trống
-- - Description không trống
-- - SaleOffEventID nếu có phải tồn tại trong Event


DROP PROCEDURE IF EXISTS sp_InsertProduct;
CREATE PROCEDURE sp_InsertProduct(
    IN p_ShopID BIGINT,
    IN p_SaleOffEventID BIGINT,
    IN p_Name VARCHAR(200),
    IN p_Description TEXT,
    OUT p_ErrorCode INT,
    OUT p_ErrorMessage VARCHAR(255)
)
proc_label: BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET p_ErrorCode = -1;
        SET p_ErrorMessage = 'Database error occurred';
        ROLLBACK;
    END;
    
    SET p_ErrorCode = 0;
    SET p_ErrorMessage = '';
    
    START TRANSACTION;
    
    -- Kiểm tra ShopID tồn tại
    IF NOT EXISTS (SELECT 1 FROM Shop WHERE ShopID = p_ShopID) THEN
        SET p_ErrorCode = 1;
        SET p_ErrorMessage = 'Lỗi: ShopID không tồn tại trong hệ thống.';
        ROLLBACK;
        LEAVE proc_label;
    END IF;
    
    -- Kiểm tra Name không trống
    IF p_Name IS NULL OR TRIM(p_Name) = '' THEN
        SET p_ErrorCode = 2;
        SET p_ErrorMessage = 'Lỗi: Tên sản phẩm không được để trống.';
        ROLLBACK;
        LEAVE proc_label;
    END IF;
    
    -- Kiểm tra Description không trống
    IF p_Description IS NULL OR TRIM(p_Description) = '' THEN
        SET p_ErrorCode = 3;
        SET p_ErrorMessage = 'Lỗi: Mô tả sản phẩm không được để trống.';
        ROLLBACK;
        LEAVE proc_label;
    END IF;
    
    -- Kiểm tra SaleOffEventID nếu có
    IF p_SaleOffEventID IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM Event WHERE EventID = p_SaleOffEventID) THEN
            SET p_ErrorCode = 4;
            SET p_ErrorMessage = 'Lỗi: EventID cho SaleOff không tồn tại.';
            ROLLBACK;
            LEAVE proc_label;
        END IF;
    END IF;
    
    -- Insert Product
    INSERT INTO Product (ShopID, SaleOffEventID, Name, Description, SoldCount, CancelledCount)
    VALUES (p_ShopID, p_SaleOffEventID, p_Name, p_Description, 0, 0);
    
    SET p_ErrorCode = 0;
    SET p_ErrorMessage = 'Thêm sản phẩm thành công.';
    
    COMMIT;
END//

-- THỦ TỤC SỬA SẢN PHẨM (UPDATE)
-- Kiểm tra:
-- - ProductID tồn tại
-- - Name không trống
-- - SaleOffEventID nếu có phải tồn tại
DROP PROCEDURE IF EXISTS sp_UpdateProduct;
CREATE PROCEDURE sp_UpdateProduct(
    IN p_ProductID BIGINT,
    IN p_Name VARCHAR(200),
    IN p_Description TEXT,
    IN p_SaleOffEventID BIGINT,
    OUT p_ErrorCode INT,
    OUT p_ErrorMessage VARCHAR(255)
)
proc_label: BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET p_ErrorCode = -1;
        SET p_ErrorMessage = 'Database error occurred';
        ROLLBACK;
    END;
    
    SET p_ErrorCode = 0;
    SET p_ErrorMessage = '';
    
    START TRANSACTION;
    
    -- Kiểm tra ProductID tồn tại
    IF NOT EXISTS (SELECT 1 FROM Product WHERE ProductID = p_ProductID) THEN
        SET p_ErrorCode = 1;
        SET p_ErrorMessage = 'Lỗi: Sản phẩm không tồn tại.';
        ROLLBACK;
        LEAVE proc_label;
    END IF;
    
    -- Kiểm tra Name không trống
    IF p_Name IS NULL OR TRIM(p_Name) = '' THEN
        SET p_ErrorCode = 2;
        SET p_ErrorMessage = 'Lỗi: Tên sản phẩm không được để trống.';
        ROLLBACK;
        LEAVE proc_label;
    END IF;
    
    -- Kiểm tra SaleOffEventID nếu có
    IF p_SaleOffEventID IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM Event WHERE EventID = p_SaleOffEventID) THEN
            SET p_ErrorCode = 3;
            SET p_ErrorMessage = 'Lỗi: EventID cho SaleOff không tồn tại.';
            ROLLBACK;
            LEAVE proc_label;
        END IF;
    END IF;
    
    -- Update Product
    UPDATE Product 
    SET Name = p_Name,
        Description = p_Description,
        SaleOffEventID = p_SaleOffEventID
    WHERE ProductID = p_ProductID;
    
    SET p_ErrorCode = 0;
    SET p_ErrorMessage = 'Cập nhật sản phẩm thành công.';
    
    COMMIT;
END//

-- THỦ TỤC XÓA SẢN PHẨM (DELETE)
-- Kiểm tra:
-- - ProductID tồn tại
-- - Sản phẩm không có đơn hàng hoặc chỉ có đơn hàng bị hủy
-- Mục đích: Chỉ xóa sản phẩm khi nó không được bán hoặc chỉ bị hủy
DROP PROCEDURE IF EXISTS sp_DeleteProduct;
CREATE PROCEDURE sp_DeleteProduct(
    IN p_ProductID BIGINT,
    OUT p_ErrorCode INT,
    OUT p_ErrorMessage VARCHAR(255)
)
proc_label: BEGIN
    DECLARE v_OrderCount INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET p_ErrorCode = -1;
        SET p_ErrorMessage = 'Database error occurred';
        ROLLBACK;
    END;
    
    SET p_ErrorCode = 0;
    SET p_ErrorMessage = '';
    
    START TRANSACTION;
    
    -- Kiểm tra ProductID tồn tại
    IF NOT EXISTS (SELECT 1 FROM Product WHERE ProductID = p_ProductID) THEN
        SET p_ErrorCode = 1;
        SET p_ErrorMessage = 'Lỗi: Sản phẩm không tồn tại.';
        ROLLBACK;
        LEAVE proc_label;
    END IF;
    
    -- Kiểm tra có đơn hàng chưa hoàn tất
    -- Không cho phép xóa nếu có đơn hàng ĐANG GIAO HÀNG hoặc CHƯA THANH TOÁN
    SELECT COUNT(*) INTO v_OrderCount
    FROM OrderItem oi
    JOIN `Order` o ON oi.OrderID = o.OrderID
    WHERE oi.ProductID = p_ProductID 
      AND o.Status IN ('Pending', 'Shipping', 'Delivered');
    
    IF v_OrderCount > 0 THEN
        SET p_ErrorCode = 2;
        SET p_ErrorMessage = 'Lỗi: Không thể xóa sản phẩm vì còn đơn hàng chưa hoàn tất.';
        ROLLBACK;
        LEAVE proc_label;
    END IF;
    
    -- Xóa các bảng liên quan theo thứ tự (cascade manual)
    -- 1. Xóa Review trước (FK đến OrderItem)
    DELETE r FROM Review r
    JOIN OrderItem oi ON r.ItemID = oi.ItemID
    WHERE oi.ProductID = p_ProductID;
    
    -- 2. Xóa OrderItem (đơn hàng đã hoàn tất/hủy)
    DELETE FROM OrderItem WHERE ProductID = p_ProductID;
    
    -- 3. Xóa CartItem
    DELETE FROM CartItem WHERE ProductID = p_ProductID;
    
    -- 4. Xóa ProductCategory
    DELETE FROM ProductCategory WHERE ProductID = p_ProductID;
    
    -- 5. Xóa ProductVariation
    DELETE FROM ProductVariation WHERE ProductID = p_ProductID;
    
    -- 6. Xóa Product
    DELETE FROM Product WHERE ProductID = p_ProductID;
    
    SET p_ErrorCode = 0;
    SET p_ErrorMessage = 'Xóa sản phẩm thành công.';
    
    COMMIT;
END//

-- ============================================================
-- PHẦN 2.3: THỦ TỤC SELECT - Hiển thị danh sách (2 thủ tục)
-- ============================================================

-- THỦ TỤC 1: Lấy người mua có điểm cao và nhiều địa chỉ
DROP PROCEDURE IF EXISTS sp_GetHighValueBuyersWithAddresses;
CREATE PROCEDURE sp_GetHighValueBuyersWithAddresses (
    IN p_MinBonusPoint INT,
    IN p_MinAddresses INT
)
BEGIN
    SELECT
        U.UserID,
        U.Fullname,
        U.Email,
        B.BonusPoint,
        COUNT(A.AddressID) AS TotalAddresses,
        MAX(A.CreatedAt) AS LatestAddressDate -- Thời gian tạo địa chỉ gần nhất
    FROM
        Useraccount U
    JOIN
        Buyer B ON U.UserID = B.UserID
    JOIN
        Address A ON B.UserID = A.BuyerID
    WHERE
        -- Chỉ xét người mua có điểm thưởng >= p_MinBonusPoint
        B.BonusPoint >= p_MinBonusPoint 
    GROUP BY
        U.UserID, U.Fullname, U.Email, B.BonusPoint
    HAVING
        -- Chỉ hiển thị người mua có số địa chỉ >= p_MinAddresses
        COUNT(A.AddressID) >= p_MinAddresses
    ORDER BY
        B.BonusPoint DESC, TotalAddresses DESC; -- Ưu tiên người có điểm cao nhất
END//

-- THỦ TỤC 2: Lấy danh sách sản phẩm "yếu thế" (nhiều hủy, ít đánh giá cao)
DROP PROCEDURE IF EXISTS sp_GetUnderperformingProducts;
CREATE PROCEDURE sp_GetUnderperformingProducts (
    IN p_MinCancelledOrders INT,
    IN p_MaxAverageRating DECIMAL(2, 1)
)
BEGIN
    -- Tìm các Sản phẩm có nhiều hơn p_MinCancelledOrders bị hủy
    -- và có Rating trung bình THẤP hơn p_MaxAverageRating
    SELECT
        P.ProductID,
        P.Name AS ProductName,
        COUNT(CASE WHEN O.Status = 'Cancelled' THEN 1 END) AS TotalCancelledOrders,
        AVG(R.Rating) AS AverageRating
    FROM
        Product P
    JOIN
        ProductVariation PV ON P.ProductID = PV.ProductID
    JOIN
        OrderItem OI ON PV.ProductID = OI.ProductID AND PV.VariationID = OI.VariationID
    JOIN
        `Order` O ON OI.OrderID = O.OrderID
    LEFT JOIN
        Review R ON OI.ItemID = R.ItemID
    WHERE
        -- Chỉ xét các đơn hàng đã 'Completed' hoặc 'Cancelled'
        O.Status IN ('Completed', 'Cancelled')
    GROUP BY
        P.ProductID, P.Name
    HAVING
        -- Số đơn bị hủy phải >= p_MinCancelledOrders
        COUNT(CASE WHEN O.Status = 'Cancelled' THEN 1 END) >= p_MinCancelledOrders
        AND
        -- Rating trung bình phải <= p_MaxAverageRating
        AVG(R.Rating) <= p_MaxAverageRating
    ORDER BY
        TotalCancelledOrders DESC, AverageRating ASC; -- Ưu tiên xem các sản phẩm bị hủy nhiều nhất, sau đó là điểm thấp nhất
END//

DELIMITER ;


