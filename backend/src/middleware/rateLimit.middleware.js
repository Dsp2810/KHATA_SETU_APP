const rateLimit = require('express-rate-limit');
const config = require('../config/config');

/**
 * General API rate limiter
 */
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: config.nodeEnv === 'development' ? 1000 : 100, // Relaxed in dev
  message: {
    success: false,
    message: 'Too many requests. Please try again later.',
    code: 'RATE_LIMIT_EXCEEDED',
  },
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => {
    // Use user ID if authenticated, otherwise use IP
    return req.userId?.toString() || req.ip;
  },
});

/**
 * Strict rate limiter for authentication endpoints
 */
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: config.nodeEnv === 'development' ? 100 : 10, // Relaxed in dev
  message: {
    success: false,
    message: 'Too many login attempts. Please try again in 15 minutes.',
    code: 'AUTH_RATE_LIMIT',
  },
  standardHeaders: true,
  legacyHeaders: false,
  skipSuccessfulRequests: false,
});

/**
 * OTP rate limiter
 */
const otpLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: config.nodeEnv === 'development' ? 50 : 3, // Relaxed in dev
  message: {
    success: false,
    message: 'Too many OTP requests. Please wait before requesting again.',
    code: 'OTP_RATE_LIMIT',
  },
  standardHeaders: true,
  legacyHeaders: false,
});

/**
 * SMS rate limiter (per phone number)
 */
const smsLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 5, // 5 SMS per hour per phone
  message: {
    success: false,
    message: 'SMS limit reached. Please try again later.',
    code: 'SMS_RATE_LIMIT',
  },
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => {
    return req.body.phone || req.ip;
  },
});

/**
 * Upload rate limiter
 */
const uploadLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 50, // 50 uploads per hour
  message: {
    success: false,
    message: 'Upload limit reached. Please try again later.',
    code: 'UPLOAD_RATE_LIMIT',
  },
  standardHeaders: true,
  legacyHeaders: false,
});

/**
 * Report generation rate limiter
 */
const reportLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: config.nodeEnv === 'development' ? 200 : 20, // Relaxed in dev
  message: {
    success: false,
    message: 'Report generation limit reached. Please try again later.',
    code: 'REPORT_RATE_LIMIT',
  },
  standardHeaders: true,
  legacyHeaders: false,
});

/**
 * Sync rate limiter
 */
const syncLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: config.nodeEnv === 'development' ? 100 : 10, // Relaxed in dev
  message: {
    success: false,
    message: 'Sync rate limit reached. Please wait before syncing again.',
    code: 'SYNC_RATE_LIMIT',
  },
  standardHeaders: true,
  legacyHeaders: false,
});

/**
 * Create custom rate limiter
 * @param {number} windowMs - Window size in milliseconds
 * @param {number} max - Maximum requests per window
 * @param {string} message - Error message
 */
const createLimiter = (windowMs, max, message) => {
  return rateLimit({
    windowMs,
    max,
    message: {
      success: false,
      message,
      code: 'RATE_LIMIT_EXCEEDED',
    },
    standardHeaders: true,
    legacyHeaders: false,
  });
};

module.exports = {
  apiLimiter,
  authLimiter,
  otpLimiter,
  smsLimiter,
  uploadLimiter,
  reportLimiter,
  syncLimiter,
  createLimiter,
};
