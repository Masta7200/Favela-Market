const Product = require('../models/Product');
const { ORDER_STATUS, FINAL_ORDER_STATUSES, NOTIFICATION_TYPES } = require('../constants');
const { notifyUser, notifyUsers } = require('./notify');

const STATUS_LABELS = {
  pending: 'En attente',
  confirmed: 'Confirmée',
  preparing: 'En préparation',
  ready: 'Prête à récupérer',
  in_transit: 'En livraison',
  delivered: 'Livrée',
  completed: 'Terminée',
  cancelled: 'Annulée',
  rejected: 'Rejetée'
};

const VALID_STATUSES = Object.values(ORDER_STATUS);

// Same populated shape for every app (client, merchant, delivery, admin)
const populateOrder = (query) => query
  .populate('client', 'name phone email')
  .populate('merchant', 'name shopName phone shopPhone shopAddress email')
  .populate('deliveryPerson', 'name phone vehicleType vehicleNumber isAvailable')
  .populate('items.product', 'name description price images image');

const idOf = (ref) => (ref && ref._id ? ref._id : ref);
const sameId = (a, b) => a != null && b != null && String(idOf(a)) === String(idOf(b));

const isFinal = (status) => FINAL_ORDER_STATUSES.includes(status);

const restoreStock = async (order) => {
  for (const item of order.items) {
    await Product.findByIdAndUpdate(idOf(item.product), { $inc: { stock: item.quantity } });
  }
};

// Set the new status with its timestamps and stock / payment side effects.
// Does not save the order.
const applyStatus = async (order, status, { reason } = {}) => {
  const previous = order.status;
  order.status = status;

  if (status === ORDER_STATUS.IN_TRANSIT && !order.pickedUpAt) {
    order.pickedUpAt = new Date();
  }

  if (status === ORDER_STATUS.DELIVERED) {
    order.deliveredAt = new Date();
    // Cash is collected on delivery
    if (order.paymentMethod === 'cash') order.paymentStatus = 'paid';
    for (const item of order.items) {
      await Product.findByIdAndUpdate(idOf(item.product), { $inc: { soldCount: item.quantity } });
    }
  }

  if ((status === ORDER_STATUS.CANCELLED || status === ORDER_STATUS.REJECTED) && !isFinal(previous)) {
    order.cancelledAt = new Date();
    if (reason) order.cancelReason = reason;
    await restoreStock(order);
  }
};

// Tell everyone involved that the status changed (except the person who did it)
const notifyStatusChange = async (order, status, actorId) => {
  const label = STATUS_LABELS[status] || status;
  const cancelled = status === ORDER_STATUS.CANCELLED || status === ORDER_STATUS.REJECTED;
  const type = cancelled ? NOTIFICATION_TYPES.ORDER_CANCELLED : NOTIFICATION_TYPES.ORDER_UPDATED;
  const reason = cancelled && order.cancelReason ? ` Motif : ${order.cancelReason}` : '';

  // The delivery person gets a specific message when the parcel can be collected
  const readyForPickup = status === ORDER_STATUS.READY && order.deliveryPerson && order.deliveryAcceptedAt;

  const recipients = [
    idOf(order.client),
    idOf(order.merchant),
    readyForPickup ? null : idOf(order.deliveryPerson)
  ].filter((id) => id && !sameId(id, actorId));

  await notifyUsers(recipients, {
    title: `Commande ${order.orderNumber} : ${label}`,
    message: `La commande ${order.orderNumber} est maintenant « ${label} ».${reason}`,
    type,
    order: order._id
  });

  if (readyForPickup && !sameId(order.deliveryPerson, actorId)) {
    await notifyUser(idOf(order.deliveryPerson), {
      title: 'Commande prête à récupérer',
      message: `La commande ${order.orderNumber} vous attend chez le marchand.`,
      type: NOTIFICATION_TYPES.ORDER_UPDATED,
      order: order._id
    });
  }
};

module.exports = {
  STATUS_LABELS,
  VALID_STATUSES,
  populateOrder,
  idOf,
  sameId,
  isFinal,
  restoreStock,
  applyStatus,
  notifyStatusChange
};
