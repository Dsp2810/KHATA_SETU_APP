# KhataSetu - Screen-by-Screen UI Breakdown

## 📱 Complete Screen List

### Total Screens: 35+

---

## 🔐 Authentication Module (5 Screens)

### 1. Splash Screen
**Path:** `/splash`
**Purpose:** App initialization and authentication status check

```
┌─────────────────────────────────────┐
│                                     │
│                                     │
│                                     │
│            [LOGO]                   │
│          KhataSetu                  │
│                                     │
│     "आपका डिजिटल खाता साथी"         │
│                                     │
│         [Loading...]                │
│                                     │
│                                     │
│                                     │
│         Version 1.0.0               │
└─────────────────────────────────────┘
```

**Features:**
- App logo with fade-in animation
- Tagline in regional language
- Auto-redirect based on auth status
- Version display

---

### 2. Onboarding Screen
**Path:** `/onboarding`
**Purpose:** First-time user introduction (3 slides)

```
┌─────────────────────────────────────┐
│                                     │
│         [Illustration 1]           │
│                                     │
│      "डिजिटल उधार खाता"             │
│                                     │
│   Track all your credit entries     │
│   digitally without paper hassle    │
│                                     │
│                                     │
│           ●  ○  ○                   │
│                                     │
│    [Skip]            [Next →]       │
└─────────────────────────────────────┘
```

**Slides:**
1. Digital Ledger Introduction
2. UPI Payment Integration
3. Reports & Analytics

---

### 3. Login Screen
**Path:** `/login`
**Purpose:** User authentication

```
┌─────────────────────────────────────┐
│                                     │
│           [LOGO]                    │
│                                     │
│         Welcome Back!               │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  📱 Phone Number              │  │
│  │  +91 98765 43210              │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  🔒 Password                  │  │
│  │  ••••••••                     │  │
│  └───────────────────────────────┘  │
│                                     │
│       [Forgot Password?]            │
│                                     │
│  ┌───────────────────────────────┐  │
│  │          LOGIN                │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │   [Biometric Login Icon]      │  │
│  └───────────────────────────────┘  │
│                                     │
│   Don't have account? Register      │
└─────────────────────────────────────┘
```

**Features:**
- Phone number with country code
- Secure password field with toggle visibility
- Biometric login option
- Forgot password link
- Register navigation

---

### 4. Register Screen
**Path:** `/register`
**Purpose:** New user registration

```
┌─────────────────────────────────────┐
│  ←                                  │
│                                     │
│        Create Account               │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  👤 Full Name                 │  │
│  │  Ramesh Patel                 │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  📱 Phone Number              │  │
│  │  +91 98765 43210              │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  🔒 Password                  │  │
│  │  ••••••••                     │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  🔒 Confirm Password          │  │
│  │  ••••••••                     │  │
│  └───────────────────────────────┘  │
│                                     │
│  ☑ I agree to Terms & Conditions   │
│                                     │
│  ┌───────────────────────────────┐  │
│  │        REGISTER               │  │
│  └───────────────────────────────┘  │
│                                     │
│   Already have account? Login       │
└─────────────────────────────────────┘
```

---

### 5. Forgot Password Screen
**Path:** `/forgot-password`
**Purpose:** Password recovery via OTP

```
┌─────────────────────────────────────┐
│  ←                                  │
│                                     │
│        Forgot Password              │
│                                     │
│   Enter your phone number and       │
│   we'll send you OTP to reset       │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  📱 Phone Number              │  │
│  │  +91 98765 43210              │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │        SEND OTP               │  │
│  └───────────────────────────────┘  │
│                                     │
│                                     │
└─────────────────────────────────────┘
```

---

## 🏠 Dashboard Module (3 Screens)

### 6. Shopkeeper Dashboard
**Path:** `/dashboard`
**Purpose:** Main overview screen for shopkeepers

```
┌─────────────────────────────────────┐
│  ☰  KhataSetu        [Shop ▼] 🔔   │
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────────┐│
│  │  Welcome, Ramesh!               ││
│  │  Today: 27 Feb 2026             ││
│  └─────────────────────────────────┘│
│                                     │
│  ┌────────────┐  ┌────────────┐    │
│  │ ₹45,000    │  │ ₹5,200     │    │
│  │ Total Due  │  │ Today's    │    │
│  │            │  │ Collection │    │
│  └────────────┘  └────────────┘    │
│                                     │
│  ┌─────────────────────────────────┐│
│  │  Monthly Revenue                ││
│  │  [═══════════════════════════] ││
│  │  [LINE CHART]                   ││
│  └─────────────────────────────────┘│
│                                     │
│  ┌─────────────────────────────────┐│
│  │  ⚠️ Low Stock Alerts (3)        ││
│  │  Rice - 5kg remaining           ││
│  │  Sugar - 2kg remaining          ││
│  └─────────────────────────────────┘│
│                                     │
│  ┌─────────────────────────────────┐│
│  │  🔴 Top Defaulters              ││
│  │  Suresh - ₹12,000 (45 days)    ││
│  │  Mahesh - ₹8,500 (30 days)     ││
│  └─────────────────────────────────┘│
│                                     │
│  Quick Actions:                     │
│  [+ Credit] [+ Payment] [Remind]   │
│                                     │
├─────────────────────────────────────┤
│  🏠    👥    ➕    📦    📊         │
│ Home  Cust  Add  Stock Reports     │
└─────────────────────────────────────┘
```

**Features:**
- Shop switcher dropdown
- Notification bell
- Summary cards (Total due, Today's collection)
- Revenue chart (fl_chart)
- Low stock alerts
- Top defaulters list
- Quick action buttons
- Bottom navigation

---

### 7. Customer Dashboard (For Customer Role)
**Path:** `/customer-dashboard`
**Purpose:** Customer view of their credit status

```
┌─────────────────────────────────────┐
│  ☰  KhataSetu                  🔔   │
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────────┐│
│  │  Hello, Suresh!                 ││
│  │  Customer of: Ramesh Store     ││
│  └─────────────────────────────────┘│
│                                     │
│  ┌─────────────────────────────────┐│
│  │                                 ││
│  │         ₹ 5,000                 ││
│  │        Amount Due               ││
│  │                                 ││
│  │    Last payment: 15 Feb 2026   ││
│  └─────────────────────────────────┘│
│                                     │
│  ┌─────────────────────────────────┐│
│  │        PAY NOW                  ││
│  │     [Scan QR / UPI Link]       ││
│  └─────────────────────────────────┘│
│                                     │
│  Recent Transactions:               │
│  ┌─────────────────────────────────┐│
│  │ 📅 25 Feb - Credit    +₹500    ││
│  │ 📅 20 Feb - Payment   -₹1000   ││
│  │ 📅 15 Feb - Credit    +₹2000   ││
│  └─────────────────────────────────┘│
│                                     │
│  [View Full Ledger]                 │
│                                     │
└─────────────────────────────────────┘
```

---

### 8. Notifications Screen
**Path:** `/notifications`
**Purpose:** View all notifications

```
┌─────────────────────────────────────┐
│  ←  Notifications         [Clear]   │
├─────────────────────────────────────┤
│                                     │
│  Today                              │
│  ┌─────────────────────────────────┐│
│  │ 💰 Payment Received             ││
│  │ Suresh paid ₹2,000              ││
│  │ 2 hours ago                     ││
│  └─────────────────────────────────┘│
│  ┌─────────────────────────────────┐│
│  │ ⚠️ Low Stock Alert              ││
│  │ Rice stock below threshold      ││
│  │ 5 hours ago                     ││
│  └─────────────────────────────────┘│
│                                     │
│  Yesterday                          │
│  ┌─────────────────────────────────┐│
│  │ 🔔 Reminder Sent                ││
│  │ Reminder sent to Mahesh         ││
│  │ Yesterday, 4:30 PM              ││
│  └─────────────────────────────────┘│
│                                     │
└─────────────────────────────────────┘
```

---

## 👥 Customer Management Module (5 Screens)

### 9. Customer List Screen
**Path:** `/customers`
**Purpose:** View and search all customers

```
┌─────────────────────────────────────┐
│  ←  Customers              [+ Add]  │
├─────────────────────────────────────┤
│  ┌─────────────────────────────────┐│
│  │  🔍 Search customers...         ││
│  └─────────────────────────────────┘│
│                                     │
│  [All] [Due] [Clear] [Risky]       │
│                                     │
│  ┌─────────────────────────────────┐│
│  │  🔴 Suresh Sharma               ││
│  │  📱 98765 43210                 ││
│  │  Balance: ₹12,000 | 45 days    ││
│  │  Credit Limit: ₹15,000          ││
│  └─────────────────────────────────┘│
│                                     │
│  ┌─────────────────────────────────┐│
│  │  🟡 Mahesh Patel                ││
│  │  📱 98765 43211                 ││
│  │  Balance: ₹5,000 | 15 days     ││
│  │  Credit Limit: ₹10,000          ││
│  └─────────────────────────────────┘│
│                                     │
│  ┌─────────────────────────────────┐│
│  │  🟢 Rajesh Kumar                ││
│  │  📱 98765 43212                 ││
│  │  Balance: ₹0 | Cleared         ││
│  │  Credit Limit: ₹8,000           ││
│  └─────────────────────────────────┘│
│                                     │
├─────────────────────────────────────┤
│  🏠    👥    ➕    📦    📊         │
└─────────────────────────────────────┘
```

**Color Codes:**
- 🔴 Red: Overdue (>30 days)
- 🟡 Yellow: Warning (15-30 days)
- 🟢 Green: Good standing

---

### 10. Add Customer Screen
**Path:** `/customers/add`
**Purpose:** Add new customer

```
┌─────────────────────────────────────┐
│  ←  Add Customer                    │
├─────────────────────────────────────┤
│                                     │
│  ┌───────────────────────────────┐  │
│  │  👤 Customer Name *           │  │
│  │  Enter full name              │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  📱 Phone Number *            │  │
│  │  +91                          │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  📧 Email (Optional)          │  │
│  │                               │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  📍 Address                   │  │
│  │  Village, District            │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  💰 Credit Limit              │  │
│  │  ₹ 10,000                     │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  📝 Notes                     │  │
│  │  Optional notes about customer│  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │        SAVE CUSTOMER          │  │
│  └───────────────────────────────┘  │
│                                     │
└─────────────────────────────────────┘
```

---

### 11. Customer Detail Screen
**Path:** `/customers/:id`
**Purpose:** View customer details and ledger

```
┌─────────────────────────────────────┐
│  ←  Suresh Sharma           [Edit]  │
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────────┐│
│  │         [Avatar]                ││
│  │      Suresh Sharma              ││
│  │      📱 98765 43210             ││
│  │      📍 Modhera, Mehsana        ││
│  └─────────────────────────────────┘│
│                                     │
│  ┌────────────┐  ┌────────────┐    │
│  │ ₹12,000    │  │ ₹15,000    │    │
│  │ Current    │  │ Credit     │    │
│  │ Balance    │  │ Limit      │    │
│  └────────────┘  └────────────┘    │
│                                     │
│  ┌────────────┐  ┌────────────┐    │
│  │ 45 days    │  │ 72%        │    │
│  │ Overdue    │  │ Risk Score │    │
│  └────────────┘  └────────────┘    │
│                                     │
│  [+ Credit] [+ Payment] [Remind]   │
│                                     │
│  Recent Transactions:               │
│  ┌─────────────────────────────────┐│
│  │ 📅 25 Feb  Credit   +₹500      ││
│  │    Rice 10kg, Sugar 5kg        ││
│  │ 📅 20 Feb  Payment  -₹1000     ││
│  │    Cash payment                ││
│  │ 📅 15 Feb  Credit   +₹2000     ││
│  │    Monthly grocery             ││
│  └─────────────────────────────────┘│
│                                     │
│  [View Full Ledger] [Download PDF] │
│                                     │
└─────────────────────────────────────┘
```

---

### 12. Edit Customer Screen
**Path:** `/customers/:id/edit`
**Purpose:** Edit customer information

Similar to Add Customer with pre-filled data.

---

### 13. Customer Ledger Full View
**Path:** `/customers/:id/ledger`
**Purpose:** Complete transaction history

```
┌─────────────────────────────────────┐
│  ←  Suresh's Ledger   [Filter] 📥   │
├─────────────────────────────────────┤
│                                     │
│  Current Balance: ₹12,000          │
│                                     │
│  [All] [Credits] [Payments]        │
│                                     │
│  February 2026                      │
│  ├─ 25 Feb ──────────────────────┤ │
│  │  Credit    +₹500              │ │
│  │  Rice 10kg, Sugar 5kg         │ │
│  │  Running: ₹12,000             │ │
│  ├─ 20 Feb ──────────────────────┤ │
│  │  Payment   -₹1,000            │ │
│  │  Cash                         │ │
│  │  Running: ₹11,500             │ │
│  ├─ 15 Feb ──────────────────────┤ │
│  │  Credit    +₹2,000            │ │
│  │  Monthly grocery              │ │
│  │  Running: ₹12,500             │ │
│  ├─ 10 Feb ──────────────────────┤ │
│  │  Payment   -₹500              │ │
│  │  UPI                          │ │
│  │  Running: ₹10,500             │ │
│  └────────────────────────────────┘ │
│                                     │
│  January 2026                       │
│  [Collapsed - Tap to expand]       │
│                                     │
└─────────────────────────────────────┘
```

---

## 📝 Ledger Module (4 Screens)

### 14. Add Credit Entry Screen
**Path:** `/ledger/credit`
**Purpose:** Add new credit (udhar) entry

```
┌─────────────────────────────────────┐
│  ←  Add Credit Entry                │
├─────────────────────────────────────┤
│                                     │
│  ┌───────────────────────────────┐  │
│  │  👤 Select Customer *         │  │
│  │  [Suresh Sharma ▼]            │  │
│  └───────────────────────────────┘  │
│                                     │
│  Current Balance: ₹12,000          │
│  Credit Limit: ₹15,000             │
│  Available: ₹3,000                 │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  💰 Amount *                  │  │
│  │  ₹ 500                        │  │
│  └───────────────────────────────┘  │
│                                     │
│  Add Items from Inventory?          │
│  [+ Add Items]                      │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  Items Added:                 │  │
│  │  Rice 10kg - ₹300             │  │
│  │  Sugar 5kg - ₹200             │  │
│  │  Total: ₹500                  │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  📅 Date                      │  │
│  │  27 Feb 2026                  │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  📝 Notes                     │  │
│  │  Optional description         │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │        SAVE CREDIT            │  │
│  └───────────────────────────────┘  │
│                                     │
└─────────────────────────────────────┘
```

---

### 15. Add Payment Entry Screen
**Path:** `/ledger/payment`
**Purpose:** Record payment received

```
┌─────────────────────────────────────┐
│  ←  Add Payment Entry               │
├─────────────────────────────────────┤
│                                     │
│  ┌───────────────────────────────┐  │
│  │  👤 Select Customer *         │  │
│  │  [Suresh Sharma ▼]            │  │
│  └───────────────────────────────┘  │
│                                     │
│  Current Balance: ₹12,000          │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  💰 Amount *                  │  │
│  │  ₹ 2,000                      │  │
│  └───────────────────────────────┘  │
│                                     │
│  Payment Mode:                      │
│  ┌──────┐ ┌──────┐ ┌──────┐       │
│  │ Cash │ │ UPI  │ │ Bank │       │
│  │  ✓   │ │      │ │      │       │
│  └──────┘ └──────┘ └──────┘       │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  📅 Date                      │  │
│  │  27 Feb 2026                  │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  📝 Reference/Notes           │  │
│  │  UPI Transaction ID           │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │        SAVE PAYMENT           │  │
│  └───────────────────────────────┘  │
│                                     │
│  New Balance: ₹10,000              │
│                                     │
└─────────────────────────────────────┘
```

---

### 16. Quick Add Screen (Floating Button)
**Path:** `/quick-add`
**Purpose:** Quick entry from dashboard

```
┌─────────────────────────────────────┐
│  ←  Quick Add                       │
├─────────────────────────────────────┤
│                                     │
│     What would you like to add?     │
│                                     │
│  ┌─────────────────────────────────┐│
│  │                                 ││
│  │     📥 Credit Entry             ││
│  │     Add new udhar               ││
│  │                                 ││
│  └─────────────────────────────────┘│
│                                     │
│  ┌─────────────────────────────────┐│
│  │                                 ││
│  │     💰 Payment Entry            ││
│  │     Record payment received     ││
│  │                                 ││
│  └─────────────────────────────────┘│
│                                     │
│  ┌─────────────────────────────────┐│
│  │                                 ││
│  │     👤 New Customer             ││
│  │     Add new customer            ││
│  │                                 ││
│  └─────────────────────────────────┘│
│                                     │
│  ┌─────────────────────────────────┐│
│  │                                 ││
│  │     📦 New Product              ││
│  │     Add inventory item          ││
│  │                                 ││
│  └─────────────────────────────────┘│
│                                     │
└─────────────────────────────────────┘
```

---

### 17. Transaction Detail Screen
**Path:** `/transactions/:id`
**Purpose:** View transaction details

```
┌─────────────────────────────────────┐
│  ←  Transaction Details    [Delete] │
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────────┐│
│  │         Credit Entry            ││
│  │         +₹500                   ││
│  │                                 ││
│  │   📅 27 February 2026           ││
│  │   🕐 10:30 AM                   ││
│  └─────────────────────────────────┘│
│                                     │
│  Customer: Suresh Sharma            │
│                                     │
│  Items:                             │
│  ┌─────────────────────────────────┐│
│  │ Rice 10kg           ₹300       ││
│  │ Sugar 5kg           ₹200       ││
│  ├─────────────────────────────────┤│
│  │ Total                ₹500       ││
│  └─────────────────────────────────┘│
│                                     │
│  Notes: Monthly grocery             │
│                                     │
│  Balance after: ₹12,000            │
│                                     │
│  [Edit]  [Share Receipt]           │
│                                     │
└─────────────────────────────────────┘
```

---

## 💳 Payment Module (3 Screens)

### 18. UPI Setup Screen
**Path:** `/settings/upi`
**Purpose:** Configure UPI details

```
┌─────────────────────────────────────┐
│  ←  UPI Setup                       │
├─────────────────────────────────────┤
│                                     │
│  Your UPI Details                   │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  UPI ID                       │  │
│  │  ramesh@paytm                 │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  Merchant Name                │  │
│  │  Ramesh General Store         │  │
│  └───────────────────────────────┘  │
│                                     │
│  Static QR Code:                    │
│  ┌───────────────────────────────┐  │
│  │                               │  │
│  │        [QR Code Image]        │  │
│  │                               │  │
│  │   [Upload New QR]             │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │        SAVE UPI DETAILS       │  │
│  └───────────────────────────────┘  │
│                                     │
└─────────────────────────────────────┘
```

---

### 19. Payment Collection Screen
**Path:** `/collect-payment/:customerId`
**Purpose:** Show QR/UPI link for collection

```
┌─────────────────────────────────────┐
│  ←  Collect Payment                 │
├─────────────────────────────────────┤
│                                     │
│  Collecting from: Suresh Sharma     │
│  Amount Due: ₹12,000               │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  Enter Amount to Collect      │  │
│  │  ₹ 5,000                      │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌─────────────────────────────────┐│
│  │                                 ││
│  │         [QR CODE]               ││
│  │                                 ││
│  │     Scan to pay ₹5,000         ││
│  │     to Ramesh Store            ││
│  │                                 ││
│  └─────────────────────────────────┘│
│                                     │
│  [Share QR]  [Copy UPI Link]       │
│                                     │
│  Or ask customer to pay via:       │
│                                     │
│  ┌─────────────────────────────────┐│
│  │     Open in UPI App →          ││
│  │     (Google Pay / PhonePe)     ││
│  └─────────────────────────────────┘│
│                                     │
│  ┌───────────────────────────────┐  │
│  │   CONFIRM PAYMENT RECEIVED    │  │
│  └───────────────────────────────┘  │
│                                     │
└─────────────────────────────────────┘
```

---

### 20. Payment Receipt Screen
**Path:** `/receipt/:transactionId`
**Purpose:** Digital receipt

```
┌─────────────────────────────────────┐
│  ←  Payment Receipt                 │
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────────┐│
│  │      RAMESH GENERAL STORE      ││
│  │      Modhera, Mehsana          ││
│  │      📱 98765 43210            ││
│  │─────────────────────────────────││
│  │                                 ││
│  │  PAYMENT RECEIPT               ││
│  │                                 ││
│  │  Received From: Suresh Sharma  ││
│  │  Amount: ₹5,000                ││
│  │  Mode: UPI                     ││
│  │  Date: 27 Feb 2026             ││
│  │  Time: 10:30 AM                ││
│  │                                 ││
│  │  Ref: TXN123456789             ││
│  │                                 ││
│  │─────────────────────────────────││
│  │  New Balance: ₹7,000           ││
│  │─────────────────────────────────││
│  │                                 ││
│  │  Thank you for your payment!   ││
│  │                                 ││
│  └─────────────────────────────────┘│
│                                     │
│  [Download PDF] [Share via WhatsApp]│
│                                     │
└─────────────────────────────────────┘
```

---

## 📦 Inventory Module (4 Screens)

### 21. Inventory List Screen
**Path:** `/inventory`
**Purpose:** View all products

```
┌─────────────────────────────────────┐
│  ←  Inventory              [+ Add]  │
├─────────────────────────────────────┤
│  ┌─────────────────────────────────┐│
│  │  🔍 Search products...          ││
│  └─────────────────────────────────┘│
│                                     │
│  [All] [Low Stock] [Categories ▼]  │
│                                     │
│  Total Inventory Value: ₹85,000    │
│                                     │
│  ┌─────────────────────────────────┐│
│  │  🔴 Rice (Basmati 25kg)        ││
│  │  Stock: 5 | Min: 10            ││
│  │  Buy: ₹800 | Sell: ₹900        ││
│  └─────────────────────────────────┘│
│                                     │
│  ┌─────────────────────────────────┐│
│  │  🟢 Sugar (5kg)                 ││
│  │  Stock: 20 | Min: 5            ││
│  │  Buy: ₹200 | Sell: ₹240        ││
│  └─────────────────────────────────┘│
│                                     │
│  ┌─────────────────────────────────┐│
│  │  🟡 Wheat Flour (10kg)          ││
│  │  Stock: 8 | Min: 10            ││
│  │  Buy: ₹350 | Sell: ₹400        ││
│  └─────────────────────────────────┘│
│                                     │
├─────────────────────────────────────┤
│  🏠    👥    ➕    📦    📊         │
└─────────────────────────────────────┘
```

---

### 22. Add Product Screen
**Path:** `/inventory/add`
**Purpose:** Add new product

```
┌─────────────────────────────────────┐
│  ←  Add Product                     │
├─────────────────────────────────────┤
│                                     │
│  ┌───────────────────────────────┐  │
│  │  📦 Product Name *            │  │
│  │  Rice Basmati 25kg            │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  📁 Category                  │  │
│  │  [Grocery ▼]                  │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  📊 Barcode (Optional)        │  │
│  │  [Scan 📷]                    │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  💰 Purchase Price            │  │
│  │  ₹ 800                        │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  💰 Selling Price             │  │
│  │  ₹ 900                        │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  📈 Current Stock             │  │
│  │  15                           │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  ⚠️ Low Stock Threshold       │  │
│  │  10                           │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │        SAVE PRODUCT           │  │
│  └───────────────────────────────┘  │
│                                     │
└─────────────────────────────────────┘
```

---

### 23. Product Detail Screen
**Path:** `/inventory/:id`
**Purpose:** View product details and history

```
┌─────────────────────────────────────┐
│  ←  Rice Basmati 25kg       [Edit]  │
├─────────────────────────────────────┤
│                                     │
│  ┌────────────┐  ┌────────────┐    │
│  │ 15         │  │ 10         │    │
│  │ Current    │  │ Minimum    │    │
│  │ Stock      │  │ Threshold  │    │
│  └────────────┘  └────────────┘    │
│                                     │
│  ┌────────────┐  ┌────────────┐    │
│  │ ₹800       │  │ ₹900       │    │
│  │ Purchase   │  │ Selling    │    │
│  │ Price      │  │ Price      │    │
│  └────────────┘  └────────────┘    │
│                                     │
│  Category: Grocery                  │
│  Barcode: 8901234567890            │
│  Value: ₹12,000                    │
│  Margin: 12.5%                     │
│                                     │
│  Stock History:                     │
│  ┌─────────────────────────────────┐│
│  │ 📅 25 Feb  Sold    -2 (to Suresh)│
│  │ 📅 20 Feb  Added   +10          ││
│  │ 📅 15 Feb  Sold    -5           ││
│  │ 📅 10 Feb  Added   +20          ││
│  └─────────────────────────────────┘│
│                                     │
│  [+ Add Stock]  [Adjust Stock]     │
│                                     │
└─────────────────────────────────────┘
```

---

### 24. Stock Adjustment Screen
**Path:** `/inventory/:id/adjust`
**Purpose:** Add or remove stock

```
┌─────────────────────────────────────┐
│  ←  Stock Adjustment                │
├─────────────────────────────────────┤
│                                     │
│  Product: Rice Basmati 25kg         │
│  Current Stock: 15                  │
│                                     │
│  Adjustment Type:                   │
│  ┌──────────┐  ┌──────────┐        │
│  │ + Add    │  │ - Remove │        │
│  │    ✓     │  │          │        │
│  └──────────┘  └──────────┘        │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  Quantity                     │  │
│  │  10                           │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  Reason                       │  │
│  │  New stock purchase           │  │
│  └───────────────────────────────┘  │
│                                     │
│  New Stock: 25                      │
│                                     │
│  ┌───────────────────────────────┐  │
│  │        SAVE ADJUSTMENT        │  │
│  └───────────────────────────────┘  │
│                                     │
└─────────────────────────────────────┘
```

---

## 🔔 Reminder Module (3 Screens)

### 25. Reminder Dashboard
**Path:** `/reminders`
**Purpose:** View and manage reminders

```
┌─────────────────────────────────────┐
│  ←  Reminders              [+ New]  │
├─────────────────────────────────────┤
│                                     │
│  Auto Reminder Settings:            │
│  ┌─────────────────────────────────┐│
│  │  Send reminder after: 15 days  ││
│  │  [Edit Settings]               ││
│  └─────────────────────────────────┘│
│                                     │
│  Pending Reminders (5):             │
│                                     │
│  ┌─────────────────────────────────┐│
│  │  Suresh Sharma                  ││
│  │  ₹12,000 | 45 days overdue     ││
│  │  [Send Reminder] [WhatsApp]    ││
│  └─────────────────────────────────┘│
│                                     │
│  ┌─────────────────────────────────┐│
│  │  Mahesh Patel                   ││
│  │  ₹8,500 | 30 days overdue      ││
│  │  [Send Reminder] [WhatsApp]    ││
│  └─────────────────────────────────┘│
│                                     │
│  Sent Today (3):                    │
│  ┌─────────────────────────────────┐│
│  │  Rajesh Kumar - 10:30 AM       ││
│  │  Sent via Push Notification    ││
│  └─────────────────────────────────┘│
│                                     │
└─────────────────────────────────────┘
```

---

### 26. Send Reminder Screen
**Path:** `/reminders/send/:customerId`
**Purpose:** Compose and send reminder

```
┌─────────────────────────────────────┐
│  ←  Send Reminder                   │
├─────────────────────────────────────┤
│                                     │
│  To: Suresh Sharma                  │
│  Amount Due: ₹12,000               │
│  Days Overdue: 45                   │
│                                     │
│  Message Template:                  │
│  ┌───────────────────────────────┐  │
│  │  [Friendly ▼]                 │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌─────────────────────────────────┐│
│  │  🙏 Reminder from Ramesh Store  ││
│  │                                 ││
│  │  Dear Suresh ji,                ││
│  │                                 ││
│  │  Your pending amount of         ││
│  │  ₹12,000 is overdue for 45     ││
│  │  days. Kindly clear the dues   ││
│  │  at your earliest convenience.  ││
│  │                                 ││
│  │  Thank you!                     ││
│  │  - Ramesh Store                 ││
│  └─────────────────────────────────┘│
│                                     │
│  Send via:                          │
│  [☑ Push Notification]             │
│  [☐ WhatsApp]                      │
│  [☐ SMS]                           │
│                                     │
│  ┌───────────────────────────────┐  │
│  │        SEND REMINDER          │  │
│  └───────────────────────────────┘  │
│                                     │
└─────────────────────────────────────┘
```

---

### 27. Reminder Settings Screen
**Path:** `/settings/reminders`
**Purpose:** Configure auto-reminder rules

```
┌─────────────────────────────────────┐
│  ←  Reminder Settings               │
├─────────────────────────────────────┤
│                                     │
│  Auto Reminder:                     │
│  ┌─────────────────────────────────┐│
│  │  Enable Auto Reminders    [ON] ││
│  └─────────────────────────────────┘│
│                                     │
│  ┌───────────────────────────────┐  │
│  │  Send after X days of credit  │  │
│  │  [15 days ▼]                  │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  Repeat reminder every        │  │
│  │  [7 days ▼]                   │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  Max reminders per customer   │  │
│  │  [3 ▼]                        │  │
│  └───────────────────────────────┘  │
│                                     │
│  Default Channel:                   │
│  [☑ Push Notification]             │
│  [☐ WhatsApp]                      │
│                                     │
│  ┌───────────────────────────────┐  │
│  │        SAVE SETTINGS          │  │
│  └───────────────────────────────┘  │
│                                     │
└─────────────────────────────────────┘
```

---

## 📊 Reports Module (4 Screens)

### 28. Reports Dashboard
**Path:** `/reports`
**Purpose:** Analytics overview

```
┌─────────────────────────────────────┐
│  ←  Reports & Analytics             │
├─────────────────────────────────────┤
│                                     │
│  Period: [This Month ▼]            │
│                                     │
│  ┌─────────────────────────────────┐│
│  │  Revenue Summary                ││
│  │                                 ││
│  │  Total Credit: ₹1,25,000       ││
│  │  Total Collected: ₹80,000      ││
│  │  Pending: ₹45,000              ││
│  └─────────────────────────────────┘│
│                                     │
│  ┌─────────────────────────────────┐│
│  │  [PIE CHART]                   ││
│  │  Collected vs Pending          ││
│  └─────────────────────────────────┘│
│                                     │
│  ┌─────────────────────────────────┐│
│  │  [LINE CHART]                  ││
│  │  Daily Collection Trend        ││
│  └─────────────────────────────────┘│
│                                     │
│  Quick Reports:                     │
│  ┌─────────────┐ ┌─────────────┐   │
│  │ Customer    │ │ Inventory   │   │
│  │ Report      │ │ Report      │   │
│  └─────────────┘ └─────────────┘   │
│  ┌─────────────┐ ┌─────────────┐   │
│  │ Download    │ │ Payment     │   │
│  │ Ledger PDF  │ │ Heatmap     │   │
│  └─────────────┘ └─────────────┘   │
│                                     │
├─────────────────────────────────────┤
│  🏠    👥    ➕    📦    📊         │
└─────────────────────────────────────┘
```

---

### 29. Customer Performance Report
**Path:** `/reports/customers`
**Purpose:** Customer-wise analytics

```
┌─────────────────────────────────────┐
│  ←  Customer Report                 │
├─────────────────────────────────────┤
│                                     │
│  Period: [This Month ▼]            │
│                                     │
│  Top Credit Customers:              │
│  ┌─────────────────────────────────┐│
│  │ 1. Suresh    ₹25,000 credit    ││
│  │ 2. Mahesh    ₹18,000 credit    ││
│  │ 3. Rajesh    ₹12,000 credit    ││
│  └─────────────────────────────────┘│
│                                     │
│  Top Payers:                        │
│  ┌─────────────────────────────────┐│
│  │ 1. Rajesh    ₹20,000 paid      ││
│  │ 2. Suresh    ₹15,000 paid      ││
│  │ 3. Kiran     ₹10,000 paid      ││
│  └─────────────────────────────────┘│
│                                     │
│  Risk Analysis:                     │
│  ┌─────────────────────────────────┐│
│  │ 🔴 High Risk: 3 customers      ││
│  │ 🟡 Medium Risk: 5 customers    ││
│  │ 🟢 Low Risk: 20 customers      ││
│  └─────────────────────────────────┘│
│                                     │
│  [Export CSV]  [Share Report]      │
│                                     │
└─────────────────────────────────────┘
```

---

### 30. Inventory Report
**Path:** `/reports/inventory`
**Purpose:** Inventory analytics

```
┌─────────────────────────────────────┐
│  ←  Inventory Report                │
├─────────────────────────────────────┤
│                                     │
│  Inventory Summary:                 │
│  ┌─────────────────────────────────┐│
│  │  Total Products: 45            ││
│  │  Total Value: ₹85,000          ││
│  │  Low Stock Items: 5            ││
│  │  Out of Stock: 2               ││
│  └─────────────────────────────────┘│
│                                     │
│  Top Selling Products:              │
│  ┌─────────────────────────────────┐│
│  │ 1. Rice 25kg      120 sold     ││
│  │ 2. Sugar 5kg      85 sold      ││
│  │ 3. Atta 10kg      70 sold      ││
│  └─────────────────────────────────┘│
│                                     │
│  Category Breakdown:                │
│  ┌─────────────────────────────────┐│
│  │  [BAR CHART]                   ││
│  │  Sales by Category             ││
│  └─────────────────────────────────┘│
│                                     │
│  [Export CSV]  [Print Report]      │
│                                     │
└─────────────────────────────────────┘
```

---

### 31. Payment Heatmap
**Path:** `/reports/heatmap`
**Purpose:** Visual payment pattern

```
┌─────────────────────────────────────┐
│  ←  Payment Heatmap                 │
├─────────────────────────────────────┤
│                                     │
│  February 2026                      │
│                                     │
│  ┌─────────────────────────────────┐│
│  │ Mon Tue Wed Thu Fri Sat Sun    ││
│  │                                 ││
│  │  █   ░   ▓   ░   ▓   █   ░     ││
│  │  ░   ▓   █   ▓   ░   ▓   ░     ││
│  │  ▓   ░   ░   █   ▓   ░   ░     ││
│  │  ░   ▓   ▓   ░   █   ▓   █     ││
│  │                                 ││
│  │  Legend:                        ││
│  │  █ High  ▓ Medium  ░ Low       ││
│  └─────────────────────────────────┘│
│                                     │
│  Best Collection Days:              │
│  • Saturday (avg ₹8,500)           │
│  • Friday (avg ₹6,200)             │
│                                     │
│  Worst Collection Days:             │
│  • Tuesday (avg ₹1,200)            │
│                                     │
└─────────────────────────────────────┘
```

---

## ⚙️ Settings Module (4 Screens)

### 32. Settings Main Screen
**Path:** `/settings`
**Purpose:** App settings hub

```
┌─────────────────────────────────────┐
│  ←  Settings                        │
├─────────────────────────────────────┤
│                                     │
│  Account                            │
│  ┌─────────────────────────────────┐│
│  │  👤 Profile Settings         → ││
│  │  🏪 Shop Settings            → ││
│  │  🔐 Security & Password      → ││
│  └─────────────────────────────────┘│
│                                     │
│  Preferences                        │
│  ┌─────────────────────────────────┐│
│  │  🌐 Language               [EN]││
│  │  🌙 Dark Mode             [OFF]││
│  │  🔔 Notifications          [ON]││
│  └─────────────────────────────────┘│
│                                     │
│  Business                           │
│  ┌─────────────────────────────────┐│
│  │  💳 UPI Settings             → ││
│  │  🔔 Reminder Settings        → ││
│  │  📊 Report Settings          → ││
│  └─────────────────────────────────┘│
│                                     │
│  Data                               │
│  ┌─────────────────────────────────┐│
│  │  ☁️ Backup & Restore         → ││
│  │  📤 Export Data              → ││
│  └─────────────────────────────────┘│
│                                     │
│  [Logout]                           │
│                                     │
└─────────────────────────────────────┘
```

---

### 33. Profile Settings Screen
**Path:** `/settings/profile`
**Purpose:** User profile management

```
┌─────────────────────────────────────┐
│  ←  Profile Settings                │
├─────────────────────────────────────┤
│                                     │
│           [Avatar]                  │
│         [Change Photo]              │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  Full Name                    │  │
│  │  Ramesh Patel                 │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  Phone Number                 │  │
│  │  +91 98765 43210              │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  Email                        │  │
│  │  ramesh@email.com             │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │        SAVE CHANGES           │  │
│  └───────────────────────────────┘  │
│                                     │
└─────────────────────────────────────┘
```

---

### 34. Shop Settings Screen
**Path:** `/settings/shop`
**Purpose:** Shop configuration

```
┌─────────────────────────────────────┐
│  ←  Shop Settings                   │
├─────────────────────────────────────┤
│                                     │
│  Current Shop: Ramesh General Store │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  Shop Name                    │  │
│  │  Ramesh General Store         │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  Address                      │  │
│  │  Main Market, Modhera         │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  Phone                        │  │
│  │  +91 98765 43210              │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  Shop Logo (for receipts)     │  │
│  │  [Upload Logo]                │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │        SAVE CHANGES           │  │
│  └───────────────────────────────┘  │
│                                     │
│  Manage Shops:                      │
│  [+ Add New Shop]                   │
│                                     │
└─────────────────────────────────────┘
```

---

### 35. Language Settings Screen
**Path:** `/settings/language`
**Purpose:** Language selection

```
┌─────────────────────────────────────┐
│  ←  Language / ભાષા                 │
├─────────────────────────────────────┤
│                                     │
│  Select your preferred language:    │
│                                     │
│  ┌─────────────────────────────────┐│
│  │  ☑ English                     ││
│  └─────────────────────────────────┘│
│                                     │
│  ┌─────────────────────────────────┐│
│  │  ☐ ગુજરાતી (Gujarati)          ││
│  └─────────────────────────────────┘│
│                                     │
│  ┌─────────────────────────────────┐│
│  │  ☐ हिंदी (Hindi) - Coming Soon ││
│  └─────────────────────────────────┘│
│                                     │
│                                     │
│  App will restart to apply changes  │
│                                     │
└─────────────────────────────────────┘
```

---

## 📋 Summary

| Module | Screens | Priority |
|--------|---------|----------|
| Authentication | 5 | P0 |
| Dashboard | 3 | P0 |
| Customer Management | 5 | P0 |
| Ledger | 4 | P0 |
| Payment | 3 | P1 |
| Inventory | 4 | P1 |
| Reminders | 3 | P1 |
| Reports | 4 | P2 |
| Settings | 4 | P2 |
| **Total** | **35** | - |
