class ItemPriceHistory {
  final String priceId;
  final String itemId;
  final String itemName;  // New field
  final DateTime effectiveAt;
  final double purchaseCost;
  final double sellingPrice;
  final double marginPercent;
  final String changedBy;

  ItemPriceHistory({
    required this.priceId,
    required this.itemId,
    required this.itemName,
    required this.effectiveAt,
    required this.purchaseCost,
    required this.sellingPrice,
    required this.marginPercent,
    required this.changedBy,
  });

  factory ItemPriceHistory.fromJson(Map<String, dynamic> json) {
    return ItemPriceHistory(
      priceId: json['id'].toString(), // backend uses 'id'
      itemId: json['itemId'].toString(),
      itemName: json['itemName'] ?? 'Unknown',
      effectiveAt: DateTime.parse(json['effectiveAt']),
      purchaseCost: (json['purchaseCost'] as num).toDouble(),
      sellingPrice: (json['sellingPrice'] as num).toDouble(),
      marginPercent: (json['marginPercent'] as num).toDouble(),
      changedBy: json['changedBy'] ?? 'System', // backend may not have this
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': priceId,
      'itemId': itemId,
      'effectiveAt': effectiveAt.toIso8601String(),
      'purchaseCost': purchaseCost,
      'sellingPrice': sellingPrice,
      'marginPercent': marginPercent,
      'changedBy': changedBy,
    };
  }
}