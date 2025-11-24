const express = require("express");
const router = express.Router();
const firebaseAuth = require("../middleware/firebase.js");
const { makeAdmin, getWorkers, assignObjectsToUser} = require("../controllers/userController");

router.post("/makeAdmin", firebaseAuth, makeAdmin);

router.get("/workers", firebaseAuth, getWorkers);

router.post("/assignObjects", firebaseAuth, assignObjectsToUser);

module.exports = router;
