const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { v4: uuidv4 } = require('uuid');
const config = require('../config/config');

// Ensure upload directories exist
const uploadDirs = [
  path.join(config.upload.path, 'products'),
  path.join(config.upload.path, 'attachments'),
];

uploadDirs.forEach(dir => {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
});

/**
 * Storage configuration for product images.
 */
const productStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, path.join(config.upload.path, 'products'));
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    const filename = `product_${uuidv4()}${ext}`;
    cb(null, filename);
  },
});

/**
 * Storage configuration for ledger attachments.
 */
const attachmentStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, path.join(config.upload.path, 'attachments'));
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    const filename = `attach_${uuidv4()}${ext}`;
    cb(null, filename);
  },
});

/**
 * File filter: only images allowed.
 */
const imageFilter = (req, file, cb) => {
  const allowedMimes = [
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
  ];

  if (allowedMimes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new multer.MulterError('LIMIT_UNEXPECTED_FILE', 'Only image files (JPEG, PNG, GIF, WebP) are allowed'));
  }
};

/**
 * Product image upload (single image).
 */
const uploadProductImage = multer({
  storage: productStorage,
  limits: {
    fileSize: config.upload.maxSize, // Default 5MB
  },
  fileFilter: imageFilter,
}).single('image');

/**
 * Product images upload (multiple).
 */
const uploadProductImages = multer({
  storage: productStorage,
  limits: {
    fileSize: config.upload.maxSize,
    files: 5,
  },
  fileFilter: imageFilter,
}).array('images', 5);

/**
 * Ledger attachment upload.
 */
const uploadAttachment = multer({
  storage: attachmentStorage,
  limits: {
    fileSize: config.upload.maxSize,
  },
  fileFilter: imageFilter,
}).single('attachment');

/**
 * Middleware wrapper that handles multer errors gracefully.
 */
const handleUpload = (uploadFn) => (req, res, next) => {
  uploadFn(req, res, (err) => {
    if (err instanceof multer.MulterError) {
      // Let error middleware handle multer errors
      return next(err);
    }
    if (err) {
      return next(err);
    }
    next();
  });
};

module.exports = {
  uploadProductImage: handleUpload(uploadProductImage),
  uploadProductImages: handleUpload(uploadProductImages),
  uploadAttachment: handleUpload(uploadAttachment),
};
