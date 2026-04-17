import 'package:flutter/material.dart';
import '../services/api/stock_api.dart';
import '../models/stock_ledger.dart';
import '../models/stock_on_hand.dart';

class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  List<StockLedgerEntry> ledger = [];
  List<StockOnHand> onHand = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      // Fetch both ledger and onhand in parallel
      final results = await Future.wait([
        StockApiService.getStockLedger(),
        StockApiService.getStockOnHand(),
      ]);
      final ledgerData = results[0] as List<StockLedgerEntry>;
      final onHandData = results[1] as List<StockOnHand>;

      // Create a map for quick lookup of item name by itemId
      final Map<int, String> itemNameMap = {};
      for (var item in onHandData) {
        itemNameMap[item.itemId] = item.itemName;
      }

      // Assign item names to ledger entries
      for (var entry in ledgerData) {
        entry.itemName = itemNameMap[entry.itemId] ?? 'Unknown';
      }

      setState(() {
        ledger = ledgerData;
        onHand = onHandData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load stock data: $e';
        isLoading = false;
      });
    }
  }

  // Compute running stock for each ledger entry
  List<int> _computeRunningStock() {
    final Map<int, int> tempStock = {};
    final List<int> running = [];
    for (var e in ledger) {
      final key = e.itemId;
      tempStock[key] = (tempStock[key] ?? 0) + e.qtyIn - e.qtyOut;
      running.add(tempStock[key]!);
    }
    return running;
  }

  // Get latest selling price for an item (from onHand list)
  double _getSellingPrice(int itemId) {
    final item = onHand.firstWhere(
      (item) => item.itemId == itemId,
      orElse: () => StockOnHand(
        itemId: itemId,
        itemName: '',
        qtyOnHand: 0,
        currentSellingPrice: 0,
      ),
    );
    return item.currentSellingPrice;
  }

  // Desktop table header
  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Expanded(child: Text("ID", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text("Item", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text("Date", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text("Rate", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text("Qty In", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text("Qty Out", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text("Stock", style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  // Desktop table row
  Widget _buildTableRow(StockLedgerEntry e, int currentStock) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3)],
      ),
      child: Row(
        children: [
          Expanded(child: Text(e.id.toString())),
          Expanded(child: Text(e.itemName ?? 'Unknown')),
          Expanded(
            child: Text(
              "${e.txnDate.day}/${e.txnDate.month}/${e.txnDate.year}",
            ),
          ),
          Expanded(
            child: Text(
              _getSellingPrice(e.itemId).toStringAsFixed(2),
            ),
          ),
          Expanded(
            child: Text(
              e.qtyIn > 0 ? "+${e.qtyIn}" : "-",
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              e.qtyOut > 0 ? "-${e.qtyOut}" : "-",
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              currentStock.toString(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Mobile expandable card
  Widget _buildMobileCard(StockLedgerEntry e, int currentStock) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: ExpansionTile(
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: Colors.blue.shade100,
          child: Text(
            e.id.toString(),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          e.itemName ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Stock: $currentStock'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('Date', "${e.txnDate.day}/${e.txnDate.month}/${e.txnDate.year}"),
                _detailRow('Rate', '₹${_getSellingPrice(e.itemId).toStringAsFixed(2)}'),
                _detailRow('Qty In', e.qtyIn > 0 ? '+${e.qtyIn}' : '-',
                    valueColor: Colors.green),
                _detailRow('Qty Out', e.qtyOut > 0 ? '-${e.qtyOut}' : '-',
                    valueColor: Colors.red),
                const Divider(),
                _detailRow('Running Stock', currentStock.toString(),
                    isBold: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value,
      {Color valueColor = Colors.black, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:',
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final runningStock = _computeRunningStock();
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Stock Dashboard"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
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
                                onPressed: _loadData,
                                child: const Text("Retry"),
                              ),
                            ],
                          ),
                        )
                      : ledger.isEmpty
                          ? const Center(child: Text("No stock transactions"))
                          : isDesktop
                              ? ListView.builder(
                                  itemCount: ledger.length,
                                  itemBuilder: (_, i) =>
                                      _buildTableRow(ledger[i], runningStock[i]),
                                )
                              : ListView.builder(
                                  itemCount: ledger.length,
                                  itemBuilder: (_, i) =>
                                      _buildMobileCard(ledger[i], runningStock[i]),
                                ),
            ),
          ],
        ),
      ),
    );
  }
}