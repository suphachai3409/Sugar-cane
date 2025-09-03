//main.js
const express = require('express');
const mongoose = require('mongoose');
const bodyParser = require('body-parser');
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const app = express();
app.use(bodyParser.json());
app.use(cors());

// ===== Multer สำหรับอัปโหลดรูป =====
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    // สร้างโฟลเดอร์ uploads ถ้ายังไม่มี
    if (!fs.existsSync('uploads')) {
      fs.mkdirSync('uploads');
    }
    cb(null, 'uploads/');
  },
  filename: function (req, file, cb) {
    cb(null, Date.now() + path.extname(file.originalname)); // ตั้งชื่อไฟล์ไม่ซ้ำ
  }
});
const upload = multer({ storage: storage });

// ===== เชื่อมต่อ MongoDB =====
mongoose.connect('mongodb://127.0.0.1:27017/sugar_cane', {});

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
    userData.profileImage = req.file.filename;
    console.log('Profile image added:', req.file.filename);
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





///////////////////////////////////// profile 
// อัปเดตข้อมูลผู้ใช้ (รองรับอัปโหลดรูป)
app.put('/updateuser/:id', upload.single('profileImage'), async (req, res) => {
  const { id } = req.params;
  const { name, email, number, username, password, menu } = req.body;
  let updateData = { name, email, number, username, password, menu };

  if (req.file) {
    updateData.profileImage = req.file.filename; // เก็บชื่อไฟล์รูป
  }

  try {
    await User.findByIdAndUpdate(id, updateData);
    res.status(200).json({ message: 'User updated successfully' });
  } catch (error) {
    res.status(500).json({ message: 'Error updating user', error });
  }
});

// ดึงข้อมูลผู้ใช้ทั้งหมด
app.get('/pulluser', async (req, res) => {
  try {
    const users = await User.find();
    res.status(200).json(users);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching users', error });
  }
});


// Static path สำหรับให้ client โหลดรูป
app.use('/uploads', express.static('uploads'));

////////////////////////////////////////////////// เชื่อมคนงานลูกไร่
   const profileRoutes = require('./profile');
   const authMiddleware = require('./auth_middleware');
   app.use('/api/profile', authMiddleware, profileRoutes);



///////////////////////////////////////////////// แปลงปลูก
const plotRoutes = require('./plotRoutes'); 
app.use('/api/plots', plotRoutes);



// เริ่มเซิร์ฟเวอร์
app.listen(3000, () => {
  console.log('Server is running on port 3000');
});