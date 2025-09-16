const express = require('express');
const mongoose = require('mongoose');
const bodyParser = require('body-parser');
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const cloudinary = require('./cloudinary');

const app = express();
app.use(bodyParser.json());
app.use(cors());

// ===== Multer สำหรับอัปโหลดรูป =====
// ใช้ memory storage สำหรับ Vercel (read-only file system)
const storage = multer.memoryStorage();
const upload = multer({ storage: storage });

// ===== เชื่อมต่อ MongoDB =====
mongoose.connect('mongodb+srv://sugarcanedata69:TpP8JDPaynmBSh4B@sugarcane.yatstlf.mongodb.net/sugar_cane?retryWrites=true&w=majority&appName=Sugarcane', {});

// ตรวจสอบการเชื่อมต่อ MongoDB
const db = mongoose.connection;
db.on('error', (error) => {
  console.error('Error connecting to MongoDB:', error);
});
db.once('open', () => {
  console.log('Connected to MongoDB successfully');
});

// ===== Schema และ Model =====
const userSchema = new mongoose.Schema({
  name: String,
  email: String,
  number: Number,
  username: String,
  password: String,
  menu: { type: Number, default: 1 },
  profileImage: String, // เก็บชื่อไฟล์รูป
});
const User = mongoose.model('User', userSchema);

// ===== IMPORT MODELS =====
const CashAdvance = require('./models/CashAdvance');


// ให้สามารถใช้ใน auth_middleware และ profile
module.exports.User = User;
module.exports.db = db;

module.exports.CashAdvance = CashAdvance;


// ===== router: ROOT ENDPOINT =====
app.get('/', (req, res) => {
  res.json({ 
    message: 'Sugar Cane API is running!',
    status: 'success',
    timestamp: new Date().toISOString()
  });
});

// ลงทะเบียนผู้ใช้ (รองรับอัปโหลดรูป)
app.post('/register', upload.single('profileImage'), async (req, res) => {
  console.log('=== REGISTER REQUEST ===');
  console.log('Body:', req.body);
  console.log('File:', req.file);
  
  const { name, email, number, username, password, relationCode } = req.body;
  
  // ตรวจสอบข้อมูลที่จำเป็น
  if (!name || !email || !number || !username || !password) {
    console.log('Missing required fields');
    return res.status(400).json({ 
      message: 'Missing required fields',
      required: ['name', 'email', 'number', 'username', 'password']
    });
  }
  
  let userData = { name, email, number, username, password };
  
  // เพิ่มรูปภาพถ้ามี
  if (req.file) {
    try {
      console.log('🔄 กำลังอัพโหลดรูปไปยัง Cloudinary...');
      
      // แก้ไข: ใช้ Promise แทน callback
      const result = await new Promise((resolve, reject) => {
        cloudinary.uploader.upload_stream({
          folder: 'sugarcane-profiles',
          resource_type: 'auto',
          use_filename: true,
          unique_filename: true,
          overwrite: false,
          transformation: [
            { width: 400, height: 400, crop: 'fill', gravity: 'face' }
          ]
        }, (error, result) => {
          if (error) {
            console.error('Cloudinary upload error:', error);
            reject(error);
          } else {
            resolve(result);
          }
        }).end(req.file.buffer);
      });
      
      userData.profileImage = result.secure_url;
      console.log('✅ Profile image uploaded to Cloudinary:', result.secure_url);
    } catch (error) {
      console.error('❌ Cloudinary upload error:', error);
      return res.status(500).json({ 
        message: 'Image upload failed',
        error: error.message 
      });
    }
  }
  
  console.log('User data to save:', userData);
  
  const newUser = new User(userData);
  try {
    const savedUser = await newUser.save();
    console.log('User saved successfully:', savedUser);
    
    res.status(200).json({ 
      message: 'User registered successfully',
      user: {
        _id: savedUser._id,
        name: savedUser.name,
        email: savedUser.email,
        number: savedUser.number,
        username: savedUser.username,
        profileImage: savedUser.profileImage
      }
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ message: 'Error registering user', error: error.message });
  }
});

// ===== API ดึงผู้ใช้ทั้งหมด =====
app.get('/pulluser', async (req, res) => {
  try {
    const users = await User.find();
    res.status(200).json(users);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching users', error });
  }
});

// อัปเดตข้อมูลผู้ใช้ (รองรับอัปโหลดรูป)
app.put('/updateuser/:id', upload.single('profileImage'), async (req, res) => {
  const { id } = req.params;
  const { name, email, number, username, password, menu } = req.body;
  let updateData = { name, email, number, username, password, menu };

  if (req.file) {
    try {
      console.log('🔄 กำลังอัพโหลดรูปไปยัง Cloudinary...');
      
      // แก้ไข: ใช้ Promise แทน callback
      const result = await new Promise((resolve, reject) => {
        cloudinary.uploader.upload_stream({
          folder: 'sugarcane-profiles',
          resource_type: 'auto',
          use_filename: true,
          unique_filename: true,
          overwrite: false,
          transformation: [
            { width: 400, height: 400, crop: 'fill', gravity: 'face' }
          ]
        }, (error, result) => {
          if (error) {
            console.error('Cloudinary upload error:', error);
            reject(error);
          } else {
            resolve(result);
          }
        }).end(req.file.buffer);
      });
      
      updateData.profileImage = result.secure_url;
      console.log('✅ Profile image updated in Cloudinary:', result.secure_url);
    } catch (error) {
      console.error('❌ Cloudinary upload error:', error);
      return res.status(500).json({ 
        message: 'Image upload failed',
        error: error.message 
      });
    }
  }

  try {
    await User.findByIdAndUpdate(id, updateData);
    res.status(200).json({ message: 'User updated successfully' });
  } catch (error) {
    res.status(500).json({ message: 'Error updating user', error });
  }
});

// ล็อกอิน
app.post('/login', async (req, res) => {
  const { username, password } = req.body;
  try {
    const user = await User.findOne({ username, password });
    if (user) {
      res.status(200).json({
        message: 'Login successful',
        user: {
          _id: user._id,
          username: user.username,
          menu: user.menu,
          profileImage: user.profileImage // ส่งชื่อไฟล์รูปกลับไปด้วย
        }
      });
    } else {
      res.status(401).json({ message: 'Username or password incorrect' });
    }
  } catch (error) {
    res.status(500).json({ message: 'Error logging in', error });
  }
});

// ตรวจสอบ username availability
app.post('/api/check-username', async (req, res) => {
  try {
    const { username } = req.body;
    
    console.log('🔍 Checking username availability:', username);
    
    if (!username) {
      return res.status(400).json({
        success: false,
        message: 'Username is required'
      });
    }
    
    // ตรวจสอบในฐานข้อมูล
    const existingUser = await User.findOne({ username: username });
    
    if (existingUser) {
      // Username มีอยู่แล้ว
      console.log('❌ Username already exists:', username);
      return res.status(200).json({
        success: true,
        available: false,
        message: 'Username is already taken'
      });
    } else {
      // Username ว่าง
      console.log('✅ Username available:', username);
      return res.status(200).json({
        success: true,
        available: true,
        message: 'Username is available'
      });
    }
    
  } catch (error) {
    console.error('❌ Error checking username:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

// เพิ่ม endpoint อัพโหลดรูปภาพ
app.post('/api/upload', upload.single('image'), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ success: false, message: 'ไม่มีไฟล์ที่อัพโหลด' });
  }

  try {
    console.log('🔄 กำลังอัพโหลดรูปไปยัง Cloudinary...');
    
    // แก้ไข: ใช้ Promise แทน callback
    const result = await new Promise((resolve, reject) => {
        cloudinary.uploader.upload_stream({
          folder: 'sugarcane-uploads',
          resource_type: 'auto',
          use_filename: true,
          unique_filename: true,
          overwrite: false
        }, (error, result) => {
        if (error) {
          console.error('Cloudinary upload error:', error);
          reject(error);
        } else {
          resolve(result);
        }
      }).end(req.file.buffer);
    });

    console.log('✅ Image uploaded to Cloudinary:', result.secure_url);
    res.json({
      success: true,
      message: 'อัพโหลดสำเร็จ',
      imageUrl: result.secure_url
    });
  } catch (error) {
    console.error('❌ Cloudinary upload error:', error);
    res.status(500).json({ 
      success: false,
      message: 'Image upload failed',
      error: error.message 
    });
  }
});

// Static path ไม่ใช้แล้ว เพราะใช้ Cloudinary


// ===== IMPORT ROUTES และ MIDDLEWARE =====
const plotRoutes = require('./routes/plotRoutes');
const profileRoutes = require('./routes/profile');
const equipmentRoutes = require('./routes/equipment'); // เพิ่มบรรทัดนี้
const authMiddleware = require('./auth_middleware');
const cashAdvanceRoutes = require('./routes/cashAdvanceRoutes');

// ===== ROUTE: API แปลงปลูก =====
app.use('/api/plots', plotRoutes);

// ===== ROUTE: Profile ใช้ middleware ตรวจ token =====
app.use('/api/profile', authMiddleware, profileRoutes);

// ===== ROUTE: Equipment ใช้ middleware ตรวจ token =====
app.use('/api/equipment', authMiddleware, equipmentRoutes); // เพิ่มบรรทัดนี้

// ===== ROUTE: Cash Advance ใช้ middleware ตรวจ token =====
// ใน server.js
app.use('/api/cash-advance', (req, res, next) => {
  const headerUserId = req.headers['user-id'];
  const isRequestsRoute = req.path.startsWith('/requests/');
  
  // ✅ อนุญาตให้ข้าม auth สำหรับ route requests ถ้ามี header user-id
  if (isRequestsRoute && headerUserId) {
    console.log('🔄 Bypassing auth for requests with user-id header:', headerUserId);
    
    // ตั้งค่า req.user เผื่อต้องการใช้
    req.user = {
      id: headerUserId,
      menu: 1 // เมนูของเจ้าของ
    };
    
    return next();
  }
  
  // ข้าม auth สำหรับ route อื่นๆ
  if (req.path === '/check-relation' || 
      req.path.startsWith('/check-relation/') ||
      req.path === '/user-requests' ||
      req.path.startsWith('/user-requests/')) {
    return next();
  }
  
  // ใช้ auth middleware สำหรับ route อื่นๆ
  authMiddleware(req, res, next);
}, cashAdvanceRoutes);

// ใน server.js - แก้ไข endpoint ดึงคนงานและลูกไร่
app.get('/api/profile/workers/:ownerId', async (req, res) => {
  const { ownerId } = req.params;
  console.log('🔍 Fetching workers for ownerId:', ownerId);
  
  try {
    // ใช้ Worker model ที่ถูกต้อง
    const Worker = require('./models/Worker');
    const workers = await Worker.find({ ownerId: ownerId }).populate('userId', 'name email number profileImage username');
    
    console.log('✅ Found workers:', workers.length);
    console.log('📋 Workers data:', workers);
    
    res.status(200).json({
      success: true,
      workers: workers
    });
  } catch (error) {
    console.error('❌ Error fetching workers:', error);
    res.status(500).json({ 
      success: false,
      message: 'เกิดข้อผิดพลาดในการดึงข้อมูลคนงาน', 
      error: error.message 
    });
  }
});

app.get('/api/profile/farmers/:ownerId', async (req, res) => {
  const { ownerId } = req.params;
  console.log('🔍 Fetching farmers for ownerId:', ownerId);
  
  try {
    // ใช้ Farmer model ที่ถูกต้อง
    const Farmer = require('./models/Farmer');
    const farmers = await Farmer.find({ ownerId: ownerId }).populate('userId', 'name email number profileImage username');
    
    console.log('✅ Found farmers:', farmers.length);
    console.log('📋 Farmers data:', farmers);
    
    res.status(200).json({
      success: true,
      farmers: farmers
    });
  } catch (error) {
    console.error('❌ Error fetching farmers:', error);
    res.status(500).json({ 
      success: false,
      message: 'เกิดข้อผิดพลาดในการดึงข้อมูลลูกไร่', 
      error: error.message 
    });
  }
});

// เพิ่ม endpoint สำหรับตรวจสอบความสัมพันธ์ของผู้ใช้
app.get('/api/profile/check-relationship/:userId', async (req, res) => {
  const { userId } = req.params;
  console.log('🔍 Checking relationship for userId:', userId);
  
  try {
    const Worker = require('./models/Worker');
    const Farmer = require('./models/Farmer');
    
    // ตรวจสอบว่าเป็นคนงานของใคร
    const worker = await Worker.findOne({ userId: userId });
    if (worker) {
      console.log('✅ Found worker relationship:', worker.ownerId);
      return res.status(200).json({
        success: true,
        ownerId: worker.ownerId.toString(),
        userType: 'worker'
      });
    }
    
    // ตรวจสอบว่าเป็นลูกไร่ของใคร
    const farmer = await Farmer.findOne({ userId: userId });
    if (farmer) {
      console.log('✅ Found farmer relationship:', farmer.ownerId);
      return res.status(200).json({
        success: true,
        ownerId: farmer.ownerId.toString(),
        userType: 'farmer'
      });
    }
    
    // ถ้าไม่พบความสัมพันธ์ แสดงว่าผู้ใช้เป็นเจ้าของ
    console.log('ℹ️ No relationship found - user is likely an owner');
    return res.status(404).json({
      success: false,
      message: 'ไม่พบความสัมพันธ์ - ผู้ใช้อาจเป็นเจ้าของ'
    });
    
  } catch (error) {
    console.error('❌ Error checking relationship:', error);
    res.status(500).json({
      success: false,
      message: 'เกิดข้อผิดพลาดในการตรวจสอบความสัมพันธ์',
      error: error.message
    });
  }
});

// เพิ่ม endpoint สำหรับดึงจำนวนการขอเบิกเงินล่วงหน้าของคนงานแต่ละคน
app.get('/api/cash-advance/worker-notifications/:ownerId', async (req, res) => {
  const { ownerId } = req.params;
  console.log('🔔 Fetching worker notifications for ownerId:', ownerId);
  
  try {
    const CashAdvanceRequest = require('./models/CashAdvanceRequest');
    const Worker = require('./models/Worker');
    
    // ดึงข้อมูลคนงานทั้งหมดของเจ้าของ
    const workers = await Worker.find({ ownerId: ownerId }).populate('userId', 'name email phone profileImage');
    console.log('👥 Found workers:', workers.length);
    
    // สร้าง array สำหรับเก็บจำนวนการแจ้งเตือนของแต่ละคนงาน
    const workerNotifications = [];
    
    for (const worker of workers) {
      // นับจำนวนการขอเบิกเงินล่วงหน้าที่ยังไม่ได้อนุมัติ
      const pendingRequests = await CashAdvanceRequest.countDocuments({
        userId: worker.userId._id,
        status: { $in: ['pending', 'submitted'] }
      });
      
      workerNotifications.push({
        workerId: worker.userId._id,
        workerName: worker.userId.name,
        notificationCount: pendingRequests
      });
      
      console.log(`📊 Worker ${worker.userId.name}: ${pendingRequests} pending requests`);
    }
    
    res.status(200).json({
      success: true,
      notifications: workerNotifications
    });
    
  } catch (error) {
    console.error('❌ Error fetching worker notifications:', error);
    res.status(500).json({
      success: false,
      message: 'เกิดข้อผิดพลาดในการดึงข้อมูลการแจ้งเตือน',
      error: error.message
    });
  }
});

// Export สำหรับ Vercel
module.exports = app;