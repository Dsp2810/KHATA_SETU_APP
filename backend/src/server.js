require('dotenv').config();

const express = require('express');
const mongoose = require('mongoose');
const app = require('./app');
const config = require('./config/config');
const { logger } = require('./utils/logger.util');

const PORT = config.port || 3000;

// Connect to MongoDB
mongoose
  .connect(config.mongoUri)
  .then(() => {
    logger.info('✅ Connected to MongoDB');

    // Start server
    app.listen(PORT, () => {
      logger.info(`🚀 Server running on port ${PORT}`);
      logger.info(`📍 Environment: ${config.nodeEnv}`);
    });
  })
  .catch((error) => {
    logger.error('❌ MongoDB connection error:', error);
    process.exit(1);
  });

// Handle unhandled promise rejections
process.on('unhandledRejection', (err) => {
  logger.error('UNHANDLED REJECTION! Shutting down...');
  logger.error(err);
  process.exit(1);
});

// Handle uncaught exceptions
process.on('uncaughtException', (err) => {
  logger.error('UNCAUGHT EXCEPTION! Shutting down...');
  logger.error(err);
  process.exit(1);
});

// Graceful shutdown
process.on('SIGTERM', async () => {
  logger.info('👋 SIGTERM received. Shutting down gracefully');
  await mongoose.connection.close();
  logger.info('💤 Process terminated!');
  process.exit(0);
});
