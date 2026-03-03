const { Product, InventoryTransaction } = require('../models');
const { asyncHandler, AppError } = require('../middleware');
const { auditLog } = require('../utils');
const mongoose = require('mongoose');

/**
 * Create a new product
 * POST /api/shops/:shopId/products
 */
const createProduct = asyncHandler(async (req, res) => {
  const { shopId } = req.params;
  const productData = {
    ...req.body,
    shopId,
  };
  
  const product = await Product.create(productData);
  
  // Create initial stock entry if stock > 0
  if (product.currentStock > 0) {
    await InventoryTransaction.create({
      shopId,
      productId: product._id,
      type: 'stock_in',
      quantity: product.currentStock,
      previousStock: 0,
      newStock: product.currentStock,
      unitPrice: product.purchasePrice,
      totalValue: product.currentStock * product.purchasePrice,
      referenceType: 'manual',
      notes: 'Initial stock',
      createdBy: req.userId,
    });
  }
  
  auditLog('PRODUCT_CREATED', req.userId, {
    productId: product._id,
    shopId,
  });
  
  res.status(201).json({
    success: true,
    message: 'Product created successfully',
    data: { product },
  });
});

/**
 * Get all products for a shop
 * GET /api/shops/:shopId/products
 */
const getProducts = asyncHandler(async (req, res) => {
  const { shopId } = req.params;
  const {
    search,
    category,
    isActive,
    isLowStock,
    isOutOfStock,
    minPrice,
    maxPrice,
    tags,
    sortBy,
    sortOrder,
    page,
    limit,
  } = req.query;
  
  // Build query
  const query = { shopId: new mongoose.Types.ObjectId(shopId) };
  
  if (typeof isActive === 'boolean') {
    query.isActive = isActive;
  }
  
  if (search) {
    query.$or = [
      { name: { $regex: search, $options: 'i' } },
      { localName: { $regex: search, $options: 'i' } },
      { barcode: { $regex: search, $options: 'i' } },
      { sku: { $regex: search, $options: 'i' } },
    ];
  }
  
  if (category) {
    query.category = { $regex: category, $options: 'i' };
  }
  
  if (isLowStock) {
    query.$expr = { $lte: ['$currentStock', '$minStockLevel'] };
  }
  
  if (isOutOfStock) {
    query.currentStock = 0;
  }
  
  if (minPrice !== undefined) {
    query.sellingPrice = { $gte: minPrice };
  }
  
  if (maxPrice !== undefined) {
    query.sellingPrice = { ...query.sellingPrice, $lte: maxPrice };
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
  const [products, totalCount] = await Promise.all([
    Product.find(query)
      .sort(sort)
      .skip(skip)
      .limit(limit)
      .lean(),
    Product.countDocuments(query),
  ]);
  
  // Calculate summary
  const summary = await Product.aggregate([
    { $match: { shopId: new mongoose.Types.ObjectId(shopId), isActive: true } },
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
  
  res.json({
    success: true,
    data: {
      products,
      pagination: {
        page,
        limit,
        totalCount,
        totalPages: Math.ceil(totalCount / limit),
      },
      summary: summary[0] || {
        totalProducts: 0,
        totalStockValue: 0,
        lowStockCount: 0,
        outOfStockCount: 0,
      },
    },
  });
});

/**
 * Get a single product
 * GET /api/shops/:shopId/products/:productId
 */
const getProduct = asyncHandler(async (req, res) => {
  const { shopId, productId } = req.params;
  
  const product = await Product.findOne({
    _id: productId,
    shopId,
  });
  
  if (!product) {
    throw new AppError('Product not found', 404, 'PRODUCT_NOT_FOUND');
  }
  
  res.json({
    success: true,
    data: { product },
  });
});

/**
 * Get product by barcode
 * GET /api/shops/:shopId/products/barcode/:barcode
 */
const getProductByBarcode = asyncHandler(async (req, res) => {
  const { shopId, barcode } = req.params;
  
  const product = await Product.findOne({
    shopId,
    barcode,
    isActive: true,
  });
  
  if (!product) {
    throw new AppError('Product not found', 404, 'PRODUCT_NOT_FOUND');
  }
  
  res.json({
    success: true,
    data: { product },
  });
});

/**
 * Update a product
 * PATCH /api/shops/:shopId/products/:productId
 */
const updateProduct = asyncHandler(async (req, res) => {
  const { shopId, productId } = req.params;
  
  // Don't allow direct stock updates through this endpoint
  delete req.body.currentStock;
  
  const product = await Product.findOneAndUpdate(
    { _id: productId, shopId },
    req.body,
    { new: true, runValidators: true }
  );
  
  if (!product) {
    throw new AppError('Product not found', 404, 'PRODUCT_NOT_FOUND');
  }
  
  auditLog('PRODUCT_UPDATED', req.userId, {
    productId,
    shopId,
    updates: Object.keys(req.body),
  });
  
  res.json({
    success: true,
    message: 'Product updated successfully',
    data: { product },
  });
});

/**
 * Delete a product (soft delete)
 * DELETE /api/shops/:shopId/products/:productId
 */
const deleteProduct = asyncHandler(async (req, res) => {
  const { shopId, productId } = req.params;
  
  const product = await Product.findOneAndUpdate(
    { _id: productId, shopId },
    { isActive: false },
    { new: true }
  );
  
  if (!product) {
    throw new AppError('Product not found', 404, 'PRODUCT_NOT_FOUND');
  }
  
  auditLog('PRODUCT_DELETED', req.userId, { productId, shopId });
  
  res.json({
    success: true,
    message: 'Product deleted successfully',
  });
});

/**
 * Adjust stock
 * POST /api/shops/:shopId/products/:productId/stock
 */
const adjustStock = asyncHandler(async (req, res) => {
  const { shopId, productId } = req.params;
  const { type, quantity, unitPrice, notes, batchNumber, expiryDate, supplierName } = req.body;
  
  const product = await Product.findOne({ _id: productId, shopId });
  
  if (!product) {
    throw new AppError('Product not found', 404, 'PRODUCT_NOT_FOUND');
  }
  
  const transaction = await InventoryTransaction.create({
    shopId,
    productId,
    type,
    quantity,
    previousStock: product.currentStock,
    newStock: product.currentStock, // Will be updated in pre-save
    unitPrice: unitPrice || product.purchasePrice,
    totalValue: quantity * (unitPrice || product.purchasePrice),
    referenceType: 'manual',
    notes,
    batchNumber,
    expiryDate,
    supplierName,
    createdBy: req.userId,
  });
  
  // Reload product to get updated stock
  const updatedProduct = await Product.findById(productId);
  
  auditLog('STOCK_ADJUSTED', req.userId, {
    productId,
    shopId,
    type,
    quantity,
    newStock: transaction.newStock,
  });
  
  res.status(201).json({
    success: true,
    message: 'Stock adjusted successfully',
    data: {
      transaction,
      product: {
        id: product._id,
        name: product.name,
        previousStock: transaction.previousStock,
        newStock: transaction.newStock,
      },
    },
  });
});

/**
 * Get stock history for a product
 * GET /api/shops/:shopId/products/:productId/stock-history
 */
const getStockHistory = asyncHandler(async (req, res) => {
  const { shopId, productId } = req.params;
  const { page = 1, limit = 20 } = req.query;
  
  const skip = (page - 1) * limit;
  
  const [transactions, totalCount] = await Promise.all([
    InventoryTransaction.find({ shopId, productId })
      .populate('createdBy', 'name')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit))
      .lean(),
    InventoryTransaction.countDocuments({ shopId, productId }),
  ]);
  
  res.json({
    success: true,
    data: {
      transactions,
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
 * Get low stock products
 * GET /api/shops/:shopId/products/low-stock
 */
const getLowStockProducts = asyncHandler(async (req, res) => {
  const { shopId } = req.params;
  
  const products = await Product.find({
    shopId,
    isActive: true,
    $expr: { $lte: ['$currentStock', '$minStockLevel'] },
  })
    .select('name localName currentStock minStockLevel reorderPoint category')
    .sort({ currentStock: 1 })
    .lean();
  
  res.json({
    success: true,
    data: {
      products,
      count: products.length,
    },
  });
});

/**
 * Get categories
 * GET /api/shops/:shopId/products/categories
 */
const getCategories = asyncHandler(async (req, res) => {
  const { shopId } = req.params;
  
  const categories = await Product.aggregate([
    { $match: { shopId: new mongoose.Types.ObjectId(shopId), isActive: true } },
    { $group: { _id: '$category', count: { $sum: 1 } } },
    { $match: { _id: { $ne: null, $ne: '' } } },
    { $sort: { count: -1 } },
  ]);
  
  res.json({
    success: true,
    data: {
      categories: categories.map(c => ({
        name: c._id,
        count: c.count,
      })),
    },
  });
});

module.exports = {
  createProduct,
  getProducts,
  getProduct,
  getProductByBarcode,
  updateProduct,
  deleteProduct,
  adjustStock,
  getStockHistory,
  getLowStockProducts,
  getCategories,
};
