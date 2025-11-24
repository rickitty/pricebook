const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  firebaseUid: { type: String, index: true },
  phone: { type: String, required: true, unique: true }, 
  role: { type: String, enum: ['worker', 'admin'], default: 'worker' },
  objects: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Object' }], 
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('User', userSchema);
