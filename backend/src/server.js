require('dotenv').config();

const mongoose = require('mongoose');
const app = require('./app');
const config = require('./config/config');
const { logger } = require('./utils/logger.util');

/**
 * Use Render dynamic port first
 * Fallback to config or 3000 for local
 */
const PORT = process.env.PORT || config.port || 3000;

/**
 * Start server immediately
 * (IMPORTANT for Render health check)
 */
const server = app.listen(PORT, () => {
  logger.info(`🚀 Server running on port ${PORT}`);
  logger.info(`📍 Environment: ${config.nodeEnv || 'development'}`);
});

/**
 * Connect to MongoDB separately
 * (So deployment does not hang)
 */
mongoose
  .connect(config.mongoUri, {
    serverSelectionTimeoutMS: 10000, // Fail fast if Mongo unreachable
  })
  .then(() => {
    logger.info('✅ Connected to MongoDB');
  })
  .catch((error) => {
    logger.error('❌ MongoDB connection error:', error);
  });

/**
 * Handle unhandled promise rejections
 */
process.on('unhandledRejection', (err) => {
  logger.error('❌ UNHANDLED REJECTION! Shutting down...');
  logger.error(err);
  server.close(() => {
    process.exit(1);
  });
});

/**
 * Handle uncaught exceptions
 */
process.on('uncaughtException', (err) => {
  logger.error('❌ UNCAUGHT EXCEPTION! Shutting down...');
  logger.error(err);
  process.exit(1);
});

/**
 * Graceful shutdown (Render sends SIGTERM on redeploy)
 */
process.on('SIGTERM', async () => {
  logger.info('👋 SIGTERM received. Shutting down gracefully...');

  try {
    await mongoose.connection.close();
    logger.info('🛑 MongoDB connection closed.');
  } catch (error) {
    logger.error('Error closing MongoDB:', error);
  }

  server.close(() => {
    logger.info('💤 Server terminated.');
    process.exit(0);
  });
});
