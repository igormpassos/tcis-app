class Supplier {
  final int id;
  final String name;
  final String? code;
  final String? contact;
  final String? email;
  final String? phone;
  final String? address;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? productCount;
  final int? reportCount;

  Supplier({
    required this.id,
    required this.name,
    this.code,
    this.contact,
    this.email,
    this.phone,
    this.address,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
    this.productCount,
    this.reportCount,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      contact: json['contact'],
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      active: json['active'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      productCount: json['_count']?['products'],
      reportCount: json['_count']?['reports'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'contact': contact,
      'email': email,
      'phone': phone,
      'address': address,
      'active': active,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Supplier copyWith({
    int? id,
    String? name,
    String? code,
    String? contact,
    String? email,
    String? phone,
    String? address,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? productCount,
    int? reportCount,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      contact: contact ?? this.contact,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      productCount: productCount ?? this.productCount,
      reportCount: reportCount ?? this.reportCount,
    );
  }

  String get displayCode => code?.isNotEmpty == true ? code! : 'S${id.toString().padLeft(3, '0')}';
}
