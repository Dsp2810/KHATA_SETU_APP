require('dotenv').config();

module.exports = {
  // ===============================
  // Server
  // ===============================
  nodeEnv: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT, 10) || 3000,

  // ===============================
  // Database
  // ===============================
  // Support both MONGO_URI and MONGODB_URI (safe for deployment)
  mongoUri:
    process.env.MONGO_URI ||
    process.env.MONGODB_URI ||
    'mongodb://localhost:27017/khatasetu',

  // ===============================
  // JWT
  // ===============================
  jwt: {
    secret: process.env.JWT_SECRET || 'change-this-in-production',
    accessExpiry: process.env.JWT_ACCESS_EXPIRY || '15m',
    refreshExpiry: process.env.JWT_REFRESH_EXPIRY || '7d',
    accessTokenExpiry: process.env.JWT_ACCESS_EXPIRY || '15m',
    refreshTokenExpiry: process.env.JWT_REFRESH_EXPIRY || '7d',
  },

  // ===============================
  // Rate Limiting
  // ===============================
  rateLimit: {
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS, 10) || 60000,
    maxRequests:
      parseInt(process.env.RATE_LIMIT_MAX_REQUESTS, 10) || 100,
  },

  // ===============================
  // Firebase
  // ===============================
  firebase: {
    projectId: process.env.FIREBASE_PROJECT_ID,
    privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
    serviceAccount: process.env.FIREBASE_SERVICE_ACCOUNT_JSON,
  },

  // ===============================
  // SMS Configuration
  // ===============================
  sms: {
    provider: process.env.SMS_PROVIDER || 'mock',
    senderId: process.env.SMS_SENDER_ID || 'KHATAS',

    msg91AuthKey: process.env.MSG91_AUTH_KEY,

    twilioAccountSid: process.env.TWILIO_ACCOUNT_SID,
    twilioAuthToken: process.env.TWILIO_AUTH_TOKEN,
    twilioPhoneNumber: process.env.TWILIO_PHONE_NUMBER,
    whatsappNumber: process.env.TWILIO_WHATSAPP_NUMBER,

    textLocalApiKey: process.env.TEXTLOCAL_API_KEY,
  },

  // ===============================
  // File Upload
  // ===============================
  upload: {
    maxSize:
      parseInt(process.env.MAX_FILE_SIZE, 10) ||
      5 * 1024 * 1024,
    path: process.env.UPLOAD_PATH || './uploads',
  },

  // ===============================
  // CORS
  // ===============================
  frontendUrl: process.env.FRONTEND_URL || '*',

  // ===============================
  // Logging
  // ===============================
  logLevel: process.env.LOG_LEVEL || 'info',
};
