const express = require("express");
const router = express.Router();
const firebaseAuth = require("../middleware/firebase.js");
const { ensureUser } = require("../controllers/authController");

router.post("/ensureUser", firebaseAuth, ensureUser);

module.exports = router;
