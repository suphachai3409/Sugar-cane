const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const authMiddleware = require('../auth_middleware'); // ตรวจสอบ path ให้ถูกต้อง
// สร้าง Schema สำหรับอุปกรณ์
const equipmentSchema = new mongoose.Schema({
  userId: { type: String, required: true },
  name: { type: String, required: true },
  phone: { type: String, required: true },
  equipmentName: { type: String, required: true },
  description: { type: String, required: true },
  date: { type: Date, required: true },
  imagePaths: { type: [String], required: true },
  menu: { type: Number, required: true },
  createdAt: { type: Date, default: Date.now },
});

// สร้าง Model จาก Schema
const Equipment = mongoose.model('Equipment', equipmentSchema);

// ใช้ authMiddleware จากไฟล์ auth_middleware.js แทน

// เส้นทาง API สำหรับดึงข้อมูลอุปกรณ์ทั้งหมด
router.get('/', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id;
    console.log('🔍 Fetching equipment for userId:', userId);
    
    // ดึงข้อมูลอุปกรณ์ทั้งหมด (frontend จะกรองเอง)
    const equipment = await Equipment.find({});
    
    console.log('✅ Found equipment:', equipment.length);
    res.status(200).json(equipment);
  } catch (error) {
    console.error('❌ Error fetching equipment:', error);
    res.status(500).json({ 
      message: 'Error fetching equipment', 
      error: error.message 
    });
  }
});

// เส้นทาง API สำหรับบันทึกข้อมูลอุปกรณ์ใหม่
router.post('/', authMiddleware, async (req, res) => {
  try {
    // ตรวจสอบว่ามีข้อมูลที่จำเป็นครบถ้วนหรือไม่
    const { name, phone, equipmentName, description, date, imagePaths, menu } = req.body;
    
    if (!name || !phone || !equipmentName || !description || !date || !imagePaths || !menu) {
      return res.status(400).json({ message: 'ข้อมูลไม่ครบถ้วน' });
    }

    const newEquipment = new Equipment({
      userId: req.user.id, // ใช้ userId จาก authMiddleware
      name,
      phone,
      equipmentName,
      description,
      date: new Date(date),
      imagePaths,
      menu: Number(menu),
    });

    await newEquipment.save();
    console.log('✅ Equipment saved:', newEquipment._id);
    res.status(201).json(newEquipment);
  } catch (error) {
    console.error('❌ Error saving equipment:', error);
    res.status(500).json({ 
      message: 'Error saving equipment',
      error: error.message 
    });
  }
});

// เส้นทาง API สำหรับแก้ไขข้อมูลอุปกรณ์
router.put('/:id', authMiddleware, async (req, res) => {
  const { id } = req.params;
  
  try {
    // ตรวจสอบว่ามีข้อมูลที่จำเป็นครบถ้วนหรือไม่
    const { name, phone, equipmentName, description, date, imagePaths, menu } = req.body;
    
    if (!name || !phone || !equipmentName || !description || !date || !imagePaths || !menu) {
      return res.status(400).json({ message: 'ข้อมูลไม่ครบถ้วน' });
    }

    // ตรวจสอบว่าเป็นเจ้าของอุปกรณ์หรือไม่
    const equipment = await Equipment.findById(id);
    if (!equipment) {
      return res.status(404).json({ message: 'ไม่พบอุปกรณ์' });
    }
    
    if (equipment.userId !== req.user.id) {
      return res.status(403).json({ message: 'ไม่มีสิทธิ์แก้ไขอุปกรณ์นี้' });
    }

    const updatedEquipment = await Equipment.findByIdAndUpdate(
      id,
      {
        name,
        phone,
        equipmentName,
        description,
        date: new Date(date),
        imagePaths,
        menu: Number(menu),
      },
      { new: true }
    );
    
    console.log('✅ Equipment updated:', id);
    res.status(200).json(updatedEquipment);
  } catch (error) {
    console.error('❌ Error updating equipment:', error);
    res.status(500).json({ 
      message: 'Error updating equipment',
      error: error.message 
    });
  }
});

// ในส่วนของการลบอุปกรณ์
router.delete('/:id', authMiddleware, async (req, res) => {
  const { id } = req.params;
  
  try {
    const equipment = await Equipment.findById(id);
    if (!equipment) {
      return res.status(404).json({ 
        success: false,
        message: 'ไม่พบอุปกรณ์' 
      });
    }
    
    // ตรวจสอบสิทธิ์
    if (equipment.userId !== req.user.id && req.user.menu !== 1) {
      return res.status(403).json({ 
        success: false,
        message: 'ไม่มีสิทธิ์ลบอุปกรณ์นี้' 
      });
    }

    await Equipment.findByIdAndDelete(id);
    res.status(200).json({ 
      success: true,
      message: 'ลบอุปกรณ์สำเร็จ' 
    });
  } catch (error) {
    res.status(500).json({ 
      success: false,
      message: 'Error deleting equipment', 
      error: error.message 
    });
  }
});

module.exports = router;