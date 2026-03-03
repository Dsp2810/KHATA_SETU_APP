# KhataSetu - Backend Folder Structure

## 📁 Complete Node.js Backend Structure

```
khatasetu_backend/
├── src/
│   ├── app.js                        # Express app setup
│   ├── server.js                     # Server entry point
│   │
│   ├── config/
│   │   ├── index.js                  # Config aggregator
│   │   ├── database.js               # MongoDB connection
│   │   ├── env.js                    # Environment variables
│   │   ├── firebase.js               # Firebase Admin SDK
│   │   └── cors.js                   # CORS configuration
│   │
│   ├── constants/
│   │   ├── index.js
│   │   ├── error-codes.js            # Error code definitions
│   │   ├── roles.js                  # User role constants
│   │   └── status.js                 # Status enums
│   │
│   ├── controllers/
│   │   ├── auth.controller.js        # Authentication
│   │   ├── user.controller.js        # User management
│   │   ├── shop.controller.js        # Shop management
│   │   ├── customer.controller.js    # Customer CRUD
│   │   ├── ledger.controller.js      # Ledger entries
│   │   ├── product.controller.js     # Inventory/Products
│   │   ├── reminder.controller.js    # Reminders
│   │   ├── report.controller.js      # Reports & Analytics
│   │   ├── sync.controller.js        # Offline sync
│   │   ├── notification.controller.js # Push notifications
│   │   └── upload.controller.js      # File uploads
│   │
│   ├── middleware/
│   │   ├── auth.middleware.js        # JWT verification
│   │   ├── role.middleware.js        # Role-based access
│   │   ├── shop.middleware.js        # Shop context
│   │   ├── validate.middleware.js    # Request validation
│   │   ├── error.middleware.js       # Error handling
│   │   ├── rateLimit.middleware.js   # Rate limiting
│   │   └── upload.middleware.js      # Multer config
│   │
│   ├── models/
│   │   ├── index.js                  # Model exports
│   │   ├── User.model.js
│   │   ├── Shop.model.js
│   │   ├── Customer.model.js
│   │   ├── LedgerEntry.model.js
│   │   ├── Product.model.js
│   │   ├── InventoryTransaction.model.js
│   │   ├── Reminder.model.js
│   │   ├── RefreshToken.model.js
│   │   ├── FCMToken.model.js
│   │   └── SyncQueue.model.js
│   │
│   ├── routes/
│   │   ├── index.js                  # Route aggregator
│   │   ├── auth.routes.js
│   │   ├── user.routes.js
│   │   ├── shop.routes.js
│   │   ├── customer.routes.js
│   │   ├── ledger.routes.js
│   │   ├── product.routes.js
│   │   ├── reminder.routes.js
│   │   ├── report.routes.js
│   │   ├── sync.routes.js
│   │   ├── notification.routes.js
│   │   └── upload.routes.js
│   │
│   ├── services/
│   │   ├── auth.service.js           # Auth business logic
│   │   ├── user.service.js
│   │   ├── shop.service.js
│   │   ├── customer.service.js
│   │   ├── ledger.service.js
│   │   ├── product.service.js
│   │   ├── inventory.service.js
│   │   ├── reminder.service.js
│   │   ├── report.service.js
│   │   ├── sync.service.js
│   │   ├── notification.service.js   # FCM service
│   │   ├── pdf.service.js            # PDF generation
│   │   └── upload.service.js         # Cloud storage
│   │
│   ├── validators/
│   │   ├── auth.validator.js
│   │   ├── user.validator.js
│   │   ├── shop.validator.js
│   │   ├── customer.validator.js
│   │   ├── ledger.validator.js
│   │   ├── product.validator.js
│   │   ├── reminder.validator.js
│   │   └── common.validator.js
│   │
│   ├── utils/
│   │   ├── response.util.js          # API response helper
│   │   ├── pagination.util.js        # Pagination helper
│   │   ├── token.util.js             # JWT utilities
│   │   ├── hash.util.js              # Password hashing
│   │   ├── date.util.js              # Date formatting
│   │   ├── risk-score.util.js        # Credit scoring
│   │   ├── receipt.util.js           # Receipt number gen
│   │   └── logger.util.js            # Winston logger
│   │
│   └── jobs/
│       ├── index.js                  # Cron job scheduler
│       ├── reminder.job.js           # Auto reminder job
│       ├── risk-update.job.js        # Risk score update
│       ├── stats-update.job.js       # Dashboard stats cache
│       └── cleanup.job.js            # Token cleanup
│
├── tests/
│   ├── unit/
│   │   ├── services/
│   │   ├── utils/
│   │   └── validators/
│   ├── integration/
│   │   ├── auth.test.js
│   │   ├── customer.test.js
│   │   └── ledger.test.js
│   └── fixtures/
│       └── test-data.js
│
├── scripts/
│   ├── seed.js                       # Database seeding
│   ├── migrate.js                    # Migrations
│   └── generate-docs.js              # API docs generation
│
├── docs/
│   └── swagger.json                  # OpenAPI spec
│
├── .env.example                      # Environment template
├── .env.development
├── .env.production
├── .gitignore
├── package.json
├── nodemon.json
├── jest.config.js
├── Dockerfile
├── docker-compose.yml
└── README.md
```

---

## 📦 Package.json Dependencies

```json
{
  "name": "khatasetu-backend",
  "version": "1.0.0",
  "description": "KhataSetu Backend API",
  "main": "src/server.js",
  "scripts": {
    "start": "node src/server.js",
    "dev": "nodemon src/server.js",
    "test": "jest --coverage",
    "test:watch": "jest --watch",
    "lint": "eslint src/",
    "seed": "node scripts/seed.js",
    "docs": "node scripts/generate-docs.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "mongoose": "^8.0.3",
    "jsonwebtoken": "^9.0.2",
    "bcryptjs": "^2.4.3",
    "cors": "^2.8.5",
    "helmet": "^7.1.0",
    "morgan": "^1.10.0",
    "dotenv": "^16.3.1",
    "joi": "^17.11.0",
    "express-rate-limit": "^7.1.5",
    "node-cron": "^3.0.3",
    "firebase-admin": "^12.0.0",
    "multer": "^1.4.5-lts.1",
    "cloudinary": "^1.41.1",
    "pdfkit": "^0.14.0",
    "winston": "^3.11.0",
    "uuid": "^9.0.1",
    "dayjs": "^1.11.10"
  },
  "devDependencies": {
    "nodemon": "^3.0.2",
    "jest": "^29.7.0",
    "supertest": "^6.3.3",
    "eslint": "^8.56.0",
    "mongodb-memory-server": "^9.1.4"
  }
}
```

---

## 🔧 Environment Variables (.env.example)

```env
# Server
NODE_ENV=development
PORT=3000
API_PREFIX=/api/v1

# MongoDB
MONGODB_URI=mongodb://localhost:27017/khatasetu_dev

# JWT
JWT_SECRET=your-super-secret-jwt-key-min-32-chars
JWT_ACCESS_EXPIRY=15m
JWT_REFRESH_EXPIRY=7d

# Firebase
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY=your-private-key
FIREBASE_CLIENT_EMAIL=your-client-email

# Cloudinary (for file uploads)
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_API_KEY=your-api-key
CLOUDINARY_API_SECRET=your-api-secret

# Rate Limiting
RATE_LIMIT_WINDOW_MS=60000
RATE_LIMIT_MAX_REQUESTS=100

# Logging
LOG_LEVEL=debug

# Frontend URL (for CORS)
FRONTEND_URL=http://localhost:3001
```
