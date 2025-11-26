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
  password: "",
  database: "btl2_db",
});
app.set("view engine", "ejs")
app.use(express.urlencoded({extended: false}))
app.use(cookieParser())
app.use(express.static("public"))

app.use(function (req, res, next) {
    res.locals.error = [];

    try {
        const decoded = jwt.verify(req.cookies.token, process.env.JWTSECRET);
        req.user = decoded;
    }
    catch (err) {
        req.user = null;
    }
    res.locals.user = req.user;
    if (res.locals.user) console.log(req.user)
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

app.get("/profile", (req, res) => {
    res.render("profile");
})

app.post("/login", async (req, res) => {
    const { email, password } = req.body;
  
    const [rows] = await pool.query("SELECT * FROM Useraccount WHERE Email = ?", [email]);
    if (rows.length === 0) {
        return res.status(400).send("Incorrect email or password");
    }

    const user = rows[0];

    const isMatch = (password === user.PasswordHash);

    if (!isMatch) {
        return res.status(400).send("Incorrect email or password");
    }

    if (user) {
        //Tao token cho nguoi dung dang nhap thanh cong
        const tokenValue = jwt.sign({exp: Math.floor(Date.now() / 1000)+60*60*24, 
                                    fullname: user.Fullname, 
                                    email: user.Email, 
                                    sex: user.Sex, phonenum: 
                                    user.PhoneNumber, 
                                    dob: user.DoB}, process.env.JWTSECRET)
        res.cookie("token", tokenValue, {
            httpOnly: true,
            secure: true,
            sameSite: "strict",
            maxAge: 24 * 60 * 60 * 1000
        })
        return res.redirect("/");
    } else {
        return res.redirect("/");
    }
})

app.post("/register", (req, res) => {
    const salt = bcrypt.genSaltSync(10);
    req.body.password = bcrypt.hashSync(req.body.password, salt);

    const { fullname, email, password, sex, phonenum, dob } = req.body;
    try {
        pool.query(
        "CALL sp_InsertUser (?, ?, ?, ?, ?, ?)",
        [fullname, email, password, sex, phonenum, dob]
        );
        res.send("Account created!");
        res.redirect("/");
    } catch (err) {
        if (err.code === "ER_DUP_ENTRY") {
        res.status(400).send("Username already exists");
        } else {
        res.status(500).send(err.message);
        }
    }
})

app.listen(3000)
