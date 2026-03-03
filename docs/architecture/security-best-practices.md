# KhataSetu - Security Best Practices

## 🔒 Security Overview

Security is paramount for a fintech application handling financial data. This document outlines all security measures implemented in KhataSetu.

---

## 🎯 Security Checklist

### Authentication & Authorization
- [x] JWT-based authentication
- [x] Refresh token rotation
- [x] Password hashing with bcrypt
- [x] Role-based access control (RBAC)
- [x] Session management
- [x] Biometric authentication support

### Data Protection
- [x] HTTPS enforcement
- [x] Sensitive data encryption
- [x] Secure storage for tokens
- [x] Input validation & sanitization
- [x] SQL injection prevention (via ORM)
- [x] XSS prevention

### Network Security
- [x] Rate limiting
- [x] CORS configuration
- [x] Request size limits
- [x] Helmet.js security headers

### Application Security
- [x] Environment variable management
- [x] Error message sanitization
- [x] Logging (without sensitive data)
- [x] Audit trails

---

## 🔐 Authentication Implementation

### 1. Password Hashing (Backend)

```javascript
// utils/hash.util.js
const bcrypt = require('bcryptjs');

const SALT_ROUNDS = 12;

const hashPassword = async (password) => {
  const salt = await bcrypt.genSalt(SALT_ROUNDS);
  return bcrypt.hash(password, salt);
};

const comparePassword = async (password, hashedPassword) => {
  return bcrypt.compare(password, hashedPassword);
};

module.exports = { hashPassword, comparePassword };
```

### 2. JWT Token Generation

```javascript
// utils/token.util.js
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');

const generateAccessToken = (payload) => {
  return jwt.sign(
    {
      userId: payload.userId,
      shopId: payload.shopId,
      role: payload.role,
      type: 'access',
    },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_ACCESS_EXPIRY || '15m' }
  );
};

const generateRefreshToken = (userId) => {
  const token = jwt.sign(
    {
      userId,
      tokenId: uuidv4(),
      type: 'refresh',
    },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_REFRESH_EXPIRY || '7d' }
  );
  return token;
};

const verifyToken = (token) => {
  try {
    return jwt.verify(token, process.env.JWT_SECRET);
  } catch (error) {
    throw new Error('Invalid or expired token');
  }
};

module.exports = {
  generateAccessToken,
  generateRefreshToken,
  verifyToken,
};
```

### 3. Auth Middleware

```javascript
// middleware/auth.middleware.js
const { verifyToken } = require('../utils/token.util');
const User = require('../models/User.model');

const authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        error: {
          code: 'UNAUTHORIZED',
          message: 'Access token required',
        },
      });
    }
    
    const token = authHeader.split(' ')[1];
    const decoded = verifyToken(token);
    
    if (decoded.type !== 'access') {
      return res.status(401).json({
        success: false,
        error: {
          code: 'INVALID_TOKEN',
          message: 'Invalid token type',
        },
      });
    }
    
    const user = await User.findById(decoded.userId).select('-password');
    
    if (!user || !user.isActive) {
      return res.status(401).json({
        success: false,
        error: {
          code: 'USER_NOT_FOUND',
          message: 'User not found or inactive',
        },
      });
    }
    
    req.user = user;
    req.shopId = decoded.shopId;
    next();
  } catch (error) {
    return res.status(401).json({
      success: false,
      error: {
        code: 'UNAUTHORIZED',
        message: 'Invalid or expired token',
      },
    });
  }
};

module.exports = { authenticate };
```

### 4. Role-Based Access Control

```javascript
// middleware/role.middleware.js
const authorize = (...allowedRoles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        error: {
          code: 'UNAUTHORIZED',
          message: 'Authentication required',
        },
      });
    }
    
    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        error: {
          code: 'FORBIDDEN',
          message: 'You do not have permission to perform this action',
        },
      });
    }
    
    next();
  };
};

module.exports = { authorize };
```

---

## 📱 Flutter Secure Storage

### 1. Token Storage

```dart
// core/storage/secure_storage.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  
  // Keys
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userKey = 'user_data';
  
  // Access Token
  static Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }
  
  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }
  
  // Refresh Token
  static Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }
  
  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }
  
  // Clear All
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
```

### 2. Biometric Authentication

```dart
// services/biometric_service.dart
import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }
  
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }
  
  Future<bool> authenticate({
    required String localizedReason,
  }) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }
}
```

---

## 🛡️ Input Validation

### Backend Validation with Joi

```javascript
// validators/auth.validator.js
const Joi = require('joi');

const phoneRegex = /^[6-9]\d{9}$/;
const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/;

const registerSchema = Joi.object({
  name: Joi.string()
    .trim()
    .min(2)
    .max(100)
    .required()
    .messages({
      'string.min': 'Name must be at least 2 characters',
      'string.max': 'Name cannot exceed 100 characters',
      'any.required': 'Name is required',
    }),
  
  phone: Joi.string()
    .pattern(phoneRegex)
    .required()
    .messages({
      'string.pattern.base': 'Please enter a valid 10-digit Indian phone number',
      'any.required': 'Phone number is required',
    }),
  
  password: Joi.string()
    .pattern(passwordRegex)
    .required()
    .messages({
      'string.pattern.base': 'Password must contain at least 8 characters, one uppercase, one lowercase, one number and one special character',
      'any.required': 'Password is required',
    }),
  
  role: Joi.string()
    .valid('shopkeeper', 'customer')
    .default('shopkeeper'),
});

const loginSchema = Joi.object({
  phone: Joi.string()
    .pattern(phoneRegex)
    .required(),
  
  password: Joi.string()
    .required(),
});

module.exports = {
  registerSchema,
  loginSchema,
};
```

### Validation Middleware

```javascript
// middleware/validate.middleware.js
const validate = (schema) => {
  return (req, res, next) => {
    const { error, value } = schema.validate(req.body, {
      abortEarly: false,
      stripUnknown: true,
    });
    
    if (error) {
      const details = error.details.map((detail) => ({
        field: detail.path.join('.'),
        message: detail.message,
      }));
      
      return res.status(400).json({
        success: false,
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Validation failed',
          details,
        },
      });
    }
    
    req.body = value;
    next();
  };
};

module.exports = { validate };
```

### Flutter Input Validation

```dart
// core/utils/validators.dart
class Validators {
  static final RegExp _phoneRegex = RegExp(r'^[6-9]\d{9}$');
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
  );
  
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (!_phoneRegex.hasMatch(value)) {
      return 'Enter valid 10-digit phone number';
    }
    return null;
  }
  
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain uppercase letter';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain lowercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain number';
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain special character';
    }
    return null;
  }
  
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }
  
  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }
    final amount = double.tryParse(value);
    if (amount == null || amount <= 0) {
      return 'Enter valid amount';
    }
    return null;
  }
  
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Email is optional
    }
    if (!_emailRegex.hasMatch(value)) {
      return 'Enter valid email address';
    }
    return null;
  }
}
```

---

## 🌐 Network Security

### Rate Limiting

```javascript
// middleware/rateLimit.middleware.js
const rateLimit = require('express-rate-limit');

// General API rate limit
const apiLimiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 60 * 1000, // 1 minute
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
  message: {
    success: false,
    error: {
      code: 'RATE_LIMITED',
      message: 'Too many requests, please try again later',
    },
  },
  standardHeaders: true,
  legacyHeaders: false,
});

// Strict limit for auth endpoints
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // 5 attempts
  message: {
    success: false,
    error: {
      code: 'RATE_LIMITED',
      message: 'Too many login attempts, please try again after 15 minutes',
    },
  },
});

module.exports = { apiLimiter, authLimiter };
```

### Security Headers (Helmet)

```javascript
// app.js
const express = require('express');
const helmet = require('helmet');
const cors = require('cors');

const app = express();

// Security headers
app.use(helmet());
app.use(helmet.contentSecurityPolicy({
  directives: {
    defaultSrc: ["'self'"],
    styleSrc: ["'self'", "'unsafe-inline'"],
    scriptSrc: ["'self'"],
    imgSrc: ["'self'", 'data:', 'https:'],
  },
}));

// CORS
app.use(cors({
  origin: process.env.FRONTEND_URL,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  credentials: true,
  maxAge: 86400, // 24 hours
}));

// Body size limits
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
```

### Dio Interceptors (Flutter)

```dart
// core/network/api_interceptors.dart
import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorage _storage;
  
  AuthInterceptor(this._storage);
  
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Add authorization header
    final token = await _storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    // Add shop context
    final shopId = await _storage.getActiveShopId();
    if (shopId != null) {
      options.headers['X-Shop-Id'] = shopId;
    }
    
    handler.next(options);
  }
  
  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // Token expired - try refresh
      final refreshed = await _refreshToken();
      if (refreshed) {
        // Retry original request
        final response = await _retry(err.requestOptions);
        return handler.resolve(response);
      }
    }
    handler.next(err);
  }
  
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) return false;
      
      final dio = Dio();
      final response = await dio.post(
        '${ApiConstants.baseUrl}/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      
      if (response.statusCode == 200) {
        await _storage.saveAccessToken(response.data['data']['accessToken']);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  Future<Response> _retry(RequestOptions requestOptions) async {
    final token = await _storage.getAccessToken();
    
    final options = Options(
      method: requestOptions.method,
      headers: {
        ...requestOptions.headers,
        'Authorization': 'Bearer $token',
      },
    );
    
    return Dio().request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }
}
```

---

## 📝 Error Handling & Logging

### Sanitized Error Responses

```javascript
// middleware/error.middleware.js
const logger = require('../utils/logger.util');

const errorHandler = (err, req, res, next) => {
  // Log full error internally
  logger.error({
    message: err.message,
    stack: err.stack,
    path: req.path,
    method: req.method,
    userId: req.user?.id,
  });
  
  // Sanitize error for client
  const statusCode = err.statusCode || 500;
  const isProduction = process.env.NODE_ENV === 'production';
  
  const response = {
    success: false,
    error: {
      code: err.code || 'INTERNAL_ERROR',
      message: isProduction && statusCode === 500
        ? 'Something went wrong'
        : err.message,
    },
  };
  
  // Never expose stack traces in production
  if (!isProduction && statusCode !== 500) {
    response.error.details = err.details;
  }
  
  res.status(statusCode).json(response);
};

module.exports = { errorHandler };
```

### Secure Logging

```javascript
// utils/logger.util.js
const winston = require('winston');

// Sensitive fields to redact
const sensitiveFields = ['password', 'token', 'accessToken', 'refreshToken', 'otp'];

const redactSensitiveData = (obj) => {
  if (!obj || typeof obj !== 'object') return obj;
  
  const redacted = { ...obj };
  for (const field of sensitiveFields) {
    if (redacted[field]) {
      redacted[field] = '[REDACTED]';
    }
  }
  return redacted;
};

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json(),
    winston.format((info) => {
      info.data = redactSensitiveData(info.data);
      return info;
    })()
  ),
  transports: [
    new winston.transports.File({ filename: 'logs/error.log', level: 'error' }),
    new winston.transports.File({ filename: 'logs/combined.log' }),
  ],
});

if (process.env.NODE_ENV !== 'production') {
  logger.add(new winston.transports.Console({
    format: winston.format.simple(),
  }));
}

module.exports = logger;
```

---

## 🗄️ Data Protection

### MongoDB Security

```javascript
// models/User.model.js
const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  // ... other fields
  
  password: {
    type: String,
    required: true,
    select: false,  // Never include password by default
  },
});

// Never return password
userSchema.methods.toJSON = function() {
  const user = this.toObject();
  delete user.password;
  return user;
};
```

### Multi-tenancy Data Isolation

```javascript
// middleware/shop.middleware.js
const Shop = require('../models/Shop.model');

const requireShopContext = async (req, res, next) => {
  const shopId = req.params.shopId || req.headers['x-shop-id'];
  
  if (!shopId) {
    return res.status(400).json({
      success: false,
      error: {
        code: 'SHOP_REQUIRED',
        message: 'Shop context is required',
      },
    });
  }
  
  // Verify user has access to this shop
  const shop = await Shop.findOne({
    _id: shopId,
    $or: [
      { ownerId: req.user._id },
      { 'employees._id': req.user._id },
    ],
  });
  
  if (!shop) {
    return res.status(403).json({
      success: false,
      error: {
        code: 'SHOP_ACCESS_DENIED',
        message: 'You do not have access to this shop',
      },
    });
  }
  
  req.shop = shop;
  req.shopId = shop._id;
  next();
};

// Always filter queries by shopId
const CustomerService = {
  getAll: async (shopId, filters) => {
    return Customer.find({ shopId, ...filters });  // Always include shopId
  },
};
```

---

## 📋 Security Audit Checklist

### Pre-Launch Security Review

- [ ] All endpoints require authentication (except public ones)
- [ ] Role-based access properly implemented
- [ ] Input validation on all endpoints
- [ ] Rate limiting configured
- [ ] CORS properly configured
- [ ] Security headers enabled
- [ ] Error messages sanitized
- [ ] Sensitive data never logged
- [ ] Password requirements enforced
- [ ] Tokens stored securely on device
- [ ] HTTPS enforced
- [ ] Database queries parameterized
- [ ] File uploads validated
- [ ] Session timeout implemented
- [ ] Refresh token rotation working

### Periodic Security Checks

- [ ] Dependency vulnerabilities scan (npm audit)
- [ ] API security testing
- [ ] Penetration testing
- [ ] Log review for suspicious activity
- [ ] Token expiry review
- [ ] User permission audit
