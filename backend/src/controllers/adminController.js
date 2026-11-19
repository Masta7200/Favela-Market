const User = require('../models/User');
const Product = require('../models/Product');
const Category = require('../models/Category');
const Order = require('../models/Order');
const Notification = require('../models/Notification');
const { USER_ROLES, PRODUCT_STATUS, ORDER_STATUS, FINAL_ORDER_STATUSES, NOTIFICATION_TYPES } = require('../constants');
const { notifyUser } = require('../utils/notify');
const {
  STATUS_LABELS,
  VALID_STATUSES,
  populateOrder,
  idOf,
  sameId,
  isFinal,
  restoreStock,
  applyStatus,
  notifyStatusChange
} = require('../utils/orderHelpers');

const NEEDS_APPROVAL = [USER_ROLES.MERCHANT, USER_ROLES.DELIVERY];

// Orders a delivery person is currently handling
const ACTIVE_DELIVERY_FILTER = { status: { $nin: [...FINAL_ORDER_STATUSES] } };

// Get dashboard stats
exports.getStats = async (req, res) => {
  try {
    const [
      totalUsers,
      totalProducts,
      totalCategories,
      pendingProducts,
      pendingMerchants,
      pendingDelivery,
      availableDelivery,
      totalOrders,
      unassignedOrders,
      revenue
    ] = await Promise.all([
      User.countDocuments(),
      Product.countDocuments(),
      Category.countDocuments(),
      Product.countDocuments({ status: PRODUCT_STATUS.PENDING }),
      User.countDocuments({ role: USER_ROLES.MERCHANT, isApproved: false }),
      User.countDocuments({ role: USER_ROLES.DELIVERY, isApproved: false }),
      User.countDocuments({ role: USER_ROLES.DELIVERY, isApproved: true, isActive: true, isAvailable: true }),
      Order.countDocuments(),
      Order.countDocuments({ ...ACTIVE_DELIVERY_FILTER, deliveryPerson: null }),
      Order.aggregate([
        { $match: { status: { $in: ['delivered', 'completed'] } } },
        { $group: { _id: null, total: { $sum: '$total' } } }
      ])
    ]);

    res.json({
      success: true,
      data: {
        totalUsers,
        totalProducts,
        totalCategories,
        pendingProducts,
        pendingMerchants,
        pendingDelivery,
        availableDelivery,
        totalOrders,
        unassignedOrders,
        totalRevenue: revenue[0]?.total || 0
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
    const { status, delivery } = req.query;
    const filter = {};
    if (status && status !== 'all') filter.status = status;
    // ?delivery=unassigned → open orders that still need a delivery person
    if (delivery === 'unassigned') {
      Object.assign(filter, ACTIVE_DELIVERY_FILTER, { deliveryPerson: null });
      if (status && status !== 'all') filter.status = status;
    }

    const orders = await populateOrder(Order.find(filter)).sort({ createdAt: -1 });

    // Transform orders to include customer info
    const transformedOrders = orders.map(order => ({
      _id: order._id,
      orderNumber: order.orderNumber,
      customerName: order.client?.name || 'N/A',
      customerPhone: order.client?.phone || '',
      customerEmail: order.client?.email || '',
      merchantName: order.merchant?.shopName || order.merchant?.name || 'N/A',
      deliveryPerson: order.deliveryPerson
        ? { _id: order.deliveryPerson._id, name: order.deliveryPerson.name, phone: order.deliveryPerson.phone }
        : null,
      assignedAt: order.assignedAt,
      deliveryAcceptedAt: order.deliveryAcceptedAt,
      items: order.items,
      total: order.total,
      status: order.status,
      paymentMethod: order.paymentMethod,
      paymentStatus: order.paymentStatus,
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
    const order = await populateOrder(Order.findById(orderId))
      .populate('deliveryDeclines.deliveryPerson', 'name phone');

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
    const { status, reason } = req.body;

    if (!VALID_STATUSES.includes(status)) {
      return res.status(400).json({ success: false, message: 'Statut invalide' });
    }

    const order = await Order.findById(orderId);
    if (!order) {
      return res.status(404).json({ success: false, message: 'Commande introuvable' });
    }

    if (order.status !== status) {
      await applyStatus(order, status, { reason: reason || 'Modifiée par l\'administrateur' });
      await order.save();
      await notifyStatusChange(order, status, req.user._id);
    }

    const updated = await populateOrder(Order.findById(order._id));

    res.json({
      success: true,
      data: { order: updated },
      message: 'Statut mis à jour avec succès'
    });
  } catch (err) {
    console.error('updateOrderStatus error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// List delivery persons who can receive orders
// GET /api/admin/delivery-persons?available=true
exports.getDeliveryPersons = async (req, res) => {
  try {
    const filter = { role: USER_ROLES.DELIVERY, isApproved: true, isActive: true };
    if (req.query.available === 'true') filter.isAvailable = true;

    const [persons, activeCounts] = await Promise.all([
      User.find(filter).select('name phone vehicleType vehicleNumber isAvailable').sort({ isAvailable: -1, name: 1 }),
      Order.aggregate([
        { $match: { ...ACTIVE_DELIVERY_FILTER, deliveryPerson: { $ne: null } } },
        { $group: { _id: '$deliveryPerson', count: { $sum: 1 } } }
      ])
    ]);

    const countById = new Map(activeCounts.map((c) => [String(c._id), c.count]));
    const deliveryPersons = persons.map((p) => ({
      ...p.toObject(),
      activeOrders: countById.get(String(p._id)) || 0
    }));

    res.json({ success: true, data: { deliveryPersons } });
  } catch (err) {
    console.error('getDeliveryPersons error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// Assign (or reassign) an order to a delivery person
// PUT /api/admin/orders/:orderId/assign   body { deliveryPersonId }
exports.assignDelivery = async (req, res) => {
  try {
    const { orderId } = req.params;
    const { deliveryPersonId } = req.body;

    if (!deliveryPersonId) {
      return res.status(400).json({ success: false, message: 'Livreur requis' });
    }

    const order = await Order.findById(orderId);
    if (!order) {
      return res.status(404).json({ success: false, message: 'Commande introuvable' });
    }

    if (isFinal(order.status)) {
      return res.status(400).json({ success: false, message: `Commande « ${STATUS_LABELS[order.status]} » : impossible d'assigner un livreur` });
    }

    if (order.status === ORDER_STATUS.IN_TRANSIT) {
      return res.status(400).json({ success: false, message: 'La commande est déjà en cours de livraison' });
    }

    const deliveryPerson = await User.findById(deliveryPersonId);
    if (!deliveryPerson || deliveryPerson.role !== USER_ROLES.DELIVERY) {
      return res.status(404).json({ success: false, message: 'Livreur introuvable' });
    }

    if (!deliveryPerson.isApproved || !deliveryPerson.isActive) {
      return res.status(400).json({ success: false, message: 'Ce livreur n\'est pas vérifié ou son compte est suspendu' });
    }

    if (sameId(order.deliveryPerson, deliveryPerson._id)) {
      return res.status(400).json({ success: false, message: 'Cette commande est déjà assignée à ce livreur' });
    }

    const previous = idOf(order.deliveryPerson);

    order.deliveryPerson = deliveryPerson._id;
    order.assignedAt = new Date();
    order.deliveryAcceptedAt = undefined;
    order.pickedUpAt = undefined;
    await order.save();

    if (previous) {
      await notifyUser(previous, {
        title: `Commande ${order.orderNumber} retirée`,
        message: `La commande ${order.orderNumber} a été confiée à un autre livreur.`,
        type: NOTIFICATION_TYPES.ORDER_CANCELLED,
        order: order._id
      });
    }

    const populated = await populateOrder(Order.findById(order._id));
    const address = populated.deliveryAddress?.label || populated.deliveryAddress?.fullAddress || populated.deliveryAddress || '';
    const pickup = populated.merchant?.shopName || populated.merchant?.name || 'le marchand';

    await notifyUser(deliveryPerson._id, {
      title: 'Nouvelle livraison assignée',
      message: `Commande ${order.orderNumber} : récupération chez ${pickup}, livraison à ${address}. Acceptez-la dans l'application.`,
      type: NOTIFICATION_TYPES.ORDER_ASSIGNED,
      order: order._id
    });

    res.json({
      success: true,
      message: `Commande assignée à ${deliveryPerson.name}`,
      data: { order: populated }
    });
  } catch (err) {
    console.error('assignDelivery error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// Remove the delivery person from an order
// DELETE /api/admin/orders/:orderId/assign
exports.unassignDelivery = async (req, res) => {
  try {
    const order = await Order.findById(req.params.orderId);
    if (!order) {
      return res.status(404).json({ success: false, message: 'Commande introuvable' });
    }

    if (!order.deliveryPerson) {
      return res.status(400).json({ success: false, message: 'Aucun livreur assigné' });
    }

    if (order.status === ORDER_STATUS.IN_TRANSIT || isFinal(order.status)) {
      return res.status(400).json({ success: false, message: 'Impossible de retirer le livreur à ce stade' });
    }

    const previous = idOf(order.deliveryPerson);
    order.deliveryPerson = undefined;
    order.assignedAt = undefined;
    order.deliveryAcceptedAt = undefined;
    await order.save();

    await notifyUser(previous, {
      title: `Commande ${order.orderNumber} retirée`,
      message: `La commande ${order.orderNumber} ne vous est plus assignée.`,
      type: NOTIFICATION_TYPES.ORDER_CANCELLED,
      order: order._id
    });

    const populated = await populateOrder(Order.findById(order._id));
    res.json({ success: true, message: 'Livreur retiré', data: { order: populated } });
  } catch (err) {
    console.error('unassignDelivery error', err);
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

    // Cancelled / rejected orders already gave their stock back
    if (!isFinal(order.status)) {
      await restoreStock(order);
    }

    await Order.findByIdAndDelete(orderId);
    await Notification.deleteMany({ order: orderId });

    res.json({
      success: true,
      message: 'Commande supprimée avec succès'
    });
  } catch (err) {
    console.error('deleteOrder error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// Tell a merchant / delivery person that their account was approved or rejected
const notifyApproval = async (user) => {
  if (!NEEDS_APPROVAL.includes(user.role)) return;
  if (user.isApproved) {
    await notifyUser(user._id, {
      title: 'Compte vérifié',
      message: user.role === USER_ROLES.DELIVERY
        ? 'Votre compte livreur est validé. Passez « En ligne » pour recevoir des livraisons.'
        : 'Votre boutique est validée. Vous pouvez maintenant ajouter vos produits.',
      type: NOTIFICATION_TYPES.ACCOUNT_APPROVED
    });
  } else {
    await notifyUser(user._id, {
      title: 'Compte non validé',
      message: `Votre compte n'a pas été validé.${user.rejectionReason ? ` Motif : ${user.rejectionReason}` : ''}`,
      type: NOTIFICATION_TYPES.ACCOUNT_REJECTED
    });
  }
};

// Approve a merchant or delivery account
// PUT /api/admin/users/:id/approve
exports.approveUser = async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ success: false, message: 'Utilisateur introuvable' });

    if (!NEEDS_APPROVAL.includes(user.role)) {
      return res.status(400).json({ success: false, message: 'Seuls les marchands et livreurs doivent être approuvés' });
    }

    user.isApproved = true;
    user.approvedAt = new Date();
    user.rejectionReason = undefined;
    await user.save();
    await notifyApproval(user);

    res.json({ success: true, message: 'Compte approuvé', data: { user } });
  } catch (err) {
    console.error('approveUser error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// Reject (or revoke) a merchant or delivery account
// PUT /api/admin/users/:id/reject   body { reason? }
exports.rejectUser = async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ success: false, message: 'Utilisateur introuvable' });

    if (!NEEDS_APPROVAL.includes(user.role)) {
      return res.status(400).json({ success: false, message: 'Seuls les marchands et livreurs doivent être approuvés' });
    }

    user.isApproved = false;
    user.isAvailable = false;
    user.approvedAt = undefined;
    user.rejectionReason = (req.body && req.body.reason) || 'Informations insuffisantes';
    await user.save();
    await notifyApproval(user);

    res.json({ success: true, message: 'Compte refusé', data: { user } });
  } catch (err) {
    console.error('rejectUser error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// Get all users (with optional role filter)
// ?role=merchant|delivery|...  ?approval=pending
exports.getUsers = async (req, res) => {
  try {
    const { role, approval } = req.query;
    const filter = {};
    if (role && role !== 'all') filter.role = role;
    if (approval === 'pending') {
      filter.isApproved = false;
      if (!filter.role) filter.role = { $in: NEEDS_APPROVAL };
    }

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
    const { name, phone, password, role, isActive } = req.body;
    const email = req.body.email ? String(req.body.email).trim().toLowerCase() : undefined;

    if (!name || !phone || !password) {
      return res.status(400).json({ success: false, message: 'Champs requis manquants' });
    }

    // Check duplicate phone or email (only compare email when one is given)
    const duplicates = [{ phone }];
    if (email) duplicates.push({ email });
    const existing = await User.findOne({ $or: duplicates });
    if (existing) {
      return res.status(400).json({ success: false, message: 'Utilisateur déjà existant (téléphone ou email)' });
    }

    const userData = { name, phone, email, password, role: role || USER_ROLES.CLIENT, isActive: isActive !== undefined ? isActive : true };
    EDITABLE_USER_FIELDS.forEach((field) => {
      if (userData[field] === undefined && req.body[field] !== undefined && req.body[field] !== '') {
        userData[field] = req.body[field];
      }
    });
    if (userData.isApproved) userData.approvedAt = new Date();

    const user = await User.create(userData);

    res.status(201).json({ success: true, data: { user } });
  } catch (err) {
    if (err.name === 'ValidationError') {
      return res.status(400).json({ success: false, message: Object.values(err.errors).map((e) => e.message).join(', ') });
    }
    console.error('createUser error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// Fields the admin may edit (anything else in the body is ignored)
const EDITABLE_USER_FIELDS = [
  'name', 'phone', 'email', 'role', 'isActive', 'isApproved',
  'shopName', 'shopDescription', 'shopAddress', 'shopPhone',
  'vehicleType', 'vehicleNumber'
];

// Update user
exports.updateUser = async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body || {};

    // Load and save (instead of findByIdAndUpdate) so validators and the password hash hook run
    const user = await User.findById(id);
    if (!user) return res.status(404).json({ success: false, message: 'Utilisateur introuvable' });

    const wasApproved = user.isApproved;

    EDITABLE_USER_FIELDS.forEach((field) => {
      if (updates[field] !== undefined) user[field] = updates[field];
    });
    // Empty vehicle type from the form must not break the enum validator
    if (user.vehicleType === '') user.vehicleType = undefined;
    if (updates.password) user.password = updates.password;

    if (user.isApproved && !wasApproved) {
      user.approvedAt = new Date();
      user.rejectionReason = undefined;
    }
    if (!user.isApproved || !user.isActive) user.isAvailable = false;

    await user.save();

    if (user.isApproved !== wasApproved) await notifyApproval(user);

    res.json({ success: true, data: { user } });
  } catch (err) {
    if (err.name === 'ValidationError' || err.code === 11000) {
      const message = err.code === 11000
        ? 'Ce téléphone ou cet email est déjà utilisé'
        : Object.values(err.errors).map((e) => e.message).join(', ');
      return res.status(400).json({ success: false, message });
    }
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
    if (!user.isActive) user.isAvailable = false;
    await user.save();
    res.json({ success: true, data: { user } });
  } catch (err) {
    console.error('toggleUserStatus error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};
