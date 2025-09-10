// models/User.js
const mongoose = require('mongoose');

if (mongoose.models.User) {
  module.exports = mongoose.models.User;
} else {
  const userSchema = new mongoose.Schema({
    name: String,
    email: String,
    number: Number,
    username: String,
    password: String,
    menu: { type: Number, default: 1 },
    profileImage: String, // เพิ่มฟิลด์สำหรับเก็บ URL รูปโปรไฟล์
  });
  
  module.exports = mongoose.model('User', userSchema);
}