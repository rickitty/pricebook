const express = require("express");
const router = express.Router();
const firebaseAuth = require("../middleware/firebase.js");
const {getObjects} = require("../controllers/objectController.js");
const User = require('../models/User');

router.get("/objects", firebaseAuth, getObjects);

router.get('/objects-of/:workerId', async (req, res) => {
  try {
    const { lang = "en" } = req.query;
    const worker = await User.findById(req.params.workerId).populate('objects');

    if (!worker) return res.status(404).json({ message: 'Работник не найден' });

    const localizedObjects = worker.objects.map(obj => ({
      _id: obj._id,
      name: obj.name[lang] ?? obj.name['en'] ?? "Без имени",
      type: obj.type?.[lang] ?? obj.type?.['en'] ?? "Тип неизвестен",
      address: obj.address?.[lang] ?? obj.address?.['en'] ?? "Адрес неизвестен",
      coords: obj.coords,
      status: obj.status,
    }));

    res.json(localizedObjects);

  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Ошибка сервера', error });
  }
});

module.exports = router;
