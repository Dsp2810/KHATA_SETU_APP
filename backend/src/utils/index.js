// Export all utilities
const { logger, requestLogger, auditLog, logError } = require('./logger.util');
const {
  generateAccessToken,
  generateRefreshToken,
  verifyAccessToken,
  generateOTP,
  hashOTP,
  verifyOTP,
  generateRandomToken,
  getRefreshTokenExpiry,
  generateDeviceId,
  decodeToken,
  isTokenExpiringSoon,
} = require('./token.util');
const {
  hashPassword,
  comparePassword,
  generateRandomPassword,
  generatePIN,
  hashPIN,
  verifyPIN,
  maskSensitiveData,
  maskPhone,
  maskEmail,
} = require('./hash.util');

module.exports = {
  // Logger utilities
  logger,
  requestLogger,
  auditLog,
  logError,
  
  // Token utilities
  generateAccessToken,
  generateRefreshToken,
  verifyAccessToken,
  generateOTP,
  hashOTP,
  verifyOTP,
  generateRandomToken,
  getRefreshTokenExpiry,
  generateDeviceId,
  decodeToken,
  isTokenExpiringSoon,
  
  // Hash utilities
  hashPassword,
  comparePassword,
  generateRandomPassword,
  generatePIN,
  hashPIN,
  verifyPIN,
  maskSensitiveData,
  maskPhone,
  maskEmail,
};
