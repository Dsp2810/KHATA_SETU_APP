import '../../l10n/generated/app_localizations.dart';

class Validators {
  Validators._();

  // Phone number regex for Indian phones (starts with 6-9, 10 digits)
  static final RegExp _phoneRegex = RegExp(r'^[6-9]\d{9}$');

  // Email regex
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  // Validate phone number
  static String? validatePhone(String? value, {required S l10n}) {
    if (value == null || value.isEmpty) {
      return l10n.phoneRequired;
    }
    final phone = value.replaceAll(RegExp(r'\s+'), ''); // Remove spaces
    if (!_phoneRegex.hasMatch(phone)) {
      return l10n.phoneInvalid;
    }
    return null;
  }

  // Validate password
  static String? validatePassword(String? value, {required S l10n}) {
    if (value == null || value.isEmpty) {
      return l10n.passwordRequired;
    }
    if (value.length < 8) {
      return l10n.passwordMinLength;
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return l10n.passwordUppercase;
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return l10n.passwordLowercase;
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return l10n.passwordNumber;
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return l10n.passwordSpecial;
    }
    return null;
  }

  // Validate simple password (for PIN)
  static String? validatePin(String? value, {int length = 4, required S l10n}) {
    if (value == null || value.isEmpty) {
      return l10n.pinRequired;
    }
    if (value.length != length) {
      return l10n.pinLength(length);
    }
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return l10n.pinDigitsOnly;
    }
    return null;
  }

  // Validate name
  static String? validateName(String? value, {required S l10n}) {
    if (value == null || value.trim().isEmpty) {
      return l10n.nameRequired;
    }
    if (value.trim().length < 2) {
      return l10n.nameMinLength;
    }
    if (value.trim().length > 100) {
      return l10n.nameMaxLength;
    }
    return null;
  }

  // Validate email (optional)
  static String? validateEmail(String? value, {required S l10n}) {
    if (value == null || value.isEmpty) {
      return null; // Email is optional
    }
    if (!_emailRegex.hasMatch(value)) {
      return l10n.emailInvalid;
    }
    return null;
  }

  // Validate amount
  static String? validateAmount(String? value, {double maxAmount = 10000000, required S l10n}) {
    if (value == null || value.isEmpty) {
      return l10n.amountRequired;
    }
    final amount = double.tryParse(value.replaceAll(',', ''));
    if (amount == null) {
      return l10n.amountInvalid;
    }
    if (amount <= 0) {
      return l10n.amountPositive;
    }
    if (amount > maxAmount) {
      return l10n.amountMaxExceeded('₹', maxAmount.toStringAsFixed(0));
    }
    return null;
  }

  // Validate required field
  static String? validateRequired(String? value, {String? fieldName, required S l10n}) {
    if (value == null || value.trim().isEmpty) {
      return l10n.fieldRequired(fieldName ?? l10n.validatorDefaultFieldName);
    }
    return null;
  }

  // Validate OTP
  static String? validateOtp(String? value, {int length = 6, required S l10n}) {
    if (value == null || value.isEmpty) {
      return l10n.otpRequired;
    }
    if (value.length != length) {
      return l10n.otpLength(length);
    }
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return l10n.otpDigitsOnly;
    }
    return null;
  }

  // Validate shop name
  static String? validateShopName(String? value, {required S l10n}) {
    if (value == null || value.trim().isEmpty) {
      return l10n.shopNameRequired;
    }
    if (value.trim().length < 2) {
      return l10n.shopNameMinLength;
    }
    if (value.trim().length > 150) {
      return l10n.shopNameMaxLength;
    }
    return null;
  }

  // Validate address
  static String? validateAddress(String? value, {required S l10n}) {
    if (value == null || value.trim().isEmpty) {
      return l10n.addressRequired;
    }
    if (value.trim().length < 10) {
      return l10n.addressMinLength;
    }
    if (value.trim().length > 500) {
      return l10n.addressMaxLength;
    }
    return null;
  }

  // Validate quantity
  static String? validateQuantity(String? value, {required S l10n}) {
    if (value == null || value.isEmpty) {
      return l10n.quantityRequired;
    }
    final quantity = int.tryParse(value);
    if (quantity == null) {
      return l10n.quantityInvalid;
    }
    if (quantity < 0) {
      return l10n.quantityNegative;
    }
    return null;
  }

  // Validate confirm password
  static String? validateConfirmPassword(String? value, String? password, {required S l10n}) {
    if (value == null || value.isEmpty) {
      return l10n.confirmPasswordRequired;
    }
    if (value != password) {
      return l10n.passwordsDoNotMatch;
    }
    return null;
  }
}
