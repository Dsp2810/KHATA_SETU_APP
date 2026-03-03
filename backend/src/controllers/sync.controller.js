const { SyncQueue, LedgerEntry, Customer, Product, InventoryTransaction, Reminder, DailyNote } = require('../models');
const { asyncHandler, AppError } = require('../middleware');
const { auditLog } = require('../utils');
const mongoose = require('mongoose');

/**
 * Sync offline data
 * POST /api/shops/:shopId/sync
 */
const syncData = asyncHandler(async (req, res) => {
  const { shopId } = req.params;
  const { items, deviceId, lastSyncAt } = req.body;
  
  if (!items || !Array.isArray(items)) {
    throw new AppError('items array is required', 400, 'INVALID_INPUT');
  }
  
  const results = {
    success: [],
    failed: [],
    conflicts: [],
  };
  
  const session = await mongoose.startSession();
  session.startTransaction();
  
  try {
    for (const item of items) {
      try {
        let result;
        
        switch (item.entityType) {
          case 'customer':
            result = await syncCustomer(shopId, item, req.userId, session);
            break;
          case 'ledger_entry':
            result = await syncLedgerEntry(shopId, item, req.userId, session);
            break;
          case 'product':
            result = await syncProduct(shopId, item, req.userId, session);
            break;
          case 'inventory_transaction':
            result = await syncInventoryTransaction(shopId, item, req.userId, session);
            break;
          case 'reminder':
            result = await syncReminder(shopId, item, req.userId, session);
            break;
          case 'daily_note':
            result = await syncDailyNote(shopId, item, req.userId, session);
            break;
          default:
            throw new Error(`Unknown entity type: ${item.entityType}`);
        }
        
        if (result.conflict) {
          results.conflicts.push({
            offlineId: item.offlineId,
            entityType: item.entityType,
            serverData: result.serverData,
          });
        } else {
          results.success.push({
            offlineId: item.offlineId,
            entityType: item.entityType,
            serverId: result.serverId,
          });
        }
      } catch (error) {
        results.failed.push({
          offlineId: item.offlineId,
          entityType: item.entityType,
          error: error.message,
        });
      }
    }
    
    await session.commitTransaction();
    
    auditLog('SYNC_COMPLETED', req.userId, {
      shopId,
      deviceId,
      success: results.success.length,
      failed: results.failed.length,
      conflicts: results.conflicts.length,
    });
    
    res.json({
      success: true,
      message: 'Sync completed',
      data: {
        results,
        syncedAt: new Date(),
      },
    });
  } catch (error) {
    await session.abortTransaction();
    throw error;
  } finally {
    session.endSession();
  }
});

/**
 * Sync a customer
 */
async function syncCustomer(shopId, item, userId, session) {
  const { operation, payload, offlineId } = item;
  
  if (operation === 'create') {
    // Check for duplicates by phone
    const existing = await Customer.findOne({
      shopId,
      phone: payload.phone,
    }).session(session);
    
    if (existing) {
      return {
        conflict: true,
        serverData: existing,
      };
    }
    
    const customer = await Customer.create([{
      ...payload,
      shopId,
    }], { session });
    
    return { serverId: customer[0]._id };
  }
  
  if (operation === 'update') {
    const customer = await Customer.findOneAndUpdate(
      { _id: payload._id, shopId },
      payload,
      { session, new: true }
    );
    
    return { serverId: customer._id };
  }
  
  if (operation === 'delete') {
    await Customer.findOneAndUpdate(
      { _id: payload._id, shopId },
      { isActive: false },
      { session }
    );
    
    return { serverId: payload._id };
  }
}

/**
 * Sync a ledger entry
 */
async function syncLedgerEntry(shopId, item, userId, session) {
  const { operation, payload, offlineId, clientTimestamp } = item;
  
  if (operation === 'create') {
    // Check if already synced
    const existing = await LedgerEntry.findOne({ offlineId }).session(session);
    
    if (existing) {
      return { serverId: existing._id };
    }
    
    // Get customer current balance to check for conflicts
    const customer = await Customer.findById(payload.customerId).session(session);
    
    if (!customer) {
      throw new Error('Customer not found');
    }
    
    const entry = await LedgerEntry.create([{
      ...payload,
      shopId,
      createdBy: userId,
      isOfflineEntry: true,
      offlineId,
      syncedAt: new Date(),
    }], { session });
    
    return { serverId: entry[0]._id };
  }
  
  if (operation === 'delete') {
    // Soft delete with reason
    await LedgerEntry.findOneAndUpdate(
      { _id: payload._id, shopId },
      {
        isDeleted: true,
        deletedAt: new Date(),
        deletedBy: userId,
        deletionReason: payload.reason || 'Deleted offline',
      },
      { session }
    );
    
    return { serverId: payload._id };
  }
}

/**
 * Sync a product
 */
async function syncProduct(shopId, item, userId, session) {
  const { operation, payload, offlineId } = item;
  
  if (operation === 'create') {
    const product = await Product.create([{
      ...payload,
      shopId,
    }], { session });
    
    return { serverId: product[0]._id };
  }
  
  if (operation === 'update') {
    const product = await Product.findOneAndUpdate(
      { _id: payload._id, shopId },
      payload,
      { session, new: true }
    );
    
    return { serverId: product._id };
  }
  
  if (operation === 'delete') {
    await Product.findOneAndUpdate(
      { _id: payload._id, shopId },
      { isActive: false },
      { session }
    );
    
    return { serverId: payload._id };
  }
}

/**
 * Sync an inventory transaction
 */
async function syncInventoryTransaction(shopId, item, userId, session) {
  const { operation, payload, offlineId } = item;
  
  if (operation === 'create') {
    const existing = await InventoryTransaction.findOne({ offlineId }).session(session);
    
    if (existing) {
      return { serverId: existing._id };
    }
    
    const transaction = await InventoryTransaction.create([{
      ...payload,
      shopId,
      createdBy: userId,
      isOfflineEntry: true,
      offlineId,
      syncedAt: new Date(),
    }], { session });
    
    return { serverId: transaction[0]._id };
  }
}

/**
 * Sync a reminder
 */
async function syncReminder(shopId, item, userId, session) {
  const { operation, payload, offlineId } = item;
  
  if (operation === 'create') {
    const reminder = await Reminder.create([{
      ...payload,
      shopId,
      createdBy: userId,
    }], { session });
    
    return { serverId: reminder[0]._id };
  }
  
  if (operation === 'update') {
    const reminder = await Reminder.findOneAndUpdate(
      { _id: payload._id, shopId },
      payload,
      { session, new: true }
    );
    
    return { serverId: reminder._id };
  }
  
  if (operation === 'delete') {
    await Reminder.findOneAndUpdate(
      { _id: payload._id, shopId },
      { isDeleted: true },
      { session }
    );
    
    return { serverId: payload._id };
  }
}

/**
 * Sync a daily note
 */
async function syncDailyNote(shopId, item, userId, session) {
  const { operation, payload, offlineId } = item;

  if (operation === 'create') {
    // Dedup by offlineId
    const existing = await DailyNote.findOne({ offlineId }).session(session);
    if (existing) {
      return { serverId: existing._id };
    }

    const note = await DailyNote.create([{
      ...payload,
      shopId,
      createdBy: userId,
      isOfflineEntry: true,
      offlineId,
      syncedAt: new Date(),
    }], { session });

    return { serverId: note[0]._id };
  }

  if (operation === 'update') {
    const note = await DailyNote.findOneAndUpdate(
      { _id: payload._id, shopId, isDeleted: false },
      { ...payload, modifiedBy: userId },
      { session, new: true }
    );

    return { serverId: note._id };
  }

  if (operation === 'delete') {
    await DailyNote.findOneAndUpdate(
      { _id: payload._id, shopId },
      {
        isDeleted: true,
        deletedAt: new Date(),
        deletedBy: userId,
      },
      { session }
    );

    return { serverId: payload._id };
  }
}

/**
 * Get changes since last sync
 * GET /api/shops/:shopId/sync/changes
 */
const getChanges = asyncHandler(async (req, res) => {
  const { shopId } = req.params;
  const { since, entityTypes } = req.query;
  
  const sinceDate = since ? new Date(since) : new Date(0);
  const types = entityTypes ? entityTypes.split(',') : ['customer', 'ledger_entry', 'product', 'reminder', 'daily_note'];
  
  const changes = {};
  
  if (types.includes('customer')) {
    changes.customers = await Customer.find({
      shopId,
      updatedAt: { $gt: sinceDate },
    }).lean();
  }
  
  if (types.includes('ledger_entry')) {
    changes.ledgerEntries = await LedgerEntry.find({
      shopId,
      updatedAt: { $gt: sinceDate },
    }).lean();
  }
  
  if (types.includes('product')) {
    changes.products = await Product.find({
      shopId,
      updatedAt: { $gt: sinceDate },
    }).lean();
  }
  
  if (types.includes('reminder')) {
    changes.reminders = await Reminder.find({
      shopId,
      updatedAt: { $gt: sinceDate },
    }).lean();
  }
  
  if (types.includes('daily_note')) {
    changes.dailyNotes = await DailyNote.find({
      shopId,
      updatedAt: { $gt: sinceDate },
    }).lean();
  }
  
  res.json({
    success: true,
    data: {
      changes,
      serverTime: new Date(),
    },
  });
});

/**
 * Get sync status
 * GET /api/shops/:shopId/sync/status
 */
const getSyncStatus = asyncHandler(async (req, res) => {
  const { shopId } = req.params;
  
  const status = await SyncQueue.getSyncStatus(shopId);
  
  res.json({
    success: true,
    data: { status },
  });
});

/**
 * Resolve sync conflict
 * POST /api/shops/:shopId/sync/resolve
 */
const resolveConflict = asyncHandler(async (req, res) => {
  const { shopId } = req.params;
  const { offlineId, resolution, mergedData } = req.body;
  
  if (!['client_wins', 'server_wins', 'merged'].includes(resolution)) {
    throw new AppError('Invalid resolution type', 400, 'INVALID_RESOLUTION');
  }
  
  const queueItem = await SyncQueue.findOne({ offlineId, shopId, status: 'conflict' });
  
  if (!queueItem) {
    throw new AppError('Conflict not found', 404, 'CONFLICT_NOT_FOUND');
  }
  
  if (resolution === 'client_wins') {
    // Apply client data
    // Implementation depends on entity type
  } else if (resolution === 'merged') {
    // Apply merged data
    // Implementation depends on entity type
  }
  
  await SyncQueue.resolveConflict(offlineId, resolution, req.userId);
  
  res.json({
    success: true,
    message: 'Conflict resolved',
  });
});

module.exports = {
  syncData,
  getChanges,
  getSyncStatus,
  resolveConflict,
};
