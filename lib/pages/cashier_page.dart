import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/print_bill.dart';
import '../services/api/cashier_service.dart';
import '../services/api/billing_service.dart';
import '../models/product.dart';
import 'login_page.dart';

/// ================= CART ITEM MODEL =================
class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
}

/// ================= CART PAGE (Mobile only) =================
class CartPage extends StatelessWidget {
  final List<CartItem> cart;
  final Function(CartItem, int) onUpdateQuantity;
  final Function(CartItem) onRemove;
  final VoidCallback onPrintBill;

  const CartPage({
    Key? key,
    required this.cart,
    required this.onUpdateQuantity,
    required this.onRemove,
    required this.onPrintBill,
  }) : super(key: key);

  double get total =>
      cart.fold(0, (sum, item) => sum + item.quantity * item.product.price);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Order"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: cart.isEmpty
          ? const Center(child: Text("Cart is empty"))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cart.length,
                    itemBuilder: (_, i) {
                      final item = cart[i];
                      final itemTotal = item.quantity * item.product.price;
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.product.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => onRemove(item),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                      '₹${item.product.price}/${item.product.unit}'),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove,
                                            size: 18, color: Colors.red),
                                        onPressed: () => onUpdateQuantity(
                                            item, item.quantity - 1),
                                      ),
                                      Text(
                                        '${item.quantity}',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add,
                                            size: 18, color: Colors.green),
                                        onPressed: () => onUpdateQuantity(
                                            item, item.quantity + 1),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Total:',
                                      style:
                                          TextStyle(fontWeight: FontWeight.bold)),
                                  Text(
                                    '₹${itemTotal.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green),
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
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          blurRadius: 5, color: Colors.grey.shade300),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total:',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(
                            '₹${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: onPrintBill,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text(
                            "PRINT BILL",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

/// ================= CASHIER PAGE =================
class CashierPage extends StatefulWidget {
  const CashierPage({super.key});

  @override
  State<CashierPage> createState() => _CashierPageState();
}

class _CashierPageState extends State<CashierPage> {
  final TextEditingController _searchController = TextEditingController();

  List<Product> availableProducts = [];
  List<CartItem> cart = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      final products = await CashierService.getProducts();
      setState(() {
        availableProducts = products;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load products: $e';
        isLoading = false;
      });
    }
  }

  void _searchProduct(String query) {
    if (query.isEmpty) {
      _loadProducts();
      return;
    }
    final lowerQuery = query.toLowerCase();
    setState(() {
      availableProducts = availableProducts
          .where((p) => p.name.toLowerCase().contains(lowerQuery))
          .toList();
    });
  }

  double get total =>
      cart.fold(0, (sum, item) => sum + item.quantity * item.product.price);

  void addToCart(Product product, int quantity) {
    final existingIndex =
        cart.indexWhere((c) => c.product.itemId == product.itemId);
    final alreadyInCart =
        existingIndex >= 0 ? cart[existingIndex].quantity : 0;

    if (alreadyInCart + quantity > product.availableStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Not enough stock. Available: ${product.availableStock} ${product.unit}"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      if (existingIndex >= 0) {
        cart[existingIndex].quantity += quantity;
      } else {
        cart.add(CartItem(product: product, quantity: quantity));
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            "Added $quantity ${product.unit} of ${product.name} to cart"),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.green,
      ),
    );
  }

  void removeFromCart(CartItem item) {
    setState(() {
      cart.remove(item);
    });
  }

  void updateCartQuantity(CartItem item, int newQuantity) {
    if (newQuantity > item.product.availableStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Not enough stock. Available: ${item.product.availableStock} ${item.product.unit}"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (newQuantity <= 0) {
      removeFromCart(item);
      return;
    }

    setState(() {
      item.quantity = newQuantity;
    });
  }

  Future<bool> _completeBilling() async {
    if (cart.isEmpty) return false;

    // Prepare bill lines
    final lines = cart.map((c) => {
          'itemId': c.product.itemId,
          'quantity': c.quantity,
          'price': c.product.price,
        }).toList();

    try {
      final success = await BillingService.createBill(lines);
      if (success) {
        // Print bill
        final pdfCart = cart.map((c) => {
              'name': c.product.name,
              'qty': c.quantity,
              'unit': c.product.unit,
              'price': c.product.price,
              'total': c.quantity * c.product.price,
            }).toList();
        final billNumber = 'BILL-${DateTime.now().millisecondsSinceEpoch}';
        await printBill(pdfCart, total);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Bill #$billNumber printed successfully"),
              backgroundColor: Colors.green,
            ),
          );
        }

        setState(() {
          cart.clear();
        });
        await _loadProducts(); // Refresh stock
        return true;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Failed to create bill"),
              backgroundColor: Colors.red,
            ),
          );
        }
        return false;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported, size: 40, color: Colors.grey[400]),
          Text(
            'No Image',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(Product product) {
    if (product.imageBase64 != null && product.imageBase64!.isNotEmpty) {
      try {
        return Image.memory(
          base64Decode(product.imageBase64!),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholderImage();
          },
        );
      } catch (e) {
        return _buildPlaceholderImage();
      }
    }
    return _buildPlaceholderImage();
  }

  void showProductDialog(Product product) {
    int quantity = 1;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text(product.name),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[100],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildProductImage(product),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Price: ₹${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                  ),
                  Text('/ ${product.unit}',
                      style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Available: ${product.availableStock} ${product.unit}',
                      style: TextStyle(
                          color: Colors.blue[800], fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle,
                            color: Colors.red),
                        onPressed: () {
                          if (quantity > 1) {
                            quantity--;
                            setStateDialog(() {});
                          }
                        },
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('$quantity',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.green),
                        onPressed: () {
                          if (quantity < product.availableStock) {
                            quantity++;
                            setStateDialog(() {});
                          }
                        },
                      ),
                    ],
                  ),
                  if (quantity == product.availableStock)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        "Max quantity reached",
                        style: TextStyle(
                            color: Colors.orange[700], fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Total: ₹${(quantity * product.price).toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: quantity > 0 && quantity <= product.availableStock
                      ? () {
                          addToCart(product, quantity);
                          Navigator.pop(context);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Add to Cart"),
                )
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "No products available",
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            "Approve GRNs to add products",
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadProducts,
            icon: const Icon(Icons.refresh),
            label: const Text("Refresh"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text("HnA Shop "),
      centerTitle: true,
      backgroundColor: Colors.purple.shade100,
      foregroundColor: Colors.black,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => LoginPage())),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: availableProducts.isNotEmpty
                      ? Colors.green
                      : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text('${availableProducts.length} items'),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadProducts,
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      appBar: _buildAppBar(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(errorMessage,
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _loadProducts,
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                )
              : availableProducts.isEmpty
                  ? _buildEmptyState()
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: TextField(
                            controller: _searchController,
                            onChanged: _searchProduct,
                            decoration: InputDecoration(
                              hintText: "Search product...",
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              suffixIcon:
                                  _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            _searchController.clear();
                                            _loadProducts();
                                          },
                                        )
                                      : null,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: GridView.builder(
                                  padding: const EdgeInsets.all(12),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    childAspectRatio: 0.72,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                                  itemCount: availableProducts.length,
                                  itemBuilder: (_, i) {
                                    final p = availableProducts[i];
                                    return GestureDetector(
                                      onTap: () => showProductDialog(p),
                                      child: Card(
                                        elevation: 3,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16)),
                                        clipBehavior: Clip.antiAlias,
                                        child: Column(
                                          children: [
                                            if (p.availableStock < 10)
                                              Container(
                                                width: double.infinity,
                                                color: Colors.orange.shade100,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 4),
                                                child: Text(
                                                  'Low Stock: ${p.availableStock}',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.orange[800],
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            Expanded(
                                              flex: 3,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(10),
                                                color: Colors.grey.shade50,
                                                child: _buildProductImage(p),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(6),
                                                child: Column(
                                                  children: [
                                                    Text(
                                                      p.name,
                                                      textAlign:
                                                          TextAlign.center,
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 13),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      '₹${p.price.toStringAsFixed(2)}',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Colors.green,
                                                      ),
                                                    ),
                                                    Text(
                                                      '/ ${p.unit}',
                                                      style: TextStyle(
                                                          fontSize: 10,
                                                          color:
                                                              Colors.grey[600]),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Container(
                                width: 320,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  border: Border(
                                      left: BorderSide(
                                          color: Colors.grey.shade300)),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      color: Colors.purple.shade100,
                                      child: Row(
                                        children: [
                                          const Icon(Icons.shopping_cart),
                                          const SizedBox(width: 8),
                                          Text(
                                            "Cart (${cart.length})",
                                            style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: cart.isEmpty
                                          ? Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                      Icons
                                                          .shopping_cart_outlined,
                                                      size: 50,
                                                      color: Colors.grey[400]),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    "Cart is empty",
                                                    style: TextStyle(
                                                        color:
                                                            Colors.grey[600]),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : ListView.builder(
                                              itemCount: cart.length,
                                              itemBuilder: (_, i) {
                                                final item = cart[i];
                                                final itemTotal = item
                                                        .quantity *
                                                    item.product.price;

                                                return Card(
                                                  margin: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Expanded(
                                                              child: Text(
                                                                item
                                                                    .product.name,
                                                                style: const TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        14),
                                                              ),
                                                            ),
                                                            IconButton(
                                                              icon: const Icon(
                                                                  Icons.delete,
                                                                  color: Colors
                                                                      .red,
                                                                  size: 20),
                                                              onPressed: () =>
                                                                  removeFromCart(
                                                                      item),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                            height: 4),
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Text(
                                                                '₹${item.product.price}/${item.product.unit}'),
                                                            Row(
                                                              children: [
                                                                IconButton(
                                                                  icon: const Icon(
                                                                      Icons
                                                                          .remove,
                                                                      size: 18,
                                                                      color: Colors
                                                                          .red),
                                                                  onPressed: () =>
                                                                      updateCartQuantity(
                                                                          item,
                                                                          item.quantity -
                                                                              1),
                                                                ),
                                                                Text(
                                                                  '${item.quantity}',
                                                                  style: const TextStyle(
                                                                      fontSize:
                                                                          16,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold),
                                                                ),
                                                                IconButton(
                                                                  icon: const Icon(
                                                                      Icons.add,
                                                                      size: 18,
                                                                      color: Colors
                                                                          .green),
                                                                  onPressed: () =>
                                                                      updateCartQuantity(
                                                                          item,
                                                                          item.quantity +
                                                                              1),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                        const Divider(),
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            const Text('Total:',
                                                                style: TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold)),
                                                            Text(
                                                              '₹${itemTotal.toStringAsFixed(2)}',
                                                              style: const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                      .green,
                                                                  fontSize: 16),
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
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.3),
                                            blurRadius: 5,
                                            offset: const Offset(0, -2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text('Grand Total:',
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                              Text(
                                                '₹${total.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed: cart.isEmpty
                                                  ? null
                                                  : _completeBilling,
                                              style: ElevatedButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 16),
                                                backgroundColor: Colors.purple,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8)),
                                              ),
                                              child: const Text(
                                                "PRINT BILL",
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: _buildAppBar(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(errorMessage,
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _loadProducts,
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _searchProduct,
                        decoration: InputDecoration(
                          hintText: "Search product...",
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _loadProducts();
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                    Expanded(
                      child: availableProducts.isEmpty
                          ? _buildEmptyState()
                          : GridView.builder(
                              padding: const EdgeInsets.all(12),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.7,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: availableProducts.length,
                              itemBuilder: (_, i) {
                                final p = availableProducts[i];
                                return GestureDetector(
                                  onTap: () => showProductDialog(p),
                                  child: Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    clipBehavior: Clip.antiAlias,
                                    child: Column(
                                      children: [
                                        if (p.availableStock < 10)
                                          Container(
                                            width: double.infinity,
                                            color: Colors.orange.shade100,
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    vertical: 2),
                                            child: Text(
                                              'Low Stock: ${p.availableStock}',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: Colors.orange[800],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        Expanded(
                                          flex: 3,
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            color: Colors.grey.shade50,
                                            child: _buildProductImage(p),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Padding(
                                            padding: const EdgeInsets.all(4),
                                            child: Column(
                                              children: [
                                                Text(
                                                  p.name,
                                                  textAlign: TextAlign.center,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '₹${p.price.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.green),
                                                ),
                                                Text(
                                                  '/ ${p.unit}',
                                                  style: TextStyle(
                                                      fontSize: 9,
                                                      color: Colors.grey[600]),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    if (cart.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                                blurRadius: 5, color: Colors.grey.shade300),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${cart.length} item(s)',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Total: ₹${total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green),
                                ),
                              ],
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CartPage(
                                      cart: cart,
                                      onUpdateQuantity: updateCartQuantity,
                                      onRemove: removeFromCart,
                                      onPrintBill: () async {
                                        bool success = await _completeBilling();
                                        if (success && context.mounted) {
                                          Navigator.pop(context);
                                        }
                                      },
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                              ),
                              child: const Text("Continue"),
                            ),
                          ],
                        ),
                      ),
                  ],
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