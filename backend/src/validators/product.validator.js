const Joi = require('joi');

// Custom validators
const objectIdRegex = /^[0-9a-fA-F]{24}$/;

// Create product schema
const createProductSchema = Joi.object({
  name: Joi.string()
    .trim()
    .min(1)
    .max(200)
    .required()
    .messages({
      'string.empty': 'Product name is required',
      'string.max': 'Product name cannot exceed 200 characters',
    }),
  localName: Joi.string()
    .trim()
    .max(200)
    .allow('')
    .optional(),
  description: Joi.string()
    .max(1000)
    .allow('')
    .optional(),
  category: Joi.string()
    .trim()
    .max(100)
    .allow('')
    .optional(),
  subCategory: Joi.string()
    .trim()
    .max(100)
    .allow('')
    .optional(),
  sku: Joi.string()
    .trim()
    .max(50)
    .allow('')
    .optional(),
  barcode: Joi.string()
    .trim()
    .max(100)
    .allow('')
    .optional(),
  unit: Joi.string()
    .valid('piece', 'kg', 'gram', 'liter', 'ml', 'meter', 'dozen', 'packet', 'box', 'bundle', 'other')
    .default('piece'),
  purchasePrice: Joi.number()
    .min(0)
    .precision(2)
    .required()
    .messages({
      'number.min': 'Purchase price cannot be negative',
      'number.base': 'Purchase price must be a number',
    }),
  sellingPrice: Joi.number()
    .min(0)
    .precision(2)
    .required()
    .messages({
      'number.min': 'Selling price cannot be negative',
      'number.base': 'Selling price must be a number',
    }),
  mrp: Joi.number()
    .min(0)
    .precision(2)
    .optional(),
  taxRate: Joi.number()
    .min(0)
    .max(100)
    .default(0),
  currentStock: Joi.number()
    .min(0)
    .integer()
    .default(0),
  minStockLevel: Joi.number()
    .min(0)
    .integer()
    .default(5),
  maxStockLevel: Joi.number()
    .min(Joi.ref('minStockLevel'))
    .integer()
    .default(1000),
  reorderPoint: Joi.number()
    .min(0)
    .integer()
    .default(10),
  supplier: Joi.object({
    name: Joi.string().max(200).allow(''),
    phone: Joi.string().max(15).allow(''),
    address: Joi.string().max(500).allow(''),
  }).optional(),
  expiryDate: Joi.date()
    .iso()
    .allow(null)
    .optional(),
  tags: Joi.array()
    .items(Joi.string().max(50))
    .max(10)
    .default([]),
});

// Update product schema
const updateProductSchema = Joi.object({
  name: Joi.string()
    .trim()
    .min(1)
    .max(200),
  localName: Joi.string()
    .trim()
    .max(200)
    .allow('', null),
  description: Joi.string()
    .max(1000)
    .allow('', null),
  category: Joi.string()
    .trim()
    .max(100)
    .allow('', null),
  subCategory: Joi.string()
    .trim()
    .max(100)
    .allow('', null),
  sku: Joi.string()
    .trim()
    .max(50)
    .allow('', null),
  barcode: Joi.string()
    .trim()
    .max(100)
    .allow('', null),
  unit: Joi.string()
    .valid('piece', 'kg', 'gram', 'liter', 'ml', 'meter', 'dozen', 'packet', 'box', 'bundle', 'other'),
  purchasePrice: Joi.number()
    .min(0)
    .precision(2),
  sellingPrice: Joi.number()
    .min(0)
    .precision(2),
  mrp: Joi.number()
    .min(0)
    .precision(2)
    .allow(null),
  taxRate: Joi.number()
    .min(0)
    .max(100),
  minStockLevel: Joi.number()
    .min(0)
    .integer(),
  maxStockLevel: Joi.number()
    .integer(),
  reorderPoint: Joi.number()
    .min(0)
    .integer(),
  supplier: Joi.object({
    name: Joi.string().max(200).allow('', null),
    phone: Joi.string().max(15).allow('', null),
    address: Joi.string().max(500).allow('', null),
  }),
  expiryDate: Joi.date()
    .iso()
    .allow(null),
  tags: Joi.array()
    .items(Joi.string().max(50))
    .max(10),
  isActive: Joi.boolean(),
}).min(1).messages({
  'object.min': 'At least one field is required to update',
});

// Stock adjustment schema
const stockAdjustmentSchema = Joi.object({
  type: Joi.string()
    .valid('stock_in', 'stock_out', 'adjustment', 'damage', 'expired')
    .required()
    .messages({
      'any.only': 'Invalid stock adjustment type',
      'string.empty': 'Adjustment type is required',
    }),
  quantity: Joi.number()
    .positive()
    .required()
    .messages({
      'number.positive': 'Quantity must be greater than 0',
    }),
  unitPrice: Joi.number()
    .min(0)
    .optional(),
  notes: Joi.string()
    .max(500)
    .allow('')
    .optional(),
  batchNumber: Joi.string()
    .max(50)
    .allow('')
    .optional(),
  expiryDate: Joi.date()
    .iso()
    .allow(null)
    .optional(),
  supplierName: Joi.string()
    .max(200)
    .allow('')
    .optional(),
});

// Query products schema
const queryProductsSchema = Joi.object({
  search: Joi.string()
    .max(100)
    .optional(),
  category: Joi.string()
    .max(100)
    .optional(),
  isActive: Joi.boolean()
    .optional(),
  isLowStock: Joi.boolean()
    .optional(),
  isOutOfStock: Joi.boolean()
    .optional(),
  minPrice: Joi.number()
    .min(0)
    .optional(),
  maxPrice: Joi.number()
    .optional(),
  tags: Joi.string()
    .optional(),
  sortBy: Joi.string()
    .valid('name', 'sellingPrice', 'currentStock', 'createdAt', 'category')
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

// Product ID param schema
const productIdSchema = Joi.object({
  productId: Joi.string()
    .pattern(objectIdRegex)
    .required()
    .messages({
      'string.pattern.base': 'Invalid product ID format',
    }),
});

// Barcode lookup schema
const barcodeLookupSchema = Joi.object({
  barcode: Joi.string()
    .required()
    .messages({
      'string.empty': 'Barcode is required',
    }),
});

module.exports = {
  createProductSchema,
  updateProductSchema,
  stockAdjustmentSchema,
  queryProductsSchema,
  productIdSchema,
  barcodeLookupSchema,
};
