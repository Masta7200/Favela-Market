// API Configuration
export const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:5000/api';

export const ENDPOINTS = {
  // Auth
  LOGIN: '/auth/login',
  
  // Dashboard Stats
  STATS: '/admin/stats',
  
  // Users
  USERS: '/admin/users',
  
  // Merchants
  MERCHANTS: '/admin/merchants',
  APPROVE_MERCHANT: (id) => `/admin/merchants/${id}/approve`,
  REJECT_MERCHANT: (id) => `/admin/merchants/${id}/reject`,
  
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
  
  // Delivery Personnel
  DELIVERY: '/admin/delivery',
};

export const ORDER_STATUSES = [
  { value: 'pending', label: 'En attente', color: 'gray' },
  { value: 'confirmed', label: 'Confirmé', color: 'blue' },
  { value: 'preparing', label: 'En préparation', color: 'yellow' },
  { value: 'ready', label: 'Prêt', color: 'purple' },
  { value: 'picked', label: 'Récupéré', color: 'indigo' },
  { value: 'delivering', label: 'En livraison', color: 'orange' },
  { value: 'delivered', label: 'Livré', color: 'green' },
  { value: 'cancelled', label: 'Annulé', color: 'red' },
  { value: 'rejected', label: 'Rejeté', color: 'red' },
];

export const CURRENCY = 'FCFA';