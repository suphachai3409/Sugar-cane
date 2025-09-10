// models/RelationCodeMap.js
const mongoose = require('mongoose');

if (mongoose.models.RelationCodeMap) {
  module.exports = mongoose.models.RelationCodeMap;
} else {
  const relationCodeMapSchema = new mongoose.Schema({
    code: { type: String, required: true, unique: true },
    ownerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    type: { type: String, enum: ['worker', 'farmer'], required: true },
    isUsed: { type: Boolean, default: false },
    createdAt: { type: Date, default: Date.now },
    expiresAt: { type: Date, default: Date.now, expires: 86400 }
  });

  module.exports = mongoose.model('RelationCodeMap', relationCodeMapSchema);
}