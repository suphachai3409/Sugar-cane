// routes/cashAdvanceRoutes.js
const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const CashAdvance = require('../models/CashAdvance');
const Worker = require('../models/Worker');
const Farmer = require('../models/Farmer');

// Middleware สำหรับตรวจสอบ user-id header
const checkUserIdHeader = (req, res, next) => {
  // ใช้เฉพาะกับ route /user-requests
  if (req.path.startsWith('/user-requests')) {
    // แก้ไขการดึง userId จาก params ให้ถูกต้อง
    const pathParts = req.path.split('/');
    const userId = pathParts[pathParts.length - 1]; // ดึง userId จาก path แทน

    const headerUserId = req.headers['user-id'];

    console.log('🔍 Checking user-id header:', {
      path: req.path,
      extractedUserId: userId,
      headerUserId: headerUserId
    });

    if (!headerUserId) {
      console.log('⚠️ No user-id header found');
      return res.status(401).json({
        success: false,
        message: 'Missing user-id header'
      });
    }

    if (headerUserId !== userId) {
      console.log('❌ user-id header mismatch');
      return res.status(401).json({
        success: false,
        message: 'Unauthorized access - user-id header mismatch'
      });
    }

    console.log('✅ user-id header matched, proceeding');
    return next();
  }
  next();
};

// ใช้ middleware สำหรับทุก route ในไฟล์นี้
router.use(checkUserIdHeader);

// ตรวจสอบความสัมพันธ์ก่อนเบิกเงิน
router.get('/check-relation/:userId/:ownerId', async (req, res) => {
  const { userId, ownerId } = req.params;

  console.log('🔍 ตรวจสอบความสัมพันธ์:');
  console.log('   - userId:', userId);
  console.log('   - ownerId:', ownerId);

  try {
    // ตรวจสอบว่าเป็นคนงานของ owner หรือไม่
    const worker = await Worker.findOne({
      userId: new mongoose.Types.ObjectId(userId),
      ownerId: new mongoose.Types.ObjectId(ownerId)
    });

    console.log('👷 ผลการค้นหาคนงาน:', worker);

    if (worker) {
      return res.json({
        success: true,
        type: 'worker',
        message: 'เป็นคนงานของเจ้าของนี้'
      });
    }

    // ตรวจสอบว่าเป็นลูกไร่ของ owner หรือไม่
    const farmer = await Farmer.findOne({
      userId: new mongoose.Types.ObjectId(userId),
      ownerId: new mongoose.Types.ObjectId(ownerId)
    });

    console.log('👨‍🌾 ผลการค้นหาลูกไร่:', farmer);

    if (farmer) {
      return res.json({
        success: true,
        type: 'farmer',
        message: 'เป็นลูกไร่ของเจ้าของนี้'
      });
    }

    // ถ้าไม่พบความสัมพันธ์
    console.log('❌ ไม่พบความสัมพันธ์ใดๆ');
    res.json({
      success: false,
      message: 'ไม่มีสิทธิ์เบิกเงินจากเจ้าของนี้'
    });

  } catch (error) {
    console.error('❌ Error checking relation:', error);
    res.status(500).json({
      success: false,
      message: 'เกิดข้อผิดพลาดในการตรวจสอบความสัมพันธ์',
      error: error.message
    });
  }
});

// ส่งคำขอเบิกเงิน
// ใน route POST /request
router.post('/request', async (req, res) => {
  const { userId, ownerId, name, phone, purpose, amount, date, type, images } = req.body;

  console.log('📥 Received cash advance request:', {
    userId, ownerId, name, phone, purpose, amount, date, type, images
  });

  try {
    // ตรวจสอบว่ามีคำขอที่ยังไม่處理อยู่แล้วหรือไม่
    const existingRequest = await CashAdvance.findOne({
      userId: new mongoose.Types.ObjectId(userId),
      ownerId: new mongoose.Types.ObjectId(ownerId),
      status: 'pending'
    });

    if (existingRequest) {
      console.log('❌ Already has pending request');
      return res.status(400).json({
        success: false,
        message: 'มีคำขอเบิกเงินที่ยังไม่อยู่แล้ว'
      });
    }

    // สร้างคำขอใหม่
    const newRequest = new CashAdvance({
      userId: new mongoose.Types.ObjectId(userId),
      ownerId: new mongoose.Types.ObjectId(ownerId),
      name,
      phone,
      purpose, // ✅ ใช้ purpose จาก request
      amount,
      date: new Date(date),
      type,
      images: images || [],
      status: 'pending'
    });

    await newRequest.save();

    console.log('✅ Cash advance request saved:', newRequest._id);

    res.status(201).json({
      success: true,
      message: 'ส่งคำขอเบิกเงินเรียบร้อย',
      requestId: newRequest._id
    });

  } catch (error) {
    console.error('❌ Error creating cash advance request:', error);
    res.status(500).json({
      success: false,
      message: 'เกิดข้อผิดพลาดในการส่งคำขอ',
      error: error.message
    });
  }
});

// ดึงคำขอเบิกเงินตาม owner และ type
// ใน cashAdvanceRoutes.js - แก้ไข endpoint /requests
router.get('/requests/:ownerId/:type', async (req, res) => {
  const { ownerId, type } = req.params;
  const headerUserId = req.headers['user-id'];

  console.log('📥 ดึงคำขอเบิกเงินสำหรับ owner:', ownerId, 'type:', type);
  console.log('📥 Header user-id:', headerUserId);

  // ตรวจสอบว่า header user-id ตรงกับ ownerId (เจ้าของต้องเป็นคนดึงข้อมูลของตัวเอง)
  if (headerUserId && headerUserId !== ownerId) {
    return res.status(401).json({
      success: false,
      message: 'Unauthorized access - คุณไม่มีสิทธิ์ดูข้อมูลนี้'
    });
  }

  try {
    // ดึงคำขอเบิกเงินทั้งหมดของ owner ที่มีสถานะ pending
    const requests = await CashAdvance.find({
      ownerId: new mongoose.Types.ObjectId(ownerId),
      type: type,
      status: 'pending'
    }).populate('userId', 'name email number profileImage'); // populate ข้อมูล user

    console.log('✅ พบคำขอเบิกเงินจำนวน:', requests.length, 'สำหรับ', type);

    res.json({
      success: true,
      requests: requests
    });

  } catch (error) {
    console.error('❌ Error fetching cash advance requests:', error);
    res.status(500).json({
      success: false,
      message: 'เกิดข้อผิดพลาดในการดึงคำขอ',
      error: error.message
    });
  }
});

// ✅ เพิ่ม endpoint ใหม่สำหรับดึงคำขอทั้งหมดของ owner
router.get('/owner-requests/:ownerId', async (req, res) => {
  const { ownerId } = req.params;
  const headerUserId = req.headers['user-id'];

  console.log('📥 ดึงคำขอเบิกเงินทั้งหมดสำหรับ owner:', ownerId);

  // ตรวจสอบสิทธิ์
  if (headerUserId && headerUserId !== ownerId) {
    return res.status(401).json({
      success: false,
      message: 'Unauthorized access'
    });
  }

  try {
    // ดึงคำขอเบิกเงินทั้งหมดของ owner (ทั้ง worker และ farmer)
    const requests = await CashAdvance.find({
      ownerId: new mongoose.Types.ObjectId(ownerId),
      status: 'pending'
    }).populate('userId', 'name email number profileImage')
      .sort({ createdAt: -1 });

    console.log('✅ พบคำขอเบิกเงินทั้งหมดจำนวน:', requests.length);

    res.json({
      success: true,
      requests: requests
    });

  } catch (error) {
    console.error('❌ Error fetching all owner requests:', error);
    res.status(500).json({
      success: false,
      message: 'เกิดข้อผิดพลาดในการดึงคำขอทั้งหมด',
      error: error.message
    });
  }
});

// อัปเดตสถานะคำขอเบิกเงิน
router.put('/request/:requestId', async (req, res) => {
  const { requestId } = req.params;
  const { status, approvalImage, rejectionReason } = req.body; // ✅ เพิ่ม rejectionReason
  const headerUserId = req.headers['user-id'];

  console.log('📤 Updating request status:', {
    requestId,
    status,
    approvalImage,
    rejectionReason, // ✅ log เหตุผลการปฏิเสธ
    headerUserId
  });

  try {
    const updateData = {
      status: status,
      updatedAt: new Date()
    };

    // ถ้ามีรูปภาพการอนุมัติ
    if (approvalImage) {
      updateData.approvalImage = approvalImage;
      updateData.approvedAt = new Date();
    }

    // ✅ ถ้ามีเหตุผลการปฏิเสธ
    if (rejectionReason) {
      updateData.rejectionReason = rejectionReason;
      updateData.rejectedAt = new Date();
    }

    const updatedRequest = await CashAdvance.findByIdAndUpdate(
      requestId,
      updateData,
      { new: true }
    ).populate('userId', 'name email'); // ✅ populate ข้อมูล user

    if (!updatedRequest) {
      return res.status(404).json({
        success: false,
        message: 'ไม่พบคำขอเบิกเงิน'
      });
    }

    console.log('✅ Request updated successfully:', updatedRequest);

    res.json({
      success: true,
      message: 'อัปเดตสถานะคำขอเรียบร้อย',
      request: updatedRequest
    });

  } catch (error) {
    console.error('❌ Error updating cash advance request:', error);
    res.status(500).json({
      success: false,
      message: 'เกิดข้อผิดพลาดในการอัปเดตสถานะ',
      error: error.message
    });
  }
});
// ลบคำขอ (soft delete - เก็บข้อมูลไว้แต่ไม่แสดง)
// ลบคำขอ (soft delete)
router.delete('/request/:requestId', async (req, res) => {
  const { requestId } = req.params;
  const headerUserId = req.headers['user-id'];

  console.log('🗑️ Soft deleting request:', requestId);

  try {
    // ตรวจสอบสิทธิ์การเข้าถึง
    const request = await CashAdvance.findById(requestId);
    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'ไม่พบคำขอเบิกเงิน'
      });
    }

    // ตรวจสอบว่า user มีสิทธิ์ลบคำขอนี้หรือไม่
    if (request.userId.toString() !== headerUserId) {
      return res.status(403).json({
        success: false,
        message: 'ไม่มีสิทธิ์ลบคำขอนี้'
      });
    }

    // ทำ soft delete โดยอัปเดตสถานะ
    const updatedRequest = await CashAdvance.findByIdAndUpdate(
      requestId,
      {
        status: 'deleted',
        deletedAt: new Date(),
        updatedAt: new Date()
      },
      { new: true }
    );

    console.log('✅ Request soft deleted successfully');

    res.json({
      success: true,
      message: 'ลบคำขอเรียบร้อย'
    });

  } catch (error) {
    console.error('❌ Error soft deleting cash advance request:', error);
    res.status(500).json({
      success: false,
      message: 'เกิดข้อผิดพลาดในการลบคำขอ',
      error: error.message
    });
  }
});

// ดึงประวัติคำขอเบิกเงินของผู้ใช้
router.get('/user-requests/:userId', async (req, res) => {
  const { userId } = req.params;
  const headerUserId = req.headers['user-id'];

  console.log('📥 ดึงประวัติคำขอเบิกเงินสำหรับ user:', userId);
  console.log('📥 Headers user-id:', headerUserId);

  // ตรวจสอบให้แน่ใจว่า userId ถูกต้อง
  if (!mongoose.Types.ObjectId.isValid(userId)) {
    return res.status(400).json({
      success: false,
      message: 'Invalid user ID format'
    });
  }


  try {
    const requests = await CashAdvance.find({
      userId: new mongoose.Types.ObjectId(userId),
      status: { $ne: 'deleted' } // ✅ ไม่แสดงคำขอที่ถูกลบแล้ว
    })
      .populate('ownerId', 'name profileImage')
      .populate('userId', 'name profileImage')
      .sort({ createdAt: -1 });

    console.log('✅ พบคำขอเบิกเงินจำนวน:', requests.length);

    // แปลงข้อมูลให้เหมาะสมสำหรับ frontend
    const formattedRequests = requests.map(request => ({
      _id: request._id,
      userId: request.userId,
      ownerId: request.ownerId,
      name: request.name,
      phone: request.phone,
      purpose: request.purpose, // ✅ เพิ่มบรรทัดนี้
      amount: request.amount,
      date: request.date.toISOString(),
      type: request.type,
      status: request.status,
      images: request.images || [],
      approvalImage: request.approvalImage,
      approvedAt: request.approvedAt ? request.approvedAt.toISOString() : null,
      rejectedAt: request.rejectedAt ? request.rejectedAt.toISOString() : null, // ✅ เพิ่มด้วย
      rejectionReason: request.rejectionReason, // ✅ เพิ่มด้วย
      createdAt: request.createdAt.toISOString(),
      updatedAt: request.updatedAt.toISOString()
    }));

    res.json({
      success: true,
      requests: formattedRequests
    });

  } catch (error) {
    console.error('❌ Error fetching cash advance history:', error);
    res.status(500).json({
      success: false,
      message: 'เกิดข้อผิดพลาดในการดึงประวัติ',
      error: error.message
    });
  }
});

module.exports = router;