const express = require('express');
const router = express.Router({ mergeParams: true }); // Access shopId from parent
const { noteController } = require('../controllers');
const {
  authenticate,
  authorizeShopAccess,
  requirePermission,
  validate,
  validateObjectId,
} = require('../middleware');
const {
  createNoteSchema,
  updateNoteSchema,
  queryNotesSchema,
  bulkCompleteSchema,
  bulkDeleteSchema,
} = require('../validators');

// All routes require authentication and shop access
router.use(authenticate);
router.use(authorizeShopAccess);

// ───────────────────────────────────────────────
// Bulk operations (declared BEFORE /:noteId to avoid route conflicts)
// ───────────────────────────────────────────────

router.post(
  '/bulk-complete',
  requirePermission('manage_notes'),
  validate(bulkCompleteSchema),
  noteController.bulkComplete
);

router.post(
  '/bulk-delete',
  requirePermission('manage_notes'),
  validate(bulkDeleteSchema),
  noteController.bulkDelete
);

// ───────────────────────────────────────────────
// Special views (declared BEFORE /:noteId)
// ───────────────────────────────────────────────

router.get(
  '/today',
  requirePermission('view_notes'),
  noteController.getTodayNotes
);

router.get(
  '/summary',
  requirePermission('view_notes'),
  noteController.getNoteSummary
);

// ───────────────────────────────────────────────
// CRUD routes
// ───────────────────────────────────────────────

router.post(
  '/',
  requirePermission('manage_notes'),
  validate(createNoteSchema),
  noteController.createNote
);

router.get(
  '/',
  requirePermission('view_notes'),
  validate(queryNotesSchema, 'query'),
  noteController.getNotes
);

router.get(
  '/:noteId',
  requirePermission('view_notes'),
  validateObjectId('noteId'),
  noteController.getNote
);

router.patch(
  '/:noteId',
  requirePermission('manage_notes'),
  validateObjectId('noteId'),
  validate(updateNoteSchema),
  noteController.updateNote
);

router.delete(
  '/:noteId',
  requirePermission('manage_notes'),
  validateObjectId('noteId'),
  noteController.deleteNote
);

// ───────────────────────────────────────────────
// Actions on a single note
// ───────────────────────────────────────────────

router.post(
  '/:noteId/complete',
  requirePermission('manage_notes'),
  validateObjectId('noteId'),
  noteController.completeNote
);

module.exports = router;
