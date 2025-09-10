// models/Farmer.js
const mongoose = require('mongoose');

if (mongoose.models.Farmer) {
  module.exports = mongoose.models.Farmer;
} else {
  const farmerSchema = new mongoose.Schema({
    name: String,
    phone: String,
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    ownerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    relationCode: String,
    createdAt: { type: Date, default: Date.now }
  });

  module.exports = mongoose.model('Farmer', farmerSchema);
}