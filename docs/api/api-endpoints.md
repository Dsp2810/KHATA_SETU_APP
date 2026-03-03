# KhataSetu - API Endpoints Documentation

## 📡 API Overview

**Base URL:** `https://api.khatasetu.com/v1`

**Authentication:** Bearer Token (JWT)

**Content-Type:** `application/json`

---

## 🔐 Authentication APIs

### 1. Register User
```http
POST /auth/register
```

**Request Body:**
```json
{
  "name": "Ramesh Patel",
  "phone": "9876543210",
  "password": "SecurePass@123",
  "role": "shopkeeper"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Registration successful",
  "data": {
    "user": {
      "id": "64a7b8c9d0e1f2a3b4c5d6e7",
      "name": "Ramesh Patel",
      "phone": "9876543210",
      "role": "shopkeeper"
    },
    "tokens": {
      "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "expiresIn": 900
    }
  }
}
```

---

### 2. Login
```http
POST /auth/login
```

**Request Body:**
```json
{
  "phone": "9876543210",
  "password": "SecurePass@123"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "id": "64a7b8c9d0e1f2a3b4c5d6e7",
      "name": "Ramesh Patel",
      "phone": "9876543210",
      "role": "shopkeeper",
      "shops": [
        {
          "id": "64a7b8c9d0e1f2a3b4c5d6e8",
          "name": "Ramesh General Store",
          "code": "SHP001"
        }
      ],
      "activeShopId": "64a7b8c9d0e1f2a3b4c5d6e8"
    },
    "tokens": {
      "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "expiresIn": 900
    }
  }
}
```

---

### 3. Refresh Token
```http
POST /auth/refresh
```

**Request Body:**
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiresIn": 900
  }
}
```

---

### 4. Logout
```http
POST /auth/logout
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

---

### 5. Forgot Password - Send OTP
```http
POST /auth/forgot-password
```

**Request Body:**
```json
{
  "phone": "9876543210"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "OTP sent successfully",
  "data": {
    "otpToken": "temp_token_for_verification"
  }
}
```

---

### 6. Reset Password
```http
POST /auth/reset-password
```

**Request Body:**
```json
{
  "otpToken": "temp_token_for_verification",
  "otp": "123456",
  "newPassword": "NewSecurePass@123"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Password reset successfully"
}
```

---

## 👤 User APIs

### 7. Get Current User Profile
```http
GET /users/me
Authorization: Bearer <access_token>
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "64a7b8c9d0e1f2a3b4c5d6e7",
    "name": "Ramesh Patel",
    "phone": "9876543210",
    "email": "ramesh@email.com",
    "avatar": "https://storage.khatasetu.com/avatars/user123.jpg",
    "role": "shopkeeper",
    "preferences": {
      "language": "en",
      "darkMode": false,
      "notificationsEnabled": true
    },
    "shops": [...],
    "activeShopId": "64a7b8c9d0e1f2a3b4c5d6e8"
  }
}
```

---

### 8. Update User Profile
```http
PUT /users/me
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "name": "Ramesh K. Patel",
  "email": "ramesh.patel@email.com",
  "preferences": {
    "language": "gu",
    "darkMode": true
  }
}
```

---

### 9. Change Password
```http
PUT /users/me/password
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "currentPassword": "OldPass@123",
  "newPassword": "NewPass@456"
}
```

---

### 10. Switch Active Shop
```http
PUT /users/me/active-shop
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "shopId": "64a7b8c9d0e1f2a3b4c5d6e9"
}
```

---

## 🏪 Shop APIs

### 11. Create Shop
```http
POST /shops
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "name": "Ramesh General Store",
  "type": "grocery",
  "phone": "9876543210",
  "address": {
    "street": "Main Market",
    "village": "Modhera",
    "district": "Mehsana",
    "state": "Gujarat",
    "pincode": "384212"
  }
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Shop created successfully",
  "data": {
    "id": "64a7b8c9d0e1f2a3b4c5d6e8",
    "name": "Ramesh General Store",
    "code": "SHP001",
    "type": "grocery",
    ...
  }
}
```

---

### 12. Get All Shops
```http
GET /shops
Authorization: Bearer <access_token>
```

---

### 13. Get Shop Details
```http
GET /shops/:shopId
Authorization: Bearer <access_token>
```

---

### 14. Update Shop
```http
PUT /shops/:shopId
Authorization: Bearer <access_token>
```

---

### 15. Update Shop Settings
```http
PUT /shops/:shopId/settings
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "autoReminderEnabled": true,
  "reminderAfterDays": 15,
  "defaultCreditLimit": 10000,
  "interestEnabled": false
}
```

---

### 16. Update UPI Settings
```http
PUT /shops/:shopId/upi-settings
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "upiId": "ramesh@paytm",
  "merchantName": "Ramesh General Store",
  "qrCodeUrl": "https://storage.khatasetu.com/qr/shop123.jpg"
}
```

---

### 17. Get Shop Dashboard Stats
```http
GET /shops/:shopId/dashboard
Authorization: Bearer <access_token>
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "totalPendingAmount": 45000,
    "todayCollection": 5200,
    "todayCredit": 3500,
    "monthlyRevenue": [
      { "date": "2026-02-01", "credit": 5000, "collection": 3000 },
      { "date": "2026-02-02", "credit": 4500, "collection": 6000 },
      ...
    ],
    "lowStockAlerts": [
      { "productId": "...", "name": "Rice 25kg", "currentStock": 5, "minThreshold": 10 }
    ],
    "topDefaulters": [
      { "customerId": "...", "name": "Suresh", "balance": 12000, "daysOverdue": 45 }
    ],
    "customerCount": 150,
    "activeCustomers": 35
  }
}
```

---

## 👥 Customer APIs

### 18. Create Customer
```http
POST /shops/:shopId/customers
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "name": "Suresh Sharma",
  "phone": "9876543211",
  "email": "suresh@email.com",
  "address": {
    "village": "Modhera",
    "district": "Mehsana"
  },
  "creditLimit": 15000,
  "notes": "Regular customer, pays on time"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Customer created successfully",
  "data": {
    "id": "64a7b8c9d0e1f2a3b4c5d6e9",
    "name": "Suresh Sharma",
    "phone": "9876543211",
    "currentBalance": 0,
    "creditLimit": 15000,
    "riskScore": 0,
    ...
  }
}
```

---

### 19. Get All Customers
```http
GET /shops/:shopId/customers
Authorization: Bearer <access_token>
```

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| page | number | Page number (default: 1) |
| limit | number | Items per page (default: 20) |
| search | string | Search by name or phone |
| filter | string | 'all', 'due', 'clear', 'risky' |
| sortBy | string | 'name', 'balance', 'riskScore', 'lastTransaction' |
| sortOrder | string | 'asc', 'desc' |

**Response (200):**
```json
{
  "success": true,
  "data": {
    "customers": [...],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 150,
      "totalPages": 8
    }
  }
}
```

---

### 20. Get Customer Details
```http
GET /shops/:shopId/customers/:customerId
Authorization: Bearer <access_token>
```

---

### 21. Update Customer
```http
PUT /shops/:shopId/customers/:customerId
Authorization: Bearer <access_token>
```

---

### 22. Delete Customer
```http
DELETE /shops/:shopId/customers/:customerId
Authorization: Bearer <access_token>
```

---

### 23. Get Customer Ledger
```http
GET /shops/:shopId/customers/:customerId/ledger
Authorization: Bearer <access_token>
```

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| page | number | Page number |
| limit | number | Items per page |
| type | string | 'all', 'credit', 'debit' |
| startDate | date | Filter from date |
| endDate | date | Filter to date |

---

## 📝 Ledger Entry APIs

### 24. Create Credit Entry
```http
POST /shops/:shopId/ledger/credit
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "customerId": "64a7b8c9d0e1f2a3b4c5d6e9",
  "amount": 500,
  "transactionDate": "2026-02-27T10:30:00Z",
  "description": "Monthly grocery",
  "items": [
    {
      "productId": "64a7b8c9d0e1f2a3b4c5d6f1",
      "quantity": 2,
      "unitPrice": 150,
      "totalPrice": 300
    },
    {
      "productId": "64a7b8c9d0e1f2a3b4c5d6f2",
      "quantity": 1,
      "unitPrice": 200,
      "totalPrice": 200
    }
  ]
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Credit entry created",
  "data": {
    "id": "64a7b8c9d0e1f2a3b4c5d6fa",
    "type": "credit",
    "amount": 500,
    "runningBalance": 12500,
    "receiptNumber": "SHP001-202602-0125",
    "items": [...],
    ...
  }
}
```

---

### 25. Create Payment Entry (Debit)
```http
POST /shops/:shopId/ledger/debit
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "customerId": "64a7b8c9d0e1f2a3b4c5d6e9",
  "amount": 2000,
  "transactionDate": "2026-02-27T11:00:00Z",
  "paymentMode": "upi",
  "paymentReference": "UPI123456789",
  "description": "Partial payment"
}
```

---

### 26. Get Transaction Details
```http
GET /shops/:shopId/ledger/:entryId
Authorization: Bearer <access_token>
```

---

### 27. Update Transaction
```http
PUT /shops/:shopId/ledger/:entryId
Authorization: Bearer <access_token>
```

---

### 28. Delete Transaction
```http
DELETE /shops/:shopId/ledger/:entryId
Authorization: Bearer <access_token>
```

---

### 29. Get All Transactions (Shop-wide)
```http
GET /shops/:shopId/ledger
Authorization: Bearer <access_token>
```

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| page | number | Page number |
| limit | number | Items per page |
| type | string | 'all', 'credit', 'debit' |
| customerId | string | Filter by customer |
| startDate | date | Filter from date |
| endDate | date | Filter to date |

---

## 📦 Product/Inventory APIs

### 30. Create Product
```http
POST /shops/:shopId/products
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "name": "Rice Basmati 25kg",
  "category": "grocery",
  "barcode": "8901234567890",
  "purchasePrice": 800,
  "sellingPrice": 900,
  "currentStock": 15,
  "minStockThreshold": 10,
  "unit": "piece"
}
```

---

### 31. Get All Products
```http
GET /shops/:shopId/products
Authorization: Bearer <access_token>
```

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| page | number | Page number |
| limit | number | Items per page |
| search | string | Search by name |
| category | string | Filter by category |
| stockStatus | string | 'all', 'low_stock', 'out_of_stock' |

---

### 32. Get Product Details
```http
GET /shops/:shopId/products/:productId
Authorization: Bearer <access_token>
```

---

### 33. Update Product
```http
PUT /shops/:shopId/products/:productId
Authorization: Bearer <access_token>
```

---

### 34. Delete Product
```http
DELETE /shops/:shopId/products/:productId
Authorization: Bearer <access_token>
```

---

### 35. Adjust Stock
```http
POST /shops/:shopId/products/:productId/adjust-stock
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "type": "add",  // or "remove"
  "quantity": 10,
  "reason": "New stock purchase"
}
```

---

### 36. Get Product History
```http
GET /shops/:shopId/products/:productId/history
Authorization: Bearer <access_token>
```

---

### 37. Search Product by Barcode
```http
GET /shops/:shopId/products/barcode/:barcode
Authorization: Bearer <access_token>
```

---

## 🔔 Reminder APIs

### 38. Get All Reminders
```http
GET /shops/:shopId/reminders
Authorization: Bearer <access_token>
```

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| status | string | 'pending', 'sent', 'all' |
| customerId | string | Filter by customer |

---

### 39. Send Manual Reminder
```http
POST /shops/:shopId/reminders
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "customerId": "64a7b8c9d0e1f2a3b4c5d6e9",
  "messageTemplate": "friendly",
  "channels": ["push", "whatsapp"]
}
```

---

### 40. Get Pending Reminder Suggestions
```http
GET /shops/:shopId/reminders/suggestions
Authorization: Bearer <access_token>
```

Returns customers who should receive reminders based on shop settings.

---

### 41. Update Reminder Settings
```http
PUT /shops/:shopId/reminders/settings
Authorization: Bearer <access_token>
```

---

## 📊 Reports APIs

### 42. Get Dashboard Report
```http
GET /shops/:shopId/reports/dashboard
Authorization: Bearer <access_token>
```

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| period | string | 'today', 'week', 'month', 'year', 'custom' |
| startDate | date | For custom period |
| endDate | date | For custom period |

---

### 43. Get Customer Report
```http
GET /shops/:shopId/reports/customers
Authorization: Bearer <access_token>
```

---

### 44. Get Inventory Report
```http
GET /shops/:shopId/reports/inventory
Authorization: Bearer <access_token>
```

---

### 45. Get Payment Heatmap
```http
GET /shops/:shopId/reports/payment-heatmap
Authorization: Bearer <access_token>
```

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| month | number | Month (1-12) |
| year | number | Year |

---

### 46. Download Ledger PDF
```http
GET /shops/:shopId/reports/ledger-pdf
Authorization: Bearer <access_token>
```

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| customerId | string | Optional - specific customer |
| startDate | date | Start date |
| endDate | date | End date |

Returns PDF file.

---

### 47. Export Data (CSV)
```http
GET /shops/:shopId/reports/export
Authorization: Bearer <access_token>
```

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| type | string | 'customers', 'ledger', 'inventory', 'all' |
| format | string | 'csv', 'json' |

---

## 🔄 Sync APIs

### 48. Sync Offline Data
```http
POST /sync
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "shopId": "64a7b8c9d0e1f2a3b4c5d6e8",
  "operations": [
    {
      "localId": "uuid-1",
      "operation": "create",
      "collection": "ledger_entries",
      "data": {...},
      "clientTimestamp": "2026-02-27T10:30:00Z"
    },
    {
      "localId": "uuid-2",
      "operation": "update",
      "collection": "customers",
      "documentId": "64a7b8c9d0e1f2a3b4c5d6e9",
      "data": {...},
      "clientTimestamp": "2026-02-27T10:35:00Z"
    }
  ]
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "synced": [
      { "localId": "uuid-1", "serverId": "64a7b8c9d0e1f2a3b4c5d6fa", "status": "synced" },
      { "localId": "uuid-2", "serverId": "64a7b8c9d0e1f2a3b4c5d6e9", "status": "synced" }
    ],
    "conflicts": [],
    "failed": []
  }
}
```

---

### 49. Get Sync Status
```http
GET /sync/status
Authorization: Bearer <access_token>
```

---

### 50. Resolve Conflict
```http
POST /sync/resolve-conflict
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "localId": "uuid-1",
  "resolution": "client_wins"  // or "server_wins"
}
```

---

## 🔔 Notification APIs

### 51. Register FCM Token
```http
POST /notifications/fcm-token
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "token": "fcm_token_string",
  "deviceInfo": {
    "deviceId": "device-123",
    "platform": "android",
    "appVersion": "1.0.0"
  }
}
```

---

### 52. Get Notifications
```http
GET /notifications
Authorization: Bearer <access_token>
```

---

### 53. Mark Notification as Read
```http
PUT /notifications/:notificationId/read
Authorization: Bearer <access_token>
```

---

## 📁 File Upload APIs

### 54. Upload Image
```http
POST /uploads/image
Authorization: Bearer <access_token>
Content-Type: multipart/form-data
```

**Form Data:**
- `file`: Image file
- `type`: 'avatar', 'logo', 'qr', 'product'

**Response (200):**
```json
{
  "success": true,
  "data": {
    "url": "https://storage.khatasetu.com/uploads/image123.jpg",
    "thumbnail": "https://storage.khatasetu.com/uploads/thumb_image123.jpg"
  }
}
```

---

## ❌ Error Response Format

All error responses follow this format:

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed",
    "details": [
      {
        "field": "phone",
        "message": "Invalid phone number format"
      }
    ]
  }
}
```

### Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| VALIDATION_ERROR | 400 | Input validation failed |
| UNAUTHORIZED | 401 | Not authenticated |
| FORBIDDEN | 403 | Not authorized for action |
| NOT_FOUND | 404 | Resource not found |
| CONFLICT | 409 | Resource conflict (duplicate) |
| RATE_LIMITED | 429 | Too many requests |
| INTERNAL_ERROR | 500 | Server error |

---

## 📋 API Summary Table

| # | Method | Endpoint | Description | Auth |
|---|--------|----------|-------------|------|
| 1 | POST | /auth/register | Register new user | No |
| 2 | POST | /auth/login | User login | No |
| 3 | POST | /auth/refresh | Refresh access token | No |
| 4 | POST | /auth/logout | User logout | Yes |
| 5-6 | POST | /auth/forgot-password, /auth/reset-password | Password recovery | No |
| 7-10 | GET/PUT | /users/me/* | User profile management | Yes |
| 11-17 | ALL | /shops/* | Shop management | Yes |
| 18-23 | ALL | /shops/:id/customers/* | Customer management | Yes |
| 24-29 | ALL | /shops/:id/ledger/* | Ledger entries | Yes |
| 30-37 | ALL | /shops/:id/products/* | Inventory management | Yes |
| 38-41 | ALL | /shops/:id/reminders/* | Reminder management | Yes |
| 42-47 | GET | /shops/:id/reports/* | Reports & analytics | Yes |
| 48-50 | ALL | /sync/* | Offline sync | Yes |
| 51-53 | ALL | /notifications/* | Push notifications | Yes |
| 54 | POST | /uploads/image | File uploads | Yes |

**Total Endpoints: 54**
