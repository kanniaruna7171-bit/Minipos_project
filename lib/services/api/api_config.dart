import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

/// API Configuration for different platforms
/// 
/// This class provides the correct API base URL based on the platform:
/// - Web: Uses localhost
/// - Windows/Desktop: Uses localhost
/// - Android Emulator: Uses 10.0.2.2 (special IP for emulator to access host)
/// - Android Physical Device: Uses your computer's IP address
/// - iOS Simulator: Uses localhost
/// - iOS Physical Device: Uses your computer's IP address
class ApiConfig {
  // TODO: Update this with your computer's IP address for physical devices
  // To find your IP:
  // - Windows: Run 'ipconfig' in Command Prompt, look for IPv4 Address
  // - Mac/Linux: Run 'ifconfig' in Terminal, look for inet address
  static const String _hostIpAddress = '10.52.160.137'; // Your IP address
  
  // TODO: Update this with your backend port if different
  static const String _port = '5286';  // Updated to match your C# backend
  
  // TODO: Update this with your API path if different
  static const String _apiPath = '/api';
  
  /// Get the appropriate base URL for the current platform
  static String get baseUrl {
    if (kIsWeb) {
      // Web platform
      return 'http://localhost:$_port$_apiPath';
    }
    
    if (Platform.isAndroid) {
      // Android platform
      // For emulator, use 10.0.2.2 to access host machine
      // For physical device, use the host machine's IP address
      
      // For physical Android devices (UNCOMMENTED - using your IP):
      return 'http://$_hostIpAddress:$_port$_apiPath';
      
      // For Android emulator (comment line above, uncomment line below):
      // return 'http://10.0.2.2:$_port$_apiPath';
    }
    
    if (Platform.isIOS) {
      // iOS platform
      // Simulator can use localhost
      // Physical device needs host machine's IP address
      
      // For physical iOS devices (UNCOMMENTED - using your IP):
      return 'http://$_hostIpAddress:$_port$_apiPath';
      
      // For iOS simulator (comment line above, uncomment line below):
      // return 'http://localhost:$_port$_apiPath';
    }
    
    // Windows, macOS, Linux - use localhost
    return 'http://localhost:$_port$_apiPath';
  }
  
  /// Get full URL for a specific endpoint
  /// 
  /// Example:
  /// ```dart
  /// final url = ApiConfig.getUrl('/items');
  /// // Returns: http://localhost:3000/api/items
  /// ```
  static String getUrl(String endpoint) {
    // Remove leading slash if present to avoid double slashes
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    return '$baseUrl/$cleanEndpoint';
  }
  
  /// Check if running on physical device (for debugging)
  static bool get isPhysicalDevice {
    if (kIsWeb) return false;
    
    // This is a simple check - you might want to enhance it
    // For now, we assume emulator/simulator if using default URLs
    return false; // Set to true when testing on physical devices
  }
  
  /// Get platform name for debugging
  static String get platformName {
    if (kIsWeb) return 'Web';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }
  
  /// Print current configuration (for debugging)
  static void printConfig() {
    print('=== API Configuration ===');
    print('Platform: $platformName');
    print('Base URL: $baseUrl');
    print('Physical Device: $isPhysicalDevice');
    print('========================');
  }
}

/// Example usage in your API services:
/// 
/// ```dart
/// import 'package:http/http.dart' as http;
/// import '../config/api_config.dart';
/// 
/// class ItemsService {
///   static Future<List<Item>> getItems() async {
///     final response = await http.get(
///       Uri.parse(ApiConfig.getUrl('items')),
///     );
///     
///     if (response.statusCode == 200) {
///       // Parse and return items
///     } else {
///       throw Exception('Failed to load items');
///     }
///   }
/// }
/// ```
