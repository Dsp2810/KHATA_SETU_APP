const mongoose = require('mongoose');
const { Product, InventoryTransaction } = require('../models');
const { AppError } = require('../middleware');
const { logger, auditLog } = require('../utils');

/**
 * ProductService — Encapsulates all product/inventory business logic.
 * Uses MongoDB sessions for stock adjustments.
 */
class ProductService {
  /**
   * Create a product with initial stock entry (atomic).
   */
  static async createProduct(shopId, productData, userId) {
    const session = await mongoose.startSession();
    session.startTransaction();

    const txnId = new mongoose.Types.ObjectId().toString().slice(-8);
    logger.info(`[TXN:${txnId}] ── CREATE PRODUCT ──`);
    logger.info(`[TXN:${txnId}] Shop: ${shopId}, Name: ${productData.name}`);

    try {
      const product = new Product({
        ...productData,
        shopId,
      });
      await product.save({ session });

      // Create initial stock entry if stock > 0
      if (product.currentStock > 0) {
        const invTxn = new InventoryTransaction({
          shopId,
          productId: product._id,
          type: 'stock_in',
          quantity: product.currentStock,
          previousStock: 0,
          newStock: product.currentStock,
          unitPrice: product.purchasePrice,
          totalValue: product.currentStock * product.purchasePrice,
          referenceType: 'manual',
          notes: 'Initial stock on product creation',
          createdBy: userId,
        });

        // Skip pre-save stock update since we're managing manually
        invTxn._skipStockUpdate = true;
        await invTxn.save({ session });

        logger.info(`[TXN:${txnId}] Initial stock: ${product.currentStock} units`);
      }

      await session.commitTransaction();
      logger.info(`[TXN:${txnId}] ✅ Product created: ${product._id}`);

      auditLog('PRODUCT_CREATED', userId, {
        txnId,
        productId: product._id,
        shopId,
        name: product.name,
        initialStock: product.currentStock,
      });

      return product;
    } catch (error) {
      await session.abortTransaction();
      logger.error(`[TXN:${txnId}] ❌ ABORTED: ${error.message}`);
      throw error;
    } finally {
      session.endSession();
    }
  }

  /**
   * Get products with filtering, pagination, and summary.
   */
  static async getProducts(shopId, filters = {}) {
    const {
      search,
      category,
      isActive,
      isLowStock,
      isOutOfStock,
      minPrice,
      maxPrice,
      tags,
      sortBy = 'name',
      sortOrder = 'asc',
      page = 1,
      limit = 20,
    } = filters;

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

    if (minPrice !== undefined || maxPrice !== undefined) {
      query.sellingPrice = {};
      if (minPrice !== undefined) query.sellingPrice.$gte = Number(minPrice);
      if (maxPrice !== undefined) query.sellingPrice.$lte = Number(maxPrice);
    }

    if (tags) {
      const tagArray = tags.split(',').map(t => t.trim());
      query.tags = { $in: tagArray };
    }

    const sort = { [sortBy]: sortOrder === 'desc' ? -1 : 1 };
    const skip = (Number(page) - 1) * Number(limit);

    logger.debug(`[PRODUCT] getProducts query: ${JSON.stringify(query)}`);

    const [products, totalCount, summary] = await Promise.all([
      Product.find(query)
        .sort(sort)
        .skip(skip)
        .limit(Number(limit))
        .lean(),
      Product.countDocuments(query),
      Product.aggregate([
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
      ]),
    ]);

    return {
      products,
      pagination: {
        page: Number(page),
        limit: Number(limit),
        totalCount,
        totalPages: Math.ceil(totalCount / Number(limit)),
      },
      summary: summary[0] || {
        totalProducts: 0,
        totalStockValue: 0,
        lowStockCount: 0,
        outOfStockCount: 0,
      },
    };
  }

  /**
   * Get a single product by ID.
   */
  static async getProduct(shopId, productId) {
    const product = await Product.findOne({ _id: productId, shopId });
    if (!product) {
      throw new AppError('Product not found', 404, 'PRODUCT_NOT_FOUND');
    }
    return product;
  }

  /**
   * Get product by barcode.
   */
  static async getProductByBarcode(shopId, barcode) {
    const product = await Product.findOne({ shopId, barcode, isActive: true });
    if (!product) {
      throw new AppError('Product not found', 404, 'PRODUCT_NOT_FOUND');
    }
    return product;
  }

  /**
   * Update a product (excludes direct stock updates).
   */
  static async updateProduct(shopId, productId, updates, userId) {
    // Don't allow direct stock updates through this method
    delete updates.currentStock;

    const product = await Product.findOneAndUpdate(
      { _id: productId, shopId },
      updates,
      { new: true, runValidators: true }
    );

    if (!product) {
      throw new AppError('Product not found', 404, 'PRODUCT_NOT_FOUND');
    }

    auditLog('PRODUCT_UPDATED', userId, {
      productId,
      shopId,
      updates: Object.keys(updates),
    });

    return product;
  }

  /**
   * Delete a product (soft delete).
   */
  static async deleteProduct(shopId, productId, userId) {
    const product = await Product.findOneAndUpdate(
      { _id: productId, shopId },
      { isActive: false },
      { new: true }
    );

    if (!product) {
      throw new AppError('Product not found', 404, 'PRODUCT_NOT_FOUND');
    }

    auditLog('PRODUCT_DELETED', userId, { productId, shopId });
    return product;
  }

  /**
   * Adjust stock with atomic MongoDB session.
   */
  static async adjustStock(shopId, productId, adjustmentData, userId) {
    const session = await mongoose.startSession();
    session.startTransaction();

    const txnId = new mongoose.Types.ObjectId().toString().slice(-8);
    logger.info(`[TXN:${txnId}] ── STOCK ADJUSTMENT ──`);

    try {
      const product = await Product.findOne({ _id: productId, shopId }).session(session);

      if (!product) {
        throw new AppError('Product not found', 404, 'PRODUCT_NOT_FOUND');
      }

      const { type, quantity, unitPrice, notes, batchNumber, expiryDate, supplierName } = adjustmentData;
      const previousStock = product.currentStock;

      logger.info(`[TXN:${txnId}] Product: ${product.name}, Type: ${type}, Qty: ${quantity}`);
      logger.info(`[TXN:${txnId}] Stock BEFORE: ${previousStock}`);

      // Calculate new stock
      let newStock;
      switch (type) {
        case 'stock_in':
        case 'return':
          newStock = previousStock + quantity;
          break;
        case 'stock_out':
        case 'sale':
        case 'damage':
        case 'expired':
          if (previousStock < quantity) {
            throw new AppError(
              `Insufficient stock. Available: ${previousStock}, Requested: ${quantity}`,
              400,
              'INSUFFICIENT_STOCK'
            );
          }
          newStock = previousStock - quantity;
          break;
        case 'adjustment':
          newStock = quantity; // Direct set
          break;
        default:
          throw new AppError(`Invalid stock adjustment type: ${type}`, 400, 'INVALID_TYPE');
      }

      // Update product stock
      product.currentStock = newStock;
      if (type === 'stock_in') {
        product.lastRestockedAt = new Date();
      }
      await product.save({ session });

      // Create inventory transaction
      const invTxn = new InventoryTransaction({
        shopId,
        productId,
        type,
        quantity,
        previousStock,
        newStock,
        unitPrice: unitPrice || product.purchasePrice,
        totalValue: quantity * (unitPrice || product.purchasePrice),
        referenceType: 'manual',
        notes,
        batchNumber,
        expiryDate,
        supplierName,
        createdBy: userId,
      });

      invTxn._skipStockUpdate = true;
      await invTxn.save({ session });

      logger.info(`[TXN:${txnId}] Stock AFTER: ${newStock}`);

      await session.commitTransaction();
      logger.info(`[TXN:${txnId}] ✅ Stock adjustment COMMITTED`);

      auditLog('STOCK_ADJUSTED', userId, {
        txnId,
        productId,
        shopId,
        type,
        quantity,
        previousStock,
        newStock,
      });

      return {
        transaction: invTxn,
        product: {
          id: product._id,
          name: product.name,
          previousStock,
          newStock,
        },
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
   * Get stock history for a product.
   */
  static async getStockHistory(shopId, productId, filters = {}) {
    const { page = 1, limit = 20 } = filters;
    const skip = (Number(page) - 1) * Number(limit);

    const [transactions, totalCount] = await Promise.all([
      InventoryTransaction.find({ shopId, productId })
        .populate('createdBy', 'name')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(Number(limit))
        .lean(),
      InventoryTransaction.countDocuments({ shopId, productId }),
    ]);

    return {
      transactions,
      pagination: {
        page: Number(page),
        limit: Number(limit),
        totalCount,
        totalPages: Math.ceil(totalCount / Number(limit)),
      },
    };
  }

  /**
   * Get low stock products.
   */
  static async getLowStockProducts(shopId) {
    const products = await Product.find({
      shopId,
      isActive: true,
      $expr: { $lte: ['$currentStock', '$minStockLevel'] },
    })
      .select('name localName currentStock minStockLevel reorderPoint category images')
      .sort({ currentStock: 1 })
      .lean();

    return { products, count: products.length };
  }

  /**
   * Get categories.
   */
  static async getCategories(shopId) {
    const categories = await Product.aggregate([
      { $match: { shopId: new mongoose.Types.ObjectId(shopId), isActive: true } },
      { $group: { _id: '$category', count: { $sum: 1 } } },
      { $match: { _id: { $ne: null, $ne: '' } } },
      { $sort: { count: -1 } },
    ]);

    return categories.map(c => ({ name: c._id, count: c.count }));
  }

  /**
   * Handle product image upload.
   * Stores the image path/URL on the product.
   */
  static async addProductImage(shopId, productId, imageFile, userId) {
    const product = await Product.findOne({ _id: productId, shopId });
    if (!product) {
      throw new AppError('Product not found', 404, 'PRODUCT_NOT_FOUND');
    }

    const imageEntry = {
      url: `/uploads/products/${imageFile.filename}`,
      isPrimary: product.images.length === 0, // First image is primary
      uploadedAt: new Date(),
    };

    product.images.push(imageEntry);
    await product.save();

    logger.info(`[PRODUCT] Image added: ${imageFile.filename} for product ${productId}`);

    auditLog('PRODUCT_IMAGE_ADDED', userId, {
      productId,
      shopId,
      filename: imageFile.filename,
    });

    return product;
  }

  /**
   * Create product with image in one step.
   * Handles the case where image is uploaded as part of product creation.
   */
  static async createProductWithImage(shopId, productData, imageFile, userId) {
    if (imageFile) {
      productData.images = [{
        url: `/uploads/products/${imageFile.filename}`,
        isPrimary: true,
        uploadedAt: new Date(),
      }];
    }

    return ProductService.createProduct(shopId, productData, userId);
  }
}

module.exports = ProductService;
