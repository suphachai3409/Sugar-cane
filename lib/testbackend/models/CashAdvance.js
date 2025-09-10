// models/CashAdvance.js
const mongoose = require('mongoose');

if (mongoose.models.CashAdvance) {
  module.exports = mongoose.models.CashAdvance;
} else {
  const cashAdvanceSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  ownerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  name: { type: String, required: true },
  phone: { type: String, required: true },
  purpose: { type: String, required: true },
  amount: { type: String, required: true },
  date: { type: Date, required: true },
  type: { type: String, enum: ['worker', 'farmer'], required: true },
  status: { type: String, enum: ['pending', 'approved', 'rejected'], default: 'pending' },
  images: [{ type: String }],
  approvalImage: { type: String },
  approvedAt: { type: Date },
  rejectionReason: { type: String }, // ✅ เพิ่มฟิลด์เหตุผลการปฏิเสธ
  rejectedAt: { type: Date },        // ✅ เพิ่มฟิลด์วันที่ปฏิเสธ
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

  cashAdvanceSchema.pre('save', function(next) {
    this.updatedAt = Date.now();
    next();
  });

  module.exports = mongoose.model('CashAdvance', cashAdvanceSchema);
}