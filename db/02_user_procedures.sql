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

    -- Không thể xóa nếu User đang là Seller hoặc Buyer hoặc Admin
    IF EXISTS (SELECT 1 FROM Seller WHERE UserID = pUserID) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Không thể xóa: User đang là Seller!';
    END IF;
	
    IF EXISTS (SELECT 1 FROM Buyer WHERE UserID = pUserID) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Không thể xóa: User đang là Buyer!';
    END IF;

    IF EXISTS (SELECT 1 FROM Address WHERE BuyerID = pUserID) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Không thể xóa: User này có địa chỉ giao hàng.';
    END IF;
    
	IF EXISTS (SELECT 1 FROM ReportTicket WHERE UserID = pUserID) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Không thể xóa: User này có phiếu báo cáo.';
    END IF;
    
    IF EXISTS (SELECT 1 FROM Adminaccount WHERE AdminID = pUserID) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Không thể xóa: User đang là Admin!';
    END IF;

    DELETE FROM Useraccount WHERE UserID = pUserID;
END//

DELIMITER ;








