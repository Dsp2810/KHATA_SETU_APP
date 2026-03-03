/**
 * Validation middleware using Joi schemas
 * @param {object} schema - Joi validation schema object
 * @param {string} source - Where to validate: 'body', 'query', 'params'
 */
const validate = (schema, source = 'body') => {
  return (req, res, next) => {
    const dataToValidate = req[source];
    
    if (!dataToValidate) {
      return res.status(400).json({
        success: false,
        message: `No ${source} data provided.`,
        code: 'VALIDATION_ERROR',
      });
    }
    
    const options = {
      abortEarly: false, // Return all errors, not just the first one
      allowUnknown: true, // Allow unknown keys that are not in schema
      stripUnknown: true, // Remove unknown keys from validated data
    };
    
    const { error, value } = schema.validate(dataToValidate, options);
    
    if (error) {
      const errors = error.details.map((detail) => ({
        field: detail.path.join('.'),
        message: detail.message.replace(/"/g, ''),
        type: detail.type,
      }));
      
      return res.status(400).json({
        success: false,
        message: 'Validation failed.',
        code: 'VALIDATION_ERROR',
        errors,
      });
    }
    
    // Replace original data with validated value
    req[source] = value;
    next();
  };
};

/**
 * Validate multiple sources at once
 * @param {object} schemas - Object with schema for each source
 */
const validateAll = (schemas) => {
  return (req, res, next) => {
    const allErrors = [];
    
    const options = {
      abortEarly: false,
      allowUnknown: true,
      stripUnknown: true,
    };
    
    Object.entries(schemas).forEach(([source, schema]) => {
      const dataToValidate = req[source];
      
      if (dataToValidate) {
        const { error, value } = schema.validate(dataToValidate, options);
        
        if (error) {
          const errors = error.details.map((detail) => ({
            source,
            field: detail.path.join('.'),
            message: detail.message.replace(/"/g, ''),
            type: detail.type,
          }));
          allErrors.push(...errors);
        } else {
          req[source] = value;
        }
      }
    });
    
    if (allErrors.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed.',
        code: 'VALIDATION_ERROR',
        errors: allErrors,
      });
    }
    
    next();
  };
};

/**
 * Sanitize strings to prevent XSS
 */
const sanitizeInput = (req, res, next) => {
  const sanitize = (obj) => {
    if (typeof obj === 'string') {
      return obj
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#x27;')
        .trim();
    }
    
    if (Array.isArray(obj)) {
      return obj.map(sanitize);
    }
    
    if (obj !== null && typeof obj === 'object') {
      const sanitized = {};
      Object.keys(obj).forEach((key) => {
        sanitized[key] = sanitize(obj[key]);
      });
      return sanitized;
    }
    
    return obj;
  };
  
  if (req.body) {
    req.body = sanitize(req.body);
  }
  
  if (req.query) {
    req.query = sanitize(req.query);
  }
  
  next();
};

/**
 * Check for MongoDB ObjectId validity
 */
const validateObjectId = (...paramNames) => {
  return (req, res, next) => {
    const objectIdRegex = /^[0-9a-fA-F]{24}$/;
    const invalidIds = [];
    
    paramNames.forEach((paramName) => {
      const id = req.params[paramName] || req.body[paramName] || req.query[paramName];
      
      if (id && !objectIdRegex.test(id)) {
        invalidIds.push(paramName);
      }
    });
    
    if (invalidIds.length > 0) {
      return res.status(400).json({
        success: false,
        message: `Invalid ID format for: ${invalidIds.join(', ')}`,
        code: 'INVALID_OBJECT_ID',
      });
    }
    
    next();
  };
};

module.exports = {
  validate,
  validateAll,
  sanitizeInput,
  validateObjectId,
};
