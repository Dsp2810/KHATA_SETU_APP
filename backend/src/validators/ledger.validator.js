const Joi = require('joi');

// Custom validators
const objectIdRegex = /^[0-9a-fA-F]{24}$/;

// Create ledger entry schema
const createLedgerEntrySchema = Joi.object({
  customerId: Joi.string()
    .pattern(objectIdRegex)
    .required()
    .messages({
      'string.pattern.base': 'Invalid customer ID format',
      'string.empty': 'Customer ID is required',
    }),
  type: Joi.string()
    .valid('credit', 'debit')
    .required()
    .messages({
      'any.only': 'Type must be credit or debit',
      'string.empty': 'Transaction type is required',
    }),
  amount: Joi.number()
    .positive()
    .precision(2)
    .required()
    .messages({
      'number.positive': 'Amount must be greater than 0',
      'number.base': 'Amount must be a number',
    }),
  description: Joi.string()
    .max(500)
    .allow('')
    .optional(),
  paymentMode: Joi.string()
    .valid('cash', 'upi', 'card', 'bank_transfer', 'cheque', 'other')
    .default('cash'),
  upiTransactionId: Joi.string()
    .max(100)
    .allow('')
    .optional()
    .when('paymentMode', {
      is: 'upi',
      then: Joi.string().optional(),
    }),
  linkedProducts: Joi.array()
    .items(
      Joi.object({
        productId: Joi.string().pattern(objectIdRegex).required(),
        quantity: Joi.number().positive().required(),
        pricePerUnit: Joi.number().min(0).required(),
      })
    )
    .max(50)
    .optional(),
  isOfflineEntry: Joi.boolean()
    .default(false),
  offlineId: Joi.string()
    .when('isOfflineEntry', {
      is: true,
      then: Joi.string().required(),
      otherwise: Joi.string().optional(),
    }),
});

// Update ledger entry schema (limited updates allowed)
const updateLedgerEntrySchema = Joi.object({
  description: Joi.string()
    .max(500)
    .allow(''),
  notes: Joi.string()
    .max(500)
    .allow(''),
}).min(1).messages({
  'object.min': 'At least one field is required to update',
});

// Delete ledger entry schema
const deleteLedgerEntrySchema = Joi.object({
  reason: Joi.string()
    .max(500)
    .required()
    .messages({
      'string.empty': 'Deletion reason is required',
    }),
});

// Query ledger entries schema
const queryLedgerEntriesSchema = Joi.object({
  customerId: Joi.string()
    .pattern(objectIdRegex)
    .optional(),
  type: Joi.string()
    .valid('credit', 'debit')
    .optional(),
  paymentMode: Joi.string()
    .valid('cash', 'upi', 'card', 'bank_transfer', 'cheque', 'other')
    .optional(),
  startDate: Joi.date()
    .iso()
    .optional(),
  endDate: Joi.date()
    .iso()
    .min(Joi.ref('startDate'))
    .optional(),
  minAmount: Joi.number()
    .min(0)
    .optional(),
  maxAmount: Joi.number()
    .min(Joi.ref('minAmount'))
    .optional(),
  includeDeleted: Joi.boolean()
    .default(false),
  sortBy: Joi.string()
    .valid('createdAt', 'amount', 'type')
    .default('createdAt'),
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

// Ledger entry ID param schema
const ledgerEntryIdSchema = Joi.object({
  entryId: Joi.string()
    .pattern(objectIdRegex)
    .required()
    .messages({
      'string.pattern.base': 'Invalid entry ID format',
    }),
});

// Bulk create ledger entries schema (for offline sync)
const bulkCreateLedgerEntriesSchema = Joi.object({
  entries: Joi.array()
    .items(createLedgerEntrySchema)
    .min(1)
    .max(100)
    .required()
    .messages({
      'array.min': 'At least one entry is required',
      'array.max': 'Cannot create more than 100 entries at once',
    }),
});

module.exports = {
  createLedgerEntrySchema,
  updateLedgerEntrySchema,
  deleteLedgerEntrySchema,
  queryLedgerEntriesSchema,
  ledgerEntryIdSchema,
  bulkCreateLedgerEntriesSchema,
};
