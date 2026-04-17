//import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../../models/grn.dart';


class GRNService {
  static Future<List<GRN>> getGRNs() async {
  try {
    final response = await ApiClient.get('/GRN');
    print('📥 Raw GET response: $response');
    if (response != null && response is List) {
      return response.map((json) => GRN.fromJson(json)).toList();
    }
    return [];
  } catch (e) {
    debugPrint('Error fetching GRNs: $e');
    return [];
  }
}

  static Future<GRN?> createGRN(Map<String, dynamic> data) async {
    try {
      final response = await ApiClient.post('/GRN', data);
      if (response != null) {
        return GRN.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('Error creating GRN: $e');
      return null;
    }
  }

  static Future<bool> approveGRN(int id) async {
    try {
      final response = await ApiClient.put('/GRN/$id/approve', {});
      return response != null;
    } catch (e) {
      debugPrint('Error approving GRN: $e');
      return false;
    }
  }


  static Future<bool> saveEmailLog(int grnId, String toEmail, String subject, String body) async {
  try {
    debugPrint('📧 Saving email log for GRN ID: $grnId to /GRN/$grnId/email-log');
    final response = await ApiClient.post('/GRN/$grnId/email-log', {
      'toEmail': toEmail,
      'subject': subject,
      'body': body,
    });
    debugPrint('📨 Email log response: $response');
    return response != null;
  } catch (e) {
    debugPrint('❌ Error saving GRN email log: $e');
    return false;
  }
}
}