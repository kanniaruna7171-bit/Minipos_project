class Supplier {
  final int id;
  final String code;
  final String name;
  final String email;
  final String phone;
  final String status;

  Supplier({
    required this.id,
    required this.code,
    required this.name,
    required this.email,
    required this.phone,
    required this.status,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    final id = json['supplierId'] ?? json['id'] ?? 0;
    return Supplier(
      id: id,
      code: json['code'] ?? 'SUP${id.toString().padLeft(3, '0')}',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      status: json['status'] ?? 'Active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'supplierId': id,
      'code': code,
      'name': name,
      'email': email,
      'phone': phone,
      'status': status,
    };
  }
}