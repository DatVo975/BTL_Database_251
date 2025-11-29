SET @@sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
-- sử dụng database
CREATE SCHEMA IF NOT EXISTS btl2_db;
USE btl2_db;
-- xóa bảng nếu có để chạy lại
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS ApplyVoucher;
DROP TABLE IF EXISTS VoucherOfBuyer;
DROP TABLE IF EXISTS ParticipationEvent;
DROP TABLE IF EXISTS Payment;
DROP TABLE IF EXISTS `Order`;
DROP TABLE IF EXISTS OrderItem;
DROP TABLE IF EXISTS CartItem;
DROP TABLE IF EXISTS ReportTicket;
DROP TABLE IF EXISTS Review;
DROP TABLE IF EXISTS Address;
DROP TABLE IF EXISTS ProductVariation;
DROP TABLE IF EXISTS ProductCategory;
DROP TABLE IF EXISTS Product;
DROP TABLE IF EXISTS ShopFollower;
DROP TABLE IF EXISTS Shop;
DROP TABLE IF EXISTS Category;
DROP TABLE IF EXISTS Voucher;
DROP TABLE IF EXISTS Buyer;
DROP TABLE IF EXISTS Seller;
DROP TABLE IF EXISTS Adminaccount;
DROP TABLE IF EXISTS Useraccount;
DROP TABLE IF EXISTS `Event`;
DROP TABLE IF EXISTS BonusPoint;
DROP TABLE IF EXISTS SaleOff;
SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- NHÓM 1: USER & ADMIN & SELLER & BUYER
-- ============================================================

-- Tạo bảng User (Useraccount)
CREATE TABLE Useraccount (
  UserID BIGINT AUTO_INCREMENT PRIMARY KEY,
  Fullname VARCHAR(200) NOT NULL,
  Email VARCHAR(255) NOT NULL UNIQUE,
  PasswordHash VARCHAR(255) NOT NULL,
  Sex ENUM('Male','Female','Other') DEFAULT 'Other',
  PhoneNumber VARCHAR(10) NOT NULL UNIQUE,
  DoB DATE,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CHECK (PhoneNumber REGEXP '^0[0-9]{9}$'),
  CHECK (Email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
) ENGINE=InnoDB;

-- Tạo bảng Admin
CREATE TABLE Adminaccount (
  AdminID BIGINT PRIMARY KEY,
  Fullname VARCHAR(200) NOT NULL,
  CONSTRAINT FK_adminID FOREIGN KEY (AdminID) REFERENCES Useraccount(UserID) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Tạo bảng Seller
CREATE TABLE Seller (
  UserID BIGINT PRIMARY KEY,
  TaxNum VARCHAR(100) NOT NULL,
  CONSTRAINT FK_SuserID FOREIGN KEY (UserID) REFERENCES Useraccount(UserID) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Tạo bảng Buyer
CREATE TABLE Buyer (
  UserID BIGINT PRIMARY KEY,
  BonusPoint INT DEFAULT 0 CHECK (BonusPoint >= 0),
  CONSTRAINT FK_BuserID FOREIGN KEY (UserID) REFERENCES Useraccount(UserID) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Tạo bảng ReportTicket
CREATE TABLE ReportTicket (
  TicketID BIGINT PRIMARY KEY AUTO_INCREMENT,
  AdminID BIGINT,
  UserID BIGINT,
  Status ENUM('Open','InProgress','Closed') DEFAULT 'Open',
  Detail TEXT,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT FK_RTadminID FOREIGN KEY (AdminID) REFERENCES Adminaccount(AdminID),
  CONSTRAINT FK_RTuserID FOREIGN KEY (UserID) REFERENCES Useraccount(UserID)
) ENGINE=InnoDB;

-- ============================================================
-- NHÓM 2: SHOP & PRODUCT
-- ============================================================

-- Tạo bảng Event trước (vì Product có FK đến Event)
CREATE TABLE `Event` (
  EventID BIGINT PRIMARY KEY AUTO_INCREMENT,
  AdminID BIGINT NOT NULL,
  Name VARCHAR(150),
  StartAt DATETIME,
  EndAt DATETIME,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT FK_EadminID FOREIGN KEY (AdminID) REFERENCES Adminaccount(AdminID)
) ENGINE=InnoDB;

-- Tạo bảng Shop
CREATE TABLE Shop (
  ShopID BIGINT PRIMARY KEY AUTO_INCREMENT,
  SellerID BIGINT NOT NULL,
  Name VARCHAR(200) NOT NULL,
  DeliveryMethod VARCHAR(200),
  TotalRevenue DECIMAL(15,2) DEFAULT 0 CHECK (TotalRevenue >= 0),
  CancelledOrderCount INT DEFAULT 0 CHECK (CancelledOrderCount >= 0),
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT FK_SHuserID FOREIGN KEY (SellerID) REFERENCES Seller(UserID),
  CHECK (Name <> '')
) ENGINE=InnoDB;

-- Tạo bảng ShopFollower
CREATE TABLE ShopFollower (
  ShopID BIGINT NOT NULL,
  BuyerID BIGINT NOT NULL,
  FollowedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (ShopID, BuyerID),
  CONSTRAINT FK_SFshopID FOREIGN KEY (ShopID) REFERENCES Shop(ShopID),
  CONSTRAINT FK_SFbuyerID FOREIGN KEY (BuyerID) REFERENCES Buyer(UserID)
) ENGINE=InnoDB;

-- Tạo bảng Category
CREATE TABLE Category (
  CategoryID BIGINT PRIMARY KEY AUTO_INCREMENT,
  ClassifyCategoryID BIGINT DEFAULT NULL,
  Name VARCHAR(200) NOT NULL,
  ProductCount BIGINT DEFAULT 0 CHECK (ProductCount >= 0),
  CONSTRAINT FK_ClassifyCategoryID FOREIGN KEY (ClassifyCategoryID) REFERENCES Category(CategoryID) ON DELETE SET NULL
) ENGINE=InnoDB;

-- Tạo bảng Product
CREATE TABLE Product (
  ProductID BIGINT PRIMARY KEY AUTO_INCREMENT,
  ShopID BIGINT NOT NULL,
  SaleOffEventID BIGINT NULL,
  Name VARCHAR(200) NOT NULL,
  Description TEXT,
  SoldCount INT DEFAULT 0 CHECK (SoldCount >= 0),
  CancelledCount INT DEFAULT 0 CHECK (CancelledCount >= 0),
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT FK_ShopID FOREIGN KEY (ShopID) REFERENCES Shop(ShopID),
  CONSTRAINT FK_Product_SaleOffEvent FOREIGN KEY (SaleOffEventID) REFERENCES Event(EventID)
) ENGINE=InnoDB;

-- Tạo bảng ProductCategory
CREATE TABLE ProductCategory (
  ProductID BIGINT NOT NULL,
  CategoryID BIGINT NOT NULL,
  PRIMARY KEY (ProductID, CategoryID),
  CONSTRAINT FK_PCproductID FOREIGN KEY (ProductID) REFERENCES Product(ProductID) ON DELETE CASCADE,
  CONSTRAINT FK_PCcategoryID FOREIGN KEY (CategoryID) REFERENCES Category(CategoryID) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Tạo bảng ProductVariation
CREATE TABLE ProductVariation (
  ProductID BIGINT NOT NULL,
  VariationID BIGINT NOT NULL,
  Type VARCHAR(100),
  Price DECIMAL(13,2) NOT NULL CHECK (Price >= 0),
  Stock INT NOT NULL DEFAULT 0 CHECK (Stock >= 0),
  PRIMARY KEY (ProductID, VariationID),
  CONSTRAINT FK_PVproductID FOREIGN KEY (ProductID) REFERENCES Product(ProductID)
) ENGINE=InnoDB;

-- ============================================================
-- NHÓM 3: CART & ORDER & PAYMENT
-- ============================================================

-- Tạo bảng CartItem
CREATE TABLE CartItem (
  CartItemID BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  BuyerID BIGINT NOT NULL,
  ProductID BIGINT NOT NULL,
  VariationID BIGINT NOT NULL,
  Quantity INT NOT NULL CHECK (Quantity > 0),
  AddedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT FK_CIuserID FOREIGN KEY (BuyerID) REFERENCES Buyer(UserID),
  CONSTRAINT FK_CIprov_varID FOREIGN KEY (ProductID, VariationID) REFERENCES ProductVariation(ProductID, VariationID),
  CONSTRAINT UQ_Cart_Product UNIQUE (BuyerID, ProductID, VariationID)
) ENGINE=InnoDB;

-- Tạo bảng Address
CREATE TABLE Address (
  AddressID BIGINT PRIMARY KEY AUTO_INCREMENT,
  BuyerID BIGINT NOT NULL,
  Detail TEXT,
  Name VARCHAR(200),
  PhoneNumber VARCHAR(10),
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT FK_AuserID FOREIGN KEY (BuyerID) REFERENCES Buyer(UserID),
  CHECK (PhoneNumber REGEXP '^0[0-9]{9}$')
) ENGINE=InnoDB;

-- Tạo bảng Order
CREATE TABLE `Order` (
  OrderID BIGINT PRIMARY KEY AUTO_INCREMENT,
  BuyerID BIGINT NOT NULL,
  AddressID BIGINT NOT NULL,
  Amount DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (Amount >= 0),
  Status ENUM('Pending','Shipping','Delivered','Completed','Cancelled') DEFAULT 'Pending',
  DeliveryFee DECIMAL(12,2) DEFAULT 0 CHECK (DeliveryFee >= 0),
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UpdatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT FK_OuserID FOREIGN KEY (BuyerID) REFERENCES Buyer(UserID),
  CONSTRAINT FK_OaddressID FOREIGN KEY (AddressID) REFERENCES Address(AddressID)
) ENGINE=InnoDB;

-- Tạo bảng OrderItem
CREATE TABLE OrderItem (
  ItemID BIGINT PRIMARY KEY AUTO_INCREMENT,
  OrderID BIGINT NOT NULL,
  ProductID BIGINT NOT NULL,
  VariationID BIGINT NOT NULL,
  Quantity INT NOT NULL CHECK (Quantity > 0),
  UnitPrice DECIMAL(12,2) NOT NULL CHECK (UnitPrice >= 0),
  CONSTRAINT FK_OIorderID FOREIGN KEY (OrderID) REFERENCES `Order`(OrderID) ON DELETE CASCADE,
  CONSTRAINT FK_OIpro_varID FOREIGN KEY (ProductID, VariationID) REFERENCES ProductVariation(ProductID, VariationID)
) ENGINE=InnoDB;

-- Tạo bảng Payment
CREATE TABLE Payment (
  PaymentID BIGINT PRIMARY KEY AUTO_INCREMENT,
  OrderID BIGINT UNIQUE,
  Amount DECIMAL(12,2) NOT NULL CHECK (Amount >= 0),
  Status ENUM('Pending','Paid','Failed','Refunded') DEFAULT 'Pending',
  Method VARCHAR(50),
  PaidAt TIMESTAMP NULL,
  CONSTRAINT FK_PorderID FOREIGN KEY (OrderID) REFERENCES `Order`(OrderID)
) ENGINE=InnoDB;

-- Tạo bảng Review
CREATE TABLE Review (
  ReviewID BIGINT PRIMARY KEY AUTO_INCREMENT,
  ItemID BIGINT NOT NULL,
  Rating TINYINT CHECK (Rating >= 1 AND Rating <= 5),
  Spec TEXT,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT FK_RitemID FOREIGN KEY (ItemID) REFERENCES OrderItem(ItemID),
  CONSTRAINT UQ_Review_Item UNIQUE (ItemID)
) ENGINE=InnoDB;

-- ============================================================
-- NHÓM 4: VOUCHER
-- ============================================================

-- Tạo bảng Voucher
CREATE TABLE Voucher (
  VoucherID BIGINT PRIMARY KEY AUTO_INCREMENT,
  Name VARCHAR(200),
  ExpiredDate DATE,
  Number INT DEFAULT 0 CHECK (Number >= 0),
  Value DECIMAL(12,2) DEFAULT 0 CHECK (Value >= 0),
  ConditionText DECIMAL(12,2) DEFAULT 0,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Tạo bảng VoucherOfBuyer
CREATE TABLE VoucherOfBuyer (
  BuyerID BIGINT NOT NULL,
  VoucherID BIGINT NOT NULL,
  AcquiredAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (BuyerID, VoucherID),
  CONSTRAINT FK_VOBuserID FOREIGN KEY (BuyerID) REFERENCES Buyer(UserID),
  CONSTRAINT FK_VOBvoucherID FOREIGN KEY (VoucherID) REFERENCES Voucher(VoucherID)
) ENGINE=InnoDB;

-- Tạo bảng ApplyVoucher
CREATE TABLE ApplyVoucher (
  OrderID BIGINT NOT NULL,
  VoucherID BIGINT NOT NULL,
  AppliedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY(OrderID, VoucherID),
  CONSTRAINT FK_AVorderID FOREIGN KEY (OrderID) REFERENCES `Order`(OrderID),
  CONSTRAINT FK_AVvoucherID FOREIGN KEY (VoucherID) REFERENCES Voucher(VoucherID)
) ENGINE=InnoDB;

-- ============================================================
-- NHÓM 5: EVENT & BONUS & SALEOFF
-- ============================================================

-- Tạo bảng ParticipationEvent
CREATE TABLE ParticipationEvent (
  BuyerID BIGINT NOT NULL,
  EventID BIGINT NOT NULL,
  ParticipatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (BuyerID, EventID),
  CONSTRAINT FK_PEuserID FOREIGN KEY (BuyerID) REFERENCES Buyer(UserID),
  CONSTRAINT FK_PEeventID FOREIGN KEY (EventID) REFERENCES Event(EventID)
) ENGINE=InnoDB;

-- Tạo bảng BonusPoint
CREATE TABLE BonusPoint (
  EventID BIGINT PRIMARY KEY,
  Point INT DEFAULT 0 CHECK (Point >= 0),
  CONSTRAINT FK_BPeventID FOREIGN KEY (EventID) REFERENCES Event(EventID)
) ENGINE=InnoDB;

-- Tạo bảng SaleOff
CREATE TABLE SaleOff (
  EventID BIGINT PRIMARY KEY,
  Deal VARCHAR(255),
  StartAt DATETIME,
  EndAt DATETIME,
  CONSTRAINT FK_SOeventID FOREIGN KEY (EventID) REFERENCES Event(EventID)
) ENGINE=InnoDB;

