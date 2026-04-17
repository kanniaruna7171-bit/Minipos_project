import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api/items_service.dart';
import '../services/api/stock_api.dart';
import '../models/item.dart';
import '../models/stock_on_hand.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/custom_button.dart';
import '../widgets/summary_card.dart';
//import '../utils/responsive_utils.dart';
import '../widgets/responsive_builder.dart';

class ItemsPage extends StatefulWidget {
  const ItemsPage({super.key});

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  final searchController = TextEditingController();

  // Item detail controllers
  final itemIdController = TextEditingController();
  final codeController = TextEditingController();
  final nameController = TextEditingController();
  final uomController = TextEditingController();
  final priceController = TextEditingController();
  final statusController = TextEditingController();

  Uint8List? pickedImageBytes;
  String? pickedImagePath;

  int selectedIndex = -1;
  String selectedStatus = "Active";

  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> filteredItems = [];

  bool isLoading = true;
  String errorMessage = '';

  // Scroll controller for syncing table header and body on mobile
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    searchController.dispose();
    itemIdController.dispose();
    codeController.dispose();
    nameController.dispose();
    uomController.dispose();
    priceController.dispose();
    statusController.dispose();
    super.dispose();
  }

Future<void> _loadItems() async {
  setState(() {
    isLoading = true;
    errorMessage = '';
  });

  try {
    final results = await Future.wait([
      ItemsService.getInventoryItems(),       // changed method – only received items
      StockApiService.getStockOnHand(),
    ]);

    final List<Item> itemsData = results[0] as List<Item>;
    final List<StockOnHand> stockData = results[1] as List<StockOnHand>;

    final Map<int, int> stockMap = {};
    for (var s in stockData) {
      stockMap[s.itemId] = s.qtyOnHand;
    }

    final List<Map<String, dynamic>> loadedItems = [];

    for (var item in itemsData) {
      final availableQty = stockMap[item.itemId] ?? 0;

      // Optional: hide items with zero stock by adding condition (availableQty > 0)
      loadedItems.add({
        "itemId": item.itemId,
        "code": item.code,
        "name": item.name,
        "uom": item.uom,
        "currentSellingPrice": item.currentSellingPrice,
        "status": availableQty > 0 ? item.status : "Inactive",
        "stock": availableQty,
        "imageBase64": item.imageBase64,
        "createdAt": DateTime.now().toIso8601String(), // adjust if you have real dates
        "updatedAt": DateTime.now().toIso8601String(),
        "createdBy": "System",
        "updatedBy": "System",
      });
    }

    loadedItems.sort((a, b) => a["name"].compareTo(b["name"]));

    setState(() {
      items = loadedItems;
      filteredItems = List.from(items);
      isLoading = false;
    });
  } catch (e) {
    setState(() {
      errorMessage = 'Failed to load items: $e';
      isLoading = false;
    });
  }
}

  void searchItems(String value) {
    setState(() {
      filteredItems = items.where((item) {
        return item["name"].toLowerCase().contains(value.toLowerCase()) ||
            item["itemId"].toString().toLowerCase().contains(value.toLowerCase()) ||
            item["code"].toLowerCase().contains(value.toLowerCase());
      }).toList();
    });
  }

  void selectItem(int index) {
    setState(() {
      selectedIndex = index;
      final item = filteredItems[index];

      itemIdController.text = item["itemId"].toString();
      codeController.text = item["code"];
      nameController.text = item["name"];
      uomController.text = item["uom"];
      priceController.text = item["currentSellingPrice"].toStringAsFixed(2);
      statusController.text = item["status"];
      selectedStatus = item["status"];

      // Handle image
      if (item["imageBase64"] != null) {
        pickedImageBytes = base64Decode(item["imageBase64"]);
        pickedImagePath = null;
      } else {
        pickedImageBytes = null;
        pickedImagePath = null;
      }
    });
  }

  void clearFields() {
    itemIdController.clear();
    codeController.clear();
    nameController.clear();
    uomController.clear();
    priceController.clear();
    statusController.clear();
    pickedImageBytes = null;
    pickedImagePath = null;
    selectedStatus = "Active";
    setState(() {
      selectedIndex = -1;
    });
  }

  Widget buildImage(Map item) {
    if (item["imageBase64"] != null && item["imageBase64"].isNotEmpty) {
      try {
        return Image.memory(
          base64Decode(item["imageBase64"]),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholderImage();
          },
        );
      } catch (e) {
        return _buildPlaceholderImage();
      }
    }
    return _buildPlaceholderImage();
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported, size: 30, color: Colors.grey[400]),
          Text(
            'No Image',
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return isoString;
    }
  }

  // String _formatDateTime(String isoString) {
  //   try {
  //     final date = DateTime.parse(isoString);
  //     return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  //   } catch (e) {
  //     return isoString;
  //   }
  // }

  void _showItemDetails(BuildContext context, Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item["name"]),
        content: Container(
          width: 500,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade100,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: buildImage(item),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildDetailRow("Item ID", item["itemId"].toString()),
                _buildDetailRow("Code", item["code"]),
                _buildDetailRow("Name", item["name"]),
                _buildDetailRow("UOM", item["uom"]),
                _buildDetailRow("Current Selling Price", "₹${item["currentSellingPrice"].toStringAsFixed(2)}"),
                _buildDetailRow("Stock", "${item["stock"]} ${item["uom"]}"),
                _buildDetailRow("Status", item["status"]),
                // const Divider(height: 20),
                // const Text("Audit Information", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                // const SizedBox(height: 8),
                // _buildDetailRow("Created At", _formatDateTime(item["createdAt"])),
                // _buildDetailRow("Updated At", _formatDateTime(item["updatedAt"])),
                // _buildDetailRow("Created By", item["createdBy"]),
                // _buildDetailRow("Updated By", item["updatedBy"]),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Desktop Table Header
  Widget _buildDesktopTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(bottom: BorderSide(color: Colors.purple.shade200)),
      ),
      child: const Row(
        children: [
          Expanded(flex: 1, child: Text("Image", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 1, child: Text("Item ID", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 1, child: Text("Code", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text("Name", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 1, child: Text("UOM", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 1, child: Text("Price", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 1, child: Text("Stock", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 1, child: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 1, child: Text("Updated", style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  // Mobile Table Header (with horizontal scroll)
  Widget _buildMobileTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(bottom: BorderSide(color: Colors.purple.shade200)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 60, child: Text("Image", style: TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(width: 70, child: Text("ID", style: TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(width: 80, child: Text("Code", style: TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(width: 120, child: Text("Name", style: TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(width: 60, child: Text("UOM", style: TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(width: 80, child: Text("Price", style: TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(width: 70, child: Text("Stock", style: TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(width: 80, child: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(width: 100, child: Text("Updated", style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  // Desktop Table Row
  Widget _buildDesktopTableRow(
    Map<String, dynamic> item, int index, bool isSelected, int stockQty) {
  return InkWell(
    onTap: () => selectItem(index),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.purple.shade50 : null,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade100,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: buildImage(item),
              ),
            ),
          ),

          Expanded(flex: 1, child: Text(item["itemId"].toString())),
          Expanded(flex: 1, child: Text(item["code"])),
          Expanded(flex: 2, child: Text(item["name"])),
          Expanded(flex: 1, child: Text(item["uom"])),

          Expanded(
            flex: 1,
            child: Text(
              "₹${item["currentSellingPrice"].toStringAsFixed(2)}",
              style: const TextStyle(
                  color: Colors.green, fontWeight: FontWeight.w500),
            ),
          ),

          Expanded(
            flex: 1,
            child: Text(
              "${item["stock"]}",
              style: TextStyle(
                color: stockQty < 10 ? Colors.orange : null,
                fontWeight: stockQty < 10 ? FontWeight.bold : null,
              ),
            ),
          ),

          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: item["status"] == "Active"
                    ? Colors.green.shade50
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                item["status"],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: item["status"] == "Active"
                      ? Colors.green.shade700
                      : Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          Expanded(
            flex: 1,
            child: Text(
              _formatDate(item["updatedAt"]),
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    ),
  );
}

  // Mobile Table Row (with horizontal scroll)
  Widget _buildMobileTableRow(Map<String, dynamic> item, int index, bool isSelected, int stockQty) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? Colors.purple.shade50 : null,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: InkWell(
        onTap: () => selectItem(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Image
              SizedBox(
                width: 60,
                child: Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade100,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: buildImage(item),
                  ),
                ),
              ),
              // ID
              SizedBox(
                width: 70,
                child: Text(item["itemId"].toString(), style: const TextStyle(fontSize: 13)),
              ),
              // Code
              SizedBox(
                width: 80,
                child: Text(item["code"], style: const TextStyle(fontSize: 13)),
              ),
              // Name
              SizedBox(
                width: 120,
                child: Text(item["name"], 
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // UOM
              SizedBox(
                width: 60,
                child: Text(item["uom"], style: const TextStyle(fontSize: 13)),
              ),
              // Price
              SizedBox(
                width: 80,
                child: Text("₹${item["currentSellingPrice"].toStringAsFixed(2)}", 
                  style: const TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.w500),
                ),
              ),
              // Stock
              SizedBox(
                width: 70,
                child: Text("${item["stock"]}", 
                  style: TextStyle(fontSize: 13, 
                    color: stockQty < 10 ? Colors.orange : null, 
                    fontWeight: stockQty < 10 ? FontWeight.bold : null
                  ),
                ),
              ),
              // Status
              SizedBox(
                width: 80,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: item["status"] == "Active" ? Colors.green.shade50 : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(item["status"], 
                    style: TextStyle(fontSize: 12, 
                      color: item["status"] == "Active" ? Colors.green.shade700 : Colors.grey.shade600,
                      fontWeight: FontWeight.w500
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              // Updated
              SizedBox(
                width: 100,
                child: Text(_formatDate(item["updatedAt"]), 
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildMobileExpandableCard(Map<String, dynamic> item, int index) {
  final stockQty = item["stock"];

  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: ExpansionTile(
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade100,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: buildImage(item),
        ),
      ),
      title: Text(
        item["name"],
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        "₹${item["currentSellingPrice"].toStringAsFixed(2)} | Stock: ${item["stock"]}",
        style: const TextStyle(fontSize: 12),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            children: [
              _buildDetailRow("Item ID", item["itemId"].toString()),
              _buildDetailRow("Code", item["code"]),
              _buildDetailRow("Name", item["name"]),
              _buildDetailRow("UOM", item["uom"]),
              _buildDetailRow(
                "Price",
                "₹${item["currentSellingPrice"].toStringAsFixed(2)}",
              ),
              _buildDetailRow("Stock", "${item["stock"]} ${item["uom"]}"),
              _buildDetailRow("Status", item["status"]),
              _buildDetailRow("Updated", _formatDate(item["updatedAt"])),

              const SizedBox(height: 10),

              CustomButton(
                text: "View Full Details",
                icon: Icons.info_outline,
                backgroundColor: Colors.purple,
                onPressed: () => _showItemDetails(context, item),
              ),
            ],
          ),
        )
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    int totalItems = items.length;
    int totalStock = items.fold(0, (sum, item) => sum + (item["stock"] as int));
    int lowStock = items.where((item) => (item["stock"] as int) < 10).length;

    return ResponsiveBuilder(
      mobile: _buildMobileLayout(context, totalItems, totalStock, lowStock),
      tablet: _buildTabletLayout(context, totalItems, totalStock, lowStock),
      desktop: _buildDesktopLayout(context, totalItems, totalStock, lowStock),
    );
  }

  // Mobile Layout
  Widget _buildMobileLayout(BuildContext context, int totalItems, int totalStock, int lowStock) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Items Management"),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadItems),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Search - Using CustomTextField
            CustomTextField(
              controller: searchController,
              hint: "Search by ID, Code or Name",
              prefixIcon: Icons.search,
              onChanged: searchItems,
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        searchController.clear();
                        searchItems('');
                      },
                    )
                  : null,
            ),

            const SizedBox(height: 16),

            // Summary Cards - Using Custom SummaryCard
           Row(
  children: [
    Expanded(
      child: SummaryCard(
        title: "Total Items",
        value: "$totalItems",
        icon: Icons.inventory,
        color: Colors.blue,
      ),
    ),

    const SizedBox(width: 10),

    Expanded(
      child: SummaryCard(
        title: "Total Stock",
        value: "$totalStock",
        icon: Icons.warehouse,
        color: Colors.green,
      ),
    ),

    const SizedBox(width: 10),

    Expanded(
      child: SummaryCard(
        title: "Low Stock",
        value: "$lowStock",
        icon: Icons.warning,
        color: Colors.orange,
      ),
    ),
  ],
),

            const SizedBox(height: 16),

            // Table
           // Items List (Expandable Cards)
Expanded(
  child: Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: isLoading
        ? const Center(child: CircularProgressIndicator())
        : errorMessage.isNotEmpty
            ? _buildErrorWidget()
            : filteredItems.isEmpty
                ? _buildEmptyWidget()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return _buildMobileExpandableCard(item, index);
                    },
                  ),
  ),
),

            // View Details Button
            if (selectedIndex != -1)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: CustomButton(
                  text: "View Full Details",
                  onPressed: () => _showItemDetails(context, filteredItems[selectedIndex]),
                  icon: Icons.info_outline,
                  backgroundColor: Colors.purple,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Tablet Layout
  Widget _buildTabletLayout(BuildContext context, int totalItems, int totalStock, int lowStock) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Items Management"),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadItems),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search - Using CustomTextField
            Center(
              child: SizedBox(
                width: 500,
                child: CustomTextField(
                  controller: searchController,
                  hint: "Search by Item ID, Code or Name",
                  prefixIcon: Icons.search,
                  onChanged: searchItems,
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            searchController.clear();
                            searchItems('');
                          },
                        )
                      : null,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Summary Cards - Using Custom SummaryCard
            Row(
              children: [
                Expanded(
                  child: SummaryCard(
                    title: "Total Items",
                    value: "$totalItems",
                    icon: Icons.inventory,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SummaryCard(
                    title: "Total Stock",
                    value: "$totalStock",
                    icon: Icons.warehouse,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SummaryCard(
                    title: "Low Stock",
                    value: "$lowStock",
                    icon: Icons.warning,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Table
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header
                    _buildDesktopTableHeader(),
                    
                    // Body
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : errorMessage.isNotEmpty
                              ? _buildErrorWidget()
                              : filteredItems.isEmpty
                                  ? _buildEmptyWidget()
                                  : SingleChildScrollView(
                                      child: Column(
                                        children: List.generate(
                                          filteredItems.length,
                                          (index) {
                                            final item = filteredItems[index];
                                            final isSelected = index == selectedIndex;
                                            final stockQty = item["stock"] as int;
                                            return _buildDesktopTableRow(item, index, isSelected, stockQty);
                                          },
                                        ),
                                      ),
                                    ),
                    ),
                  ],
                ),
              ),
            ),

            // View Details Button
            if (selectedIndex != -1)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: CustomButton(
                  text: "View Full Details",
                  onPressed: () => _showItemDetails(context, filteredItems[selectedIndex]),
                  icon: Icons.info_outline,
                  backgroundColor: Colors.purple,
                  width: 300,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Desktop Layout
  Widget _buildDesktopLayout(BuildContext context, int totalItems, int totalStock, int lowStock) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Items Management"),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadItems),
        ],
      ),
      body: Center(
        child: SizedBox(
          width: 1400,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Search - Using CustomTextField
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 600,
                      child: CustomTextField(
                        controller: searchController,
                        hint: "Search by Item ID, Code or Name",
                        prefixIcon: Icons.search,
                        onChanged: searchItems,
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  searchController.clear();
                                  searchItems('');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Summary Cards - Using Custom SummaryCard
                Row(
                  children: [
                    Expanded(
                      child: SummaryCard(
                        title: "Total Items",
                        value: "$totalItems",
                        icon: Icons.inventory,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SummaryCard(
                        title: "Total Stock",
                        value: "$totalStock",
                        icon: Icons.warehouse,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SummaryCard(
                        title: "Low Stock",
                        value: "$lowStock",
                        icon: Icons.warning,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Items Table
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Table Header
                        _buildDesktopTableHeader(),

                        // Table Body
                        Expanded(
                          child: isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : errorMessage.isNotEmpty
                                  ? _buildErrorWidget()
                                  : filteredItems.isEmpty
                                      ? _buildEmptyWidget()
                                      : ListView.builder(
                                          itemCount: filteredItems.length,
                                          itemBuilder: (context, index) {
                                            final item = filteredItems[index];
                                            final isSelected = index == selectedIndex;
                                            final stockQty = item["stock"];
                                            return _buildDesktopTableRow(item, index, isSelected, stockQty);
                                          },
                                        ),
                        ),
                      ],
                    ),
                  ),
                ),

                // View Details Button
                if (selectedIndex != -1)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: CustomButton(
                      text: "View Full Details",
                      onPressed: () => _showItemDetails(context, filteredItems[selectedIndex]),
                      icon: Icons.info_outline,
                      backgroundColor: Colors.purple,
                      width: 300,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      // floatingActionButton: selectedIndex != -1
      //     ? FloatingActionButton.extended(
      //         onPressed: () => _showItemDetails(context, filteredItems[selectedIndex]),
      //         icon: const Icon(Icons.info_outline),
      //         label: const Text("View Details"),
      //         backgroundColor: Colors.purple,
      //       )
          // : null,
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(errorMessage, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 10),
          CustomButton(
            text: "Retry",
            onPressed: _loadItems,
            width: 150,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "No items found",
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            "Approve GRNs to add items",
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}