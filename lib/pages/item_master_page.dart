import 'package:flutter/material.dart';
import '../services/api/api_client.dart';

class ItemMasterPage extends StatefulWidget {
  const ItemMasterPage({super.key});

  @override
  State<ItemMasterPage> createState() => _ItemMasterPageState();
}

class _ItemMasterPageState extends State<ItemMasterPage> {
  final TextEditingController nameController = TextEditingController();

  Future<void> saveItem() async {
    await ApiClient.post('/Items', {
      "name": nameController.text,
       "code": "",
     "uom": "",
      "status": "Active",
      "currentSellingPrice": 0
    });

    nameController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Item saved")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Item Master"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Item Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveItem,
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}