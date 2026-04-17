import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../../models/item.dart'; // We'll create this model

class ItemsService {
  static Future<List<Item>> getItems() async {
    try {
      final response = await ApiClient.get('/Items');
      if (response != null && response is List) {
        return response.map((json) => Item.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching items: $e');
      return [];
    }
  }

  static Future<List<Item>> getMasterItems() async {
    final data = await ApiClient.get('/Items/master');
    return (data as List).map((json) => Item.fromJson(json)).toList();
  }

  static Future<List<Item>> getInventoryItems() async {
    final data = await ApiClient.get('/Items/inventory');
    return (data as List).map((json) => Item.fromJson(json)).toList();
  }
}