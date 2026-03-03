const Joi = require('joi');

// Custom validators
const objectIdRegex = /^[0-9a-fA-F]{24}$/;

// ───────────────────────────────────────────────
// Reusable sub-schemas
// ───────────────────────────────────────────────

const structuredItemSchema = Joi.object({
  productId: Joi.string()
    .pattern(objectIdRegex)
    .allow(null)
    .optional()
    .messages({
      'string.pattern.base': 'Invalid product ID format',
    }),
  productName: Joi.string()
    .trim()
    .max(200)
    .allow('')
    .optional(),
  quantity: Joi.number()
    .min(0.01)
    .precision(3)
    .required()
    .messages({
      'number.min': 'Quantity must be greater than 0',
      'number.base': 'Quantity must be a number',
      'any.required': 'Quantity is required for each item',
    }),
  unit: Joi.string()
    .valid('piece', 'kg', 'gram', 'liter', 'ml', 'meter', 'dozen', 'packet', 'box', 'bundle', 'other')
    .default('piece'),
  unitPrice: Joi.number()
    .min(0)
    .precision(2)
    .required()
    .messages({
      'number.min': 'Unit price cannot be negative',
      'number.base': 'Unit price must be a number',
      'any.required': 'Unit price is required for each item',
    }),
  total: Joi.number()
    .min(0)
    .optional(), // Auto-calculated server-side
});

// ───────────────────────────────────────────────
// CREATE NOTE
// ───────────────────────────────────────────────

const createNoteSchema = Joi.object({
  title: Joi.string()
    .trim()
    .min(1)
    .max(300)
    .required()
    .messages({
      'string.empty': 'Note title is required',
      'string.min': 'Title must be at least 1 character',
      'string.max': 'Title cannot exceed 300 characters',
      'any.required': 'Title is required',
    }),
  description: Joi.string()
    .trim()
    .max(5000)
    .allow('', null)
    .optional(),
  customerId: Joi.string()
    .pattern(objectIdRegex)
    .allow(null)
    .optional()
    .messages({
      'string.pattern.base': 'Invalid customer ID format',
    }),
  structuredItems: Joi.array()
    .items(structuredItemSchema)
    .max(50)
    .default([])
    .messages({
      'array.max': 'Cannot have more than 50 items per note',
    }),
  priority: Joi.string()
    .valid('low', 'medium', 'high')
    .default('medium')
    .messages({
      'any.only': 'Priority must be low, medium, or high',
    }),
  status: Joi.string()
    .valid('pending', 'completed', 'cancelled')
    .default('pending')
    .messages({
      'any.only': 'Status must be pending, completed, or cancelled',
    }),
  noteDate: Joi.date()
    .iso()
    .default(() => {
      const now = new Date();
      now.setHours(0, 0, 0, 0);
      return now;
    })
    .messages({
      'date.base': 'Invalid date format for noteDate',
    }),
  reminderAt: Joi.date()
    .iso()
    .allow(null)
    .optional()
    .messages({
      'date.base': 'Invalid date format for reminderAt',
    }),
  tags: Joi.array()
    .items(Joi.string().trim().max(50))
    .max(20)
    .default([])
    .messages({
      'array.max': 'Cannot have more than 20 tags',
    }),

  // Offline sync support
  offlineId: Joi.string()
    .max(100)
    .allow(null, '')
    .optional(),
  isOfflineEntry: Joi.boolean()
    .default(false),
});

// ───────────────────────────────────────────────
// UPDATE NOTE
// ───────────────────────────────────────────────

const updateNoteSchema = Joi.object({
  title: Joi.string()
    .trim()
    .min(1)
    .max(300)
    .messages({
      'string.empty': 'Title cannot be empty',
      'string.max': 'Title cannot exceed 300 characters',
    }),
  description: Joi.string()
    .trim()
    .max(5000)
    .allow('', null),
  customerId: Joi.string()
    .pattern(objectIdRegex)
    .allow(null)
    .messages({
      'string.pattern.base': 'Invalid customer ID format',
    }),
  structuredItems: Joi.array()
    .items(structuredItemSchema)
    .max(50),
  priority: Joi.string()
    .valid('low', 'medium', 'high')
    .messages({
      'any.only': 'Priority must be low, medium, or high',
    }),
  status: Joi.string()
    .valid('pending', 'completed', 'cancelled')
    .messages({
      'any.only': 'Status must be pending, completed, or cancelled',
    }),
  noteDate: Joi.date()
    .iso(),
  reminderAt: Joi.date()
    .iso()
    .allow(null),
  tags: Joi.array()
    .items(Joi.string().trim().max(50))
    .max(20),
}).min(1).messages({
  'object.min': 'At least one field is required to update',
});

// ───────────────────────────────────────────────
// QUERY NOTES
// ───────────────────────────────────────────────

const queryNotesSchema = Joi.object({
  customerId: Joi.string()
    .pattern(objectIdRegex)
    .optional(),
  status: Joi.string()
    .valid('pending', 'completed', 'cancelled')
    .optional(),
  priority: Joi.string()
    .valid('low', 'medium', 'high')
    .optional(),
  tag: Joi.string()
    .trim()
    .max(50)
    .optional(),
  startDate: Joi.date()
    .iso()
    .optional(),
  endDate: Joi.date()
    .iso()
    .min(Joi.ref('startDate'))
    .optional(),
  search: Joi.string()
    .trim()
    .max(200)
    .optional(),
  sortBy: Joi.string()
    .valid('noteDate', 'priority', 'createdAt', 'status', 'totalAmount')
    .default('noteDate'),
  sortOrder: Joi.string()
    .valid('asc', 'desc')
    .default('desc'),
  page: Joi.number()
    .integer()
    .min(1)
    .default(1),
  limit: Joi.number()
    .integer()
    .min(1)
    .max(100)
    .default(20),
});

// ───────────────────────────────────────────────
// BULK OPERATIONS
// ───────────────────────────────────────────────

const bulkCompleteSchema = Joi.object({
  noteIds: Joi.array()
    .items(
      Joi.string()
        .pattern(objectIdRegex)
        .messages({ 'string.pattern.base': 'Invalid note ID format' })
    )
    .min(1)
    .max(100)
    .required()
    .messages({
      'array.min': 'At least one note ID is required',
      'array.max': 'Cannot bulk-complete more than 100 notes at once',
      'any.required': 'noteIds array is required',
    }),
});

const bulkDeleteSchema = Joi.object({
  noteIds: Joi.array()
    .items(
      Joi.string()
        .pattern(objectIdRegex)
        .messages({ 'string.pattern.base': 'Invalid note ID format' })
    )
    .min(1)
    .max(100)
    .required()
    .messages({
      'array.min': 'At least one note ID is required',
      'array.max': 'Cannot bulk-delete more than 100 notes at once',
      'any.required': 'noteIds array is required',
    }),
  reason: Joi.string()
    .trim()
    .max(500)
    .allow('', null)
    .optional(),
});

module.exports = {
  createNoteSchema,
  updateNoteSchema,
  queryNotesSchema,
  bulkCompleteSchema,
  bulkDeleteSchema,
};
