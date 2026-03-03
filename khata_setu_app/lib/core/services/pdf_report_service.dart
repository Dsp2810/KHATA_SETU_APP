import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/generated/app_localizations.dart';

/// Report types supported by the PDF generator
enum ReportType {
  daily,
  weekly,
  monthly,
  yearly,
  custom,
  customerStatement,
}

/// Transaction data model for reports
class ReportTransaction {
  final String id;
  final String customerName;
  final String type; // 'credit' or 'payment' (legacy: 'debit')
  final double amount;
  final DateTime date;
  final String description;
  final List<ReportItem> items;

  ReportTransaction({
    required this.id,
    required this.customerName,
    required this.type,
    required this.amount,
    required this.date,
    required this.description,
    this.items = const [],
  });
}

/// Item in a transaction
class ReportItem {
  final String name;
  final int quantity;
  final double price;
  final String unit;

  ReportItem({
    required this.name,
    required this.quantity,
    required this.price,
    this.unit = 'pcs',
  });

  double get total => quantity * price;
}

/// Summary data for reports
class ReportSummary {
  final double totalCredit;
  final double totalDebit;
  final double netBalance;
  final int transactionCount;
  final int customerCount;
  final Map<String, double> categoryBreakdown;

  ReportSummary({
    required this.totalCredit,
    required this.totalDebit,
    required this.netBalance,
    required this.transactionCount,
    required this.customerCount,
    this.categoryBreakdown = const {},
  });
}

/// Bundle of fonts for PDF generation
class _PdfFontBundle {
  final pw.Font regular;
  final pw.Font bold;
  final pw.Font semiBold;

  _PdfFontBundle({
    required this.regular,
    required this.bold,
    required this.semiBold,
  });
}

/// PDF Report Generation Service
class PdfReportService {
  static const String _currencySymbol = '₹';
  static final _dateFormat = DateFormat('dd MMM yyyy');
  static final _timeFormat = DateFormat('hh:mm a');
  static final _monthFormat = DateFormat('MMMM yyyy');

  // Brand colors
  static const PdfColor _primaryColor = PdfColor.fromInt(0xFF1E88E5);
  static const PdfColor _successColor = PdfColor.fromInt(0xFF4CAF50);
  static const PdfColor _errorColor = PdfColor.fromInt(0xFFE53935);
  static const PdfColor _greyColor = PdfColor.fromInt(0xFF757575);
  static const PdfColor _lightGrey = PdfColor.fromInt(0xFFF5F5F5);

  /// Load appropriate fonts based on locale
  /// - Gujarati: Noto Sans Gujarati
  /// - Hindi: Noto Sans Devanagari
  /// - English/Other: Nunito
  static Future<_PdfFontBundle> _loadFontsForLocale(String locale) async {
    switch (locale) {
      case 'gu':
        // Gujarati script support
        return _PdfFontBundle(
          regular: await PdfGoogleFonts.notoSansGujaratiRegular(),
          bold: await PdfGoogleFonts.notoSansGujaratiBold(),
          semiBold: await PdfGoogleFonts.notoSansGujaratiSemiBold(),
        );
      case 'hi':
        // Devanagari script support (Hindi)
        return _PdfFontBundle(
          regular: await PdfGoogleFonts.notoSansDevanagariRegular(),
          bold: await PdfGoogleFonts.notoSansDevanagariBold(),
          semiBold: await PdfGoogleFonts.notoSansDevanagariSemiBold(),
        );
      default:
        // Latin script (English)
        return _PdfFontBundle(
          regular: await PdfGoogleFonts.nunitoRegular(),
          bold: await PdfGoogleFonts.nunitoBold(),
          semiBold: await PdfGoogleFonts.nunitoSemiBold(),
        );
    }
  }

  /// Generate a report PDF
  static Future<Uint8List> generateReport({
    required ReportType type,
    required String shopName,
    required DateTime startDate,
    required DateTime endDate,
    required List<ReportTransaction> transactions,
    required ReportSummary summary,
    required S l10n,
    String? customerName,
    String locale = 'en',
  }) async {
    final pdf = pw.Document();
    
    // Load fonts based on locale for proper script rendering
    final fonts = await _loadFontsForLocale(locale);
    final font = fonts.regular;
    final fontBold = fonts.bold;
    final fontSemiBold = fonts.semiBold;

    // Styles
    final titleStyle = pw.TextStyle(font: fontBold, fontSize: 24, color: _primaryColor);
    final headerStyle = pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.white);
    // ignore: unused_local_variable
    final subHeaderStyle = pw.TextStyle(font: fontSemiBold, fontSize: 12, color: _primaryColor);
    final bodyStyle = pw.TextStyle(font: font, fontSize: 10);
    final smallStyle = pw.TextStyle(font: font, fontSize: 8, color: _greyColor);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(
          shopName: shopName,
          reportType: type,
          startDate: startDate,
          endDate: endDate,
          customerName: customerName,
          titleStyle: titleStyle,
          smallStyle: smallStyle,
          fontBold: fontBold,
          l10n: l10n,
        ),
        footer: (context) => _buildFooter(context, smallStyle, l10n),
        build: (context) => [
          // Summary Section
          _buildSummarySection(summary, fontBold, fontSemiBold, font, l10n),
          pw.SizedBox(height: 20),

          // Transactions Table
          _buildTransactionsTable(
            transactions: transactions,
            headerStyle: headerStyle,
            bodyStyle: bodyStyle,
            fontBold: fontBold,
            l10n: l10n,
          ),

          // Category Breakdown (if available)
          if (summary.categoryBreakdown.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            _buildCategoryBreakdown(summary.categoryBreakdown, fontBold, font, l10n),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  /// Generate a daily bill/invoice
  static Future<Uint8List> generateBill({
    required String shopName,
    required String shopAddress,
    required String shopPhone,
    required String customerName,
    required String customerPhone,
    required String billNumber,
    required DateTime date,
    required List<ReportItem> items,
    required S l10n,
    double discount = 0,
    double previousBalance = 0,
    String? notes,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();
    final fontSemiBold = await PdfGoogleFonts.nunitoSemiBold();

    final subtotal = items.fold<double>(0, (sum, item) => sum + item.total);
    final grandTotal = subtotal - discount + previousBalance;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header with shop details
            _buildBillHeader(
              shopName: shopName,
              shopAddress: shopAddress,
              shopPhone: shopPhone,
              billNumber: billNumber,
              date: date,
              fontBold: fontBold,
              font: font,
              l10n: l10n,
            ),
            pw.SizedBox(height: 20),

            // Customer details
            _buildCustomerSection(
              customerName: customerName,
              customerPhone: customerPhone,
              fontBold: fontBold,
              font: font,
              l10n: l10n,
            ),
            pw.SizedBox(height: 20),

            // Items table
            _buildItemsTable(items, fontBold, font, l10n),
            pw.SizedBox(height: 10),

            // Totals
            _buildTotalsSection(
              subtotal: subtotal,
              discount: discount,
              previousBalance: previousBalance,
              grandTotal: grandTotal,
              fontBold: fontBold,
              font: font,
              l10n: l10n,
            ),

            // Notes
            if (notes != null && notes.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: _lightGrey,
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('${l10n.pdfNotes}:', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                    pw.SizedBox(height: 5),
                    pw.Text(notes, style: pw.TextStyle(font: font, fontSize: 9)),
                  ],
                ),
              ),
            ],

            pw.Spacer(),

            // Footer
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    l10n.pdfThankYou,
                    style: pw.TextStyle(font: fontSemiBold, fontSize: 12, color: _primaryColor),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    l10n.generatedByApp,
                    style: pw.TextStyle(font: font, fontSize: 8, color: _greyColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  /// Generate customer statement
  static Future<Uint8List> generateCustomerStatement({
    required String shopName,
    required String customerName,
    required String customerPhone,
    required DateTime startDate,
    required DateTime endDate,
    required List<ReportTransaction> transactions,
    required double openingBalance,
    required double closingBalance,
    required S l10n,
    String locale = 'en',
  }) async {
    final pdf = pw.Document();
    
    // Load fonts based on locale for proper script rendering
    final fonts = await _loadFontsForLocale(locale);
    final font = fonts.regular;
    final fontBold = fonts.bold;
    final fontSemiBold = fonts.semiBold;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(shopName, style: pw.TextStyle(font: fontBold, fontSize: 20, color: _primaryColor)),
                    pw.SizedBox(height: 5),
                    pw.Text(l10n.customerStatement, style: pw.TextStyle(font: fontSemiBold, fontSize: 14)),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: _primaryColor),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(l10n.pdfPeriod, style: pw.TextStyle(font: font, fontSize: 8, color: _greyColor)),
                      pw.Text(
                        '${_dateFormat.format(startDate)} - ${_dateFormat.format(endDate)}',
                        style: pw.TextStyle(font: fontSemiBold, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 15),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: _lightGrey,
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(l10n.pdfCustomer, style: pw.TextStyle(font: font, fontSize: 8, color: _greyColor)),
                      pw.Text(customerName, style: pw.TextStyle(font: fontBold, fontSize: 12)),
                      pw.Text(customerPhone, style: pw.TextStyle(font: font, fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(l10n.pdfOpeningBalance, style: pw.TextStyle(font: font, fontSize: 8, color: _greyColor)),
                      pw.Text(
                        '$_currencySymbol${openingBalance.toStringAsFixed(2)}',
                        style: pw.TextStyle(font: fontBold, fontSize: 12, color: openingBalance > 0 ? _errorColor : _successColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 15),
            pw.Divider(color: _greyColor),
          ],
        ),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(color: _greyColor),
            pw.SizedBox(height: 5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  l10n.pdfGeneratedBy(_dateFormat.format(DateTime.now()), ''),
                  style: pw.TextStyle(font: font, fontSize: 8, color: _greyColor),
                ),
                pw.Text(
                  l10n.pdfPage(context.pageNumber, context.pagesCount),
                  style: pw.TextStyle(font: font, fontSize: 8, color: _greyColor),
                ),
              ],
            ),
          ],
        ),
        build: (context) => [
          // Transaction ledger
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: _primaryColor),
            cellStyle: pw.TextStyle(font: font, fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
            headerAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.all(6),
            headers: [l10n.pdfDate, l10n.pdfDescription, l10n.pdfCredit, l10n.pdfPayment, l10n.pdfBalance],
            data: _buildStatementData(transactions, openingBalance),
          ),
          pw.SizedBox(height: 20),

          // Closing balance
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: closingBalance > 0 ? PdfColor.fromInt(0xFFFFEBEE) : PdfColor.fromInt(0xFFE8F5E9),
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(
                color: closingBalance > 0 ? _errorColor : _successColor,
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  l10n.pdfClosingBalance,
                  style: pw.TextStyle(font: fontBold, fontSize: 14),
                ),
                pw.Text(
                  '$_currencySymbol${closingBalance.abs().toStringAsFixed(2)} ${closingBalance > 0 ? l10n.pdfDue : l10n.pdfAdvance}',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 16,
                    color: closingBalance > 0 ? _errorColor : _successColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // Helper methods for building PDF components
  static pw.Widget _buildHeader({
    required String shopName,
    required ReportType reportType,
    required DateTime startDate,
    required DateTime endDate,
    String? customerName,
    required pw.TextStyle titleStyle,
    required pw.TextStyle smallStyle,
    required pw.Font fontBold,
    required S l10n,
  }) {
    String reportTitle;
    switch (reportType) {
      case ReportType.daily:
        reportTitle = l10n.pdfDailyReport(_dateFormat.format(startDate));
        break;
      case ReportType.weekly:
        reportTitle = l10n.pdfWeeklyReport;
        break;
      case ReportType.monthly:
        reportTitle = l10n.pdfMonthlyReport(_monthFormat.format(startDate));
        break;
      case ReportType.yearly:
        reportTitle = l10n.pdfYearlyReport(startDate.year.toString());
        break;
      case ReportType.customerStatement:
        reportTitle = l10n.pdfCustomerStatement(customerName ?? l10n.pdfUnknownCustomer);
        break;
      case ReportType.custom:
        reportTitle = l10n.pdfCustomReport;
        break;
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(shopName, style: titleStyle),
                pw.SizedBox(height: 5),
                pw.Text(reportTitle, style: pw.TextStyle(font: fontBold, fontSize: 14)),
              ],
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: pw.BoxDecoration(
                color: _lightGrey,
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(l10n.pdfPeriod, style: smallStyle),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    '${_dateFormat.format(startDate)} - ${_dateFormat.format(endDate)}',
                    style: pw.TextStyle(font: fontBold, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 15),
        pw.Divider(color: _primaryColor, thickness: 2),
        pw.SizedBox(height: 15),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context context, pw.TextStyle smallStyle, S l10n) {
    return pw.Column(
      children: [
        pw.Divider(color: _greyColor),
        pw.SizedBox(height: 5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              l10n.pdfGeneratedBy(_dateFormat.format(DateTime.now()), _timeFormat.format(DateTime.now())),
              style: smallStyle,
            ),
            pw.Text(
              l10n.pdfPage(context.pageNumber, context.pagesCount),
              style: smallStyle,
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildSummarySection(
    ReportSummary summary,
    pw.Font fontBold,
    pw.Font fontSemiBold,
    pw.Font font,
    S l10n,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: _lightGrey,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(l10n.pdfTotalCredit, summary.totalCredit, _successColor, fontBold, font),
          _buildSummaryItem(l10n.pdfTotalDebit, summary.totalDebit, _errorColor, fontBold, font),
          _buildSummaryItem(l10n.pdfNetBalance, summary.netBalance, _primaryColor, fontBold, font),
          _buildSummaryItem(l10n.pdfTransactions, summary.transactionCount.toDouble(), _greyColor, fontBold, font, isCount: true),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryItem(
    String label,
    double value,
    PdfColor color,
    pw.Font fontBold,
    pw.Font font, {
    bool isCount = false,
  }) {
    return pw.Column(
      children: [
        pw.Text(label, style: pw.TextStyle(font: font, fontSize: 9, color: _greyColor)),
        pw.SizedBox(height: 5),
        pw.Text(
          isCount ? value.toInt().toString() : '$_currencySymbol${value.toStringAsFixed(2)}',
          style: pw.TextStyle(font: fontBold, fontSize: 14, color: color),
        ),
      ],
    );
  }

  static pw.Widget _buildTransactionsTable({
    required List<ReportTransaction> transactions,
    required pw.TextStyle headerStyle,
    required pw.TextStyle bodyStyle,
    required pw.Font fontBold,
    required S l10n,
  }) {
    return pw.TableHelper.fromTextArray(
      headerStyle: headerStyle,
      headerDecoration: const pw.BoxDecoration(color: _primaryColor),
      cellStyle: bodyStyle,
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(6),
      headers: [l10n.pdfDate, l10n.pdfCustomer, l10n.pdfDescription, l10n.pdfType, l10n.pdfAmount],
      data: transactions.map((t) => [
        _dateFormat.format(t.date),
        t.customerName,
        t.description.length > 30 ? '${t.description.substring(0, 27)}...' : t.description,
        t.type.toUpperCase(),
        '$_currencySymbol${t.amount.toStringAsFixed(2)}',
      ]).toList(),
      cellDecoration: (index, data, rowNum) {
        if (rowNum == 0) return const pw.BoxDecoration();
        return pw.BoxDecoration(
          color: rowNum.isEven ? _lightGrey : PdfColors.white,
        );
      },
    );
  }

  static pw.Widget _buildCategoryBreakdown(
    Map<String, double> categories,
    pw.Font fontBold,
    pw.Font font,
    S l10n,
  ) {
    final sortedCategories = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(l10n.pdfCategoryBreakdown, style: pw.TextStyle(font: fontBold, fontSize: 12)),
        pw.SizedBox(height: 10),
        ...sortedCategories.map((entry) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(entry.key, style: pw.TextStyle(font: font, fontSize: 10)),
              pw.Text(
                '$_currencySymbol${entry.value.toStringAsFixed(2)}',
                style: pw.TextStyle(font: fontBold, fontSize: 10),
              ),
            ],
          ),
        )),
      ],
    );
  }

  static pw.Widget _buildBillHeader({
    required String shopName,
    required String shopAddress,
    required String shopPhone,
    required String billNumber,
    required DateTime date,
    required pw.Font fontBold,
    required pw.Font font,
    required S l10n,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(shopName, style: pw.TextStyle(font: fontBold, fontSize: 22, color: _primaryColor)),
            pw.SizedBox(height: 5),
            pw.Text(shopAddress, style: pw.TextStyle(font: font, fontSize: 10, color: _greyColor)),
            pw.Text('${l10n.pdfPhoneLabel}: $shopPhone', style: pw.TextStyle(font: font, fontSize: 10, color: _greyColor)),
          ],
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _primaryColor, width: 2),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(l10n.invoiceTitle, style: pw.TextStyle(font: fontBold, fontSize: 16, color: _primaryColor)),
              pw.SizedBox(height: 5),
              pw.Text('${l10n.billNumber}: $billNumber', style: pw.TextStyle(font: font, fontSize: 10)),
              pw.Text('${l10n.pdfDate}: ${_dateFormat.format(date)}', style: pw.TextStyle(font: font, fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildCustomerSection({
    required String customerName,
    required String customerPhone,
    required pw.Font fontBold,
    required pw.Font font,
    required S l10n,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _lightGrey,
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Row(
        children: [
          pw.Text('${l10n.pdfBillTo}: ', style: pw.TextStyle(font: font, fontSize: 10, color: _greyColor)),
          pw.SizedBox(width: 10),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(customerName, style: pw.TextStyle(font: fontBold, fontSize: 12)),
              pw.Text(customerPhone, style: pw.TextStyle(font: font, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildItemsTable(List<ReportItem> items, pw.Font fontBold, pw.Font font, S l10n) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: _primaryColor),
      cellStyle: pw.TextStyle(font: font, fontSize: 10),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(8),
      headers: [l10n.pdfItem, l10n.pdfItemName, l10n.pdfQty, l10n.pdfUnit, l10n.pdfPrice, l10n.pdfTotal],
      data: items.asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;
        return [
          (i + 1).toString(),
          item.name,
          item.quantity.toString(),
          item.unit,
          '$_currencySymbol${item.price.toStringAsFixed(2)}',
          '$_currencySymbol${item.total.toStringAsFixed(2)}',
        ];
      }).toList(),
      cellDecoration: (index, data, rowNum) {
        if (rowNum == 0) return const pw.BoxDecoration();
        return pw.BoxDecoration(
          color: rowNum.isEven ? _lightGrey : PdfColors.white,
        );
      },
    );
  }

  static pw.Widget _buildTotalsSection({
    required double subtotal,
    required double discount,
    required double previousBalance,
    required double grandTotal,
    required pw.Font fontBold,
    required pw.Font font,
    required S l10n,
  }) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 200,
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _greyColor),
          borderRadius: pw.BorderRadius.circular(5),
        ),
        child: pw.Column(
          children: [
            _buildTotalRow(l10n.pdfSubtotal, subtotal, font, fontBold),
            if (discount > 0) _buildTotalRow(l10n.pdfDiscount, -discount, font, fontBold, color: _successColor),
            if (previousBalance != 0)
              _buildTotalRow(
                l10n.pdfPreviousBalance,
                previousBalance,
                font,
                fontBold,
                color: previousBalance > 0 ? _errorColor : _successColor,
              ),
            pw.Divider(color: _greyColor),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(l10n.pdfGrandTotal, style: pw.TextStyle(font: fontBold, fontSize: 12)),
                pw.Text(
                  '$_currencySymbol${grandTotal.toStringAsFixed(2)}',
                  style: pw.TextStyle(font: fontBold, fontSize: 14, color: _primaryColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildTotalRow(String label, double value, pw.Font font, pw.Font fontBold, {PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(font: font, fontSize: 10)),
          pw.Text(
            '${value < 0 ? '-' : ''}$_currencySymbol${value.abs().toStringAsFixed(2)}',
            style: pw.TextStyle(font: fontBold, fontSize: 10, color: color),
          ),
        ],
      ),
    );
  }

  /// Build statement data rows from transactions.
  /// Handles both legacy 'debit' and new 'payment' type names.
  static List<List<String>> _buildStatementData(List<ReportTransaction> transactions, double openingBalance) {
    final data = <List<String>>[];
    double runningBalance = openingBalance;

    for (final t in transactions) {
      if (t.type == 'credit') {
        // Credit sale: customer takes goods, balance increases
        runningBalance += t.amount;
        data.add([
          _dateFormat.format(t.date),
          t.description,
          '$_currencySymbol${t.amount.toStringAsFixed(2)}', // Credit column
          '-',
          '$_currencySymbol${runningBalance.toStringAsFixed(2)}',
        ]);
      } else {
        // Payment: customer pays, balance decreases (handles both 'debit' and 'payment')
        runningBalance -= t.amount;
        data.add([
          _dateFormat.format(t.date),
          t.description,
          '-',
          '$_currencySymbol${t.amount.toStringAsFixed(2)}', // Payment column
          '$_currencySymbol${runningBalance.toStringAsFixed(2)}',
        ]);
      }
    }

    return data;
  }

  // File operations
  static Future<File> saveToFile(Uint8List bytes, String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file;
  }

  static Future<void> shareReport(Uint8List bytes, String fileName, {required S l10n}) async {
    final file = await saveToFile(bytes, fileName);
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: l10n.pdfShareSubject(fileName),
    );
  }

  static Future<void> printReport(Uint8List bytes) async {
    await Printing.layoutPdf(onLayout: (_) => bytes);
  }
}
