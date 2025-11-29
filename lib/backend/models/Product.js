const mongoose = require("mongoose");

const productSchema = new mongoose.Schema({
  name: {
    en: String,
    ru: String,
    kz: String,
  },
  category: {
    en: String,
    ru: String,
    kz: String,
  },
  imageUrl: String,
  iconUrl: String,
});

module.exports = mongoose.model("Product", productSchema);
