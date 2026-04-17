//import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../../models/stock_ledger.dart';
import '../../models/stock_on_hand.dart';

class StockApiService {
  // Fetch stock on hand (includes item name and selling price)
  static Future<List<StockOnHand>> getStockOnHand() async {
    try {
      final response = await ApiClient.get('/Stock/onhand');
      if (response != null && response is List) {
        return response.map((json) => StockOnHand.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching stock on hand: $e');
      return [];
    }
  }

  // Fetch stock ledger entries
  static Future<List<StockLedgerEntry>> getStockLedger() async {
    try {
      final response = await ApiClient.get('/Stock/ledger');
      if (response != null && response is List) {
        return response.map((json) => StockLedgerEntry.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching stock ledger: $e');
      return [];
    }
  }
}