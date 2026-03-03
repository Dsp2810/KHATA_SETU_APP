const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const config = require('../config/config');

/**
 * Generate access token
 * @param {object} payload - Token payload (userId, role, etc.)
 * @returns {string} JWT access token
 */
const generateAccessToken = (payload) => {
  return jwt.sign(payload, config.jwt.secret, {
    expiresIn: config.jwt.accessTokenExpiry,
    issuer: 'khatasetu',
    audience: 'khatasetu-app',
  });
};

/**
 * Generate refresh token
 * @returns {string} Random refresh token
 */
const generateRefreshToken = () => {
  return crypto.randomBytes(64).toString('hex');
};

/**
 * Verify access token
 * @param {string} token - JWT token to verify
 * @returns {object} Decoded token payload
 */
const verifyAccessToken = (token) => {
  return jwt.verify(token, config.jwt.secret, {
    issuer: 'khatasetu',
    audience: 'khatasetu-app',
  });
};

/**
 * Generate OTP
 * @param {number} length - OTP length (default: 6)
 * @returns {string} OTP string
 */
const generateOTP = (length = 6) => {
  const digits = '0123456789';
  let otp = '';
  
  for (let i = 0; i < length; i++) {
    otp += digits[Math.floor(Math.random() * 10)];
  }
  
  return otp;
};

/**
 * Hash OTP for storage
 * @param {string} otp - Plain OTP
 * @returns {string} Hashed OTP
 */
const hashOTP = (otp) => {
  return crypto.createHash('sha256').update(otp).digest('hex');
};

/**
 * Verify OTP
 * @param {string} plainOtp - Plain OTP entered by user
 * @param {string} hashedOtp - Stored hashed OTP
 * @returns {boolean} Whether OTP matches
 */
const verifyOTP = (plainOtp, hashedOtp) => {
  const hashed = hashOTP(plainOtp);
  return crypto.timingSafeEqual(Buffer.from(hashed), Buffer.from(hashedOtp));
};

/**
 * Generate random token (for email verification, password reset, etc.)
 * @param {number} bytes - Number of random bytes (default: 32)
 * @returns {string} Random hex string
 */
const generateRandomToken = (bytes = 32) => {
  return crypto.randomBytes(bytes).toString('hex');
};

/**
 * Calculate refresh token expiry date
 * @returns {Date} Expiry date
 */
const getRefreshTokenExpiry = () => {
  const expiryString = config.jwt.refreshTokenExpiry;
  const value = parseInt(expiryString);
  const unit = expiryString.replace(/[0-9]/g, '');
  
  const now = new Date();
  
  switch (unit) {
    case 'd':
      now.setDate(now.getDate() + value);
      break;
    case 'h':
      now.setHours(now.getHours() + value);
      break;
    case 'm':
      now.setMinutes(now.getMinutes() + value);
      break;
    default:
      now.setDate(now.getDate() + 7); // Default 7 days
  }
  
  return now;
};

/**
 * Generate device ID from device info
 * @param {object} deviceInfo - Device information
 * @returns {string} Device ID hash
 */
const generateDeviceId = (deviceInfo) => {
  const { deviceType, deviceName, osVersion } = deviceInfo;
  const data = `${deviceType}-${deviceName}-${osVersion}`;
  return crypto.createHash('md5').update(data).digest('hex');
};

/**
 * Decode token without verification (for debugging)
 * @param {string} token - JWT token
 * @returns {object} Decoded payload
 */
const decodeToken = (token) => {
  return jwt.decode(token);
};

/**
 * Check if token is about to expire
 * @param {number} exp - Token expiry timestamp
 * @param {number} bufferMinutes - Buffer time in minutes
 * @returns {boolean} Whether token is expiring soon
 */
const isTokenExpiringSoon = (exp, bufferMinutes = 5) => {
  const now = Math.floor(Date.now() / 1000);
  const buffer = bufferMinutes * 60;
  return exp - now < buffer;
};

module.exports = {
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
};
