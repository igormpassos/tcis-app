class Product {
  final int id;
  final String name;
  final String? code;
  final String? description;
  final String? category;
  final int? supplierId;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? supplierName;
  final int? reportCount;

  Product({
    required this.id,
    required this.name,
    this.code,
    this.description,
    this.category,
    this.supplierId,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
    this.supplierName,
    this.reportCount,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      description: json['description'],
      category: json['category'],
      supplierId: json['supplierId'],
      active: json['active'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      supplierName: json['supplier']?['name'],
      reportCount: json['_count']?['reports'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'description': description,
      'category': category,
      'supplierId': supplierId,
      'active': active,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Product copyWith({
    int? id,
    String? name,
    String? code,
    String? description,
    String? category,
    int? supplierId,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? supplierName,
    int? reportCount,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      category: category ?? this.category,
      supplierId: supplierId ?? this.supplierId,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      supplierName: supplierName ?? this.supplierName,
      reportCount: reportCount ?? this.reportCount,
    );
  }

  String get displayCode => code?.isNotEmpty == true ? code! : 'P${id.toString().padLeft(3, '0')}';
  String get displaySupplier => supplierName ?? 'Sem fornecedor';
}
