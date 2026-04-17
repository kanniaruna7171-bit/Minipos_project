import 'package:flutter/material.dart';
import '../services/api/purchase_order_service.dart';
import '../models/purchase_order.dart';
import '../services/po_email_service.dart';
import '../models/item.dart';
import '../services/api/items_service.dart';

class PurchaseOrdersPage extends StatefulWidget {
  const PurchaseOrdersPage({super.key});

  @override
  State<PurchaseOrdersPage> createState() => _PurchaseOrdersPageState();
}

class _PurchaseOrdersPageState extends State<PurchaseOrdersPage> {
  List<PurchaseOrder> orders = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      final data = await PurchaseOrderService.getPurchaseOrders();
      setState(() {
        orders = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load orders: $e';
        isLoading = false;
      });
    }
  }

  int get totalPO => orders.length;
  int get pendingPO => orders.where((o) => o.status == "Pending" || o.status == "Draft").length;
  int get receivedPO => orders.where((o) => o.status == "Received").length;
  double get totalAmount => orders.fold(0, (sum, o) => sum + o.total);

  void _openCreatePO({PurchaseOrder? order}) async {
    final result = await showDialog<PurchaseOrder?>(
      context: context,
      builder: (_) => CreatePOPopup(order: order),
    );
    if (result != null && mounted) {
      await _loadOrders();
    }
  }

  void _openDetails(PurchaseOrder order) {
    showDialog(
      context: context,
      builder: (_) => PODetailsPopup(order: order, onUpdate: _loadOrders),
    );
  }

  // Robust date formatter (unchanged)
  String _formatDate(String dateStr) {
    try {
      final DateTime parsed = DateTime.parse(dateStr);
      return '${parsed.day.toString().padLeft(2, '0')}-'
          '${parsed.month.toString().padLeft(2, '0')}-'
          '${parsed.year}';
    } catch (_) {
      final RegExp exp = RegExp(r'^(\d{2}).*?(\d{2})-(\d{4})$');
      final match = exp.firstMatch(dateStr);
      if (match != null) {
        return '${match.group(1)}-${match.group(2)}-${match.group(3)}';
      }
      if (dateStr.contains('-')) {
        final parts = dateStr.split('-');
        if (parts.length == 3) {
          if (parts[0].length == 4) {
            return '${parts[2].padLeft(2, '0')}-${parts[1].padLeft(2, '0')}-${parts[0]}';
          }
          return dateStr;
        }
      } else if (dateStr.contains('/')) {
        final parts = dateStr.split('/');
        if (parts[2].length == 4) {
          return '${parts[0].padLeft(2, '0')}-${parts[1].padLeft(2, '0')}-${parts[2]}';
        }
      }
      return dateStr;
    }
  }

  // Desktop summary card
  Widget _buildSummaryCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            Text(title, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  // Mobile summary card (more compact)
  Widget _buildSummaryCardMobile(String title, String value, Color color) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          Text(title,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  // Desktop layout (unchanged)
  Widget _buildDesktopLayout() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Orders', textAlign: TextAlign.center),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreatePO(),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _buildSummaryCard("Total", totalPO.toString(), Colors.blue),
                const SizedBox(width: 10),
                _buildSummaryCard("Pending", pendingPO.toString(), Colors.orange),
                const SizedBox(width: 10),
                _buildSummaryCard("Received", receivedPO.toString(), Colors.green),
                const SizedBox(width: 10),
                _buildSummaryCard("Amount", "₹${totalAmount.toStringAsFixed(0)}", Colors.purple),
              ],
            ),
            const SizedBox(height: 20),

            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (errorMessage.isNotEmpty)
              Center(
                child: Column(
                  children: [
                    Text(errorMessage, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 10),
                    ElevatedButton(onPressed: _loadOrders, child: const Text("Retry")),
                  ],
                ),
              )
            else
              Expanded(
                child: Column(
                  children: [
                    // Table Header
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Expanded(child: Text("PO Number", style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(child: Text("Supplier", style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(child: Text("Date", style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(child: Text("Total", style: TextStyle(fontWeight: FontWeight.bold))),
                          SizedBox(width: 40),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // List
                    Expanded(
                      child: ListView.builder(
                        itemCount: orders.length,
                        itemBuilder: (_, i) {
                          final o = orders[i];
                          return GestureDetector(
                            onTap: () => _openDetails(o),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                              ),
                              child: Row(
                                children: [
                                  Expanded(child: Text(o.number)),
                                  Expanded(child: Text(o.supplier)),
                                  Expanded(child: Text(o.date)),
                                  Expanded(child: Text("₹${o.total.toStringAsFixed(0)}")),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _openCreatePO(order: o),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Mobile layout (unchanged)
  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Orders', textAlign: TextAlign.center),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreatePO(),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildSummaryCardMobile("Total", totalPO.toString(), Colors.blue)),
                const SizedBox(width: 6),
                Expanded(child: _buildSummaryCardMobile("Pending", pendingPO.toString(), Colors.orange)),
                const SizedBox(width: 6),
                Expanded(child: _buildSummaryCardMobile("Received", receivedPO.toString(), Colors.green)),
                const SizedBox(width: 6),
                Expanded(child: _buildSummaryCardMobile("Amount", "₹${totalAmount.toStringAsFixed(0)}", Colors.purple)),
              ],
            ),
            const SizedBox(height: 20),

            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (errorMessage.isNotEmpty)
              Center(
                child: Column(
                  children: [
                    Text(errorMessage, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 10),
                    ElevatedButton(onPressed: _loadOrders, child: const Text("Retry")),
                  ],
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (_, i) {
                    final o = orders[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        onTap: () => _openDetails(o),
                        title: Text(o.number, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Supplier: ${o.supplier}"),
                            Text("Total: ₹${o.total.toStringAsFixed(0)}"),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _openCreatePO(order: o),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return _buildMobileLayout();
        } else {
          return _buildDesktopLayout();
        }
      },
    );
  }
}

// ================= CORRECTED CREATE/EDIT POPUP =================
class CreatePOPopup extends StatefulWidget {
  final PurchaseOrder? order;
  const CreatePOPopup({super.key, this.order});

  @override
  State<CreatePOPopup> createState() => _CreatePOPopupState();
}

class _CreatePOPopupState extends State<CreatePOPopup> {
  final supplierController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final qtyController = TextEditingController();
  final rateController = TextEditingController();

  List<Item> items = [];
  Item? selectedItem;
  final List<PurchaseLine> lines = [];
  bool isEditing = false;
  int? editingPOId;
  bool isSaving = false;
  bool isLoadingItems = false; // ✅ Added for loading indicator

  @override
  void initState() {
    super.initState();
    _loadItems(); // Load master items for dropdown

    if (widget.order != null) {
      // ✅ Populate fields when editing
      isEditing = true;
      editingPOId = widget.order!.poId;
      supplierController.text = widget.order!.supplier;
      emailController.text = widget.order!.supplierEmail;
      phoneController.text = widget.order!.supplierPhone ?? '';
      lines.addAll(widget.order!.lines);
    }
  }

  Future<void> _loadItems() async {
    setState(() => isLoadingItems = true);
    try {
      // ✅ Use master items endpoint (all items, regardless of received status)
      final data = await ItemsService.getMasterItems();
      setState(() {
        items = data;
        isLoadingItems = false;
      });
    } catch (e) {
      setState(() => isLoadingItems = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load items: $e')),
      );
    }
  }

  String get poNumber => isEditing ? widget.order!.number : "PO${DateTime.now().millisecondsSinceEpoch}";
  double get total => lines.fold(0, (sum, l) => sum + l.total);

  void _addLine() {
    if (selectedItem == null || qtyController.text.isEmpty || rateController.text.isEmpty) return;
    setState(() {
      lines.add(PurchaseLine(
        itemId: selectedItem!.itemId, // include itemId if your model has it
        item: selectedItem!.name,
        qty: int.parse(qtyController.text),
        rate: double.parse(rateController.text),
      ));
      selectedItem = null;
      qtyController.clear();
      rateController.clear();
    });
  }

  void _removeLine(int index) {
    setState(() => lines.removeAt(index));
  }

  Future<void> _save() async {
    if (supplierController.text.isEmpty || emailController.text.isEmpty || lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => isSaving = true);

    final data = {
      'ponumber': poNumber,
      'supplierName': supplierController.text,
      'supplierEmail': emailController.text,
      'supplierPhone': phoneController.text,
      'lines': lines.map((l) => {
        'itemId': l.itemId,   // send itemId if your API expects it
        'item': l.item,
        'qty': l.qty,
        'rate': l.rate,
      }).toList(),
      'status': 'Draft',
    };

    PurchaseOrder? result;
    if (isEditing && editingPOId != null) {
      result = await PurchaseOrderService.updatePurchaseOrder(editingPOId!, data);
    } else {
      result = await PurchaseOrderService.createPurchaseOrder(data);
    }

    setState(() => isSaving = false);

    if (result != null) {
      Navigator.pop(context, result);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save purchase order"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    return Dialog(
      child: Container(
        width: isMobile ? screenWidth * 0.95 : 500,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(isEditing ? "Edit Purchase Order" : "Create Purchase Order",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                const SizedBox(height: 10),
                Text("PO Number: $poNumber", textAlign: TextAlign.center),
                const SizedBox(height: 8),

                // Supplier fields
                TextField(
                  controller: supplierController,
                  decoration: const InputDecoration(
                    labelText: "Supplier Name",
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    labelStyle: TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: "Supplier Email",
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    labelStyle: TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: "Supplier Phone",
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    labelStyle: TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(height: 16),

                // Line entry row with item dropdown
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 100),
                        child: isLoadingItems
                            ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator()))
                            : DropdownButtonFormField<Item>(
                                value: selectedItem,
                                hint: const Text("Select Item"),
                                isExpanded: true,
                                items: items.map((item) {
                                  return DropdownMenuItem<Item>(
                                    value: item,
                                    child: Text(item.name),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedItem = value;
                                    // ❌ Do NOT autofill rate – user enters manually
                                  });
                                },
                                decoration: const InputDecoration(
                                  labelText: "Item",
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 60),
                        child: TextField(
                          controller: qtyController,
                          decoration: const InputDecoration(
                            labelText: "Qty",
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                            labelStyle: TextStyle(fontSize: 12),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 70),
                        child: TextField(
                          controller: rateController,
                          decoration: const InputDecoration(
                            labelText: "Rate",
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                            labelStyle: TextStyle(fontSize: 12),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: _addLine,
                      icon: const Icon(Icons.add),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Lines list
                if (lines.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: lines.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final l = lines[i];
                        return ListTile(
                          dense: true,
                          title: Text(l.item),
                          subtitle: Text("Qty: ${l.qty}, Rate: ₹${l.rate}"),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                            onPressed: () => _removeLine(i),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 10),
                Text("Total: ₹${total.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                      child: isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text("Save"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ================= DETAILS POPUP (unchanged) =================
class PODetailsPopup extends StatelessWidget {
  final PurchaseOrder order;
  final VoidCallback onUpdate;
  const PODetailsPopup({super.key, required this.order, required this.onUpdate});

  Future<void> _sendEmail(BuildContext context) async {
    try {
      final emailBody = POEmailService.buildEmailBody(order);
      final emailSubject = 'Purchase Order Created: ${order.number}';

      await POEmailService.sendEmail(
        supplierEmail: order.supplierEmail,
        order: order,
      );

      final logSaved = await PurchaseOrderService.saveEmailLog(
        order.poId,
        order.supplierEmail,
        emailSubject,
        emailBody,
      );

      if (logSaved && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email sent and logged"), backgroundColor: Colors.green),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email sent but log failed"), backgroundColor: Colors.orange),
        );
      }

      onUpdate();
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send email: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatDate(String dateStr) {
    try {
      final DateTime parsed = DateTime.parse(dateStr);
      return '${parsed.day.toString().padLeft(2, '0')}-'
          '${parsed.month.toString().padLeft(2, '0')}-'
          '${parsed.year}';
    } catch (_) {
      final RegExp exp = RegExp(r'^(\d{2}).*?(\d{2})-(\d{4})$');
      final match = exp.firstMatch(dateStr);
      if (match != null) {
        return '${match.group(1)}-${match.group(2)}-${match.group(3)}';
      }
      if (dateStr.contains('-')) {
        final parts = dateStr.split('-');
        if (parts.length == 3) {
          if (parts[0].length == 4) {
            return '${parts[2].padLeft(2, '0')}-${parts[1].padLeft(2, '0')}-${parts[0]}';
          }
          return dateStr;
        }
      } else if (dateStr.contains('/')) {
        final parts = dateStr.split('/');
        if (parts[2].length == 4) {
          return '${parts[0].padLeft(2, '0')}-${parts[1].padLeft(2, '0')}-${parts[2]}';
        }
      }
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Dialog(
      child: Container(
        width: screenWidth > 600 ? 500 : screenWidth * 0.95,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(order.number, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(order.supplier),
              Text(order.supplierEmail),
              Text(_formatDate(order.date)),
              const SizedBox(height: 10),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: order.lines.length,
                  itemBuilder: (_, i) {
                    final l = order.lines[i];
                    return ListTile(
                      dense: true,
                      title: Text(l.item),
                      subtitle: Text("Qty: ${l.qty}, Rate: ₹${l.rate}"),
                      trailing: Text("₹${l.total}"),
                    );
                  },
                ),
              ),
              Text("Total ₹${order.total}", style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => _sendEmail(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Send Email"),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}