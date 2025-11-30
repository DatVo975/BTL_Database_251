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
        // Kiểm tra xem có phải Admin đang xem profile của user khác không
        const targetUserId = req.query.userId || res.locals.user.id;
        const isViewingOtherUser = targetUserId != res.locals.user.id;
        
        // Kiểm tra quyền Admin
        let isAdmin = false;
        const [adminCheck] = await pool.query(
            "SELECT AdminID FROM Adminaccount WHERE AdminID = ?",
            [res.locals.user.id]
        );
        isAdmin = adminCheck.length > 0;
        
        // Nếu không phải Admin mà cố xem profile người khác → từ chối
        if (isViewingOtherUser && !isAdmin) {
            res.locals.errors.push("Bạn không có quyền xem thông tin người dùng này!");
            return res.redirect("/profile");
        }
        
        const [rows] = await pool.query(
            "SELECT UserID, Fullname, Email, Sex, PhoneNumber, DoB FROM Useraccount WHERE UserID = ?", 
            [targetUserId]
        );
        const userData = rows[0] || null;
        
        if (!userData) {
            res.locals.errors.push("Không tìm thấy người dùng!");
            return res.redirect("/buyers");
        }
        
        res.render("profile", { 
            userData, 
            isAdmin,
            isViewingOtherUser 
        });
    } catch (err) {
        res.locals.errors.push(err.message);
        res.render("profile", { userData: null, isAdmin: false, isViewingOtherUser: false });
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
    const { fullname, email, sex, phonenum, dob, userId } = req.body;
    
    if (!res.locals.user || !res.locals.user.id) {
        return res.redirect("/login");
    }

    try {
        // Xác định user nào sẽ được update
        let targetUserId = res.locals.user.id;
        let isUpdatingOtherUser = false;
        
        // Nếu có userId trong body (Admin đang update user khác)
        if (userId && userId != res.locals.user.id) {
            // Kiểm tra quyền Admin
            const [adminCheck] = await pool.query(
                "SELECT AdminID FROM Adminaccount WHERE AdminID = ?",
                [res.locals.user.id]
            );
            
            if (adminCheck.length === 0) {
                errors.push("Bạn không có quyền sửa thông tin người dùng khác!");
                return res.redirect("/profile");
            }
            
            targetUserId = userId;
            isUpdatingOtherUser = true;
        }
        
        await pool.query(
            "CALL sp_UpdateUser (?, ?, ?, ?, ?, ?)",
            [targetUserId, fullname, email, sex, phonenum, dob]
        );
        
        // Nếu Admin sửa user khác, redirect về buyers list
        if (isUpdatingOtherUser) {
            return res.redirect("/buyers");
        }
        
        // Re-fetch updated row to confirm changes and render immediately
        const [rows] = await pool.query(
            "SELECT UserID, Fullname, Email, Sex, PhoneNumber, DoB FROM Useraccount WHERE UserID = ?",
            [targetUserId]
        );
        const userData = rows[0] || null;
        
        // Kiểm tra isAdmin cho render
        const [adminCheck] = await pool.query(
            "SELECT AdminID FROM Adminaccount WHERE AdminID = ?",
            [res.locals.user.id]
        );
        const isAdmin = adminCheck.length > 0;
        
        return res.render("profile", { 
            errors: [], 
            userData, 
            isAdmin,
            isViewingOtherUser: isUpdatingOtherUser 
        });
    } catch (err) {
        errors.push(err.sqlState === "45000" ? err.message : err.message);
        // try to fetch current data for display
        let userData = null;
        let isAdmin = false;
        try {
            const targetUserId = userId || res.locals.user.id;
            const [rows] = await pool.query(
                "SELECT UserID, Fullname, Email, Sex, PhoneNumber, DoB FROM Useraccount WHERE UserID = ?",
                [targetUserId]
            );
            userData = rows[0] || null;
            
            const [adminCheck] = await pool.query(
                "SELECT AdminID FROM Adminaccount WHERE AdminID = ?",
                [res.locals.user.id]
            );
            isAdmin = adminCheck.length > 0;
        } catch (e) {
            console.error("Failed to fetch user after update error:", e);
        }
        return res.render("profile", { 
            errors, 
            userData, 
            isAdmin,
            isViewingOtherUser: userId && userId != res.locals.user.id 
        });
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
// PHẦN 3.2: GIAO DIỆN DANH SÁCH NGƯỜI DÙNG (Tìm kiếm & Xóa)
// ============================================================

// GET: Hiển thị giao diện và danh sách tìm kiếm
// ============================================================
// PHẦN 3.2 BỔ SUNG: GIAO DIỆN QUẢN LÝ BUYERS (Gọi thủ tục SELECT)
// ============================================================

// GET: Hiển thị danh sách Buyers VIP
app.get("/buyers", async (req, res) => {
    if (!res.locals.user) {
        return res.redirect("/login");
    }

    const { minBonusPoint = 150, minAddresses = 1, search = '' } = req.query;
    let buyersList = [];
    let errors = [];

    try {
        // Gọi stored procedure sp_GetHighValueBuyersWithAddresses
        const [rows] = await pool.query(
            "CALL sp_GetHighValueBuyersWithAddresses(?, ?)",
            [parseInt(minBonusPoint), parseInt(minAddresses)]
        );

        buyersList = rows[0]; // Kết quả từ stored procedure

        // Filter theo search (tìm kiếm theo tên hoặc email)
        if (search.trim() !== '') {
            buyersList = buyersList.filter(buyer => 
                buyer.Fullname.toLowerCase().includes(search.toLowerCase()) ||
                buyer.Email.toLowerCase().includes(search.toLowerCase())
            );
        }

    } catch (err) {
        errors.push(err.message);
    }

    // Kiểm tra quyền Admin
    let isAdmin = false;
    try {
        const userId = res.locals.user.id;
        const [adminCheck] = await pool.query("SELECT AdminID FROM Adminaccount WHERE AdminID = ?", [userId]);
        isAdmin = adminCheck.length > 0;
    } catch (err) {
        console.error('Error checking admin role:', err);
    }

    res.render("buyers", { 
        buyers: buyersList, 
        filters: { minBonusPoint, minAddresses, search },
        errors: errors,
        isAdmin: isAdmin
    });
});

// DELETE: Xóa Buyer (chỉ Admin)
app.delete("/buyers/delete/:id", async (req, res) => {
    if (!res.locals.user) {
        return res.status(401).json({ ok: false, message: "Unauthorized" });
    }

    const buyerId = req.params.id;
    const userId = res.locals.user.id;

    try {
        // Kiểm tra quyền Admin
        const [adminCheck] = await pool.query(
            "SELECT AdminID FROM Adminaccount WHERE AdminID = ?",
            [userId]
        );

        if (adminCheck.length === 0) {
            return res.status(403).json({ 
                ok: false, 
                message: "Chỉ Admin mới có quyền xóa người dùng." 
            });
        }

        // Gọi stored procedure sp_DeleteUser (chỉ có 1 tham số IN, không có OUT)
        await pool.query("CALL sp_DeleteUser(?)", [buyerId]);
        
        return res.json({ ok: true, message: "Xóa người dùng thành công!" });
        
    } catch (err) {
        // Lỗi từ SIGNAL SQLSTATE '45000' sẽ có trong err.message
        return res.status(500).json({ ok: false, message: err.message });
    }
});

// PUT: Cập nhật điểm thưởng của Buyer (chỉ Admin)
app.put("/buyers/update-points/:id", express.json(), async (req, res) => {
    if (!res.locals.user) {
        return res.status(401).json({ ok: false, message: "Unauthorized" });
    }

    const buyerId = req.params.id;
    const userId = res.locals.user.id;
    const { bonusPoint } = req.body;

    try {
        // Kiểm tra quyền Admin
        const [adminCheck] = await pool.query(
            "SELECT AdminID FROM Adminaccount WHERE AdminID = ?",
            [userId]
        );

        if (adminCheck.length === 0) {
            return res.status(403).json({ 
                ok: false, 
                message: "Chỉ Admin mới có quyền cập nhật điểm thưởng." 
            });
        }

        // Kiểm tra Buyer có tồn tại không
        const [buyerCheck] = await pool.query(
            "SELECT UserID FROM Buyer WHERE UserID = ?",
            [buyerId]
        );

        if (buyerCheck.length === 0) {
            return res.status(404).json({ 
                ok: false, 
                message: "Không tìm thấy Buyer này." 
            });
        }

        // Cập nhật điểm thưởng
        await pool.query(
            "UPDATE Buyer SET BonusPoint = ? WHERE UserID = ?",
            [bonusPoint, buyerId]
        );
        
        return res.json({ 
            ok: true, 
            message: `Cập nhật điểm thưởng thành công! Điểm mới: ${bonusPoint}` 
        });
        
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
