const config = require('../config/config');

/**
 * Custom error class with status code
 */
class AppError extends Error {
  constructor(message, statusCode, code = 'ERROR') {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
    this.isOperational = true;
    
    Error.captureStackTrace(this, this.constructor);
  }
}

/**
 * Not found error handler
 */
const notFound = (req, res, next) => {
  const error = new AppError(`Not found - ${req.originalUrl}`, 404, 'NOT_FOUND');
  next(error);
};

/**
 * Global error handler middleware
 */
const errorHandler = (err, req, res, next) => {
  let error = { ...err };
  error.message = err.message;
  error.stack = err.stack;
  
  // Log error for debugging
  if (config.nodeEnv === 'development') {
    console.error('Error:', err);
  } else {
    console.error('Error:', err.message);
  }
  
  // Mongoose bad ObjectId
  if (err.name === 'CastError') {
    const message = 'Invalid resource ID format.';
    error = new AppError(message, 400, 'INVALID_ID');
  }
  
  // Mongoose duplicate key error
  if (err.code === 11000) {
    const field = Object.keys(err.keyValue)[0];
    const message = `Duplicate value for '${field}'. This ${field} already exists.`;
    error = new AppError(message, 400, 'DUPLICATE_KEY');
  }
  
  // Mongoose validation error
  if (err.name === 'ValidationError') {
    const messages = Object.values(err.errors).map(val => val.message);
    const message = messages.join('. ');
    error = new AppError(message, 400, 'VALIDATION_ERROR');
  }
  
  // JWT errors
  if (err.name === 'JsonWebTokenError') {
    error = new AppError('Invalid token.', 401, 'INVALID_TOKEN');
  }
  
  if (err.name === 'TokenExpiredError') {
    error = new AppError('Token has expired.', 401, 'TOKEN_EXPIRED');
  }
  
  // Multer file upload errors
  if (err.name === 'MulterError') {
    if (err.code === 'LIMIT_FILE_SIZE') {
      error = new AppError('File size too large.', 400, 'FILE_TOO_LARGE');
    } else if (err.code === 'LIMIT_FILE_COUNT') {
      error = new AppError('Too many files.', 400, 'TOO_MANY_FILES');
    } else if (err.code === 'LIMIT_UNEXPECTED_FILE') {
      error = new AppError('Unexpected file field.', 400, 'UNEXPECTED_FILE');
    } else {
      error = new AppError('File upload error.', 400, 'UPLOAD_ERROR');
    }
  }
  
  // Response
  const statusCode = error.statusCode || 500;
  const response = {
    success: false,
    message: error.message || 'Internal server error.',
    code: error.code || 'INTERNAL_ERROR',
  };
  
  // Add stack trace in development
  if (config.nodeEnv === 'development') {
    response.stack = error.stack;
  }
  
  // Add validation errors if present
  if (error.errors) {
    response.errors = error.errors;
  }
  
  res.status(statusCode).json(response);
};

/**
 * Async handler wrapper to avoid try-catch in every controller
 */
const asyncHandler = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};

module.exports = {
  AppError,
  notFound,
  errorHandler,
  asyncHandler,
};
