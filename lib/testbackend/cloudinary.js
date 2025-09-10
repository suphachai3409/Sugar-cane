const cloudinary = require('cloudinary').v2;

// Configure Cloudinary using CLOUDINARY_URL
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME || 'dkcprf6ic',
  api_key: process.env.CLOUDINARY_API_KEY || '555498432776172',
  api_secret: process.env.CLOUDINARY_API_SECRET || '-MUtJPsxxiTj9gZphsHSSNL344I'
});

module.exports = cloudinary;
