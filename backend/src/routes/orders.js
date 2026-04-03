const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middlewares/auth');
const { USER_ROLES } = require('../constants');
const orderController = require('../controllers/orderController');

// All routes require authentication
router.use(protect);

// Create order (clients)
router.post('/', authorize(USER_ROLES.CLIENT), orderController.createOrder);

// Get user's orders (client sees their orders, merchants see their orders)
router.get('/', orderController.getUserOrders);

// Get specific order
router.get('/:orderId', orderController.getOrder);

// Update order status (merchant/admin only)
router.put('/:orderId/status', authorize(USER_ROLES.MERCHANT, USER_ROLES.ADMIN), orderController.updateOrderStatus);

// Cancel order (client only)
router.post('/:orderId/cancel', authorize(USER_ROLES.CLIENT), orderController.cancelOrder);

module.exports = router;
