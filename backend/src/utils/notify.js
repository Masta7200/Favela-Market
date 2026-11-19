const Notification = require('../models/Notification');
const User = require('../models/User');
const { USER_ROLES } = require('../constants');

// Notifications never block or fail the main request: errors are only logged.

// Create a notification for one user
const notifyUser = async (userId, { title, message, type, order, product }) => {
  if (!userId) return null;
  try {
    return await Notification.create({
      user: userId,
      title,
      message,
      type,
      order: order?._id || order,
      product: product?._id || product
    });
  } catch (err) {
    console.error('notifyUser error', err.message);
    return null;
  }
};

// Create the same notification for several users
const notifyUsers = async (userIds, payload) => {
  const ids = [...new Set(userIds.filter(Boolean).map(String))];
  await Promise.all(ids.map((id) => notifyUser(id, payload)));
};

// Notify every active admin (shown in the admin panel bell)
const notifyAdmins = async (payload) => {
  try {
    const admins = await User.find({ role: USER_ROLES.ADMIN, isActive: true }).select('_id');
    await notifyUsers(admins.map((a) => a._id), payload);
  } catch (err) {
    console.error('notifyAdmins error', err.message);
  }
};

module.exports = { notifyUser, notifyUsers, notifyAdmins };
