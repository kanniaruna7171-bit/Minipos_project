class PurchaseOrder {
  final int poId;
  final String number;
  final String date;
  final String supplier;
  final String supplierEmail;
  final String supplierPhone;
  final List<PurchaseLine> lines;
  final double total;
  String status;

  PurchaseOrder({
    required this.poId,
    required this.number,
    required this.date,
    required this.supplier,
    required this.supplierEmail,
    required this.supplierPhone,
    required this.lines,
    required this.total,
    this.status = "Pending",
  });

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    // Try multiple possible keys for number and date
    final number = json['ponumber'] ?? 
                   json['PONumber'] ?? 
                   json['poNumber'] ?? 
                   json['PONumber'] ?? 
                   '';
    
    final date = json['podate'] ?? 
                 json['PODate'] ?? 
                 json['poDate'] ?? 
                 json['PODate'] ?? 
                 '';

    final poId = json['poId'] ?? json['POId'] ?? 0;
    final status = json['status'] ?? 'Pending';

    // Supplier handling
    String supplier = '';
    String supplierEmail = '';
    String supplierPhone = '';
    if (json['supplier'] is Map) {
      final supplierMap = json['supplier'] as Map<String, dynamic>;
      supplier = supplierMap['name'] ?? supplierMap['supplierName'] ?? '';
      supplierEmail = supplierMap['email'] ?? '';
      supplierPhone = supplierMap['phone'] ?? supplierMap['supplierPhone'] ?? '';
    } else {
      supplier = json['supplier'] ?? '';
      supplierEmail = json['supplierEmail'] ?? '';
      supplierPhone = json['supplierPhone'] ?? '';
    }

    // Lines parsing – now includes itemId
    List<PurchaseLine> lines = [];
    if (json['lines'] != null) {
      lines = (json['lines'] as List).map((l) {
        return PurchaseLine(
          itemId: l['itemId'], // may be null
          item: l['itemName'] ?? l['item'] ?? '',
          qty: l['orderedQty'] ?? l['qty'] ?? 0,
          rate: (l['rate'] ?? 0).toDouble(),
        );
      }).toList();
    }

    double total = (json['total'] ?? 0).toDouble();
    if (total == 0 && lines.isNotEmpty) {
      total = lines.fold(0, (sum, l) => sum + l.total);
    }

    return PurchaseOrder(
      poId: poId,
      number: number,
      date: date,
      supplier: supplier,
      supplierEmail: supplierEmail,
      supplierPhone: supplierPhone,
      lines: lines,
      total: total,
      status: status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ponumber': number,
      'supplierName': supplier,
      'supplierEmail': supplierEmail,
      'supplierPhone': supplierPhone,
      'lines': lines.map((l) => {
        'itemId': l.itemId,       // include itemId
        'item': l.item,
        'qty': l.qty,
        'rate': l.rate,
      }).toList(),
      'status': status,
    };
  }
}

class PurchaseLine {
  final int? itemId;      // added
  final String item;
  final int qty;
  final double rate;

  PurchaseLine({
    this.itemId,          // optional
    required this.item,
    required this.qty,
    required this.rate,
  });

  double get total => qty * rate;
}