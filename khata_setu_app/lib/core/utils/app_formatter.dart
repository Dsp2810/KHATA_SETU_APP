import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../l10n/generated/app_localizations.dart';

/// Convenience extension for accessing localizations
extension LocalizationX on BuildContext {
  /// Access the generated AppLocalizations (shorthand: `context.l10n`)
  S get l10n => S.of(this);
}

/// Locale-aware formatting utilities for currency, numbers, dates, and time
class AppFormatter {
  AppFormatter._();

  // ─── Currency ───

  /// Format amount as Indian currency: ₹12,34,567.00
  /// Uses Indian grouping pattern (lakhs/crores) regardless of locale.
  static String currency(double amount, {int decimalDigits = 2}) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: decimalDigits,
    );
    return formatter.format(amount);
  }

  /// Compact currency: ₹1.2L, ₹5.3Cr
  static String currencyCompact(double amount) {
    if (amount.abs() >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount.abs() >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount.abs() >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  /// Currency without decimals: ₹12,34,567
  static String currencyWhole(double amount) {
    return currency(amount, decimalDigits: 0);
  }

  // ─── Numbers ───

  /// Format number with locale grouping
  static String number(num value, {String locale = 'en_IN'}) {
    return NumberFormat('#,##,##0.##', locale).format(value);
  }

  /// Format integer with locale grouping
  static String integer(int value, {String locale = 'en_IN'}) {
    return NumberFormat('#,##,##0', locale).format(value);
  }

  /// Format percentage
  static String percent(double value, {int decimalDigits = 1}) {
    return '${value.toStringAsFixed(decimalDigits)}%';
  }

  // ─── Dates ───

  /// Format date as dd MMM yyyy (e.g., 15 Mar 2026)
  static String dateShort(DateTime date, {String? locale}) {
    return DateFormat('dd MMM yyyy', locale).format(date);
  }

  /// Format date as dd/MM/yyyy
  static String dateSlash(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Format date as full: Monday, 15 March 2026
  static String dateFull(DateTime date, {String? locale}) {
    return DateFormat('EEEE, dd MMMM yyyy', locale).format(date);
  }

  /// Format month-year: March 2026
  static String monthYear(DateTime date, {String? locale}) {
    return DateFormat('MMMM yyyy', locale).format(date);
  }

  /// Format day-month: 15 Mar
  static String dayMonth(DateTime date, {String? locale}) {
    return DateFormat('dd MMM', locale).format(date);
  }

  /// Format time: 02:30 PM
  static String time(DateTime date, {String? locale}) {
    return DateFormat('hh:mm a', locale).format(date);
  }

  /// Format date + time: 15 Mar 2026, 02:30 PM
  static String dateTime(DateTime date, {String? locale}) {
    return DateFormat('dd MMM yyyy, hh:mm a', locale).format(date);
  }

  // ─── Relative Time ───

  /// Relative time string using localized strings
  static String relativeTime(DateTime date, S l10n) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.isNegative) return l10n.tomorrow;
    if (diff.inSeconds < 60) return l10n.justNow;
    if (diff.inMinutes < 60) return l10n.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.hoursAgo(diff.inHours);

    // Check if yesterday
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return l10n.yesterday;
    }

    if (diff.inDays < 7) return l10n.daysAgo(diff.inDays);
    if (diff.inDays < 30) return l10n.weeksAgo(diff.inDays ~/ 7);

    return dateShort(date);
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
