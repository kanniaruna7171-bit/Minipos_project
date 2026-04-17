// import 'package:flutter/material.dart';
// import 'services/api/auth_service.dart';
// import 'services/api/api_config.dart';

// class TestConnectionPage extends StatefulWidget {
//   const TestConnectionPage({super.key});

//   @override
//   State<TestConnectionPage> createState() => _TestConnectionPageState();
// }

// class _TestConnectionPageState extends State<TestConnectionPage> {
//   String status = "Ready to test";
//   bool isLoading = false;
//   String details = "";

//   Future<void> testConnection() async {
//     setState(() {
//       isLoading = true;
//       status = "Testing connection...";
//       details = "";
//     });

//     final result = await AuthService.login('admin', 'admin123');
    
//     setState(() => isLoading = false);

//     if (result != null) {
//       setState(() {
//         status = "✅ Connected successfully!";
//         details = "Token received!\nRole: ${result['role']}";
//       });
//     } else {
//       setState(() {
//         status = "❌ Connection failed";
//         details = "Check if backend is running at ${ApiConfig.baseUrl}";
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Connection Test")),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                 status,
//                 style: TextStyle(
//                   fontSize: 18,
//                   color: status.contains("✅") ? Colors.green :
//                          status.contains("❌") ? Colors.red : Colors.black,
//                 ),
//               ),
//               const SizedBox(height: 20),
//               if (details.isNotEmpty)
//                 Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Colors.grey[200],
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Text(details),
//                 ),
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: isLoading ? null : testConnection,
//                 child: isLoading
//                     ? const CircularProgressIndicator()
//                     : const Text("Test Connection"),
//               ),
//               const SizedBox(height: 10),
//               Text(
//                 "Backend URL: ${ApiConfig.baseUrl}",
//                 style: const TextStyle(fontSize: 12, color: Colors.grey),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }