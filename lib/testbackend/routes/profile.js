//profile.js
const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');

// Import User model (ต้องแน่ใจว่ามี User model)
const User = mongoose.model('User');

// ใช้ db จาก mongoose
const db = mongoose.connection;

// ===== Schema และ Model สำหรับ RelationCodeMap =====
const relationCodeMapSchema = new mongoose.Schema({
  code: { type: String, required: true, unique: true },
  ownerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  type: { type: String, enum: ['worker', 'farmer'], required: true },
  isUsed: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now },
  expiresAt: { type: Date, default: Date.now, expires: 86400 } // หมดอายุ 24 ชั่วโมง
});
const RelationCodeMap = mongoose.model('RelationCodeMap', relationCodeMapSchema);

// ===== Schema และ Model สำหรับ Worker =====
const workerSchema = new mongoose.Schema({
  name: String,
  phone: String,
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }, // user ที่เป็นคนงาน
  ownerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }, // อ้างอิงเจ้าของ
  relationCode: String, // รหัสความสัมพันธ์
  createdAt: { type: Date, default: Date.now }
});
const Worker = mongoose.model('Worker', workerSchema);

// ===== Schema และ Model สำหรับ Farmer =====
const farmerSchema = new mongoose.Schema({
  name: String,
  phone: String,
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }, // user ที่เป็นลูกไร่
  ownerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }, // อ้างอิงเจ้าของ
  relationCode: String, // รหัสความสัมพันธ์
  createdAt: { type: Date, default: Date.now }
});
const Farmer = mongoose.model('Farmer', farmerSchema);

// สร้างรหัสความสัมพันธ์ (สุ่มรหัส)
function generateRelationCode() {
  const code = Math.random().toString(36).substring(2, 8).toUpperCase();
  console.log(`🎲 Generated relation code: ${code} at ${new Date().toLocaleString('th-TH')}`);
  return code;
}

// สร้างรหัสสำหรับคนงาน
router.post('/create-worker-code', async (req, res) => {
  console.log('📞 API Called: /create-worker-code at', new Date().toLocaleString('th-TH'));
  console.log('📝 Request body:', req.body);
  
  try {
    const { ownerId } = req.body;
    
    if (!ownerId) {
      console.log('❌ Error: ownerId not provided');
      return res.status(400).json({ message: 'ต้องระบุ ownerId' });
    }

    console.log(`👤 Creating worker code for ownerId: ${ownerId}`);
    const code = generateRelationCode();
    
    // บันทึกรหัสลงฐานข้อมูล
    const relationCode = new RelationCodeMap({
      code: code,
      ownerId: ownerId,
      type: 'worker',
      expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000) // หมดอายุใน 24 ชั่วโมง
    });
    
    await relationCode.save();
    console.log(`✅ Worker code saved to database: ${code}`);
    
    const response = { 
      success: true,
      code: code,
      message: 'สร้างรหัสสำหรับคนงานสำเร็จ',
      expiresAt: relationCode.expiresAt
    };
    
    console.log('📤 Response sent:', response);
    res.status(200).json(response);
  } catch (error) {
    console.log('❌ Error in create-worker-code:', error.message);
    res.status(500).json({ 
      success: false,
      message: 'เกิดข้อผิดพลาดในการสร้างรหัส', 
      error: error.message 
    });
  }
});

// สร้างรหัสสำหรับลูกไร่
router.post('/create-farmer-code', async (req, res) => {
  console.log('📞 API Called: /create-farmer-code at', new Date().toLocaleString('th-TH'));
  console.log('📝 Request body:', req.body);
  
  try {
    const { ownerId } = req.body;
    
    if (!ownerId) {
      console.log('❌ Error: ownerId not provided');
      return res.status(400).json({ message: 'ต้องระบุ ownerId' });
    }

    console.log(`👤 Creating farmer code for ownerId: ${ownerId}`);
    const code = generateRelationCode();
    
    // บันทึกรหัสลงฐานข้อมูล
    const relationCode = new RelationCodeMap({
      code: code,
      ownerId: ownerId,
      type: 'farmer',
      expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000) // หมดอายุใน 24 ชั่วโมง
    });
    
    await relationCode.save();
    console.log(`✅ Farmer code saved to database: ${code}`);
    
    const response = { 
      success: true,
      code: code,
      message: 'สร้างรหัสสำหรับลูกไร่สำเร็จ',
      expiresAt: relationCode.expiresAt
    };
    
    console.log('📤 Response sent:', response);
    res.status(200).json(response);
  } catch (error) {
    console.log('❌ Error in create-farmer-code:', error.message);
    res.status(500).json({ 
      success: false,
      message: 'เกิดข้อผิดพลาดในการสร้างรหัส', 
      error: error.message 
    });
  }
});

// เพิ่มคนงาน
router.post('/add-worker', async (req, res) => {
  try {
    const { relationCode } = req.body;
    const user = req.user; // ต้องมี middleware auth
    
    if (!relationCode) {
      return res.status(400).json({ message: 'ต้องระบุรหัสความสัมพันธ์' });
    }

    // หา relation code และตรวจสอบความถูกต้อง
    const relation = await RelationCodeMap.findOne({ 
      code: relationCode,
      type: 'worker',
      isUsed: false 
    });
    
    if (!relation) {
      return res.status(400).json({ message: 'รหัสไม่ถูกต้อง หรือถูกใช้ไปแล้ว หรือไม่ใช่รหัสสำหรับคนงาน' });
    }

    // ตรวจสอบว่าหมดอายุหรือยัง
    if (relation.expiresAt < new Date()) {
      return res.status(400).json({ message: 'รหัสหมดอายุแล้ว' });
    }

    // ตรวจสอบว่า user คนนี้เป็นคนงานของ owner คนนี้อยู่แล้วหรือไม่
    const existingWorker = await Worker.findOne({ 
      userId: user._id, 
      ownerId: relation.ownerId 
    });
    
    if (existingWorker) {
      return res.status(400).json({ message: 'คุณเป็นคนงานของเจ้าของคนนี้อยู่แล้ว' });
    }

    // สร้าง worker ใหม่
    const newWorker = new Worker({
      name: user.name,
      phone: user.phone,
      userId: user._id,
      ownerId: relation.ownerId,
      relationCode: relationCode
    });
    
    await newWorker.save();

    // อัปเดตสถานะรหัสให้เป็นถูกใช้แล้ว
    await RelationCodeMap.findByIdAndUpdate(relation._id, { isUsed: true });

    // อัปเดต user menu เป็น worker (menu3)
    await User.findByIdAndUpdate(user._id, { menu: 3 });

    res.status(200).json({ 
      success: true,
      message: 'เชื่อมโยงเป็นคนงานสำเร็จ',
      worker: newWorker
    });
  } catch (error) {
    res.status(500).json({ 
      success: false,
      message: 'เกิดข้อผิดพลาดในการเพิ่มคนงาน', 
      error: error.message 
    });
  }
});

// เพิ่มลูกไร่
router.post('/add-farmer', async (req, res) => {
  try {
    const { relationCode } = req.body;
    const user = req.user;
    
    if (!relationCode) {
      return res.status(400).json({ message: 'ต้องระบุรหัสความสัมพันธ์' });
    }

    // หา relation code และตรวจสอบความถูกต้อง
    const relation = await RelationCodeMap.findOne({ 
      code: relationCode,
      type: 'farmer',
      isUsed: false 
    });
    
    if (!relation) {
      return res.status(400).json({ message: 'รหัสไม่ถูกต้อง หรือถูกใช้ไปแล้ว หรือไม่ใช่รหัสสำหรับลูกไร่' });
    }

    // ตรวจสอบว่าหมดอายุหรือยัง
    if (relation.expiresAt < new Date()) {
      return res.status(400).json({ message: 'รหัสหมดอายุแล้ว' });
    }

    // ตรวจสอบว่า user คนนี้เป็นลูกไร่ของ owner คนนี้อยู่แล้วหรือไม่
    const existingFarmer = await Farmer.findOne({ 
      userId: user._id, 
      ownerId: relation.ownerId 
    });
    
    if (existingFarmer) {
      return res.status(400).json({ message: 'คุณเป็นลูกไร่ของเจ้าของคนนี้อยู่แล้ว' });
    }

    // สร้าง farmer ใหม่
    const newFarmer = new Farmer({
      name: user.name,
      phone: user.phone,
      userId: user._id,
      ownerId: relation.ownerId,
      relationCode: relationCode
    });
    
    await newFarmer.save();

    // อัปเดตสถานะรหัสให้เป็นถูกใช้แล้ว
    await RelationCodeMap.findByIdAndUpdate(relation._id, { isUsed: true });

    // อัปเดต user menu เป็น farmer (menu2)
    await User.findByIdAndUpdate(user._id, { menu: 2 });

    res.status(200).json({ 
      success: true,
      message: 'เชื่อมโยงเป็นลูกไร่สำเร็จ',
      farmer: newFarmer
    });
  } catch (error) {
    res.status(500).json({ 
      success: false,
      message: 'เกิดข้อผิดพลาดในการเพิ่มลูกไร่', 
      error: error.message 
    });
  }
});

// ดึงคนงานของเจ้าของ
router.get('/workers/:ownerId', async (req, res) => {
  const { ownerId } = req.params;
  try {
    const workers = await Worker.find({ ownerId }).populate('userId', 'name email number profileImage username');
    res.status(200).json({
      success: true,
      workers: workers
    });
  } catch (error) {
    res.status(500).json({ 
      success: false,
      message: 'เกิดข้อผิดพลาดในการดึงข้อมูลคนงาน', 
      error: error.message 
    });
  }
});

// ดึงลูกไร่ของเจ้าของ
router.get('/farmers/:ownerId', async (req, res) => {
  const { ownerId } = req.params;
  try {
    const farmers = await Farmer.find({ ownerId }).populate('userId', 'name email number profileImage username');
    res.status(200).json({
      success: true,
      farmers: farmers
    });
  } catch (error) {
    res.status(500).json({ 
      success: false,
      message: 'เกิดข้อผิดพลาดในการดึงข้อมูลลูกไร่', 
      error: error.message 
    });
  }
});

// ดึงรหัสที่ยังไม่ได้ใช้ของเจ้าของ
router.get('/relation-codes/:ownerId', async (req, res) => {
  const { ownerId } = req.params;
  try {
    const codes = await RelationCodeMap.find({ 
      ownerId: ownerId,
      isUsed: false,
      expiresAt: { $gt: new Date() }
    }).sort({ createdAt: -1 });
    
    res.status(200).json({
      success: true,
      codes: codes
    });
  } catch (error) {
    res.status(500).json({ 
      success: false,
      message: 'เกิดข้อผิดพลาดในการดึงข้อมูลรหัส', 
      error: error.message 
    });
  }
});

// ===== ข้อมูล worker-info สำหรับทดสอบฝั่งแอป =====
// GET /api/profile/worker-info/:userId -> คืน ownerId ของเจ้าของที่สัมพันธ์กับ worker (userId คนงาน)
router.get('/worker-info/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const isValid = mongoose.Types.ObjectId.isValid(userId);
    const criteria = isValid ? { userId: new mongoose.Types.ObjectId(userId) } : { userId };

    const worker = await mongoose.model('Worker').findOne(criteria);

    if (!worker) {
      return res.status(200).json({ success: true, worker: null });
    }

    // ส่งกลับ ownerId/userId เป็น string เพื่อให้ frontend ใช้งานง่าย
    return res.status(200).json({
      success: true,
      worker: {
        userId: worker.userId?.toString?.() ?? worker.userId,
        ownerId: worker.ownerId?.toString?.() ?? worker.ownerId,
      }
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'เกิดข้อผิดพลาดในการดึง worker-info', error: error.message });
  }
});

module.exports = router;