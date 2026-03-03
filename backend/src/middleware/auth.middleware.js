const jwt = require('jsonwebtoken');
const { User, RefreshToken } = require('../models');
const config = require('../config/config');

/**
 * Authentication middleware
 * Verifies JWT token and attaches user to request
 */
const authenticate = async (req, res, next) => {
  try {
    // Get token from header
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: 'Access denied. No token provided.',
        code: 'NO_TOKEN',
      });
    }
    
    const token = authHeader.split(' ')[1];
    
    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Access denied. Invalid token format.',
        code: 'INVALID_TOKEN_FORMAT',
      });
    }
    
    // Verify token
    let decoded;
    try {
      decoded = jwt.verify(token, config.jwt.secret);
    } catch (jwtError) {
      if (jwtError.name === 'TokenExpiredError') {
        return res.status(401).json({
          success: false,
          message: 'Token has expired.',
          code: 'TOKEN_EXPIRED',
        });
      }
      
      if (jwtError.name === 'JsonWebTokenError') {
        return res.status(401).json({
          success: false,
          message: 'Invalid token.',
          code: 'INVALID_TOKEN',
        });
      }
      
      throw jwtError;
    }
    
    // Find user
    const user = await User.findById(decoded.userId)
      .select('-password')
      .lean();
    
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'User not found.',
        code: 'USER_NOT_FOUND',
      });
    }
    
    if (!user.isActive) {
      return res.status(401).json({
        success: false,
        message: 'Account is deactivated.',
        code: 'ACCOUNT_DEACTIVATED',
      });
    }
    
    // Check if user's phone is verified (skip in development for testing)
    if (user.isPhoneVerified === false && process.env.NODE_ENV === 'production') {
      return res.status(403).json({
        success: false,
        message: 'Phone number not verified.',
        code: 'PHONE_NOT_VERIFIED',
      });
    }
    
    // Attach user and token info to request
    req.user = user;
    req.userId = user._id;
    req.tokenExp = decoded.exp;
    
    next();
  } catch (error) {
    console.error('Authentication error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error during authentication.',
      code: 'AUTH_ERROR',
    });
  }
};

/**
 * Optional authentication middleware
 * Attempts to authenticate but allows request to proceed even if not authenticated
 */
const optionalAuthenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return next();
    }
    
    const token = authHeader.split(' ')[1];
    
    if (!token) {
      return next();
    }
    
    try {
      const decoded = jwt.verify(token, config.jwt.secret);
      const user = await User.findById(decoded.userId)
        .select('-password')
        .lean();
      
      if (user && user.isActive) {
        req.user = user;
        req.userId = user._id;
      }
    } catch (error) {
      // Token invalid but continue anyway
    }
    
    next();
  } catch (error) {
    next();
  }
};

/**
 * Verify refresh token middleware
 */
const verifyRefreshToken = async (req, res, next) => {
  try {
    const { refreshToken } = req.body;
    
    if (!refreshToken) {
      return res.status(400).json({
        success: false,
        message: 'Refresh token is required.',
        code: 'NO_REFRESH_TOKEN',
      });
    }
    
    // Find refresh token in database
    const tokenDoc = await RefreshToken.findOne({ token: refreshToken });
    
    if (!tokenDoc) {
      return res.status(401).json({
        success: false,
        message: 'Invalid refresh token.',
        code: 'INVALID_REFRESH_TOKEN',
      });
    }
    
    if (tokenDoc.isRevoked) {
      // Possible token theft - revoke all tokens for security
      await RefreshToken.revokeAllForUser(tokenDoc.userId, 'security');
      
      return res.status(401).json({
        success: false,
        message: 'Refresh token has been revoked.',
        code: 'TOKEN_REVOKED',
      });
    }
    
    if (tokenDoc.expiresAt < new Date()) {
      return res.status(401).json({
        success: false,
        message: 'Refresh token has expired.',
        code: 'REFRESH_TOKEN_EXPIRED',
      });
    }
    
    // Attach token document to request
    req.refreshTokenDoc = tokenDoc;
    
    next();
  } catch (error) {
    console.error('Refresh token verification error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error during token verification.',
      code: 'TOKEN_VERIFY_ERROR',
    });
  }
};

module.exports = {
  authenticate,
  optionalAuthenticate,
  verifyRefreshToken,
};
