import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../../models/supplier.dart';

class SuppliersService {
  static Future<List<Supplier>> getSuppliers() async {
    try {
      final response = await ApiClient.get('/Suppliers');
      if (response != null && response is List) {
        return response.map((json) => Supplier.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching suppliers: $e');
      return [];
    }
  }

  static Future<Supplier?> createSupplier(Map<String, dynamic> supplierData) async {
    try {
      final response = await ApiClient.post('/Suppliers', supplierData);
      if (response != null) {
        return Supplier.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('Error creating supplier: $e');
      return null;
    }
  }

  static Future<Supplier?> updateSupplier(int id, Map<String, dynamic> supplierData) async {
    try {
      final response = await ApiClient.put('/Suppliers/$id', supplierData);
      if (response != null) {
        return Supplier.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('Error updating supplier: $e');
      return null;
    }
  }

  static Future<bool> deleteSupplier(int id) async {
    try {
      return await ApiClient.delete('/Suppliers/$id');
    } catch (e) {
      debugPrint('Error deleting supplier: $e');
      return false;
    }
  }
}