class Terminal {
  final int id;
  final String name;
  final String? code;
  final String? location;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  Terminal({
    required this.id,
    required this.name,
    this.code,
    this.location,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Terminal.fromJson(Map<String, dynamic> json) {
    return Terminal(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      location: json['location'],
      active: json['active'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'location': location,
      'active': active,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

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
  final List<Product>? products;

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
    this.products,
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
      active: json['active'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      products: json['products'] != null
          ? (json['products'] as List)
              .map((product) => Product.fromJson(product))
              .toList()
          : null,
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
      if (products != null) 'products': products!.map((p) => p.toJson()).toList(),
    };
  }
}

class Product {
  final int id;
  final String name;
  final String? code;
  final String? description;
  final String? category;
  final bool active;
  final int? supplierId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Supplier? supplier;

  Product({
    required this.id,
    required this.name,
    this.code,
    this.description,
    this.category,
    required this.active,
    this.supplierId,
    required this.createdAt,
    required this.updatedAt,
    this.supplier,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      description: json['description'],
      category: json['category'],
      active: json['active'],
      supplierId: json['supplierId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      supplier: json['supplier'] != null ? Supplier.fromJson(json['supplier']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'description': description,
      'category': category,
      'active': active,
      'supplierId': supplierId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (supplier != null) 'supplier': supplier!.toJson(),
    };
  }
}

class Client {
  final int id;
  final String name;
  final String? contact;
  final List<String> emails;
  final DateTime createdAt;
  final DateTime updatedAt;

  Client({
    required this.id,
    required this.name,
    this.contact,
    required this.emails,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'],
      name: json['name'],
      contact: json['contact'],
      emails: List<String>.from(json['emails'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'contact': contact,
      'emails': emails,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
