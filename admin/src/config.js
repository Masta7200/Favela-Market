// API Configuration
export const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:5000/api';

export const ENDPOINTS = {
  // Auth
  LOGIN: '/auth/login',
  
  // Dashboard Stats
  STATS: '/admin/stats',
  // Public platform figures (landing page, no login)
  PUBLIC_STATS: '/public/stats',
  
  // Users
  USERS: '/admin/users',

  // Merchant & delivery account verification
  APPROVE_USER: (id) => `/admin/users/${id}/approve`,
  REJECT_USER: (id) => `/admin/users/${id}/reject`,

  // Products
  PRODUCTS: '/admin/products',
  PRODUCT_BY_ID: (id) => `/admin/products/${id}`,
  APPROVE_PRODUCT: (id) => `/admin/products/${id}/approve`,
  REJECT_PRODUCT: (id) => `/admin/products/${id}/reject`,
  
  // Categories
  CATEGORIES: '/admin/categories',
  CATEGORY_BY_ID: (id) => `/admin/categories/${id}`,
  
  // Orders
  ORDERS: '/admin/orders',
  ORDER_BY_ID: (id) => `/admin/orders/${id}`,
  UPDATE_ORDER_STATUS: (id) => `/admin/orders/${id}/status`,
  DELETE_ORDER: (id) => `/admin/orders/${id}`,
  ASSIGN_ORDER: (id) => `/admin/orders/${id}/assign`,

  // Delivery Personnel (approved + active)
  DELIVERY_PERSONS: '/admin/delivery-persons',

  // Notifications (admin's own)
  NOTIFICATIONS: '/notifications',
  NOTIFICATION_READ: (id) => `/notifications/${id}/read`,
  NOTIFICATIONS_READ_ALL: '/notifications/read-all',
};

// How often the admin panel checks for new notifications
export const NOTIFICATION_POLL_MS = 30000;

// Must match the backend Order status enum
export const ORDER_STATUSES = [
  { value: 'pending', label: 'En attente', color: 'gray' },
  { value: 'confirmed', label: 'Confirmé', color: 'blue' },
  { value: 'preparing', label: 'En préparation', color: 'yellow' },
  { value: 'ready', label: 'Prêt', color: 'purple' },
  { value: 'in_transit', label: 'En livraison', color: 'orange' },
  { value: 'delivered', label: 'Livré', color: 'green' },
  { value: 'completed', label: 'Terminé', color: 'green' },
  { value: 'cancelled', label: 'Annulé', color: 'red' },
  { value: 'rejected', label: 'Rejeté', color: 'red' },
];

export const getOrderStatus = (value) =>
  ORDER_STATUSES.find((s) => s.value === value) || { value, label: value, color: 'gray' };

// Tailwind classes for the status colours above
export const BADGE_CLASSES = {
  gray: 'bg-gray-100 text-gray-700',
  blue: 'bg-blue-100 text-blue-700',
  yellow: 'bg-yellow-100 text-yellow-700',
  purple: 'bg-purple-100 text-purple-700',
  indigo: 'bg-indigo-100 text-indigo-700',
  orange: 'bg-orange-100 text-orange-700',
  green: 'bg-green-100 text-green-700',
  red: 'bg-red-100 text-red-700',
};

export const FINAL_ORDER_STATUSES = ['delivered', 'completed', 'cancelled', 'rejected'];

export const VEHICLE_TYPES = { moto: 'Moto', velo: 'Vélo', voiture: 'Voiture' };

export const ROLE_LABELS = { client: 'Client', merchant: 'Marchand', delivery: 'Livreur', admin: 'Admin' };

export const CURRENCY = 'FCFA';