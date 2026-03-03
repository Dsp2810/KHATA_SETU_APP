const express = require('express');
const router = express.Router({ mergeParams: true }); // Access shopId from parent
const { customerController } = require('../controllers');
const {
  authenticate,
  authorizeShopAccess,
  requirePermission,
  validate,
  validateObjectId,
} = require('../middleware');
const {
  createCustomerSchema,
  updateCustomerSchema,
  queryCustomersSchema,
} = require('../validators');

// All routes require authentication and shop access
router.use(authenticate);
router.use(authorizeShopAccess);

// Customer routes
router.post(
  '/',
  requirePermission('manage_customers'),
  validate(createCustomerSchema),
  customerController.createCustomer
);

router.get(
  '/',
  requirePermission('view_customers'),
  validate(queryCustomersSchema, 'query'),
  customerController.getCustomers
);

router.get(
  '/search',
  requirePermission('view_customers'),
  customerController.searchCustomers
);

router.get(
  '/:customerId',
  requirePermission('view_customers'),
  validateObjectId('customerId'),
  customerController.getCustomer
);

router.get(
  '/:customerId/stats',
  requirePermission('view_customers'),
  validateObjectId('customerId'),
  customerController.getCustomerStats
);

router.patch(
  '/:customerId',
  requirePermission('manage_customers'),
  validateObjectId('customerId'),
  validate(updateCustomerSchema),
  customerController.updateCustomer
);

router.delete(
  '/:customerId',
  requirePermission('manage_customers'),
  validateObjectId('customerId'),
  customerController.deleteCustomer
);

module.exports = router;
