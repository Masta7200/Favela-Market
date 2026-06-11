const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middlewares/auth');
const { USER_ROLES } = require('../constants');
const productController = require('../controllers/productController');

// Public routes
router.get('/', productController.getPublicProducts);
router.get('/my-products', protect, authorize(USER_ROLES.MERCHANT), productController.getMerchantProducts);
router.get('/:id', productController.getPublicProduct);

// Merchant routes (requires merchant role)
router.post('/', protect, authorize(USER_ROLES.MERCHANT), productController.createMerchantProduct);
router.put('/:id', protect, authorize(USER_ROLES.MERCHANT), productController.updateMerchantProduct);
router.delete('/:id', protect, authorize(USER_ROLES.MERCHANT), productController.deleteMerchantProduct);

module.exports = router;
