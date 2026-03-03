const express = require('express');
const router = express.Router({ mergeParams: true });
const { reminderController } = require('../controllers');
const {
  authenticate,
  authorizeShopAccess,
  requirePermission,
  validate,
  validateObjectId,
} = require('../middleware');
const {
  createReminderSchema,
  updateReminderSchema,
  snoozeReminderSchema,
  queryRemindersSchema,
  bulkCreateRemindersSchema,
} = require('../validators');

// All routes require authentication and shop access
router.use(authenticate);
router.use(authorizeShopAccess);

// Reminder routes
router.post(
  '/',
  requirePermission('manage_reminders'),
  validate(createReminderSchema),
  reminderController.createReminder
);

router.post(
  '/bulk',
  requirePermission('manage_reminders'),
  validate(bulkCreateRemindersSchema),
  reminderController.bulkCreateReminders
);

router.get(
  '/',
  requirePermission('view_reminders'),
  validate(queryRemindersSchema, 'query'),
  reminderController.getReminders
);

router.get(
  '/today',
  requirePermission('view_reminders'),
  reminderController.getTodayReminders
);

router.get(
  '/:reminderId',
  requirePermission('view_reminders'),
  validateObjectId('reminderId'),
  reminderController.getReminder
);

router.patch(
  '/:reminderId',
  requirePermission('manage_reminders'),
  validateObjectId('reminderId'),
  validate(updateReminderSchema),
  reminderController.updateReminder
);

router.delete(
  '/:reminderId',
  requirePermission('manage_reminders'),
  validateObjectId('reminderId'),
  reminderController.deleteReminder
);

// Reminder actions
router.post(
  '/:reminderId/acknowledge',
  requirePermission('manage_reminders'),
  validateObjectId('reminderId'),
  reminderController.acknowledgeReminder
);

router.post(
  '/:reminderId/snooze',
  requirePermission('manage_reminders'),
  validateObjectId('reminderId'),
  validate(snoozeReminderSchema),
  reminderController.snoozeReminder
);

router.post(
  '/:reminderId/cancel',
  requirePermission('manage_reminders'),
  validateObjectId('reminderId'),
  reminderController.cancelReminder
);

module.exports = router;
