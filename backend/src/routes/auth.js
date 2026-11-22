const express = require('express');
const router = express.Router();
const {
  register,
  login,
  getMe,
  updateProfile,
  updatePassword,
  addAddress,
  updateAddress,
  deleteAddress,
  updateFCMToken,
  forgotPassword,
  resetPassword,
  setAvailability
} = require('../controllers/authController');
const { protect, authorize } = require('../middlewares/auth');
const { authLimiter, resetRequestLimiter } = require('../middlewares/rateLimit');
const { USER_ROLES } = require('../constants');

// Basic test route
router.get('/', (req, res) => {
  res.json({ success: true, message: 'Auth routes are working' });
});

// Public routes
router.post('/register', register);
router.post('/login', authLimiter, login);
router.post('/forgot-password', resetRequestLimiter, forgotPassword);
router.post('/reset-password', authLimiter, resetPassword);

// Protected routes
router.get('/me', protect, getMe);
router.put('/profile', protect, updateProfile);
router.put('/password', protect, updatePassword);
router.post('/fcm-token', protect, updateFCMToken);

// Client specific routes
router.post('/addresses', protect, authorize(USER_ROLES.CLIENT), addAddress);
router.put('/addresses/:addressId', protect, authorize(USER_ROLES.CLIENT), updateAddress);
router.delete('/addresses/:addressId', protect, authorize(USER_ROLES.CLIENT), deleteAddress);

// Delivery specific routes
router.put('/availability', protect, authorize(USER_ROLES.DELIVERY), setAvailability);

module.exports = router;