import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PrintService {
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
    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

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
              pw.Text(
                title,
                style: pw.TextStyle(fontSize: 14),
                textAlign: pw.TextAlign.center,
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
                  pw.Text(customerName),
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
                      pw.Expanded(child: pw.Text(item['name'])),
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
                  pw.Text(paymentMethod),
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

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Receipt_${DateTime.now().millisecondsSinceEpoch}',
      usePrinterSettings: true,
    );
  }
}
