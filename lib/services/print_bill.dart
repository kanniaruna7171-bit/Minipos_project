import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

Future<void> printBill(List<Map<String, dynamic>> cart, double total) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.roll80,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            /// SHOP TITLE
            pw.Text(
              'Sales Receipt',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),

            pw.SizedBox(height: 5),

            pw.Text(
              'HnA Shop',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),

            pw.Text('Kalavakkam Road'),

            pw.SizedBox(height: 10),
            pw.Divider(),

            /// TABLE HEADER
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            ),

            pw.Divider(),

            /// CART ITEMS
            ...cart.map((item) {
              final lineTotal = item['qty'] * item['price'];

              return pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(item['name']),
                  pw.Text('${item['qty']}'),
                  pw.Text('Rs. ${item['price']}'),  // ← changed from ₹ to Rs.
                  pw.Text('Rs. $lineTotal'),        // ← changed from ₹ to Rs.
                ],
              );
            }).toList(),

            pw.Divider(),

            /// TOTAL AMOUNT
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Total: Rs. ${total.toStringAsFixed(2)}', // ← changed from ₹ to Rs.
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),

            pw.SizedBox(height: 10),

            /// FOOTER
            pw.Text(
              'Thank You! Visit Again!',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ],
        );
      },
    ),
  );

  await Printing.layoutPdf(onLayout: (format) async => pdf.save());
}