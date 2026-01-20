const express = require('express');
const router = express.Router();
const {
  register,
  login,
  getMe,
  updateProfile,
  updatePassword,
  addAddress,
  updateFCMToken,
  forgotPassword,
  resetPassword
} = require('../controllers/authController');
const { protect, authorize } = require('../middlewares/auth');
const { USER_ROLES } = require('../constants');

// Basic test route
router.get('/', (req, res) => {
  res.json({ success: true, message: 'Auth routes are working' });
});

// Public routes
router.post('/register', register);
router.post('/login', login);
router.post('/forgot-password', forgotPassword);
router.post('/reset-password', resetPassword);

// Protected routes
router.get('/me', protect, getMe);
router.put('/profile', protect, updateProfile);
router.put('/password', protect, updatePassword);
router.post('/fcm-token', protect, updateFCMToken);

// Client specific routes
router.post('/addresses', protect, authorize(USER_ROLES.CLIENT), addAddress);

module.exports = router;