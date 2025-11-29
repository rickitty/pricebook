const express = require("express");
const router = express.Router();
const { makeAdmin, getWorkers, assignObjectsToUser} = require("../controllers/userController");

router.post("/makeAdmin", makeAdmin);

router.get("/workers", getWorkers);

router.post("/assignObjects", assignObjectsToUser);

module.exports = router;
