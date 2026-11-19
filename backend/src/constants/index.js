// User Roles
const USER_ROLES = {
  CLIENT: 'client',
  MERCHANT: 'merchant',
  DELIVERY: 'delivery',
  ADMIN: 'admin'
};

// Order Status (must match the enum in models/Order.js)
const ORDER_STATUS = {
  PENDING: 'pending',           // En attente
  CONFIRMED: 'confirmed',       // Confirmé
  PREPARING: 'preparing',       // En préparation
  READY: 'ready',               // Prêt à récupérer
  IN_TRANSIT: 'in_transit',     // En livraison
  DELIVERED: 'delivered',       // Livré
  COMPLETED: 'completed',       // Terminé
  CANCELLED: 'cancelled',       // Annulé
  REJECTED: 'rejected'          // Rejeté
};

// Statuses after which an order can no longer change
const FINAL_ORDER_STATUSES = [
  ORDER_STATUS.DELIVERED,
  ORDER_STATUS.COMPLETED,
  ORDER_STATUS.CANCELLED,
  ORDER_STATUS.REJECTED
];

// Notification types
const NOTIFICATION_TYPES = {
  ORDER_NEW: 'order_new',               // Merchant: new order received
  ORDER_ASSIGNED: 'order_assigned',     // Delivery: order assigned to you
  ORDER_UPDATED: 'order_updated',       // Status changed
  ORDER_CANCELLED: 'order_cancelled',
  DELIVERY_DECLINED: 'delivery_declined', // Admin: a delivery person declined
  ACCOUNT_PENDING: 'account_pending',   // Admin: new account to verify
  ACCOUNT_APPROVED: 'account_approved',
  ACCOUNT_REJECTED: 'account_rejected',
  PRODUCT_APPROVED: 'product_approved',
  PRODUCT_REJECTED: 'product_rejected',
  GENERAL: 'general'
};

// Product Status
const PRODUCT_STATUS = {
  PENDING: 'pending',          // En attente d'approbation
  APPROVED: 'approved',        // Approuvé
  REJECTED: 'rejected',        // Rejeté
  INACTIVE: 'inactive'         // Inactif
};

// Payment Methods
const PAYMENT_METHODS = {
  COD: 'cod'                   // Cash on Delivery / Paiement à la livraison
};

module.exports = {
  USER_ROLES,
  ORDER_STATUS,
  FINAL_ORDER_STATUSES,
  NOTIFICATION_TYPES,
  PRODUCT_STATUS,
  PAYMENT_METHODS
};