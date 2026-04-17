import 'package:flutter/material.dart';
import '../widgets/responsive_builder.dart';
import '../utils/responsive_utils.dart';
import 'items_page.dart';
import 'suppliers_page.dart';
import 'purchase_orders_page.dart';
import 'grn_page.dart';
import 'stock_page.dart';
import 'price_history_page.dart';
import 'login_page.dart';
import 'item_master_page.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int selectedIndex = 0;

  final List<Widget> pages = const [
    ItemsPage(),
    ItemMasterPage(), // ✅ ADD THIS
    SuppliersPage(),
    PurchaseOrdersPage(),
    GRNPage(),
    StockPage(),
    PriceHistoryPage(),
  ];

  final List<Map<String, dynamic>> menuItems = const [
    {'index': 0, 'title': 'Items', 'icon': Icons.inventory_2},
     {'index': 1, 'title': 'Item Master', 'icon': Icons.edit}, // ✅ ADD
    {'index': 2, 'title': 'Suppliers', 'icon': Icons.local_shipping},
    {'index': 3, 'title': 'Purchase Orders', 'icon': Icons.receipt_long},
    {'index': 4, 'title': 'GRN', 'icon': Icons.assignment_turned_in},
    {'index': 5, 'title': 'Stock', 'icon': Icons.warehouse},
    {'index': 6, 'title': 'Price History', 'icon': Icons.history},
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: _buildMobileLayout(),
      tablet: _buildTabletLayout(),
      desktop: _buildDesktopLayout(),
    );
  }

  /// MOBILE LAYOUT (< 600px)
  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "HnA Shop",
          style: TextStyle(
            fontSize: ResponsiveUtils.getValue<double>(
              context,
              mobile: 18,
              tablet: 20,
              desktop: 22,
            ),
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF5A54E8)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage("assets/admin.png"),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Admin",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: ResponsiveUtils.getValue<double>(
                        context,
                        mobile: 16,
                        tablet: 18,
                        desktop: 20,
                      ),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "admin@example.com",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: ResponsiveUtils.getValue<double>(
                        context,
                        mobile: 12,
                        tablet: 13,
                        desktop: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...menuItems.map((item) => ListTile(
              leading: Icon(item['icon']),
              title: Text(item['title']),
              selected: selectedIndex == item['index'],
              selectedTileColor: Colors.blue.shade50,
              onTap: () {
                setState(() {
                  selectedIndex = item['index'];
                });
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
      body: pages[selectedIndex],
    );
  }

  /// TABLET LAYOUT (600px - 1200px)
  Widget _buildTabletLayout() {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "HnA Shop",
          style: TextStyle(
            fontSize: ResponsiveUtils.getValue<double>(
              context,
              mobile: 18,
              tablet: 20,
              desktop: 22,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Row(
        children: [
          // Collapsed Sidebar (icons only)
          Material(  // ✅ Add Material wrapper
            child: Container(
              width: 80,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF6C63FF), Color(0xFF5A54E8)],
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const CircleAvatar(
                    radius: 25,
                    backgroundImage: AssetImage("assets/admin.png"),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Admin",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...menuItems.map((item) => _buildIconMenuItem(item)),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      onPressed: _logout,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Main Content
          Expanded(
            child: pages[selectedIndex],
          ),
        ],
      ),
    );
  }

  /// DESKTOP LAYOUT (> 1200px)
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Full Sidebar
        Material(  // ✅ Add Material wrapper
          child: Container(
            width: 280,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF6C63FF), Color(0xFF5A54E8)],
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 40),
                const CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage("assets/admin.png"),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Admin",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // const Text(
                //   "admin@example.com",
                //   style: TextStyle(
                //     color: Colors.white70,
                //     fontSize: 14,
                //   ),
                // ),
                const SizedBox(height: 40),
                ...menuItems.map((item) => _buildFullMenuItem(item)),
                const Spacer(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.white),
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: _logout,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        // Main Content
        Expanded(
          child: Column(
            children: [
              // // Custom App Bar
              // Container(
              //   padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              //   decoration: BoxDecoration(
              //     color: Colors.white,
              //     boxShadow: [
              //       BoxShadow(
              //         color: Colors.grey.withOpacity(0.1),
              //         spreadRadius: 1,
              //         blurRadius: 5,
              //       ),
              //     ],
              //   ),
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //     children: [
              //       Text(
              //         menuItems[selectedIndex]['title'],
              //         style: TextStyle(
              //           fontSize: ResponsiveUtils.getValue<double>(
              //             context,
              //             mobile: 18,
              //             tablet: 20,
              //             desktop: 22,
              //           ),
              //           fontWeight: FontWeight.bold,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              // Page Content
              Expanded(
                child: pages[selectedIndex],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Helper for tablet icon menu - FIXED: Added Material wrapper
  Widget _buildIconMenuItem(Map<String, dynamic> item) {
    final isSelected = selectedIndex == item['index'];
    return Material(  // ✅ Add Material wrapper
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Tooltip(
          message: item['title'],
          child: IconButton(
            icon: Icon(item['icon'], color: Colors.white),
            onPressed: () {
              setState(() {
                selectedIndex = item['index'];
              });
            },
            style: IconButton.styleFrom(
              backgroundColor: isSelected ? Colors.white24 : Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Helper for desktop full menu - FIXED: Replaced ListTile with custom widget
  Widget _buildFullMenuItem(Map<String, dynamic> item) {
    final isSelected = selectedIndex == item['index'];
    return Material(  // ✅ Add Material wrapper
      color: Colors.transparent,
      child: InkWell(  // ✅ Use InkWell for ripple effect
        onTap: () {
          setState(() {
            selectedIndex = item['index'];
          });
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isSelected ? Colors.white24 : Colors.transparent,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(item['icon'], color: Colors.white, size: 24),
                const SizedBox(width: 16),
                Text(
                  item['title'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Logout function
  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }
}