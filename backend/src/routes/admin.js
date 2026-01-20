const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middlewares/auth');
const { USER_ROLES } = require('../constants');
const adminController = require('../controllers/adminController');
const productController = require('../controllers/productController');
const categoryController = require('../controllers/categoryController');

// All admin routes require authentication and admin role
router.use(protect, authorize(USER_ROLES.ADMIN));

// Stats
router.get('/stats', adminController.getStats);

// Users
router.get('/users', adminController.getUsers);
router.post('/users', adminController.createUser);
router.put('/users/:id', adminController.updateUser);
router.delete('/users/:id', adminController.deleteUser);
router.put('/users/:id/toggle-status', adminController.toggleUserStatus);

// Products
router.get('/products', productController.getProducts);
router.get('/products/:id', productController.getProduct);
router.post('/products', productController.createProduct);
router.put('/products/:id', productController.updateProduct);
router.delete('/products/:id', productController.deleteProduct);
router.put('/products/:id/approve', productController.approveProduct);
router.put('/products/:id/reject', productController.rejectProduct);

// Categories
router.get('/categories', categoryController.getCategories);
router.get('/categories/:id', categoryController.getCategory);
router.post('/categories', categoryController.createCategory);
router.put('/categories/:id', categoryController.updateCategory);
router.delete('/categories/:id', categoryController.deleteCategory);
router.put('/categories/:id/toggle-status', categoryController.toggleCategoryStatus);

module.exports = router;
