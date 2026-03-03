const express = require('express');
const router = express.Router({ mergeParams: true });
const { reportController } = require('../controllers');
const {
  authenticate,
  authorizeShopAccess,
  requirePermission,
  reportLimiter,
} = require('../middleware');

// All routes require authentication and shop access
router.use(authenticate);
router.use(authorizeShopAccess);

// Dashboard
router.get(
  '/dashboard',
  requirePermission('view_reports'),
  reportController.getDashboard
);

// Reports
router.get(
  '/ledger',
  requirePermission('view_reports'),
  reportLimiter,
  reportController.getLedgerReport
);

router.get(
  '/inventory',
  requirePermission('view_reports'),
  reportLimiter,
  reportController.getInventoryReport
);

router.get(
  '/customers',
  requirePermission('view_reports'),
  reportLimiter,
  reportController.getCustomerReport
);

// Export
router.get(
  '/export/:type',
  requirePermission('export_data'),
  reportLimiter,
  reportController.exportReport
);

module.exports = router;
