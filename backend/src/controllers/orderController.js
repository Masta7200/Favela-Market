const Order = require('../models/Order');
const Product = require('../models/Product');
const { USER_ROLES, ORDER_STATUS, NOTIFICATION_TYPES } = require('../constants');
const { notifyUser, notifyUsers, notifyAdmins } = require('../utils/notify');
const {
  STATUS_LABELS,
  VALID_STATUSES,
  populateOrder,
  idOf,
  sameId,
  isFinal,
  applyStatus,
  notifyStatusChange
} = require('../utils/orderHelpers');

const generateOrderNumber = async () => {
  const lastOrder = await Order.findOne({ orderNumber: { $exists: true } }).sort({ _id: -1 });
  const lastNumber = lastOrder && lastOrder.orderNumber
    ? parseInt(lastOrder.orderNumber.replace('ORD-', ''))
    : 0;
  return `ORD-${String(lastNumber + 1).padStart(6, '0')}`;
};

// Two orders placed at the same moment can get the same number: retry on duplicate key
const createWithOrderNumber = async (data, attempts = 5) => {
  for (let i = 0; i < attempts; i++) {
    try {
      return await Order.create({ ...data, orderNumber: await generateOrderNumber() });
    } catch (err) {
      if (err.code !== 11000 || i === attempts - 1) throw err;
    }
  }
};

const canSeeOrder = (user, order) =>
  user.role === USER_ROLES.ADMIN ||
  sameId(order.client, user._id) ||
  sameId(order.merchant, user._id) ||
  sameId(order.deliveryPerson, user._id);

// Create a new order.
// A cart can contain products from several merchants: one order is created per merchant,
// so each merchant only sees (and prepares) their own items.
exports.createOrder = async (req, res) => {
  const reserved = []; // stock already taken, given back if something fails
  try {
    const { items, deliveryAddress, deliveryPhone, paymentMethod, notes } = req.body;
    const clientId = req.user._id;

    if (!items || items.length === 0) {
      return res.status(400).json({ success: false, message: 'Les articles sont requis' });
    }

    if (!deliveryAddress) {
      return res.status(400).json({ success: false, message: 'L\'adresse de livraison est requise' });
    }

    // Convert deliveryAddress object to structured object if needed
    let deliveryAddressValue = deliveryAddress;
    if (typeof deliveryAddress === 'object' && deliveryAddress !== null) {
      deliveryAddressValue = {
        label: `${deliveryAddress.fullAddress}, ${deliveryAddress.quarter ?? ''}, ${deliveryAddress.city}`
            .replace(/, ,/g, ',')
            .replace(/, $/, ''),
        fullAddress: deliveryAddress.fullAddress,
        city: deliveryAddress.city,
        quarter: deliveryAddress.quarter,
        details: deliveryAddress.details,
      };
    }

    // Normalize payment method to backend enum values
    const normalizedPaymentMethod = paymentMethod == 'cod' ? 'cash' : paymentMethod || 'cash';

    // Validate every product first
    const groups = new Map(); // merchantId -> { items, total }
    for (const item of items) {
      const quantity = Number(item.quantity);
      if (!Number.isInteger(quantity) || quantity < 1) {
        return res.status(400).json({ success: false, message: 'Quantité invalide' });
      }

      const product = await Product.findById(item.product).populate('merchant', 'role isActive');
      if (!product || !product.isApproved || !product.isActive || !product.merchant || !product.merchant.isActive) {
        return res.status(404).json({ success: false, message: `Produit ${item.product} introuvable ou indisponible` });
      }

      if (product.stock < quantity) {
        return res.status(400).json({ success: false, message: `Stock insuffisant pour ${product.name}` });
      }

      const merchantId = String(product.merchant._id);
      if (!groups.has(merchantId)) {
        groups.set(merchantId, { items: [], total: 0, sellerRole: product.merchant.role });
      }
      const group = groups.get(merchantId);

      const subtotal = product.price * quantity;
      group.total += subtotal;
      group.items.push({ product: product._id, quantity, price: product.price, subtotal, name: product.name });
    }

    // Reserve stock atomically (no overselling when two clients buy the last item)
    for (const group of groups.values()) {
      for (const item of group.items) {
        const updated = await Product.findOneAndUpdate(
          { _id: item.product, stock: { $gte: item.quantity } },
          { $inc: { stock: -item.quantity } }
        );
        if (!updated) {
          throw Object.assign(new Error(`Stock insuffisant pour ${item.name}`), { statusCode: 400 });
        }
        reserved.push(item);
      }
    }

    // One order per merchant
    const created = [];
    const needsDeliveryPerson = [];
    for (const [merchantId, group] of groups) {
      // A delivery person selling their own item delivers it themselves:
      // the order is assigned to them, already accepted and confirmed.
      const sellerDelivers = group.sellerRole === USER_ROLES.DELIVERY;
      const now = new Date();

      const order = await createWithOrderNumber({
        client: clientId,
        merchant: merchantId,
        items: group.items.map(({ name, ...rest }) => rest),
        total: group.total,
        deliveryAddress: deliveryAddressValue,
        deliveryPhone: deliveryPhone || req.user.phone,
        paymentMethod: normalizedPaymentMethod,
        notes,
        ...(sellerDelivers ? {
          status: ORDER_STATUS.CONFIRMED,
          deliveryPerson: merchantId,
          assignedAt: now,
          deliveryAcceptedAt: now
        } : {})
      });
      created.push(order);
      if (!sellerDelivers) needsDeliveryPerson.push(order);

      await notifyUser(merchantId, {
        title: sellerDelivers ? 'Nouvelle commande à livrer' : 'Nouvelle commande',
        message: `Commande ${order.orderNumber} de ${req.user.name} : ${group.items.length} article(s), ${group.total.toLocaleString('fr-FR')} FCFA.`,
        type: sellerDelivers ? NOTIFICATION_TYPES.ORDER_ASSIGNED : NOTIFICATION_TYPES.ORDER_NEW,
        order: order._id
      });
    }

    if (needsDeliveryPerson.length) {
      await notifyAdmins({
        title: 'Nouvelle commande à livrer',
        message: `${needsDeliveryPerson.map((o) => o.orderNumber).join(', ')} : un livreur doit être assigné.`,
        type: NOTIFICATION_TYPES.ORDER_NEW,
        order: needsDeliveryPerson[0]._id
      });
    }

    const populatedOrders = await populateOrder(Order.find({ _id: { $in: created.map((o) => o._id) } }));

    res.status(201).json({
      success: true,
      // `order` is kept for the current client app; `orders` lists every order created
      data: { order: populatedOrders[0], orders: populatedOrders },
      message: created.length > 1
        ? `${created.length} commandes créées (une par boutique)`
        : 'Commande créée avec succès'
    });
  } catch (err) {
    // Give back any stock that was reserved before the failure
    for (const item of reserved) {
      await Product.findByIdAndUpdate(item.product, { $inc: { stock: item.quantity } }).catch(() => {});
    }
    if (err.statusCode === 400) {
      return res.status(400).json({ success: false, message: err.message });
    }
    console.error('createOrder error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// Get the current user's orders (as client, merchant or delivery person)
exports.getUserOrders = async (req, res) => {
  try {
    const userId = req.user._id;
    const { status } = req.query;

    let filter;
    if (req.user.role === USER_ROLES.MERCHANT) filter = { merchant: userId };
    else if (req.user.role === USER_ROLES.DELIVERY) filter = { deliveryPerson: userId };
    else filter = { client: userId };

    if (status && status !== 'all') filter.status = status;

    const orders = await populateOrder(Order.find(filter)).sort({ createdAt: -1 });

    res.json({
      success: true,
      data: { orders }
    });
  } catch (err) {
    console.error('getUserOrders error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// Get order by ID
exports.getOrder = async (req, res) => {
  try {
    const { orderId } = req.params;
    const order = await populateOrder(Order.findById(orderId));

    if (!order) {
      return res.status(404).json({ success: false, message: 'Commande introuvable' });
    }

    // Only the client, the merchant, the assigned delivery person or an admin
    if (!canSeeOrder(req.user, order)) {
      return res.status(403).json({ success: false, message: 'Accès refusé' });
    }

    res.json({
      success: true,
      data: { order }
    });
  } catch (err) {
    console.error('getOrder error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// Update order status (merchant)
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

    // Check permissions
    if (!sameId(order.merchant, req.user._id) && req.user.role !== USER_ROLES.ADMIN) {
      return res.status(403).json({ success: false, message: 'Accès refusé' });
    }

    if (isFinal(order.status)) {
      return res.status(400).json({
        success: false,
        message: `Cette commande est déjà « ${STATUS_LABELS[order.status]} »`
      });
    }

    // Once a delivery person is assigned, they handle pickup and delivery
    if (order.deliveryPerson &&
        [ORDER_STATUS.IN_TRANSIT, ORDER_STATUS.DELIVERED].includes(status) &&
        req.user.role !== USER_ROLES.ADMIN) {
      return res.status(400).json({
        success: false,
        message: 'Un livreur est assigné : c\'est lui qui confirme la récupération et la livraison'
      });
    }

    await applyStatus(order, status, { reason: reason || (status === ORDER_STATUS.REJECTED ? 'Rejetée par le marchand' : undefined) });
    await order.save();
    await notifyStatusChange(order, status, req.user._id);

    const updatedOrder = await populateOrder(Order.findById(order._id));

    res.json({
      success: true,
      data: { order: updatedOrder },
      message: 'Statut mis à jour avec succès'
    });
  } catch (err) {
    console.error('updateOrderStatus error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// Cancel order (client)
exports.cancelOrder = async (req, res) => {
  try {
    const { orderId } = req.params;
    const { reason } = req.body || {};

    const order = await Order.findById(orderId);
    if (!order) {
      return res.status(404).json({ success: false, message: 'Commande introuvable' });
    }

    // Check if user is the client
    if (!sameId(order.client, req.user._id)) {
      return res.status(403).json({ success: false, message: 'Accès refusé' });
    }

    // Can't cancel once finished or already on its way
    if (isFinal(order.status) || order.status === ORDER_STATUS.IN_TRANSIT) {
      return res.status(400).json({ success: false, message: 'Impossible d\'annuler cette commande' });
    }

    await applyStatus(order, ORDER_STATUS.CANCELLED, { reason: reason || 'Annulée par le client' });
    await order.save();
    await notifyStatusChange(order, ORDER_STATUS.CANCELLED, req.user._id);

    res.json({
      success: true,
      data: { order },
      message: 'Commande annulée avec succès'
    });
  } catch (err) {
    console.error('cancelOrder error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// ==================== DELIVERY PERSON ====================

// Load an order assigned to the current delivery person, or send the error response
const loadAssignedOrder = async (req, res) => {
  const order = await Order.findById(req.params.orderId);
  if (!order) {
    res.status(404).json({ success: false, message: 'Commande introuvable' });
    return null;
  }
  if (!sameId(order.deliveryPerson, req.user._id)) {
    res.status(403).json({ success: false, message: 'Cette commande ne vous est pas assignée' });
    return null;
  }
  if (isFinal(order.status)) {
    res.status(400).json({ success: false, message: `Cette commande est « ${STATUS_LABELS[order.status]} »` });
    return null;
  }
  return order;
};

// @route GET /api/orders/delivery/orders
exports.getDeliveryOrders = async (req, res) => {
  try {
    const filter = { deliveryPerson: req.user._id };
    if (req.query.status && req.query.status !== 'all') filter.status = req.query.status;

    const orders = await populateOrder(Order.find(filter)).sort({ assignedAt: -1, createdAt: -1 });

    res.json({ success: true, data: { orders } });
  } catch (err) {
    console.error('getDeliveryOrders error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// @route PUT /api/orders/:orderId/delivery/accept
exports.acceptDelivery = async (req, res) => {
  try {
    const order = await loadAssignedOrder(req, res);
    if (!order) return;

    if (order.deliveryAcceptedAt) {
      return res.status(400).json({ success: false, message: 'Vous avez déjà accepté cette livraison' });
    }

    order.deliveryAcceptedAt = new Date();
    await order.save();

    await notifyUsers([idOf(order.merchant), idOf(order.client)], {
      title: `Livreur en route pour ${order.orderNumber}`,
      message: `${req.user.name} (${req.user.phone}) va prendre en charge la commande ${order.orderNumber}.`,
      type: NOTIFICATION_TYPES.ORDER_UPDATED,
      order: order._id
    });

    const populated = await populateOrder(Order.findById(order._id));
    res.json({ success: true, message: 'Livraison acceptée', data: { order: populated } });
  } catch (err) {
    console.error('acceptDelivery error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// @route PUT /api/orders/:orderId/delivery/decline   body { reason? }
exports.declineDelivery = async (req, res) => {
  try {
    const order = await loadAssignedOrder(req, res);
    if (!order) return;

    if (order.pickedUpAt || order.status === ORDER_STATUS.IN_TRANSIT) {
      return res.status(400).json({ success: false, message: 'Commande déjà récupérée : impossible de la refuser' });
    }

    const reason = (req.body && req.body.reason) || 'Aucun motif';
    order.deliveryDeclines.push({ deliveryPerson: req.user._id, reason });
    order.deliveryPerson = undefined;
    order.assignedAt = undefined;
    order.deliveryAcceptedAt = undefined;
    await order.save();

    await notifyAdmins({
      title: `Livraison refusée : ${order.orderNumber}`,
      message: `${req.user.name} a refusé la commande ${order.orderNumber}. Motif : ${reason}. Merci d'assigner un autre livreur.`,
      type: NOTIFICATION_TYPES.DELIVERY_DECLINED,
      order: order._id
    });

    res.json({ success: true, message: 'Livraison refusée' });
  } catch (err) {
    console.error('declineDelivery error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// @route PUT /api/orders/:orderId/delivery/status   body { status: 'in_transit' | 'delivered' }
exports.updateDeliveryStatus = async (req, res) => {
  try {
    const { status } = req.body;
    if (![ORDER_STATUS.IN_TRANSIT, ORDER_STATUS.DELIVERED].includes(status)) {
      return res.status(400).json({ success: false, message: 'Statut invalide (in_transit ou delivered)' });
    }

    const order = await loadAssignedOrder(req, res);
    if (!order) return;

    if (!order.deliveryAcceptedAt) {
      return res.status(400).json({ success: false, message: 'Acceptez d\'abord la livraison' });
    }

    if (status === ORDER_STATUS.IN_TRANSIT &&
        ![ORDER_STATUS.CONFIRMED, ORDER_STATUS.PREPARING, ORDER_STATUS.READY].includes(order.status)) {
      return res.status(400).json({ success: false, message: 'La commande n\'a pas encore été confirmée par le marchand' });
    }

    if (status === ORDER_STATUS.DELIVERED && order.status !== ORDER_STATUS.IN_TRANSIT) {
      return res.status(400).json({ success: false, message: 'Confirmez d\'abord la récupération de la commande' });
    }

    await applyStatus(order, status);
    await order.save();
    await notifyStatusChange(order, status, req.user._id);

    if (status === ORDER_STATUS.DELIVERED) {
      await notifyAdmins({
        title: `Commande ${order.orderNumber} livrée`,
        message: `${req.user.name} a livré la commande ${order.orderNumber}.`,
        type: NOTIFICATION_TYPES.ORDER_UPDATED,
        order: order._id
      });
    }

    const populated = await populateOrder(Order.findById(order._id));
    res.json({ success: true, message: 'Statut mis à jour', data: { order: populated } });
  } catch (err) {
    console.error('updateDeliveryStatus error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};
