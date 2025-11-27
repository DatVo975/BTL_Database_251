require("dotenv").config()
const express = require("express")
const jwt = require("jsonwebtoken")
const cookieParser = require("cookie-parser")
const mysql = require("mysql2/promise")
const bcrypt = require("bcrypt")

const app = express()
const pool = mysql.createPool({
  host: "localhost",
  user: "root",
  password: "CptDuck247",
  database: "btl2_db",
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

app.post("/login", async (req, res) => {
    const { email, password } = req.body;
  
    const [rows] = await pool.query("SELECT UserID, PasswordHash FROM Useraccount WHERE Email = ?", [email]);
    if (rows.length === 0) {
        return res.status(400).send("Incorrect email or password");
    }

    const user = rows[0];

    const isMatch = bcrypt.compareSync(password, user.PasswordHash);

    if (!isMatch) {
        return res.status(400).send("Incorrect email or password");
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
        return res.status(500).render("profile", { errors, userData });
    }
})

app.listen(3000)
