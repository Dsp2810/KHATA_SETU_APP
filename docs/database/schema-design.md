# KhataSetu - Database Schema Design

## 📊 MongoDB Collections Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        DATABASE: khatasetu_db                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Collections:                                                               │
│  ├── users                    (User accounts & authentication)             │
│  ├── shops                    (Shop/Business profiles)                     │
│  ├── customers                (Customer records per shop)                  │
│  ├── ledger_entries           (Credit & Debit transactions)               │
│  ├── products                 (Inventory items)                           │
│  ├── inventory_transactions   (Stock movements)                           │
│  ├── reminders                (Payment reminders)                         │
│  ├── refresh_tokens           (JWT refresh tokens)                        │
│  ├── fcm_tokens               (Firebase Cloud Messaging tokens)           │
│  └── sync_queue               (Offline sync queue)                        │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 📋 Collection Schemas

### 1. Users Collection

**Purpose:** Store user account information and authentication data

```javascript
// Collection: users
{
  _id: ObjectId,
  
  // Basic Info
  name: {
    type: String,
    required: true,
    trim: true,
    minLength: 2,
    maxLength: 100
  },
  
  phone: {
    type: String,
    required: true,
    unique: true,
    match: /^[6-9]\d{9}$/  // Indian mobile number
  },
  
  email: {
    type: String,
    lowercase: true,
    trim: true,
    sparse: true  // Optional but unique if provided
  },
  
  password: {
    type: String,
    required: true,
    minLength: 8
    // Stored as bcrypt hash
  },
  
  // Profile
  avatar: {
    type: String,  // URL to profile image
    default: null
  },
  
  // Role & Permissions
  role: {
    type: String,
    enum: ['shopkeeper', 'customer', 'admin'],
    default: 'shopkeeper'
  },
  
  // Multi-shop support (for shopkeeper role)
  shops: [{
    type: ObjectId,
    ref: 'Shop'
  }],
  
  // For customer role - linked to which shops
  linkedToShops: [{
    shop: { type: ObjectId, ref: 'Shop' },
    customerId: { type: ObjectId, ref: 'Customer' }
  }],
  
  activeShopId: {
    type: ObjectId,
    ref: 'Shop',
    default: null
  },
  
  // Settings
  preferences: {
    language: {
      type: String,
      enum: ['en', 'gu', 'hi'],
      default: 'en'
    },
    darkMode: {
      type: Boolean,
      default: false
    },
    notificationsEnabled: {
      type: Boolean,
      default: true
    }
  },
  
  // Biometric
  biometricEnabled: {
    type: Boolean,
    default: false
  },
  
  // Status
  isActive: {
    type: Boolean,
    default: true
  },
  
  isVerified: {
    type: Boolean,
    default: false
  },
  
  lastLogin: {
    type: Date,
    default: null
  },
  
  // Timestamps
  createdAt: {
    type: Date,
    default: Date.now
  },
  
  updatedAt: {
    type: Date,
    default: Date.now
  }
}

// Indexes
users.createIndex({ phone: 1 }, { unique: true });
users.createIndex({ email: 1 }, { sparse: true, unique: true });
users.createIndex({ role: 1 });
```

---

### 2. Shops Collection

**Purpose:** Store shop/business information

```javascript
// Collection: shops
{
  _id: ObjectId,
  
  // Owner
  ownerId: {
    type: ObjectId,
    ref: 'User',
    required: true
  },
  
  // Basic Info
  name: {
    type: String,
    required: true,
    trim: true,
    maxLength: 200
  },
  
  code: {
    type: String,
    unique: true,
    uppercase: true
    // Auto-generated: e.g., "SHP001"
  },
  
  type: {
    type: String,
    enum: ['grocery', 'hardware', 'medical', 'clothing', 'electronics', 'other'],
    default: 'grocery'
  },
  
  // Contact
  phone: {
    type: String,
    match: /^[6-9]\d{9}$/
  },
  
  email: {
    type: String,
    lowercase: true
  },
  
  // Address
  address: {
    street: String,
    village: String,
    district: String,
    state: {
      type: String,
      default: 'Gujarat'
    },
    pincode: {
      type: String,
      match: /^\d{6}$/
    }
  },
  
  // Branding
  logo: {
    type: String,  // URL
    default: null
  },
  
  tagline: {
    type: String,
    maxLength: 200
  },
  
  // UPI Settings
  upiSettings: {
    upiId: {
      type: String,
      match: /^[\w.-]+@[\w]+$/
    },
    merchantName: String,
    qrCodeUrl: String  // Uploaded QR image URL
  },
  
  // Business Settings
  settings: {
    // Reminder settings
    autoReminderEnabled: {
      type: Boolean,
      default: true
    },
    reminderAfterDays: {
      type: Number,
      default: 15
    },
    reminderRepeatDays: {
      type: Number,
      default: 7
    },
    maxRemindersPerCustomer: {
      type: Number,
      default: 3
    },
    
    // Credit settings
    defaultCreditLimit: {
      type: Number,
      default: 10000
    },
    
    // Interest settings (optional)
    interestEnabled: {
      type: Boolean,
      default: false
    },
    interestRate: {
      type: Number,  // Percentage per month
      default: 0
    },
    interestAfterDays: {
      type: Number,
      default: 30
    }
  },
  
  // Statistics (cached, updated via aggregation)
  stats: {
    totalCustomers: {
      type: Number,
      default: 0
    },
    totalPendingAmount: {
      type: Number,
      default: 0
    },
    totalProducts: {
      type: Number,
      default: 0
    },
    inventoryValue: {
      type: Number,
      default: 0
    },
    lastUpdated: Date
  },
  
  // Status
  isActive: {
    type: Boolean,
    default: true
  },
  
  // Timestamps
  createdAt: {
    type: Date,
    default: Date.now
  },
  
  updatedAt: {
    type: Date,
    default: Date.now
  }
}

// Indexes
shops.createIndex({ ownerId: 1 });
shops.createIndex({ code: 1 }, { unique: true });
shops.createIndex({ 'address.pincode': 1 });
```

---

### 3. Customers Collection

**Purpose:** Store customer information for each shop

```javascript
// Collection: customers
{
  _id: ObjectId,
  
  // Shop Reference
  shopId: {
    type: ObjectId,
    ref: 'Shop',
    required: true
  },
  
  // Linked User (if customer has app account)
  linkedUserId: {
    type: ObjectId,
    ref: 'User',
    default: null
  },
  
  // Basic Info
  name: {
    type: String,
    required: true,
    trim: true,
    maxLength: 100
  },
  
  phone: {
    type: String,
    required: true,
    match: /^[6-9]\d{9}$/
  },
  
  email: {
    type: String,
    lowercase: true,
    default: null
  },
  
  // Address
  address: {
    street: String,
    village: String,
    district: String,
    state: String,
    pincode: String
  },
  
  // Profile
  avatar: String,
  
  // Credit Settings
  creditLimit: {
    type: Number,
    required: true,
    default: 10000
  },
  
  // Calculated Fields (updated on each transaction)
  currentBalance: {
    type: Number,
    default: 0
    // Positive = customer owes, Negative = shop owes
  },
  
  totalCredit: {
    type: Number,
    default: 0
  },
  
  totalPayments: {
    type: Number,
    default: 0
  },
  
  // Last Activity
  lastTransactionDate: {
    type: Date,
    default: null
  },
  
  lastPaymentDate: {
    type: Date,
    default: null
  },
  
  // Risk Assessment
  riskScore: {
    type: Number,
    min: 0,
    max: 100,
    default: 0
    // 0-30: Low Risk (Green)
    // 31-60: Medium Risk (Yellow)
    // 61-100: High Risk (Red)
  },
  
  riskFactors: {
    avgPaymentDelay: Number,  // Average days to pay
    overdueCount: Number,     // Number of overdue transactions
    defaultCount: Number,     // Number of defaults
    creditUtilization: Number // Percentage of limit used
  },
  
  // Due Days Tracking
  oldestUnpaidDate: {
    type: Date,
    default: null
  },
  
  daysOverdue: {
    type: Number,
    default: 0
  },
  
  // Reminder Tracking
  lastReminderSent: {
    type: Date,
    default: null
  },
  
  remindersSentCount: {
    type: Number,
    default: 0
  },
  
  // Notes
  notes: {
    type: String,
    maxLength: 1000
  },
  
  // Tags for filtering
  tags: [{
    type: String,
    trim: true
  }],
  
  // Status
  isActive: {
    type: Boolean,
    default: true
  },
  
  // Timestamps
  createdAt: {
    type: Date,
    default: Date.now
  },
  
  updatedAt: {
    type: Date,
    default: Date.now
  }
}

// Indexes
customers.createIndex({ shopId: 1, phone: 1 }, { unique: true });
customers.createIndex({ shopId: 1, name: 'text' });
customers.createIndex({ shopId: 1, currentBalance: -1 });
customers.createIndex({ shopId: 1, riskScore: -1 });
customers.createIndex({ shopId: 1, daysOverdue: -1 });
customers.createIndex({ linkedUserId: 1 });
```

---

### 4. Ledger Entries Collection

**Purpose:** Store all credit and payment transactions

```javascript
// Collection: ledger_entries
{
  _id: ObjectId,
  
  // References
  shopId: {
    type: ObjectId,
    ref: 'Shop',
    required: true
  },
  
  customerId: {
    type: ObjectId,
    ref: 'Customer',
    required: true
  },
  
  // Transaction Type
  type: {
    type: String,
    enum: ['credit', 'debit'],  // credit = udhar, debit = payment
    required: true
  },
  
  // Amount
  amount: {
    type: Number,
    required: true,
    min: 0.01
  },
  
  // Running Balance (after this transaction)
  runningBalance: {
    type: Number,
    required: true
  },
  
  // For credit entries - linked items
  items: [{
    productId: {
      type: ObjectId,
      ref: 'Product'
    },
    productName: String,  // Denormalized for history
    quantity: Number,
    unitPrice: Number,
    totalPrice: Number
  }],
  
  // For debit entries - payment details
  paymentMode: {
    type: String,
    enum: ['cash', 'upi', 'bank', 'cheque', 'other'],
    default: 'cash'
  },
  
  paymentReference: {
    type: String,  // UPI transaction ID, cheque number, etc.
    default: null
  },
  
  // Date
  transactionDate: {
    type: Date,
    required: true,
    default: Date.now
  },
  
  // Description
  description: {
    type: String,
    maxLength: 500
  },
  
  // Interest (if applicable)
  interest: {
    principal: Number,
    interestAmount: Number,
    rate: Number,
    fromDate: Date,
    toDate: Date
  },
  
  // Sync Status (for offline)
  syncStatus: {
    type: String,
    enum: ['synced', 'pending', 'failed'],
    default: 'synced'
  },
  
  localId: {
    type: String,  // UUID generated on client for offline entries
    default: null
  },
  
  // Receipt
  receiptNumber: {
    type: String,
    unique: true,
    sparse: true
    // Format: SHP001-202602-0001
  },
  
  // Created By
  createdBy: {
    type: ObjectId,
    ref: 'User',
    required: true
  },
  
  // Soft Delete
  isDeleted: {
    type: Boolean,
    default: false
  },
  
  deletedAt: Date,
  deletedBy: ObjectId,
  
  // Timestamps
  createdAt: {
    type: Date,
    default: Date.now
  },
  
  updatedAt: {
    type: Date,
    default: Date.now
  }
}

// Indexes
ledger_entries.createIndex({ shopId: 1, customerId: 1, transactionDate: -1 });
ledger_entries.createIndex({ shopId: 1, transactionDate: -1 });
ledger_entries.createIndex({ customerId: 1, transactionDate: -1 });
ledger_entries.createIndex({ shopId: 1, type: 1, transactionDate: -1 });
ledger_entries.createIndex({ receiptNumber: 1 }, { unique: true, sparse: true });
ledger_entries.createIndex({ localId: 1 }, { sparse: true });
ledger_entries.createIndex({ syncStatus: 1 });
```

---

### 5. Products Collection

**Purpose:** Store inventory/product information

```javascript
// Collection: products
{
  _id: ObjectId,
  
  // Shop Reference
  shopId: {
    type: ObjectId,
    ref: 'Shop',
    required: true
  },
  
  // Basic Info
  name: {
    type: String,
    required: true,
    trim: true,
    maxLength: 200
  },
  
  description: {
    type: String,
    maxLength: 1000
  },
  
  // Category
  category: {
    type: String,
    enum: [
      'grocery', 'dairy', 'beverages', 'snacks', 'personal_care',
      'household', 'medicines', 'stationery', 'hardware', 'other'
    ],
    default: 'grocery'
  },
  
  // Identification
  barcode: {
    type: String,
    sparse: true
  },
  
  sku: {
    type: String,  // Shop's internal code
    sparse: true
  },
  
  // Pricing
  purchasePrice: {
    type: Number,
    required: true,
    min: 0
  },
  
  sellingPrice: {
    type: Number,
    required: true,
    min: 0
  },
  
  mrp: {
    type: Number,  // Maximum Retail Price
    default: null
  },
  
  // Unit
  unit: {
    type: String,
    enum: ['piece', 'kg', 'gram', 'liter', 'ml', 'dozen', 'pack', 'box', 'other'],
    default: 'piece'
  },
  
  // Stock
  currentStock: {
    type: Number,
    required: true,
    default: 0
  },
  
  minStockThreshold: {
    type: Number,
    default: 10
  },
  
  maxStock: {
    type: Number,
    default: null
  },
  
  // Stock Status (calculated)
  stockStatus: {
    type: String,
    enum: ['in_stock', 'low_stock', 'out_of_stock'],
    default: 'in_stock'
  },
  
  // Value
  stockValue: {
    type: Number,  // currentStock * purchasePrice
    default: 0
  },
  
  // Image
  image: {
    type: String,  // URL
    default: null
  },
  
  // Tracking
  totalSold: {
    type: Number,
    default: 0
  },
  
  lastSoldDate: {
    type: Date,
    default: null
  },
  
  lastRestockDate: {
    type: Date,
    default: null
  },
  
  // Status
  isActive: {
    type: Boolean,
    default: true
  },
  
  // Timestamps
  createdAt: {
    type: Date,
    default: Date.now
  },
  
  updatedAt: {
    type: Date,
    default: Date.now
  }
}

// Indexes
products.createIndex({ shopId: 1, name: 'text' });
products.createIndex({ shopId: 1, barcode: 1 }, { sparse: true });
products.createIndex({ shopId: 1, category: 1 });
products.createIndex({ shopId: 1, stockStatus: 1 });
products.createIndex({ shopId: 1, currentStock: 1 });
```

---

### 6. Inventory Transactions Collection

**Purpose:** Track stock movements

```javascript
// Collection: inventory_transactions
{
  _id: ObjectId,
  
  // References
  shopId: {
    type: ObjectId,
    ref: 'Shop',
    required: true
  },
  
  productId: {
    type: ObjectId,
    ref: 'Product',
    required: true
  },
  
  // Transaction Type
  type: {
    type: String,
    enum: ['purchase', 'sale', 'adjustment', 'return', 'damage', 'transfer'],
    required: true
  },
  
  // Quantity
  quantity: {
    type: Number,
    required: true
    // Positive for additions, negative for deductions
  },
  
  previousStock: {
    type: Number,
    required: true
  },
  
  newStock: {
    type: Number,
    required: true
  },
  
  // Linked References
  ledgerEntryId: {
    type: ObjectId,
    ref: 'LedgerEntry',
    default: null  // For sales linked to credit entries
  },
  
  customerId: {
    type: ObjectId,
    ref: 'Customer',
    default: null
  },
  
  // Details
  unitPrice: {
    type: Number,
    default: null
  },
  
  totalValue: {
    type: Number,
    default: null
  },
  
  reason: {
    type: String,
    maxLength: 500
  },
  
  // Created By
  createdBy: {
    type: ObjectId,
    ref: 'User',
    required: true
  },
  
  // Timestamps
  createdAt: {
    type: Date,
    default: Date.now
  }
}

// Indexes
inventory_transactions.createIndex({ shopId: 1, productId: 1, createdAt: -1 });
inventory_transactions.createIndex({ shopId: 1, type: 1, createdAt: -1 });
inventory_transactions.createIndex({ ledgerEntryId: 1 });
```

---

### 7. Reminders Collection

**Purpose:** Track payment reminders

```javascript
// Collection: reminders
{
  _id: ObjectId,
  
  // References
  shopId: {
    type: ObjectId,
    ref: 'Shop',
    required: true
  },
  
  customerId: {
    type: ObjectId,
    ref: 'Customer',
    required: true
  },
  
  // Reminder Details
  type: {
    type: String,
    enum: ['manual', 'auto', 'smart'],
    default: 'manual'
  },
  
  // Amount at time of reminder
  amountDue: {
    type: Number,
    required: true
  },
  
  daysOverdue: {
    type: Number,
    default: 0
  },
  
  // Scheduling
  scheduledAt: {
    type: Date,
    default: null  // For scheduled reminders
  },
  
  sentAt: {
    type: Date,
    default: null
  },
  
  // Delivery Channels
  channels: {
    push: {
      sent: Boolean,
      sentAt: Date,
      delivered: Boolean,
      deliveredAt: Date,
      error: String
    },
    whatsapp: {
      sent: Boolean,
      sentAt: Date,
      delivered: Boolean,
      deliveredAt: Date,
      error: String
    },
    sms: {
      sent: Boolean,
      sentAt: Date,
      delivered: Boolean,
      deliveredAt: Date,
      error: String
    }
  },
  
  // Message
  messageTemplate: {
    type: String,
    enum: ['friendly', 'formal', 'urgent', 'custom'],
    default: 'friendly'
  },
  
  messageContent: {
    type: String,
    maxLength: 1000
  },
  
  // Status
  status: {
    type: String,
    enum: ['pending', 'sent', 'delivered', 'failed', 'cancelled'],
    default: 'pending'
  },
  
  // Response (if customer responded)
  customerResponse: {
    responded: Boolean,
    respondedAt: Date,
    action: String  // 'paid', 'promised', 'ignored'
  },
  
  // Created By
  createdBy: {
    type: ObjectId,
    ref: 'User',
    required: true
  },
  
  // Timestamps
  createdAt: {
    type: Date,
    default: Date.now
  },
  
  updatedAt: {
    type: Date,
    default: Date.now
  }
}

// Indexes
reminders.createIndex({ shopId: 1, customerId: 1, createdAt: -1 });
reminders.createIndex({ scheduledAt: 1, status: 1 });
reminders.createIndex({ status: 1 });
```

---

### 8. Refresh Tokens Collection

**Purpose:** Store JWT refresh tokens for secure authentication

```javascript
// Collection: refresh_tokens
{
  _id: ObjectId,
  
  userId: {
    type: ObjectId,
    ref: 'User',
    required: true
  },
  
  token: {
    type: String,
    required: true,
    unique: true
  },
  
  deviceInfo: {
    deviceId: String,
    deviceType: String,  // 'android', 'ios', 'web'
    deviceName: String,
    appVersion: String
  },
  
  ipAddress: String,
  
  expiresAt: {
    type: Date,
    required: true
  },
  
  isRevoked: {
    type: Boolean,
    default: false
  },
  
  revokedAt: Date,
  
  lastUsedAt: {
    type: Date,
    default: Date.now
  },
  
  createdAt: {
    type: Date,
    default: Date.now
  }
}

// Indexes
refresh_tokens.createIndex({ token: 1 }, { unique: true });
refresh_tokens.createIndex({ userId: 1 });
refresh_tokens.createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 });  // TTL index
```

---

### 9. FCM Tokens Collection

**Purpose:** Store Firebase Cloud Messaging tokens for push notifications

```javascript
// Collection: fcm_tokens
{
  _id: ObjectId,
  
  userId: {
    type: ObjectId,
    ref: 'User',
    required: true
  },
  
  token: {
    type: String,
    required: true
  },
  
  deviceInfo: {
    deviceId: String,
    platform: String,  // 'android', 'ios'
    appVersion: String
  },
  
  isActive: {
    type: Boolean,
    default: true
  },
  
  lastUsedAt: {
    type: Date,
    default: Date.now
  },
  
  createdAt: {
    type: Date,
    default: Date.now
  },
  
  updatedAt: {
    type: Date,
    default: Date.now
  }
}

// Indexes
fcm_tokens.createIndex({ userId: 1 });
fcm_tokens.createIndex({ token: 1 });
```

---

### 10. Sync Queue Collection

**Purpose:** Store offline operations pending sync

```javascript
// Collection: sync_queue
{
  _id: ObjectId,
  
  userId: {
    type: ObjectId,
    ref: 'User',
    required: true
  },
  
  shopId: {
    type: ObjectId,
    ref: 'Shop',
    required: true
  },
  
  // Operation Details
  operation: {
    type: String,
    enum: ['create', 'update', 'delete'],
    required: true
  },
  
  collection: {
    type: String,
    enum: ['customers', 'ledger_entries', 'products', 'inventory_transactions'],
    required: true
  },
  
  localId: {
    type: String,  // UUID from client
    required: true
  },
  
  data: {
    type: Object,  // The actual data to sync
    required: true
  },
  
  // Status
  status: {
    type: String,
    enum: ['pending', 'processing', 'synced', 'failed', 'conflict'],
    default: 'pending'
  },
  
  attempts: {
    type: Number,
    default: 0
  },
  
  lastAttemptAt: Date,
  
  error: String,
  
  // Conflict Resolution
  conflictData: {
    serverData: Object,
    resolution: String  // 'server_wins', 'client_wins', 'manual'
  },
  
  // Client timestamp (when action was performed offline)
  clientTimestamp: {
    type: Date,
    required: true
  },
  
  // Server timestamps
  createdAt: {
    type: Date,
    default: Date.now
  },
  
  syncedAt: Date
}

// Indexes
sync_queue.createIndex({ userId: 1, status: 1, clientTimestamp: 1 });
sync_queue.createIndex({ status: 1 });
sync_queue.createIndex({ localId: 1 });
```

---

## 🔗 Entity Relationship Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        ENTITY RELATIONSHIPS                                  │
└─────────────────────────────────────────────────────────────────────────────┘

    ┌──────────┐     1:N     ┌──────────┐     1:N     ┌──────────────┐
    │   USER   │────────────▶│   SHOP   │────────────▶│   CUSTOMER   │
    └──────────┘             └──────────┘             └──────────────┘
         │                        │                         │
         │                        │                         │
         │                   1:N  │                    1:N  │
         │                        ▼                         ▼
         │                  ┌──────────┐             ┌──────────────┐
         │                  │ PRODUCT  │             │LEDGER_ENTRY  │
         │                  └──────────┘             └──────────────┘
         │                        │                         │
         │                   1:N  │                         │
         │                        ▼                         │
         │                  ┌──────────────────┐            │
         │                  │ INVENTORY_TRANS  │◀───────────┘
         │                  └──────────────────┘
         │
         │     1:N     ┌──────────────┐
         └────────────▶│ REFRESH_TOKEN│
         │             └──────────────┘
         │
         │     1:N     ┌──────────────┐
         └────────────▶│  FCM_TOKEN   │
                       └──────────────┘


    CUSTOMER ─────1:N─────▶ REMINDER
    
    USER ─────1:N─────▶ SYNC_QUEUE
```

---

## 📊 Indexing Strategy

| Collection | Index | Type | Purpose |
|------------|-------|------|---------|
| users | phone | Unique | Login lookup |
| users | email | Sparse Unique | Email login |
| shops | ownerId | Regular | User's shops |
| shops | code | Unique | Shop lookup |
| customers | shopId + phone | Compound Unique | Prevent duplicates |
| customers | shopId + name | Text | Name search |
| customers | shopId + currentBalance | Compound | Sorting by balance |
| ledger_entries | shopId + customerId + date | Compound | Transaction history |
| products | shopId + name | Text | Product search |
| products | shopId + barcode | Sparse | Barcode lookup |
| reminders | scheduledAt + status | Compound | Cron job queries |
| refresh_tokens | expiresAt | TTL | Auto-cleanup |

---

## 🔒 Data Security Considerations

1. **Password Storage**: Bcrypt hash with salt rounds = 12
2. **Sensitive Fields**: Encrypt UPI IDs, bank details at rest
3. **Soft Delete**: Use `isDeleted` flag instead of hard delete
4. **Audit Trail**: Store `createdBy`, `updatedAt` for all records
5. **Data Isolation**: Always filter by `shopId` for multi-tenancy
