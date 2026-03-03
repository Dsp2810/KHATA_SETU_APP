const Joi = require('joi');

// Custom validators
const phoneRegex = /^[6-9]\d{9}$/;
const objectIdRegex = /^[0-9a-fA-F]{24}$/;

// Create customer schema
const createCustomerSchema = Joi.object({
  name: Joi.string()
    .trim()
    .min(2)
    .max(100)
    .required()
    .messages({
      'string.empty': 'Customer name is required',
      'string.min': 'Name must be at least 2 characters',
      'string.max': 'Name cannot exceed 100 characters',
    }),
  phone: Joi.string()
    .pattern(phoneRegex)
    .required()
    .messages({
      'string.pattern.base': 'Please enter a valid 10-digit phone number',
      'string.empty': 'Phone number is required',
    }),
  email: Joi.string()
    .email()
    .allow('')
    .optional(),
  address: Joi.string()
    .max(500)
    .allow('')
    .optional(),
  creditLimit: Joi.number()
    .min(0)
    .default(0)
    .messages({
      'number.min': 'Credit limit cannot be negative',
    }),
  tags: Joi.array()
    .items(Joi.string().max(50))
    .max(10)
    .default([]),
  notes: Joi.string()
    .max(1000)
    .allow('')
    .optional(),
});

// Update customer schema
const updateCustomerSchema = Joi.object({
  name: Joi.string()
    .trim()
    .min(2)
    .max(100)
    .messages({
      'string.min': 'Name must be at least 2 characters',
      'string.max': 'Name cannot exceed 100 characters',
    }),
  phone: Joi.string()
    .pattern(phoneRegex)
    .messages({
      'string.pattern.base': 'Please enter a valid 10-digit phone number',
    }),
  email: Joi.string()
    .email()
    .allow('', null),
  address: Joi.string()
    .max(500)
    .allow('', null),
  creditLimit: Joi.number()
    .min(0)
    .messages({
      'number.min': 'Credit limit cannot be negative',
    }),
  trustScore: Joi.number()
    .min(0)
    .max(100),
  tags: Joi.array()
    .items(Joi.string().max(50))
    .max(10),
  notes: Joi.string()
    .max(1000)
    .allow('', null),
  isActive: Joi.boolean(),
}).min(1).messages({
  'object.min': 'At least one field is required to update',
});

// Query customers schema
const queryCustomersSchema = Joi.object({
  search: Joi.string()
    .max(100)
    .optional(),
  isActive: Joi.boolean()
    .optional(),
  hasBalance: Joi.string()
    .valid('owing', 'owed', 'settled', 'any')
    .default('any'),
  minBalance: Joi.number()
    .optional(),
  maxBalance: Joi.number()
    .optional(),
  tags: Joi.string()
    .optional(),
  sortBy: Joi.string()
    .valid('name', 'currentBalance', 'lastTransactionAt', 'createdAt', 'trustScore')
    .default('name'),
  sortOrder: Joi.string()
    .valid('asc', 'desc')
    .default('asc'),
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

// Customer ID param schema
const customerIdSchema = Joi.object({
  customerId: Joi.string()
    .pattern(objectIdRegex)
    .required()
    .messages({
      'string.pattern.base': 'Invalid customer ID format',
    }),
});

module.exports = {
  createCustomerSchema,
  updateCustomerSchema,
  queryCustomersSchema,
  customerIdSchema,
};
