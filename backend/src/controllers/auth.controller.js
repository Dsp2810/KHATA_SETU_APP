const { User, Shop, RefreshToken, FCMToken } = require('../models');
const { asyncHandler, AppError } = require('../middleware');
const {
  generateAccessToken,
  generateRefreshToken,
  getRefreshTokenExpiry,
  generateOTP,
  hashOTP,
  verifyOTP,
  auditLog,
} = require('../utils');
const config = require('../config/config');

/**
 * Register a new user
 * POST /api/auth/register
 */
const register = asyncHandler(async (req, res) => {
  const { name, phone, password, shopName, language } = req.body;
  
  // Check if user already exists
  const existingUser = await User.findOne({ phone });
  if (existingUser) {
    throw new AppError('Phone number already registered', 400, 'PHONE_EXISTS');
  }
  
  // Create user
  const user = await User.create({
    name,
    phone,
    password,
    settings: {
      language: language || 'en',
    },
  });
  
  // Create default shop
  const shop = await Shop.create({
    name: shopName,
    owner: user._id,
  });
  
  // Update user with default shop
  user.defaultShopId = shop._id;
  await user.save();
  
  // Generate tokens
  const accessToken = generateAccessToken({
    userId: user._id,
    role: user.role,
  });
  
  const refreshToken = generateRefreshToken();
  
  // Save refresh token
  await RefreshToken.create({
    userId: user._id,
    token: refreshToken,
    expiresAt: getRefreshTokenExpiry(),
    deviceInfo: req.body.deviceInfo || {},
    ipAddress: req.ip,
    userAgent: req.get('user-agent'),
  });
  
  auditLog('USER_REGISTERED', user._id, { phone: user.phone });
  
  res.status(201).json({
    success: true,
    message: 'Registration successful. Please verify your phone number.',
    data: {
      user: {
        id: user._id,
        name: user.name,
        phone: user.phone,
        role: user.role,
        isPhoneVerified: user.isPhoneVerified,
      },
      shop: {
        id: shop._id,
        name: shop.name,
      },
      tokens: {
        accessToken,
        refreshToken,
        expiresIn: config.jwt.accessTokenExpiry,
      },
    },
  });
});

/**
 * Login user
 * POST /api/auth/login
 */
const login = asyncHandler(async (req, res) => {
  const { phone, password, deviceInfo } = req.body;
  
  // Find user
  const user = await User.findOne({ phone }).select('+password');
  if (!user) {
    throw new AppError('Invalid phone number or password', 401, 'INVALID_CREDENTIALS');
  }
  
  // Check password
  const isMatch = await user.comparePassword(password);
  if (!isMatch) {
    throw new AppError('Invalid phone number or password', 401, 'INVALID_CREDENTIALS');
  }
  
  // Check if account is active
  if (!user.isActive) {
    throw new AppError('Account is deactivated', 403, 'ACCOUNT_DEACTIVATED');
  }
  
  // Generate tokens
  const accessToken = generateAccessToken({
    userId: user._id,
    role: user.role,
  });
  
  const refreshToken = generateRefreshToken();
  
  // Save refresh token
  await RefreshToken.create({
    userId: user._id,
    token: refreshToken,
    expiresAt: getRefreshTokenExpiry(),
    deviceInfo: deviceInfo || {},
    ipAddress: req.ip,
    userAgent: req.get('user-agent'),
  });
  
  // Update last login
  user.lastLoginAt = new Date();
  await user.save();
  
  // Get user's shops
  const shops = await Shop.find({
    $or: [
      { owner: user._id },
      { 'employees.userId': user._id, 'employees.isActive': true },
    ],
  }).select('name');
  
  auditLog('USER_LOGIN', user._id, { phone: user.phone });
  
  res.json({
    success: true,
    message: 'Login successful',
    data: {
      user: {
        id: user._id,
        name: user.name,
        phone: user.phone,
        role: user.role,
        isPhoneVerified: user.isPhoneVerified,
        defaultShopId: user.defaultShopId,
        settings: user.settings,
      },
      shops,
      tokens: {
        accessToken,
        refreshToken,
        expiresIn: config.jwt.accessTokenExpiry,
      },
    },
  });
});

/**
 * Refresh access token
 * POST /api/auth/refresh-token
 */
const refreshAccessToken = asyncHandler(async (req, res) => {
  const { refreshTokenDoc } = req;
  
  // Generate new tokens
  const accessToken = generateAccessToken({
    userId: refreshTokenDoc.userId,
    role: 'user', // Would need to fetch user for actual role
  });
  
  const newRefreshToken = generateRefreshToken();
  
  // Revoke old token and create new one (token rotation)
  await refreshTokenDoc.revoke('replaced');
  
  await RefreshToken.create({
    userId: refreshTokenDoc.userId,
    token: newRefreshToken,
    expiresAt: getRefreshTokenExpiry(),
    deviceInfo: refreshTokenDoc.deviceInfo,
    ipAddress: req.ip,
    userAgent: req.get('user-agent'),
    previousTokenId: refreshTokenDoc._id,
    rotationCount: refreshTokenDoc.rotationCount + 1,
  });
  
  res.json({
    success: true,
    message: 'Token refreshed successfully',
    data: {
      tokens: {
        accessToken,
        refreshToken: newRefreshToken,
        expiresIn: config.jwt.accessTokenExpiry,
      },
    },
  });
});

/**
 * Logout user
 * POST /api/auth/logout
 */
const logout = asyncHandler(async (req, res) => {
  const { refreshToken, deviceId } = req.body;
  
  // Revoke specific refresh token if provided
  if (refreshToken) {
    await RefreshToken.findOneAndUpdate(
      { token: refreshToken },
      { isRevoked: true, revokedAt: new Date(), revokedReason: 'logout' }
    );
  }
  
  // Deactivate FCM token for device
  if (deviceId) {
    await FCMToken.deactivate(req.userId, deviceId);
  }
  
  auditLog('USER_LOGOUT', req.userId, {});
  
  res.json({
    success: true,
    message: 'Logged out successfully',
  });
});

/**
 * Logout from all devices
 * POST /api/auth/logout-all
 */
const logoutAll = asyncHandler(async (req, res) => {
  // Revoke all refresh tokens
  await RefreshToken.revokeAllForUser(req.userId, 'logout');
  
  // Deactivate all FCM tokens
  await FCMToken.deactivateAll(req.userId);
  
  auditLog('USER_LOGOUT_ALL', req.userId, {});
  
  res.json({
    success: true,
    message: 'Logged out from all devices',
  });
});

/**
 * Send OTP
 * POST /api/auth/send-otp
 */
const sendOtp = asyncHandler(async (req, res) => {
  const { phone, type } = req.body;
  
  // Generate OTP
  const otp = generateOTP(6);
  const hashedOtp = hashOTP(otp);
  const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes
  
  // Find or create user OTP record
  await User.findOneAndUpdate(
    { phone },
    {
      'otp.code': hashedOtp,
      'otp.expiresAt': expiresAt,
      'otp.attempts': 0,
      'otp.type': type,
    },
    { upsert: false }
  );
  
  // TODO: Send OTP via SMS service
  console.log(`OTP for ${phone}: ${otp}`); // For development
  
  res.json({
    success: true,
    message: 'OTP sent successfully',
    data: {
      expiresIn: 600, // 10 minutes in seconds
    },
  });
});

/**
 * Verify OTP
 * POST /api/auth/verify-otp
 */
const verifyOtpHandler = asyncHandler(async (req, res) => {
  const { phone, otp } = req.body;
  
  const user = await User.findOne({ phone });
  if (!user) {
    throw new AppError('User not found', 404, 'USER_NOT_FOUND');
  }
  
  if (!user.otp || !user.otp.code) {
    throw new AppError('No OTP requested', 400, 'NO_OTP');
  }
  
  if (user.otp.expiresAt < new Date()) {
    throw new AppError('OTP has expired', 400, 'OTP_EXPIRED');
  }
  
  if (user.otp.attempts >= 3) {
    throw new AppError('Too many attempts. Please request a new OTP', 400, 'OTP_MAX_ATTEMPTS');
  }
  
  const isValid = verifyOTP(otp, user.otp.code);
  
  if (!isValid) {
    user.otp.attempts += 1;
    await user.save();
    throw new AppError('Invalid OTP', 400, 'INVALID_OTP');
  }
  
  // Mark phone as verified
  user.isPhoneVerified = true;
  user.otp = undefined;
  await user.save();
  
  auditLog('PHONE_VERIFIED', user._id, { phone });
  
  res.json({
    success: true,
    message: 'Phone number verified successfully',
  });
});

/**
 * Change password
 * POST /api/auth/change-password
 */
const changePassword = asyncHandler(async (req, res) => {
  const { currentPassword, newPassword } = req.body;
  
  const user = await User.findById(req.userId).select('+password');
  if (!user) {
    throw new AppError('User not found', 404, 'USER_NOT_FOUND');
  }
  
  const isMatch = await user.comparePassword(currentPassword);
  if (!isMatch) {
    throw new AppError('Current password is incorrect', 400, 'WRONG_PASSWORD');
  }
  
  user.password = newPassword;
  await user.save();
  
  // Revoke all refresh tokens except current
  await RefreshToken.revokeAllForUser(req.userId, 'security');
  
  auditLog('PASSWORD_CHANGED', req.userId, {});
  
  res.json({
    success: true,
    message: 'Password changed successfully. Please login again on other devices.',
  });
});

/**
 * Get current user
 * GET /api/auth/me
 */
const getMe = asyncHandler(async (req, res) => {
  const user = await User.findById(req.userId).select('-otp');
  if (!user) {
    throw new AppError('User not found', 404, 'USER_NOT_FOUND');
  }
  
  const shops = await Shop.find({
    $or: [
      { owner: user._id },
      { 'employees.userId': user._id, 'employees.isActive': true },
    ],
  }).select('name');
  
  res.json({
    success: true,
    data: {
      user: {
        id: user._id,
        name: user.name,
        phone: user.phone,
        email: user.email,
        role: user.role,
        avatar: user.avatar,
        isPhoneVerified: user.isPhoneVerified,
        defaultShopId: user.defaultShopId,
        settings: user.settings,
        createdAt: user.createdAt,
      },
      shops,
    },
  });
});

/**
 * Register FCM token
 * POST /api/auth/fcm-token
 */
const registerFcmToken = asyncHandler(async (req, res) => {
  const { token, deviceId, deviceType, deviceName } = req.body;
  
  await FCMToken.registerToken(req.userId, {
    token,
    deviceId,
    deviceType,
    deviceName,
  });
  
  res.json({
    success: true,
    message: 'FCM token registered successfully',
  });
});

module.exports = {
  register,
  login,
  refreshAccessToken,
  logout,
  logoutAll,
  sendOtp,
  verifyOtp: verifyOtpHandler,
  changePassword,
  getMe,
  registerFcmToken,
};
