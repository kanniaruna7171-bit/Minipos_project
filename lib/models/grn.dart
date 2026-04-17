class GRN {
  final int id;               // GRNId from backend
  final String grnNumber;
  final String date;
  final String poNumber;
  final String supplier;      // supplier email
  String invoiceNo;
  final List<GRNLine> lines;
  final String remarks;
  String status;

  GRN({
    required this.id,
    required this.grnNumber,
    required this.date,
    required this.poNumber,
    required this.supplier,
    required this.invoiceNo,
    required this.lines,
    required this.remarks,
    this.status = "Pending",
  });

  double get total => lines.fold(0, (sum, l) => sum + (l.receivedQty * l.rate));

  factory GRN.fromJson(Map<String, dynamic> json) {
    String rawDate = json['date'] ?? '';
    if (rawDate.isEmpty) {
      rawDate = DateTime.now().toIso8601String().split('T')[0]; // fallback
    }
    return GRN(
      id: json['grnId'] ?? json['GRNId'] ?? 0,
      grnNumber: json['grnNumber'] ?? json['GRNNumber'] ?? '',
      date: rawDate,
      poNumber: json['poNumber'] ?? json['PONumber'] ?? '',
      supplier: json['supplier'] ?? '',
      invoiceNo: json['invoiceNo'] ?? json['InvoiceNo'] ?? '',
      remarks: json['remarks'] ?? json['Remarks'] ?? '',
      status: json['status'] ?? 'Pending',
      lines: (json['lines'] as List?)?.map((l) => GRNLine(
        itemId: l['itemId'],                     // ← added
        item: l['itemName'] ?? l['item'] ?? '',
        orderedQty: l['orderedQty'] ?? 0,
        receivedQty: l['receivedQty'] ?? 0,
        damageQty: l['damageQty'] ?? 0,
        rate: (l['rate'] ?? 0).toDouble(),
        unit: l['unit'] ?? l['uom'] ?? 'pcs',
        imageBase64: l['imageBase64'],
      )).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'grnNumber': grnNumber,
      'date': date,
      'poNumber': poNumber,
      'supplier': supplier,
      'invoiceNo': invoiceNo,
      'remarks': remarks,
      'lines': lines.map((l) => {
        'itemId': l.itemId,                       // ← added
        'item': l.item,
        'orderedQty': l.orderedQty,
        'receivedQty': l.receivedQty,
        'damageQty': l.damageQty,
        'rate': l.rate,
        'unit': l.unit,
        'imageBase64': l.imageBase64,
      }).toList(),
    };
  }
}

class GRNLine {
  final int? itemId;            // ← added
  final String item;
  final int orderedQty;
  int receivedQty;
  int damageQty;
  double rate;                  // mutable
  String unit;                  // mutable
  String? imageBase64;

  GRNLine({
    this.itemId,                 // ← added
    required this.item,
    required this.orderedQty,
    required this.receivedQty,
    required this.damageQty,
    required this.rate,
    required this.unit,
    this.imageBase64,
  });

  double get total => receivedQty * rate;
}