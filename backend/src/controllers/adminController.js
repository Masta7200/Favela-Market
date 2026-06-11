const User = require('../models/User');
const Product = require('../models/Product');
const Category = require('../models/Category');
const Order = require('../models/Order');
const { USER_ROLES, PRODUCT_STATUS } = require('../constants');

// Get dashboard stats
exports.getStats = async (req, res) => {
  try {
    const totalUsers = await User.countDocuments();
    const totalProducts = await Product.countDocuments();
    const totalCategories = await Category.countDocuments();
    const pendingProducts = await Product.countDocuments({ status: PRODUCT_STATUS.PENDING });
    const pendingMerchants = await User.countDocuments({ role: USER_ROLES.MERCHANT, isApproved: false });
    const totalOrders = await Order.countDocuments();
    const totalRevenue = await Order.aggregate([
      { $match: { status: { $in: ['delivered', 'completed'] } } },
      { $group: { _id: null, total: { $sum: '$total' } } }
    ]).then(result => result[0]?.total || 0);

    res.json({
      success: true,
      data: {
        totalUsers,
        totalProducts,
        totalCategories,
        pendingProducts,
        pendingMerchants,
        totalOrders,
        totalRevenue
      }
    });
  } catch (err) {
    console.error('getStats error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// Get all orders (admin)
exports.getOrders = async (req, res) => {
  try {
    const { status } = req.query;
    const filter = {};
    if (status && status !== 'all') filter.status = status;

    const orders = await Order.find(filter)
      .populate('client', 'name phone email')
      .populate('merchant', 'name shopName phone')
      .sort({ createdAt: -1 });

    // Transform orders to include customer info
    const transformedOrders = orders.map(order => ({
      _id: order._id,
      orderNumber: order.orderNumber,
      customerName: order.client?.name || 'N/A',
      customerPhone: order.client?.phone || '',
      customerEmail: order.client?.email || '',
      merchantName: order.merchant?.shopName || order.merchant?.name || 'N/A',
      items: order.items,
      total: order.total,
      status: order.status,
      createdAt: order.createdAt,
      deliveryAddress: order.deliveryAddress
    }));

    res.json({
      success: true,
      data: { orders: transformedOrders }
    });
  } catch (err) {
    console.error('getOrders error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// Get order by ID (admin)
exports.getOrderById = async (req, res) => {
  try {
    const { orderId } = req.params;
    const order = await Order.findById(orderId)
      .populate('client', 'name phone email')
      .populate('merchant', 'name shopName phone email')
      .populate('items.product', 'name images price');

    if (!order) {
      return res.status(404).json({ success: false, message: 'Commande introuvable' });
    }

    res.json({
      success: true,
      data: { order }
    });
  } catch (err) {
    console.error('getOrderById error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// Update order status (admin)
exports.updateOrderStatus = async (req, res) => {
  try {
    const { orderId } = req.params;
    const { status } = req.body;

    const order = await Order.findByIdAndUpdate(
      orderId,
      { status },
      { new: true }
    ).populate('client', 'name phone').populate('merchant', 'name shopName');

    if (!order) {
      return res.status(404).json({ success: false, message: 'Commande introuvable' });
    }

    res.json({
      success: true,
      data: { order },
      message: 'Statut mis à jour avec succès'
    });
  } catch (err) {
    console.error('updateOrderStatus error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// Delete order (admin)
exports.deleteOrder = async (req, res) => {
  try {
    const { orderId } = req.params;
    const order = await Order.findById(orderId);
    if (!order) {
      return res.status(404).json({ success: false, message: 'Commande introuvable' });
    }

    if (!['delivered', 'completed'].includes(order.status)) {
      for (const item of order.items) {
        await Product.findByIdAndUpdate(item.product, {
          $inc: { stock: item.quantity }
        });
      }
    }

    await Order.findByIdAndDelete(orderId);

    res.json({
      success: true,
      message: 'Commande supprimée avec succès'
    });
  } catch (err) {
    console.error('deleteOrder error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// Get all users (with optional role filter)
exports.getUsers = async (req, res) => {
  try {
    const { role } = req.query;
    const filter = {};
    if (role && role !== 'all') filter.role = role;

    const users = await User.find(filter).sort({ createdAt: -1 });
    res.json({ success: true, data: { users } });
  } catch (err) {
    console.error('getUsers error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// Create a new user
exports.createUser = async (req, res) => {
  try {
    const { name, phone, email, password, role, isActive } = req.body;

    if (!name || !phone || !password) {
      return res.status(400).json({ success: false, message: 'Champs requis manquants' });
    }

    // Check duplicate phone or email
    const existing = await User.findOne({ $or: [{ phone }, { email }] }).select('+password');
    if (existing) {
      return res.status(400).json({ success: false, message: 'Utilisateur déjà existant' });
    }

    const user = await User.create({ name, phone, email, password, role: role || USER_ROLES.CLIENT, isActive: isActive !== undefined ? isActive : true });

    res.status(201).json({ success: true, data: { user } });
  } catch (err) {
    console.error('createUser error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// Update user
exports.updateUser = async (req, res) => {
  try {
    const { id } = req.params;
    const updates = { ...req.body };

    // Prevent password update here via plain update; let model handle hashing if provided
    if (updates.password) {
      // set and save to trigger pre save hook
      const user = await User.findById(id);
      if (!user) return res.status(404).json({ success: false, message: 'Utilisateur introuvable' });
      user.name = updates.name ?? user.name;
      user.phone = updates.phone ?? user.phone;
      user.email = updates.email ?? user.email;
      user.role = updates.role ?? user.role;
      user.isActive = updates.isActive ?? user.isActive;
      if (updates.password) user.password = updates.password;
      // role specific
      user.shopName = updates.shopName ?? user.shopName;
      user.shopDescription = updates.shopDescription ?? user.shopDescription;
      user.shopAddress = updates.shopAddress ?? user.shopAddress;
      user.shopPhone = updates.shopPhone ?? user.shopPhone;
      user.isApproved = updates.isApproved ?? user.isApproved;
      user.vehicleType = updates.vehicleType ?? user.vehicleType;
      user.vehicleNumber = updates.vehicleNumber ?? user.vehicleNumber;

      await user.save();
      return res.json({ success: true, data: { user } });
    }

    const user = await User.findByIdAndUpdate(id, updates, { new: true });
    if (!user) return res.status(404).json({ success: false, message: 'Utilisateur introuvable' });

    res.json({ success: true, data: { user } });
  } catch (err) {
    console.error('updateUser error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// Delete user
exports.deleteUser = async (req, res) => {
  try {
    const { id } = req.params;
    const user = await User.findByIdAndDelete(id);
    if (!user) return res.status(404).json({ success: false, message: 'Utilisateur introuvable' });
    res.json({ success: true, message: 'Utilisateur supprimé' });
  } catch (err) {
    console.error('deleteUser error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// Toggle user active status
exports.toggleUserStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const user = await User.findById(id);
    if (!user) return res.status(404).json({ success: false, message: 'Utilisateur introuvable' });
    user.isActive = !user.isActive;
    await user.save();
    res.json({ success: true, data: { user } });
  } catch (err) {
    console.error('toggleUserStatus error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};
