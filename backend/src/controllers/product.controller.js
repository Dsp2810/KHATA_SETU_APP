const { asyncHandler } = require('../middleware');
const ProductService = require('../services/product.service');

/**
 * Product Controller — Thin layer delegating to ProductService.
 * Handles HTTP I/O; business logic + sessions live in the service.
 */

/**
 * Create a new product (with optional image upload)
 * POST /api/shops/:shopId/products
 */
const createProduct = asyncHandler(async (req, res) => {
  const { shopId } = req.params;

  let product;
  if (req.file) {
    product = await ProductService.createProductWithImage(shopId, req.body, req.file, req.userId);
  } else {
    product = await ProductService.createProduct(shopId, req.body, req.userId);
  }

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
  const result = await ProductService.getProducts(shopId, req.query);
  res.json({ success: true, data: result });
});

/**
 * Get a single product
 * GET /api/shops/:shopId/products/:productId
 */
const getProduct = asyncHandler(async (req, res) => {
  const { shopId, productId } = req.params;
  const product = await ProductService.getProduct(shopId, productId);
  res.json({ success: true, data: { product } });
});

/**
 * Get product by barcode
 * GET /api/shops/:shopId/products/barcode/:barcode
 */
const getProductByBarcode = asyncHandler(async (req, res) => {
  const { shopId, barcode } = req.params;
  const product = await ProductService.getProductByBarcode(shopId, barcode);
  res.json({ success: true, data: { product } });
});

/**
 * Update a product
 * PATCH /api/shops/:shopId/products/:productId
 */
const updateProduct = asyncHandler(async (req, res) => {
  const { shopId, productId } = req.params;
  const product = await ProductService.updateProduct(shopId, productId, req.body, req.userId);
  res.json({ success: true, message: 'Product updated successfully', data: { product } });
});

/**
 * Delete a product (soft delete)
 * DELETE /api/shops/:shopId/products/:productId
 */
const deleteProduct = asyncHandler(async (req, res) => {
  const { shopId, productId } = req.params;
  await ProductService.deleteProduct(shopId, productId, req.userId);
  res.json({ success: true, message: 'Product deleted successfully' });
});

/**
 * Adjust stock (atomic with session)
 * POST /api/shops/:shopId/products/:productId/stock
 */
const adjustStock = asyncHandler(async (req, res) => {
  const { shopId, productId } = req.params;
  const result = await ProductService.adjustStock(shopId, productId, req.body, req.userId);
  res.status(201).json({ success: true, message: 'Stock adjusted successfully', data: result });
});

/**
 * Get stock history for a product
 * GET /api/shops/:shopId/products/:productId/stock-history
 */
const getStockHistory = asyncHandler(async (req, res) => {
  const { shopId, productId } = req.params;
  const result = await ProductService.getStockHistory(shopId, productId, req.query);
  res.json({ success: true, data: result });
});

/**
 * Get low stock products
 * GET /api/shops/:shopId/products/low-stock
 */
const getLowStockProducts = asyncHandler(async (req, res) => {
  const { shopId } = req.params;
  const result = await ProductService.getLowStockProducts(shopId);
  res.json({ success: true, data: result });
});

/**
 * Get categories
 * GET /api/shops/:shopId/products/categories
 */
const getCategories = asyncHandler(async (req, res) => {
  const { shopId } = req.params;
  const categories = await ProductService.getCategories(shopId);
  res.json({ success: true, data: { categories } });
});

/**
 * Upload product image
 * POST /api/shops/:shopId/products/:productId/image
 */
const uploadProductImage = asyncHandler(async (req, res) => {
  const { shopId, productId } = req.params;

  if (!req.file) {
    return res.status(400).json({
      success: false,
      message: 'No image file provided',
      code: 'NO_FILE',
    });
  }

  const product = await ProductService.addProductImage(shopId, productId, req.file, req.userId);
  res.json({ success: true, message: 'Image uploaded successfully', data: { product } });
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
  uploadProductImage,
};
