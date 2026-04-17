import '../pages/item_price_history.dart';

class StockLedgerEntry {
  final int ledgerId;
  final DateTime txnDate;
  final String itemId;
  final String itemName;
  final double rate;
  final int qtyIn;
  final int qtyOut;
  final String ref;

  StockLedgerEntry({
    required this.ledgerId,
    required this.txnDate,
    required this.itemId,
    required this.itemName,
    required this.rate,
    required this.qtyIn,
    required this.qtyOut,
    required this.ref,
  });
}

class StockService {
  static final List<StockLedgerEntry> _ledger = [];
  static int _autoId = 1;

  static final List<ItemPriceHistory> _priceHistory = [];
  
  // NEW: Store product images (base64 or URL)
  static final Map<String, String> _productImages = {};
  
  // NEW: Store product image base64 data
  static final Map<String, String> _productImagesBase64 = {};
  
  // NEW: Store product units
  static final Map<String, String> _productUnits = {};
  static final Map<String, DateTime> _itemCreatedAt = {};
  static final Map<String, DateTime> _itemUpdatedAt = {};
  
  // NEW: Listeners for UI updates
  static final List<Function> _listeners = [];
  static DateTime? getItemCreatedAt(String itemName) {
    return _itemCreatedAt[itemName.toLowerCase()];
  }

  /// ===== GET ITEM UPDATED AT =====
  static DateTime? getItemUpdatedAt(String itemName) {
    return _itemUpdatedAt[itemName.toLowerCase()];
  }


  /// ===== ADD LISTENER FOR UI UPDATES =====
  static void addListener(Function listener) {
    _listeners.add(listener);
  }

  /// ===== REMOVE LISTENER =====
  static void removeListener(Function listener) {
    _listeners.remove(listener);
  }

  /// ===== NOTIFY LISTENERS =====
  static void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }

  /// ===== GET PRICE HISTORY =====
  static List<ItemPriceHistory> getPriceHistory() {
    return _priceHistory;
  }

  // /// ===== ADD PRICE HISTORY =====
  // static void addPriceHistory({
  //   required String itemId,
  //   required double purchaseCost,
  //   required String changedBy,
  // }) {
  //   double sellingPrice = purchaseCost * 1.20; // 20% margin
  //   double marginPercent =
  //       ((sellingPrice - purchaseCost) / purchaseCost) * 100;

  //   _priceHistory.add(
  //     ItemPriceHistory(
  //       priceId: "PH${DateTime.now().millisecondsSinceEpoch}",
  //       itemId: itemId,
  //       effectiveAt: DateTime.now(),
  //       purchaseCost: purchaseCost,
  //       sellingPrice: sellingPrice,
  //       marginPercent: marginPercent,
  //       changedBy: changedBy,
  //     ),
  //   );
  // }

  // /// ===== GRN APPROVED → ADD STOCK WITH COMPLETE PRODUCT INFO =====
  // static void addItemFromGRN({
  //   required String itemName,
  //   required int quantity,
  //   required double rate,
  //   String? imageBase64,
  //   String? imageUrl,
  //   String unit = "pcs",
  //   String ref = "GRN",
  // }) {
  //   // Add to ledger (increase stock)
  //   _ledger.add(
  //     StockLedgerEntry(
  //       ledgerId: _autoId++,
  //       txnDate: DateTime.now(),
  //       itemId: itemName.toLowerCase(),
  //       itemName: itemName,
  //       rate: rate,
  //       qtyIn: quantity,
  //       qtyOut: 0,
  //       ref: ref,
  //     ),
  //   );
    
  //   // Store image if provided
  //   if (imageBase64 != null && imageBase64.isNotEmpty) {
  //     _productImagesBase64[itemName.toLowerCase()] = imageBase64;
  //   } else if (imageUrl != null && imageUrl.isNotEmpty) {
  //     _productImages[itemName.toLowerCase()] = imageUrl;
  //   }
    
  //   // Store unit
  //   _productUnits[itemName.toLowerCase()] = unit;
    
  //   // Add price history
  //   addPriceHistory(
  //     itemId: itemName.toLowerCase(),
  //     purchaseCost: rate,
  //     changedBy: "Admin",
  //   );
    
  //   // Notify listeners (Cashier page will refresh)
  //   _notifyListeners();
  // }

  // /// ===== GRN APPROVED → ADD STOCK (Backward compatibility) =====
  // static void increaseStock(
  //   String itemName,
  //   int qty, {
  //   double rate = 0,
  //   String ref = "GRN",
  // }) {
  //   _ledger.add(
  //     StockLedgerEntry(
  //       ledgerId: _autoId++,
  //       txnDate: DateTime.now(),
  //       itemId: itemName.toLowerCase(),
  //       itemName: itemName,
  //       rate: rate,
  //       qtyIn: qty,
  //       qtyOut: 0,
  //       ref: ref,
  //     ),
  //   );
  // }

  /// ===== BILLING → REDUCE STOCK =====
  static void decreaseStock(
    String itemName,
    int qty, {
    double rate = 0,
    String ref = "BILL",
  }) {
    _ledger.add(
      StockLedgerEntry(
        ledgerId: _autoId++,
        txnDate: DateTime.now(),
        itemId: itemName.toLowerCase(),
        itemName: itemName,
        rate: rate,
        qtyIn: 0,
        qtyOut: qty,
        ref: ref,
      ),
    );
    
    // Notify listeners after stock change
    _notifyListeners();
  }

  /// ===== GET FULL LEDGER =====
  static List<StockLedgerEntry> getLedger() => _ledger;

  /// ===== CALCULATE STOCK ON HAND =====
  static Map<String, int> getStockOnHand() {
    final Map<String, int> stock = {};

    for (var e in _ledger) {
      stock[e.itemName.toLowerCase()] =
          (stock[e.itemName.toLowerCase()] ?? 0) + e.qtyIn - e.qtyOut;
    }

    return stock;
  }

  /// ===== GET LATEST SELLING PRICE =====
  static double getLatestSellingPrice(String itemId) {
    final prices = _priceHistory
        .where((p) => p.itemId.toLowerCase() == itemId.toLowerCase())
        .toList();

    if (prices.isEmpty) return 0;

    prices.sort((a, b) => b.effectiveAt.compareTo(a.effectiveAt));

    return prices.first.sellingPrice;
  }

  /// ===== GET PRODUCT IMAGE (URL) =====
  static String? getItemImage(String itemName) {
    return _productImages[itemName.toLowerCase()];
  }

  /// ===== GET PRODUCT IMAGE (Base64) =====
  static String? getItemImageBase64(String itemName) {
    return _productImagesBase64[itemName.toLowerCase()];
  }

  /// ===== GET PRODUCT UNIT =====
  static String? getItemUnit(String itemName) {
    return _productUnits[itemName.toLowerCase()];
  }

  /// ===== REGISTER PRODUCT (FROM GRN) - Legacy =====
  static void registerProduct({
    required String itemName,
    required String imagePath,
  }) {
    _productImages[itemName.toLowerCase()] = imagePath;
  }

  /// ===== GET REGISTERED PRODUCTS =====
  static Map<String, String> getRegisteredProducts() {
    return _productImages;
  }
  
  /// ===== GET ALL REGISTERED PRODUCTS WITH COMPLETE INFO =====
  static List<Map<String, dynamic>> getAllProducts() {
    final stock = getStockOnHand();
    final List<Map<String, dynamic>> products = [];
    
    for (var entry in stock.entries) {
      if (entry.value > 0) {
        final itemName = entry.key;
        products.add({
          'name': itemName,
          'stock': entry.value,
          'price': getLatestSellingPrice(itemName),
          'unit': getItemUnit(itemName) ?? 'pcs',
          'image': getItemImage(itemName),
          'imageBase64': getItemImageBase64(itemName),
        });
      }
    }
    
    return products;
  }
}