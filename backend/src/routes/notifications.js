const express = require('express');
const router = express.Router();
const { protect } = require('../middlewares/auth');
const notificationController = require('../controllers/notificationController');

// Every role (client, merchant, delivery, admin) reads its own notifications
router.use(protect);

router.get('/', notificationController.getNotifications);
// Must come before '/:id/read'
router.put('/read-all', notificationController.markAllAsRead);
router.put('/:id/read', notificationController.markAsRead);
router.delete('/:id', notificationController.deleteNotification);

module.exports = router;
