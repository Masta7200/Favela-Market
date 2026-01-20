// User Roles
const USER_ROLES = {
  CLIENT: 'client',
  MERCHANT: 'merchant',
  DELIVERY: 'delivery',
  ADMIN: 'admin'
};

// Order Status
const ORDER_STATUS = {
  PENDING: 'pending',           // En attente
  CONFIRMED: 'confirmed',       // Confirmé
  PREPARING: 'preparing',       // En préparation
  READY: 'ready',              // Prêt
  PICKED: 'picked',            // Récupéré
  DELIVERING: 'delivering',    // En livraison
  DELIVERED: 'delivered',      // Livré
  CANCELLED: 'cancelled',      // Annulé
  REJECTED: 'rejected'         // Rejeté
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
  PRODUCT_STATUS,
  PAYMENT_METHODS
};