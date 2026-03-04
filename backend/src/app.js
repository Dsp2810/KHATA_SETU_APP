const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const config = require('./config/config');
const { apiLimiter } = require('./middleware/rateLimit.middleware');
const { errorHandler } = require('./middleware/error.middleware');

// Import route aggregator
const routes = require('./routes');

const app = express();

/* ===============================
   Security Middleware
=============================== */
app.use(helmet());

/* ===============================
   CORS
=============================== */
app.use(
  cors({
    origin: config.frontendUrl === '*' ? '*' : config.frontendUrl,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
    credentials: config.frontendUrl !== '*',
    maxAge: 86400,
  })
);

/* ===============================
   Logging
=============================== */
if (config.nodeEnv !== 'test') {
  app.use(morgan('combined'));
}

/* ===============================
   Body Parsing
=============================== */
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

/* ===============================
   Root Route (IMPORTANT for Render)
=============================== */
app.get('/', (req, res) => {
  res.status(200).json({
    success: true,
    message: '🚀 KhataSetu API is running',
    environment: config.nodeEnv,
  });
});

/* ===============================
   Health Check
=============================== */
app.get('/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Server is healthy',
    timestamp: new Date().toISOString(),
  });
});

/* ===============================
   Rate Limiting
=============================== */
app.use('/api/', apiLimiter);

/* ===============================
   API Routes
=============================== */
app.use('/api/v1', routes);

/* ===============================
   404 Handler
=============================== */
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: {
      code: 'NOT_FOUND',
      message: `Route ${req.method} ${req.originalUrl} not found`,
    },
  });
});

/* ===============================
   Global Error Handler
=============================== */
app.use(errorHandler);

module.exports = app;
