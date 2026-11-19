const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middlewares/auth');
const { USER_ROLES } = require('../constants');
const productController = require('../controllers/productController');

// Merchants and delivery persons can both sell items (products still need admin approval)
const sellers = authorize(USER_ROLES.MERCHANT, USER_ROLES.DELIVERY);

// Public routes
router.get('/', productController.getPublicProducts);
router.get('/my-products', protect, sellers, productController.getMerchantProducts);
router.get('/:id', productController.getPublicProduct);

// Seller routes
router.post('/', protect, sellers, productController.createMerchantProduct);
router.put('/:id', protect, sellers, productController.updateMerchantProduct);
router.delete('/:id', protect, sellers, productController.deleteMerchantProduct);

module.exports = router;
