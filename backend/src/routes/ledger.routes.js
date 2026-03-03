const express = require('express');
const router = express.Router({ mergeParams: true });
const { ledgerController } = require('../controllers');
const {
  authenticate,
  authorizeShopAccess,
  requirePermission,
  validate,
  validateObjectId,
} = require('../middleware');
const {
  createLedgerEntrySchema,
  updateLedgerEntrySchema,
  deleteLedgerEntrySchema,
  queryLedgerEntriesSchema,
} = require('../validators');

// All routes require authentication and shop access
router.use(authenticate);
router.use(authorizeShopAccess);

// Ledger routes
router.post(
  '/',
  requirePermission('manage_ledger'),
  validate(createLedgerEntrySchema),
  ledgerController.createLedgerEntry
);

router.get(
  '/',
  requirePermission('view_ledger'),
  validate(queryLedgerEntriesSchema, 'query'),
  ledgerController.getLedgerEntries
);

router.get(
  '/summary',
  requirePermission('view_ledger'),
  ledgerController.getLedgerSummary
);

router.get(
  '/:entryId',
  requirePermission('view_ledger'),
  validateObjectId('entryId'),
  ledgerController.getLedgerEntry
);

router.patch(
  '/:entryId',
  requirePermission('manage_ledger'),
  validateObjectId('entryId'),
  validate(updateLedgerEntrySchema),
  ledgerController.updateLedgerEntry
);

router.delete(
  '/:entryId',
  requirePermission('manage_ledger'),
  validateObjectId('entryId'),
  validate(deleteLedgerEntrySchema),
  ledgerController.deleteLedgerEntry
);

// Customer-specific ledger route (nested under customers)
router.get(
  '/customers/:customerId',
  requirePermission('view_ledger'),
  validateObjectId('customerId'),
  ledgerController.getCustomerLedger
);

module.exports = router;
