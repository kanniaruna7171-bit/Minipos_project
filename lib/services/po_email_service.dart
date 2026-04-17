// ================= EMAIL SERVICE (NO PDF) =================
// pubspec.yaml dependency: http: ^1.2.0

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/purchase_order.dart'; // adjust path if needed

class POEmailService {
  /// Builds the plain‑text email body exactly as shown in the manager's image.
  static String buildEmailBody(PurchaseOrder order) {
    final itemsText = order.lines.map((line) =>
        "${line.item} | Qty: ${line.qty} | Rate: ₹${line.rate} | Total: ₹${line.total}"
    ).join("\n");

    return '''
Hello,

A new Purchase Order has been created.

PO Number: ${order.number}
Date: ${order.date}
Supplier: ${order.supplier}

Items:
$itemsText

Thank you.
''';
  }

  /// Sends the email via EmailJS using the predefined template.
  static Future<void> sendEmail({
    required String supplierEmail,
    required PurchaseOrder order,
  }) async {
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    const serviceId = 'service_3hmxznm';
    const templateId = 'template_si0ib8s';
    const userId = 'mBwEamqFeXxFIJPN1';

    // Prepare the items list as a single string (same as in buildEmailBody)
    final itemsString = order.lines
        .map((e) =>
            "${e.item} | Qty: ${e.qty} | Rate: ₹${e.rate} | Total: ₹${e.total}")
        .join("\n");

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': userId,
        'template_params': {
          'to_email': supplierEmail,
          'po_number': order.number,
          'po_date': order.date,
          'supplier': order.supplier,
          'items': itemsString,
          'total': order.total.toStringAsFixed(2),
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Email sending failed: ${response.body}');
    }
  }
}