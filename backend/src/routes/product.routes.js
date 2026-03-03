const express = require('express');
const router = express.Router({ mergeParams: true });
const { productController } = require('../controllers');
const {
  authenticate,
  authorizeShopAccess,
  requirePermission,
  validate,
  validateObjectId,
} = require('../middleware');
const {
  createProductSchema,
  updateProductSchema,
  stockAdjustmentSchema,
  queryProductsSchema,
} = require('../validators');

// All routes require authentication and shop access
router.use(authenticate);
router.use(authorizeShopAccess);

// Product routes
router.post(
  '/',
  requirePermission('manage_inventory'),
  validate(createProductSchema),
  productController.createProduct
);

router.get(
  '/',
  requirePermission('view_inventory'),
  validate(queryProductsSchema, 'query'),
  productController.getProducts
);

router.get(
  '/categories',
  requirePermission('view_inventory'),
  productController.getCategories
);

router.get(
  '/low-stock',
  requirePermission('view_inventory'),
  productController.getLowStockProducts
);

router.get(
  '/barcode/:barcode',
  requirePermission('view_inventory'),
  productController.getProductByBarcode
);

router.get(
  '/:productId',
  requirePermission('view_inventory'),
  validateObjectId('productId'),
  productController.getProduct
);

router.patch(
  '/:productId',
  requirePermission('manage_inventory'),
  validateObjectId('productId'),
  validate(updateProductSchema),
  productController.updateProduct
);

router.delete(
  '/:productId',
  requirePermission('manage_inventory'),
  validateObjectId('productId'),
  productController.deleteProduct
);

// Stock management
router.post(
  '/:productId/stock',
  requirePermission('manage_inventory'),
  validateObjectId('productId'),
  validate(stockAdjustmentSchema),
  productController.adjustStock
);

router.get(
  '/:productId/stock-history',
  requirePermission('view_inventory'),
  validateObjectId('productId'),
  productController.getStockHistory
);

module.exports = router;
