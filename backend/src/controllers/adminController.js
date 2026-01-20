const User = require('../models/User');
const Product = require('../models/Product');
const Category = require('../models/Category');
const { USER_ROLES, PRODUCT_STATUS } = require('../constants');

// Get dashboard stats
exports.getStats = async (req, res) => {
  try {
    const totalUsers = await User.countDocuments();
    const totalProducts = await Product.countDocuments();
    const totalCategories = await Category.countDocuments();
    const pendingProducts = await Product.countDocuments({ status: PRODUCT_STATUS.PENDING });
    const pendingMerchants = await User.countDocuments({ role: USER_ROLES.MERCHANT, isApproved: false });
    const totalOrders = 0; // TODO: Add Order model count
    const totalRevenue = 0; // TODO: Calculate from orders

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
