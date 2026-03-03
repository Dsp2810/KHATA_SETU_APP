// Export all controllers
const authController = require('./auth.controller');
const shopController = require('./shop.controller');
const customerController = require('./customer.controller');
const ledgerController = require('./ledger.controller');
const productController = require('./product.controller');
const reminderController = require('./reminder.controller');
const reportController = require('./report.controller');
const syncController = require('./sync.controller');
const noteController = require('./note.controller');

module.exports = {
  authController,
  shopController,
  customerController,
  ledgerController,
  productController,
  reminderController,
  reportController,
  syncController,
  noteController,
};
