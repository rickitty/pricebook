const mongoose = require('mongoose');

const productSubSchema = new mongoose.Schema({
  productId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Product',
    required: true,
  },
  status: {
    type: String,
    enum: ['pending', 'added'],
    default: 'pending',
  },
  price: {
    type: Number, 
  },
  photoUrl: {
    type: String, 
  },
}, { _id: false });

const objectSubSchema = new mongoose.Schema({
  objectId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Object',
    required: true,
  },
  products: [productSubSchema],
}, { _id: false });

const taskSchema = new mongoose.Schema({
  workerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },

  objects: [objectSubSchema],

  date: {
    type: Date,
    required: true,
  },

  status: {
    type: String,
    enum: ['pending', 'in_progress', 'completed'],
    default: 'pending',
  },

  startLat: Number,
  startLng: Number,
  endLat: Number,
  endLng: Number,
  startedAt: Date,
  finishedAt: Date,
}, { timestamps: true });

module.exports = mongoose.model('Task', taskSchema);

