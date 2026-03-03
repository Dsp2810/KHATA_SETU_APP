const { LedgerEntry, Customer } = require('../models');
const { asyncHandler, AppError } = require('../middleware');
const { auditLog } = require('../utils');
const mongoose = require('mongoose');

/**
 * Create a new ledger entry
 * POST /api/shops/:shopId/ledger
 */
const createLedgerEntry = asyncHandler(async (req, res) => {
  const { shopId } = req.params;
  const entryData = {
    ...req.body,
    shopId,
    createdBy: req.userId,
  };
  
  // Verify customer exists
  const customer = await Customer.findOne({
    _id: req.body.customerId,
    shopId,
  });
  
  if (!customer) {
    throw new AppError('Customer not found', 404, 'CUSTOMER_NOT_FOUND');
  }
  
  // Check credit limit for credit entries
  if (req.body.type === 'credit') {
    const newBalance = customer.currentBalance + req.body.amount;
    if (customer.creditLimit > 0 && newBalance > customer.creditLimit) {
      throw new AppError(
        `Credit limit exceeded. Customer limit: ₹${customer.creditLimit}, Current balance: ₹${customer.currentBalance}`,
        400,
        'CREDIT_LIMIT_EXCEEDED'
      );
    }
  }
  
  const entry = await LedgerEntry.create(entryData);
  
  // Populate for response
  await entry.populate('customerId', 'name phone currentBalance');
  
  auditLog('LEDGER_ENTRY_CREATED', req.userId, {
    entryId: entry._id,
    shopId,
    type: entry.type,
    amount: entry.amount,
  });
  
  res.status(201).json({
    success: true,
    message: `${entry.type === 'credit' ? 'Credit' : 'Payment'} recorded successfully`,
    data: { entry },
  });
});

/**
 * Get all ledger entries for a shop
 * GET /api/shops/:shopId/ledger
 */
const getLedgerEntries = asyncHandler(async (req, res) => {
  const { shopId } = req.params;
  const {
    customerId,
    type,
    paymentMode,
    startDate,
    endDate,
    minAmount,
    maxAmount,
    includeDeleted,
    sortBy,
    sortOrder,
    page,
    limit,
  } = req.query;
  
  // Build query
  const query = { shopId: new mongoose.Types.ObjectId(shopId) };
  
  if (!includeDeleted) {
    query.isDeleted = false;
  }
  
  if (customerId) {
    query.customerId = new mongoose.Types.ObjectId(customerId);
  }
  
  if (type) {
    query.type = type;
  }
  
  if (paymentMode) {
    query.paymentMode = paymentMode;
  }
  
  if (startDate) {
    query.createdAt = { $gte: new Date(startDate) };
  }
  
  if (endDate) {
    query.createdAt = { ...query.createdAt, $lte: new Date(endDate) };
  }
  
  if (minAmount !== undefined) {
    query.amount = { $gte: minAmount };
  }
  
  if (maxAmount !== undefined) {
    query.amount = { ...query.amount, $lte: maxAmount };
  }
  
  // Build sort
  const sort = {};
  sort[sortBy] = sortOrder === 'desc' ? -1 : 1;
  
  // Pagination
  const skip = (page - 1) * limit;
  
  // Execute query
  const [entries, totalCount] = await Promise.all([
    LedgerEntry.find(query)
      .populate('customerId', 'name phone')
      .populate('createdBy', 'name')
      .sort(sort)
      .skip(skip)
      .limit(limit)
      .lean(),
    LedgerEntry.countDocuments(query),
  ]);
  
  // Calculate summary
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
  
  res.json({
    success: true,
    data: {
      entries,
      pagination: {
        page,
        limit,
        totalCount,
        totalPages: Math.ceil(totalCount / limit),
      },
      summary: summary[0] || {
        totalCredit: 0,
        totalDebit: 0,
        totalTransactions: 0,
      },
    },
  });
});

/**
 * Get ledger entries for a specific customer
 * GET /api/shops/:shopId/customers/:customerId/ledger
 */
const getCustomerLedger = asyncHandler(async (req, res) => {
  const { shopId, customerId } = req.params;
  const { page = 1, limit = 20, startDate, endDate } = req.query;
  
  const customer = await Customer.findOne({ _id: customerId, shopId });
  if (!customer) {
    throw new AppError('Customer not found', 404, 'CUSTOMER_NOT_FOUND');
  }
  
  const query = {
    shopId: new mongoose.Types.ObjectId(shopId),
    customerId: new mongoose.Types.ObjectId(customerId),
    isDeleted: false,
  };
  
  if (startDate) {
    query.createdAt = { $gte: new Date(startDate) };
  }
  
  if (endDate) {
    query.createdAt = { ...query.createdAt, $lte: new Date(endDate) };
  }
  
  const skip = (page - 1) * limit;
  
  const [entries, totalCount] = await Promise.all([
    LedgerEntry.find(query)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit))
      .lean(),
    LedgerEntry.countDocuments(query),
  ]);
  
  res.json({
    success: true,
    data: {
      customer: {
        id: customer._id,
        name: customer.name,
        phone: customer.phone,
        currentBalance: customer.currentBalance,
      },
      entries,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        totalCount,
        totalPages: Math.ceil(totalCount / limit),
      },
    },
  });
});

/**
 * Get a single ledger entry
 * GET /api/shops/:shopId/ledger/:entryId
 */
const getLedgerEntry = asyncHandler(async (req, res) => {
  const { shopId, entryId } = req.params;
  
  const entry = await LedgerEntry.findOne({ _id: entryId, shopId })
    .populate('customerId', 'name phone currentBalance')
    .populate('createdBy', 'name')
    .populate('modifiedBy', 'name')
    .populate('linkedProducts.productId', 'name sellingPrice');
  
  if (!entry) {
    throw new AppError('Ledger entry not found', 404, 'ENTRY_NOT_FOUND');
  }
  
  res.json({
    success: true,
    data: { entry },
  });
});

/**
 * Update a ledger entry (limited fields)
 * PATCH /api/shops/:shopId/ledger/:entryId
 */
const updateLedgerEntry = asyncHandler(async (req, res) => {
  const { shopId, entryId } = req.params;
  
  const entry = await LedgerEntry.findOne({ _id: entryId, shopId });
  
  if (!entry) {
    throw new AppError('Ledger entry not found', 404, 'ENTRY_NOT_FOUND');
  }
  
  if (entry.isDeleted) {
    throw new AppError('Cannot update deleted entry', 400, 'ENTRY_DELETED');
  }
  
  // Only allow updating description/notes
  const allowedUpdates = ['description', 'notes'];
  const updates = {};
  
  allowedUpdates.forEach(field => {
    if (req.body[field] !== undefined) {
      updates[field] = req.body[field];
    }
  });
  
  updates.modifiedBy = req.userId;
  
  const updatedEntry = await LedgerEntry.findByIdAndUpdate(
    entryId,
    updates,
    { new: true }
  ).populate('customerId', 'name phone');
  
  auditLog('LEDGER_ENTRY_UPDATED', req.userId, {
    entryId,
    shopId,
    updates: Object.keys(updates),
  });
  
  res.json({
    success: true,
    message: 'Entry updated successfully',
    data: { entry: updatedEntry },
  });
});

/**
 * Delete a ledger entry (soft delete with balance reversal)
 * DELETE /api/shops/:shopId/ledger/:entryId
 */
const deleteLedgerEntry = asyncHandler(async (req, res) => {
  const { shopId, entryId } = req.params;
  const { reason } = req.body;
  
  const session = await mongoose.startSession();
  session.startTransaction();
  
  try {
    const entry = await LedgerEntry.findOne({ _id: entryId, shopId }).session(session);
    
    if (!entry) {
      throw new AppError('Ledger entry not found', 404, 'ENTRY_NOT_FOUND');
    }
    
    if (entry.isDeleted) {
      throw new AppError('Entry already deleted', 400, 'ALREADY_DELETED');
    }
    
    // Reverse the balance
    const customer = await Customer.findById(entry.customerId).session(session);
    
    if (entry.type === 'credit') {
      customer.currentBalance -= entry.amount;
    } else {
      customer.currentBalance += entry.amount;
    }
    
    await customer.save({ session });
    
    // Soft delete the entry
    entry.isDeleted = true;
    entry.deletedAt = new Date();
    entry.deletedBy = req.userId;
    entry.deletionReason = reason;
    
    await entry.save({ session });
    
    await session.commitTransaction();
    
    auditLog('LEDGER_ENTRY_DELETED', req.userId, {
      entryId,
      shopId,
      reason,
      amount: entry.amount,
      type: entry.type,
    });
    
    res.json({
      success: true,
      message: 'Entry deleted successfully',
      data: {
        reversedAmount: entry.amount,
        newBalance: customer.currentBalance,
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
 * Get ledger summary/dashboard
 * GET /api/shops/:shopId/ledger/summary
 */
const getLedgerSummary = asyncHandler(async (req, res) => {
  const { shopId } = req.params;
  const { startDate, endDate } = req.query;
  
  const dateQuery = {};
  if (startDate) {
    dateQuery.createdAt = { $gte: new Date(startDate) };
  }
  if (endDate) {
    dateQuery.createdAt = { ...dateQuery.createdAt, $lte: new Date(endDate) };
  }
  
  const summary = await LedgerEntry.aggregate([
    {
      $match: {
        shopId: new mongoose.Types.ObjectId(shopId),
        isDeleted: false,
        ...dateQuery,
      },
    },
    {
      $group: {
        _id: null,
        totalCredit: {
          $sum: { $cond: [{ $eq: ['$type', 'credit'] }, '$amount', 0] },
        },
        totalDebit: {
          $sum: { $cond: [{ $eq: ['$type', 'debit'] }, '$amount', 0] },
        },
        creditCount: {
          $sum: { $cond: [{ $eq: ['$type', 'credit'] }, 1, 0] },
        },
        debitCount: {
          $sum: { $cond: [{ $eq: ['$type', 'debit'] }, 1, 0] },
        },
        totalTransactions: { $sum: 1 },
      },
    },
  ]);
  
  // Payment mode breakdown
  const paymentModeBreakdown = await LedgerEntry.aggregate([
    {
      $match: {
        shopId: new mongoose.Types.ObjectId(shopId),
        isDeleted: false,
        type: 'debit',
        ...dateQuery,
      },
    },
    {
      $group: {
        _id: '$paymentMode',
        amount: { $sum: '$amount' },
        count: { $sum: 1 },
      },
    },
  ]);
  
  // Daily trends (last 30 days)
  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
  
  const dailyTrends = await LedgerEntry.aggregate([
    {
      $match: {
        shopId: new mongoose.Types.ObjectId(shopId),
        isDeleted: false,
        createdAt: { $gte: thirtyDaysAgo },
      },
    },
    {
      $group: {
        _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
        credit: {
          $sum: { $cond: [{ $eq: ['$type', 'credit'] }, '$amount', 0] },
        },
        debit: {
          $sum: { $cond: [{ $eq: ['$type', 'debit'] }, '$amount', 0] },
        },
      },
    },
    { $sort: { _id: 1 } },
  ]);
  
  res.json({
    success: true,
    data: {
      summary: summary[0] || {
        totalCredit: 0,
        totalDebit: 0,
        creditCount: 0,
        debitCount: 0,
        totalTransactions: 0,
      },
      paymentModeBreakdown,
      dailyTrends,
    },
  });
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
