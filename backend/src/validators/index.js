// Export all validators
const authValidator = require('./auth.validator');
const customerValidator = require('./customer.validator');
const ledgerValidator = require('./ledger.validator');
const productValidator = require('./product.validator');
const reminderValidator = require('./reminder.validator');
const noteValidator = require('./note.validator');

module.exports = {
  ...authValidator,
  ...customerValidator,
  ...ledgerValidator,
  ...productValidator,
  ...reminderValidator,
  ...noteValidator,
};
