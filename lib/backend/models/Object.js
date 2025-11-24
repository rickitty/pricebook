const mongoose = require('mongoose');

const objectSchema = new mongoose.Schema({
  name: {
  en: { type: String, required: true },
  ru: { type: String, required: true },
  kz: { type: String, required: true },
}, 
  type: { 
    en: { type: String, required: true },
    ru: { type: String, required: true },
    kz: { type: String, required: true },
  },
  address: { 
    en: { type: String, required: true },
    ru: { type: String, required: true },
    kz: { type: String, required: true },
  },
  coords: {
    lat: { type: Number, required: true },
    lng: { type: Number, required: true },
  },
  status: { type: String, default: 'active' }, 
  createdAt: { type: Date, default: Date.now }, 
});

module.exports = mongoose.model('Object', objectSchema);
