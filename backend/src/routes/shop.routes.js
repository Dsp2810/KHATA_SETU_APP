const express = require('express');
const router = express.Router();
const { shopController } = require('../controllers');
const {
  authenticate,
  authorizeShopAccess,
  requirePermission,
  validate,
  validateObjectId,
} = require('../middleware');

// All routes require authentication
router.use(authenticate);

// Shop CRUD
router.post('/', shopController.createShop);
router.get('/', shopController.getShops);

// Shop-specific routes - require shop access
router.get(
  '/:shopId',
  validateObjectId('shopId'),
  authorizeShopAccess,
  shopController.getShop
);

router.patch(
  '/:shopId',
  validateObjectId('shopId'),
  authorizeShopAccess,
  requirePermission('manage_shop'),
  shopController.updateShop
);

router.delete(
  '/:shopId',
  validateObjectId('shopId'),
  authorizeShopAccess,
  shopController.deleteShop
);

// Employee management
router.get(
  '/:shopId/employees',
  validateObjectId('shopId'),
  authorizeShopAccess,
  requirePermission('manage_employees'),
  shopController.getEmployees
);

router.post(
  '/:shopId/employees',
  validateObjectId('shopId'),
  authorizeShopAccess,
  requirePermission('manage_employees'),
  shopController.addEmployee
);

router.patch(
  '/:shopId/employees/:employeeId',
  validateObjectId('shopId', 'employeeId'),
  authorizeShopAccess,
  requirePermission('manage_employees'),
  shopController.updateEmployee
);

router.delete(
  '/:shopId/employees/:employeeId',
  validateObjectId('shopId', 'employeeId'),
  authorizeShopAccess,
  requirePermission('manage_employees'),
  shopController.removeEmployee
);

// Shop settings
router.patch(
  '/:shopId/settings',
  validateObjectId('shopId'),
  authorizeShopAccess,
  requirePermission('manage_shop'),
  shopController.updateSettings
);

module.exports = router;
