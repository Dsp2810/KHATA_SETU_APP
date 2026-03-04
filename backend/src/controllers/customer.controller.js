const { Customer, LedgerEntry } = require('../models');
const { asyncHandler, AppError } = require('../middleware');
const { auditLog } = require('../utils');
const mongoose = require('mongoose');

/**
 * Create a new customer
 * POST /api/shops/:shopId/customers
 */
const createCustomer = asyncHandler(async (req, res) => {
  const { shopId } = req.params;
  const customerData = {
    ...req.body,
    shopId,
  };
  
  const customer = await Customer.create(customerData);
  
  auditLog('CUSTOMER_CREATED', req.userId, {
    customerId: customer._id,
    shopId,
  });
  
  res.status(201).json({
    success: true,
    message: 'Customer created successfully',
    data: { customer },
  });
});

/**
 * Get all customers for a shop
 * GET /api/shops/:shopId/customers
 */
const getCustomers = asyncHandler(async (req, res) => {
  const { shopId } = req.params;
  const {
    search,
    isActive,
    hasBalance,
    minBalance,
    maxBalance,
    tags,
    sortBy,
    sortOrder,
    page,
    limit,
  } = req.query;
  
  // Build query — default to active customers only
  const query = { shopId };
  
  if (isActive !== undefined) {
    // Query params are strings; convert to boolean
    query.isActive = isActive === 'true' || isActive === true;
  } else {
    // By default only show active customers
    query.isActive = true;
  }
  
  if (search) {
    query.$or = [
      { name: { $regex: search, $options: 'i' } },
      { phone: { $regex: search, $options: 'i' } },
    ];
  }
  
  if (hasBalance && hasBalance !== 'any') {
    if (hasBalance === 'owing') {
      query.currentBalance = { $gt: 0 };
    } else if (hasBalance === 'owed') {
      query.currentBalance = { $lt: 0 };
    } else if (hasBalance === 'settled') {
      query.currentBalance = 0;
    }
  }
  
  if (minBalance !== undefined) {
    query.currentBalance = { ...query.currentBalance, $gte: minBalance };
  }
  
  if (maxBalance !== undefined) {
    query.currentBalance = { ...query.currentBalance, $lte: maxBalance };
  }
  
  if (tags) {
    const tagArray = tags.split(',').map(t => t.trim());
    query.tags = { $in: tagArray };
  }
  
  // Build sort
  const sort = {};
  sort[sortBy] = sortOrder === 'desc' ? -1 : 1;
  
  // Pagination
  const skip = (page - 1) * limit;
  
  // Execute query
  const [customers, totalCount] = await Promise.all([
    Customer.find(query)
      .sort(sort)
      .skip(skip)
      .limit(limit)
      .lean(),
    Customer.countDocuments(query),
  ]);
  
  // Calculate summary
  const summary = await Customer.aggregate([
    { $match: { shopId: new mongoose.Types.ObjectId(shopId) } },
    {
      $group: {
        _id: null,
        totalCustomers: { $sum: 1 },
        activeCustomers: {
          $sum: { $cond: ['$isActive', 1, 0] },
        },
        totalOwing: {
          $sum: { $cond: [{ $gt: ['$currentBalance', 0] }, '$currentBalance', 0] },
        },
        totalOwed: {
          $sum: { $cond: [{ $lt: ['$currentBalance', 0] }, { $abs: '$currentBalance' }, 0] },
        },
      },
    },
  ]);
  
  res.json({
    success: true,
    data: {
      customers,
      pagination: {
        page,
        limit,
        totalCount,
        totalPages: Math.ceil(totalCount / limit),
      },
      summary: summary[0] || {
        totalCustomers: 0,
        activeCustomers: 0,
        totalOwing: 0,
        totalOwed: 0,
      },
    },
  });
});

/**
 * Get a single customer
 * GET /api/shops/:shopId/customers/:customerId
 */
const getCustomer = asyncHandler(async (req, res) => {
  const { shopId, customerId } = req.params;
  
  const customer = await Customer.findOne({
    _id: customerId,
    shopId,
  });
  
  if (!customer) {
    throw new AppError('Customer not found', 404, 'CUSTOMER_NOT_FOUND');
  }
  
  res.json({
    success: true,
    data: { customer },
  });
});

/**
 * Update a customer (whitelisted fields only)
 * PATCH /api/shops/:shopId/customers/:customerId
 */
const updateCustomer = asyncHandler(async (req, res) => {
  const { shopId, customerId } = req.params;
  
  // Only allow safe fields — prevent injection of currentBalance, trustScore, etc.
  const allowedFields = ['name', 'phone', 'email', 'address', 'creditLimit', 'avatar', 'tags', 'notes'];
  const updates = {};
  allowedFields.forEach(field => {
    if (req.body[field] !== undefined) {
      updates[field] = req.body[field];
    }
  });
  
  const customer = await Customer.findOneAndUpdate(
    { _id: customerId, shopId },
    updates,
    { new: true, runValidators: true }
  );
  
  if (!customer) {
    throw new AppError('Customer not found', 404, 'CUSTOMER_NOT_FOUND');
  }
  
  auditLog('CUSTOMER_UPDATED', req.userId, {
    customerId,
    shopId,
    updates: Object.keys(req.body),
  });
  
  res.json({
    success: true,
    message: 'Customer updated successfully',
    data: { customer },
  });
});

/**
 * Delete a customer (soft delete with cascade)
 * DELETE /api/shops/:shopId/customers/:customerId
 */
const deleteCustomer = asyncHandler(async (req, res) => {
  const { shopId, customerId } = req.params;
  
  const session = await mongoose.startSession();
  session.startTransaction();
  
  try {
    const customer = await Customer.findOne({ _id: customerId, shopId }).session(session);
    
    if (!customer) {
      throw new AppError('Customer not found', 404, 'CUSTOMER_NOT_FOUND');
    }
    
    // Float-safe zero check (tolerance of ₹0.01)
    if (Math.abs(customer.currentBalance) > 0.01) {
      throw new AppError(
        'Cannot delete customer with outstanding balance',
        400,
        'BALANCE_EXISTS'
      );
    }
    
    // Soft-delete the customer
    customer.isActive = false;
    await customer.save({ session });
    
    // Cascade: soft-delete all associated ledger entries
    await LedgerEntry.updateMany(
      { customerId: customer._id, shopId, isDeleted: false },
      {
        $set: {
          isDeleted: true,
          deletedAt: new Date(),
          deletedBy: req.userId,
          deletionReason: 'Customer deleted',
        },
      },
      { session }
    );
    
    await session.commitTransaction();
    
    auditLog('CUSTOMER_DELETED', req.userId, { customerId, shopId });
    
    res.json({
      success: true,
      message: 'Customer deleted successfully',
    });
  } catch (error) {
    await session.abortTransaction();
    throw error;
  } finally {
    session.endSession();
  }
});

/**
 * Get customer statistics
 * GET /api/shops/:shopId/customers/:customerId/stats
 */
const getCustomerStats = asyncHandler(async (req, res) => {
  const { shopId, customerId } = req.params;
  const { LedgerEntry } = require('../models');
  
  const customer = await Customer.findOne({ _id: customerId, shopId });
  
  if (!customer) {
    throw new AppError('Customer not found', 404, 'CUSTOMER_NOT_FOUND');
  }
  
  // Get transaction statistics
  const stats = await LedgerEntry.aggregate([
    { $match: { customerId: new mongoose.Types.ObjectId(customerId), isDeleted: false } },
    {
      $group: {
        _id: null,
        totalTransactions: { $sum: 1 },
        totalCredit: {
          $sum: { $cond: [{ $eq: ['$type', 'credit'] }, '$amount', 0] },
        },
        totalDebit: {
          $sum: { $cond: [{ $eq: ['$type', 'debit'] }, '$amount', 0] },
        },
        avgTransactionAmount: { $avg: '$amount' },
        lastTransaction: { $max: '$createdAt' },
        firstTransaction: { $min: '$createdAt' },
      },
    },
  ]);
  
  // Get monthly trends (last 6 months)
  const sixMonthsAgo = new Date();
  sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);
  
  const monthlyTrends = await LedgerEntry.aggregate([
    {
      $match: {
        customerId: new mongoose.Types.ObjectId(customerId),
        isDeleted: false,
        createdAt: { $gte: sixMonthsAgo },
      },
    },
    {
      $group: {
        _id: {
          year: { $year: '$createdAt' },
          month: { $month: '$createdAt' },
        },
        credit: {
          $sum: { $cond: [{ $eq: ['$type', 'credit'] }, '$amount', 0] },
        },
        debit: {
          $sum: { $cond: [{ $eq: ['$type', 'debit'] }, '$amount', 0] },
        },
        transactionCount: { $sum: 1 },
      },
    },
    { $sort: { '_id.year': 1, '_id.month': 1 } },
  ]);
  
  res.json({
    success: true,
    data: {
      customer: {
        id: customer._id,
        name: customer.name,
        currentBalance: customer.currentBalance,
        trustScore: customer.trustScore,
        creditLimit: customer.creditLimit,
      },
      stats: stats[0] || {
        totalTransactions: 0,
        totalCredit: 0,
        totalDebit: 0,
        avgTransactionAmount: 0,
      },
      monthlyTrends,
    },
  });
});

/**
 * Search customers
 * GET /api/shops/:shopId/customers/search
 */
const searchCustomers = asyncHandler(async (req, res) => {
  const { shopId } = req.params;
  const { q, limit = 10 } = req.query;
  
  if (!q || q.length < 2) {
    return res.json({
      success: true,
      data: { customers: [] },
    });
  }
  
  const customers = await Customer.find({
    shopId,
    isActive: true,
    $or: [
      { name: { $regex: q, $options: 'i' } },
      { phone: { $regex: q, $options: 'i' } },
    ],
  })
    .select('name phone currentBalance avatar')
    .limit(parseInt(limit))
    .lean();
  
  res.json({
    success: true,
    data: { customers },
  });
});

module.exports = {
  createCustomer,
  getCustomers,
  getCustomer,
  updateCustomer,
  deleteCustomer,
  getCustomerStats,
  searchCustomers,
};
