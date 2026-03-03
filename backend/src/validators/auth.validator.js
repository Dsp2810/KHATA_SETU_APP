const Joi = require('joi');

// Custom validators
const phoneRegex = /^[6-9]\d{9}$/;
const pinRegex = /^\d{6}$/;

// Register schema
const registerSchema = Joi.object({
  name: Joi.string()
    .trim()
    .min(2)
    .max(100)
    .required()
    .messages({
      'string.empty': 'Name is required',
      'string.min': 'Name must be at least 2 characters',
      'string.max': 'Name cannot exceed 100 characters',
    }),
  phone: Joi.string()
    .pattern(phoneRegex)
    .required()
    .messages({
      'string.pattern.base': 'Please enter a valid 10-digit Indian phone number',
      'string.empty': 'Phone number is required',
    }),
  password: Joi.string()
    .min(8)
    .max(128)
    .required()
    .messages({
      'string.empty': 'Password is required',
      'string.min': 'Password must be at least 8 characters',
      'string.max': 'Password cannot exceed 128 characters',
    }),
  shopName: Joi.string()
    .trim()
    .min(2)
    .max(200)
    .required()
    .messages({
      'string.empty': 'Shop name is required',
      'string.min': 'Shop name must be at least 2 characters',
      'string.max': 'Shop name cannot exceed 200 characters',
    }),
  language: Joi.string()
    .valid('en', 'hi', 'gu')
    .default('en'),
});

// Login schema
const loginSchema = Joi.object({
  phone: Joi.string()
    .pattern(phoneRegex)
    .required()
    .messages({
      'string.pattern.base': 'Please enter a valid phone number',
      'string.empty': 'Phone number is required',
    }),
  password: Joi.string()
    .required()
    .messages({
      'string.empty': 'Password is required',
    }),
  deviceInfo: Joi.object({
    deviceId: Joi.string().allow(''),
    deviceType: Joi.string().valid('android', 'ios', 'web'),
    deviceName: Joi.string().allow(''),
    osVersion: Joi.string().allow(''),
    appVersion: Joi.string().allow(''),
  }),
});

// Send OTP schema
const sendOtpSchema = Joi.object({
  phone: Joi.string()
    .pattern(phoneRegex)
    .required()
    .messages({
      'string.pattern.base': 'Please enter a valid phone number',
      'string.empty': 'Phone number is required',
    }),
  type: Joi.string()
    .valid('register', 'login', 'reset_password', 'verify')
    .default('verify'),
});

// Verify OTP schema
const verifyOtpSchema = Joi.object({
  phone: Joi.string()
    .pattern(phoneRegex)
    .required()
    .messages({
      'string.pattern.base': 'Please enter a valid phone number',
    }),
  otp: Joi.string()
    .length(6)
    .pattern(/^\d+$/)
    .required()
    .messages({
      'string.length': 'OTP must be 6 digits',
      'string.pattern.base': 'OTP must contain only digits',
      'string.empty': 'OTP is required',
    }),
});

// Refresh token schema
const refreshTokenSchema = Joi.object({
  refreshToken: Joi.string()
    .required()
    .messages({
      'string.empty': 'Refresh token is required',
    }),
});

// Change password schema
const changePasswordSchema = Joi.object({
  currentPassword: Joi.string()
    .required()
    .messages({
      'string.empty': 'Current password is required',
    }),
  newPassword: Joi.string()
    .min(8)
    .max(128)
    .required()
    .messages({
      'string.empty': 'New password is required',
      'string.min': 'New password must be at least 8 characters',
    }),
  confirmPassword: Joi.string()
    .valid(Joi.ref('newPassword'))
    .required()
    .messages({
      'any.only': 'Passwords do not match',
    }),
});

// Reset password schema
const resetPasswordSchema = Joi.object({
  phone: Joi.string()
    .pattern(phoneRegex)
    .required(),
  otp: Joi.string()
    .length(6)
    .pattern(/^\d+$/)
    .required(),
  newPassword: Joi.string()
    .min(8)
    .max(128)
    .required(),
});

// Setup PIN schema
const setupPinSchema = Joi.object({
  pin: Joi.string()
    .length(4)
    .pattern(/^\d+$/)
    .required()
    .messages({
      'string.length': 'PIN must be 4 digits',
      'string.pattern.base': 'PIN must contain only digits',
    }),
  confirmPin: Joi.string()
    .valid(Joi.ref('pin'))
    .required()
    .messages({
      'any.only': 'PINs do not match',
    }),
});

module.exports = {
  registerSchema,
  loginSchema,
  sendOtpSchema,
  verifyOtpSchema,
  refreshTokenSchema,
  changePasswordSchema,
  resetPasswordSchema,
  setupPinSchema,
};
