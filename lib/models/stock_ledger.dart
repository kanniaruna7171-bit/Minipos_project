class StockLedgerEntry {
  final int id;
  final DateTime txnDate;
  final String txnType;
  final int itemId;
  final int qtyIn;
  final int qtyOut;
  final double rate;
  String? itemName; // Will be filled later from onhand data

  StockLedgerEntry({
    required this.id,
    required this.txnDate,
    required this.txnType,
    required this.itemId,
    required this.qtyIn,
    required this.qtyOut,
    required this.rate,
    this.itemName,
  });

  factory StockLedgerEntry.fromJson(Map<String, dynamic> json) {
    return StockLedgerEntry(
      id: json['id'] ?? 0,
      txnDate: DateTime.parse(json['txnDate']),
      txnType: json['txnType'] ?? '',
      itemId: json['itemId'] ?? 0,
      qtyIn: json['qtyIn'] ?? 0,
      qtyOut: json['qtyOut'] ?? 0,
      rate: (json['rate'] ?? 0).toDouble(),
    );
  }
}