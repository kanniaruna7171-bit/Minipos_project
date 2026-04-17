import 'package:flutter/material.dart';

/// A responsive table widget that adapts to screen size
/// - Desktop/Web: Traditional table layout with horizontal scrolling
/// - Mobile: Card-based layout for better mobile viewing
class ResponsiveTable extends StatelessWidget {
  final List<TableColumn> columns;
  final List<Map<String, dynamic>> data;
  final Function(int index)? onRowTap;
  final int? selectedIndex;
  final bool isLoading;
  final String emptyMessage;
  final Widget? emptyIcon;

  const ResponsiveTable({
    super.key,
    required this.columns,
    required this.data,
    this.onRowTap,
    this.selectedIndex,
    this.isLoading = false,
    this.emptyMessage = 'No data available',
    this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Mobile view for screens smaller than 600px
        if (constraints.maxWidth < 600) {
          return _buildMobileView(context);
        }
        // Desktop/Web view for larger screens
        return _buildDesktopView(context);
      },
    );
  }

  Widget _buildDesktopView(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.purple.shade200),
              ),
            ),
            child: Row(
              children: columns.map((col) {
                return Expanded(
                  flex: col.flex,
                  child: Text(
                    col.label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
            ),
          ),

          // Table Body
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : data.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            emptyIcon ??
                                Icon(Icons.inbox_outlined,
                                    size: 60, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              emptyMessage,
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          final item = data[index];
                          final isSelected = index == selectedIndex;

                          return Container(
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.purple.shade50 : null,
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey.shade200,
                                ),
                              ),
                            ),
                            child: ListTile(
                              onTap: onRowTap != null
                                  ? () => onRowTap!(index)
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              tileColor:
                                  isSelected ? Colors.purple.shade50 : null,
                              title: Row(
                                children: columns.map((col) {
                                  return Expanded(
                                    flex: col.flex,
                                    child: col.builder(item, context),
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileView(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : data.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    emptyIcon ??
                        Icon(Icons.inbox_outlined,
                            size: 60, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      emptyMessage,
                      style:
                          TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final item = data[index];
                  final isSelected = index == selectedIndex;

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isSelected
                          ? BorderSide(color: Colors.purple.shade300, width: 2)
                          : BorderSide.none,
                    ),
                    color: isSelected ? Colors.purple.shade50 : Colors.white,
                    child: InkWell(
                      onTap: onRowTap != null ? () => onRowTap!(index) : null,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: columns.map((col) {
                            // Skip columns marked as hideOnMobile
                            if (col.hideOnMobile) return const SizedBox.shrink();
                            
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 120,
                                    child: Text(
                                      "${col.label}:",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: col.builder(item, context),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  );
                },
              );
  }
}

/// Column definition for ResponsiveTable
class TableColumn {
  final String label;
  final int flex;
  final Widget Function(Map<String, dynamic> item, BuildContext context) builder;
  final bool hideOnMobile;

  const TableColumn({
    required this.label,
    this.flex = 1,
    required this.builder,
    this.hideOnMobile = false,
  });
}
