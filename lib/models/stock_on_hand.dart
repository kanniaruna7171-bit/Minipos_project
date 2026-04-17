class StockOnHand {
  final int itemId;
  final String itemName;
  final int qtyOnHand;
  final double currentSellingPrice;

  StockOnHand({
    required this.itemId,
    required this.itemName,
    required this.qtyOnHand,
    required this.currentSellingPrice,
  });

  factory StockOnHand.fromJson(Map<String, dynamic> json) {
    return StockOnHand(
      itemId: json['itemId'] ?? 0,
      itemName: json['name'] ?? '',
      qtyOnHand: json['qtyOnHand'] ?? 0,
      currentSellingPrice: (json['currentSellingPrice'] ?? 0).toDouble(),
    );
  }
}