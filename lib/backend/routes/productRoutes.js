const express = require('express');
const router = express.Router();
const Product = require('../models/Product');

router.get('/', async (req, res) => {
  try {
    const { lang = "en", category, search } = req.query;

    let filter = {};
    if (category) filter[`category.${lang}`] = category;
    if (search) filter[`name.${lang}`] = { $regex: search, $options: 'i' };

    const products = await Product.find(filter).sort({ [`name.${lang}`]: 1 });

    const localizedProducts = products.map(p => ({
      _id: p._id,
      name: p.name[lang] ?? p.name['en'] ?? "Без имени",
      category: p.category?.[lang] ?? p.category?.['en'] ?? "Без категории",
    }));

    res.json(localizedProducts);

  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Ошибка сервера" });
  }
});

module.exports = router;
