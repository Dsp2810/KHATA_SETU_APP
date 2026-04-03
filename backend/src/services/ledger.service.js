const mongoose = require('mongoose');
const { LedgerEntry, Customer, Product, InventoryTransaction } = require('../models');
const { AppError } = require('../middleware');
const { logger, auditLog } = require('../utils');

/**
 * LedgerService — Encapsulates ALL ledger business logic.
 * Uses MongoDB sessions for atomic transactions.
 */
class LedgerService {
  /**
   * Create a ledger entry with atomic balance update.
   * Uses MongoDB session to ensure consistency.
   */
  static async createEntry(shopId, entryData, userId) {
    const session = await mongoose.startSession();
    session.startTransaction();

    const txnId = new mongoose.Types.ObjectId().toString().slice(-8);
    logger.info(`[TXN:${txnId}] ── CREATE LEDGER ENTRY ──`);
    logger.info(`[TXN:${txnId}] Shop: ${shopId}, Customer: ${entryData.customerId}, Type: ${entryData.type}, Amount: ₹${entryData.amount}`);

    try {
      // 1. Fetch customer inside session
      const customer = await Customer.findOne({
        _id: entryData.customerId,
        shopId,
      }).session(session);

      if (!customer) {
        throw new AppError('Customer not found', 404, 'CUSTOMER_NOT_FOUND');
      }

      const balanceBefore = customer.currentBalance;
      logger.info(`[TXN:${txnId}] Balance BEFORE: ₹${balanceBefore}`);

      // 2. Credit limit check
      if (entryData.type === 'credit') {
        const newBalance = customer.currentBalance + entryData.amount;
        if (customer.creditLimit > 0 && newBalance > customer.creditLimit) {
          throw new AppError(
            `Credit limit exceeded. Limit: ₹${customer.creditLimit}, Current: ₹${customer.currentBalance}, Requested: ₹${entryData.amount}`,
            400,
            'CREDIT_LIMIT_EXCEEDED'
          );
        }
      }

      // 3. Calculate new balance
      let balanceAfter;
      if (entryData.type === 'credit') {
        balanceAfter = customer.currentBalance + entryData.amount;
      } else {
        balanceAfter = customer.currentBalance - entryData.amount;
      }

      // 4. Create ledger entry with explicit balanceAfter (skip pre-save hooks)
      const entry = new LedgerEntry({
        ...entryData,
        shopId,
        createdBy: userId,
        balanceAfter,
      });

      // Save entry — but we handle balance manually in this service
      // so we skip the model's pre-save hook by flagging
      entry._skipBalanceUpdate = true;
      await entry.save({ session });

      // 5. Update customer balance atomically
      customer.currentBalance = balanceAfter;
      customer.lastTransactionAt = new Date();
      await customer.save({ session });

      logger.info(`[TXN:${txnId}] Balance AFTER: ₹${balanceAfter}`);

      // 6. Handle linked products (inventory deduction for credit/sale entries)
      if (entryData.linkedProducts && entryData.linkedProducts.length > 0) {
        for (const item of entryData.linkedProducts) {
          const product = await Product.findById(item.productId).session(session);
          if (product) {
            const previousStock = product.currentStock;
            const quantity = item.quantity || 1;

            if (entryData.type === 'credit') {
              // Selling on credit → reduce stock
              if (product.currentStock < quantity) {
                logger.warn(`[TXN:${txnId}] Insufficient stock for ${product.name}: has ${product.currentStock}, need ${quantity}`);
              } else {
                product.currentStock -= quantity;
              }
            }

            // Record inventory transaction
            const invTxn = new InventoryTransaction({
              shopId,
              productId: item.productId,
              type: entryData.type === 'credit' ? 'sale' : 'return',
              quantity,
              previousStock,
              newStock: product.currentStock,
              unitPrice: item.pricePerUnit || product.sellingPrice,
              totalValue: quantity * (item.pricePerUnit || product.sellingPrice),
              referenceType: 'ledger_entry',
              referenceId: entry._id,
              referenceModel: 'LedgerEntry',
              customerId: entryData.customerId,
              createdBy: userId,
            });

            invTxn._skipStockUpdate = true;
            await invTxn.save({ session });
            await product.save({ session });

            logger.info(`[TXN:${txnId}] Inventory: ${product.name} ${previousStock} → ${product.currentStock}`);
          }
        }
      }

      // 7. Commit
      await session.commitTransaction();
      logger.info(`[TXN:${txnId}] ✅ COMMITTED successfully`);

      // Populate for response
      await entry.populate('customerId', 'name phone currentBalance');

      auditLog('LEDGER_ENTRY_CREATED', userId, {
        txnId,
        entryId: entry._id,
        shopId,
        type: entry.type,
        amount: entry.amount,
        balanceBefore,
        balanceAfter,
      });

      return {
        entry,
        balanceBefore,
        balanceAfter,
      };
    } catch (error) {
      await session.abortTransaction();
      logger.error(`[TXN:${txnId}] ❌ ABORTED: ${error.message}`);
      throw error;
    } finally {
      session.endSession();
    }
  }

  /**
   * Delete (soft-delete) a ledger entry with reverse balance calculation.
   * Atomically reverses the balance impact.
   */
  static async deleteEntry(shopId, entryId, userId, reason) {
    const session = await mongoose.startSession();
    session.startTransaction();

    const txnId = new mongoose.Types.ObjectId().toString().slice(-8);
    logger.info(`[TXN:${txnId}] ── DELETE LEDGER ENTRY ──`);
    logger.info(`[TXN:${txnId}] Shop: ${shopId}, EntryId: ${entryId}`);

    try {
      // 1. Fetch entry
      const entry = await LedgerEntry.findOne({
        _id: entryId,
        shopId,
      }).session(session);

      if (!entry) {
        throw new AppError('Ledger entry not found', 404, 'ENTRY_NOT_FOUND');
      }

      if (entry.isDeleted) {
        throw new AppError('Entry already deleted', 400, 'ALREADY_DELETED');
      }

      // 2. Fetch customer
      const customer = await Customer.findById(entry.customerId).session(session);
      if (!customer) {
        throw new AppError('Customer not found', 404, 'CUSTOMER_NOT_FOUND');
      }

      const balanceBefore = customer.currentBalance;
      logger.info(`[TXN:${txnId}] Entry type: ${entry.type}, Amount: ₹${entry.amount}`);
      logger.info(`[TXN:${txnId}] Balance BEFORE reversal: ₹${balanceBefore}`);

      // 3. Reverse balance impact
      //    - If original was 'credit' (customer owes more) → subtract to reverse
      //    - If original was 'debit' (customer paid) → add to reverse
      let balanceAfter;
      if (entry.type === 'credit') {
        balanceAfter = customer.currentBalance - entry.amount;
      } else {
        balanceAfter = customer.currentBalance + entry.amount;
      }

      customer.currentBalance = balanceAfter;
      await customer.save({ session });

      logger.info(`[TXN:${txnId}] Balance AFTER reversal: ₹${balanceAfter}`);

      // 4. Reverse inventory impact if linked products exist
      if (entry.linkedProducts && entry.linkedProducts.length > 0) {
        for (const item of entry.linkedProducts) {
          const product = await Product.findById(item.productId).session(session);
          if (product) {
            const previousStock = product.currentStock;

            if (entry.type === 'credit') {
              // Original was a sale → return stock
              product.currentStock += item.quantity;
            } else {
              // Original was a return/payment → remove stock
              product.currentStock = Math.max(0, product.currentStock - item.quantity);
            }

            const invTxn = new InventoryTransaction({
              shopId,
              productId: item.productId,
              type: entry.type === 'credit' ? 'return' : 'stock_out',
              quantity: item.quantity,
              previousStock,
              newStock: product.currentStock,
              unitPrice: item.pricePerUnit || product.sellingPrice,
              totalValue: item.quantity * (item.pricePerUnit || product.sellingPrice),
              referenceType: 'ledger_entry',
              referenceId: entry._id,
              referenceModel: 'LedgerEntry',
              notes: `Reversal: Entry ${entryId} deleted. Reason: ${reason}`,
              createdBy: userId,
            });

            invTxn._skipStockUpdate = true;
            await invTxn.save({ session });
            await product.save({ session });

            logger.info(`[TXN:${txnId}] Inventory reversed: ${product.name} ${previousStock} → ${product.currentStock}`);
          }
        }
      }

      // 5. Soft delete the entry
      entry.isDeleted = true;
      entry.deletedAt = new Date();
      entry.deletedBy = userId;
      entry.deletionReason = reason;
      await entry.save({ session });

      // 6. Commit
      await session.commitTransaction();
      logger.info(`[TXN:${txnId}] ✅ DELETE COMMITTED`);

      auditLog('LEDGER_ENTRY_DELETED', userId, {
        txnId,
        entryId,
        shopId,
        reason,
        type: entry.type,
        amount: entry.amount,
        balanceBefore,
        balanceAfter,
      });

      return {
        reversedAmount: entry.amount,
        balanceBefore,
        balanceAfter,
        newBalance: balanceAfter,
      };
    } catch (error) {
      await session.abortTransaction();
      logger.error(`[TXN:${txnId}] ❌ DELETE ABORTED: ${error.message}`);
      throw error;
    } finally {
      session.endSession();
    }
  }

  /**
   * Get ALL ledger entries for a shop (not just one customer).
   * This fixes "only customer transactions showing" by returning all entries
   * when no customerId filter is provided.
   */
  static async getEntries(shopId, filters = {}) {
    const {
      customerId,
      type,
      paymentMode,
      startDate,
      endDate,
      minAmount,
      maxAmount,
      includeDeleted = false,
      sortBy = 'createdAt',
      sortOrder = 'desc',
      page = 1,
      limit = 20,
    } = filters;

    // Build query — shopId is the ONLY required filter
    const query = { shopId: new mongoose.Types.ObjectId(shopId) };

    if (!includeDeleted) {
      query.isDeleted = false;
    }

    // Optional customer filter — when omitted, ALL shop entries are returned
    if (customerId) {
      query.customerId = new mongoose.Types.ObjectId(customerId);
    }

    if (type) {
      query.type = type;
    }

    if (paymentMode) {
      query.paymentMode = paymentMode;
    }

    if (startDate || endDate) {
      query.createdAt = {};
      if (startDate) query.createdAt.$gte = new Date(startDate);
      if (endDate) query.createdAt.$lte = new Date(endDate);
    }

    if (minAmount !== undefined || maxAmount !== undefined) {
      query.amount = {};
      if (minAmount !== undefined) query.amount.$gte = Number(minAmount);
      if (maxAmount !== undefined) query.amount.$lte = Number(maxAmount);
    }

    const sort = { [sortBy]: sortOrder === 'desc' ? -1 : 1 };
    const skip = (Number(page) - 1) * Number(limit);

    logger.debug(`[LEDGER] getEntries query: ${JSON.stringify(query)}`);

    const [entries, totalCount] = await Promise.all([
      LedgerEntry.find(query)
        .populate('customerId', 'name phone currentBalance')
        .populate('createdBy', 'name')
        .sort(sort)
        .skip(skip)
        .limit(Number(limit))
        .lean(),
      LedgerEntry.countDocuments(query),
    ]);

    // Summary aggregation
    const summary = await LedgerEntry.aggregate([
      { $match: { ...query, isDeleted: false } },
      {
        $group: {
          _id: null,
          totalCredit: {
            $sum: { $cond: [{ $eq: ['$type', 'credit'] }, '$amount', 0] },
          },
          totalDebit: {
            $sum: { $cond: [{ $eq: ['$type', 'debit'] }, '$amount', 0] },
          },
          totalTransactions: { $sum: 1 },
        },
      },
    ]);

    return {
      entries,
      pagination: {
        page: Number(page),
        limit: Number(limit),
        totalCount,
        totalPages: Math.ceil(totalCount / Number(limit)),
      },
      summary: summary[0] || {
        totalCredit: 0,
        totalDebit: 0,
        totalTransactions: 0,
      },
    };
  }

  /**
   * Get customer-specific ledger entries with customer details.
   */
  static async getCustomerLedger(shopId, customerId, filters = {}) {
    const { page = 1, limit = 20, startDate, endDate } = filters;

    const customer = await Customer.findOne({ _id: customerId, shopId });
    if (!customer) {
      throw new AppError('Customer not found', 404, 'CUSTOMER_NOT_FOUND');
    }

    const query = {
      shopId: new mongoose.Types.ObjectId(shopId),
      customerId: new mongoose.Types.ObjectId(customerId),
      isDeleted: false,
    };

    if (startDate || endDate) {
      query.createdAt = {};
      if (startDate) query.createdAt.$gte = new Date(startDate);
      if (endDate) query.createdAt.$lte = new Date(endDate);
    }

    const skip = (Number(page) - 1) * Number(limit);

    const [entries, totalCount] = await Promise.all([
      LedgerEntry.find(query)
        .populate('customerId', 'name phone')
        .populate('linkedProducts.productId', 'name sellingPrice')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(Number(limit))
        .lean(),
      LedgerEntry.countDocuments(query),
    ]);

    return {
      customer: {
        id: customer._id,
        name: customer.name,
        phone: customer.phone,
        currentBalance: customer.currentBalance,
        creditLimit: customer.creditLimit,
        trustScore: customer.trustScore,
      },
      entries,
      pagination: {
        page: Number(page),
        limit: Number(limit),
        totalCount,
        totalPages: Math.ceil(totalCount / Number(limit)),
      },
    };
  }

  /**
   * Get single entry with full population.
   */
  static async getEntry(shopId, entryId) {
    const entry = await LedgerEntry.findOne({ _id: entryId, shopId })
      .populate('customerId', 'name phone currentBalance')
      .populate('createdBy', 'name')
      .populate('modifiedBy', 'name')
      .populate('linkedProducts.productId', 'name sellingPrice');

    if (!entry) {
      throw new AppError('Ledger entry not found', 404, 'ENTRY_NOT_FOUND');
    }

    return entry;
  }

  /**
   * Update a ledger entry (limited to non-financial fields).
   */
  static async updateEntry(shopId, entryId, updates, userId) {
    const entry = await LedgerEntry.findOne({ _id: entryId, shopId });

    if (!entry) {
      throw new AppError('Ledger entry not found', 404, 'ENTRY_NOT_FOUND');
    }

    if (entry.isDeleted) {
      throw new AppError('Cannot update deleted entry', 400, 'ENTRY_DELETED');
    }

    const allowedUpdates = ['description', 'notes'];
    const safeUpdates = {};
    allowedUpdates.forEach(field => {
      if (updates[field] !== undefined) {
        safeUpdates[field] = updates[field];
      }
    });
    safeUpdates.modifiedBy = userId;

    const updatedEntry = await LedgerEntry.findByIdAndUpdate(
      entryId,
      safeUpdates,
      { new: true }
    ).populate('customerId', 'name phone');

    auditLog('LEDGER_ENTRY_UPDATED', userId, {
      entryId,
      shopId,
      updates: Object.keys(safeUpdates),
    });

    return updatedEntry;
  }

  /**
   * Ledger summary/dashboard aggregation.
   */
  static async getSummary(shopId, filters = {}) {
    const { startDate, endDate } = filters;

    const dateQuery = {};
    if (startDate) dateQuery.createdAt = { $gte: new Date(startDate) };
    if (endDate) dateQuery.createdAt = { ...dateQuery.createdAt, $lte: new Date(endDate) };

    const matchStage = {
      shopId: new mongoose.Types.ObjectId(shopId),
      isDeleted: false,
      ...dateQuery,
    };

    const [summary, paymentModeBreakdown, dailyTrends] = await Promise.all([
      LedgerEntry.aggregate([
        { $match: matchStage },
        {
          $group: {
            _id: null,
            totalCredit: { $sum: { $cond: [{ $eq: ['$type', 'credit'] }, '$amount', 0] } },
            totalDebit: { $sum: { $cond: [{ $eq: ['$type', 'debit'] }, '$amount', 0] } },
            creditCount: { $sum: { $cond: [{ $eq: ['$type', 'credit'] }, 1, 0] } },
            debitCount: { $sum: { $cond: [{ $eq: ['$type', 'debit'] }, 1, 0] } },
            totalTransactions: { $sum: 1 },
          },
        },
      ]),
      LedgerEntry.aggregate([
        { $match: { ...matchStage, type: 'debit' } },
        { $group: { _id: '$paymentMode', amount: { $sum: '$amount' }, count: { $sum: 1 } } },
      ]),
      LedgerEntry.aggregate([
        {
          $match: {
            shopId: new mongoose.Types.ObjectId(shopId),
            isDeleted: false,
            createdAt: { $gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) },
          },
        },
        {
          $group: {
            _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
            credit: { $sum: { $cond: [{ $eq: ['$type', 'credit'] }, '$amount', 0] } },
            debit: { $sum: { $cond: [{ $eq: ['$type', 'debit'] }, '$amount', 0] } },
          },
        },
        { $sort: { _id: 1 } },
      ]),
    ]);

    return {
      summary: summary[0] || {
        totalCredit: 0, totalDebit: 0, creditCount: 0, debitCount: 0, totalTransactions: 0,
      },
      paymentModeBreakdown,
      dailyTrends,
    };
  }
}

module.exports = LedgerService;
