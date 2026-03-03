// Export all models
const User = require('./User.model');
const Shop = require('./Shop.model');
const Customer = require('./Customer.model');
const LedgerEntry = require('./LedgerEntry.model');
const Product = require('./Product.model');
const InventoryTransaction = require('./InventoryTransaction.model');
const Reminder = require('./Reminder.model');
const RefreshToken = require('./RefreshToken.model');
const FCMToken = require('./FCMToken.model');
const SyncQueue = require('./SyncQueue.model');
const DailyNote = require('./DailyNote.model');

module.exports = {
  User,
  Shop,
  Customer,
  LedgerEntry,
  Product,
  InventoryTransaction,
  Reminder,
  RefreshToken,
  FCMToken,
  SyncQueue,
  DailyNote,
};
