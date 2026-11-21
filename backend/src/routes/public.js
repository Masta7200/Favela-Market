const express = require('express');
const router = express.Router();
const { getPublicStats } = require('../controllers/publicController');

// No authentication: used by the landing page
router.get('/stats', getPublicStats);

module.exports = router;
