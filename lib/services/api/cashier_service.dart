import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../../models/product.dart';

class CashierService {
  static Future<List<Product>> getProducts() async {
    try {
      final response = await ApiClient.get('/Cashier/products');
      if (response != null && response is List) {
        return response.map((json) => Product.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching products: $e');
      return [];
    }
  }
}