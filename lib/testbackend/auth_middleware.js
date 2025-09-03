const mongoose = require('mongoose');
const User = mongoose.model('User');

// Middleware สำหรับตรวจสอบ authentication
const authMiddleware = async (req, res, next) => {
  try {
    console.log('🔍 DEBUG: auth_middleware ถูกเรียกสำหรับ path:', req.path);
    
  // ข้าม authentication สำหรับ endpoint ทดสอบบางตัว
  if (
    req.path === '/create-worker-code' ||
    req.path === '/create-farmer-code' ||
    req.path.startsWith('/worker-info') ||
    req.path.includes('/worker-info/') ||
    req.path.startsWith('/worker-info/')
  ) {
      console.log('🔄 ข้าม authentication สำหรับการสร้างรหัส');
      return next();
    }

    // ตรวจสอบ Authorization header
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ 
        success: false, 
        message: 'กรุณาเข้าสู่ระบบใหม่ token หาย' 
      });
    }

    // ดึง token จาก header
    const token = authHeader.substring(7); // ตัด "Bearer " ออก
    
    // ค้นหาผู้ใช้จาก token (ในที่นี้เราจะใช้ token เป็น userId)
    const user = await User.findById(token);
    
    if (!user) {
      return res.status(401).json({ 
        success: false, 
        message: 'ไม่พบผู้ใช้ กรุณาเข้าสู่ระบบใหม่' 
      });
    }

    // เพิ่ม user object ลงใน request
    req.user = user;
    next();
    
  } catch (error) {
    console.error('❌ Auth middleware error:', error);
    return res.status(500).json({ 
      success: false, 
      message: 'เกิดข้อผิดพลาดในการตรวจสอบ authentication' 
    });
  }
};

module.exports = authMiddleware;