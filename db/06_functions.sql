USE btl2_db;

-- ============================================================
-- PHẦN 2.4: HÀMS SQL
-- ============================================================

-- ============================================================
-- HÀM 1: Tính doanh thu của Shop trong tháng/năm
-- ============================================================
-- Yêu cầu:
-- - Có IF để kiểm tra tham số
-- - Có LOOP để tính toán
-- - Có CON TRỎ để duyệt dữ liệu
-- - Lấy dữ liệu từ câu truy vấn (SELECT)
-- - Trả về -1 nếu ShopID không tồn tại
-- - Trả về -2 nếu tháng/năm không hợp lệ

DROP FUNCTION IF EXISTS fn_TinhDoanhThuShop;

DELIMITER //

CREATE FUNCTION fn_TinhDoanhThuShop(p_ShopID BIGINT, p_Month INT, p_Year INT) 
RETURNS DECIMAL(15,2)
DETERMINISTIC
BEGIN
    DECLARE v_TotalRevenue DECIMAL(15,2) DEFAULT 0;
    DECLARE v_Quantity INT;
    DECLARE v_UnitPrice DECIMAL(12,2);
    DECLARE done INT DEFAULT FALSE;

    DECLARE cur_Revenue CURSOR FOR 
        SELECT oi.Quantity, oi.UnitPrice
        FROM OrderItem oi
        JOIN `Order` o ON oi.OrderID = o.OrderID
        JOIN ProductVariation pv ON oi.ProductID = pv.ProductID AND oi.VariationID = pv.VariationID
        JOIN Product p ON pv.ProductID = p.ProductID
        WHERE p.ShopID = p_ShopID 
          AND o.Status = 'Completed' 
          AND MONTH(o.CreatedAt) = p_Month
          AND YEAR(o.CreatedAt) = p_Year;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;


    IF NOT EXISTS (SELECT 1 FROM Shop WHERE ShopID = p_ShopID) THEN
        RETURN -1;
    END IF;

    IF p_Month < 1 OR p_Month > 12 OR p_Year < 2000 THEN
        RETURN -2;
    END IF;

    OPEN cur_Revenue;

    read_loop: LOOP
        FETCH cur_Revenue INTO v_Quantity, v_UnitPrice;
        
        IF done THEN
            LEAVE read_loop;
        END IF;

        SET v_TotalRevenue = v_TotalRevenue + (v_Quantity * v_UnitPrice);
    END LOOP;

    CLOSE cur_Revenue;

    RETURN v_TotalRevenue;
END//

DELIMITER ;

-- =============================================
-- HÀM 2: XẾP HẠNG THÀNH VIÊN (BUYER) DỰA TRÊN CHI TIÊU
-- =============================================
DROP FUNCTION IF EXISTS fn_XepHangThanhVien;

DELIMITER //

CREATE FUNCTION fn_XepHangThanhVien(p_BuyerID BIGINT) 
RETURNS VARCHAR(50)
DETERMINISTIC
BEGIN

    DECLARE v_TotalSpent DECIMAL(15,2) DEFAULT 0;
    DECLARE v_OrderAmount DECIMAL(12,2);
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_Rank VARCHAR(50);

    DECLARE cur_Spending CURSOR FOR 
        SELECT Amount 
        FROM `Order` 
        WHERE BuyerID = p_BuyerID AND Status = 'Completed';

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    IF NOT EXISTS (SELECT 1 FROM Buyer WHERE UserID = p_BuyerID) THEN
        RETURN 'Lỗi: BuyerID không tồn tại';
    END IF;

    OPEN cur_Spending;

    spending_loop: LOOP
        FETCH cur_Spending INTO v_OrderAmount;
        
        IF done THEN
            LEAVE spending_loop;
        END IF;

        SET v_TotalSpent = v_TotalSpent + v_OrderAmount;
    END LOOP;

    CLOSE cur_Spending;

    IF v_TotalSpent >= 50000000 THEN
        SET v_Rank = 'Hạng Kim Cương (Diamond)';
    ELSEIF v_TotalSpent >= 20000000 THEN
        SET v_Rank = 'Hạng Vàng (Gold)';
    ELSEIF v_TotalSpent >= 5000000 THEN
        SET v_Rank = 'Hạng Bạc (Silver)';
    ELSE
        SET v_Rank = 'Thành viên mới (Member)';
    END IF;

    RETURN v_Rank;
END//

DELIMITER ;
