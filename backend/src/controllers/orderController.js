const Order = require('../models/Order');
const Product = require('../models/Product');
const User = require('../models/User');

const generateOrderNumber = async () => {
  const lastOrder = await Order.findOne({ orderNumber: { $exists: true } }).sort({ _id: -1 });
  const lastNumber = lastOrder && lastOrder.orderNumber
    ? parseInt(lastOrder.orderNumber.replace('ORD-', ''))
    : 0;
  return `ORD-${String(lastNumber + 1).padStart(6, '0')}`;
};

// Create a new order
exports.createOrder = async (req, res) => {
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

    let merchantId;
    let total = 0;
    const processedItems = [];

    // Normalize payment method to backend enum values
    const normalizedPaymentMethod = paymentMethod == 'cod' ? 'cash' : paymentMethod || 'cash';

    // Validate and calculate total
    for (const item of items) {
      const product = await Product.findById(item.product);
      if (!product) {
        return res.status(404).json({ success: false, message: `Produit ${item.product} introuvable` });
      }

      if (product.stock < item.quantity) {
        return res.status(400).json({ success: false, message: `Stock insuffisant pour ${product.name}` });
      }

      // Set merchant from first product
      if (!merchantId) {
        merchantId = product.merchant;
      }

      const subtotal = product.price * item.quantity;
      total += subtotal;

      processedItems.push({
        product: product._id,
        quantity: item.quantity,
        price: product.price,
        subtotal
      });
    }

    // Create order
    const orderNumber = await generateOrderNumber();
    const order = await Order.create({
      orderNumber,
      client: clientId,
      merchant: merchantId,
      items: processedItems,
      total,
      deliveryAddress: deliveryAddressValue,
      deliveryPhone: deliveryPhone || req.user.phone,
      paymentMethod: normalizedPaymentMethod,
      notes
    });

    // Reduce product stock
    for (const item of processedItems) {
      await Product.findByIdAndUpdate(item.product, {
        $inc: { stock: -item.quantity }
      });
    }

    const populatedOrder = await Order.findById(order._id)
      .populate('client', 'name phone email')
      .populate('merchant', 'shopName phone')
      .populate('items.product', 'name price images');

    res.status(201).json({
      success: true,
      data: { order: populatedOrder },
      message: 'Commande créée avec succès'
    });
  } catch (err) {
    console.error('createOrder error', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// Get user's orders
exports.getUserOrders = async (req, res) => {
  try {
    const userId = req.user._id;
    const { status } = req.query;

    const filter = { $or: [{ client: userId }, { merchant: userId }] };
    if (status && status !== 'all') filter.status = status;

    const orders = await Order.find(filter)
      .populate('client', 'name phone email')
      .populate('merchant', 'shopName phone')
      .populate('items.product', 'name price images')
      .sort({ createdAt: -1 });

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
    const order = await Order.findById(orderId)
      .populate('client', 'name phone email address')
      .populate('merchant', 'shopName phone email shopAddress')
      .populate('items.product', 'name description price images');

    if (!order) {
      return res.status(404).json({ success: false, message: 'Commande introuvable' });
    }

    // Check if user is involved in this order
    if (req.user._id.toString() !== order.client._id.toString() && 
        req.user._id.toString() !== order.merchant._id.toString()) {
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

// Update order status (client/merchant/admin)
exports.updateOrderStatus = async (req, res) => {
  try {
    const { orderId } = req.params;
    const { status } = req.body;

    const validStatuses = ['pending', 'confirmed', 'preparing', 'ready', 'in_transit', 'delivered', 'cancelled', 'rejected', 'completed'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ success: false, message: 'Statut invalide' });
    }

    const order = await Order.findById(orderId);
    if (!order) {
      return res.status(404).json({ success: false, message: 'Commande introuvable' });
    }

    // Check permissions
    if (req.user._id.toString() !== order.merchant._id.toString() && 
        req.user.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Accès refusé' });
    }

    // Update timestamps based on status
    if (status === 'delivered') {
      order.deliveredAt = new Date();
    } else if (status === 'cancelled') {
      order.cancelledAt = new Date();
      // Restore product stock
      for (const item of order.items) {
        await Product.findByIdAndUpdate(item.product, {
          $inc: { stock: item.quantity }
        });
      }
    }

    order.status = status;
    await order.save();

    const updatedOrder = await order.populate('client', 'name phone')
      .populate('merchant', 'shopName phone')
      .populate('items.product', 'name price');

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

// Cancel order
exports.cancelOrder = async (req, res) => {
  try {
    const { orderId } = req.params;
    const { reason } = req.body;

    const order = await Order.findById(orderId);
    if (!order) {
      return res.status(404).json({ success: false, message: 'Commande introuvable' });
    }

    // Check if user is the client
    if (req.user._id.toString() !== order.client._id.toString()) {
      return res.status(403).json({ success: false, message: 'Accès refusé' });
    }

    // Can only cancel if not already delivered/cancelled
    if (['delivered', 'cancelled', 'completed'].includes(order.status)) {
      return res.status(400).json({ success: false, message: 'Impossible d\'annuler cette commande' });
    }

    // Restore product stock
    for (const item of order.items) {
      await Product.findByIdAndUpdate(item.product, {
        $inc: { stock: item.quantity }
      });
    }

    order.status = 'cancelled';
    order.cancelledAt = new Date();
    order.cancelReason = reason || 'Annulée par le client';
    await order.save();

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
