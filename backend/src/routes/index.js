const express = require('express');
const router = express.Router();

const authRoutes = require('./auth.routes');
const shopRoutes = require('./shop.routes');
const customerRoutes = require('./customer.routes');
const ledgerRoutes = require('./ledger.routes');
const productRoutes = require('./product.routes');
const reminderRoutes = require('./reminder.routes');
const reportRoutes = require('./report.routes');
const syncRoutes = require('./sync.routes');
const noteRoutes = require('./note.routes');

// Health check
router.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'KhataSetu API is running',
    timestamp: new Date().toISOString(),
    version: '1.0.0',
  });
});

// Mount routes
router.use('/auth', authRoutes);
router.use('/shops', shopRoutes);

// Nested routes under shops (mergeParams ensures :shopId is available)
router.use('/shops/:shopId/customers', customerRoutes);
router.use('/shops/:shopId/ledger', ledgerRoutes);
router.use('/shops/:shopId/products', productRoutes);
router.use('/shops/:shopId/reminders', reminderRoutes);
router.use('/shops/:shopId/reports', reportRoutes);
router.use('/shops/:shopId/sync', syncRoutes);
router.use('/shops/:shopId/notes', noteRoutes);

module.exports = router;
