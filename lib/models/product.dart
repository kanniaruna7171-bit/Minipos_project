class Product {
  final int itemId;
  final String name;
  final double price;
  final String unit;
  final String? imageBase64;
  final int availableStock;

  Product({
    required this.itemId,
    required this.name,
    required this.price,
    required this.unit,
    this.imageBase64,
    required this.availableStock,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      itemId: json['itemId'] ?? 0,
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      unit: json['unit'] ?? 'pcs',
      imageBase64: json['imageBase64'],
      availableStock: json['availableStock'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'name': name,
      'price': price,
      'unit': unit,
      'imageBase64': imageBase64,
      'availableStock': availableStock,
    };
  }
}