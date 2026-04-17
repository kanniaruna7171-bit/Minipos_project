import 'dart:convert';
import 'package:flutter/material.dart';
import 'api_config.dart';
import 'http_client.dart';
import 'token_storage.dart';

class ApiClient {
  static String? _token;
  static String? _role;

  static void setToken(String token, String role) {
    _token = token;
    _role = role;
    TokenStorage.saveToken(token, role);
  }

  static Map<String, String> get headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    
    return headers;
  }

  static Future<dynamic> get(String endpoint) async {
    try {
      final client = HttpClientWithSSL.create();
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      
      final response = await client.get(
        uri,
        headers: headers,
      ).timeout(const Duration(seconds: 30));
      
      client.close();

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      
      debugPrint('GET failed: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      debugPrint('GET error: $e');
      return null;
    }
  }

  static Future<dynamic> post(String endpoint, dynamic data) async {
    try {
      final client = HttpClientWithSSL.create();
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      
      final response = await client.post(
        uri,
        headers: headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 30));
      
      client.close();

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      
      debugPrint('POST failed: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      debugPrint('POST error: $e');
      return null;
    }
  }

  static Future<dynamic> put(String endpoint, dynamic data) async {
    try {
      final client = HttpClientWithSSL.create();
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      
      final response = await client.put(
        uri,
        headers: headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 30));
      
      client.close();

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      
      debugPrint('PUT failed: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      debugPrint('PUT error: $e');
      return null;
    }
  }

  static Future<bool> delete(String endpoint) async {
    try {
      final client = HttpClientWithSSL.create();
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      
      final response = await client.delete(
        uri,
        headers: headers,
      ).timeout(const Duration(seconds: 30));
      
      client.close();

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('DELETE error: $e');
      return false;
    }
  }

  // Helper method to check if user is logged in
  static bool get isLoggedIn => _token != null && _token!.isNotEmpty;
  
  // Get current role
  static String? get currentRole => _role;
  
  // Get current token
  static String? get currentToken => _token;
  
  // Clear token (logout)
  static Future<void> clearToken() async {
    _token = null;
    _role = null;
    await TokenStorage.clearToken();
  }
}