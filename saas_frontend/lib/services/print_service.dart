import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show kIsWeb;
class PrintService {
  static Future<pw.Font> _getCairoRegular() async {
    return await PdfGoogleFonts.cairoRegular();
  }

  static Future<pw.Font> _getCairoBold() async {
    return await PdfGoogleFonts.cairoBold();
  }

  static Future<void> printReceipt({
    required bool isAr,
    required String title,
    required String customerName,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required double amountPaid,
    required String paymentMethod,
    required DateTime date,
  }) async {
    final font = await _getCairoRegular();
    final fontBold = await _getCairoBold();

    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(12),
        textDirection: isAr ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
        ),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              // Header
              pw.Text(
                isAr ? 'نظام الحجوزات الذكي' : 'Smart Booking System',
                style: pw.TextStyle(font: fontBold, fontSize: 16),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 4),
              pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Text(
                  title,
                  style: pw.TextStyle(fontSize: 14),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 8),

              // Date & Customer
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(isAr ? 'التاريخ:' : 'Date:', style: pw.TextStyle(font: fontBold)),
                  pw.Text(DateFormat('yyyy-MM-dd HH:mm').format(date)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(isAr ? 'العميل:' : 'Customer:', style: pw.TextStyle(font: fontBold)),
                  pw.Directionality(
                    textDirection: pw.TextDirection.rtl,
                    child: pw.Text(customerName),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 8),

              // Items
              ...items.map((item) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Directionality(
                          textDirection: pw.TextDirection.rtl,
                          child: pw.Text(
                            item['name'].toString(),
                            textAlign: isAr ? pw.TextAlign.right : pw.TextAlign.left,
                          ),
                        ),
                      ),
                      pw.Text('${item['price']} \$'),
                    ],
                  ),
                );
              }),

              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 8),

              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(isAr ? 'الإجمالي:' : 'Total:', style: pw.TextStyle(font: fontBold, fontSize: 14)),
                  pw.Text('${totalAmount.toStringAsFixed(2)} \$', style: pw.TextStyle(font: fontBold, fontSize: 14)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(isAr ? 'المدفوع:' : 'Paid:'),
                  pw.Text('${amountPaid.toStringAsFixed(2)} \$'),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(isAr ? 'المتبقي:' : 'Balance:'),
                  pw.Text('${(totalAmount - amountPaid).toStringAsFixed(2)} \$'),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(isAr ? 'طريقة الدفع:' : 'Method:'),
                  pw.Directionality(
                    textDirection: pw.TextDirection.rtl,
                    child: pw.Text(paymentMethod),
                  ),
                ],
              ),

              pw.SizedBox(height: 16),
              pw.Text(
                isAr ? 'شكراً لتعاملكم معنا' : 'Thank you for your business!',
                style: pw.TextStyle(font: fontBold),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 16),
            ],
          );
        },
      ),
    );

    final String fileName = 'Receipt_${DateFormat('yyyy_MM_dd_HH_mm').format(DateTime.now())}.pdf';
    
    if (kIsWeb) {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save(),
        name: fileName,
      );
    } else {
      await Printing.sharePdf(
        bytes: await doc.save(),
        filename: fileName,
      );
    }
  }

  static Future<void> printFinanceReport({
    required bool isAr,
    required String title,
    required Map<String, dynamic> summary,
    required List<dynamic> transactions,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final font = await _getCairoRegular();
    final fontBold = await _getCairoBold();
    final doc = pw.Document();

    String dateRangeStr = '';
    if (startDate != null && endDate != null) {
      dateRangeStr = '${DateFormat('yyyy-MM-dd').format(startDate)} - ${DateFormat('yyyy-MM-dd').format(endDate)}';
    } else {
      dateRangeStr = isAr ? 'كل الأوقات' : 'All Time';
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        textDirection: isAr ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold).copyWith(
          defaultTextStyle: pw.TextStyle(fontFallback: [font, fontBold]),
        ),
        build: (pw.Context ctx) {
          return [
            // Header
            pw.Center(
              child: pw.Text(
                title,
                style: pw.TextStyle(font: fontBold, fontSize: 24),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                '${isAr ? 'الفترة:' : 'Period:'} $dateRangeStr',
                style: const pw.TextStyle(fontSize: 14),
              ),
            ),
            pw.SizedBox(height: 24),

            // Summary Section
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                children: [
                  pw.Column(
                    children: [
                      pw.Text(isAr ? 'إجمالي الأرباح' : 'Total Revenue', style: pw.TextStyle(font: fontBold)),
                      pw.SizedBox(height: 4),
                      pw.Text('\$${(summary['totalRevenue'] ?? 0).toStringAsFixed(2)}', style: pw.TextStyle(font: fontBold, fontSize: 16)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text(isAr ? 'النقد الإجمالي' : 'Total Cash', style: pw.TextStyle(font: fontBold)),
                      pw.SizedBox(height: 4),
                      pw.Text('\$${(summary['totalCash'] ?? 0).toStringAsFixed(2)}', style: pw.TextStyle(font: fontBold, fontSize: 16)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Transactions Table Header
            pw.Text(
              isAr ? 'العمليات المالية' : 'Transactions Ledger',
              style: pw.TextStyle(font: fontBold, fontSize: 18),
            ),
            pw.SizedBox(height: 12),

            // Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(1.5),
                2: const pw.FlexColumnWidth(2.5),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(1.5),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: (isAr 
                      ? ['التاريخ', 'النوع', 'العميل', 'المبلغ', 'طريقة الدفع']
                      : ['Date', 'Type', 'Customer', 'Amount', 'Method']).map((h) {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(h, style: pw.TextStyle(font: fontBold)),
                    );
                  }).toList(),
                ),
                ...transactions.map((t) {
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(t['date']).toLocal()), style: pw.TextStyle(font: font)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(t['type'] ?? '', style: pw.TextStyle(font: font)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Directionality(
                          textDirection: pw.TextDirection.rtl,
                          child: pw.Text(t['customerName'] ?? 'Walk-in', style: pw.TextStyle(font: font)),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('\$${(t['amount'] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00'}', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: font)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(t['method'] ?? '-', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: font)),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ];
        },
      ),
    );

    final String fileName = 'Finance_Report_${DateFormat('yyyy_MM_dd_HH_mm').format(DateTime.now())}.pdf';

    if (kIsWeb) {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save(),
        name: fileName,
      );
    } else {
      await Printing.sharePdf(
        bytes: await doc.save(),
        filename: fileName,
      );
    }
  }
}
