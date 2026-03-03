// Export all middleware
const { authenticate, optionalAuthenticate, verifyRefreshToken } = require('./auth.middleware');
const { authorize, authorizeShopAccess, requirePermission, adminOnly } = require('./role.middleware');
const { validate, validateAll, sanitizeInput, validateObjectId } = require('./validate.middleware');
const { AppError, notFound, errorHandler, asyncHandler } = require('./error.middleware');
const {
  apiLimiter,
  authLimiter,
  otpLimiter,
  smsLimiter,
  uploadLimiter,
  reportLimiter,
  syncLimiter,
  createLimiter,
} = require('./rateLimit.middleware');

module.exports = {
  // Auth middleware
  authenticate,
  optionalAuthenticate,
  verifyRefreshToken,
  
  // Role middleware
  authorize,
  authorizeShopAccess,
  requirePermission,
  adminOnly,
  
  // Validation middleware
  validate,
  validateAll,
  sanitizeInput,
  validateObjectId,
  
  // Error middleware
  AppError,
  notFound,
  errorHandler,
  asyncHandler,
  
  // Rate limiting middleware
  apiLimiter,
  authLimiter,
  otpLimiter,
  smsLimiter,
  uploadLimiter,
  reportLimiter,
  syncLimiter,
  createLimiter,
};
