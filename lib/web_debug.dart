// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// void main() {
//   runApp(const MaterialApp(home: WebDebugPage()));
// }

// class WebDebugPage extends StatefulWidget {
//   const WebDebugPage({super.key});

//   @override
//   State<WebDebugPage> createState() => _WebDebugPageState();
// }

// class _WebDebugPageState extends State<WebDebugPage> {
//   String status = "Ready to test";
//   String responseBody = "";
//   bool isLoading = false;

//   Future<void> testConnection() async {
//     setState(() {
//       isLoading = true;
//       status = "Testing...";
//       responseBody = "";
//     });

//     try {
//       // Test different URLs
//       final urls = [
//         'https://localhost:7158/api/auth/login',
//         'https://127.0.0.1:7158/api/auth/login',
//         'http://localhost:5286/api/auth/login', // Try HTTP as fallback
//       ];

//       for (String url in urls) {
//         try {
//           final response = await http.post(
//             Uri.parse(url),
//             headers: {'Content-Type': 'application/json'},
//             body: jsonEncode({
//               'username': 'admin',
//               'password': 'admin123',
//             }),
//           ).timeout(const Duration(seconds: 5));

//           setState(() {
//             status = "✅ Connected to: $url";
//             responseBody = "Status: ${response.statusCode}\nBody: ${response.body}";
//           });
//           break;
//         } catch (e) {
//           // Try next URL
//           continue;
//         }
//       }
      
//       if (status == "Testing...") {
//         setState(() {
//           status = "❌ Failed to connect to any URL";
//         });
//       }
//     } catch (e) {
//       setState(() {
//         status = "❌ Error: $e";
//       });
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Web Debug - Test Connection")),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                 status,
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: status.contains("✅") ? Colors.green : 
//                          status.contains("❌") ? Colors.red : Colors.black,
//                 ),
//               ),
//               const SizedBox(height: 20),
//               if (responseBody.isNotEmpty)
//                 Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Colors.grey[200],
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Text(responseBody),
//                 ),
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: isLoading ? null : testConnection,
//                 child: isLoading 
//                     ? const CircularProgressIndicator() 
//                     : const Text("Test Backend Connection"),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }