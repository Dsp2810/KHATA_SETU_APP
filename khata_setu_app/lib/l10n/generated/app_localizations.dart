import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S)!;
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('gu'),
    Locale('hi'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'KhataSetu'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Digital Udhar & Inventory Management'**
  String get appTagline;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String appVersion(String version);

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @print.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get print;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait...'**
  String get pleaseWait;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @noDataFound.
  ///
  /// In en, this message translates to:
  /// **'No data found'**
  String get noDataFound;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get navCustomers;

  /// No description provided for @navLedger.
  ///
  /// In en, this message translates to:
  /// **'Ledger'**
  String get navLedger;

  /// No description provided for @navInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get navInventory;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back!'**
  String get welcomeBack;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginTitle;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerTitle;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'Enter 10-digit mobile number'**
  String get phoneHint;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get confirmPasswordHint;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerButton;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get orContinueWith;

  /// No description provided for @enterOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP'**
  String get enterOtp;

  /// No description provided for @otpSentTo.
  ///
  /// In en, this message translates to:
  /// **'OTP sent to {phone}'**
  String otpSentTo(String phone);

  /// No description provided for @resendOtp.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOtp;

  /// No description provided for @resendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String resendIn(int seconds);

  /// No description provided for @verifyOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verifyOtp;

  /// No description provided for @shopName.
  ///
  /// In en, this message translates to:
  /// **'Shop Name'**
  String get shopName;

  /// No description provided for @shopNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your shop name'**
  String get shopNameHint;

  /// No description provided for @ownerName.
  ///
  /// In en, this message translates to:
  /// **'Owner Name'**
  String get ownerName;

  /// No description provided for @ownerNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter owner name'**
  String get ownerNameHint;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @addressHint.
  ///
  /// In en, this message translates to:
  /// **'Enter shop address'**
  String get addressHint;

  /// No description provided for @setPin.
  ///
  /// In en, this message translates to:
  /// **'Set PIN'**
  String get setPin;

  /// No description provided for @enterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get enterPin;

  /// No description provided for @loginDemoMode.
  ///
  /// In en, this message translates to:
  /// **'Login (Demo Mode)'**
  String get loginDemoMode;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number to continue'**
  String get loginSubtitle;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Your Digital Udhar Khata'**
  String get splashTagline;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @loginSuccess.
  ///
  /// In en, this message translates to:
  /// **'Login successful!'**
  String get loginSuccess;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get goodEvening;

  /// No description provided for @greeting.
  ///
  /// In en, this message translates to:
  /// **'{greeting}, {name}!'**
  String greeting(String greeting, String name);

  /// No description provided for @totalOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Total Outstanding'**
  String get totalOutstanding;

  /// No description provided for @todayCollection.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Collection'**
  String get todayCollection;

  /// No description provided for @todayCredit.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Credit'**
  String get todayCredit;

  /// No description provided for @totalCustomers.
  ///
  /// In en, this message translates to:
  /// **'Total Customers'**
  String get totalCustomers;

  /// No description provided for @activeCustomers.
  ///
  /// In en, this message translates to:
  /// **'Active Customers'**
  String get activeCustomers;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactions;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @addCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add Customer'**
  String get addCustomer;

  /// No description provided for @addTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add Transaction'**
  String get addTransaction;

  /// No description provided for @generateReport.
  ///
  /// In en, this message translates to:
  /// **'Generate Report'**
  String get generateReport;

  /// No description provided for @collectPayment.
  ///
  /// In en, this message translates to:
  /// **'Collect Payment'**
  String get collectPayment;

  /// No description provided for @weeklyOverview.
  ///
  /// In en, this message translates to:
  /// **'Weekly Overview'**
  String get weeklyOverview;

  /// No description provided for @monthlyOverview.
  ///
  /// In en, this message translates to:
  /// **'Monthly Overview'**
  String get monthlyOverview;

  /// No description provided for @noTransactionsYet.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactionsYet;

  /// No description provided for @startByAddingCustomer.
  ///
  /// In en, this message translates to:
  /// **'Start by adding your first customer'**
  String get startByAddingCustomer;

  /// No description provided for @topDebtors.
  ///
  /// In en, this message translates to:
  /// **'Top Debtors'**
  String get topDebtors;

  /// No description provided for @creditGiven.
  ///
  /// In en, this message translates to:
  /// **'Credit Given'**
  String get creditGiven;

  /// No description provided for @paymentReceived.
  ///
  /// In en, this message translates to:
  /// **'Payment Received'**
  String get paymentReceived;

  /// No description provided for @netBalance.
  ///
  /// In en, this message translates to:
  /// **'Net Balance'**
  String get netBalance;

  /// No description provided for @totalCredit.
  ///
  /// In en, this message translates to:
  /// **'Total Credit'**
  String get totalCredit;

  /// No description provided for @totalDebit.
  ///
  /// In en, this message translates to:
  /// **'Total Debit'**
  String get totalDebit;

  /// No description provided for @overviewStats.
  ///
  /// In en, this message translates to:
  /// **'Overview Stats'**
  String get overviewStats;

  /// No description provided for @smartBilling.
  ///
  /// In en, this message translates to:
  /// **'Smart Billing'**
  String get smartBilling;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @customers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customers;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @searchCustomers.
  ///
  /// In en, this message translates to:
  /// **'Search customers...'**
  String get searchCustomers;

  /// No description provided for @addNewCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add New Customer'**
  String get addNewCustomer;

  /// No description provided for @editCustomer.
  ///
  /// In en, this message translates to:
  /// **'Edit Customer'**
  String get editCustomer;

  /// No description provided for @customerName.
  ///
  /// In en, this message translates to:
  /// **'Customer Name'**
  String get customerName;

  /// No description provided for @customerNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter customer name'**
  String get customerNameHint;

  /// No description provided for @customerPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get customerPhone;

  /// No description provided for @customerPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number'**
  String get customerPhoneHint;

  /// No description provided for @customerEmail.
  ///
  /// In en, this message translates to:
  /// **'Email (Optional)'**
  String get customerEmail;

  /// No description provided for @customerEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter email address'**
  String get customerEmailHint;

  /// No description provided for @customerAddress.
  ///
  /// In en, this message translates to:
  /// **'Address (Optional)'**
  String get customerAddress;

  /// No description provided for @customerAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Enter address'**
  String get customerAddressHint;

  /// No description provided for @customerNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes (Optional)'**
  String get customerNotes;

  /// No description provided for @customerNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Any additional notes...'**
  String get customerNotesHint;

  /// No description provided for @customerDetails.
  ///
  /// In en, this message translates to:
  /// **'Customer Details'**
  String get customerDetails;

  /// No description provided for @customerBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get customerBalance;

  /// No description provided for @customerOwes.
  ///
  /// In en, this message translates to:
  /// **'{name} owes'**
  String customerOwes(String name);

  /// No description provided for @youOwe.
  ///
  /// In en, this message translates to:
  /// **'You owe {name}'**
  String youOwe(String name);

  /// No description provided for @settled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get settled;

  /// No description provided for @trustScore.
  ///
  /// In en, this message translates to:
  /// **'Trust Score'**
  String get trustScore;

  /// No description provided for @lastTransaction.
  ///
  /// In en, this message translates to:
  /// **'Last Transaction'**
  String get lastTransaction;

  /// No description provided for @noCustomersYet.
  ///
  /// In en, this message translates to:
  /// **'No customers yet'**
  String get noCustomersYet;

  /// No description provided for @noCustomersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first customer to start tracking credit'**
  String get noCustomersSubtitle;

  /// No description provided for @customerAdded.
  ///
  /// In en, this message translates to:
  /// **'Customer added successfully!'**
  String get customerAdded;

  /// No description provided for @customerUpdated.
  ///
  /// In en, this message translates to:
  /// **'Customer updated successfully!'**
  String get customerUpdated;

  /// No description provided for @customerDeleted.
  ///
  /// In en, this message translates to:
  /// **'Customer deleted'**
  String get customerDeleted;

  /// No description provided for @deleteCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Customer?'**
  String get deleteCustomerTitle;

  /// No description provided for @deleteCustomerMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete {name} and all their transactions. This cannot be undone.'**
  String deleteCustomerMessage(String name);

  /// No description provided for @totalCustomersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} customers'**
  String totalCustomersCount(int count);

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortBy;

  /// No description provided for @sortByName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sortByName;

  /// No description provided for @sortByBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get sortByBalance;

  /// No description provided for @sortByRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get sortByRecent;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterOwing.
  ///
  /// In en, this message translates to:
  /// **'Owing'**
  String get filterOwing;

  /// No description provided for @filterAdvance.
  ///
  /// In en, this message translates to:
  /// **'Advance'**
  String get filterAdvance;

  /// No description provided for @filterSettled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get filterSettled;

  /// No description provided for @customerSince.
  ///
  /// In en, this message translates to:
  /// **'Customer since {date}'**
  String customerSince(String date);

  /// No description provided for @transactionHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get transactionHistory;

  /// No description provided for @sendReminder.
  ///
  /// In en, this message translates to:
  /// **'Send Reminder'**
  String get sendReminder;

  /// No description provided for @shareStatement.
  ///
  /// In en, this message translates to:
  /// **'Share Statement'**
  String get shareStatement;

  /// No description provided for @callCustomer.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get callCustomer;

  /// No description provided for @messageCustomer.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get messageCustomer;

  /// No description provided for @ledger.
  ///
  /// In en, this message translates to:
  /// **'Ledger'**
  String get ledger;

  /// No description provided for @dailyBook.
  ///
  /// In en, this message translates to:
  /// **'Daily Book'**
  String get dailyBook;

  /// No description provided for @addNewTransaction.
  ///
  /// In en, this message translates to:
  /// **'New Transaction'**
  String get addNewTransaction;

  /// No description provided for @transactionType.
  ///
  /// In en, this message translates to:
  /// **'Transaction Type'**
  String get transactionType;

  /// No description provided for @creditUdhar.
  ///
  /// In en, this message translates to:
  /// **'Credit (Udhar)'**
  String get creditUdhar;

  /// No description provided for @creditDescription.
  ///
  /// In en, this message translates to:
  /// **'Customer owes you'**
  String get creditDescription;

  /// No description provided for @debitPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment (Vasuli)'**
  String get debitPayment;

  /// No description provided for @debitDescription.
  ///
  /// In en, this message translates to:
  /// **'Customer paid you'**
  String get debitDescription;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @amountHint.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get amountHint;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'What is this for?'**
  String get descriptionHint;

  /// No description provided for @selectCustomer.
  ///
  /// In en, this message translates to:
  /// **'Select Customer'**
  String get selectCustomer;

  /// No description provided for @selectCustomerHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a customer'**
  String get selectCustomerHint;

  /// No description provided for @transactionDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get transactionDate;

  /// No description provided for @addItems.
  ///
  /// In en, this message translates to:
  /// **'Add Items'**
  String get addItems;

  /// No description provided for @itemName.
  ///
  /// In en, this message translates to:
  /// **'Item Name'**
  String get itemName;

  /// No description provided for @itemNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter item name'**
  String get itemNameHint;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @quantityHint.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get quantityHint;

  /// No description provided for @unitPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get unitPrice;

  /// No description provided for @unitPriceHint.
  ///
  /// In en, this message translates to:
  /// **'₹ Price'**
  String get unitPriceHint;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @pcs.
  ///
  /// In en, this message translates to:
  /// **'pcs'**
  String get pcs;

  /// No description provided for @kg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get kg;

  /// No description provided for @litre.
  ///
  /// In en, this message translates to:
  /// **'litre'**
  String get litre;

  /// No description provided for @metre.
  ///
  /// In en, this message translates to:
  /// **'metre'**
  String get metre;

  /// No description provided for @dozen.
  ///
  /// In en, this message translates to:
  /// **'dozen'**
  String get dozen;

  /// No description provided for @box.
  ///
  /// In en, this message translates to:
  /// **'box'**
  String get box;

  /// No description provided for @packet.
  ///
  /// In en, this message translates to:
  /// **'packet'**
  String get packet;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @grandTotal.
  ///
  /// In en, this message translates to:
  /// **'Grand Total'**
  String get grandTotal;

  /// No description provided for @transactionAdded.
  ///
  /// In en, this message translates to:
  /// **'Transaction added successfully!'**
  String get transactionAdded;

  /// No description provided for @transactionDeleted.
  ///
  /// In en, this message translates to:
  /// **'Transaction deleted'**
  String get transactionDeleted;

  /// No description provided for @undoDelete.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undoDelete;

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions'**
  String get noTransactions;

  /// No description provided for @noTransactionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first transaction to start tracking'**
  String get noTransactionsSubtitle;

  /// No description provided for @todayTransactions.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Transactions'**
  String get todayTransactions;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @allTransactions.
  ///
  /// In en, this message translates to:
  /// **'All Transactions'**
  String get allTransactions;

  /// No description provided for @filterByDate.
  ///
  /// In en, this message translates to:
  /// **'Filter by Date'**
  String get filterByDate;

  /// No description provided for @filterByType.
  ///
  /// In en, this message translates to:
  /// **'Filter by Type'**
  String get filterByType;

  /// No description provided for @allTypes.
  ///
  /// In en, this message translates to:
  /// **'All Types'**
  String get allTypes;

  /// No description provided for @creditOnly.
  ///
  /// In en, this message translates to:
  /// **'Credit Only'**
  String get creditOnly;

  /// No description provided for @debitOnly.
  ///
  /// In en, this message translates to:
  /// **'Debit Only'**
  String get debitOnly;

  /// No description provided for @transactionCount.
  ///
  /// In en, this message translates to:
  /// **'{count} transactions'**
  String transactionCount(int count);

  /// No description provided for @creditAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Credit: {amount}'**
  String creditAmountLabel(String amount);

  /// No description provided for @debitAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Debit: {amount}'**
  String debitAmountLabel(String amount);

  /// No description provided for @paymentMode.
  ///
  /// In en, this message translates to:
  /// **'Payment Mode'**
  String get paymentMode;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @upi.
  ///
  /// In en, this message translates to:
  /// **'UPI'**
  String get upi;

  /// No description provided for @bank.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer'**
  String get bank;

  /// No description provided for @otherPayment.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherPayment;

  /// No description provided for @addMoreItems.
  ///
  /// In en, this message translates to:
  /// **'Add More Items'**
  String get addMoreItems;

  /// No description provided for @removeItem.
  ///
  /// In en, this message translates to:
  /// **'Remove Item'**
  String get removeItem;

  /// No description provided for @itemTotal.
  ///
  /// In en, this message translates to:
  /// **'Item Total: {amount}'**
  String itemTotal(String amount);

  /// No description provided for @saveTransaction.
  ///
  /// In en, this message translates to:
  /// **'Save Transaction'**
  String get saveTransaction;

  /// No description provided for @timeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timeline;

  /// No description provided for @inventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventory;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @searchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search products...'**
  String get searchProducts;

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProduct;

  /// No description provided for @editProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get editProduct;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productName;

  /// No description provided for @productNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter product name'**
  String get productNameHint;

  /// No description provided for @productPrice.
  ///
  /// In en, this message translates to:
  /// **'Selling Price'**
  String get productPrice;

  /// No description provided for @productPriceHint.
  ///
  /// In en, this message translates to:
  /// **'Enter selling price'**
  String get productPriceHint;

  /// No description provided for @costPrice.
  ///
  /// In en, this message translates to:
  /// **'Cost Price (Optional)'**
  String get costPrice;

  /// No description provided for @costPriceHint.
  ///
  /// In en, this message translates to:
  /// **'Enter cost price'**
  String get costPriceHint;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @categoryHint.
  ///
  /// In en, this message translates to:
  /// **'Select category'**
  String get categoryHint;

  /// No description provided for @sku.
  ///
  /// In en, this message translates to:
  /// **'SKU / Barcode'**
  String get sku;

  /// No description provided for @skuHint.
  ///
  /// In en, this message translates to:
  /// **'Enter SKU or barcode'**
  String get skuHint;

  /// No description provided for @currentStock.
  ///
  /// In en, this message translates to:
  /// **'Current Stock'**
  String get currentStock;

  /// No description provided for @stockHint.
  ///
  /// In en, this message translates to:
  /// **'Enter current stock'**
  String get stockHint;

  /// No description provided for @lowStockAlert.
  ///
  /// In en, this message translates to:
  /// **'Low Stock Alert'**
  String get lowStockAlert;

  /// No description provided for @lowStockThreshold.
  ///
  /// In en, this message translates to:
  /// **'Alert when stock below'**
  String get lowStockThreshold;

  /// No description provided for @productAdded.
  ///
  /// In en, this message translates to:
  /// **'Product added successfully!'**
  String get productAdded;

  /// No description provided for @productUpdated.
  ///
  /// In en, this message translates to:
  /// **'Product updated!'**
  String get productUpdated;

  /// No description provided for @productDeleted.
  ///
  /// In en, this message translates to:
  /// **'Product deleted'**
  String get productDeleted;

  /// No description provided for @noProductsYet.
  ///
  /// In en, this message translates to:
  /// **'No products yet'**
  String get noProductsYet;

  /// No description provided for @noProductsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add products to manage your inventory'**
  String get noProductsSubtitle;

  /// No description provided for @inStock.
  ///
  /// In en, this message translates to:
  /// **'In Stock'**
  String get inStock;

  /// No description provided for @lowStock.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get lowStock;

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get outOfStock;

  /// No description provided for @stockCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String stockCount(int count);

  /// No description provided for @allProducts.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allProducts;

  /// No description provided for @categoriesFilter.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoriesFilter;

  /// No description provided for @totalProducts.
  ///
  /// In en, this message translates to:
  /// **'Total Products'**
  String get totalProducts;

  /// No description provided for @totalStockValue.
  ///
  /// In en, this message translates to:
  /// **'Stock Value'**
  String get totalStockValue;

  /// No description provided for @lowStockItems.
  ///
  /// In en, this message translates to:
  /// **'Low Stock Items'**
  String get lowStockItems;

  /// No description provided for @groceries.
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get groceries;

  /// No description provided for @dairy.
  ///
  /// In en, this message translates to:
  /// **'Dairy'**
  String get dairy;

  /// No description provided for @snacks.
  ///
  /// In en, this message translates to:
  /// **'Snacks'**
  String get snacks;

  /// No description provided for @beverages.
  ///
  /// In en, this message translates to:
  /// **'Beverages'**
  String get beverages;

  /// No description provided for @household.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get household;

  /// No description provided for @personal.
  ///
  /// In en, this message translates to:
  /// **'Personal Care'**
  String get personal;

  /// No description provided for @stationery.
  ///
  /// In en, this message translates to:
  /// **'Stationery'**
  String get stationery;

  /// No description provided for @otherCategory.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherCategory;

  /// No description provided for @stockQuantity.
  ///
  /// In en, this message translates to:
  /// **'Stock: {count}'**
  String stockQuantity(String count);

  /// No description provided for @profitMargin.
  ///
  /// In en, this message translates to:
  /// **'Margin: {percent}%'**
  String profitMargin(String percent);

  /// No description provided for @billing.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get billing;

  /// No description provided for @smartBillingTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart Billing'**
  String get smartBillingTitle;

  /// No description provided for @newBill.
  ///
  /// In en, this message translates to:
  /// **'New Bill'**
  String get newBill;

  /// No description provided for @billNumber.
  ///
  /// In en, this message translates to:
  /// **'Bill No.'**
  String get billNumber;

  /// No description provided for @billDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get billDate;

  /// No description provided for @billTo.
  ///
  /// In en, this message translates to:
  /// **'Bill To'**
  String get billTo;

  /// No description provided for @selectCustomerForBill.
  ///
  /// In en, this message translates to:
  /// **'Select Customer'**
  String get selectCustomerForBill;

  /// No description provided for @addItemsToBill.
  ///
  /// In en, this message translates to:
  /// **'Add Items to Bill'**
  String get addItemsToBill;

  /// No description provided for @billSummary.
  ///
  /// In en, this message translates to:
  /// **'Bill Summary'**
  String get billSummary;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @discountHint.
  ///
  /// In en, this message translates to:
  /// **'Enter discount'**
  String get discountHint;

  /// No description provided for @previousBalance.
  ///
  /// In en, this message translates to:
  /// **'Previous Balance'**
  String get previousBalance;

  /// No description provided for @payableAmount.
  ///
  /// In en, this message translates to:
  /// **'Payable Amount'**
  String get payableAmount;

  /// No description provided for @generateBill.
  ///
  /// In en, this message translates to:
  /// **'Generate Bill'**
  String get generateBill;

  /// No description provided for @billGenerated.
  ///
  /// In en, this message translates to:
  /// **'Bill generated successfully!'**
  String get billGenerated;

  /// No description provided for @shareBill.
  ///
  /// In en, this message translates to:
  /// **'Share Bill'**
  String get shareBill;

  /// No description provided for @printBill.
  ///
  /// In en, this message translates to:
  /// **'Print Bill'**
  String get printBill;

  /// No description provided for @saveBill.
  ///
  /// In en, this message translates to:
  /// **'Save Bill'**
  String get saveBill;

  /// No description provided for @noBillsYet.
  ///
  /// In en, this message translates to:
  /// **'No bills yet'**
  String get noBillsYet;

  /// No description provided for @searchBilling.
  ///
  /// In en, this message translates to:
  /// **'Search items...'**
  String get searchBilling;

  /// No description provided for @cart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cart;

  /// No description provided for @cartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Cart is empty'**
  String get cartEmpty;

  /// No description provided for @cartEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add items from the catalog to create a bill'**
  String get cartEmptySubtitle;

  /// No description provided for @catalog.
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get catalog;

  /// No description provided for @addToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get addToCart;

  /// No description provided for @removeFromCart.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeFromCart;

  /// No description provided for @clearCart.
  ///
  /// In en, this message translates to:
  /// **'Clear Cart'**
  String get clearCart;

  /// No description provided for @itemsInCart.
  ///
  /// In en, this message translates to:
  /// **'{count} items in cart'**
  String itemsInCart(int count);

  /// No description provided for @checkout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkout;

  /// No description provided for @todayBills.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Bills'**
  String get todayBills;

  /// No description provided for @invoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'INVOICE'**
  String get invoiceTitle;

  /// No description provided for @thankYouBusiness.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your business!'**
  String get thankYouBusiness;

  /// No description provided for @generatedByApp.
  ///
  /// In en, this message translates to:
  /// **'Generated by KhataSetu'**
  String get generatedByApp;

  /// No description provided for @reportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsTitle;

  /// No description provided for @dailyReport.
  ///
  /// In en, this message translates to:
  /// **'Daily Report'**
  String get dailyReport;

  /// No description provided for @weeklyReport.
  ///
  /// In en, this message translates to:
  /// **'Weekly Report'**
  String get weeklyReport;

  /// No description provided for @monthlyReport.
  ///
  /// In en, this message translates to:
  /// **'Monthly Report'**
  String get monthlyReport;

  /// No description provided for @yearlyReport.
  ///
  /// In en, this message translates to:
  /// **'Yearly Report'**
  String get yearlyReport;

  /// No description provided for @customReport.
  ///
  /// In en, this message translates to:
  /// **'Custom Report'**
  String get customReport;

  /// No description provided for @customerStatement.
  ///
  /// In en, this message translates to:
  /// **'Customer Statement'**
  String get customerStatement;

  /// No description provided for @selectReportType.
  ///
  /// In en, this message translates to:
  /// **'Select Report Type'**
  String get selectReportType;

  /// No description provided for @selectDateRange.
  ///
  /// In en, this message translates to:
  /// **'Select Date Range'**
  String get selectDateRange;

  /// No description provided for @dateRange.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get dateRange;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @generateReportButton.
  ///
  /// In en, this message translates to:
  /// **'Generate Report'**
  String get generateReportButton;

  /// No description provided for @reportGenerated.
  ///
  /// In en, this message translates to:
  /// **'Report generated successfully!'**
  String get reportGenerated;

  /// No description provided for @reportGenerating.
  ///
  /// In en, this message translates to:
  /// **'Generating report...'**
  String get reportGenerating;

  /// No description provided for @reportError.
  ///
  /// In en, this message translates to:
  /// **'Error generating report: {error}'**
  String reportError(String error);

  /// No description provided for @previewAndPrint.
  ///
  /// In en, this message translates to:
  /// **'Preview & Print'**
  String get previewAndPrint;

  /// No description provided for @previewAndPrintSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open PDF preview with print option'**
  String get previewAndPrintSubtitle;

  /// No description provided for @sharePdf.
  ///
  /// In en, this message translates to:
  /// **'Share PDF'**
  String get sharePdf;

  /// No description provided for @sharePdfSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send via WhatsApp, Email, etc.'**
  String get sharePdfSubtitle;

  /// No description provided for @saveToDevice.
  ///
  /// In en, this message translates to:
  /// **'Save to Device'**
  String get saveToDevice;

  /// No description provided for @saveToDeviceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Download PDF to your phone'**
  String get saveToDeviceSubtitle;

  /// No description provided for @savedTo.
  ///
  /// In en, this message translates to:
  /// **'Saved to {path}'**
  String savedTo(String path);

  /// No description provided for @chooseAction.
  ///
  /// In en, this message translates to:
  /// **'Choose what to do with your PDF report'**
  String get chooseAction;

  /// No description provided for @quickReports.
  ///
  /// In en, this message translates to:
  /// **'Quick Reports'**
  String get quickReports;

  /// No description provided for @todayTotal.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Total'**
  String get todayTotal;

  /// No description provided for @monthTotal.
  ///
  /// In en, this message translates to:
  /// **'Month\'s Total'**
  String get monthTotal;

  /// No description provided for @outstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get outstanding;

  /// No description provided for @debtors.
  ///
  /// In en, this message translates to:
  /// **'Debtors'**
  String get debtors;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @period.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get period;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @categoryBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Category Breakdown'**
  String get categoryBreakdown;

  /// No description provided for @closingBalance.
  ///
  /// In en, this message translates to:
  /// **'Closing Balance'**
  String get closingBalance;

  /// No description provided for @openingBalance.
  ///
  /// In en, this message translates to:
  /// **'Opening Balance'**
  String get openingBalance;

  /// No description provided for @due.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get due;

  /// No description provided for @advance.
  ///
  /// In en, this message translates to:
  /// **'Advance'**
  String get advance;

  /// No description provided for @reportCustomerName.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get reportCustomerName;

  /// No description provided for @reportDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get reportDescription;

  /// No description provided for @reportType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get reportType;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @dataAndSync.
  ///
  /// In en, this message translates to:
  /// **'Data & Sync'**
  String get dataAndSync;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemTheme;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @pushNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Payment reminders & alerts'**
  String get pushNotificationsSubtitle;

  /// No description provided for @biometricLock.
  ///
  /// In en, this message translates to:
  /// **'Biometric Lock'**
  String get biometricLock;

  /// No description provided for @biometricLockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock app with fingerprint'**
  String get biometricLockSubtitle;

  /// No description provided for @changePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get changePin;

  /// No description provided for @changePinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your security PIN'**
  String get changePinSubtitle;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNow;

  /// No description provided for @syncNowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Never synced'**
  String get syncNowSubtitle;

  /// No description provided for @lastSynced.
  ///
  /// In en, this message translates to:
  /// **'Last: {time}'**
  String lastSynced(String time);

  /// No description provided for @syncRequiresBackend.
  ///
  /// In en, this message translates to:
  /// **'Sync requires backend connection'**
  String get syncRequiresBackend;

  /// No description provided for @exportBackup.
  ///
  /// In en, this message translates to:
  /// **'Export Backup'**
  String get exportBackup;

  /// No description provided for @exportBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Download your data as JSON'**
  String get exportBackupSubtitle;

  /// No description provided for @clearAllData.
  ///
  /// In en, this message translates to:
  /// **'Clear All Data'**
  String get clearAllData;

  /// No description provided for @clearAllDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Erase all local data permanently'**
  String get clearAllDataSubtitle;

  /// No description provided for @clearAllDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear All Data?'**
  String get clearAllDataTitle;

  /// No description provided for @clearAllDataMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently erase all customers, transactions, and settings. This cannot be undone.'**
  String get clearAllDataMessage;

  /// No description provided for @allDataCleared.
  ///
  /// In en, this message translates to:
  /// **'All data cleared'**
  String get allDataCleared;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsAndConditions;

  /// No description provided for @termsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Read our terms of service'**
  String get termsSubtitle;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @privacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'How we handle your data'**
  String get privacySubtitle;

  /// No description provided for @rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate App'**
  String get rateApp;

  /// No description provided for @rateAppSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Love KhataSetu? Rate us!'**
  String get rateAppSubtitle;

  /// No description provided for @languageChanged.
  ///
  /// In en, this message translates to:
  /// **'Language changed to {language}'**
  String languageChanged(String language);

  /// No description provided for @upiQrSetup.
  ///
  /// In en, this message translates to:
  /// **'UPI QR Setup'**
  String get upiQrSetup;

  /// No description provided for @upiQrSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure UPI ID & QR code'**
  String get upiQrSetupSubtitle;

  /// No description provided for @upiSetup.
  ///
  /// In en, this message translates to:
  /// **'UPI Setup'**
  String get upiSetup;

  /// No description provided for @upiId.
  ///
  /// In en, this message translates to:
  /// **'UPI ID'**
  String get upiId;

  /// No description provided for @upiIdHint.
  ///
  /// In en, this message translates to:
  /// **'Enter UPI ID (e.g., name@upi)'**
  String get upiIdHint;

  /// No description provided for @merchantName.
  ///
  /// In en, this message translates to:
  /// **'Merchant Name'**
  String get merchantName;

  /// No description provided for @merchantNameHint.
  ///
  /// In en, this message translates to:
  /// **'Your shop/business name'**
  String get merchantNameHint;

  /// No description provided for @uploadQr.
  ///
  /// In en, this message translates to:
  /// **'Upload QR'**
  String get uploadQr;

  /// No description provided for @uploadQrSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload your UPI QR code image'**
  String get uploadQrSubtitle;

  /// No description provided for @replaceImage.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replaceImage;

  /// No description provided for @removeImage.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeImage;

  /// No description provided for @generateQr.
  ///
  /// In en, this message translates to:
  /// **'Generate QR'**
  String get generateQr;

  /// No description provided for @scanToPay.
  ///
  /// In en, this message translates to:
  /// **'Scan to Pay'**
  String get scanToPay;

  /// No description provided for @payAmount.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount}'**
  String payAmount(String amount);

  /// No description provided for @upiSaved.
  ///
  /// In en, this message translates to:
  /// **'UPI configuration saved!'**
  String get upiSaved;

  /// No description provided for @upiRemoved.
  ///
  /// In en, this message translates to:
  /// **'UPI configuration removed'**
  String get upiRemoved;

  /// No description provided for @noUpiSetup.
  ///
  /// In en, this message translates to:
  /// **'No UPI configured'**
  String get noUpiSetup;

  /// No description provided for @noUpiSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your UPI to accept digital payments'**
  String get noUpiSubtitle;

  /// No description provided for @shareQr.
  ///
  /// In en, this message translates to:
  /// **'Share QR'**
  String get shareQr;

  /// No description provided for @paymentTo.
  ///
  /// In en, this message translates to:
  /// **'Payment to {name}'**
  String paymentTo(String name);

  /// No description provided for @poweredByUpi.
  ///
  /// In en, this message translates to:
  /// **'Powered by UPI'**
  String get poweredByUpi;

  /// No description provided for @tapToShowQr.
  ///
  /// In en, this message translates to:
  /// **'Show QR'**
  String get tapToShowQr;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @selectLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get selectLanguageSubtitle;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @gujarati.
  ///
  /// In en, this message translates to:
  /// **'ગુજરાતી'**
  String get gujarati;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'हिंदी'**
  String get hindi;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageGujarati.
  ///
  /// In en, this message translates to:
  /// **'Gujarati'**
  String get languageGujarati;

  /// No description provided for @languageHindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get languageHindi;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'{field} is required'**
  String fieldRequired(String field);

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneRequired;

  /// No description provided for @phoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 10-digit phone number'**
  String get phoneInvalid;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordMinLength;

  /// No description provided for @passwordUppercase.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one uppercase letter'**
  String get passwordUppercase;

  /// No description provided for @passwordLowercase.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one lowercase letter'**
  String get passwordLowercase;

  /// No description provided for @passwordNumber.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one number'**
  String get passwordNumber;

  /// No description provided for @passwordSpecial.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one special character'**
  String get passwordSpecial;

  /// No description provided for @pinRequired.
  ///
  /// In en, this message translates to:
  /// **'PIN is required'**
  String get pinRequired;

  /// No description provided for @pinLength.
  ///
  /// In en, this message translates to:
  /// **'PIN must be {length} digits'**
  String pinLength(int length);

  /// No description provided for @pinDigitsOnly.
  ///
  /// In en, this message translates to:
  /// **'PIN must contain only digits'**
  String get pinDigitsOnly;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @nameMinLength.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get nameMinLength;

  /// No description provided for @nameMaxLength.
  ///
  /// In en, this message translates to:
  /// **'Name cannot exceed 100 characters'**
  String get nameMaxLength;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get emailInvalid;

  /// No description provided for @amountRequired.
  ///
  /// In en, this message translates to:
  /// **'Amount is required'**
  String get amountRequired;

  /// No description provided for @amountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get amountInvalid;

  /// No description provided for @amountPositive.
  ///
  /// In en, this message translates to:
  /// **'Amount must be greater than 0'**
  String get amountPositive;

  /// No description provided for @amountMaxExceeded.
  ///
  /// In en, this message translates to:
  /// **'Amount cannot exceed {symbol}{max}'**
  String amountMaxExceeded(String symbol, String max);

  /// No description provided for @otpRequired.
  ///
  /// In en, this message translates to:
  /// **'OTP is required'**
  String get otpRequired;

  /// No description provided for @otpLength.
  ///
  /// In en, this message translates to:
  /// **'OTP must be {length} digits'**
  String otpLength(int length);

  /// No description provided for @otpDigitsOnly.
  ///
  /// In en, this message translates to:
  /// **'OTP must contain only digits'**
  String get otpDigitsOnly;

  /// No description provided for @shopNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Shop name is required'**
  String get shopNameRequired;

  /// No description provided for @shopNameMinLength.
  ///
  /// In en, this message translates to:
  /// **'Shop name must be at least 2 characters'**
  String get shopNameMinLength;

  /// No description provided for @shopNameMaxLength.
  ///
  /// In en, this message translates to:
  /// **'Shop name cannot exceed 150 characters'**
  String get shopNameMaxLength;

  /// No description provided for @addressRequired.
  ///
  /// In en, this message translates to:
  /// **'Address is required'**
  String get addressRequired;

  /// No description provided for @addressMinLength.
  ///
  /// In en, this message translates to:
  /// **'Please enter a complete address'**
  String get addressMinLength;

  /// No description provided for @addressMaxLength.
  ///
  /// In en, this message translates to:
  /// **'Address cannot exceed 500 characters'**
  String get addressMaxLength;

  /// No description provided for @quantityRequired.
  ///
  /// In en, this message translates to:
  /// **'Quantity is required'**
  String get quantityRequired;

  /// No description provided for @quantityInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid quantity'**
  String get quantityInvalid;

  /// No description provided for @quantityNegative.
  ///
  /// In en, this message translates to:
  /// **'Quantity cannot be negative'**
  String get quantityNegative;

  /// No description provided for @confirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Confirm password is required'**
  String get confirmPasswordRequired;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @pdfDailyReport.
  ///
  /// In en, this message translates to:
  /// **'Daily Report - {date}'**
  String pdfDailyReport(String date);

  /// No description provided for @pdfWeeklyReport.
  ///
  /// In en, this message translates to:
  /// **'Weekly Report'**
  String get pdfWeeklyReport;

  /// No description provided for @pdfMonthlyReport.
  ///
  /// In en, this message translates to:
  /// **'Monthly Report - {month}'**
  String pdfMonthlyReport(String month);

  /// No description provided for @pdfYearlyReport.
  ///
  /// In en, this message translates to:
  /// **'Yearly Report - {year}'**
  String pdfYearlyReport(String year);

  /// No description provided for @pdfCustomerStatement.
  ///
  /// In en, this message translates to:
  /// **'Customer Statement - {name}'**
  String pdfCustomerStatement(String name);

  /// No description provided for @pdfCustomReport.
  ///
  /// In en, this message translates to:
  /// **'Custom Report'**
  String get pdfCustomReport;

  /// No description provided for @pdfGeneratedBy.
  ///
  /// In en, this message translates to:
  /// **'Generated by KhataSetu on {date} at {time}'**
  String pdfGeneratedBy(String date, String time);

  /// No description provided for @pdfPage.
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String pdfPage(int current, int total);

  /// No description provided for @pdfDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get pdfDate;

  /// No description provided for @pdfCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get pdfCustomer;

  /// No description provided for @pdfDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get pdfDescription;

  /// No description provided for @pdfType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get pdfType;

  /// No description provided for @pdfAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get pdfAmount;

  /// No description provided for @pdfCredit.
  ///
  /// In en, this message translates to:
  /// **'CREDIT'**
  String get pdfCredit;

  /// No description provided for @pdfDebit.
  ///
  /// In en, this message translates to:
  /// **'DEBIT'**
  String get pdfDebit;

  /// No description provided for @pdfPayment.
  ///
  /// In en, this message translates to:
  /// **'PAYMENT'**
  String get pdfPayment;

  /// No description provided for @pdfNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes:'**
  String get pdfNotes;

  /// No description provided for @pdfBillTo.
  ///
  /// In en, this message translates to:
  /// **'Bill To: '**
  String get pdfBillTo;

  /// No description provided for @pdfSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get pdfSubtotal;

  /// No description provided for @pdfDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get pdfDiscount;

  /// No description provided for @pdfPreviousBalance.
  ///
  /// In en, this message translates to:
  /// **'Previous Balance'**
  String get pdfPreviousBalance;

  /// No description provided for @pdfGrandTotal.
  ///
  /// In en, this message translates to:
  /// **'Grand Total'**
  String get pdfGrandTotal;

  /// No description provided for @pdfItem.
  ///
  /// In en, this message translates to:
  /// **'#'**
  String get pdfItem;

  /// No description provided for @pdfItemName.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get pdfItemName;

  /// No description provided for @pdfQty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get pdfQty;

  /// No description provided for @pdfUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get pdfUnit;

  /// No description provided for @pdfPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get pdfPrice;

  /// No description provided for @pdfTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get pdfTotal;

  /// No description provided for @pdfTotalCredit.
  ///
  /// In en, this message translates to:
  /// **'Total Credit'**
  String get pdfTotalCredit;

  /// No description provided for @pdfTotalDebit.
  ///
  /// In en, this message translates to:
  /// **'Total Debit'**
  String get pdfTotalDebit;

  /// No description provided for @pdfNetBalance.
  ///
  /// In en, this message translates to:
  /// **'Net Balance'**
  String get pdfNetBalance;

  /// No description provided for @pdfTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get pdfTransactions;

  /// No description provided for @pdfClosingBalance.
  ///
  /// In en, this message translates to:
  /// **'Closing Balance'**
  String get pdfClosingBalance;

  /// No description provided for @pdfOpeningBalance.
  ///
  /// In en, this message translates to:
  /// **'Opening Balance'**
  String get pdfOpeningBalance;

  /// No description provided for @pdfThankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your business!'**
  String get pdfThankYou;

  /// No description provided for @pdfPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get pdfPeriod;

  /// No description provided for @pdfCategoryBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Category Breakdown'**
  String get pdfCategoryBreakdown;

  /// No description provided for @pdfDue.
  ///
  /// In en, this message translates to:
  /// **'(Due)'**
  String get pdfDue;

  /// No description provided for @pdfAdvance.
  ///
  /// In en, this message translates to:
  /// **'(Advance)'**
  String get pdfAdvance;

  /// No description provided for @pdfBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get pdfBalance;

  /// No description provided for @pdfPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get pdfPhoneLabel;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get errorNetwork;

  /// No description provided for @errorTimeout.
  ///
  /// In en, this message translates to:
  /// **'Request timed out. Please try again.'**
  String get errorTimeout;

  /// No description provided for @errorServer.
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try later.'**
  String get errorServer;

  /// No description provided for @errorUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please login again.'**
  String get errorUnauthorized;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get errorNotFound;

  /// No description provided for @errorNotFoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The page you are looking for does not exist.'**
  String get errorNotFoundSubtitle;

  /// No description provided for @goToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Go to Dashboard'**
  String get goToDashboard;

  /// No description provided for @errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Error loading data'**
  String get errorLoadingData;

  /// No description provided for @errorSavingData.
  ///
  /// In en, this message translates to:
  /// **'Error saving data'**
  String get errorSavingData;

  /// No description provided for @offlineMode.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode'**
  String get offlineMode;

  /// No description provided for @offlineModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Data will sync when you\'re back online'**
  String get offlineModeSubtitle;

  /// No description provided for @syncInProgress.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncInProgress;

  /// No description provided for @syncComplete.
  ///
  /// In en, this message translates to:
  /// **'Sync completed successfully'**
  String get syncComplete;

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed. Please try again'**
  String get syncFailed;

  /// No description provided for @pendingSync.
  ///
  /// In en, this message translates to:
  /// **'{count} changes pending sync'**
  String pendingSync(int count);

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String minutesAgo(int minutes);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String hoursAgo(int hours);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String daysAgo(int days);

  /// No description provided for @weeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{weeks}w ago'**
  String weeksAgo(int weeks);

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @currencySymbol.
  ///
  /// In en, this message translates to:
  /// **'₹'**
  String get currencySymbol;

  /// No description provided for @currencyCode.
  ///
  /// In en, this message translates to:
  /// **'INR'**
  String get currencyCode;

  /// No description provided for @emptyCustomers.
  ///
  /// In en, this message translates to:
  /// **'No customers yet'**
  String get emptyCustomers;

  /// No description provided for @emptyCustomersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add your first customer'**
  String get emptyCustomersSubtitle;

  /// No description provided for @emptyTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get emptyTransactions;

  /// No description provided for @emptyTransactionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start by adding a transaction'**
  String get emptyTransactionsSubtitle;

  /// No description provided for @emptyProducts.
  ///
  /// In en, this message translates to:
  /// **'No products yet'**
  String get emptyProducts;

  /// No description provided for @emptyProductsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first product to manage inventory'**
  String get emptyProductsSubtitle;

  /// No description provided for @emptyReports.
  ///
  /// In en, this message translates to:
  /// **'No reports generated'**
  String get emptyReports;

  /// No description provided for @emptyReportsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select report type and date range to generate'**
  String get emptyReportsSubtitle;

  /// No description provided for @emptyBills.
  ///
  /// In en, this message translates to:
  /// **'No bills yet'**
  String get emptyBills;

  /// No description provided for @emptyBillsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your first bill'**
  String get emptyBillsSubtitle;

  /// No description provided for @emptySearch.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get emptySearch;

  /// No description provided for @emptySearchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try different search terms'**
  String get emptySearchSubtitle;

  /// No description provided for @todaySummary.
  ///
  /// In en, this message translates to:
  /// **'TODAY\'S SUMMARY'**
  String get todaySummary;

  /// No description provided for @fromYesterday.
  ///
  /// In en, this message translates to:
  /// **'from yesterday'**
  String get fromYesterday;

  /// No description provided for @totalTransactions.
  ///
  /// In en, this message translates to:
  /// **'Total Transactions'**
  String get totalTransactions;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get allTime;

  /// No description provided for @revenueOverview.
  ///
  /// In en, this message translates to:
  /// **'Revenue Overview'**
  String get revenueOverview;

  /// No description provided for @noCreditTransactionsYet.
  ///
  /// In en, this message translates to:
  /// **'No credit transactions yet'**
  String get noCreditTransactionsYet;

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get week;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @newSale.
  ///
  /// In en, this message translates to:
  /// **'New Sale'**
  String get newSale;

  /// No description provided for @selectShop.
  ///
  /// In en, this message translates to:
  /// **'Select Shop'**
  String get selectShop;

  /// No description provided for @addNewShop.
  ///
  /// In en, this message translates to:
  /// **'Add New Shop'**
  String get addNewShop;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// No description provided for @otpLogin.
  ///
  /// In en, this message translates to:
  /// **'OTP Login'**
  String get otpLogin;

  /// No description provided for @demoModeActive.
  ///
  /// In en, this message translates to:
  /// **'Demo Mode Active'**
  String get demoModeActive;

  /// No description provided for @demoModeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter any phone & password to explore the app'**
  String get demoModeHint;

  /// No description provided for @registerNow.
  ///
  /// In en, this message translates to:
  /// **'Register Now'**
  String get registerNow;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start your digital khata journey in minutes'**
  String get registerSubtitle;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @shopDetails.
  ///
  /// In en, this message translates to:
  /// **'Shop Details'**
  String get shopDetails;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get fullNameHint;

  /// No description provided for @businessType.
  ///
  /// In en, this message translates to:
  /// **'Business Type'**
  String get businessType;

  /// No description provided for @createPassword.
  ///
  /// In en, this message translates to:
  /// **'Create Password'**
  String get createPassword;

  /// No description provided for @createPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Min 8 chars with upper, lower, number'**
  String get createPasswordHint;

  /// No description provided for @passwordStrengthWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get passwordStrengthWeak;

  /// No description provided for @passwordStrengthMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get passwordStrengthMedium;

  /// No description provided for @passwordStrengthStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get passwordStrengthStrong;

  /// No description provided for @passwordStrengthPrefix.
  ///
  /// In en, this message translates to:
  /// **'Password Strength:'**
  String get passwordStrengthPrefix;

  /// No description provided for @agreeToTermsMessage.
  ///
  /// In en, this message translates to:
  /// **'Please agree to Terms & Conditions'**
  String get agreeToTermsMessage;

  /// No description provided for @welcomeAboard.
  ///
  /// In en, this message translates to:
  /// **'Welcome Aboard! 🎉'**
  String get welcomeAboard;

  /// No description provided for @accountCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your account has been created successfully.'**
  String get accountCreatedSuccess;

  /// No description provided for @shopIsReady.
  ///
  /// In en, this message translates to:
  /// **'{shop} is ready!'**
  String shopIsReady(String shop);

  /// No description provided for @startYourKhata.
  ///
  /// In en, this message translates to:
  /// **'Start Your Khata'**
  String get startYourKhata;

  /// No description provided for @iAgreeToThe.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get iAgreeToThe;

  /// No description provided for @andWord.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get andWord;

  /// No description provided for @loadingYourShop.
  ///
  /// In en, this message translates to:
  /// **'Loading your shop...'**
  String get loadingYourShop;

  /// No description provided for @noCustomersFound.
  ///
  /// In en, this message translates to:
  /// **'No customers found'**
  String get noCustomersFound;

  /// No description provided for @adjustSearchOrFilters.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filters'**
  String get adjustSearchOrFilters;

  /// No description provided for @searchByNameOrPhone.
  ///
  /// In en, this message translates to:
  /// **'Search by name or phone...'**
  String get searchByNameOrPhone;

  /// No description provided for @totalPending.
  ///
  /// In en, this message translates to:
  /// **'Total Pending'**
  String get totalPending;

  /// No description provided for @countWithPending.
  ///
  /// In en, this message translates to:
  /// **'{count} with pending'**
  String countWithPending(int count);

  /// No description provided for @weOwe.
  ///
  /// In en, this message translates to:
  /// **'We Owe'**
  String get weOwe;

  /// No description provided for @nameAZ.
  ///
  /// In en, this message translates to:
  /// **'Name (A-Z)'**
  String get nameAZ;

  /// No description provided for @balanceHighLow.
  ///
  /// In en, this message translates to:
  /// **'Balance (High-Low)'**
  String get balanceHighLow;

  /// No description provided for @recentlyActive.
  ///
  /// In en, this message translates to:
  /// **'Recently Active'**
  String get recentlyActive;

  /// No description provided for @addCredit.
  ///
  /// In en, this message translates to:
  /// **'Add Credit'**
  String get addCredit;

  /// No description provided for @recordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record Payment'**
  String get recordPayment;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @owesYou.
  ///
  /// In en, this message translates to:
  /// **'owes you'**
  String get owesYou;

  /// No description provided for @youOweLabel.
  ///
  /// In en, this message translates to:
  /// **'you owe'**
  String get youOweLabel;

  /// No description provided for @whatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsApp;

  /// No description provided for @transaction.
  ///
  /// In en, this message translates to:
  /// **'Transaction'**
  String get transaction;

  /// No description provided for @quickCreditDescription.
  ///
  /// In en, this message translates to:
  /// **'Quick credit from customer list'**
  String get quickCreditDescription;

  /// No description provided for @quickPaymentDescription.
  ///
  /// In en, this message translates to:
  /// **'Quick payment from customer list'**
  String get quickPaymentDescription;

  /// No description provided for @creditAddedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Credit of ₹{amount} added to {name}'**
  String creditAddedSnackbar(String amount, String name);

  /// No description provided for @paymentReceivedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Payment of ₹{amount} received from {name}'**
  String paymentReceivedSnackbar(String amount, String name);

  /// No description provided for @callingPhone.
  ///
  /// In en, this message translates to:
  /// **'Calling {phone}...'**
  String callingPhone(String phone);

  /// No description provided for @openingWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Opening WhatsApp for {name}...'**
  String openingWhatsApp(String name);

  /// No description provided for @balanceAmount.
  ///
  /// In en, this message translates to:
  /// **'Balance: ₹{amount}'**
  String balanceAmount(String amount);

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Info'**
  String get personalInfo;

  /// No description provided for @contactDetails.
  ///
  /// In en, this message translates to:
  /// **'Contact Details'**
  String get contactDetails;

  /// No description provided for @creditSettings.
  ///
  /// In en, this message translates to:
  /// **'Credit Settings'**
  String get creditSettings;

  /// No description provided for @creditLimitOptional.
  ///
  /// In en, this message translates to:
  /// **'Credit Limit (Optional)'**
  String get creditLimitOptional;

  /// No description provided for @maxCreditAllowed.
  ///
  /// In en, this message translates to:
  /// **'Maximum credit allowed'**
  String get maxCreditAllowed;

  /// No description provided for @enterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter valid amount'**
  String get enterValidAmount;

  /// No description provided for @notesSection.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesSection;

  /// No description provided for @tapToChangeAvatar.
  ///
  /// In en, this message translates to:
  /// **'Tap to change avatar'**
  String get tapToChangeAvatar;

  /// No description provided for @chooseAvatar.
  ///
  /// In en, this message translates to:
  /// **'Choose Avatar'**
  String get chooseAvatar;

  /// No description provided for @addAnother.
  ///
  /// In en, this message translates to:
  /// **'Add Another'**
  String get addAnother;

  /// No description provided for @customerAddedTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer Added!'**
  String get customerAddedTitle;

  /// No description provided for @customerAddedMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} has been added to your customer list.'**
  String customerAddedMessage(String name);

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @detailsTab.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailsTab;

  /// No description provided for @totalPaid.
  ///
  /// In en, this message translates to:
  /// **'Total Paid'**
  String get totalPaid;

  /// No description provided for @paymentProgress.
  ///
  /// In en, this message translates to:
  /// **'Payment Progress'**
  String get paymentProgress;

  /// No description provided for @paidAmount.
  ///
  /// In en, this message translates to:
  /// **'Paid: {amount}'**
  String paidAmount(String amount);

  /// No description provided for @remainingAmount.
  ///
  /// In en, this message translates to:
  /// **'Remaining: {amount}'**
  String remainingAmount(String amount);

  /// No description provided for @monthlyActivity.
  ///
  /// In en, this message translates to:
  /// **'Monthly Activity'**
  String get monthlyActivity;

  /// No description provided for @trustScoreBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Trust Score Breakdown'**
  String get trustScoreBreakdown;

  /// No description provided for @paymentHistoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment History'**
  String get paymentHistoryLabel;

  /// No description provided for @paymentTimeliness.
  ///
  /// In en, this message translates to:
  /// **'Payment Timeliness'**
  String get paymentTimeliness;

  /// No description provided for @creditUtilization.
  ///
  /// In en, this message translates to:
  /// **'Credit Utilization'**
  String get creditUtilization;

  /// No description provided for @relationshipLabel.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get relationshipLabel;

  /// No description provided for @contactInformation.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get contactInformation;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @notProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get notProvided;

  /// No description provided for @accountInformation.
  ///
  /// In en, this message translates to:
  /// **'Account Information'**
  String get accountInformation;

  /// No description provided for @customerSinceLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer Since'**
  String get customerSinceLabel;

  /// No description provided for @lastActivity.
  ///
  /// In en, this message translates to:
  /// **'Last Activity'**
  String get lastActivity;

  /// No description provided for @noActivity.
  ///
  /// In en, this message translates to:
  /// **'No activity'**
  String get noActivity;

  /// No description provided for @creditLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'Credit Limit'**
  String get creditLimitLabel;

  /// No description provided for @sms.
  ///
  /// In en, this message translates to:
  /// **'SMS'**
  String get sms;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @lastTransactionUndone.
  ///
  /// In en, this message translates to:
  /// **'Last transaction undone'**
  String get lastTransactionUndone;

  /// No description provided for @sendStatement.
  ///
  /// In en, this message translates to:
  /// **'Send Statement'**
  String get sendStatement;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportData;

  /// No description provided for @deleteCustomerLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete Customer'**
  String get deleteCustomerLabel;

  /// No description provided for @balanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balanceLabel;

  /// No description provided for @trustLabel.
  ///
  /// In en, this message translates to:
  /// **'Trust'**
  String get trustLabel;

  /// No description provided for @limitLabel.
  ///
  /// In en, this message translates to:
  /// **'Limit'**
  String get limitLabel;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @balAfter.
  ///
  /// In en, this message translates to:
  /// **'Bal: ₹{amount}'**
  String balAfter(String amount);

  /// No description provided for @lastDate.
  ///
  /// In en, this message translates to:
  /// **'Last: {date}'**
  String lastDate(String date);

  /// No description provided for @enterFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter full name'**
  String get enterFullName;

  /// No description provided for @enterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter 10-digit phone number'**
  String get enterPhoneNumber;

  /// No description provided for @enterFullAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter full address'**
  String get enterFullAddress;

  /// No description provided for @khataBook.
  ///
  /// In en, this message translates to:
  /// **'Khata Book'**
  String get khataBook;

  /// No description provided for @yourDailyNotebook.
  ///
  /// In en, this message translates to:
  /// **'Your daily notebook'**
  String get yourDailyNotebook;

  /// No description provided for @khataEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your khata is empty'**
  String get khataEmpty;

  /// No description provided for @tapToAddFirstEntry.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add the first entry'**
  String get tapToAddFirstEntry;

  /// No description provided for @noMatchingEntries.
  ///
  /// In en, this message translates to:
  /// **'No matching entries'**
  String get noMatchingEntries;

  /// No description provided for @searchByCustomerOrDescription.
  ///
  /// In en, this message translates to:
  /// **'Search by customer or description...'**
  String get searchByCustomerOrDescription;

  /// No description provided for @entriesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} entries'**
  String entriesCount(int count);

  /// No description provided for @filtered.
  ///
  /// In en, this message translates to:
  /// **'Filtered'**
  String get filtered;

  /// No description provided for @received.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get received;

  /// No description provided for @addEntry.
  ///
  /// In en, this message translates to:
  /// **'Add Entry'**
  String get addEntry;

  /// No description provided for @net.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get net;

  /// No description provided for @newTransaction.
  ///
  /// In en, this message translates to:
  /// **'New Transaction'**
  String get newTransaction;

  /// No description provided for @pleaseSelectCustomer.
  ///
  /// In en, this message translates to:
  /// **'Please select a customer'**
  String get pleaseSelectCustomer;

  /// No description provided for @paymentReceivedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Payment Received!'**
  String get paymentReceivedSuccess;

  /// No description provided for @creditRecordedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Credit Recorded!'**
  String get creditRecordedSuccess;

  /// No description provided for @newPurchase.
  ///
  /// In en, this message translates to:
  /// **'New Purchase'**
  String get newPurchase;

  /// No description provided for @customerBuysOnCredit.
  ///
  /// In en, this message translates to:
  /// **'Customer buys on credit'**
  String get customerBuysOnCredit;

  /// No description provided for @customerPaysYou.
  ///
  /// In en, this message translates to:
  /// **'Customer pays you'**
  String get customerPaysYou;

  /// No description provided for @addCustomersFirst.
  ///
  /// In en, this message translates to:
  /// **'Add customers from the Customers tab first'**
  String get addCustomersFirst;

  /// No description provided for @paymentAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Amount'**
  String get paymentAmountLabel;

  /// No description provided for @purchaseAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Purchase Amount'**
  String get purchaseAmountLabel;

  /// No description provided for @quickAmount.
  ///
  /// In en, this message translates to:
  /// **'Quick Amount'**
  String get quickAmount;

  /// No description provided for @recordPaymentPlus.
  ///
  /// In en, this message translates to:
  /// **'Record Payment (+)'**
  String get recordPaymentPlus;

  /// No description provided for @recordPurchaseMinus.
  ///
  /// In en, this message translates to:
  /// **'Record Purchase (-)'**
  String get recordPurchaseMinus;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get descriptionOptional;

  /// No description provided for @paymentViaCashHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Payment via cash'**
  String get paymentViaCashHint;

  /// No description provided for @groceryItemsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Grocery items - Rice, Dal'**
  String get groceryItemsHint;

  /// No description provided for @detailsSection.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailsSection;

  /// No description provided for @tapToAddFirstCreditOrPayment.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add the first credit or payment'**
  String get tapToAddFirstCreditOrPayment;

  /// No description provided for @outstandingBalance.
  ///
  /// In en, this message translates to:
  /// **'Outstanding Balance'**
  String get outstandingBalance;

  /// No description provided for @allSettled.
  ///
  /// In en, this message translates to:
  /// **'All Settled'**
  String get allSettled;

  /// No description provided for @overCreditLimitAmount.
  ///
  /// In en, this message translates to:
  /// **'Over credit limit (₹{amount})'**
  String overCreditLimitAmount(String amount);

  /// No description provided for @overdueWithDays.
  ///
  /// In en, this message translates to:
  /// **'Overdue ({days} days)'**
  String overdueWithDays(int days);

  /// No description provided for @creditLabel.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get creditLabel;

  /// No description provided for @paymentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get paymentsLabel;

  /// No description provided for @entriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get entriesLabel;

  /// No description provided for @groceryPurchaseHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Grocery purchase'**
  String get groceryPurchaseHint;

  /// No description provided for @cashPaymentHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Cash payment'**
  String get cashPaymentHint;

  /// No description provided for @addCreditEntry.
  ///
  /// In en, this message translates to:
  /// **'Add Credit Entry'**
  String get addCreditEntry;

  /// No description provided for @transactionUndoneAmount.
  ///
  /// In en, this message translates to:
  /// **'Transaction of ₹{amount} undone'**
  String transactionUndoneAmount(String amount);

  /// No description provided for @creditOfAmountAdded.
  ///
  /// In en, this message translates to:
  /// **'Credit of ₹{amount} added'**
  String creditOfAmountAdded(String amount);

  /// No description provided for @paymentOfAmountRecorded.
  ///
  /// In en, this message translates to:
  /// **'Payment of ₹{amount} recorded'**
  String paymentOfAmountRecorded(String amount);

  /// No description provided for @shopAndInventory.
  ///
  /// In en, this message translates to:
  /// **'Shop & Inventory'**
  String get shopAndInventory;

  /// No description provided for @noProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get noProductsFound;

  /// No description provided for @tryChangingFiltersOrSearch.
  ///
  /// In en, this message translates to:
  /// **'Try changing filters or search'**
  String get tryChangingFiltersOrSearch;

  /// No description provided for @inStockCount.
  ///
  /// In en, this message translates to:
  /// **'{count} in stock'**
  String inStockCount(int count);

  /// No description provided for @viewCart.
  ///
  /// In en, this message translates to:
  /// **'View Cart'**
  String get viewCart;

  /// No description provided for @yourCart.
  ///
  /// In en, this message translates to:
  /// **'Your Cart'**
  String get yourCart;

  /// No description provided for @productEditingComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Product editing coming soon...'**
  String get productEditingComingSoon;

  /// No description provided for @updateStock.
  ///
  /// In en, this message translates to:
  /// **'Update Stock'**
  String get updateStock;

  /// No description provided for @addStockAction.
  ///
  /// In en, this message translates to:
  /// **'+ Add Stock'**
  String get addStockAction;

  /// No description provided for @removeStockAction.
  ///
  /// In en, this message translates to:
  /// **'- Remove Stock'**
  String get removeStockAction;

  /// No description provided for @stockAddedMessage.
  ///
  /// In en, this message translates to:
  /// **'Stock added: {qty} {unit}'**
  String stockAddedMessage(String qty, String unit);

  /// No description provided for @stockRemovedMessage.
  ///
  /// In en, this message translates to:
  /// **'Stock removed: {qty} {unit}'**
  String stockRemovedMessage(String qty, String unit);

  /// No description provided for @saleCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Sale Complete!'**
  String get saleCompleteTitle;

  /// No description provided for @transactionRecordedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Transaction has been recorded successfully'**
  String get transactionRecordedSuccess;

  /// No description provided for @completeSale.
  ///
  /// In en, this message translates to:
  /// **'Complete Sale'**
  String get completeSale;

  /// No description provided for @addToKhata.
  ///
  /// In en, this message translates to:
  /// **'Add to Khata'**
  String get addToKhata;

  /// No description provided for @recordAsCustomerCredit.
  ///
  /// In en, this message translates to:
  /// **'Record as customer credit'**
  String get recordAsCustomerCredit;

  /// No description provided for @shopTab.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shopTab;

  /// No description provided for @inventoryTab.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventoryTab;

  /// No description provided for @basicInformation.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInformation;

  /// No description provided for @categoryAndUnit.
  ///
  /// In en, this message translates to:
  /// **'Category & Unit'**
  String get categoryAndUnit;

  /// No description provided for @addProductImage.
  ///
  /// In en, this message translates to:
  /// **'Add Product Image'**
  String get addProductImage;

  /// No description provided for @tapToCaptureOrSelect.
  ///
  /// In en, this message translates to:
  /// **'Tap to capture or select from gallery'**
  String get tapToCaptureOrSelect;

  /// No description provided for @cameraGalleryComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Camera/Gallery coming soon'**
  String get cameraGalleryComingSoon;

  /// No description provided for @productAddedTitle.
  ///
  /// In en, this message translates to:
  /// **'Product Added!'**
  String get productAddedTitle;

  /// No description provided for @productAddedToInventory.
  ///
  /// In en, this message translates to:
  /// **'{name} has been added to your inventory.'**
  String productAddedToInventory(String name);

  /// No description provided for @addMore.
  ///
  /// In en, this message translates to:
  /// **'Add More'**
  String get addMore;

  /// No description provided for @buyPriceRequired.
  ///
  /// In en, this message translates to:
  /// **'Buy Price *'**
  String get buyPriceRequired;

  /// No description provided for @costLabel.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get costLabel;

  /// No description provided for @sellPriceRequired.
  ///
  /// In en, this message translates to:
  /// **'Sell Price *'**
  String get sellPriceRequired;

  /// No description provided for @mrpLabel.
  ///
  /// In en, this message translates to:
  /// **'MRP'**
  String get mrpLabel;

  /// No description provided for @profit.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get profit;

  /// No description provided for @marginLabel.
  ///
  /// In en, this message translates to:
  /// **'Margin'**
  String get marginLabel;

  /// No description provided for @stockManagement.
  ///
  /// In en, this message translates to:
  /// **'Stock Management'**
  String get stockManagement;

  /// No description provided for @trackInventory.
  ///
  /// In en, this message translates to:
  /// **'Track Inventory'**
  String get trackInventory;

  /// No description provided for @enableStockAlerts.
  ///
  /// In en, this message translates to:
  /// **'Enable stock tracking & low stock alerts'**
  String get enableStockAlerts;

  /// No description provided for @currentStockRequired.
  ///
  /// In en, this message translates to:
  /// **'Current Stock *'**
  String get currentStockRequired;

  /// No description provided for @qtyLabel.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get qtyLabel;

  /// No description provided for @minStockAlert.
  ///
  /// In en, this message translates to:
  /// **'Min Stock Alert'**
  String get minStockAlert;

  /// No description provided for @lowAlertHint.
  ///
  /// In en, this message translates to:
  /// **'Low alert'**
  String get lowAlertHint;

  /// No description provided for @quickSetPrefix.
  ///
  /// In en, this message translates to:
  /// **'Quick Set: '**
  String get quickSetPrefix;

  /// No description provided for @pricingSection.
  ///
  /// In en, this message translates to:
  /// **'Pricing'**
  String get pricingSection;

  /// No description provided for @briefDescription.
  ///
  /// In en, this message translates to:
  /// **'Brief product description'**
  String get briefDescription;

  /// No description provided for @productNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Product Name *'**
  String get productNameRequired;

  /// No description provided for @scanOrEnterCode.
  ///
  /// In en, this message translates to:
  /// **'Scan or enter code'**
  String get scanOrEnterCode;

  /// No description provided for @lowStockCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Low Stock'**
  String lowStockCount(int count);

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String itemsCount(int count);

  /// No description provided for @quantityUnit.
  ///
  /// In en, this message translates to:
  /// **'Quantity ({unit})'**
  String quantityUnit(String unit);

  /// No description provided for @currentInfo.
  ///
  /// In en, this message translates to:
  /// **'Current: {stock} {unit}'**
  String currentInfo(int stock, String unit);

  /// No description provided for @fromName.
  ///
  /// In en, this message translates to:
  /// **'from {name}'**
  String fromName(String name);

  /// No description provided for @toName.
  ///
  /// In en, this message translates to:
  /// **'to {name}'**
  String toName(String name);

  /// No description provided for @currentBalanceAmount.
  ///
  /// In en, this message translates to:
  /// **'Current balance: ₹{amount}'**
  String currentBalanceAmount(String amount);

  /// No description provided for @clearBillTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear Bill?'**
  String get clearBillTitle;

  /// No description provided for @clearBillMessage.
  ///
  /// In en, this message translates to:
  /// **'This will remove all items from the current bill.'**
  String get clearBillMessage;

  /// No description provided for @noItemsFound.
  ///
  /// In en, this message translates to:
  /// **'No items found'**
  String get noItemsFound;

  /// No description provided for @billCreated.
  ///
  /// In en, this message translates to:
  /// **'Bill Created!'**
  String get billCreated;

  /// No description provided for @createBill.
  ///
  /// In en, this message translates to:
  /// **'Create Bill'**
  String get createBill;

  /// No description provided for @pleaseSelectCustomerFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select a customer first'**
  String get pleaseSelectCustomerFirst;

  /// No description provided for @pleaseAddItemsToBill.
  ///
  /// In en, this message translates to:
  /// **'Please add items to the bill'**
  String get pleaseAddItemsToBill;

  /// No description provided for @errorGeneratingBill.
  ///
  /// In en, this message translates to:
  /// **'Error generating bill: {error}'**
  String errorGeneratingBill(String error);

  /// No description provided for @cartWithCount.
  ///
  /// In en, this message translates to:
  /// **'Cart ({count} items)'**
  String cartWithCount(int count);

  /// No description provided for @yourCartIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get yourCartIsEmpty;

  /// No description provided for @addNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Add notes (optional)'**
  String get addNotesOptional;

  /// No description provided for @advShort.
  ///
  /// In en, this message translates to:
  /// **'Adv'**
  String get advShort;

  /// No description provided for @reportTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Report Type'**
  String get reportTypeLabel;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @customLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get customLabel;

  /// No description provided for @fromLabel.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get fromLabel;

  /// No description provided for @toLabel.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get toLabel;

  /// No description provided for @todaysSummaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Summary'**
  String get todaysSummaryLabel;

  /// No description provided for @topCustomersLabel.
  ///
  /// In en, this message translates to:
  /// **'Top Customers'**
  String get topCustomersLabel;

  /// No description provided for @pendingDues.
  ///
  /// In en, this message translates to:
  /// **'Pending Dues'**
  String get pendingDues;

  /// No description provided for @activeDebtors.
  ///
  /// In en, this message translates to:
  /// **'Active Debtors'**
  String get activeDebtors;

  /// No description provided for @noTransactionsReportHint.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet. Generate your first report after adding transactions.'**
  String get noTransactionsReportHint;

  /// No description provided for @reportGeneratedTitle.
  ///
  /// In en, this message translates to:
  /// **'Report Generated!'**
  String get reportGeneratedTitle;

  /// No description provided for @upiDetails.
  ///
  /// In en, this message translates to:
  /// **'UPI Details'**
  String get upiDetails;

  /// No description provided for @upiIdLabel.
  ///
  /// In en, this message translates to:
  /// **'UPI ID *'**
  String get upiIdLabel;

  /// No description provided for @upiIdPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'yourname@upi'**
  String get upiIdPlaceholder;

  /// No description provided for @upiIdRequired.
  ///
  /// In en, this message translates to:
  /// **'UPI ID is required'**
  String get upiIdRequired;

  /// No description provided for @upiIdInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid UPI ID (e.g. name@bank)'**
  String get upiIdInvalid;

  /// No description provided for @shopNameStar.
  ///
  /// In en, this message translates to:
  /// **'Shop Name *'**
  String get shopNameStar;

  /// No description provided for @upiShopNameHint.
  ///
  /// In en, this message translates to:
  /// **'Name shown on UPI payment'**
  String get upiShopNameHint;

  /// No description provided for @merchantCodeOptional.
  ///
  /// In en, this message translates to:
  /// **'Merchant Code (Optional)'**
  String get merchantCodeOptional;

  /// No description provided for @merchantCodeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 5411 for Grocery Stores'**
  String get merchantCodeHint;

  /// No description provided for @qrCodeImage.
  ///
  /// In en, this message translates to:
  /// **'QR Code Image'**
  String get qrCodeImage;

  /// No description provided for @qrUploadDescription.
  ///
  /// In en, this message translates to:
  /// **'Upload an existing QR code image or use the auto-generated one from your UPI ID.'**
  String get qrUploadDescription;

  /// No description provided for @unableToLoadQrImage.
  ///
  /// In en, this message translates to:
  /// **'Unable to load QR image'**
  String get unableToLoadQrImage;

  /// No description provided for @tapToUploadQrImage.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload QR image'**
  String get tapToUploadQrImage;

  /// No description provided for @imageFormatHint.
  ///
  /// In en, this message translates to:
  /// **'PNG, JPG up to 1MB'**
  String get imageFormatHint;

  /// No description provided for @upiUriPreview.
  ///
  /// In en, this message translates to:
  /// **'UPI URI Preview'**
  String get upiUriPreview;

  /// No description provided for @updateUpiDetails.
  ///
  /// In en, this message translates to:
  /// **'Update UPI Details'**
  String get updateUpiDetails;

  /// No description provided for @saveUpiDetails.
  ///
  /// In en, this message translates to:
  /// **'Save UPI Details'**
  String get saveUpiDetails;

  /// No description provided for @qrImageUpdated.
  ///
  /// In en, this message translates to:
  /// **'QR image updated'**
  String get qrImageUpdated;

  /// No description provided for @saveUpiFirst.
  ///
  /// In en, this message translates to:
  /// **'Save UPI details first, then upload QR image'**
  String get saveUpiFirst;

  /// No description provided for @failedToPickImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick image: {error}'**
  String failedToPickImage(String error);

  /// No description provided for @upiIdCopied.
  ///
  /// In en, this message translates to:
  /// **'UPI ID copied: {upiId}'**
  String upiIdCopied(String upiId);

  /// No description provided for @failedToShare.
  ///
  /// In en, this message translates to:
  /// **'Failed to share: {error}'**
  String failedToShare(String error);

  /// No description provided for @setupUpiInSettings.
  ///
  /// In en, this message translates to:
  /// **'Set up your UPI details in Settings first.'**
  String get setupUpiInSettings;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @paymentFromName.
  ///
  /// In en, this message translates to:
  /// **'Payment from {name}'**
  String paymentFromName(String name);

  /// No description provided for @normalBrightness.
  ///
  /// In en, this message translates to:
  /// **'Normal Brightness'**
  String get normalBrightness;

  /// No description provided for @maxBrightness.
  ///
  /// In en, this message translates to:
  /// **'Max Brightness'**
  String get maxBrightness;

  /// No description provided for @copyUpiId.
  ///
  /// In en, this message translates to:
  /// **'Copy UPI ID'**
  String get copyUpiId;

  /// No description provided for @normalLabel.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normalLabel;

  /// No description provided for @brightenLabel.
  ///
  /// In en, this message translates to:
  /// **'Brighten'**
  String get brightenLabel;

  /// No description provided for @paymentRecordedLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Recorded!'**
  String get paymentRecordedLabel;

  /// No description provided for @paymentReceivedDash.
  ///
  /// In en, this message translates to:
  /// **'Payment Received — ₹{amount}'**
  String paymentReceivedDash(String amount);

  /// No description provided for @amountFromCustomer.
  ///
  /// In en, this message translates to:
  /// **'₹{amount} from {name}'**
  String amountFromCustomer(String amount, String name);

  /// No description provided for @balanceUpdatedAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Balance updated automatically'**
  String get balanceUpdatedAutomatically;

  /// No description provided for @scanWithAnyUpiApp.
  ///
  /// In en, this message translates to:
  /// **'Scan with any UPI app'**
  String get scanWithAnyUpiApp;

  /// No description provided for @amountLabelValue.
  ///
  /// In en, this message translates to:
  /// **'Amount: ₹{amount}'**
  String amountLabelValue(String amount);

  /// No description provided for @toCollect.
  ///
  /// In en, this message translates to:
  /// **'To Collect'**
  String get toCollect;

  /// No description provided for @lowRisk.
  ///
  /// In en, this message translates to:
  /// **'Low Risk'**
  String get lowRisk;

  /// No description provided for @mediumRisk.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get mediumRisk;

  /// No description provided for @highRisk.
  ///
  /// In en, this message translates to:
  /// **'High Risk'**
  String get highRisk;

  /// No description provided for @daysAgoLong.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String daysAgoLong(int days);

  /// No description provided for @weeksAgoLong.
  ///
  /// In en, this message translates to:
  /// **'{weeks} weeks ago'**
  String weeksAgoLong(int weeks);

  /// No description provided for @monthsAgoLong.
  ///
  /// In en, this message translates to:
  /// **'{months} months ago'**
  String monthsAgoLong(int months);

  /// No description provided for @moreItemsCount.
  ///
  /// In en, this message translates to:
  /// **'+ {count} more items'**
  String moreItemsCount(int count);

  /// No description provided for @totalItemsLabel.
  ///
  /// In en, this message translates to:
  /// **'Total: {count} items'**
  String totalItemsLabel(int count);

  /// No description provided for @paidStatus.
  ///
  /// In en, this message translates to:
  /// **'PAID'**
  String get paidStatus;

  /// No description provided for @pendingStatus.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get pendingStatus;

  /// No description provided for @todayWithTime.
  ///
  /// In en, this message translates to:
  /// **'Today, {time}'**
  String todayWithTime(String time);

  /// No description provided for @yesterdayWithTime.
  ///
  /// In en, this message translates to:
  /// **'Yesterday, {time}'**
  String yesterdayWithTime(String time);

  /// No description provided for @rate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get rate;

  /// No description provided for @itemsHeader.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get itemsHeader;

  /// No description provided for @markAsPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as Paid'**
  String get markAsPaid;

  /// No description provided for @billIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Bill #{id}'**
  String billIdLabel(String id);

  /// No description provided for @lowLabel.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get lowLabel;

  /// No description provided for @stockPcsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} pcs'**
  String stockPcsCount(int count);

  /// No description provided for @pdfUnknownCustomer.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get pdfUnknownCustomer;

  /// No description provided for @pdfShareSubject.
  ///
  /// In en, this message translates to:
  /// **'KhataSetu Report - {fileName}'**
  String pdfShareSubject(String fileName);

  /// No description provided for @validatorDefaultFieldName.
  ///
  /// In en, this message translates to:
  /// **'This field'**
  String get validatorDefaultFieldName;

  /// No description provided for @biometricAuthReason.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to access KhataSetu'**
  String get biometricAuthReason;

  /// No description provided for @biometricEnableReason.
  ///
  /// In en, this message translates to:
  /// **'Verify your identity to enable biometric lock'**
  String get biometricEnableReason;

  /// No description provided for @biometricNoHardware.
  ///
  /// In en, this message translates to:
  /// **'This device does not support biometric authentication'**
  String get biometricNoHardware;

  /// No description provided for @biometricNotEnrolled.
  ///
  /// In en, this message translates to:
  /// **'No fingerprints enrolled. Please set up biometrics in device settings'**
  String get biometricNotEnrolled;

  /// No description provided for @biometricLockedOut.
  ///
  /// In en, this message translates to:
  /// **'Too many failed attempts. Try again later'**
  String get biometricLockedOut;

  /// No description provided for @biometricPermanentlyLocked.
  ///
  /// In en, this message translates to:
  /// **'Biometric locked. Use your device PIN to unlock'**
  String get biometricPermanentlyLocked;

  /// No description provided for @biometricFailed.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication failed'**
  String get biometricFailed;

  /// No description provided for @biometricCancelled.
  ///
  /// In en, this message translates to:
  /// **'Authentication cancelled'**
  String get biometricCancelled;

  /// No description provided for @biometricUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Biometric not available on this device'**
  String get biometricUnavailable;

  /// No description provided for @biometricLoginLabel.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint'**
  String get biometricLoginLabel;

  /// No description provided for @biometricVerifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying...'**
  String get biometricVerifying;

  /// No description provided for @productUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Product updated successfully'**
  String get productUpdatedSuccess;

  /// No description provided for @updateProduct.
  ///
  /// In en, this message translates to:
  /// **'Update Product'**
  String get updateProduct;

  /// No description provided for @updateCustomer.
  ///
  /// In en, this message translates to:
  /// **'Update Customer'**
  String get updateCustomer;

  /// No description provided for @billRecordedToLedger.
  ///
  /// In en, this message translates to:
  /// **'Bill of {amount} recorded to ledger'**
  String billRecordedToLedger(String amount);

  /// No description provided for @syncStarted.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncStarted;

  /// No description provided for @exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Data exported successfully'**
  String get exportSuccess;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed. Please try again'**
  String get exportFailed;

  /// No description provided for @exportingData.
  ///
  /// In en, this message translates to:
  /// **'Exporting data...'**
  String get exportingData;

  /// No description provided for @notificationsSaved.
  ///
  /// In en, this message translates to:
  /// **'Notification preference saved'**
  String get notificationsSaved;

  /// No description provided for @notificationsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Push notifications coming soon'**
  String get notificationsComingSoon;

  /// No description provided for @featureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'{feature} coming soon'**
  String featureComingSoon(String feature);

  /// No description provided for @statementShared.
  ///
  /// In en, this message translates to:
  /// **'Statement shared'**
  String get statementShared;

  /// No description provided for @shopManagementComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Shop management coming soon'**
  String get shopManagementComingSoon;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotifications;

  /// No description provided for @noDailyNotes.
  ///
  /// In en, this message translates to:
  /// **'No daily notes yet'**
  String get noDailyNotes;

  /// No description provided for @noDailyNotesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add your first daily note'**
  String get noDailyNotesSubtitle;

  /// No description provided for @newDailyNote.
  ///
  /// In en, this message translates to:
  /// **'New Note'**
  String get newDailyNote;

  /// No description provided for @allCustomers.
  ///
  /// In en, this message translates to:
  /// **'All Customers'**
  String get allCustomers;

  /// No description provided for @morningLabel.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get morningLabel;

  /// No description provided for @afternoonLabel.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get afternoonLabel;

  /// No description provided for @eveningLabel.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get eveningLabel;

  /// No description provided for @repeatYesterday.
  ///
  /// In en, this message translates to:
  /// **'Repeat Yesterday\'s Items'**
  String get repeatYesterday;

  /// No description provided for @addNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'Add a note (optional)'**
  String get addNoteOptional;

  /// No description provided for @saveToLedger.
  ///
  /// In en, this message translates to:
  /// **'Save to Ledger'**
  String get saveToLedger;

  /// No description provided for @saveDailyNote.
  ///
  /// In en, this message translates to:
  /// **'Save Daily Note'**
  String get saveDailyNote;

  /// No description provided for @noteSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Daily note saved'**
  String get noteSavedSuccess;

  /// No description provided for @noteSavedWithLedger.
  ///
  /// In en, this message translates to:
  /// **'Note saved & added to ledger'**
  String get noteSavedWithLedger;

  /// No description provided for @syncedToLedger.
  ///
  /// In en, this message translates to:
  /// **'Synced to ledger'**
  String get syncedToLedger;

  /// No description provided for @deleteNote.
  ///
  /// In en, this message translates to:
  /// **'Delete Note'**
  String get deleteNote;

  /// No description provided for @deleteNoteConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete this daily note. Are you sure?'**
  String get deleteNoteConfirm;

  /// No description provided for @frequentItems.
  ///
  /// In en, this message translates to:
  /// **'Frequent Items'**
  String get frequentItems;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'items'**
  String get items;

  /// No description provided for @noProductsAddedYet.
  ///
  /// In en, this message translates to:
  /// **'No products added yet'**
  String get noProductsAddedYet;

  /// No description provided for @addFirstProductHint.
  ///
  /// In en, this message translates to:
  /// **'Add your first product to start tracking inventory'**
  String get addFirstProductHint;

  /// No description provided for @selectTransactionType.
  ///
  /// In en, this message translates to:
  /// **'Select Transaction Type'**
  String get selectTransactionType;

  /// No description provided for @customerTakesGoodsOnCredit.
  ///
  /// In en, this message translates to:
  /// **'Customer takes goods on credit'**
  String get customerTakesGoodsOnCredit;

  /// No description provided for @addPayment.
  ///
  /// In en, this message translates to:
  /// **'Add Payment'**
  String get addPayment;

  /// No description provided for @customerPaysMoney.
  ///
  /// In en, this message translates to:
  /// **'Customer pays money'**
  String get customerPaysMoney;

  /// No description provided for @markAllAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllAsRead;

  /// No description provided for @noNotificationsDescription.
  ///
  /// In en, this message translates to:
  /// **'You\'ll see alerts for low stock, pending payments, and more here'**
  String get noNotificationsDescription;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'gu', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SEn();
    case 'gu':
      return SGu();
    case 'hi':
      return SHi();
  }

  throw FlutterError(
    'S.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
