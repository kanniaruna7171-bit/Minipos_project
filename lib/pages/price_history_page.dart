import 'package:flutter/material.dart';
import '../services/api/price_history_service.dart';
import '../pages/item_price_history.dart';

class PriceHistoryPage extends StatefulWidget {
  const PriceHistoryPage({super.key});

  @override
  State<PriceHistoryPage> createState() => _PriceHistoryPageState();
}

class _PriceHistoryPageState extends State<PriceHistoryPage> {
  List<ItemPriceHistory> history = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      final data = await PriceHistoryService.getPriceHistory();
      setState(() {
        history = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load price history: $e';
        isLoading = false;
      });
    }
  }

  // Desktop table header
  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Expanded(child: Text("Item", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text("Purchase Cost", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text("Selling Price", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text("Margin %", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text("Effective Date", style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  // Desktop table row
  Widget _buildTableRow(ItemPriceHistory item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          Expanded(child: Text(item.itemName)),
          Expanded(child: Text("₹${item.purchaseCost.toStringAsFixed(2)}")),
          Expanded(child: Text("₹${item.sellingPrice.toStringAsFixed(2)}")),
          Expanded(child: Text("${item.marginPercent.toStringAsFixed(1)}%")),
          Expanded(
            child: Text(
              "${item.effectiveAt.year}-${item.effectiveAt.month.toString().padLeft(2, '0')}-${item.effectiveAt.day.toString().padLeft(2, '0')}",
            ),
          ),
        ],
      ),
    );
  }

  // Mobile expandable card
  Widget _buildMobileCard(ItemPriceHistory item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: ExpansionTile(
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: Colors.green.shade100,
          child: const Icon(Icons.attach_money, size: 18),
        ),
        title: Text(
          item.itemName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Selling: ₹${item.sellingPrice.toStringAsFixed(2)}'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('Purchase Cost', '₹${item.purchaseCost.toStringAsFixed(2)}'),
                _detailRow('Margin', '${item.marginPercent.toStringAsFixed(1)}%'),
                _detailRow(
                  'Effective Date',
                  "${item.effectiveAt.year}-${item.effectiveAt.month.toString().padLeft(2, '0')}-${item.effectiveAt.day.toString().padLeft(2, '0')}",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Item Price History"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (isDesktop) _buildTableHeader(),
            const SizedBox(height: 10),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(errorMessage,
                                  style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: _loadHistory,
                                child: const Text("Retry"),
                              ),
                            ],
                          ),
                        )
                      : history.isEmpty
                          ? const Center(child: Text("No price history found"))
                          : isDesktop
                              ? ListView.builder(
                                  itemCount: history.length,
                                  itemBuilder: (_, index) =>
                                      _buildTableRow(history[index]),
                                )
                              : ListView.builder(
                                  itemCount: history.length,
                                  itemBuilder: (_, index) =>
                                      _buildMobileCard(history[index]),
                                ),
            ),
          ],
        ),
      ),
    );
  }
}