// cash_advance_routes.js
const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const { CashAdvance, Worker, Farmer } = require('./server');

// นำเข้า routes ทั้งหมดที่สร้างด้านบนมาไว้ที่นี่
// cash_advance_routes.js - เพิ่ม endpoint สำหรับดึงข้อมูลโดยใช้ user-id header
router.get('/user-requests/:userId', async (req, res) => {
  const { userId } = req.params;
  const headerUserId = req.headers['user-id'];

  if (!headerUserId || headerUserId !== userId) {
    return res.status(401).json({
      success: false,
      message: 'Unauthorized access'
    });
  }

  try {
    const requests = await CashAdvance.find({
      userId: new mongoose.Types.ObjectId(userId)
    }).populate('ownerId', 'name')
      .sort({ createdAt: -1 });

    // ✅ แก้ไขให้รวม purpose
    const formattedRequests = requests.map(request => ({
      _id: request._id,
      userId: request.userId,
      ownerId: request.ownerId,
      name: request.name,
      phone: request.phone,
      purpose: request.purpose, // ✅ เพิ่ม
      amount: request.amount,
      date: request.date.toISOString(),
      type: request.type,
      status: request.status,
      images: request.images || [],
      approvalImage: request.approvalImage,
      approvedAt: request.approvedAt ? request.approvedAt.toISOString() : null,
      rejectedAt: request.rejectedAt ? request.rejectedAt.toISOString() : null,
      rejectionReason: request.rejectionReason,
      createdAt: request.createdAt.toISOString(),
      updatedAt: request.updatedAt.toISOString()
    }));

    res.json({
      success: true,
      requests: formattedRequests
    });

  } catch (error) {
    console.error('Error fetching cash advance history:', error);
    res.status(500).json({
      success: false,
      message: 'เกิดข้อผิดพลาดในการดึงประวัติ',
      error: error.message
    });
  }
});
module.exports = router;