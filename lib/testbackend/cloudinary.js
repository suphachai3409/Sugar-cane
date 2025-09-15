const cloudinary = require('cloudinary').v2;

// Configure Cloudinary using CLOUDINARY_URL
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME || 'dkcprf6ic',
  api_key: process.env.CLOUDINARY_API_KEY || '555498432776172',
  api_secret: process.env.CLOUDINARY_API_SECRET || '-MUtJPsxxiTj9gZphsHSSNL344I',
  secure: true, // ใช้ HTTPS เสมอ
  secure_distribution: 'res.cloudinary.com' // ใช้ secure distribution
});

// ตรวจสอบการเชื่อมต่อ Cloudinary
cloudinary.api.ping()
  .then(result => {
    console.log('✅ Cloudinary connection successful:', result);
  })
  .catch(error => {
    console.error('❌ Cloudinary connection failed:', error);
  });

module.exports = cloudinary;
