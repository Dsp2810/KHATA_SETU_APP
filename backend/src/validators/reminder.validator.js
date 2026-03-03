const Joi = require('joi');

// Custom validators  
const objectIdRegex = /^[0-9a-fA-F]{24}$/;

// Create reminder schema
const createReminderSchema = Joi.object({
  customerId: Joi.string()
    .pattern(objectIdRegex)
    .required()
    .messages({
      'string.pattern.base': 'Invalid customer ID format',
      'string.empty': 'Customer ID is required',
    }),
  type: Joi.string()
    .valid('payment_due', 'follow_up', 'custom')
    .required()
    .messages({
      'any.only': 'Invalid reminder type',
      'string.empty': 'Reminder type is required',
    }),
  title: Joi.string()
    .trim()
    .min(1)
    .max(200)
    .required()
    .messages({
      'string.empty': 'Reminder title is required',
      'string.max': 'Title cannot exceed 200 characters',
    }),
  message: Joi.string()
    .max(1000)
    .allow('')
    .optional(),
  amount: Joi.number()
    .min(0)
    .precision(2)
    .allow(null)
    .optional(),
  scheduledAt: Joi.date()
    .iso()
    .min('now')
    .required()
    .messages({
      'date.min': 'Scheduled time must be in the future',
      'date.base': 'Invalid date format',
    }),
  reminderChannels: Joi.array()
    .items(Joi.string().valid('push', 'sms', 'whatsapp', 'call'))
    .min(1)
    .default(['push']),
  recurrence: Joi.string()
    .valid('none', 'daily', 'weekly', 'monthly')
    .default('none'),
  recurrenceEndDate: Joi.date()
    .iso()
    .min(Joi.ref('scheduledAt'))
    .when('recurrence', {
      is: Joi.not('none'),
      then: Joi.optional(),
      otherwise: Joi.forbidden(),
    }),
  priority: Joi.string()
    .valid('low', 'medium', 'high')
    .default('medium'),
});

// Update reminder schema
const updateReminderSchema = Joi.object({
  title: Joi.string()
    .trim()
    .min(1)
    .max(200),
  message: Joi.string()
    .max(1000)
    .allow('', null),
  amount: Joi.number()
    .min(0)
    .precision(2)
    .allow(null),
  scheduledAt: Joi.date()
    .iso()
    .min('now'),
  reminderChannels: Joi.array()
    .items(Joi.string().valid('push', 'sms', 'whatsapp', 'call'))
    .min(1),
  recurrence: Joi.string()
    .valid('none', 'daily', 'weekly', 'monthly'),
  recurrenceEndDate: Joi.date()
    .iso()
    .allow(null),
  priority: Joi.string()
    .valid('low', 'medium', 'high'),
}).min(1).messages({
  'object.min': 'At least one field is required to update',
});

// Snooze reminder schema
const snoozeReminderSchema = Joi.object({
  snoozeUntil: Joi.date()
    .iso()
    .min('now')
    .required()
    .messages({
      'date.min': 'Snooze time must be in the future',
      'date.base': 'Invalid date format',
    }),
});

// Query reminders schema
const queryRemindersSchema = Joi.object({
  customerId: Joi.string()
    .pattern(objectIdRegex)
    .optional(),
  type: Joi.string()
    .valid('payment_due', 'follow_up', 'custom')
    .optional(),
  status: Joi.string()
    .valid('pending', 'sent', 'acknowledged', 'snoozed', 'cancelled')
    .optional(),
  priority: Joi.string()
    .valid('low', 'medium', 'high')
    .optional(),
  startDate: Joi.date()
    .iso()
    .optional(),
  endDate: Joi.date()
    .iso()
    .min(Joi.ref('startDate'))
    .optional(),
  isOverdue: Joi.boolean()
    .optional(),
  sortBy: Joi.string()
    .valid('scheduledAt', 'priority', 'createdAt', 'status')
    .default('scheduledAt'),
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

// Reminder ID param schema
const reminderIdSchema = Joi.object({
  reminderId: Joi.string()
    .pattern(objectIdRegex)
    .required()
    .messages({
      'string.pattern.base': 'Invalid reminder ID format',
    }),
});

// Bulk create reminders schema
const bulkCreateRemindersSchema = Joi.object({
  customerIds: Joi.array()
    .items(Joi.string().pattern(objectIdRegex))
    .min(1)
    .max(100)
    .required()
    .messages({
      'array.min': 'At least one customer ID is required',
      'array.max': 'Cannot create reminders for more than 100 customers at once',
    }),
  type: Joi.string()
    .valid('payment_due', 'follow_up', 'custom')
    .required(),
  title: Joi.string()
    .trim()
    .min(1)
    .max(200)
    .required(),
  message: Joi.string()
    .max(1000)
    .allow('')
    .optional(),
  scheduledAt: Joi.date()
    .iso()
    .min('now')
    .required(),
  reminderChannels: Joi.array()
    .items(Joi.string().valid('push', 'sms', 'whatsapp', 'call'))
    .min(1)
    .default(['push']),
  priority: Joi.string()
    .valid('low', 'medium', 'high')
    .default('medium'),
});

module.exports = {
  createReminderSchema,
  updateReminderSchema,
  snoozeReminderSchema,
  queryRemindersSchema,
  reminderIdSchema,
  bulkCreateRemindersSchema,
};
