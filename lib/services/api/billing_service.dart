import 'package:flutter/foundation.dart';
import 'api_client.dart';

class BillingService {
  static Future<bool> createBill(List<Map<String, dynamic>> lines) async {
    try {
      // lines should be list of {itemId, quantity, price}
      final response = await ApiClient.post('/Billing/create', lines);
      return response != null;
    } catch (e) {
      debugPrint('Error creating bill: $e');
      return false;
    }
  }
}