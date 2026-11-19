const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middlewares/auth');
const { USER_ROLES } = require('../constants');
const orderController = require('../controllers/orderController');

// All routes require authentication
router.use(protect);

// Only approved merchants / delivery persons can work on orders
const requireApproved = (req, res, next) => {
  if (!req.user.isApproved && req.user.role !== USER_ROLES.ADMIN) {
    return res.status(403).json({ success: false, message: 'Votre compte doit être vérifié par un administrateur' });
  }
  next();
};

// Create order (clients)
router.post('/', authorize(USER_ROLES.CLIENT), orderController.createOrder);

// Get user's orders (client sees their orders, merchants see their orders)
router.get('/', orderController.getUserOrders);
router.get('/merchant/orders', authorize(USER_ROLES.MERCHANT), orderController.getUserOrders);

// Delivery person (these paths must come before '/:orderId')
router.get('/delivery/orders', authorize(USER_ROLES.DELIVERY), requireApproved, orderController.getDeliveryOrders);

// Get specific order
router.get('/:orderId', orderController.getOrder);

// Update order status (merchant/admin only)
router.put('/:orderId/status', authorize(USER_ROLES.MERCHANT, USER_ROLES.ADMIN), requireApproved, orderController.updateOrderStatus);

// Cancel order (client only)
router.post('/:orderId/cancel', authorize(USER_ROLES.CLIENT), orderController.cancelOrder);

// Delivery actions (assigned delivery person only)
router.put('/:orderId/delivery/accept', authorize(USER_ROLES.DELIVERY), requireApproved, orderController.acceptDelivery);
router.put('/:orderId/delivery/decline', authorize(USER_ROLES.DELIVERY), requireApproved, orderController.declineDelivery);
router.put('/:orderId/delivery/status', authorize(USER_ROLES.DELIVERY), requireApproved, orderController.updateDeliveryStatus);

module.exports = router;
