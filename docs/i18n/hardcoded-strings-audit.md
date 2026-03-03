# KhataSetu — Hardcoded UI Strings Audit for i18n

> **Generated**: Full codebase audit of all hardcoded user-facing strings.
> **Purpose**: Planning document for internationalization (i18n) migration.
> **Files Audited**: 30+ Dart source files across pages, widgets, services, and core utilities.

---

## Table of Contents

1. [Current Localization Setup](#1-current-localization-setup)
2. [String Inventory by File](#2-string-inventory-by-file)
   - [Core Layer](#core-layer)
   - [Auth Feature](#auth-feature)
   - [Home Feature](#home-feature)
   - [Customers Feature](#customers-feature)
   - [Ledger Feature](#ledger-feature)
   - [Inventory Feature](#inventory-feature)
   - [Settings Feature](#settings-feature)
   - [Reports Feature](#reports-feature)
   - [Billing Feature](#billing-feature)
   - [UPI Feature](#upi-feature)
   - [Shared Widgets](#shared-widgets)
   - [PDF Report Service](#pdf-report-service)
3. [String Categories Summary](#3-string-categories-summary)
4. [Estimated String Count](#4-estimated-string-count)
5. [Recommendations](#5-recommendations)

---

## 1. Current Localization Setup

### pubspec.yaml Dependencies
- `flutter_localizations` SDK — present but **unused**
- `intl: ^0.20.2` — present (used for `DateFormat` only, not for i18n messages)
- **No l10n package** (`easy_localization`, `slang`, `intl_utils`, ARB, etc.)

### main.dart (`MaterialApp.router`)
- `title: 'KhataSetu'` — hardcoded
- **No** `localizationsDelegates`
- **No** `supportedLocales`
- **No** `locale` parameter
- **No** `Localizations` widget

### Settings Page (Language Selector)
- Language map exists: `{'en': 'English', 'hi': 'हिंदी (Hindi)', 'gu': 'ગુજરાતી (Gujarati)', 'mr': 'मराठी (Marathi)'}`
- Selection persisted via `LocalStorageService.saveLanguage()`
- **Effect**: None — no locale-aware widgets consume this value

**Conclusion**: The app has zero functional i18n. All UI strings are inline Dart string literals.

---

## 2. String Inventory by File

### Core Layer

#### `lib/main.dart`
| # | String | Context |
|---|--------|---------|
| 1 | `'KhataSetu'` | MaterialApp title |

#### `lib/core/constant/constants.dart`
| # | String | Context |
|---|--------|---------|
| 1 | `'KhataSetu'` | AppConstants.appName |
| 2 | `'₹'` | AppConstants.currencySymbol |
| 3 | `'INR'` | AppConstants.currencyCode |
| 4 | `'dd MMM yyyy'` | Date format pattern |
| 5 | `'hh:mm a'` | Time format pattern |
| 6 | `'dd/MM/yyyy'` | Short date format |
| 7 | `'EEEE, dd MMMM yyyy'` | Long date format |

#### `lib/core/utils/validators.dart`
| # | String | Context |
|---|--------|---------|
| 1 | `'Phone number is required'` | Validation error |
| 2 | `'Enter a valid 10-digit phone number'` | Validation error |
| 3 | `'Name is required'` | Validation error |
| 4 | `'Name must be at least 2 characters'` | Validation error |
| 5 | `'Name cannot exceed 50 characters'` | Validation error |
| 6 | `'Only alphabets and spaces allowed'` | Validation error |
| 7 | `'Password is required'` | Validation error |
| 8 | `'Password must be at least 8 characters'` | Validation error |
| 9 | `'Must contain uppercase letter'` | Validation error |
| 10 | `'Must contain lowercase letter'` | Validation error |
| 11 | `'Must contain a number'` | Validation error |
| 12 | `'Passwords do not match'` | Validation error |
| 13 | `'Email is required'` | Validation error |
| 14 | `'Enter a valid email address'` | Validation error |
| 15 | `'Amount is required'` | Validation error |
| 16 | `'Enter a valid amount'` | Validation error |
| 17 | `'Amount must be greater than zero'` | Validation error |
| 18 | `'Amount cannot exceed ₹10,00,000'` | Validation error |
| 19 | `'Shop name is required'` | Validation error |
| 20 | `'Shop name must be at least 2 characters'` | Validation error |
| 21 | `'Enter a valid PIN code'` | Validation error |
| 22 | `'Description cannot exceed 200 characters'` | Validation error |
| 23 | `'Address cannot exceed 200 characters'` | Validation error |
| 24 | `'Notes cannot exceed 500 characters'` | Validation error |
| 25 | `'Enter a valid credit limit'` | Validation error |

#### `lib/core/router/app_router.dart`
| # | String | Context |
|---|--------|---------|
| 1 | `'Page not found'` | Error page title |
| 2 | `'The page you are looking for does not exist.'` | Error page body |
| 3 | `'Go to Dashboard'` | Error page button |

---

### Auth Feature

#### `lib/features/auth/presentation/pages/splash_page.dart`
| # | String | Context |
|---|--------|---------|
| 1 | `'KhataSetu'` | App title on splash |
| 2 | `'Your Digital Udhar Partner'` | Tagline |

#### `lib/features/auth/presentation/pages/login_page.dart`
| # | String | Context |
|---|--------|---------|
| 1 | `'Welcome Back!'` | Heading |
| 2 | `'Login to manage your khata & grow your business'` | Subtitle |
| 3 | `'Phone Number'` | Field label |
| 4 | `'Enter 10-digit phone number'` | Field hint |
| 5 | `'Password'` | Field label |
| 6 | `'Enter your password'` | Field hint |
| 7 | `'Password is required'` | Inline validation |
| 8 | `'Remember me'` | Checkbox label |
| 9 | `'Coming soon!'` | Snackbar: forgot password |
| 10 | `'Forgot Password?'` | Link text |
| 11 | `'Login'` | Button text |
| 12 | `'or continue with'` | Divider text |
| 13 | `'OTP Login'` | Button text |
| 14 | `'OTP Login coming soon!'` | Snackbar |
| 15 | `'Biometric'` | Button text |
| 16 | `'Biometric coming soon!'` | Snackbar |
| 17 | `'Demo Mode Active'` | Banner title |
| 18 | `'Enter any phone & password to explore the app'` | Banner body |
| 19 | `'Don\'t have an account?'` | Text |
| 20 | `'Sign Up'` | Link text |

#### `lib/features/auth/presentation/pages/register_page.dart`
| # | String | Context |
|---|--------|---------|
| 1 | `'Create Account'` | Page heading & button |
| 2 | `'Start your digital khata journey in minutes'` | Subtitle |
| 3 | `'Personal'` | Step label |
| 4 | `'Shop'` | Step label |
| 5 | `'Security'` | Step/section label |
| 6 | `'Personal Information'` | Section title |
| 7 | `'Full Name'` | Field label |
| 8 | `'Enter your full name'` | Field hint |
| 9 | `'Phone Number'` | Field label |
| 10 | `'Enter 10-digit phone number'` | Field hint |
| 11 | `'Shop Details'` | Section title |
| 12 | `'Shop Name'` | Field label |
| 13 | `'Enter your shop name'` | Field hint |
| 14 | `'Business Type'` | Dropdown label |
| 15 | `'Kirana Store'` | Business type option |
| 16 | `'Medical Shop'` | Business type option |
| 17 | `'Electronics'` | Business type option |
| 18 | `'Clothing'` | Business type option |
| 19 | `'Hardware'` | Business type option |
| 20 | `'Other'` | Business type option |
| 21 | `'Create Password'` | Field label |
| 22 | `'Min 8 chars with upper, lower, number'` | Field hint |
| 23 | `'Confirm Password'` | Field label |
| 24 | `'Re-enter your password'` | Field hint |
| 25 | `'Password Strength: $strengthText'` | Dynamic label |
| 26 | `'Weak'` | Password strength |
| 27 | `'Medium'` | Password strength |
| 28 | `'Strong'` | Password strength |
| 29 | `'I agree to the '` | Terms text |
| 30 | `'Terms & Conditions'` | Link text |
| 31 | `'Privacy Policy'` | Link text |
| 32 | `'Please agree to Terms & Conditions'` | Snackbar error |
| 33 | `'Welcome Aboard! 🎉'` | Success dialog title |
| 34 | `'Your account has been created successfully.'` | Success dialog body |
| 35 | `'$shopName is ready!'` | Success dialog subtitle |
| 36 | `'Start Your Khata'` | Success dialog button |
| 37 | `'Already have an account?'` | Link text |
| 38 | `'Login'` | Link text |

---

### Home Feature

#### `lib/features/home/presentation/pages/home_page.dart`
| # | String | Context |
|---|--------|---------|
| 1 | `'Home'` | Bottom nav label |
| 2 | `'Customers'` | Bottom nav label |
| 3 | `'Ledger'` | Bottom nav label |
| 4 | `'Inventory'` | Bottom nav label |
| 5 | `'Settings'` | Bottom nav label |

#### `lib/features/home/presentation/pages/dashboard_page.dart`
| # | String | Context |
|---|--------|---------|
| 1 | `'Good Morning,'` | Greeting |
| 2 | `'Good Afternoon,'` | Greeting |
| 3 | `'Good Evening,'` | Greeting |
| 4 | `'Ramesh'` | Hardcoded user name |
| 5 | `"TODAY'S SUMMARY"` | Section header |
| 6 | `'from yesterday'` | Trend label |
| 7 | `'Txns'` | Abbreviation |
| 8 | `'Total Pending'` | Stat label |
| 9 | `'From $owingCount customers'` | Dynamic subtitle |
| 10 | `"Today's Collection"` | Stat label |
| 11 | `'$todayTxnCount transactions'` | Dynamic subtitle |
| 12 | `'Total Customers'` | Stat label |
| 13 | `'$activeToday active today'` | Dynamic subtitle |
| 14 | `'Total Transactions'` | Stat label |
| 15 | `'All time'` | Stat subtitle |
| 16 | `'Revenue Overview'` | Section title |
| 17 | `'Collection'` | Chart label |
| 18 | `'Credit'` | Chart label |
| 19 | `'Week'` | Time filter |
| 20 | `'Month'` | Time filter |
| 21 | `'Year'` | Time filter |
| 22 | `'Sales by Category'` | Section title |
| 23 | `'No credit transactions yet'` | Empty state |
| 24 | `'Quick Actions'` | Section title |
| 25 | `'Add\nCustomer'` | Quick action |
| 26 | `'New\nSale'` | Quick action |
| 27 | `'Collect\nPayment'` | Quick action |
| 28 | `'View\nReports'` | Quick action |
| 29 | `'Top Defaulters'` | Section title |
| 30 | `'View All'` | Link text |
| 31 | `'Recent Transactions'` | Section title |
| 32 | `'Select Shop'` | Shop picker title |
| 33 | `'Main Branch - Village Center'` | Hardcoded shop name |
| 34 | `'Secondary - Near School'` | Hardcoded shop name |
| 35 | `'Add New Shop'` | Button text |
| 36 | `'Today'` | Date label |
| 37 | `'Yesterday'` | Date label |
| 38 | `'No transactions yet'` | Empty state |
| 39 | `'Credit Given'` | Label |
| 40 | `'Payments Received'` | Label |
| 41 | `'Net Amount'` | Label |

---

### Customers Feature

#### `lib/features/customers/presentation/pages/customers_page.dart`
| # | String | Context |
|---|--------|---------|
| 1 | `'Customers'` | Page title |
| 2 | `'Name (A-Z)'` | Sort option |
| 3 | `'Balance (High-Low)'` | Sort option |
| 4 | `'Recently Active'` | Sort option |
| 5 | `'Search by name or phone...'` | Search hint |
| 6 | `'Total Customers'` | Stat label |
| 7 | `'$owingCount with pending'` | Stat subtitle |
| 8 | `'Total Pending'` | Stat label |
| 9 | `'All'` | Filter tab |
| 10 | `'Owing'` | Filter tab |
| 11 | `'We Owe'` | Filter tab |
| 12 | `'Settled'` | Filter tab |
| 13 | `'No customers found'` | Empty state title |
| 14 | `'Try adjusting your search or filters'` | Empty state subtitle |
| 15 | `'Add Customer'` | Button |
| 16 | `'Credit (Udhar)'` | Dialog option |
| 17 | `'Payment'` | Dialog option |
| 18 | `'Add Credit'` | Button |
| 19 | `'Record Payment'` | Button |
| 20 | `'Credit of ₹$amount added to $name'` | Snackbar message |
| 21 | `'Payment of ₹$amount received from $name'` | Snackbar message |
| 22 | `'Balance: ₹...'` | Subtitle |
| 23 | `'Quick credit from customer list'` | Description |
| 24 | `'Quick payment from customer list'` | Description |
| 25 | `'Calling $name...'` | Snackbar |
| 26 | `'Opening WhatsApp for $name...'` | Snackbar |
| 27 | `'To Collect'` | Balance label |
| 28 | `'Advance'` | Balance label |

#### `lib/features/customers/presentation/pages/customer_details_page.dart`
| # | String | Context |
|---|--------|---------|
| 1 | `'Transactions'` | Tab label |
| 2 | `'Overview'` | Tab label |
| 3 | `'Details'` | Tab label |
| 4 | `'No transactions yet'` | Empty state |
| 5 | `'Today'` | Date label |
| 6 | `'Yesterday'` | Date label |
| 7 | `'Balance'` | Stat label |
| 8 | `'Trust'` | Stat label |
| 9 | `'Limit'` | Stat label |
| 10 | `'Total Credit'` | Stat label |
| 11 | `'Total Paid'` | Stat label |
| 12 | `'Payment Progress'` | Section title |
| 13 | `'Monthly Activity'` | Section title |
| 14 | `'Trust Score Breakdown'` | Section title |
| 15 | `'Payment History'` | Score label |
| 16 | `'Payment Timeliness'` | Score label |
| 17 | `'Credit Utilization'` | Score label |
| 18 | `'Relationship'` | Score label |
| 19 | `'Contact Information'` | Section title |
| 20 | `'Phone'` | Field label |
| 21 | `'Email'` | Field label |
| 22 | `'Not provided'` | Placeholder |
| 23 | `'Address'` | Field label |
| 24 | `'Account Information'` | Section title |
| 25 | `'Customer Since'` | Field label |
| 26 | `'Last Activity'` | Field label |
| 27 | `'No activity'` | Placeholder |
| 28 | `'Credit Limit'` | Field label |
| 29 | `'Trust Score'` | Field label |
| 30 | `'Notes'` | Field label |
| 31 | `'Quick Actions'` | Section title |
| 32 | `'Call'` | Action button |
| 33 | `'SMS'` | Action button |
| 34 | `'Share'` | Action button |
| 35 | `'Undo'` | Snackbar action |
| 36 | `'Last transaction undone'` | Snackbar message |
| 37 | `'New Transaction'` | Action |
| 38 | `'Send Statement'` | Action |
| 39 | `'Export Data'` | Action |
| 40 | `'Edit Customer'` | Action |
| 41 | `'Delete Customer'` | Action & dialog title |
| 42 | `'Delete Customer?'` | Dialog title |
| 43 | `'Are you sure you want to delete $name? This cannot be undone.'` | Dialog body |
| 44 | `'Cancel'` | Dialog button |
| 45 | `'Delete'` | Dialog button |
| 46 | `'Paid: ₹...'` | Progress label |
| 47 | `'Remaining: ₹...'` | Progress label |
| 48 | `'Credit (Udhar)'` | Transaction type label |
| 49 | `'Payment'` | Transaction type label |

#### `lib/features/customers/presentation/pages/add_customer_page.dart`
| # | String | Context |
|---|--------|---------|
| 1 | `'Add Customer'` | Page title |
| 2 | `'Save'` | Button |
| 3 | `'Customer Added!'` | Success dialog title |
| 4 | `'$name has been added to your customer list.'` | Success dialog body |
| 5 | `'Add Another'` | Success dialog button |
| 6 | `'Done'` | Success dialog button |
| 7 | `'Tap to change avatar'` | Hint text |
| 8 | `'Choose Avatar'` | Dialog title |
| 9 | `'Personal Info'` | Step/section label |
| 10 | `'Customer Name *'` | Field label |
| 11 | `'Enter full name'` | Field hint |
| 12 | `'Phone Number *'` | Field label |
| 13 | `'Enter 10-digit phone number'` | Field hint |
| 14 | `'Contact Details'` | Section title |
| 15 | `'Email (Optional)'` | Field label |
| 16 | `'Enter email address'` | Field hint |
| 17 | `'Address (Optional)'` | Field label |
| 18 | `'Enter full address'` | Field hint |
| 19 | `'Credit Settings'` | Section title |
| 20 | `'Credit Limit (Optional)'` | Field label |
| 21 | `'Maximum credit allowed'` | Field hint |
| 22 | `'Enter valid amount'` | Validation error |
| 23 | `'Notes'` | Section label |
| 24 | `'Notes (Optional)'` | Field label |
| 25 | `'Any additional notes about this customer...'` | Field hint |
| 26 | `'Name'` | Stepper label |
| 27 | `'Phone'` | Stepper label |
| 28 | `'Details'` | Stepper label |

---

### Ledger Feature

#### `lib/features/ledger/presentation/pages/ledger_page.dart`
| # | String | Context |
|---|--------|---------|
| 1 | `'Khata Book'` | Page title |
| 2 | `'Your daily notebook'` | Subtitle |
| 3 | `'All Time'` | Filter option |
| 4 | `'Today'` | Filter/date label |
| 5 | `'Yesterday'` | Date label |
| 6 | `'Search by customer or description...'` | Search hint |
| 7 | `'entries'` | Count label |
| 8 | `'Filtered'` | Label |
| 9 | `'Credit Given'` | Summary label |
| 10 | `'Received'` | Summary label |
| 11 | `'Net'` | Summary label |
| 12 | `'All'` | Filter tab |
| 13 | `'Credit (Udhar)'` | Filter tab |
| 14 | `'Payments'` | Filter tab |
| 15 | `'No matching entries'` | Empty state |
| 16 | `'Try adjusting your search or filters'` | Empty state subtitle |
| 17 | `'Add Entry'` | Button |
| 18 | `'Your khata is empty'` | Empty state title |
| 19 | `'Tap + to add the first entry'` | Empty state subtitle |
| 20 | `'Day Total: ₹... credit, ₹... received'` | Dynamic summary |
| 21 | `'Credit (Udhar)'` | Transaction type label (in card) |
| 22 | `'Payment'` | Transaction type label (in card) |
| 23 | `'items'` | Item count label |
| 24 | `'UPI'` / `'CARD'` / `'OTHER'` / `'CASH'` | Payment mode labels |
| 25 | `'Bal: ₹...'` | Balance display |

#### `lib/features/ledger/presentation/pages/add_transaction_page.dart`
| # | String | Context |
|---|--------|---------|
| 1 | `'Please select a customer'` | Validation message |
| 2 | `'New Transaction'` | Page title |
| 3 | `'Payment Received!'` | Success title |
| 4 | `'Credit Recorded!'` | Success title |
| 5 | `'from'` / `'to'` | Prepositions |
| 6 | `'Balance: ₹...'` | Subtitle |
| 7 | `'Done'` | Button |
| 8 | `'New Purchase'` | Tab title |
| 9 | `'Customer buys on credit'` | Tab subtitle |
| 10 | `'Payment Received'` | Tab title |
| 11 | `'Customer pays you'` | Tab subtitle |
| 12 | `'Customer'` | Section label |
| 13 | `'Search by name or phone...'` | Search hint |
| 14 | `'No customers found'` | Empty state |
| 15 | `'Add customers from the Customers tab first'` | Empty state subtitle |
| 16 | `'Amount'` | Section label |
| 17 | `'Payment Amount'` / `'Purchase Amount'` | Field labels |
| 18 | `'Quick Amount'` | Section title |
| 19 | `'Current balance: ₹...'` | Info text |
| 20 | `'Details'` | Section label |
| 21 | `'Description (Optional)'` | Field label |
| 22 | `'e.g., Payment via cash'` | Field hint |
| 23 | `'e.g., Grocery items - Rice, Dal'` | Field hint |
| 24 | `'Record Payment (+)'` | Button |
| 25 | `'Record Purchase (-)'` | Button |
| 26 | `'Payment Mode'` | Section title |
| 27 | `'Cash'` / `'UPI'` / `'Bank'` / `'Other'` | Payment mode labels |

#### `lib/features/ledger/presentation/pages/customer_timeline_page.dart`
| # | String | Context |
|---|--------|---------|
| 1 | `'Credit of ₹$amount added'` | Snackbar |
| 2 | `'Payment of ₹$amount recorded'` | Snackbar |
| 3 | `'Transaction of ₹$amount undone'` | Snackbar |
| 4 | `'No transactions yet'` | Empty state |
| 5 | `'Tap + to add the first credit or payment'` | Empty state subtitle |
| 6 | `'Outstanding Balance'` | Label |
| 7 | `'All Settled'` | Label |
| 8 | `'Over credit limit (₹...)'` | Warning |
| 9 | `'Overdue (... days)'` | Warning |
| 10 | `'Credit'` | Summary label |
| 11 | `'Payments'` | Summary label |
| 12 | `'Entries'` | Summary label |
| 13 | `'Add Credit'` / `'Add Credit Entry'` | Button |
| 14 | `'Record Payment'` | Button |
| 15 | `'Amount'` | Field label |
| 16 | `'Description (optional)'` | Field label |
| 17 | `'e.g., Grocery purchase'` | Field hint |
| 18 | `'e.g., Cash payment'` | Field hint |
| 19 | `'💵 Cash'` / `'📱 UPI'` / `'💳 Card'` | Payment mode chips |
| 20 | `'Today'` / `'Yesterday'` | Date labels |

---

### Inventory Feature

#### `lib/features/inventory/presentation/pages/inventory_page.dart`
| # | String | Context |
|---|--------|---------|
| 1 | `'Shop & Inventory'` | Page title |
| 2 | `'Low Stock'` | Filter badge |
| 3 | `'Search products...'` | Search hint |
| 4 | `'🛒 Shop'` | Tab label |
| 5 | `'📦 Inventory'` | Tab label |
| 6 | `'No products found'` | Empty state |
| 7 | `'Try changing filters or search'` | Empty state subtitle |
| 8 | `'Add Product'` | Button |
| 9 | `'items in cart'` | Cart badge |
| 10 | `'View Cart'` | Button |
| 11 | `'Your Cart'` | Sheet title |
| 12 | `'items'` | Count label |
| 13 | `'Subtotal'` | Label |
| 14 | `'Discount'` | Label |
| 15 | `'Total'` | Label |
| 16 | `'Clear'` | Button |
| 17 | `'Checkout'` | Section/button |
| 18 | `'Edit Product'` | Menu item |
| 19 | `'Product editing coming soon...'` | Snackbar |
| 20 | `'Close'` | Button |
| 21 | `'Update Stock'` | Menu item |
| 22 | `'Current:'` | Label |
| 23 | `'+ Add Stock'` / `'- Remove Stock'` | Buttons |
| 24 | `'Add Stock'` / `'Remove Stock'` | Dialog buttons |
| 25 | `'Stock added: ...'` / `'Stock removed: ...'` | Snackbar |
| 26 | `'Sale Complete!'` | Dialog title |
| 27 | `'Transaction has been recorded successfully'` | Dialog body |
| 28 | `'Done'` | Button |
| 29 | `'Out of stock'` / `'in stock'` | Status labels |
| 30 | `'OUT OF STOCK'` | Badge |
| 31 | `'Low'` | Stock badge |
| 32 | `'Delete'` | Menu item |
| 33 | `'Payment Mode'` | Section title |
| 34 | `'💵 Cash'` / `'📱 UPI'` / `'💳 Card'` | Payment mode chips |
| 35 | `'Add to Khata'` | Toggle label |
| 36 | `'Record as customer credit'` | Toggle subtitle |
| 37 | `'Select Customer'` | Dropdown label |
| 38 | `'Complete Sale'` | Button |
| 39 | `'Your cart is empty'` | Empty cart |

**Hardcoded product names (demo data)**:
`'Basmati Rice (5kg)'`, `'Toor Dal (1kg)'`, `'Loose Sugar (1kg)'`, `'Mustard Oil (1L)'`, `'Wheat Flour (5kg)'`, `'Salt (1kg)'`, `'Turmeric (200g)'`, `'Red Chilli (200g)'`, `'Tea Powder (250g)'`, `'Milk (1L)'`, `'Notebook'`, `'Pen (Pack of 5)'`, `'Pencil Box'`

#### `lib/features/inventory/presentation/pages/add_product_page.dart`
| # | String | Context |
|---|--------|---------|
| 1 | `'Add Product'` | Page title |
| 2 | `'Save'` | Button |
| 3 | `'Product Added!'` | Success dialog title |
| 4 | `'$name has been added to your inventory.'` | Success body |
| 5 | `'Add More'` | Button |
| 6 | `'Done'` | Button |
| 7 | `'Add Product Image'` | Section title |
| 8 | `'Tap to capture or select from gallery'` | Hint |
| 9 | `'Camera/Gallery coming soon'` | Snackbar |
| 10 | `'Basic Information'` | Section title |
| 11 | `'Product Name *'` | Field label |
| 12 | `'Enter product name'` | Field hint |
| 13 | `'SKU / Barcode'` | Field label |
| 14 | `'Scan or enter code'` | Field hint |
| 15 | `'Description (Optional)'` | Field label |
| 16 | `'Brief product description'` | Field hint |
| 17 | `'Category & Unit'` | Section title |
| 18 | `'Category'` | Field label |
| 19 | `'Unit'` | Field label |
| 20 | `'Pricing'` | Section title |
| 21 | `'Buy Price *'` | Field label |
| 22 | `'Cost'` | Field hint |
| 23 | `'Sell Price *'` | Field label |
| 24 | `'MRP'` | Field hint |
| 25 | `'Profit'` | Label |
| 26 | `'Margin'` | Label |
| 27 | `'Stock Management'` | Section title |
| 28 | `'Track Inventory'` | Toggle label |
| 29 | `'Enable stock tracking & low stock alerts'` | Toggle subtitle |
| 30 | `'Current Stock *'` | Field label |
| 31 | `'Qty'` | Field hint |
| 32 | `'Min Stock Alert'` | Field label |
| 33 | `'Low alert'` | Field hint |
| 34 | `'Quick Set: '` | Label |

**Hardcoded category names**: `'Grocery'`, `'Stationary'`, `'Electronics'`, `'Personal Care'`, `'Dairy'`, `'Beverages'`, `'Snacks'`, `'Household'`, `'Other'`

**Hardcoded unit names**: `'pcs'`, `'kg'`, `'g'`, `'L'`, `'ml'`, `'dozen'`, `'pack'`, `'box'`, `'meter'`, `'pair'`

---

### Settings Feature

#### `lib/features/settings/presentation/pages/settings_page.dart`
| # | String | Context |
|---|--------|---------|
| 1 | `'Settings'` | Page title |
| 2 | `'R'` | Hardcoded avatar initial |
| 3 | `'Ramesh Patel'` | Hardcoded user name |
| 4 | `'9876543210'` | Hardcoded phone |
| 5 | `'Appearance'` | Section title |
| 6 | `'Light'` | Theme option |
| 7 | `'Dark'` | Theme option |
| 8 | `'System'` | Theme option |
| 9 | `'Language'` | Section title |
| 10 | `'English'` | Language option |
| 11 | `'हिंदी (Hindi)'` | Language option |
| 12 | `'ગુજરાતી (Gujarati)'` | Language option |
| 13 | `'मराठी (Marathi)'` | Language option |
| 14 | `'Language set to $language'` | Snackbar |
| 15 | `'Payments'` | Section title |
| 16 | `'UPI QR Setup'` | Setting title |
| 17 | `'Configure UPI ID & QR code'` | Setting subtitle |
| 18 | `'Notifications'` | Section title |
| 19 | `'Push Notifications'` | Setting title |
| 20 | `'Payment reminders & alerts'` | Setting subtitle |
| 21 | `'Security'` | Section title |
| 22 | `'Biometric Lock'` | Setting title |
| 23 | `'Unlock app with fingerprint'` | Setting subtitle |
| 24 | `'Change PIN'` | Setting title |
| 25 | `'Update your security PIN'` | Setting subtitle |
| 26 | `'Coming soon'` | Snackbar (2x) |
| 27 | `'Data & Sync'` | Section title |
| 28 | `'Sync Now'` | Setting title |
| 29 | `'Never synced'` | Setting subtitle |
| 30 | `'Last: $date'` | Dynamic subtitle |
| 31 | `'Sync requires backend connection'` | Snackbar |
| 32 | `'Export Backup'` | Setting title |
| 33 | `'Download your data as JSON'` | Setting subtitle |
| 34 | `'Clear All Data'` | Setting title |
| 35 | `'Erase all local data permanently'` | Setting subtitle |
| 36 | `'About'` | Section title |
| 37 | `'Terms & Conditions'` | Setting title |
| 38 | `'Read our terms of service'` | Setting subtitle |
| 39 | `'Privacy Policy'` | Setting title |
| 40 | `'How we handle your data'` | Setting subtitle |
| 41 | `'Rate App'` | Setting title |
| 42 | `'Love KhataSetu? Rate us!'` | Setting subtitle |
| 43 | `'Clear All Data?'` | Dialog title |
| 44 | `'This will permanently erase all customers, transactions, and settings. This cannot be undone.'` | Dialog body |
| 45 | `'Cancel'` | Dialog button |
| 46 | `'Clear'` | Dialog button |
| 47 | `'All data cleared'` | Snackbar |

---

### Reports Feature

#### `lib/features/reports/presentation/pages/reports_page.dart`
| # | String | Context |
|---|--------|---------|
| 1 | `'Reports'` | AppBar title |
| 2 | `'Report Type'` | Section title |
| 3 | `'Daily'` | Report type |
| 4 | `'Weekly'` | Report type |
| 5 | `'Monthly'` | Report type |
| 6 | `'Yearly'` | Report type |
| 7 | `'Customer'` | Report type |
| 8 | `'Custom'` | Report type |
| 9 | `'Date Range'` | Section title |
| 10 | `'From'` | Date label |
| 11 | `'To'` | Date label |
| 12 | `'Select Customer'` | Section title |
| 13 | `'Choose a customer'` | Dropdown hint |
| 14 | `'Quick Reports'` | Section title |
| 15 | `'Today\'s Summary'` | Quick report title |
| 16 | `'This Month'` | Quick report title |
| 17 | `'Outstanding'` | Quick report title |
| 18 | `'Top Customers'` | Quick report title |
| 19 | `'transactions'` | Subtitle |
| 20 | `'Pending Dues'` | Subtitle |
| 21 | `'Active Debtors'` | Subtitle |
| 22 | `'Generate Report'` | Button |
| 23 | `'Report Generated!'` | Success title |
| 24 | `'Choose what to do with your PDF report'` | Subtitle |
| 25 | `'Preview & Print'` | Action title |
| 26 | `'Open PDF preview with print option'` | Action subtitle |
| 27 | `'Share PDF'` | Action title |
| 28 | `'Send via WhatsApp, Email, etc.'` | Action subtitle |
| 29 | `'Save to Device'` | Action title |
| 30 | `'Download PDF to your phone'` | Action subtitle |
| 31 | `'Saved to $path'` | Snackbar |
| 32 | `'Error generating report: $e'` | Error snackbar |
| 33 | `'Recent Activity'` | Section title |
| 34 | `'No transactions yet. Generate your first report after adding transactions.'` | Empty state |
| 35 | `'Unknown'` | Fallback customer name |

---

### Billing Feature

#### `lib/features/billing/presentation/pages/smart_billing_page.dart`
| # | String | Context |
|---|--------|---------|
| 1 | `'Smart Billing'` | AppBar title |
| 2 | `'Clear Bill?'` | Dialog title |
| 3 | `'This will remove all items from the current bill.'` | Dialog body |
| 4 | `'Cancel'` | Dialog button |
| 5 | `'Clear'` | Dialog button |
| 6 | `'Select Customer'` | Sheet/section title |
| 7 | `'Search items...'` | Search hint |
| 8 | `'No items found'` | Empty state |
| 9 | `'Create Bill'` | Button |
| 10 | `'Bill Created!'` | Success title |
| 11 | `'Share'` | Button |
| 12 | `'Print'` | Button |
| 13 | `'New Bill'` | Button |
| 14 | `'Please select a customer first'` | Error snackbar |
| 15 | `'Please add items to the bill'` | Error snackbar |
| 16 | `'Error generating bill: $e'` | Error snackbar |
| 17 | `'My Shop'` | Hardcoded shop name |
| 18 | `'123 Main Street, Village'` | Hardcoded address |
| 19 | `'9876543210'` | Hardcoded phone |
| 20 | `'Cart ($n items)'` | Sheet title |
| 21 | `'Your cart is empty'` | Empty cart |
| 22 | `'Add notes (optional)'` | Field hint |
| 23 | `'Due'` / `'Adv'` | Balance labels |
| 24 | `'$name has taken $items'` | Bill description |

**Hardcoded category names**: `'All'`, `'Grocery'`, `'Snacks'`, `'Beverages'`, `'Dairy'`, `'Personal Care'`

**Hardcoded product items (22 items)**: `'Rice (1kg)'`, `'Dal (1kg)'`, `'Atta (5kg)'`, `'Sugar (1kg)'`, `'Salt (1kg)'`, `'Oil (1L)'`, `'Biscuit Packet'`, `'Chips'`, `'Chocolate'`, `'Namkeen'`, `'Candy Pack'`, `'Cold Drink (2L)'`, `'Juice (1L)'`, `'Tea (250g)'`, `'Coffee (100g)'`, `'Milk (1L)'`, `'Curd (500g)'`, `'Paneer (200g)'`, `'Butter (100g)'`, `'Soap'`, `'Shampoo'`, `'Toothpaste'`

---

### UPI Feature

#### `lib/features/upi/presentation/pages/upi_setup_page.dart`
| # | String | Context |
|---|--------|---------|
| 1 | `'UPI Setup'` | AppBar title |
| 2 | `'UPI Details'` | Section title |
| 3 | `'UPI ID *'` | Field label |
| 4 | `'yourname@upi'` | Field hint |
| 5 | `'UPI ID is required'` | Validation |
| 6 | `'Enter a valid UPI ID (e.g. name@bank)'` | Validation |
| 7 | `'Shop Name *'` | Field label |
| 8 | `'Name shown on UPI payment'` | Field hint |
| 9 | `'Shop name is required'` | Validation |
| 10 | `'Shop name must be at least 2 characters'` | Validation |
| 11 | `'Merchant Code (Optional)'` | Field label |
| 12 | `'e.g. 5411 for Grocery Stores'` | Field hint |
| 13 | `'QR Code Image'` | Section title |
| 14 | `'Upload an existing QR code image or use the auto-generated one from your UPI ID.'` | Description |
| 15 | `'Unable to load QR image'` | Error fallback |
| 16 | `'Replace'` | Button |
| 17 | `'Remove'` | Button |
| 18 | `'Tap to upload QR image'` | Hint |
| 19 | `'PNG, JPG up to 1MB'` | Hint |
| 20 | `'UPI URI Preview'` | Section title |
| 21 | `'Update UPI Details'` / `'Save UPI Details'` | Dynamic button |
| 22 | `'Save UPI details first, then upload QR image'` | Snackbar |
| 23 | `'UPI details saved!'` | Success snackbar |
| 24 | `'QR image updated'` | Success snackbar |
| 25 | `'Failed to pick image: $e'` | Error snackbar |

#### `lib/features/upi/presentation/pages/upi_qr_display_page.dart`
| # | String | Context |
|---|--------|---------|
| 1 | `'UPI Not Configured'` | Empty state title |
| 2 | `'Set up your UPI details in Settings first.'` | Empty state body |
| 3 | `'Go Back'` | Button |
| 4 | `'Payment from $customerName'` | Header text |
| 5 | `'Amount: ₹...'` | Display |
| 6 | `'Scan with any UPI app'` | Hint |
| 7 | `'Copy UPI ID'` | Action button |
| 8 | `'Share QR'` | Action button |
| 9 | `'Normal'` / `'Brighten'` | Toggle label |
| 10 | `'Normal Brightness'` / `'Max Brightness'` | Tooltip |
| 11 | `'UPI ID copied: $id'` | Snackbar |
| 12 | `'Pay $amount to $shopName via UPI\nUPI ID: $id'` | Share text |
| 13 | `'Failed to share: $e'` | Error snackbar |
| 14 | `'Payment Received — ₹$amount'` | Confirm button |
| 15 | `'Payment Recorded!'` | Success title |
| 16 | `'₹$amount from $customerName'` | Success body |
| 17 | `'Balance updated automatically'` | Success note |
| 18 | `'Done'` | Button |
| 19 | `'UPI Payment from $customerName'` | Transaction desc |

---

### Shared Widgets

#### `lib/shared/widgets/customer_card.dart`
| # | String | Context |
|---|--------|---------|
| 1 | `'To Collect'` | Balance label |
| 2 | `'Advance'` | Balance label |
| 3 | `'Low Risk'` | Risk badge |
| 4 | `'Medium'` | Risk badge |
| 5 | `'High Risk'` | Risk badge |
| 6 | `'Today'` | Date label |
| 7 | `'Yesterday'` | Date label |
| 8 | `'$n days ago'` | Date label |
| 9 | `'$n weeks ago'` | Date label |
| 10 | `'$n months ago'` | Date label |

#### `lib/shared/widgets/product_card.dart`
| # | String | Context |
|---|--------|---------|
| 1 | `'Low'` | Stock badge |
| 2 | `'$stock pcs'` | Stock display (hardcoded unit) |
| 3 | `'Out of Stock'` | Status label |
| 4 | `'$stock in stock'` | Status label |

#### `lib/shared/widgets/transaction_card.dart`
| # | String | Context |
|---|--------|---------|
| 1 | `'Yesterday'` | Date label |

#### `lib/shared/widgets/loading_states.dart`
| # | String | Context |
|---|--------|---------|
| 1 | `'Something went wrong'` | ErrorState default title |
| 2 | `'Try Again'` | ErrorState button |
| 3 | `'Search...'` | CustomSearchField default hint |

#### `lib/shared/widgets/bill_summary_widget.dart`
| # | String | Context |
|---|--------|---------|
| 1 | `'$name has taken $items and $lastItem'` | Natural language summary |
| 2 | `'+ $n more items'` | Overflow label |
| 3 | `'Total: $n items'` | Footer |

#### `lib/shared/widgets/custom_button.dart`
No hardcoded user-facing strings (purely parametric).

#### `lib/shared/widgets/custom_text_field.dart`
No hardcoded user-facing strings (purely parametric).

#### `lib/shared/widgets/stat_card.dart`
No hardcoded user-facing strings (purely parametric).

---

### PDF Report Service

#### `lib/core/services/pdf_report_service.dart`
| # | String | Context |
|---|--------|---------|
| 1 | `'₹'` | `_currencySymbol` constant |
| 2 | `'Daily Report - $date'` | PDF header |
| 3 | `'Weekly Report'` | PDF header |
| 4 | `'Monthly Report - $month'` | PDF header |
| 5 | `'Yearly Report - $year'` | PDF header |
| 6 | `'Customer Statement - $name'` | PDF header |
| 7 | `'Custom Report'` | PDF header |
| 8 | `'Period'` | Label |
| 9 | `'Generated by KhataSetu on $date at $time'` | Footer |
| 10 | `'Page $n of $total'` | Page numbers |
| 11 | `'Total Credit'` | Summary label |
| 12 | `'Total Debit'` | Summary label |
| 13 | `'Net Balance'` | Summary label |
| 14 | `'Transactions'` | Summary label |
| 15 | `'Date'`, `'Customer'`, `'Description'`, `'Type'`, `'Amount'` | Table headers |
| 16 | `'Category Breakdown'` | Section title |
| 17 | `'INVOICE'` | Bill header |
| 18 | `'Bill No: $n'` | Bill label |
| 19 | `'Date: $date'` | Bill label |
| 20 | `'Bill To: '` | Bill label |
| 21 | `'#'`, `'Item'`, `'Qty'`, `'Unit'`, `'Price'`, `'Total'` | Bill table headers |
| 22 | `'Subtotal'` | Totals label |
| 23 | `'Discount'` | Totals label |
| 24 | `'Previous Balance'` | Totals label |
| 25 | `'Grand Total'` | Totals label |
| 26 | `'Notes:'` | Section label |
| 27 | `'Thank you for your business!'` | Bill footer |
| 28 | `'Generated by KhataSetu'` | Bill footer |
| 29 | `'Customer Statement'` | Statement header |
| 30 | `'Customer'` | Label |
| 31 | `'Opening Balance'` | Label |
| 32 | `'Closing Balance'` | Label |
| 33 | `'(Due)'` / `'(Advance)'` | Balance suffix |
| 34 | `'Debit'`, `'Credit'`, `'Balance'` | Statement table headers |
| 35 | `'Phone: $phone'` | Bill header |
| 36 | `'KhataSetu Report - $fileName'` | Share subject |

---

## 3. String Categories Summary

| Category | Approx. Count | Examples |
|----------|---------------|---------|
| **Page/Section Titles** | ~45 | `'Settings'`, `'Reports'`, `'Quick Actions'` |
| **Button Labels** | ~40 | `'Save'`, `'Done'`, `'Cancel'`, `'Delete'`, `'Login'` |
| **Form Labels & Hints** | ~60 | `'Phone Number'`, `'Enter full name'`, `'Search...'` |
| **Validation Messages** | ~25 | `'Phone number is required'`, `'Enter a valid amount'` |
| **Snackbar/Toast Messages** | ~30 | `'Coming soon'`, `'UPI details saved!'`, `'All data cleared'` |
| **Dialog Titles & Bodies** | ~20 | `'Clear All Data?'`, `'Bill Created!'`, `'Delete Customer?'` |
| **Status/Badge Labels** | ~20 | `'Low Risk'`, `'Out of Stock'`, `'To Collect'`, `'Advance'` |
| **Date/Time Labels** | ~10 | `'Today'`, `'Yesterday'`, `'$n days ago'` |
| **Chart/Report Labels** | ~15 | `'Collection'`, `'Credit'`, `'Total Credit'`, `'Net Balance'` |
| **Empty State Messages** | ~12 | `'No customers found'`, `'Your khata is empty'` |
| **Navigation Labels** | ~5 | `'Home'`, `'Customers'`, `'Ledger'`, `'Inventory'`, `'Settings'` |
| **PDF/Print Strings** | ~36 | `'INVOICE'`, `'Grand Total'`, `'Thank you for your business!'` |
| **Demo/Hardcoded Data** | ~40 | Product names, user names, shop names, business types |
| **Domain Terms** | ~15 | `'Udhar'`, `'Khata'`, `'Credit (Udhar)'`, `'Trust Score'` |
| **Payment Mode Labels** | ~8 | `'Cash'`, `'UPI'`, `'Card'`, `'Bank'`, `'Other'` |
| **Greeting/Branding** | ~5 | `'Good Morning,'`, `'KhataSetu'`, `'Your Digital Udhar Partner'` |

---

## 4. Estimated String Count

| Scope | Unique Strings |
|-------|---------------|
| Core layer (constants, validators, router) | ~33 |
| Auth pages (login, register, splash) | ~60 |
| Home pages (home, dashboard) | ~42 |
| Customer pages (list, details, add) | ~80 |
| Ledger pages (book, add txn, timeline) | ~65 |
| Inventory pages (list, add product) | ~70 |
| Settings page | ~47 |
| Reports page | ~35 |
| Billing page | ~50 |
| UPI pages (setup, QR display) | ~45 |
| Shared widgets | ~20 |
| PDF Report Service | ~36 |
| **TOTAL** | **~580 unique strings** |

After deduplication (many strings like `'Today'`, `'Cancel'`, `'Done'` repeat across files):

**~420 unique translation keys needed.**

---

## 5. Recommendations

### 5.1 Approach
Use **Flutter's built-in `intl` + ARB files** (`flutter_localizations` already in deps):
1. Add `l10n.yaml` configuration
2. Generate `AppLocalizations` via `flutter gen-l10n`
3. Create `lib/l10n/app_en.arb` as the template ARB file
4. Add `app_hi.arb`, `app_gu.arb`, `app_mr.arb` for target locales

### 5.2 Key Structure Proposal
```
lib/l10n/
  app_en.arb          # ~420 keys
  app_hi.arb           # Hindi
  app_gu.arb           # Gujarati
  app_mr.arb           # Marathi
l10n.yaml              # Gen config
```

### 5.3 Migration Priority

| Priority | Area | String Count | Rationale |
|----------|------|-------------|-----------|
| 🔴 P0 | Navigation labels, page titles, common buttons | ~30 | Visible on every screen |
| 🔴 P0 | Validation messages (validators.dart) | ~25 | Central, single file change |
| 🟡 P1 | Dashboard, customer pages, ledger pages | ~180 | Most-used screens |
| 🟡 P1 | Shared widgets (customer_card, etc.) | ~20 | Reused everywhere |
| 🟢 P2 | Settings, reports, billing, UPI pages | ~150 | Less frequently accessed |
| 🟢 P2 | PDF service strings | ~36 | Requires PDF font support for Devanagari/Gujarati |
| ⚪ P3 | Demo/hardcoded data (product names, user names) | ~40 | Should be replaced with real data, not i18n |

### 5.4 Special Considerations
- **Currency formatting**: Use `NumberFormat.currency()` from `intl` instead of hardcoded `'₹'`
- **Date formatting**: Already using `DateFormat` from `intl` — ensure locale-aware: `DateFormat.yMMMMd(locale)`
- **Plurals**: Some strings need ICU plural support: `'{count, plural, one{1 item} other{{count} items}}'`
- **Parameterized strings**: ~30% of strings contain interpolated values (`$name`, `$amount`) — use `@placeholders` in ARB
- **PDF Rendering**: Devanagari/Gujarati fonts must be bundled for `pdf` package (NotoSansDevanagari, NotoSansGujarati)
- **Hardcoded demo data**: `'Ramesh Patel'`, `'9876543210'`, `'Main Branch - Village Center'`, product names — these should be removed from code entirely, not translated
