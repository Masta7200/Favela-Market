require('dotenv').config();
const mongoose = require('mongoose');
const User = require('../models/User');
const { USER_ROLES } = require('../constants');

const connectDB = async () => {
  try {
    // set a short server selection timeout so failures surface quickly
    const mongoUri = process.env.MONGO_URI || process.env.MONGODB_URI;
    await mongoose.connect(mongoUri, { serverSelectionTimeoutMS: 5000 });
    console.log('MongoDB Connected');
  } catch (error) {
    console.error(`Error: ${error.message}`);
    process.exit(1);
  }
};

const seedAdmin = async () => {
  try {
    await connectDB();

    // Check if admin already exists
    const adminExists = await User.findOne({ role: USER_ROLES.ADMIN });

    if (adminExists) {
      console.log('Admin user already exists');
      process.exit(0);
    }

    // Create admin user
    const admin = await User.create({
      phone: process.env.ADMIN_PHONE || '+237600000000',
      password: process.env.ADMIN_PASSWORD || 'admin123',
      name: 'Super Admin',
      email: 'admin@favelamarket.com',
      role: USER_ROLES.ADMIN,
      isActive: true,
      isApproved: true
    });

    console.log('Admin user created successfully');
    console.log(`Phone: ${admin.phone}`);
    console.log(`Password: ${process.env.ADMIN_PASSWORD || 'admin123'}`);
    console.log('Please change the password after first login!');

    process.exit(0);
  } catch (error) {
    console.error('Error seeding admin:', error);
    process.exit(1);
  }
};

seedAdmin();