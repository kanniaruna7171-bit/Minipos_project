//import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../../models/purchase_order.dart';

class PurchaseOrderService {
  static Future<List<PurchaseOrder>> getPurchaseOrders() async {
    try {
      final response = await ApiClient.get('/PurchaseOrders');
      if (response != null && response is List) {
        return response.map((json) => PurchaseOrder.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching POs: $e');
      return [];
    }
  }

  static Future<PurchaseOrder?> createPurchaseOrder(Map<String, dynamic> data) async {
    try {
      final response = await ApiClient.post('/PurchaseOrders', data);
      if (response != null) {
        return PurchaseOrder.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('Error creating PO: $e');
      return null;
    }
  }

  static Future<PurchaseOrder?> updatePurchaseOrder(int id, Map<String, dynamic> data) async {
    try {
      final response = await ApiClient.put('/PurchaseOrders/$id', data);
      if (response != null) {
        return PurchaseOrder.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('Error updating PO: $e');
      return null;
    }
  }

  static Future<bool> deletePurchaseOrder(int id) async {
    try {
      return await ApiClient.delete('/PurchaseOrders/$id');
    } catch (e) {
      debugPrint('Error deleting PO: $e');
      return false;
    }
  }

  // NEW METHOD: Save email log
  static Future<bool> saveEmailLog(int poId, String toEmail, String subject, String body) async {
    try {
      final response = await ApiClient.post('/PurchaseOrders/$poId/email-log', {
        'toEmail': toEmail,
        'subject': subject,
        'body': body,
      });
      return response != null;
    } catch (e) {
      debugPrint('Error saving email log: $e');
      return false;
    }
  }

static Future<PurchaseOrder?> getPurchaseOrderByNumber(String poNumber) async {
  try {
    final response = await ApiClient.get('/PurchaseOrders/by-number?number=$poNumber');

    if (response != null) {

      if (response is List && response.isNotEmpty) {
        return PurchaseOrder.fromJson(response.first);
      }

      if (response is Map<String, dynamic>) {
        return PurchaseOrder.fromJson(response);
      }
    }

    return null;
  } catch (e) {
    debugPrint('Error fetching PO by number: $e');
    return null;
  }
}

  
}