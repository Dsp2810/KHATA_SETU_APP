const { asyncHandler } = require('../middleware');
const LedgerService = require('../services/ledger.service');

/**
 * Ledger Controller — Thin layer delegating to LedgerService.
 * All business logic (sessions, balance updates, inventory) is in the service.
 */

/**
 * Create a new ledger entry (atomic with balance update)
 * POST /api/shops/:shopId/ledger
 */
const createLedgerEntry = asyncHandler(async (req, res) => {
  const { shopId } = req.params;

  const result = await LedgerService.createEntry(shopId, req.body, req.userId);

  res.status(201).json({
    success: true,
    message: `${result.entry.type === 'credit' ? 'Credit' : 'Payment'} recorded successfully`,
    data: {
      entry: result.entry,
      balanceBefore: result.balanceBefore,
      balanceAfter: result.balanceAfter,
    },
  });
});

/**
 * Get all ledger entries for a shop.
 * When no customerId filter is provided, returns ALL entries (fixes visibility bug).
 * GET /api/shops/:shopId/ledger
 */
const getLedgerEntries = asyncHandler(async (req, res) => {
  const { shopId } = req.params;
  const result = await LedgerService.getEntries(shopId, req.query);
  res.json({ success: true, data: result });
});

/**
 * Get ledger entries for a specific customer
 * GET /api/shops/:shopId/customers/:customerId/ledger
 */
const getCustomerLedger = asyncHandler(async (req, res) => {
  const { shopId, customerId } = req.params;
  const result = await LedgerService.getCustomerLedger(shopId, customerId, req.query);
  res.json({ success: true, data: result });
});

/**
 * Get a single ledger entry
 * GET /api/shops/:shopId/ledger/:entryId
 */
const getLedgerEntry = asyncHandler(async (req, res) => {
  const { shopId, entryId } = req.params;
  const entry = await LedgerService.getEntry(shopId, entryId);
  res.json({ success: true, data: { entry } });
});

/**
 * Update a ledger entry (limited fields only)
 * PATCH /api/shops/:shopId/ledger/:entryId
 */
const updateLedgerEntry = asyncHandler(async (req, res) => {
  const { shopId, entryId } = req.params;
  const entry = await LedgerService.updateEntry(shopId, entryId, req.body, req.userId);
  res.json({ success: true, message: 'Entry updated successfully', data: { entry } });
});

/**
 * Delete a ledger entry with reverse balance calculation (atomic)
 * DELETE /api/shops/:shopId/ledger/:entryId
 */
const deleteLedgerEntry = asyncHandler(async (req, res) => {
  const { shopId, entryId } = req.params;
  const { reason } = req.body;
  const result = await LedgerService.deleteEntry(shopId, entryId, req.userId, reason);
  res.json({
    success: true,
    message: 'Entry deleted and balance reversed successfully',
    data: result,
  });
});

/**
 * Get ledger summary/dashboard
 * GET /api/shops/:shopId/ledger/summary
 */
const getLedgerSummary = asyncHandler(async (req, res) => {
  const { shopId } = req.params;
  const result = await LedgerService.getSummary(shopId, req.query);
  res.json({ success: true, data: result });
});

module.exports = {
  createLedgerEntry,
  getLedgerEntries,
  getCustomerLedger,
  getLedgerEntry,
  updateLedgerEntry,
  deleteLedgerEntry,
  getLedgerSummary,
};
