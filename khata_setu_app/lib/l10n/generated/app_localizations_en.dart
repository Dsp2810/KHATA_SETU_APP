// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'KhataSetu';

  @override
  String get appTagline => 'Digital Udhar & Inventory Management';

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get update => 'Update';

  @override
  String get search => 'Search';

  @override
  String get filter => 'Filter';

  @override
  String get share => 'Share';

  @override
  String get print => 'Print';

  @override
  String get download => 'Download';

  @override
  String get close => 'Close';

  @override
  String get done => 'Done';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get ok => 'OK';

  @override
  String get confirm => 'Confirm';

  @override
  String get retry => 'Retry';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get skip => 'Skip';

  @override
  String get submit => 'Submit';

  @override
  String get clear => 'Clear';

  @override
  String get reset => 'Reset';

  @override
  String get apply => 'Apply';

  @override
  String get copy => 'Copy';

  @override
  String get selectAll => 'Select All';

  @override
  String get loading => 'Loading...';

  @override
  String get pleaseWait => 'Please wait...';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get noDataFound => 'No data found';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get tryAgain => 'Try again';

  @override
  String get success => 'Success';

  @override
  String get error => 'Error';

  @override
  String get warning => 'Warning';

  @override
  String get info => 'Info';

  @override
  String get navHome => 'Home';

  @override
  String get navCustomers => 'Customers';

  @override
  String get navLedger => 'Ledger';

  @override
  String get navInventory => 'Inventory';

  @override
  String get navSettings => 'Settings';

  @override
  String get welcome => 'Welcome';

  @override
  String get welcomeBack => 'Welcome Back!';

  @override
  String get loginTitle => 'Login';

  @override
  String get registerTitle => 'Create Account';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get phoneHint => 'Enter 10-digit mobile number';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get confirmPasswordHint => 'Re-enter your password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get loginButton => 'Login';

  @override
  String get registerButton => 'Register';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get signUp => 'Sign Up';

  @override
  String get signIn => 'Sign In';

  @override
  String get orContinueWith => 'Or continue with';

  @override
  String get enterOtp => 'Enter OTP';

  @override
  String otpSentTo(String phone) {
    return 'OTP sent to $phone';
  }

  @override
  String get resendOtp => 'Resend OTP';

  @override
  String resendIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get verifyOtp => 'Verify OTP';

  @override
  String get shopName => 'Shop Name';

  @override
  String get shopNameHint => 'Enter your shop name';

  @override
  String get ownerName => 'Owner Name';

  @override
  String get ownerNameHint => 'Enter owner name';

  @override
  String get address => 'Address';

  @override
  String get addressHint => 'Enter shop address';

  @override
  String get setPin => 'Set PIN';

  @override
  String get enterPin => 'Enter PIN';

  @override
  String get loginDemoMode => 'Login (Demo Mode)';

  @override
  String get loginSubtitle => 'Enter your phone number to continue';

  @override
  String get splashTagline => 'Your Digital Udhar Khata';

  @override
  String get getStarted => 'Get Started';

  @override
  String get continueText => 'Continue';

  @override
  String get loginSuccess => 'Login successful!';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get goodMorning => 'Good Morning';

  @override
  String get goodAfternoon => 'Good Afternoon';

  @override
  String get goodEvening => 'Good Evening';

  @override
  String greeting(String greeting, String name) {
    return '$greeting, $name!';
  }

  @override
  String get totalOutstanding => 'Total Outstanding';

  @override
  String get todayCollection => 'Today\'s Collection';

  @override
  String get todayCredit => 'Today\'s Credit';

  @override
  String get totalCustomers => 'Total Customers';

  @override
  String get activeCustomers => 'Active Customers';

  @override
  String get recentTransactions => 'Recent Transactions';

  @override
  String get viewAll => 'View All';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get addCustomer => 'Add Customer';

  @override
  String get addTransaction => 'Add Transaction';

  @override
  String get generateReport => 'Generate Report';

  @override
  String get collectPayment => 'Collect Payment';

  @override
  String get weeklyOverview => 'Weekly Overview';

  @override
  String get monthlyOverview => 'Monthly Overview';

  @override
  String get noTransactionsYet => 'No transactions yet';

  @override
  String get startByAddingCustomer => 'Start by adding your first customer';

  @override
  String get topDebtors => 'Top Debtors';

  @override
  String get creditGiven => 'Credit Given';

  @override
  String get paymentReceived => 'Payment Received';

  @override
  String get netBalance => 'Net Balance';

  @override
  String get totalCredit => 'Total Credit';

  @override
  String get totalDebit => 'Total Debit';

  @override
  String get overviewStats => 'Overview Stats';

  @override
  String get smartBilling => 'Smart Billing';

  @override
  String get reports => 'Reports';

  @override
  String get customers => 'Customers';

  @override
  String get customer => 'Customer';

  @override
  String get searchCustomers => 'Search customers...';

  @override
  String get addNewCustomer => 'Add New Customer';

  @override
  String get editCustomer => 'Edit Customer';

  @override
  String get customerName => 'Customer Name';

  @override
  String get customerNameHint => 'Enter customer name';

  @override
  String get customerPhone => 'Phone Number';

  @override
  String get customerPhoneHint => 'Enter phone number';

  @override
  String get customerEmail => 'Email (Optional)';

  @override
  String get customerEmailHint => 'Enter email address';

  @override
  String get customerAddress => 'Address (Optional)';

  @override
  String get customerAddressHint => 'Enter address';

  @override
  String get customerNotes => 'Notes (Optional)';

  @override
  String get customerNotesHint => 'Any additional notes...';

  @override
  String get customerDetails => 'Customer Details';

  @override
  String get customerBalance => 'Balance';

  @override
  String customerOwes(String name) {
    return '$name owes';
  }

  @override
  String youOwe(String name) {
    return 'You owe $name';
  }

  @override
  String get settled => 'Settled';

  @override
  String get trustScore => 'Trust Score';

  @override
  String get lastTransaction => 'Last Transaction';

  @override
  String get noCustomersYet => 'No customers yet';

  @override
  String get noCustomersSubtitle =>
      'Add your first customer to start tracking credit';

  @override
  String get customerAdded => 'Customer added successfully!';

  @override
  String get customerUpdated => 'Customer updated successfully!';

  @override
  String get customerDeleted => 'Customer deleted';

  @override
  String get deleteCustomerTitle => 'Delete Customer?';

  @override
  String deleteCustomerMessage(String name) {
    return 'This will permanently delete $name and all their transactions. This cannot be undone.';
  }

  @override
  String totalCustomersCount(int count) {
    return '$count customers';
  }

  @override
  String get sortBy => 'Sort By';

  @override
  String get sortByName => 'Name';

  @override
  String get sortByBalance => 'Balance';

  @override
  String get sortByRecent => 'Recent';

  @override
  String get filterAll => 'All';

  @override
  String get filterOwing => 'Owing';

  @override
  String get filterAdvance => 'Advance';

  @override
  String get filterSettled => 'Settled';

  @override
  String customerSince(String date) {
    return 'Customer since $date';
  }

  @override
  String get transactionHistory => 'Transaction History';

  @override
  String get sendReminder => 'Send Reminder';

  @override
  String get shareStatement => 'Share Statement';

  @override
  String get callCustomer => 'Call';

  @override
  String get messageCustomer => 'Message';

  @override
  String get ledger => 'Ledger';

  @override
  String get dailyBook => 'Daily Book';

  @override
  String get addNewTransaction => 'New Transaction';

  @override
  String get transactionType => 'Transaction Type';

  @override
  String get creditUdhar => 'Credit (Udhar)';

  @override
  String get creditDescription => 'Customer owes you';

  @override
  String get debitPayment => 'Payment (Vasuli)';

  @override
  String get debitDescription => 'Customer paid you';

  @override
  String get amount => 'Amount';

  @override
  String get amountHint => 'Enter amount';

  @override
  String get description => 'Description';

  @override
  String get descriptionHint => 'What is this for?';

  @override
  String get selectCustomer => 'Select Customer';

  @override
  String get selectCustomerHint => 'Choose a customer';

  @override
  String get transactionDate => 'Date';

  @override
  String get addItems => 'Add Items';

  @override
  String get itemName => 'Item Name';

  @override
  String get itemNameHint => 'Enter item name';

  @override
  String get quantity => 'Quantity';

  @override
  String get quantityHint => 'Qty';

  @override
  String get unitPrice => 'Price';

  @override
  String get unitPriceHint => '₹ Price';

  @override
  String get unit => 'Unit';

  @override
  String get total => 'Total';

  @override
  String get pcs => 'pcs';

  @override
  String get kg => 'kg';

  @override
  String get litre => 'litre';

  @override
  String get metre => 'metre';

  @override
  String get dozen => 'dozen';

  @override
  String get box => 'box';

  @override
  String get packet => 'packet';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get grandTotal => 'Grand Total';

  @override
  String get transactionAdded => 'Transaction added successfully!';

  @override
  String get transactionDeleted => 'Transaction deleted';

  @override
  String get undoDelete => 'Undo';

  @override
  String get noTransactions => 'No transactions';

  @override
  String get noTransactionsSubtitle =>
      'Add your first transaction to start tracking';

  @override
  String get todayTransactions => 'Today\'s Transactions';

  @override
  String get thisWeek => 'This Week';

  @override
  String get thisMonth => 'This Month';

  @override
  String get allTransactions => 'All Transactions';

  @override
  String get filterByDate => 'Filter by Date';

  @override
  String get filterByType => 'Filter by Type';

  @override
  String get allTypes => 'All Types';

  @override
  String get creditOnly => 'Credit Only';

  @override
  String get debitOnly => 'Debit Only';

  @override
  String transactionCount(int count) {
    return '$count transactions';
  }

  @override
  String creditAmountLabel(String amount) {
    return 'Credit: $amount';
  }

  @override
  String debitAmountLabel(String amount) {
    return 'Debit: $amount';
  }

  @override
  String get paymentMode => 'Payment Mode';

  @override
  String get cash => 'Cash';

  @override
  String get upi => 'UPI';

  @override
  String get bank => 'Bank Transfer';

  @override
  String get otherPayment => 'Other';

  @override
  String get addMoreItems => 'Add More Items';

  @override
  String get removeItem => 'Remove Item';

  @override
  String itemTotal(String amount) {
    return 'Item Total: $amount';
  }

  @override
  String get saveTransaction => 'Save Transaction';

  @override
  String get timeline => 'Timeline';

  @override
  String get inventory => 'Inventory';

  @override
  String get products => 'Products';

  @override
  String get searchProducts => 'Search products...';

  @override
  String get addProduct => 'Add Product';

  @override
  String get editProduct => 'Edit Product';

  @override
  String get productName => 'Product Name';

  @override
  String get productNameHint => 'Enter product name';

  @override
  String get productPrice => 'Selling Price';

  @override
  String get productPriceHint => 'Enter selling price';

  @override
  String get costPrice => 'Cost Price (Optional)';

  @override
  String get costPriceHint => 'Enter cost price';

  @override
  String get category => 'Category';

  @override
  String get categoryHint => 'Select category';

  @override
  String get sku => 'SKU / Barcode';

  @override
  String get skuHint => 'Enter SKU or barcode';

  @override
  String get currentStock => 'Current Stock';

  @override
  String get stockHint => 'Enter current stock';

  @override
  String get lowStockAlert => 'Low Stock Alert';

  @override
  String get lowStockThreshold => 'Alert when stock below';

  @override
  String get productAdded => 'Product added successfully!';

  @override
  String get productUpdated => 'Product updated!';

  @override
  String get productDeleted => 'Product deleted';

  @override
  String get noProductsYet => 'No products yet';

  @override
  String get noProductsSubtitle => 'Add products to manage your inventory';

  @override
  String get inStock => 'In Stock';

  @override
  String get lowStock => 'Low Stock';

  @override
  String get outOfStock => 'Out of Stock';

  @override
  String stockCount(int count) {
    return '$count items';
  }

  @override
  String get allProducts => 'All';

  @override
  String get categoriesFilter => 'Categories';

  @override
  String get totalProducts => 'Total Products';

  @override
  String get totalStockValue => 'Stock Value';

  @override
  String get lowStockItems => 'Low Stock Items';

  @override
  String get groceries => 'Groceries';

  @override
  String get dairy => 'Dairy';

  @override
  String get snacks => 'Snacks';

  @override
  String get beverages => 'Beverages';

  @override
  String get household => 'Household';

  @override
  String get personal => 'Personal Care';

  @override
  String get stationery => 'Stationery';

  @override
  String get otherCategory => 'Other';

  @override
  String stockQuantity(String count) {
    return 'Stock: $count';
  }

  @override
  String profitMargin(String percent) {
    return 'Margin: $percent%';
  }

  @override
  String get billing => 'Billing';

  @override
  String get smartBillingTitle => 'Smart Billing';

  @override
  String get newBill => 'New Bill';

  @override
  String get billNumber => 'Bill No.';

  @override
  String get billDate => 'Date';

  @override
  String get billTo => 'Bill To';

  @override
  String get selectCustomerForBill => 'Select Customer';

  @override
  String get addItemsToBill => 'Add Items to Bill';

  @override
  String get billSummary => 'Bill Summary';

  @override
  String get discount => 'Discount';

  @override
  String get discountHint => 'Enter discount';

  @override
  String get previousBalance => 'Previous Balance';

  @override
  String get payableAmount => 'Payable Amount';

  @override
  String get generateBill => 'Generate Bill';

  @override
  String get billGenerated => 'Bill generated successfully!';

  @override
  String get shareBill => 'Share Bill';

  @override
  String get printBill => 'Print Bill';

  @override
  String get saveBill => 'Save Bill';

  @override
  String get noBillsYet => 'No bills yet';

  @override
  String get searchBilling => 'Search items...';

  @override
  String get cart => 'Cart';

  @override
  String get cartEmpty => 'Cart is empty';

  @override
  String get cartEmptySubtitle => 'Add items from the catalog to create a bill';

  @override
  String get catalog => 'Catalog';

  @override
  String get addToCart => 'Add to Cart';

  @override
  String get removeFromCart => 'Remove';

  @override
  String get clearCart => 'Clear Cart';

  @override
  String itemsInCart(int count) {
    return '$count items in cart';
  }

  @override
  String get checkout => 'Checkout';

  @override
  String get todayBills => 'Today\'s Bills';

  @override
  String get invoiceTitle => 'INVOICE';

  @override
  String get thankYouBusiness => 'Thank you for your business!';

  @override
  String get generatedByApp => 'Generated by KhataSetu';

  @override
  String get reportsTitle => 'Reports';

  @override
  String get dailyReport => 'Daily Report';

  @override
  String get weeklyReport => 'Weekly Report';

  @override
  String get monthlyReport => 'Monthly Report';

  @override
  String get yearlyReport => 'Yearly Report';

  @override
  String get customReport => 'Custom Report';

  @override
  String get customerStatement => 'Customer Statement';

  @override
  String get selectReportType => 'Select Report Type';

  @override
  String get selectDateRange => 'Select Date Range';

  @override
  String get dateRange => 'Date Range';

  @override
  String get startDate => 'Start Date';

  @override
  String get endDate => 'End Date';

  @override
  String get generateReportButton => 'Generate Report';

  @override
  String get reportGenerated => 'Report generated successfully!';

  @override
  String get reportGenerating => 'Generating report...';

  @override
  String reportError(String error) {
    return 'Error generating report: $error';
  }

  @override
  String get previewAndPrint => 'Preview & Print';

  @override
  String get previewAndPrintSubtitle => 'Open PDF preview with print option';

  @override
  String get sharePdf => 'Share PDF';

  @override
  String get sharePdfSubtitle => 'Send via WhatsApp, Email, etc.';

  @override
  String get saveToDevice => 'Save to Device';

  @override
  String get saveToDeviceSubtitle => 'Download PDF to your phone';

  @override
  String savedTo(String path) {
    return 'Saved to $path';
  }

  @override
  String get chooseAction => 'Choose what to do with your PDF report';

  @override
  String get quickReports => 'Quick Reports';

  @override
  String get todayTotal => 'Today\'s Total';

  @override
  String get monthTotal => 'Month\'s Total';

  @override
  String get outstanding => 'Outstanding';

  @override
  String get debtors => 'Debtors';

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String get period => 'Period';

  @override
  String get transactions => 'Transactions';

  @override
  String get categoryBreakdown => 'Category Breakdown';

  @override
  String get closingBalance => 'Closing Balance';

  @override
  String get openingBalance => 'Opening Balance';

  @override
  String get due => 'Due';

  @override
  String get advance => 'Advance';

  @override
  String get reportCustomerName => 'Customer';

  @override
  String get reportDescription => 'Description';

  @override
  String get reportType => 'Type';

  @override
  String get settings => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get language => 'Language';

  @override
  String get payments => 'Payments';

  @override
  String get notifications => 'Notifications';

  @override
  String get security => 'Security';

  @override
  String get dataAndSync => 'Data & Sync';

  @override
  String get about => 'About';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get systemTheme => 'System';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get pushNotificationsSubtitle => 'Payment reminders & alerts';

  @override
  String get biometricLock => 'Biometric Lock';

  @override
  String get biometricLockSubtitle => 'Unlock app with fingerprint';

  @override
  String get changePin => 'Change PIN';

  @override
  String get changePinSubtitle => 'Update your security PIN';

  @override
  String get syncNow => 'Sync Now';

  @override
  String get syncNowSubtitle => 'Never synced';

  @override
  String lastSynced(String time) {
    return 'Last: $time';
  }

  @override
  String get syncRequiresBackend => 'Sync requires backend connection';

  @override
  String get exportBackup => 'Export Backup';

  @override
  String get exportBackupSubtitle => 'Download your data as JSON';

  @override
  String get clearAllData => 'Clear All Data';

  @override
  String get clearAllDataSubtitle => 'Erase all local data permanently';

  @override
  String get clearAllDataTitle => 'Clear All Data?';

  @override
  String get clearAllDataMessage =>
      'This will permanently erase all customers, transactions, and settings. This cannot be undone.';

  @override
  String get allDataCleared => 'All data cleared';

  @override
  String get termsAndConditions => 'Terms & Conditions';

  @override
  String get termsSubtitle => 'Read our terms of service';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get privacySubtitle => 'How we handle your data';

  @override
  String get rateApp => 'Rate App';

  @override
  String get rateAppSubtitle => 'Love KhataSetu? Rate us!';

  @override
  String languageChanged(String language) {
    return 'Language changed to $language';
  }

  @override
  String get upiQrSetup => 'UPI QR Setup';

  @override
  String get upiQrSetupSubtitle => 'Configure UPI ID & QR code';

  @override
  String get upiSetup => 'UPI Setup';

  @override
  String get upiId => 'UPI ID';

  @override
  String get upiIdHint => 'Enter UPI ID (e.g., name@upi)';

  @override
  String get merchantName => 'Merchant Name';

  @override
  String get merchantNameHint => 'Your shop/business name';

  @override
  String get uploadQr => 'Upload QR';

  @override
  String get uploadQrSubtitle => 'Upload your UPI QR code image';

  @override
  String get replaceImage => 'Replace';

  @override
  String get removeImage => 'Remove';

  @override
  String get generateQr => 'Generate QR';

  @override
  String get scanToPay => 'Scan to Pay';

  @override
  String payAmount(String amount) {
    return 'Pay $amount';
  }

  @override
  String get upiSaved => 'UPI configuration saved!';

  @override
  String get upiRemoved => 'UPI configuration removed';

  @override
  String get noUpiSetup => 'No UPI configured';

  @override
  String get noUpiSubtitle => 'Set up your UPI to accept digital payments';

  @override
  String get shareQr => 'Share QR';

  @override
  String paymentTo(String name) {
    return 'Payment to $name';
  }

  @override
  String get poweredByUpi => 'Powered by UPI';

  @override
  String get tapToShowQr => 'Show QR';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get selectLanguageSubtitle => 'Choose your preferred language';

  @override
  String get english => 'English';

  @override
  String get gujarati => 'ગુજરાતી';

  @override
  String get hindi => 'हिंदी';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageGujarati => 'Gujarati';

  @override
  String get languageHindi => 'Hindi';

  @override
  String fieldRequired(String field) {
    return '$field is required';
  }

  @override
  String get phoneRequired => 'Phone number is required';

  @override
  String get phoneInvalid => 'Enter a valid 10-digit phone number';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordMinLength => 'Password must be at least 8 characters';

  @override
  String get passwordUppercase =>
      'Password must contain at least one uppercase letter';

  @override
  String get passwordLowercase =>
      'Password must contain at least one lowercase letter';

  @override
  String get passwordNumber => 'Password must contain at least one number';

  @override
  String get passwordSpecial =>
      'Password must contain at least one special character';

  @override
  String get pinRequired => 'PIN is required';

  @override
  String pinLength(int length) {
    return 'PIN must be $length digits';
  }

  @override
  String get pinDigitsOnly => 'PIN must contain only digits';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get nameMinLength => 'Name must be at least 2 characters';

  @override
  String get nameMaxLength => 'Name cannot exceed 100 characters';

  @override
  String get emailInvalid => 'Enter a valid email address';

  @override
  String get amountRequired => 'Amount is required';

  @override
  String get amountInvalid => 'Enter a valid amount';

  @override
  String get amountPositive => 'Amount must be greater than 0';

  @override
  String amountMaxExceeded(String symbol, String max) {
    return 'Amount cannot exceed $symbol$max';
  }

  @override
  String get otpRequired => 'OTP is required';

  @override
  String otpLength(int length) {
    return 'OTP must be $length digits';
  }

  @override
  String get otpDigitsOnly => 'OTP must contain only digits';

  @override
  String get shopNameRequired => 'Shop name is required';

  @override
  String get shopNameMinLength => 'Shop name must be at least 2 characters';

  @override
  String get shopNameMaxLength => 'Shop name cannot exceed 150 characters';

  @override
  String get addressRequired => 'Address is required';

  @override
  String get addressMinLength => 'Please enter a complete address';

  @override
  String get addressMaxLength => 'Address cannot exceed 500 characters';

  @override
  String get quantityRequired => 'Quantity is required';

  @override
  String get quantityInvalid => 'Enter a valid quantity';

  @override
  String get quantityNegative => 'Quantity cannot be negative';

  @override
  String get confirmPasswordRequired => 'Confirm password is required';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String pdfDailyReport(String date) {
    return 'Daily Report - $date';
  }

  @override
  String get pdfWeeklyReport => 'Weekly Report';

  @override
  String pdfMonthlyReport(String month) {
    return 'Monthly Report - $month';
  }

  @override
  String pdfYearlyReport(String year) {
    return 'Yearly Report - $year';
  }

  @override
  String pdfCustomerStatement(String name) {
    return 'Customer Statement - $name';
  }

  @override
  String get pdfCustomReport => 'Custom Report';

  @override
  String pdfGeneratedBy(String date, String time) {
    return 'Generated by KhataSetu on $date at $time';
  }

  @override
  String pdfPage(int current, int total) {
    return 'Page $current of $total';
  }

  @override
  String get pdfDate => 'Date';

  @override
  String get pdfCustomer => 'Customer';

  @override
  String get pdfDescription => 'Description';

  @override
  String get pdfType => 'Type';

  @override
  String get pdfAmount => 'Amount';

  @override
  String get pdfCredit => 'CREDIT';

  @override
  String get pdfDebit => 'DEBIT';

  @override
  String get pdfPayment => 'PAYMENT';

  @override
  String get pdfNotes => 'Notes:';

  @override
  String get pdfBillTo => 'Bill To: ';

  @override
  String get pdfSubtotal => 'Subtotal';

  @override
  String get pdfDiscount => 'Discount';

  @override
  String get pdfPreviousBalance => 'Previous Balance';

  @override
  String get pdfGrandTotal => 'Grand Total';

  @override
  String get pdfItem => '#';

  @override
  String get pdfItemName => 'Item';

  @override
  String get pdfQty => 'Qty';

  @override
  String get pdfUnit => 'Unit';

  @override
  String get pdfPrice => 'Price';

  @override
  String get pdfTotal => 'Total';

  @override
  String get pdfTotalCredit => 'Total Credit';

  @override
  String get pdfTotalDebit => 'Total Debit';

  @override
  String get pdfNetBalance => 'Net Balance';

  @override
  String get pdfTransactions => 'Transactions';

  @override
  String get pdfClosingBalance => 'Closing Balance';

  @override
  String get pdfOpeningBalance => 'Opening Balance';

  @override
  String get pdfThankYou => 'Thank you for your business!';

  @override
  String get pdfPeriod => 'Period';

  @override
  String get pdfCategoryBreakdown => 'Category Breakdown';

  @override
  String get pdfDue => '(Due)';

  @override
  String get pdfAdvance => '(Advance)';

  @override
  String get pdfBalance => 'Balance';

  @override
  String get pdfPhoneLabel => 'Phone';

  @override
  String get errorNetwork => 'No internet connection';

  @override
  String get errorTimeout => 'Request timed out. Please try again.';

  @override
  String get errorServer => 'Server error. Please try later.';

  @override
  String get errorUnauthorized => 'Session expired. Please login again.';

  @override
  String get errorNotFound => 'Page not found';

  @override
  String get errorNotFoundSubtitle =>
      'The page you are looking for does not exist.';

  @override
  String get goToDashboard => 'Go to Dashboard';

  @override
  String get errorLoadingData => 'Error loading data';

  @override
  String get errorSavingData => 'Error saving data';

  @override
  String get offlineMode => 'Offline Mode';

  @override
  String get offlineModeSubtitle => 'Data will sync when you\'re back online';

  @override
  String get syncInProgress => 'Syncing...';

  @override
  String get syncComplete => 'Sync completed successfully';

  @override
  String get syncFailed => 'Sync failed. Please try again';

  @override
  String pendingSync(int count) {
    return '$count changes pending sync';
  }

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String hoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String daysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String weeksAgo(int weeks) {
    return '${weeks}w ago';
  }

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get currencySymbol => '₹';

  @override
  String get currencyCode => 'INR';

  @override
  String get emptyCustomers => 'No customers yet';

  @override
  String get emptyCustomersSubtitle => 'Tap + to add your first customer';

  @override
  String get emptyTransactions => 'No transactions yet';

  @override
  String get emptyTransactionsSubtitle => 'Start by adding a transaction';

  @override
  String get emptyProducts => 'No products yet';

  @override
  String get emptyProductsSubtitle =>
      'Add your first product to manage inventory';

  @override
  String get emptyReports => 'No reports generated';

  @override
  String get emptyReportsSubtitle =>
      'Select report type and date range to generate';

  @override
  String get emptyBills => 'No bills yet';

  @override
  String get emptyBillsSubtitle => 'Create your first bill';

  @override
  String get emptySearch => 'No results found';

  @override
  String get emptySearchSubtitle => 'Try different search terms';

  @override
  String get todaySummary => 'TODAY\'S SUMMARY';

  @override
  String get fromYesterday => 'from yesterday';

  @override
  String get totalTransactions => 'Total Transactions';

  @override
  String get allTime => 'All time';

  @override
  String get revenueOverview => 'Revenue Overview';

  @override
  String get noCreditTransactionsYet => 'No credit transactions yet';

  @override
  String get week => 'Week';

  @override
  String get month => 'Month';

  @override
  String get year => 'Year';

  @override
  String get newSale => 'New Sale';

  @override
  String get selectShop => 'Select Shop';

  @override
  String get addNewShop => 'Add New Shop';

  @override
  String get rememberMe => 'Remember me';

  @override
  String get otpLogin => 'OTP Login';

  @override
  String get demoModeActive => 'Demo Mode Active';

  @override
  String get demoModeHint => 'Enter any phone & password to explore the app';

  @override
  String get registerNow => 'Register Now';

  @override
  String get registerSubtitle => 'Start your digital khata journey in minutes';

  @override
  String get personalInformation => 'Personal Information';

  @override
  String get shopDetails => 'Shop Details';

  @override
  String get fullName => 'Full Name';

  @override
  String get fullNameHint => 'Enter your full name';

  @override
  String get businessType => 'Business Type';

  @override
  String get createPassword => 'Create Password';

  @override
  String get createPasswordHint => 'Min 8 chars with upper, lower, number';

  @override
  String get passwordStrengthWeak => 'Weak';

  @override
  String get passwordStrengthMedium => 'Medium';

  @override
  String get passwordStrengthStrong => 'Strong';

  @override
  String get passwordStrengthPrefix => 'Password Strength:';

  @override
  String get agreeToTermsMessage => 'Please agree to Terms & Conditions';

  @override
  String get welcomeAboard => 'Welcome Aboard! 🎉';

  @override
  String get accountCreatedSuccess =>
      'Your account has been created successfully.';

  @override
  String shopIsReady(String shop) {
    return '$shop is ready!';
  }

  @override
  String get startYourKhata => 'Start Your Khata';

  @override
  String get iAgreeToThe => 'I agree to the ';

  @override
  String get andWord => ' and ';

  @override
  String get loadingYourShop => 'Loading your shop...';

  @override
  String get noCustomersFound => 'No customers found';

  @override
  String get adjustSearchOrFilters => 'Try adjusting your search or filters';

  @override
  String get searchByNameOrPhone => 'Search by name or phone...';

  @override
  String get totalPending => 'Total Pending';

  @override
  String countWithPending(int count) {
    return '$count with pending';
  }

  @override
  String get weOwe => 'We Owe';

  @override
  String get nameAZ => 'Name (A-Z)';

  @override
  String get balanceHighLow => 'Balance (High-Low)';

  @override
  String get recentlyActive => 'Recently Active';

  @override
  String get addCredit => 'Add Credit';

  @override
  String get recordPayment => 'Record Payment';

  @override
  String get payment => 'Payment';

  @override
  String get owesYou => 'owes you';

  @override
  String get youOweLabel => 'you owe';

  @override
  String get whatsApp => 'WhatsApp';

  @override
  String get transaction => 'Transaction';

  @override
  String get quickCreditDescription => 'Quick credit from customer list';

  @override
  String get quickPaymentDescription => 'Quick payment from customer list';

  @override
  String creditAddedSnackbar(String amount, String name) {
    return 'Credit of ₹$amount added to $name';
  }

  @override
  String paymentReceivedSnackbar(String amount, String name) {
    return 'Payment of ₹$amount received from $name';
  }

  @override
  String callingPhone(String phone) {
    return 'Calling $phone...';
  }

  @override
  String openingWhatsApp(String name) {
    return 'Opening WhatsApp for $name...';
  }

  @override
  String balanceAmount(String amount) {
    return 'Balance: ₹$amount';
  }

  @override
  String get personalInfo => 'Personal Info';

  @override
  String get contactDetails => 'Contact Details';

  @override
  String get creditSettings => 'Credit Settings';

  @override
  String get creditLimitOptional => 'Credit Limit (Optional)';

  @override
  String get maxCreditAllowed => 'Maximum credit allowed';

  @override
  String get enterValidAmount => 'Enter valid amount';

  @override
  String get notesSection => 'Notes';

  @override
  String get tapToChangeAvatar => 'Tap to change avatar';

  @override
  String get chooseAvatar => 'Choose Avatar';

  @override
  String get addAnother => 'Add Another';

  @override
  String get customerAddedTitle => 'Customer Added!';

  @override
  String customerAddedMessage(String name) {
    return '$name has been added to your customer list.';
  }

  @override
  String get overview => 'Overview';

  @override
  String get detailsTab => 'Details';

  @override
  String get totalPaid => 'Total Paid';

  @override
  String get paymentProgress => 'Payment Progress';

  @override
  String paidAmount(String amount) {
    return 'Paid: $amount';
  }

  @override
  String remainingAmount(String amount) {
    return 'Remaining: $amount';
  }

  @override
  String get monthlyActivity => 'Monthly Activity';

  @override
  String get trustScoreBreakdown => 'Trust Score Breakdown';

  @override
  String get paymentHistoryLabel => 'Payment History';

  @override
  String get paymentTimeliness => 'Payment Timeliness';

  @override
  String get creditUtilization => 'Credit Utilization';

  @override
  String get relationshipLabel => 'Relationship';

  @override
  String get contactInformation => 'Contact Information';

  @override
  String get phone => 'Phone';

  @override
  String get emailLabel => 'Email';

  @override
  String get notProvided => 'Not provided';

  @override
  String get accountInformation => 'Account Information';

  @override
  String get customerSinceLabel => 'Customer Since';

  @override
  String get lastActivity => 'Last Activity';

  @override
  String get noActivity => 'No activity';

  @override
  String get creditLimitLabel => 'Credit Limit';

  @override
  String get sms => 'SMS';

  @override
  String get undo => 'Undo';

  @override
  String get lastTransactionUndone => 'Last transaction undone';

  @override
  String get sendStatement => 'Send Statement';

  @override
  String get exportData => 'Export Data';

  @override
  String get deleteCustomerLabel => 'Delete Customer';

  @override
  String get balanceLabel => 'Balance';

  @override
  String get trustLabel => 'Trust';

  @override
  String get limitLabel => 'Limit';

  @override
  String get name => 'Name';

  @override
  String balAfter(String amount) {
    return 'Bal: ₹$amount';
  }

  @override
  String lastDate(String date) {
    return 'Last: $date';
  }

  @override
  String get enterFullName => 'Enter full name';

  @override
  String get enterPhoneNumber => 'Enter 10-digit phone number';

  @override
  String get enterFullAddress => 'Enter full address';

  @override
  String get khataBook => 'Khata Book';

  @override
  String get yourDailyNotebook => 'Your daily notebook';

  @override
  String get khataEmpty => 'Your khata is empty';

  @override
  String get tapToAddFirstEntry => 'Tap + to add the first entry';

  @override
  String get noMatchingEntries => 'No matching entries';

  @override
  String get searchByCustomerOrDescription =>
      'Search by customer or description...';

  @override
  String entriesCount(int count) {
    return '$count entries';
  }

  @override
  String get filtered => 'Filtered';

  @override
  String get received => 'Received';

  @override
  String get addEntry => 'Add Entry';

  @override
  String get net => 'Net';

  @override
  String get newTransaction => 'New Transaction';

  @override
  String get pleaseSelectCustomer => 'Please select a customer';

  @override
  String get paymentReceivedSuccess => 'Payment Received!';

  @override
  String get creditRecordedSuccess => 'Credit Recorded!';

  @override
  String get newPurchase => 'New Purchase';

  @override
  String get customerBuysOnCredit => 'Customer buys on credit';

  @override
  String get customerPaysYou => 'Customer pays you';

  @override
  String get addCustomersFirst => 'Add customers from the Customers tab first';

  @override
  String get paymentAmountLabel => 'Payment Amount';

  @override
  String get purchaseAmountLabel => 'Purchase Amount';

  @override
  String get quickAmount => 'Quick Amount';

  @override
  String get recordPaymentPlus => 'Record Payment (+)';

  @override
  String get recordPurchaseMinus => 'Record Purchase (-)';

  @override
  String get descriptionOptional => 'Description (Optional)';

  @override
  String get paymentViaCashHint => 'e.g., Payment via cash';

  @override
  String get groceryItemsHint => 'e.g., Grocery items - Rice, Dal';

  @override
  String get detailsSection => 'Details';

  @override
  String get tapToAddFirstCreditOrPayment =>
      'Tap + to add the first credit or payment';

  @override
  String get outstandingBalance => 'Outstanding Balance';

  @override
  String get allSettled => 'All Settled';

  @override
  String overCreditLimitAmount(String amount) {
    return 'Over credit limit (₹$amount)';
  }

  @override
  String overdueWithDays(int days) {
    return 'Overdue ($days days)';
  }

  @override
  String get creditLabel => 'Credit';

  @override
  String get paymentsLabel => 'Payments';

  @override
  String get entriesLabel => 'Entries';

  @override
  String get groceryPurchaseHint => 'e.g., Grocery purchase';

  @override
  String get cashPaymentHint => 'e.g., Cash payment';

  @override
  String get addCreditEntry => 'Add Credit Entry';

  @override
  String transactionUndoneAmount(String amount) {
    return 'Transaction of ₹$amount undone';
  }

  @override
  String creditOfAmountAdded(String amount) {
    return 'Credit of ₹$amount added';
  }

  @override
  String paymentOfAmountRecorded(String amount) {
    return 'Payment of ₹$amount recorded';
  }

  @override
  String get shopAndInventory => 'Shop & Inventory';

  @override
  String get noProductsFound => 'No products found';

  @override
  String get tryChangingFiltersOrSearch => 'Try changing filters or search';

  @override
  String inStockCount(int count) {
    return '$count in stock';
  }

  @override
  String get viewCart => 'View Cart';

  @override
  String get yourCart => 'Your Cart';

  @override
  String get productEditingComingSoon => 'Product editing coming soon...';

  @override
  String get updateStock => 'Update Stock';

  @override
  String get addStockAction => '+ Add Stock';

  @override
  String get removeStockAction => '- Remove Stock';

  @override
  String stockAddedMessage(String qty, String unit) {
    return 'Stock added: $qty $unit';
  }

  @override
  String stockRemovedMessage(String qty, String unit) {
    return 'Stock removed: $qty $unit';
  }

  @override
  String get saleCompleteTitle => 'Sale Complete!';

  @override
  String get transactionRecordedSuccess =>
      'Transaction has been recorded successfully';

  @override
  String get completeSale => 'Complete Sale';

  @override
  String get addToKhata => 'Add to Khata';

  @override
  String get recordAsCustomerCredit => 'Record as customer credit';

  @override
  String get shopTab => 'Shop';

  @override
  String get inventoryTab => 'Inventory';

  @override
  String get basicInformation => 'Basic Information';

  @override
  String get categoryAndUnit => 'Category & Unit';

  @override
  String get addProductImage => 'Add Product Image';

  @override
  String get tapToCaptureOrSelect => 'Tap to capture or select from gallery';

  @override
  String get cameraGalleryComingSoon => 'Camera/Gallery coming soon';

  @override
  String get productAddedTitle => 'Product Added!';

  @override
  String productAddedToInventory(String name) {
    return '$name has been added to your inventory.';
  }

  @override
  String get addMore => 'Add More';

  @override
  String get buyPriceRequired => 'Buy Price *';

  @override
  String get costLabel => 'Cost';

  @override
  String get sellPriceRequired => 'Sell Price *';

  @override
  String get mrpLabel => 'MRP';

  @override
  String get profit => 'Profit';

  @override
  String get marginLabel => 'Margin';

  @override
  String get stockManagement => 'Stock Management';

  @override
  String get trackInventory => 'Track Inventory';

  @override
  String get enableStockAlerts => 'Enable stock tracking & low stock alerts';

  @override
  String get currentStockRequired => 'Current Stock *';

  @override
  String get qtyLabel => 'Qty';

  @override
  String get minStockAlert => 'Min Stock Alert';

  @override
  String get lowAlertHint => 'Low alert';

  @override
  String get quickSetPrefix => 'Quick Set: ';

  @override
  String get pricingSection => 'Pricing';

  @override
  String get briefDescription => 'Brief product description';

  @override
  String get productNameRequired => 'Product Name *';

  @override
  String get scanOrEnterCode => 'Scan or enter code';

  @override
  String lowStockCount(int count) {
    return '$count Low Stock';
  }

  @override
  String itemsCount(int count) {
    return '$count items';
  }

  @override
  String quantityUnit(String unit) {
    return 'Quantity ($unit)';
  }

  @override
  String currentInfo(int stock, String unit) {
    return 'Current: $stock $unit';
  }

  @override
  String fromName(String name) {
    return 'from $name';
  }

  @override
  String toName(String name) {
    return 'to $name';
  }

  @override
  String currentBalanceAmount(String amount) {
    return 'Current balance: ₹$amount';
  }

  @override
  String get clearBillTitle => 'Clear Bill?';

  @override
  String get clearBillMessage =>
      'This will remove all items from the current bill.';

  @override
  String get noItemsFound => 'No items found';

  @override
  String get billCreated => 'Bill Created!';

  @override
  String get createBill => 'Create Bill';

  @override
  String get pleaseSelectCustomerFirst => 'Please select a customer first';

  @override
  String get pleaseAddItemsToBill => 'Please add items to the bill';

  @override
  String errorGeneratingBill(String error) {
    return 'Error generating bill: $error';
  }

  @override
  String cartWithCount(int count) {
    return 'Cart ($count items)';
  }

  @override
  String get yourCartIsEmpty => 'Your cart is empty';

  @override
  String get addNotesOptional => 'Add notes (optional)';

  @override
  String get advShort => 'Adv';

  @override
  String get reportTypeLabel => 'Report Type';

  @override
  String get daily => 'Daily';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String get yearly => 'Yearly';

  @override
  String get customLabel => 'Custom';

  @override
  String get fromLabel => 'From';

  @override
  String get toLabel => 'To';

  @override
  String get todaysSummaryLabel => 'Today\'s Summary';

  @override
  String get topCustomersLabel => 'Top Customers';

  @override
  String get pendingDues => 'Pending Dues';

  @override
  String get activeDebtors => 'Active Debtors';

  @override
  String get noTransactionsReportHint =>
      'No transactions yet. Generate your first report after adding transactions.';

  @override
  String get reportGeneratedTitle => 'Report Generated!';

  @override
  String get upiDetails => 'UPI Details';

  @override
  String get upiIdLabel => 'UPI ID *';

  @override
  String get upiIdPlaceholder => 'yourname@upi';

  @override
  String get upiIdRequired => 'UPI ID is required';

  @override
  String get upiIdInvalid => 'Enter a valid UPI ID (e.g. name@bank)';

  @override
  String get shopNameStar => 'Shop Name *';

  @override
  String get upiShopNameHint => 'Name shown on UPI payment';

  @override
  String get merchantCodeOptional => 'Merchant Code (Optional)';

  @override
  String get merchantCodeHint => 'e.g. 5411 for Grocery Stores';

  @override
  String get qrCodeImage => 'QR Code Image';

  @override
  String get qrUploadDescription =>
      'Upload an existing QR code image or use the auto-generated one from your UPI ID.';

  @override
  String get unableToLoadQrImage => 'Unable to load QR image';

  @override
  String get tapToUploadQrImage => 'Tap to upload QR image';

  @override
  String get imageFormatHint => 'PNG, JPG up to 1MB';

  @override
  String get upiUriPreview => 'UPI URI Preview';

  @override
  String get updateUpiDetails => 'Update UPI Details';

  @override
  String get saveUpiDetails => 'Save UPI Details';

  @override
  String get qrImageUpdated => 'QR image updated';

  @override
  String get saveUpiFirst => 'Save UPI details first, then upload QR image';

  @override
  String failedToPickImage(String error) {
    return 'Failed to pick image: $error';
  }

  @override
  String upiIdCopied(String upiId) {
    return 'UPI ID copied: $upiId';
  }

  @override
  String failedToShare(String error) {
    return 'Failed to share: $error';
  }

  @override
  String get setupUpiInSettings => 'Set up your UPI details in Settings first.';

  @override
  String get goBack => 'Go Back';

  @override
  String paymentFromName(String name) {
    return 'Payment from $name';
  }

  @override
  String get normalBrightness => 'Normal Brightness';

  @override
  String get maxBrightness => 'Max Brightness';

  @override
  String get copyUpiId => 'Copy UPI ID';

  @override
  String get normalLabel => 'Normal';

  @override
  String get brightenLabel => 'Brighten';

  @override
  String get paymentRecordedLabel => 'Payment Recorded!';

  @override
  String paymentReceivedDash(String amount) {
    return 'Payment Received — ₹$amount';
  }

  @override
  String amountFromCustomer(String amount, String name) {
    return '₹$amount from $name';
  }

  @override
  String get balanceUpdatedAutomatically => 'Balance updated automatically';

  @override
  String get scanWithAnyUpiApp => 'Scan with any UPI app';

  @override
  String amountLabelValue(String amount) {
    return 'Amount: ₹$amount';
  }

  @override
  String get toCollect => 'To Collect';

  @override
  String get lowRisk => 'Low Risk';

  @override
  String get mediumRisk => 'Medium';

  @override
  String get highRisk => 'High Risk';

  @override
  String daysAgoLong(int days) {
    return '$days days ago';
  }

  @override
  String weeksAgoLong(int weeks) {
    return '$weeks weeks ago';
  }

  @override
  String monthsAgoLong(int months) {
    return '$months months ago';
  }

  @override
  String moreItemsCount(int count) {
    return '+ $count more items';
  }

  @override
  String totalItemsLabel(int count) {
    return 'Total: $count items';
  }

  @override
  String get paidStatus => 'PAID';

  @override
  String get pendingStatus => 'PENDING';

  @override
  String todayWithTime(String time) {
    return 'Today, $time';
  }

  @override
  String yesterdayWithTime(String time) {
    return 'Yesterday, $time';
  }

  @override
  String get rate => 'Rate';

  @override
  String get itemsHeader => 'Items';

  @override
  String get markAsPaid => 'Mark as Paid';

  @override
  String billIdLabel(String id) {
    return 'Bill #$id';
  }

  @override
  String get lowLabel => 'Low';

  @override
  String stockPcsCount(int count) {
    return '$count pcs';
  }

  @override
  String get pdfUnknownCustomer => 'Unknown';

  @override
  String pdfShareSubject(String fileName) {
    return 'KhataSetu Report - $fileName';
  }

  @override
  String get validatorDefaultFieldName => 'This field';

  @override
  String get biometricAuthReason => 'Authenticate to access KhataSetu';

  @override
  String get biometricEnableReason =>
      'Verify your identity to enable biometric lock';

  @override
  String get biometricNoHardware =>
      'This device does not support biometric authentication';

  @override
  String get biometricNotEnrolled =>
      'No fingerprints enrolled. Please set up biometrics in device settings';

  @override
  String get biometricLockedOut => 'Too many failed attempts. Try again later';

  @override
  String get biometricPermanentlyLocked =>
      'Biometric locked. Use your device PIN to unlock';

  @override
  String get biometricFailed => 'Biometric authentication failed';

  @override
  String get biometricCancelled => 'Authentication cancelled';

  @override
  String get biometricUnavailable => 'Biometric not available on this device';

  @override
  String get biometricLoginLabel => 'Fingerprint';

  @override
  String get biometricVerifying => 'Verifying...';

  @override
  String get productUpdatedSuccess => 'Product updated successfully';

  @override
  String get updateProduct => 'Update Product';

  @override
  String get updateCustomer => 'Update Customer';

  @override
  String billRecordedToLedger(String amount) {
    return 'Bill of $amount recorded to ledger';
  }

  @override
  String get syncStarted => 'Syncing...';

  @override
  String get exportSuccess => 'Data exported successfully';

  @override
  String get exportFailed => 'Export failed. Please try again';

  @override
  String get exportingData => 'Exporting data...';

  @override
  String get notificationsSaved => 'Notification preference saved';

  @override
  String get notificationsComingSoon => 'Push notifications coming soon';

  @override
  String featureComingSoon(String feature) {
    return '$feature coming soon';
  }

  @override
  String get statementShared => 'Statement shared';

  @override
  String get shopManagementComingSoon => 'Shop management coming soon';

  @override
  String get noNotifications => 'No notifications yet';

  @override
  String get noDailyNotes => 'No daily notes yet';

  @override
  String get noDailyNotesSubtitle => 'Tap + to add your first daily note';

  @override
  String get newDailyNote => 'New Note';

  @override
  String get allCustomers => 'All Customers';

  @override
  String get morningLabel => 'Morning';

  @override
  String get afternoonLabel => 'Afternoon';

  @override
  String get eveningLabel => 'Evening';

  @override
  String get repeatYesterday => 'Repeat Yesterday\'s Items';

  @override
  String get addNoteOptional => 'Add a note (optional)';

  @override
  String get saveToLedger => 'Save to Ledger';

  @override
  String get saveDailyNote => 'Save Daily Note';

  @override
  String get noteSavedSuccess => 'Daily note saved';

  @override
  String get noteSavedWithLedger => 'Note saved & added to ledger';

  @override
  String get syncedToLedger => 'Synced to ledger';

  @override
  String get deleteNote => 'Delete Note';

  @override
  String get deleteNoteConfirm =>
      'This will permanently delete this daily note. Are you sure?';

  @override
  String get frequentItems => 'Frequent Items';

  @override
  String get items => 'items';

  @override
  String get noProductsAddedYet => 'No products added yet';

  @override
  String get addFirstProductHint =>
      'Add your first product to start tracking inventory';

  @override
  String get selectTransactionType => 'Select Transaction Type';

  @override
  String get customerTakesGoodsOnCredit => 'Customer takes goods on credit';

  @override
  String get addPayment => 'Add Payment';

  @override
  String get customerPaysMoney => 'Customer pays money';

  @override
  String get markAllAsRead => 'Mark all read';

  @override
  String get noNotificationsDescription =>
      'You\'ll see alerts for low stock, pending payments, and more here';
}
