const { LedgerEntry, Customer, Product, InventoryTransaction } = require('../models');
const { asyncHandler } = require('../middleware');
const mongoose = require('mongoose');

/**
 * Get dashboard summary
 * GET /api/shops/:shopId/reports/dashboard
 */
const getDashboard = asyncHandler(async (req, res) => {
  const { shopId } = req.params;
  const shopObjectId = new mongoose.Types.ObjectId(shopId);
  
  const today = new Date();
  const startOfToday = new Date(today.setHours(0, 0, 0, 0));
  const endOfToday = new Date(today.setHours(23, 59, 59, 999));
  
  // Customer stats
  const customerStats = await Customer.aggregate([
    { $match: { shopId: shopObjectId } },
    {
      $group: {
        _id: null,
        totalCustomers: { $sum: 1 },
        activeCustomers: { $sum: { $cond: ['$isActive', 1, 0] } },
        totalOwing: {
          $sum: { $cond: [{ $gt: ['$currentBalance', 0] }, '$currentBalance', 0] },
        },
        totalOwed: {
          $sum: { $cond: [{ $lt: ['$currentBalance', 0] }, { $abs: '$currentBalance' }, 0] },
        },
        customersWithBalance: {
          $sum: { $cond: [{ $ne: ['$currentBalance', 0] }, 1, 0] },
        },
      },
    },
  ]);
  
  // Today's transactions
  const todayTransactions = await LedgerEntry.aggregate([
    {
      $match: {
        shopId: shopObjectId,
        isDeleted: false,
        createdAt: { $gte: startOfToday, $lte: endOfToday },
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
        transactionCount: { $sum: 1 },
      },
    },
  ]);
  
  // Inventory stats
  const inventoryStats = await Product.aggregate([
    { $match: { shopId: shopObjectId, isActive: true } },
    {
      $group: {
        _id: null,
        totalProducts: { $sum: 1 },
        totalStockValue: { $sum: { $multiply: ['$currentStock', '$purchasePrice'] } },
        lowStockCount: {
          $sum: { $cond: [{ $lte: ['$currentStock', '$minStockLevel'] }, 1, 0] },
        },
        outOfStockCount: {
          $sum: { $cond: [{ $eq: ['$currentStock', 0] }, 1, 0] },
        },
      },
    },
  ]);
  
  // Recent transactions
  const recentTransactions = await LedgerEntry.find({
    shopId,
    isDeleted: false,
  })
    .populate('customerId', 'name')
    .sort({ createdAt: -1 })
    .limit(5)
    .lean();
  
  // Top customers by balance
  const topCustomersByBalance = await Customer.find({
    shopId,
    isActive: true,
    currentBalance: { $gt: 0 },
  })
    .select('name phone currentBalance')
    .sort({ currentBalance: -1 })
    .limit(5)
    .lean();
  
  res.json({
    success: true,
    data: {
      customers: customerStats[0] || {
        totalCustomers: 0,
        activeCustomers: 0,
        totalOwing: 0,
        totalOwed: 0,
        customersWithBalance: 0,
      },
      today: todayTransactions[0] || {
        totalCredit: 0,
        totalDebit: 0,
        transactionCount: 0,
      },
      inventory: inventoryStats[0] || {
        totalProducts: 0,
        totalStockValue: 0,
        lowStockCount: 0,
        outOfStockCount: 0,
      },
      recentTransactions,
      topCustomersByBalance,
    },
  });
});

/**
 * Get detailed ledger report
 * GET /api/shops/:shopId/reports/ledger
 */
const getLedgerReport = asyncHandler(async (req, res) => {
  const { shopId } = req.params;
  const { startDate, endDate, groupBy = 'day' } = req.query;
  
  const matchQuery = {
    shopId: new mongoose.Types.ObjectId(shopId),
    isDeleted: false,
  };
  
  if (startDate) {
    matchQuery.createdAt = { $gte: new Date(startDate) };
  }
  if (endDate) {
    matchQuery.createdAt = { ...matchQuery.createdAt, $lte: new Date(endDate) };
  }
  
  let dateFormat;
  switch (groupBy) {
    case 'month':
      dateFormat = '%Y-%m';
      break;
    case 'week':
      dateFormat = '%Y-W%V';
      break;
    default:
      dateFormat = '%Y-%m-%d';
  }
  
  const report = await LedgerEntry.aggregate([
    { $match: matchQuery },
    {
      $group: {
        _id: { $dateToString: { format: dateFormat, date: '$createdAt' } },
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
      },
    },
    { $sort: { _id: 1 } },
  ]);
  
  // Payment mode breakdown
  const paymentModes = await LedgerEntry.aggregate([
    { $match: { ...matchQuery, type: 'debit' } },
    {
      $group: {
        _id: '$paymentMode',
        total: { $sum: '$amount' },
        count: { $sum: 1 },
      },
    },
    { $sort: { total: -1 } },
  ]);
  
  // Summary
  const summary = await LedgerEntry.aggregate([
    { $match: matchQuery },
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
      report,
      paymentModes,
      summary: summary[0] || {
        totalCredit: 0,
        totalDebit: 0,
        totalTransactions: 0,
      },
    },
  });
});

/**
 * Get inventory report
 * GET /api/shops/:shopId/reports/inventory
 */
const getInventoryReport = asyncHandler(async (req, res) => {
  const { shopId } = req.params;
  const { startDate, endDate } = req.query;
  
  const shopObjectId = new mongoose.Types.ObjectId(shopId);
  
  // Category breakdown
  const categoryBreakdown = await Product.aggregate([
    { $match: { shopId: shopObjectId, isActive: true } },
    {
      $group: {
        _id: '$category',
        productCount: { $sum: 1 },
        totalStock: { $sum: '$currentStock' },
        stockValue: { $sum: { $multiply: ['$currentStock', '$purchasePrice'] } },
        sellingValue: { $sum: { $multiply: ['$currentStock', '$sellingPrice'] } },
      },
    },
    { $sort: { stockValue: -1 } },
  ]);
  
  // Stock movement
  const movementQuery = {
    shopId: shopObjectId,
  };
  
  if (startDate) {
    movementQuery.createdAt = { $gte: new Date(startDate) };
  }
  if (endDate) {
    movementQuery.createdAt = { ...movementQuery.createdAt, $lte: new Date(endDate) };
  }
  
  const stockMovement = await InventoryTransaction.aggregate([
    { $match: movementQuery },
    {
      $group: {
        _id: '$type',
        totalQuantity: { $sum: '$quantity' },
        totalValue: { $sum: '$totalValue' },
        count: { $sum: 1 },
      },
    },
  ]);
  
  // Top selling products (by stock_out and sale)
  const topMoving = await InventoryTransaction.aggregate([
    {
      $match: {
        shopId: shopObjectId,
        type: { $in: ['stock_out', 'sale'] },
        ...movementQuery,
      },
    },
    {
      $group: {
        _id: '$productId',
        totalQuantity: { $sum: '$quantity' },
        totalValue: { $sum: '$totalValue' },
      },
    },
    { $sort: { totalQuantity: -1 } },
    { $limit: 10 },
    {
      $lookup: {
        from: 'products',
        localField: '_id',
        foreignField: '_id',
        as: 'product',
      },
    },
    { $unwind: '$product' },
    {
      $project: {
        name: '$product.name',
        totalQuantity: 1,
        totalValue: 1,
      },
    },
  ]);
  
  // Overall summary
  const summary = {
    totalCategories: categoryBreakdown.length,
    totalProducts: categoryBreakdown.reduce((sum, c) => sum + c.productCount, 0),
    totalStockValue: categoryBreakdown.reduce((sum, c) => sum + c.stockValue, 0),
    potentialRevenue: categoryBreakdown.reduce((sum, c) => sum + c.sellingValue, 0),
  };
  
  res.json({
    success: true,
    data: {
      categoryBreakdown,
      stockMovement,
      topMoving,
      summary,
    },
  });
});

/**
 * Get customer report
 * GET /api/shops/:shopId/reports/customers
 */
const getCustomerReport = asyncHandler(async (req, res) => {
  const { shopId } = req.params;
  const shopObjectId = new mongoose.Types.ObjectId(shopId);
  
  // Balance distribution
  const balanceDistribution = await Customer.aggregate([
    { $match: { shopId: shopObjectId, isActive: true } },
    {
      $bucket: {
        groupBy: '$currentBalance',
        boundaries: [0, 500, 2000, 5000, 10000, 50000, Infinity],
        default: 'Other',
        output: {
          count: { $sum: 1 },
          totalBalance: { $sum: '$currentBalance' },
        },
      },
    },
  ]);
  
  // Trust score distribution
  const trustDistribution = await Customer.aggregate([
    { $match: { shopId: shopObjectId, isActive: true } },
    {
      $bucket: {
        groupBy: '$trustScore',
        boundaries: [0, 30, 50, 70, 90, 101],
        default: 'Unknown',
        output: {
          count: { $sum: 1 },
        },
      },
    },
  ]);
  
  // New customers this month
  const startOfMonth = new Date();
  startOfMonth.setDate(1);
  startOfMonth.setHours(0, 0, 0, 0);
  
  const newCustomersThisMonth = await Customer.countDocuments({
    shopId,
    createdAt: { $gte: startOfMonth },
  });
  
  // Inactive customers (no transactions in 30 days)
  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
  
  const inactiveCustomers = await Customer.countDocuments({
    shopId,
    isActive: true,
    $or: [
      { lastTransactionAt: null },
      { lastTransactionAt: { $lt: thirtyDaysAgo } },
    ],
  });
  
  // Top customers by total transactions
  const topByTransactions = await LedgerEntry.aggregate([
    { $match: { shopId: shopObjectId, isDeleted: false } },
    {
      $group: {
        _id: '$customerId',
        totalAmount: { $sum: '$amount' },
        transactionCount: { $sum: 1 },
      },
    },
    { $sort: { totalAmount: -1 } },
    { $limit: 10 },
    {
      $lookup: {
        from: 'customers',
        localField: '_id',
        foreignField: '_id',
        as: 'customer',
      },
    },
    { $unwind: '$customer' },
    {
      $project: {
        name: '$customer.name',
        phone: '$customer.phone',
        currentBalance: '$customer.currentBalance',
        totalAmount: 1,
        transactionCount: 1,
      },
    },
  ]);
  
  res.json({
    success: true,
    data: {
      balanceDistribution,
      trustDistribution,
      newCustomersThisMonth,
      inactiveCustomers,
      topByTransactions,
    },
  });
});

/**
 * Export report to CSV/Excel
 * GET /api/shops/:shopId/reports/export/:type
 */
const exportReport = asyncHandler(async (req, res) => {
  const { shopId, type } = req.params;
  const { startDate, endDate, format = 'csv' } = req.query;
  
  // This would generate actual file - for now just return data
  let data;
  
  switch (type) {
    case 'ledger':
      data = await LedgerEntry.find({
        shopId,
        isDeleted: false,
        ...(startDate && { createdAt: { $gte: new Date(startDate) } }),
        ...(endDate && { createdAt: { $lte: new Date(endDate) } }),
      })
        .populate('customerId', 'name phone')
        .sort({ createdAt: -1 })
        .lean();
      break;
      
    case 'customers':
      data = await Customer.find({ shopId, isActive: true })
        .sort({ name: 1 })
        .lean();
      break;
      
    case 'products':
      data = await Product.find({ shopId, isActive: true })
        .sort({ name: 1 })
        .lean();
      break;
      
    default:
      throw new Error('Invalid report type');
  }
  
  // In production, convert to CSV/Excel and send file
  res.json({
    success: true,
    message: 'Export generated successfully',
    data: {
      type,
      format,
      recordCount: data.length,
      // In production: downloadUrl
    },
  });
});

module.exports = {
  getDashboard,
  getLedgerReport,
  getInventoryReport,
  getCustomerReport,
  exportReport,
};
