const { logger } = require('../utils/logger.util');

/**
 * Request debug logger middleware.
 * Logs every incoming request with body/params/query details.
 * Essential for debugging transaction flow.
 */
const debugLogger = (req, res, next) => {
  const requestId = `REQ-${Date.now().toString(36)}-${Math.random().toString(36).substr(2, 5)}`;
  req.requestId = requestId;

  const startTime = Date.now();

  // Log incoming request
  logger.info(`[${requestId}] ▶ ${req.method} ${req.originalUrl}`, {
    ip: req.ip,
    userId: req.userId || 'anonymous',
    shopId: req.params?.shopId || req.headers['x-shop-id'] || 'none',
    contentType: req.headers['content-type'],
  });

  // Log request body (sanitized) for mutation requests
  if (['POST', 'PUT', 'PATCH', 'DELETE'].includes(req.method)) {
    const sanitizedBody = { ...req.body };
    // Remove sensitive fields
    delete sanitizedBody.password;
    delete sanitizedBody.token;
    delete sanitizedBody.refreshToken;

    logger.debug(`[${requestId}] Body: ${JSON.stringify(sanitizedBody)}`);
  }

  // Log query params for GET requests
  if (req.method === 'GET' && Object.keys(req.query).length > 0) {
    logger.debug(`[${requestId}] Query: ${JSON.stringify(req.query)}`);
  }

  // Log params
  if (Object.keys(req.params).length > 0) {
    logger.debug(`[${requestId}] Params: ${JSON.stringify(req.params)}`);
  }

  // Capture response
  const originalSend = res.send;
  res.send = function (body) {
    const duration = Date.now() - startTime;
    const statusEmoji = res.statusCode < 400 ? '✅' : (res.statusCode < 500 ? '⚠️' : '❌');

    logger.info(`[${requestId}] ${statusEmoji} ${res.statusCode} (${duration}ms)`);

    // Log response body size in debug mode
    if (body) {
      const size = typeof body === 'string' ? body.length : JSON.stringify(body).length;
      logger.debug(`[${requestId}] Response size: ${size} bytes`);
    }

    return originalSend.call(this, body);
  };

  next();
};

/**
 * MongoDB session logger — logs session lifecycle events.
 * Attach to session-based operations.
 */
const logSessionEvent = (txnId, event, details = {}) => {
  const eventIcons = {
    START: '🟢',
    COMMIT: '✅',
    ABORT: '❌',
    QUERY: '🔍',
    UPDATE: '📝',
    BALANCE: '💰',
  };

  const icon = eventIcons[event] || '📋';
  logger.info(`[TXN:${txnId}] ${icon} ${event}`, details);
};

module.exports = {
  debugLogger,
  logSessionEvent,
};
