const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middlewares/auth');
const { USER_ROLES } = require('../constants');
const productController = require('../controllers/productController');

// Public routes
router.get('/', productController.getPublicProducts);
router.get('/:id', productController.getPublicProduct);

// Merchant routes (requires merchant role)
router.get('/merchant/my-products', protect, authorize(USER_ROLES.MERCHANT), productController.getMerchantProducts);
router.post('/merchant', protect, authorize(USER_ROLES.MERCHANT), productController.createMerchantProduct);
router.put('/merchant/:id', protect, authorize(USER_ROLES.MERCHANT), productController.updateMerchantProduct);
router.delete('/merchant/:id', protect, authorize(USER_ROLES.MERCHANT), productController.deleteMerchantProduct);

module.exports = router;
