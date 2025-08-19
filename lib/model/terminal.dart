class Terminal {
  final int id;
  final String name;
  final String? code;
  final String? prefix;
  final String? location;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? reportCount;

  Terminal({
    required this.id,
    required this.name,
    this.code,
    this.prefix,
    this.location,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
    this.reportCount,
  });

  factory Terminal.fromJson(Map<String, dynamic> json) {
    return Terminal(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      prefix: json['prefix'],
      location: json['location'],
      active: json['active'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      reportCount: json['_count']?['reports'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'prefix': prefix,
      'location': location,
      'active': active,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Terminal copyWith({
    int? id,
    String? name,
    String? code,
    String? prefix,
    String? location,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? reportCount,
  }) {
    return Terminal(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      prefix: prefix ?? this.prefix,
      location: location ?? this.location,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reportCount: reportCount ?? this.reportCount,
    );
  }

  String get displayCode => code?.isNotEmpty == true ? code! : 'T${id.toString().padLeft(3, '0')}';
  String get displayLocation => location?.isNotEmpty == true ? location! : 'Local não especificado';
}
