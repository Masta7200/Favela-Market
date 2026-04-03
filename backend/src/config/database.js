const mongoose = require('mongoose');

const connectDB = async () => {
  const uri = process.env.MONGO_URI;
  if (!uri) {
    console.error('MONGO_URI is not set. Add MONGO_URI to your .env file (backend/.env)');
    process.exit(1);
  }

  try {
    console.log('Attempting to connect to MongoDB Atlas...');
    const conn = await mongoose.connect(uri, {
      connectTimeoutMS: 10000,
      socketTimeoutMS: 30000,
      serverSelectionTimeoutMS: 10000,
      retryWrites: true,
      w: 'majority'
    });
    console.log(`✅ MongoDB Connected: ${conn.connection.host}`);
    return conn;
  } catch (error) {
    console.error(`❌ MongoDB connection error: ${error.message}`);
    console.error('Full error:', error);
    // Don't exit, let the app run and show errors on API calls
    // This helps with debugging
    setTimeout(() => {
      console.error('Retrying MongoDB connection...');
      connectDB();
    }, 5000);
  }
};

module.exports = connectDB;