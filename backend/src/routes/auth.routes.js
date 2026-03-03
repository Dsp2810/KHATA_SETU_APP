const express = require('express');
const router = express.Router();
const { authController } = require('../controllers');
const {
  authenticate,
  verifyRefreshToken,
  validate,
  authLimiter,
  otpLimiter,
} = require('../middleware');
const {
  registerSchema,
  loginSchema,
  sendOtpSchema,
  verifyOtpSchema,
  refreshTokenSchema,
  changePasswordSchema,
} = require('../validators');

// Public routes
router.post(
  '/register',
  authLimiter,
  validate(registerSchema),
  authController.register
);

router.post(
  '/login',
  authLimiter,
  validate(loginSchema),
  authController.login
);

router.post(
  '/send-otp',
  otpLimiter,
  validate(sendOtpSchema),
  authController.sendOtp
);

router.post(
  '/verify-otp',
  otpLimiter,
  validate(verifyOtpSchema),
  authController.verifyOtp
);

router.post(
  '/refresh-token',
  validate(refreshTokenSchema),
  verifyRefreshToken,
  authController.refreshAccessToken
);

// Protected routes
router.use(authenticate);

router.get('/me', authController.getMe);

router.post('/logout', authController.logout);

router.post('/logout-all', authController.logoutAll);

router.post(
  '/change-password',
  validate(changePasswordSchema),
  authController.changePassword
);

router.post('/fcm-token', authController.registerFcmToken);

module.exports = router;
