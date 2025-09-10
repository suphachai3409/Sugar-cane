const mongoose = require('mongoose');
const User = mongoose.model('User');

// Middleware สำหรับตรวจสอบ authentication
const authMiddleware = async (req, res, next) => {
  try {
    console.log('🔍 DEBUG: auth_middleware ถูกเรียกสำหรับ path:', req.path);

    // 1. ข้าม authentication สำหรับ route ที่ไม่ต้องตรวจสอบ
    const skipAuthRoutes = [
      '/register',
      '/login',
      '/create-worker-code',
      '/create-farmer-code',
      '/check-relation',
      '/user-requests',
      '/requests',
      '/owner-requests'
    ];

    const shouldSkipAuth =
      skipAuthRoutes.some(route => req.path === route || req.path.startsWith(route + '/')) ||
      req.path.startsWith('/worker-info') || // worker-info/* 
      req.path.includes('/worker-info/');

    if (shouldSkipAuth) {
      console.log('🔄 ข้าม authentication สำหรับ route:', req.path);
      return next();
    }

    // 2. ข้าม authentication เมื่อมี user-id header
    const headerUserId = req.headers['user-id'];
    if (headerUserId) {
      console.log('🔄 Bypassing auth due to user-id header:', headerUserId);

      // ตั้งค่า req.user เผื่อต้องการใช้
      const user = await User.findById(headerUserId);
      if (user) {
        req.user = {
          id: user._id.toString(),
          menu: user.menu,
          ...user.toObject()
        };
      } else {
        req.user = {
          id: headerUserId,
          menu: 3 // default menu
        };
      }

      return next();
    }

    // 3. ตรวจสอบ Authorization header (แบบ Bearer token)
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: 'กรุณาเข้าสู่ระบบใหม่ token หาย'
      });
    }

    const token = authHeader.substring(7); // ตัด "Bearer " ออก
    const user = await User.findById(token);

    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'ไม่พบผู้ใช้ กรุณาเข้าสู่ระบบใหม่'
      });
    }

    // เพิ่ม user object ลงใน request
    req.user = {
      id: user._id.toString(),
      menu: user.menu,
      ...user.toObject()
    };

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
