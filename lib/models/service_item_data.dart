class ServiceItemData {
  final int id;
  final int businessId;
  final String title;
  final String description;
  final String image;
  final double price;
  final String currency;
  final String type;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ServiceItemData({
    required this.id,
    required this.businessId,
    required this.title,
    required this.description,
    required this.image,
    required this.price,
    required this.currency,
    required this.type,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  ServiceItemData copyWith({
    int? id,
    int? businessId,
    String? title,
    String? description,
    String? image,
    double? price,
    String? currency,
    String? type,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceItemData(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      title: title ?? this.title,
      description: description ?? this.description,
      image: image ?? this.image,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    if (v is DateTime) return v.toUtc();
    return DateTime.tryParse(v.toString())?.toUtc() ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  static int _parseInt(dynamic v, {required int fallback}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  static double _parseDouble(dynamic v, {required double fallback}) {
    if (v == null) return fallback;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }

  static bool _parseBool(dynamic v, {required bool fallback}) {
    if (v == null) return fallback;
    if (v is bool) return v;
    if (v is num) return v.toInt() != 0;
    final s = v.toString().trim().toLowerCase();
    if (s == 'true' || s == '1' || s == 'yes') return true;
    if (s == 'false' || s == '0' || s == 'no') return false;
    return fallback;
  }

  factory ServiceItemData.fromJson(Map<String, dynamic> json) {
    final title = (json['title'] ?? json['name'] ?? json['serviceName'] ?? json['displayName'] ?? '').toString().trim();
    final description = (json['description'] ?? json['details'] ?? json['summary'] ?? '').toString().trim();
    final image = (json['image'] ?? json['image_url'] ?? json['imageUrl'] ?? json['photo'] ?? '').toString();
    final currency = (json['currency'] ?? json['currency_code'] ?? json['currencyCode'] ?? 'USD').toString().trim();
    final type = (json['type'] ?? json['serviceType'] ?? json['itemType'] ?? '').toString().trim();
    final isActive = _parseBool(json['is_active'] ?? json['isActive'] ?? json['active'], fallback: true);

    return ServiceItemData(
      id: _parseInt(json['id'], fallback: 0),
      businessId: _parseInt(json['bussinessid'] ?? json['businessid'] ?? json['business_id'] ?? json['businessId'], fallback: 0),
      title: title.isEmpty ? 'Untitled service' : title,
      description: description,
      image: image,
      price: _parseDouble(json['price'] ?? json['amount'] ?? json['cost'], fallback: 0),
      currency: currency.isEmpty ? 'USD' : currency,
      type: type,
      isActive: isActive,
      createdAt: _parseDate(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDate(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bussinessid': businessId,
      'title': title,
      'description': description,
      'image': image,
      'price': price,
      'currency': currency,
      'type': type,
      'is_active': isActive,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }
}
