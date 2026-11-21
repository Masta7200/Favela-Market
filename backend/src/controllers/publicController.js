const User = require('../models/User');
const Product = require('../models/Product');
const Category = require('../models/Category');
const Order = require('../models/Order');
const { USER_ROLES, PRODUCT_STATUS } = require('../constants');

// The landing page is public: keep the counts in memory for a few minutes
// so visitors don't hit the database on every page load.
const CACHE_MS = 5 * 60 * 1000;
let cache = { data: null, at: 0 };

// Public platform figures shown on the landing page (no revenue, no personal data)
exports.getPublicStats = async (req, res) => {
  try {
    if (cache.data && Date.now() - cache.at < CACHE_MS) {
      return res.json({ success: true, data: cache.data });
    }

    const [clients, merchants, deliveryPersons, products, categories, deliveredOrders] = await Promise.all([
      User.countDocuments({ role: USER_ROLES.CLIENT, isActive: true }),
      User.countDocuments({ role: USER_ROLES.MERCHANT, isApproved: true, isActive: true }),
      User.countDocuments({ role: USER_ROLES.DELIVERY, isApproved: true, isActive: true }),
      Product.countDocuments({ status: PRODUCT_STATUS.APPROVED, isActive: true }),
      Category.countDocuments(),
      Order.countDocuments({ status: { $in: ['delivered', 'completed'] } })
    ]);

    const data = { clients, merchants, deliveryPersons, products, categories, deliveredOrders };
    cache = { data, at: Date.now() };

    res.json({ success: true, data });
  } catch (err) {
    console.error('getPublicStats error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};
