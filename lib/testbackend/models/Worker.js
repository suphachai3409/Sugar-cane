// models/Worker.js
const mongoose = require('mongoose');

// ตรวจสอบว่ามี model นี้แล้วหรือยัง
if (mongoose.models.Worker) {
  module.exports = mongoose.models.Worker;
} else {
  const workerSchema = new mongoose.Schema({
    name: String,
    phone: String,
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    ownerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    relationCode: String,
    createdAt: { type: Date, default: Date.now }
  });

  module.exports = mongoose.model('Worker', workerSchema);
}