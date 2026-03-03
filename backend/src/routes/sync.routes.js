const express = require('express');
const router = express.Router({ mergeParams: true });
const { syncController } = require('../controllers');
const {
  authenticate,
  authorizeShopAccess,
  syncLimiter,
} = require('../middleware');

// All routes require authentication and shop access
router.use(authenticate);
router.use(authorizeShopAccess);

// Sync routes
router.post(
  '/',
  syncLimiter,
  syncController.syncData
);

router.get(
  '/changes',
  syncController.getChanges
);

router.get(
  '/status',
  syncController.getSyncStatus
);

router.post(
  '/resolve',
  syncController.resolveConflict
);

module.exports = router;
