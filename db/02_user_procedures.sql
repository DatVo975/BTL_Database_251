CREATE SCHEMA IF NOT EXISTS btl2_db;
USE btl2_db;

DROP PROCEDURE IF EXISTS sp_InsertUser;
DROP PROCEDURE IF EXISTS sp_UpdateUser;
DROP PROCEDURE IF EXISTS sp_DeleteUser;

DELIMITER //

CREATE PROCEDURE sp_InsertUser(
    IN pFullname VARCHAR(200),
    IN pEmail VARCHAR(255),
    IN pPasswordHash VARCHAR(255),
    IN pSex VARCHAR(10),
    IN pPhone VARCHAR(10),
    IN pDoB DATE
)
BEGIN
    -- Kiểm tra Email format
    IF pEmail NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Email không hợp lệ!';
    END IF;

    -- Kiểm tra số điện thoại
    IF pPhone NOT REGEXP '^0[0-9]{9}$' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Số điện thoại không hợp lệ! Phải gồm 10 chữ số và bắt đầu bằng 0.';
    END IF;

    -- Kiểm tra email trùng
    IF EXISTS (SELECT 1 FROM Useraccount WHERE Email = pEmail) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Email đã tồn tại trong hệ thống!';
    END IF;

    -- Kiểm tra số điện thoại trùng
    IF EXISTS (SELECT 1 FROM Useraccount WHERE PhoneNumber = pPhone) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Số điện thoại đã tồn tại!';
    END IF;

    -- Kiểm tra tuổi >= 10
    IF pDoB IS NOT NULL AND TIMESTAMPDIFF(YEAR, pDoB, CURDATE()) < 10 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Tuổi phải lớn hơn hoặc bằng 10.';
    END IF;

    -- Insert
    INSERT INTO Useraccount (Fullname, Email, PasswordHash, Sex, PhoneNumber, DoB)
    VALUES (pFullname, pEmail, pPasswordHash, pSex, pPhone, pDoB);

END//

CREATE PROCEDURE sp_UpdateUser (
    IN p_UserID BIGINT,
    IN p_Fullname VARCHAR(200),
    IN p_Email VARCHAR(255),
    IN p_Sex VARCHAR(10),
    IN p_PhoneNumber VARCHAR(10),
    IN p_DoB DATE
)
BEGIN
    -- Kiểm tra user tồn tại
    IF NOT EXISTS (SELECT 1 FROM Useraccount WHERE UserID = p_UserID) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Không tồn tại người dùng với UserID này.';
    END IF;

    -- Validate email
    IF p_Email NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Email không hợp lệ.';
    END IF;

    -- Email trùng ngoại trừ chính nó
    IF EXISTS (SELECT 1 FROM Useraccount WHERE Email = p_Email AND UserID <> p_UserID) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Email đã được dùng bởi tài khoản khác.';
    END IF;

    -- Số điện thoại hợp lệ
    IF p_PhoneNumber NOT REGEXP '^0[0-9]{9}$' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Số điện thoại không hợp lệ.';
    END IF;

    -- Số điện thoại trùng
    IF EXISTS (SELECT 1 FROM Useraccount WHERE PhoneNumber = p_PhoneNumber AND UserID <> p_UserID) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Số điện thoại này đã thuộc về tài khoản khác.';
    END IF;

    -- Tuổi phải >= 10
    IF p_DoB IS NOT NULL AND TIMESTAMPDIFF(YEAR, p_DoB, CURDATE()) < 10 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Tuổi phải lớn hơn hoặc bằng 10.';
    END IF;

    UPDATE Useraccount
    SET Fullname = p_Fullname,
        Email = p_Email,
        Sex = p_Sex,
        PhoneNumber = p_PhoneNumber,
        DoB = p_DoB
    WHERE UserID = p_UserID;

END//

CREATE PROCEDURE sp_DeleteUser(IN pUserID BIGINT)
BEGIN
    -- Kiểm tra tồn tại
    IF NOT EXISTS (SELECT 1 FROM Useraccount WHERE UserID = pUserID) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'User không tồn tại!';
    END IF;

    -- Không thể xóa nếu User đang là Seller (có Shop đang hoạt động)
    IF EXISTS (SELECT 1 FROM Seller WHERE UserID = pUserID) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Không thể xóa: User đang là Seller!';
    END IF;
    
    -- Không thể xóa nếu User là Admin
    IF EXISTS (SELECT 1 FROM Adminaccount WHERE AdminID = pUserID) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Không thể xóa: User đang là Admin!';
    END IF;

    -- Nếu là Buyer, xóa cascade các dữ liệu liên quan
    IF EXISTS (SELECT 1 FROM Buyer WHERE UserID = pUserID) THEN
        -- Xóa Review (phụ thuộc OrderItem) - PHẢI XÓA TRƯỚC vì không có CASCADE
        DELETE r FROM Review r
        JOIN OrderItem oi ON r.ItemID = oi.ItemID
        JOIN `Order` o ON oi.OrderID = o.OrderID
        WHERE o.BuyerID = pUserID;
        
        -- Xóa ApplyVoucher (phụ thuộc Order)
        DELETE av FROM ApplyVoucher av
        JOIN `Order` o ON av.OrderID = o.OrderID
        WHERE o.BuyerID = pUserID;
        
        -- Xóa Payment (phụ thuộc Order)
        DELETE p FROM Payment p
        JOIN `Order` o ON p.OrderID = o.OrderID
        WHERE o.BuyerID = pUserID;
        
        -- XÓA ORDER TRƯỚC - OrderItem sẽ tự động cascade delete mà KHÔNG trigger conflict!
        DELETE FROM `Order` WHERE BuyerID = pUserID;
        
        -- Xóa Address
        DELETE FROM Address WHERE BuyerID = pUserID;
        
        -- Xóa CartItem
        DELETE FROM CartItem WHERE BuyerID = pUserID;
        
        -- Xóa ParticipationEvent
        DELETE FROM ParticipationEvent WHERE BuyerID = pUserID;
        
        -- Xóa ShopFollower (Buyer theo dõi các Shop)
        DELETE FROM ShopFollower WHERE BuyerID = pUserID;
        
        -- Xóa VoucherOfBuyer (Voucher mà Buyer sở hữu)
        DELETE FROM VoucherOfBuyer WHERE BuyerID = pUserID;
        
        -- Xóa ReportTicket
        DELETE FROM ReportTicket WHERE UserID = pUserID;
        
        -- Xóa Buyer
        DELETE FROM Buyer WHERE UserID = pUserID;
    END IF;

    -- Cuối cùng xóa User
    DELETE FROM Useraccount WHERE UserID = pUserID;
END//

DELIMITER ;








