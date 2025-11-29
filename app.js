require("dotenv").config()
const express = require("express")
const jwt = require("jsonwebtoken")
const cookieParser = require("cookie-parser")
const mysql = require("mysql2/promise")
const bcrypt = require("bcrypt")

const app = express()
const pool = mysql.createPool({
  host: process.env.DB_HOST || "localhost",
  user: process.env.DB_USER || "root",
  password: process.env.DB_PASSWORD || "",
  database: process.env.DB_NAME || "btl2_db",
  charset: "utf8mb4"
});
app.set("view engine", "ejs")
app.use(express.urlencoded({extended: false}))
app.use(cookieParser())
app.use(express.static("public"))

app.use(function (req, res, next) {
    res.locals.errors = [];
    res.locals.user = null;

    const token = req.cookies && req.cookies.token;
    if (token) {
        try {
            const decoded = jwt.verify(token, process.env.JWTSECRET);
            req.user = decoded;
            res.locals.user = req.user;
        } catch (err) {
            req.user = null;
            res.locals.user = null;
        }
    } else {
        req.user = null;
        res.locals.user = null;
    }
    next();
})

app.get("/", (req, res) => {
    res.render("home");
})

app.get("/logout", (req, res) => {
    res.clearCookie("token");
    res.redirect("/");
})

app.get("/login", (req, res) => {
    res.render("login");
})

app.get("/register", (req, res) => {
    res.render("register");
})

app.get("/profile", async (req, res) => {
    if (!res.locals.user || !res.locals.user.id) {
        return res.redirect("/login");
    }
    try {
        const [rows] = await pool.query(
            "SELECT Fullname, Email, Sex, PhoneNumber, DoB FROM Useraccount WHERE UserID = ?", 
            [res.locals.user.id]
        );
        const userData = rows[0] || null;
        res.render("profile", { userData });
    } catch (err) {
        res.locals.errors.push(err.message);
        res.render("profile", { userData: null });
    }
})
// ============================================================
// THÊM(ĐĂNG KÍ), XÓA, SỬA TÀI KHOẢN VÀ ĐĂNG NHẬP
// ============================================================
app.post("/login", async (req, res) => {
    const { email, password } = req.body;
    const errors = [];
  
    const [rows] = await pool.query("SELECT UserID, PasswordHash FROM Useraccount WHERE Email = ?", [email]);
    if (rows.length === 0) {
        errors.push("Email hoặc mật khẩu không đúng");
        return res.status(400).render("login", { errors });
    }

    const user = rows[0];

    const isMatch = bcrypt.compareSync(password, user.PasswordHash);

    if (!isMatch) {
        errors.push("Email hoặc mật khẩu không đúng");
        return res.status(400).render("login", { errors });
    }
    
    if (user) {
        //Tao token cho nguoi dung dang nhap thanh cong
        const tokenValue = jwt.sign({exp: Math.floor(Date.now() / 1000)+60*60*24, id: user.UserID}, process.env.JWTSECRET)
        res.cookie("token", tokenValue, {
            httpOnly: true,
            secure: process.env.NODE_ENV === "production", // <-- only true in production
            sameSite: "strict",
            maxAge: 24 * 60 * 60 * 1000
        })
        return res.redirect("/");
    } else {
        return res.redirect("/");
    }
})

app.post("/register", async (req, res) => {
    const errors = [];
    const salt = bcrypt.genSaltSync(10);
    req.body.password = bcrypt.hashSync(req.body.password, salt);

    const { fullname, email, password, sex, phonenum, dob } = req.body;
    try {
        await pool.query(
        "CALL sp_InsertUser (?, ?, ?, ?, ?, ?)",
        [fullname, email, password, sex, phonenum, dob]
        );
        return res.redirect("/login");
    } catch (err) {
        if (err.sqlState === '45000') {
            errors.push(err.message);
            return res.render("register", {errors})
        } else {
            errors.push(err.message);
            return res.render("register", {errors})
        }
    }
})

app.post("/user/update", async (req, res) => {
    const errors = [];
    const { fullname, email, sex, phonenum, dob } = req.body;
    
    if (!res.locals.user || !res.locals.user.id) {
        return res.redirect("/login");
    }

    try {
        await pool.query(
            "CALL sp_UpdateUser (?, ?, ?, ?, ?, ?)",
            [res.locals.user.id, fullname, email, sex, phonenum, dob]
        );
        // Re-fetch updated row to confirm changes and render immediately
        const [rows] = await pool.query(
            "SELECT Fullname, Email, Sex, PhoneNumber, DoB FROM Useraccount WHERE UserID = ?",
            [res.locals.user.id]
        );
        const userData = rows[0] || null;
        return res.render("profile", { errors: [], userData });
    } catch (err) {
        errors.push(err.sqlState === "45000" ? err.message : err.message);
        // try to fetch current data for display
        let userData = null;
        try {
            const [rows] = await pool.query(
                "SELECT Fullname, Email, Sex, PhoneNumber, DoB FROM Useraccount WHERE UserID = ?",
                [res.locals.user.id]
            );
            userData = rows[0] || null;
        } catch (e) {
            console.error("Failed to fetch user after update error:", e);
        }
        return res.render("profile", { errors, userData });
    }
})

app.delete("/user/delete", async (req, res) => {
    const errors = [];
    if (!res.locals.user || !res.locals.user.id) {
        return res.status(401).json({ ok: false, message: "Not authenticated" });
    }
    try {
        await pool.query("CALL sp_DeleteUser (?)", [res.locals.user.id]);
        res.clearCookie("token");
        return res.json({ ok: true });
    } catch (err) {
        if (err.sqlState === '45000') {
            errors.push(err.message);
        } else {
            errors.push(err.message);
        }
        return res.status(500).render("profile", { errors, userData: null });
    }
});

// ============================================================
// PHẦN 3.2: GIAO DIỆN DANH SÁCH SẢN PHẨM (Tìm kiếm & Xóa)
// ============================================================

// GET: Hiển thị giao diện và danh sách tìm kiếm
app.get("/products/underperforming", async (req, res) => {
    // 1. Kiểm tra đăng nhập (nếu cần bảo mật)
    if (!res.locals.user) {
        return res.redirect("/login");
    }

    // 2. Lấy tham số từ URL (Query String)
    // Mặc định: minCancel = 0, maxRate = 5.0 nếu người dùng chưa nhập
    const minCancel = req.query.minCancel || 0;
    const maxRate = req.query.maxRate || 5.0;
    
    let productList = [];
    let errors = [];

    try {
        // 3. Gọi Stored Procedure sp_GetUnderperformingProducts(?, ?)
        const [rows] = await pool.query(
            "CALL sp_GetUnderperformingProducts(?, ?)", 
            [minCancel, maxRate]
        );
        
        // Rows trả về từ CALL thường có dạng [data, metadata], lấy phần tử đầu tiên
        productList = rows[0];

    } catch (err) {
        errors.push(err.message);
    }

    // 4. Kiểm tra role của user
    const userId = res.locals.user.id; // <-- Sửa từ UserID thành id
    let canDeleteProduct = false;

    try {
        const [sellerCheck] = await pool.query("SELECT UserID FROM Seller WHERE UserID = ?", [userId]);
        const [adminCheck] = await pool.query("SELECT AdminID FROM Adminaccount WHERE AdminID = ?", [userId]);
        
        console.log(`DEBUG: UserID=${userId}, isSeller=${sellerCheck.length > 0}, isAdmin=${adminCheck.length > 0}`);
        
        canDeleteProduct = sellerCheck.length > 0 || adminCheck.length > 0;
    } catch (err) {
        console.error('Error checking role:', err);
        // Ignore error, default canDeleteProduct = false
    }

    // 5. Render ra view ejs
    res.render("products", { 
        products: productList, 
        filters: { minCancel, maxRate },
        errors: errors,
        canDeleteProduct: canDeleteProduct
    });
});

// DELETE: Xóa sản phẩm
app.delete("/products/delete/:id", async (req, res) => {
    // API trả về JSON để Client (Frontend) xử lý qua Fetch/AJAX
    if (!res.locals.user) {
        return res.status(401).json({ ok: false, message: "Unauthorized" });
    }

    const productId = req.params.id;
    const userId = res.locals.user.id; // <-- Sửa từ UserID thành id

    try {
        // Kiểm tra quyền: User phải là Seller hoặc Admin
        const [sellerCheck] = await pool.query(
            "SELECT UserID FROM Seller WHERE UserID = ?",
            [userId]
        );
        
        const [adminCheck] = await pool.query(
            "SELECT AdminID FROM Adminaccount WHERE AdminID = ?",
            [userId]
        );

        const isSeller = sellerCheck.length > 0;
        const isAdmin = adminCheck.length > 0;

        // Nếu không phải Seller hoặc Admin
        if (!isSeller && !isAdmin) {
            return res.status(403).json({ 
                ok: false, 
                message: "Bạn không có quyền xóa sản phẩm. Chỉ Seller hoặc Admin mới được phép." 
            });
        }

        // Nếu là Seller, kiểm tra sản phẩm có thuộc shop của họ không
        if (isSeller && !isAdmin) {
            const [productCheck] = await pool.query(
                `SELECT p.ProductID 
                 FROM Product p
                 JOIN Shop s ON p.ShopID = s.ShopID
                 WHERE p.ProductID = ? AND s.SellerID = ?`,
                [productId, userId]
            );

            if (productCheck.length === 0) {
                return res.status(403).json({ 
                    ok: false, 
                    message: "Bạn chỉ có thể xóa sản phẩm của shop mình." 
                });
            }
        }

        // Gọi stored procedure sp_DeleteProduct với OUT parameters
        const [rows] = await pool.query(
            "CALL sp_DeleteProduct(?, @errorCode, @errorMessage)",
            [productId]
        );

        // Lấy OUT parameters
        const [results] = await pool.query("SELECT @errorCode AS errorCode, @errorMessage AS errorMessage");
        const { errorCode, errorMessage } = results[0];

        if (errorCode === 0) {
            return res.json({ ok: true, message: "Xóa sản phẩm thành công!" });
        } else {
            return res.status(400).json({ ok: false, message: errorMessage });
        }
    } catch (err) {
        return res.status(500).json({ ok: false, message: err.message });
    }
});


// ============================================================
// PHẦN 3.3: GIAO DIỆN BÁO CÁO DOANH THU (Gọi Hàm)
// ============================================================

// GET: Hiển thị form và kết quả tính toán
app.get("/reports/revenue", async (req, res) => {
    if (!res.locals.user) {
        return res.redirect("/login");
    }

    const { shopId, month, year } = req.query;
    let revenueResult = null;
    let errors = [];
    let message = null;

    // Chỉ thực hiện query nếu người dùng đã submit form (có đủ tham số)
    if (shopId && month && year) {
        try {
            // Gọi FUNCTION trong MySQL thông qua SELECT
            const query = "SELECT fn_TinhDoanhThuShop(?, ?, ?) AS Revenue";
            const [rows] = await pool.query(query, [shopId, month, year]);

            // Lấy kết quả
            const rawValue = parseFloat(rows[0].Revenue);

            // Xử lý các mã lỗi logic trả về từ hàm SQL (-1, -2)
            if (rawValue === -1) {
                errors.push("Lỗi: ShopID không tồn tại.");
            } else if (rawValue === -2) {
                errors.push("Lỗi: Thời gian (Tháng/Năm) không hợp lệ.");
            } else {
                // Format tiền tệ VNĐ
                revenueResult = new Intl.NumberFormat('vi-VN', { 
                    style: 'currency', 
                    currency: 'VND' 
                }).format(rawValue);
            }

        } catch (err) {
            errors.push(err.message);
        }
    }

    res.render("revenue", {
        result: revenueResult,
        params: { shopId, month, year },
        errors: errors
    });
});

app.listen(3000)
