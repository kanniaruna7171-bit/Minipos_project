import 'package:flutter/material.dart';
import '../services/api/suppliers_service.dart';
import '../models/supplier.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/summary_card.dart';

class SuppliersPage extends StatefulWidget {
  const SuppliersPage({super.key});

  @override
  State<SuppliersPage> createState() => _SuppliersDashboardState();
}

class _SuppliersDashboardState extends State<SuppliersPage> {

  List<Supplier> suppliers = [];
  List<Supplier> filteredSuppliers = [];

  String searchText = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {

    setState(() => isLoading = true);

    try {

      final data = await SuppliersService.getSuppliers();

      setState(() {
        suppliers = data;
        filteredSuppliers = data;
        isLoading = false;
      });

    } catch (e) {

      setState(() => isLoading = false);

    }
  }

  List<Supplier> get filteredSuppliersList {

    if (searchText.isEmpty) return filteredSuppliers;

    return filteredSuppliers.where((s) =>
        s.name.toLowerCase().contains(searchText.toLowerCase()) ||
        s.code.toLowerCase().contains(searchText.toLowerCase())
    ).toList();
  }

  int get total => suppliers.length;
  int get active => suppliers.where((s) => s.status == "Active").length;
  int get inactive => suppliers.where((s) => s.status == "Inactive").length;

  String generateNextCode() {

    if (suppliers.isEmpty) return "SUP001";

    final lastCode = suppliers.last.code;

    final match = RegExp(r'SUP(\d+)').firstMatch(lastCode);

    if (match != null) {

      final lastNum = int.parse(match.group(1)!);

      return "SUP${(lastNum + 1).toString().padLeft(3, '0')}";
    }

    return "SUP001";
  }

  void openSupplierForm({Supplier? supplier}) {

    final nameController =
        TextEditingController(text: supplier?.name ?? "");

    final emailController =
        TextEditingController(text: supplier?.email ?? "");

    final phoneController =
        TextEditingController(text: supplier?.phone ?? "");

    String status = supplier?.status ?? "Active";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(

        title: Text(supplier == null ? "Add Supplier" : "Edit Supplier"),

        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              CustomTextField(
                controller: nameController,
                hint: "Supplier Name",
              ),

              const SizedBox(height: 10),

              CustomTextField(
                controller: emailController,
                hint: "Email",
              ),

              const SizedBox(height: 10),

              CustomTextField(
                controller: phoneController,
                hint: "Phone",
              ),

              const SizedBox(height: 10),

              DropdownButtonFormField(
                initialValue: status,
                items: const [
                  DropdownMenuItem(value: "Active", child: Text("Active")),
                  DropdownMenuItem(value: "Inactive", child: Text("Inactive")),
                ],
                onChanged: (v) => status = v!,
              ),
            ],
          ),
        ),

        actions: [

          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),

          CustomButton(
            text: supplier == null ? "Add" : "Update",
            icon: Icons.save,
            onPressed: () async {

              if (supplier == null) {

                await SuppliersService.createSupplier({
                  "code": generateNextCode(),
                  "name": nameController.text,
                  "email": emailController.text,
                  "phone": phoneController.text,
                  "status": status,
                });

              } else {

                await SuppliersService.updateSupplier(
                  supplier.id,
                  {
                    "code": supplier.code,
                    "name": nameController.text,
                    "email": emailController.text,
                    "phone": phoneController.text,
                    "status": status,
                  },
                );
              }

              if (!mounted) return;

              Navigator.pop(context);
              _loadSuppliers();
            },
          ),
        ],
      ),
    );
  }

  void deleteSupplier(int id) async {

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(

        title: const Text("Delete Supplier"),
        content: const Text("Are you sure you want to delete this supplier?"),

        actions: [

          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),

          CustomButton(
            text: "Delete",
            icon: Icons.delete,
            backgroundColor: Colors.red,
            onPressed: () => Navigator.pop(context, true),
          )
        ],
      ),
    );

    if (confirm != true) return;

    await SuppliersService.deleteSupplier(id);
    _loadSuppliers();
  }

  Widget statusBadge(String status) {

    final active = status == "Active";

    return Container(

      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),

      decoration: BoxDecoration(
        color: active ? Colors.green.shade100 : Colors.red.shade100,
        borderRadius: BorderRadius.circular(20),
      ),

      child: Text(
        status,
        style: TextStyle(
          color: active ? Colors.green : Colors.red,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget detailRow(String label, String value) {

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),

      child: Row(
        children: [

          SizedBox(
            width: 120,
            child: Text(
              "$label:",
              style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey),
            ),
          ),

          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget supplierCard(Supplier s) {

    return Card(

      margin: const EdgeInsets.only(bottom: 12),

      child: ExpansionTile(

        leading: const Icon(Icons.person),

        title: Text(
          s.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),

        subtitle: Text("Code: ${s.code}"),

        children: [

          Padding(

            padding: const EdgeInsets.all(16),

            child: Column(

              children: [

                detailRow("Supplier Code", s.code),
                detailRow("Name", s.name),
                detailRow("Email", s.email),
                detailRow("Phone", s.phone),
                detailRow("Status", s.status),

                const SizedBox(height: 16),

                Row(

                  children: [

                    Expanded(
                      child: CustomButton(
                        text: "Edit",
                        icon: Icons.edit,
                        backgroundColor: Colors.blue,
                        onPressed: () => openSupplierForm(supplier: s),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: CustomButton(
                        text: "Delete",
                        icon: Icons.delete,
                        backgroundColor: Colors.red,
                        onPressed: () => deleteSupplier(s.id),
                      ),
                    ),

                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget tableHeader() {

    return Container(

      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),

      child: const Row(

        children: [

          Expanded(flex: 2, child: Text("Code", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 3, child: Text("Name", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 3, child: Text("Email", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text("Phone", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),

          SizedBox(width: 80)
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return Scaffold(

      appBar: AppBar(
        title: const Text("Suppliers"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSuppliers,
          )
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => openSupplierForm(),
        child: const Icon(Icons.add),
      ),

      body: Padding(

        padding: const EdgeInsets.all(16),

        child: Column(

          children: [

            Row(

              children: [

                Expanded(
                  child: SummaryCard(
                    title: "Total",
                    value: total.toString(),
                    icon: Icons.people,
                    color: Colors.blue,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: SummaryCard(
                    title: "Active",
                    value: active.toString(),
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: SummaryCard(
                    title: "Inactive",
                    value: inactive.toString(),
                    icon: Icons.cancel,
                    color: Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: isMobile ? double.infinity : 400,
              child: CustomTextField(
                hint: "Search suppliers...",
                prefixIcon: Icons.search,
                onChanged: (v) => setState(() => searchText = v),
              ),
            ),

            const SizedBox(height: 20),

            Expanded(

              child: isLoading
                  ? const Center(child: CircularProgressIndicator())

                  : isMobile

                      ? ListView.builder(
                          itemCount: filteredSuppliersList.length,
                          itemBuilder: (_, i) {
                            final s = filteredSuppliersList[i];
                            return supplierCard(s);
                          },
                        )

                      : Column(

                          children: [

                            tableHeader(),

                            const SizedBox(height: 10),

                            Expanded(

                              child: ListView.builder(

                                itemCount: filteredSuppliersList.length,

                                itemBuilder: (_, i) {

                                  final s = filteredSuppliersList[i];

                                  return Container(

                                    margin: const EdgeInsets.only(bottom: 10),

                                    padding: const EdgeInsets.all(16),

                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: const [
                                        BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 4)
                                      ],
                                    ),

                                    child: Row(

                                      children: [

                                        Expanded(flex: 2, child: Text(s.code)),
                                        Expanded(flex: 3, child: Text(s.name)),
                                        Expanded(flex: 3, child: Text(s.email)),
                                        Expanded(flex: 2, child: Text(s.phone)),
                                        Expanded(flex: 2, child: statusBadge(s.status)),

                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () => openSupplierForm(supplier: s),
                                        ),

                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => deleteSupplier(s.id),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}