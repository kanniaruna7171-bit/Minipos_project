import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';  // Add this import
import 'api_config.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static Future<Map<String, dynamic>?> login(String username, String password) async {
    final url = '${ApiConfig.baseUrl}/auth/login';
    
    debugPrint('🌐 Attempting login to: $url');
    debugPrint('📝 Username: $username');
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      debugPrint('📡 Response status: ${response.statusCode}');
      debugPrint('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('❌ Login failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('🔥 Login error: $e');
      return null;
    }
  }
}