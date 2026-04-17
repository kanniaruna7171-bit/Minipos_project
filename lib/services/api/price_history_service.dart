import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../../pages/item_price_history.dart';

class PriceHistoryService {
  static Future<List<ItemPriceHistory>> getPriceHistory() async {
    try {
      final response = await ApiClient.get('/PriceHistory');
      if (response != null && response is List) {
        return response.map((json) => ItemPriceHistory.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching price history: $e');
      return [];
    }
  }
}