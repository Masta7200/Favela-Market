const Notification = require('../models/Notification');

// @desc    Get current user's notifications (newest first)
// @route   GET /api/notifications?unread=true&limit=50
// @access  Private
exports.getNotifications = async (req, res) => {
  try {
    const limit = Math.min(Number(req.query.limit) || 50, 100);
    const filter = { user: req.user._id };
    if (req.query.unread === 'true') filter.isRead = false;

    const [notifications, unreadCount] = await Promise.all([
      Notification.find(filter).sort({ createdAt: -1 }).limit(limit),
      Notification.countDocuments({ user: req.user._id, isRead: false })
    ]);

    res.json({ success: true, data: { notifications, unreadCount } });
  } catch (err) {
    console.error('getNotifications error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// @desc    Mark one notification as read
// @route   PUT /api/notifications/:id/read
// @access  Private
exports.markAsRead = async (req, res) => {
  try {
    const notification = await Notification.findOneAndUpdate(
      { _id: req.params.id, user: req.user._id },
      { isRead: true },
      { new: true }
    );

    if (!notification) {
      return res.status(404).json({ success: false, message: 'Notification introuvable' });
    }

    res.json({ success: true, data: { notification } });
  } catch (err) {
    console.error('markAsRead error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// @desc    Mark all notifications as read
// @route   PUT /api/notifications/read-all
// @access  Private
exports.markAllAsRead = async (req, res) => {
  try {
    await Notification.updateMany({ user: req.user._id, isRead: false }, { isRead: true });
    res.json({ success: true, message: 'Toutes les notifications sont lues' });
  } catch (err) {
    console.error('markAllAsRead error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// @desc    Delete one notification
// @route   DELETE /api/notifications/:id
// @access  Private
exports.deleteNotification = async (req, res) => {
  try {
    const notification = await Notification.findOneAndDelete({ _id: req.params.id, user: req.user._id });
    if (!notification) {
      return res.status(404).json({ success: false, message: 'Notification introuvable' });
    }
    res.json({ success: true, message: 'Notification supprimée' });
  } catch (err) {
    console.error('deleteNotification error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};
