class TrailerData {
  final int id;
  final int businessId;
  final String displayName;
  final String image;
  final String? email;
  final String? trailerName;
  /// Trailer model name (e.g., "XLT", "Ranger", etc.).
  ///
  /// The backend schema may store this under `trailerName` (current) or `model`
  /// (legacy). We support both for backwards compatibility.
  final String? model;
  final int? trailerType;
  final int brand;
  final int length;
  final String lengthUnit;
  final int width;
  final String widthUnit;
  final int loadCapacity;
  final String winNumber;
  final int? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TrailerData({
    required this.id,
    required this.businessId,
    required this.displayName,
    required this.image,
    required this.email,
    required this.trailerName,
    required this.model,
    required this.trailerType,
    required this.brand,
    required this.length,
    required this.lengthUnit,
    required this.width,
    required this.widthUnit,
    required this.loadCapacity,
    required this.winNumber,
    required this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  TrailerData copyWith({
    int? id,
    int? businessId,
    String? displayName,
    String? image,
    String? email,
    String? trailerName,
    String? model,
    int? trailerType,
    int? brand,
    int? length,
    String? lengthUnit,
    int? width,
    String? widthUnit,
    int? loadCapacity,
    String? winNumber,
    int? deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TrailerData(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      displayName: displayName ?? this.displayName,
      image: image ?? this.image,
      email: email ?? this.email,
      trailerName: trailerName ?? this.trailerName,
      model: model ?? this.model,
      trailerType: trailerType ?? this.trailerType,
      brand: brand ?? this.brand,
      length: length ?? this.length,
      lengthUnit: lengthUnit ?? this.lengthUnit,
      width: width ?? this.width,
      widthUnit: widthUnit ?? this.widthUnit,
      loadCapacity: loadCapacity ?? this.loadCapacity,
      winNumber: winNumber ?? this.winNumber,
      deletedAt: deletedAt ?? this.deletedAt,
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

  static int? _parseNullableInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  factory TrailerData.fromJson(Map<String, dynamic> json) {
    // Keep this resilient: DB column naming can vary (snake_case vs camelCase).
    // Trailers table in this project is camelCase, but some environments may use
    // snake_case or legacy keys.
    // In the user's current schema, Trailers.model is stored in `trailerName`.
    // Keep `model` populated too so existing UI continues to work.
    final trailerName = (json['trailerName'] ?? json['trailer_name'] ?? json['name'])?.toString();
    final model = (trailerName ?? json['model'] ?? json['modelName'] ?? json['model_name'])?.toString();

    final displayName = (json['displayName'] ?? json['display_name'] ?? json['title'] ?? '').toString();
    final image = (json['image'] ?? json['Image'] ?? '').toString();

    final businessIdRaw = json['bussinessid'] ?? json['businessId'] ?? json['business_id'] ?? json['businessid'];
    final brandRaw = json['brand'] ?? json['brandId'] ?? json['brand_id'] ?? json['makeId'] ?? json['make_id'];

    final lengthRaw = json['length'] ?? json['trailer_length'] ?? json['trailerLength'];
    final lengthUnitRaw = json['lengthUnit'] ?? json['length_unit'] ?? json['trailer_length_unit'] ?? json['trailerLengthUnit'];
    final widthRaw = json['width'] ?? json['trailer_width'] ?? json['trailerWidth'];
    final widthUnitRaw = json['widthUnit'] ?? json['width_unit'] ?? json['trailer_width_unit'] ?? json['trailerWidthUnit'];
    final loadCapacityRaw = json['loadCapacity'] ?? json['load_capacity'] ?? json['capacity'] ?? json['trailerCapacity'];
    final winNumberRaw = json['winNumber'] ?? json['vin'] ?? json['VIN'] ?? json['win_number'];

    return TrailerData(
      id: _parseInt(json['id'], fallback: 0),
      businessId: _parseInt(businessIdRaw, fallback: 0),
      displayName: displayName,
      image: image,
      email: json['email']?.toString(),
      trailerName: trailerName,
      model: model,
      trailerType: _parseNullableInt(json['trailerType']),
      brand: _parseInt(brandRaw, fallback: 0),
      length: _parseInt(lengthRaw, fallback: 0),
      lengthUnit: (lengthUnitRaw ?? '').toString(),
      width: _parseInt(widthRaw, fallback: 0),
      widthUnit: (widthUnitRaw ?? '').toString(),
      loadCapacity: _parseInt(loadCapacityRaw, fallback: 0),
      winNumber: (winNumberRaw ?? '').toString(),
      deletedAt: _parseNullableInt(json['deletedAt']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bussinessid': businessId,
      'displayName': displayName,
      'image': image,
      'email': email,
      // Current schema: model is stored as trailerName.
      'trailerName': (trailerName ?? model),
      // Legacy key retained for environments that still store it.
      'model': model,
      'trailerType': trailerType,
      'brand': brand,
      'length': length,
      'lengthUnit': lengthUnit,
      'width': width,
      'widthUnit': widthUnit,
      'loadCapacity': loadCapacity,
      'winNumber': winNumber,
      'deletedAt': deletedAt,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }
}
