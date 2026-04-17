import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../services/api/grn_service.dart';
import '../models/grn.dart';
import '../services/api/purchase_order_service.dart';
import '../models/purchase_order.dart';

/// ================= GRN PAGE =================
class GRNPage extends StatefulWidget {
  const GRNPage({super.key});

  @override
  State<GRNPage> createState() => _GRNPageState();
}

class _GRNPageState extends State<GRNPage> {
  List<GRN> grns = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadGRNs();
  }

  Future<void> _loadGRNs() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      final data = await GRNService.getGRNs();
      setState(() {
        grns = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load GRNs: $e';
        isLoading = false;
      });
    }
  }

  int get totalGRN => grns.length;

  int get todayGRN {
    final now = DateTime.now();
    int count = 0;
    for (var g in grns) {
      try {
        final grnDate = DateTime.parse(g.date);
        if (grnDate.year == now.year &&
            grnDate.month == now.month &&
            grnDate.day == now.day) {
          count++;
        }
      } catch (e) {
        // ignore
      }
    }
    return count;
  }

  int get pendingInspection =>
      grns.where((g) => g.status == "Pending").length;
  double get totalAmount => grns.fold(0, (sum, g) => sum + g.total);

  void _openCreateGRN() async {
    final result = await showDialog(
      context: context,
      builder: (context) => const CreateGRNPopup(),
    );

    if (result != null &&
        result is Map &&
        result.containsKey('grn') &&
        result.containsKey('images')) {
      final grn = result['grn'] as GRN;
      final images = result['images'] as List<String?>;

      for (int i = 0; i < grn.lines.length; i++) {
        if (i < images.length && images[i] != null) {
          grn.lines[i].imageBase64 = images[i];
        }
      }

      final created = await GRNService.createGRN(grn.toJson());
      if (created != null && mounted) {
        setState(() {
          grns.add(created);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Failed to save GRN"),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _openDetails(GRN grn) async {
    await showDialog(
      context: context,
      builder: (context) => GRNDetailsPopup(
        grn: grn,
        onUpdate: () async {
          await _loadGRNs();
        },
      ),
    );
  }

  Future<void> sendEmailJS(GRN grn) async {
    const serviceId = 'service_tyib3jm';
    const templateId = 'template_l211rnf';
    const publicKey = 'mBwEamqFeXxFIJPN1';

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    final itemsString = grn.lines
        .map((e) =>
            "${e.item} | Ordered: ${e.orderedQty} | Received: ${e.receivedQty} | Damaged: ${e.damageQty} | Rate: ₹${e.rate} | Unit: ${e.unit} | Total: ₹${e.total}")
        .join("\n");

    final emailBody = '''
Hello,

A new GRN has been created.

GRN Number: ${grn.grnNumber}
Date: ${grn.date}
PO Number: ${grn.poNumber}
Supplier: ${grn.supplier}
Invoice No: ${grn.invoiceNo.isEmpty ? 'Pending' : grn.invoiceNo}
Remarks: ${grn.remarks}

Items:
$itemsString

Total Amount: ₹${grn.total.toStringAsFixed(0)}

Thank you.
''';

    final emailSubject = "GRN Details: ${grn.grnNumber}";

    try {
      final response = await http.post(url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'service_id': serviceId,
            'template_id': templateId,
            'user_id': publicKey,
            'template_params': {
              'to_email': grn.supplier,
              'grn_number': grn.grnNumber,
              'po_number': grn.poNumber,
              'invoice_no': grn.invoiceNo.isEmpty ? 'Pending' : grn.invoiceNo,
              'supplier': grn.supplier,
              'grn_date': grn.date,
              'items': itemsString,
              'total_amount': grn.total.toStringAsFixed(0),
              'subject': emailSubject,
              'reply_to': 'admin@example.com',
            }
          }));

      if (response.statusCode == 200) {
        final logSaved = await GRNService.saveEmailLog(
          grn.id,
          grn.supplier,
          emailSubject,
          emailBody,
        );

        if (logSaved && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Email sent and logged"),
                backgroundColor: Colors.green),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Email sent but log failed"),
                backgroundColor: Colors.redAccent),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Email failed: ${response.body}")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Error sending email: $e"),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget summaryCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        height: 90,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(title,
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  // Desktop table header
  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Expanded(child: Text("GRN No", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text("Date", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text("PO No", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text("Supplier", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text("Invoice", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text("Total", style: TextStyle(fontWeight: FontWeight.bold))),
          Icon(Icons.email), // header for email column
        ],
      ),
    );
  }

  // Desktop table row
  Widget _buildTableRow(GRN g) {
    return GestureDetector(
      onTap: () => _openDetails(g),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Row(
          children: [
            Expanded(child: Text(g.grnNumber)),
            Expanded(child: Text(g.date)),
            Expanded(child: Text(g.poNumber)),
            Expanded(child: Text(g.supplier)),
            Expanded(child: Text(g.invoiceNo.isEmpty ? "Pending" : g.invoiceNo)),
            Expanded(child: Text("₹${g.total.toStringAsFixed(0)}")),
            IconButton(
              icon: const Icon(Icons.email),
              onPressed: () => sendEmailJS(g),
            ),
          ],
        ),
      ),
    );
  }

  // Mobile card (ExpansionTile)
  Widget _buildMobileCard(GRN g) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: ExpansionTile(
        title: Text(
          g.grnNumber,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Supplier: ${g.supplier}',
          style: const TextStyle(fontSize: 12), // smaller email font
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('₹${g.total.toStringAsFixed(0)}'),
            IconButton(
              icon: const Icon(Icons.email, size: 20),
              onPressed: () => sendEmailJS(g),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('Date', g.date),
                _detailRow('PO Number', g.poNumber),
                _detailRow('Invoice',
                    g.invoiceNo.isEmpty ? 'Pending' : g.invoiceNo),
                _detailRow('Remarks', g.remarks),
                const Divider(),
                const Text('Items', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...g.lines.map((line) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(line.item,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            'Ord: ${line.orderedQty}  Rec: ${line.receivedQty}  Dam: ${line.damageQty} ${line.unit}',
                          ),
                          Text(
                            '₹${line.rate}/${line.unit}  ₹${line.total.toStringAsFixed(0)}',
                          ),
                        ],
                      ),
                    )),
                const Divider(),
                _detailRow('Total Amount', '₹${g.total.toStringAsFixed(0)}',
                    isBold: true),
                const SizedBox(height: 8),
                Center(
                  child: ElevatedButton(
                    onPressed: () => _openDetails(g),
                    child: const Text('View Full Details'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
            ),
          ),
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
        title: const Text("GRN Dashboard"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGRNs,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateGRN,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Summary cards always in one row
            Row(
              children: [
                summaryCard("Total GRN", "$totalGRN", Colors.blue),
                const SizedBox(width: 4),
                summaryCard("Today", "$todayGRN", Colors.orange),
                const SizedBox(width: 4),
                summaryCard("Pending", "$pendingInspection", Colors.red),
                const SizedBox(width: 4),
                summaryCard(
                    "Amount", "₹${totalAmount.toStringAsFixed(0)}", Colors.green),
              ],
            ),
            const SizedBox(height: 16),

            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (errorMessage.isNotEmpty)
              Center(
                child: Column(
                  children: [
                    Text(errorMessage,
                        style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 10),
                    ElevatedButton(
                        onPressed: _loadGRNs, child: const Text("Retry")),
                  ],
                ),
              )
            else
              Expanded(
                child: isDesktop
                    ? Column(
                        children: [
                          _buildTableHeader(),
                          const SizedBox(height: 10),
                          Expanded(
                            child: ListView.builder(
                              itemCount: grns.length,
                              itemBuilder: (_, i) => _buildTableRow(grns[i]),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        itemCount: grns.length,
                        itemBuilder: (_, i) => _buildMobileCard(grns[i]),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

/// ================= CREATE GRN POPUP (RESPONSIVE) =================
class CreateGRNPopup extends StatefulWidget {
  const CreateGRNPopup({super.key});

  @override
  State<CreateGRNPopup> createState() => _CreateGRNPopupState();
}

class _CreateGRNPopupState extends State<CreateGRNPopup> {
  final supplierController = TextEditingController();
  final poController = TextEditingController();
  final invoiceController = TextEditingController();
  final remarksController = TextEditingController();

  // Controllers for manual item entry (used in both layouts)
  final itemController = TextEditingController();
  final orderedController = TextEditingController();
  final receivedController = TextEditingController();
  final damageController = TextEditingController();
  final rateController = TextEditingController();
  final unitController = TextEditingController();

  String? selectedImagePath;
  String? selectedImageName;

  final List<GRNLine> lines = [];
  final List<String?> itemImages = [];

  // PO fetch state
  bool _isPoFetched = false;
  List<PurchaseLine>? _fetchedPoLines;

  String get grnNumber => "GRN${DateTime.now().millisecondsSinceEpoch}";

  // ---------- Image picker methods ----------
  Future<void> _pickImage() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Image"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text("Upload from Computer"),
              onTap: () async {
                Navigator.pop(context);
                await _uploadFromComputer();
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text("Enter Image URL"),
              onTap: () {
                Navigator.pop(context);
                _enterImageUrl();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadFromComputer() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result != null) {
        final file = result.files.first;
        setState(() {
          selectedImagePath = base64Encode(file.bytes!);
          selectedImageName = file.name;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Image selected: ${file.name}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking image: $e")),
      );
    }
  }

  void _enterImageUrl() {
    showDialog(
      context: context,
      builder: (context) {
        final urlController = TextEditingController();
        return AlertDialog(
          title: const Text("Enter Image URL"),
          content: TextField(
            controller: urlController,
            decoration: const InputDecoration(
              hintText: "https://example.com/image.jpg",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (urlController.text.isNotEmpty) {
                  setState(() {
                    selectedImagePath = urlController.text;
                    selectedImageName = "URL Image";
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  // ---------- PO Fetch ----------
  Future<void> _fetchPO() async {
    final poNumber = poController.text.trim();
    if (poNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a PO number')),
      );
      return;
    }

    setState(() {
      _isPoFetched = false;
      _fetchedPoLines = null;
    });

    final po = await PurchaseOrderService.getPurchaseOrderByNumber(poNumber);
    if (po == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PO $poNumber not found')),
        );
      }
      return;
    }

    // Convert PurchaseLine to GRNLine with orderedQty and empty received/damage/rate/image
    final newLines = po.lines.map((pl) => GRNLine(
      item: pl.item,
      orderedQty: pl.qty,
      receivedQty: 0,
      damageQty: 0,
      rate: 0.0,
      unit: 'pcs', // you might want to store unit in PurchaseLine; if not, default
      imageBase64: null,
    )).toList();

    setState(() {
      _fetchedPoLines = po.lines;          // keep original if needed
      lines.clear();                        // replace existing lines
      lines.addAll(newLines);               // add fetched lines
      itemImages.clear();
      itemImages.addAll(List.filled(newLines.length, null));
      _isPoFetched = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PO $poNumber loaded with ${newLines.length} items')),
    );
  }

  // ---------- Image per line ----------
  Future<void> _pickImageForIndex(int index) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result != null) {
        final bytes = result.files.first.bytes;
        if (bytes != null) {
          setState(() {
            itemImages[index] = base64Encode(bytes);
            lines[index].imageBase64 = base64Encode(bytes);
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking image: $e")),
      );
    }
  }

  Widget _buildSmallImage(String imageBase64) {
    if (imageBase64.startsWith('http')) {
      return Image.network(imageBase64, width: 40, height: 40, fit: BoxFit.cover);
    } else {
      try {
        return Image.memory(base64Decode(imageBase64), width: 40, height: 40, fit: BoxFit.cover);
      } catch (e) {
        return const Icon(Icons.error, size: 30);
      }
    }
  }

  // ---------- Manual line addition ----------
  void _addLine() {
    if (itemController.text.isEmpty ||
        orderedController.text.isEmpty ||
        receivedController.text.isEmpty ||
        damageController.text.isEmpty ||
        rateController.text.isEmpty) {
      return;
    }

    setState(() {
      lines.add(GRNLine(
        item: itemController.text,
        orderedQty: int.parse(orderedController.text),
        receivedQty: int.parse(receivedController.text),
        damageQty: int.parse(damageController.text),
        rate: double.parse(rateController.text),
        unit: unitController.text.isEmpty ? "pcs" : unitController.text,
        imageBase64: selectedImagePath,
      ));
      itemImages.add(selectedImagePath);

      // Clear for next item
      itemController.clear();
      orderedController.clear();
      receivedController.clear();
      damageController.clear();
      rateController.clear();
      unitController.clear();
      selectedImagePath = null;
      selectedImageName = null;
    });
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: itemController,
                decoration: const InputDecoration(
                    labelText: 'Item Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: orderedController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Ordered Qty', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: receivedController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Received Qty', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: damageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Damage Qty', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: rateController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Rate (₹)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: unitController,
                decoration: const InputDecoration(
                    labelText: 'Unit (kg/ltr/pcs)',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: Text(selectedImageName ?? 'Add Image'),
              ),
              if (selectedImagePath != null) ...[
                const SizedBox(height: 8),
                _buildImagePreview(),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Clear temporary fields
              itemController.clear();
              orderedController.clear();
              receivedController.clear();
              damageController.clear();
              rateController.clear();
              unitController.clear();
              selectedImagePath = null;
              selectedImageName = null;
              Navigator.pop(ctx);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _addLine();
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _removeLine(int index) {
    setState(() {
      lines.removeAt(index);
      itemImages.removeAt(index);
    });
  }

  void _save() {
    final grn = GRN(
      id: 0,
      grnNumber: grnNumber,
      date: DateTime.now().toString().split(' ')[0],
      poNumber: poController.text,
      supplier: supplierController.text,
      invoiceNo: invoiceController.text,
      remarks: remarksController.text,
      lines: lines,
    );
    Navigator.pop(context, {
      'grn': grn,
      'images': itemImages,
    });
  }

  Widget _buildImagePreview() {
    if (selectedImagePath == null) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }
    if (selectedImagePath!.startsWith('http')) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: DecorationImage(
            image: NetworkImage(selectedImagePath!),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      try {
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: MemoryImage(base64Decode(selectedImagePath!)),
              fit: BoxFit.cover,
            ),
          ),
        );
      } catch (e) {
        return Container(
          width: 60,
          height: 60,
          color: Colors.grey[200],
          child: const Icon(Icons.error, color: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final isDesktop = width > 600;

    return Dialog(
      child: Container(
        width: isDesktop ? 1100 : double.infinity,
        constraints: BoxConstraints(maxHeight: height * 0.9),
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Create GRN",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text("GRN No: $grnNumber",
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 15),

              // Header fields with Fetch PO button
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    TextField(
                        controller: supplierController,
                        decoration: const InputDecoration(
                          labelText: "Supplier Email",
                          border: OutlineInputBorder(),
                        )),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: poController,
                            decoration: const InputDecoration(
                              labelText: "PO Number",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _fetchPO,
                          child: const Text('Fetch PO'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                        controller: invoiceController,
                        decoration: const InputDecoration(
                          labelText: "Invoice No (Pending if unknown)",
                          border: OutlineInputBorder(),
                        )),
                    const SizedBox(height: 10),
                    TextField(
                        controller: remarksController,
                        decoration: const InputDecoration(
                          labelText: "Remarks",
                          border: OutlineInputBorder(),
                        )),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Item entry section – responsive
              if (isDesktop) ...[
                // Desktop: Table for fetched lines + manual add row
                if (lines.isNotEmpty) ...[
                  const Text("Items from PO",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  // Table header
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Expanded(flex: 2, child: Text("Item", style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(child: Text("Ordered", style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(child: Text("Received", style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(child: Text("Damage", style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(child: Text("Rate", style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(child: Text("Unit", style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(flex: 1, child: Text("Image", style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(flex: 1, child: SizedBox()), // for delete button
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // List of fetched lines with editable fields
                  ...lines.asMap().entries.map((entry) {
                    int idx = entry.key;
                    GRNLine line = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Expanded(flex: 2, child: Text(line.item)),
                          Expanded(child: Text(line.orderedQty.toString())),
                          Expanded(
                            child: TextField(
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: "Received",
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (val) => line.receivedQty = int.tryParse(val) ?? 0,
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: "Damage",
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (val) => line.damageQty = int.tryParse(val) ?? 0,
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: "Rate",
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (val) => line.rate = double.tryParse(val) ?? 0,
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: "Unit",
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (val) => line.unit = val,
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: GestureDetector(
                              onTap: () => _pickImageForIndex(idx),
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: itemImages[idx] == null
                                      ? const Icon(Icons.image, color: Colors.grey)
                                      : _buildSmallImage(itemImages[idx]!),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeLine(idx),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 16),
                ],

                // const Text("Add Extra Item",
                //     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                // const SizedBox(height: 10),

                // // Manual add row (unchanged)
                // Container(
                //   padding: const EdgeInsets.all(12),
                //   decoration: BoxDecoration(
                //     color: Colors.blue[50],
                //     borderRadius: BorderRadius.circular(8),
                //     border: Border.all(color: Colors.blue.shade200),
                //   ),
                //   child: Column(
                //     children: [
                //       const Row(
                //         children: [
                //           Expanded(flex: 2, child: Text("Item", style: TextStyle(fontWeight: FontWeight.bold))),
                //           Expanded(child: Text("Ordered", style: TextStyle(fontWeight: FontWeight.bold))),
                //           Expanded(child: Text("Received", style: TextStyle(fontWeight: FontWeight.bold))),
                //           Expanded(child: Text("Damage", style: TextStyle(fontWeight: FontWeight.bold))),
                //           Expanded(child: Text("Rate", style: TextStyle(fontWeight: FontWeight.bold))),
                //           Expanded(child: Text("Unit", style: TextStyle(fontWeight: FontWeight.bold))),
                //           Expanded(flex: 1, child: Text("Image", style: TextStyle(fontWeight: FontWeight.bold))),
                //           Expanded(flex: 1, child: Text("Action", style: TextStyle(fontWeight: FontWeight.bold))),
                //         ],
                //       ),
                //       const SizedBox(height: 10),
                //       Row(
                //         children: [
                //           Expanded(flex: 2, child: TextField(
                //             controller: itemController,
                //             decoration: const InputDecoration(
                //               hintText: "Item name",
                //               border: OutlineInputBorder(),
                //             ),
                //           )),
                //           Expanded(child: TextField(
                //             controller: orderedController,
                //             keyboardType: TextInputType.number,
                //             decoration: const InputDecoration(
                //               hintText: "Qty",
                //               border: OutlineInputBorder(),
                //             ),
                //           )),
                //           Expanded(child: TextField(
                //             controller: receivedController,
                //             keyboardType: TextInputType.number,
                //             decoration: const InputDecoration(
                //               hintText: "Qty",
                //               border: OutlineInputBorder(),
                //             ),
                //           )),
                //           Expanded(child: TextField(
                //             controller: damageController,
                //             keyboardType: TextInputType.number,
                //             decoration: const InputDecoration(
                //               hintText: "Qty",
                //               border: OutlineInputBorder(),
                //             ),
                //           )),
                //           Expanded(child: TextField(
                //             controller: rateController,
                //             keyboardType: TextInputType.number,
                //             decoration: const InputDecoration(
                //               hintText: "₹",
                //               border: OutlineInputBorder(),
                //             ),
                //           )),
                //           Expanded(child: TextField(
                //             controller: unitController,
                //             decoration: const InputDecoration(
                //               hintText: "kg/ltr/pcs",
                //               border: OutlineInputBorder(),
                //             ),
                //           )),
                //           Expanded(
                //             flex: 1,
                //             child: GestureDetector(
                //               onTap: _pickImage,
                //               child: Container(
                //                 height: 50,
                //                 decoration: BoxDecoration(
                //                   border: Border.all(color: Colors.grey),
                //                   borderRadius: BorderRadius.circular(8),
                //                 ),
                //                 child: Center(
                //                   child: selectedImagePath == null
                //                       ? const Icon(Icons.image, color: Colors.grey)
                //                       : _buildImagePreview(),
                //                 ),
                //               ),
                //             ),
                //           ),
                //           Expanded(
                //             flex: 1,
                //             child: IconButton(
                //               onPressed: _addLine,
                //               icon: const Icon(Icons.add_circle, color: Colors.blue, size: 30),
                //             ),
                //           ),
                //         ],
                //       ),
                //       if (selectedImageName != null)
                //         Padding(
                //           padding: const EdgeInsets.only(top: 8),
                //           child: Text("Selected: $selectedImageName",
                //               style: const TextStyle(fontSize: 12, color: Colors.grey)),
                //         ),
                //     ],
                //   ),
                // ),
              ] else ...[
                // Mobile layout
                Column(
                  children: [
                    if (lines.isNotEmpty) ...[
                      const Text('Items from PO',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: lines.length,
                        itemBuilder: (context, idx) {
                          final line = lines[idx];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(line.item, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('Ordered: ${line.orderedQty}'),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            labelText: 'Received',
                                            border: OutlineInputBorder(),
                                            isDense: true,
                                          ),
                                          onChanged: (val) => line.receivedQty = int.tryParse(val) ?? 0,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            labelText: 'Damage',
                                            border: OutlineInputBorder(),
                                            isDense: true,
                                          ),
                                          onChanged: (val) => line.damageQty = int.tryParse(val) ?? 0,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            labelText: 'Rate',
                                            border: OutlineInputBorder(),
                                            isDense: true,
                                          ),
                                          onChanged: (val) => line.rate = double.tryParse(val) ?? 0,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          decoration: const InputDecoration(
                                            labelText: 'Unit',
                                            border: OutlineInputBorder(),
                                            isDense: true,
                                          ),
                                          onChanged: (val) => line.unit = val,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => _pickImageForIndex(idx),
                                          child: Container(
                                            height: 50,
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Center(
                                              child: itemImages[idx] == null
                                                  ? const Text('Add Image')
                                                  : _buildSmallImage(itemImages[idx]!),
                                            ),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _removeLine(idx),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _showAddItemDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Extra Item'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 20),

              // List of added items (common) – for desktop it's already shown in the table,
              // but we can keep this as a summary (optional). For mobile it's already handled.
              // We'll keep it only for desktop as a fallback, but it might duplicate. Let's conditionally show only if no fetched lines.
              if (!isDesktop && lines.isNotEmpty) ...[
                const Divider(),
                const Text('Added Items',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: lines.length,
                  itemBuilder: (context, index) {
                    final line = lines[index];
                    final image = itemImages[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: image != null
                            ? (image.startsWith('http')
                                ? Image.network(image,
                                    width: 40, height: 40, fit: BoxFit.cover)
                                : Image.memory(base64Decode(image),
                                    width: 40, height: 40, fit: BoxFit.cover))
                            : const Icon(Icons.image_not_supported, size: 40),
                        title: Text(line.item),
                        subtitle: Text(
                            'Ordered: ${line.orderedQty} | Rec: ${line.receivedQty} | Damage: ${line.damageQty} | ₹${line.rate}/${line.unit}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              lines.removeAt(index);
                              itemImages.removeAt(index);
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
              ],

              // Save button (common)
              Center(
                child: ElevatedButton(
                  onPressed: lines.isEmpty ? null : _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  ),
                  child: const Text("Save GRN", style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ================= DETAILS POPUP =================
class GRNDetailsPopup extends StatefulWidget {
  final GRN grn;
  final VoidCallback? onUpdate;

  const GRNDetailsPopup({super.key, required this.grn, this.onUpdate});

  @override
  State<GRNDetailsPopup> createState() => _GRNDetailsPopupState();
}

class _GRNDetailsPopupState extends State<GRNDetailsPopup> {
  void _updateLine(GRNLine line, int received, int damaged) {
    setState(() {
      line.receivedQty = received;
      line.damageQty = damaged;
    });
    widget.onUpdate?.call();
  }

  Widget _buildItemImage(String? imageBase64) {
    if (imageBase64 == null) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }

    if (imageBase64.startsWith('http')) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: DecorationImage(
            image: NetworkImage(imageBase64),
            fit: BoxFit.cover,
            onError: (exception, stackTrace) {},
          ),
        ),
      );
    } else {
      try {
        return Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: MemoryImage(base64Decode(imageBase64)),
              fit: BoxFit.cover,
            ),
          ),
        );
      } catch (e) {
        return Container(
          width: 50,
          height: 50,
          color: Colors.grey[200],
          child: const Icon(Icons.error, color: Colors.red),
        );
      }
    }
  }

  Future<void> _approveWithPoCheck() async {
    final po = await PurchaseOrderService.getPurchaseOrderByNumber(widget.grn.poNumber);
    if (po == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot approve: PO does not exist'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // PO exists, proceed with approval
    final success = await GRNService.approveGRN(widget.grn.id);
    if (success) {
      widget.onUpdate?.call();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("GRN ${widget.grn.grnNumber} approved successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Approval failed"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 700,
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header details
            Text(widget.grn.grnNumber,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildDetailRow('Supplier', widget.grn.supplier),
            _buildDetailRow('PO', widget.grn.poNumber),
            _buildDetailRow('Invoice',
                widget.grn.invoiceNo.isEmpty ? 'Pending' : widget.grn.invoiceNo),
            _buildDetailRow('Remarks', widget.grn.remarks),
            const Divider(height: 24),

            // Items list
            Expanded(
              child: ListView.builder(
                itemCount: widget.grn.lines.length,
                itemBuilder: (context, index) {
                  final line = widget.grn.lines[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Item name and image
                          Row(
                            children: [
                              _buildItemImage(line.imageBase64),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  line.item,
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Item details in chips
                          Wrap(
                            spacing: 16,
                            runSpacing: 8,
                            children: [
                              _buildInfoChip('Ordered', line.orderedQty.toString()),
                              _buildInfoChip('Received', line.receivedQty.toString()),
                              _buildInfoChip('Damaged', line.damageQty.toString()),
                              _buildInfoChip('Rate', '₹${line.rate}'),
                              _buildInfoChip('Unit', line.unit),
                              _buildInfoChip('Total', '₹${line.total.toStringAsFixed(0)}'),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Plus/minus buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle, color: Colors.red),
                                onPressed: () {
                                  if (line.receivedQty > 0) {
                                    _updateLine(line, line.receivedQty - 1,
                                        line.damageQty + 1);
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.add_circle, color: Colors.green),
                                onPressed: () {
                                  if (line.damageQty > 0) {
                                    _updateLine(line, line.receivedQty + 1,
                                        line.damageQty - 1);
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Total and approve button
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('₹${widget.grn.total.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Center(
              child: ElevatedButton(
                onPressed: _approveWithPoCheck,
                child: const Text("Approve"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text('$label:',
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('$label: $value'),
    );
  }
}