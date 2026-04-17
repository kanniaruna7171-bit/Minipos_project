class Item {
  final int itemId;
  final String code;
  final String name;
  final String uom;
  final String status;
  final double currentSellingPrice;
  final String? imageBase64;  // New field

  Item({
    required this.itemId,
    required this.code,
    required this.name,
    required this.uom,
    required this.status,
    required this.currentSellingPrice,
    this.imageBase64,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      itemId: json['itemId'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      uom: json['uom'] ?? '',
      status: json['status'] ?? 'Active',
      currentSellingPrice: (json['currentSellingPrice'] ?? 0).toDouble(),
      imageBase64: json['imageBase64'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'code': code,
      'name': name,
      'uom': uom,
      'status': status,
      'currentSellingPrice': currentSellingPrice,
       'imageBase64': imageBase64,
    };
  }
}