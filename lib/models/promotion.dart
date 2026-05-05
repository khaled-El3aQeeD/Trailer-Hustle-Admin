class Promotion {
  final String id;
  final String title;
  final int sponsorBusinessId;
  final String? sponsorBusinessName;
  final String imagePath;
  final String? imageUrl;
  final String? externalUrl;
  final DateTime startAt;
  final DateTime endAt;
  final bool isActive;
  final int weight;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Promotion({
    required this.id,
    required this.title,
    required this.sponsorBusinessId,
    this.sponsorBusinessName,
    required this.imagePath,
    this.imageUrl,
    this.externalUrl,
    required this.startAt,
    required this.endAt,
    required this.isActive,
    required this.weight,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLive {
    final now = DateTime.now().toUtc();
    return isActive && now.isAfter(startAt) && now.isBefore(endAt);
  }

  bool get isScheduled =>
      isActive && DateTime.now().toUtc().isBefore(startAt);

  bool get isArchived =>
      !isActive || DateTime.now().toUtc().isAfter(endAt);

  String get displayImageUrl =>
      imageUrl?.isNotEmpty == true ? imageUrl! : imagePath;

  factory Promotion.fromRow(Map<String, dynamic> r,
      {String? sponsorName}) {
    DateTime parseTs(dynamic v) {
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString()) ?? DateTime.now();
    }

    return Promotion(
      id: r['id'].toString(),
      title: (r['title'] as String?) ?? '',
      sponsorBusinessId:
          (r['sponsor_business_id'] is int)
              ? r['sponsor_business_id'] as int
              : int.tryParse(r['sponsor_business_id'].toString()) ?? 0,
      sponsorBusinessName: sponsorName,
      imagePath: (r['image_path'] as String?) ?? '',
      imageUrl: r['image_url'] as String?,
      externalUrl: r['external_url'] as String?,
      startAt: parseTs(r['start_at']),
      endAt: parseTs(r['end_at']),
      isActive: (r['is_active'] as bool?) ?? true,
      weight: (r['weight'] as int?) ?? 1,
      createdAt: parseTs(r['created_at']),
      updatedAt: parseTs(r['updated_at']),
    );
  }

  Map<String, dynamic> toInsert() => {
        'title': title,
        'sponsor_business_id': sponsorBusinessId,
        'image_path': imagePath,
        'image_url': imageUrl,
        'external_url': externalUrl,
        'start_at': startAt.toUtc().toIso8601String(),
        'end_at': endAt.toUtc().toIso8601String(),
        'is_active': isActive,
        'weight': weight,
      };

  Promotion copyWith({
    String? title,
    int? sponsorBusinessId,
    String? sponsorBusinessName,
    String? imagePath,
    String? imageUrl,
    String? externalUrl,
    DateTime? startAt,
    DateTime? endAt,
    bool? isActive,
    int? weight,
    DateTime? updatedAt,
  }) {
    return Promotion(
      id: id,
      title: title ?? this.title,
      sponsorBusinessId: sponsorBusinessId ?? this.sponsorBusinessId,
      sponsorBusinessName: sponsorBusinessName ?? this.sponsorBusinessName,
      imagePath: imagePath ?? this.imagePath,
      imageUrl: imageUrl ?? this.imageUrl,
      externalUrl: externalUrl ?? this.externalUrl,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      isActive: isActive ?? this.isActive,
      weight: weight ?? this.weight,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class PromotionStats {
  final int impressions;
  final int skips;
  final int closes;
  final int imageClicks;
  final int profileClicks;
  final double avgDwellSeconds;

  const PromotionStats({
    required this.impressions,
    required this.skips,
    required this.closes,
    required this.imageClicks,
    required this.profileClicks,
    required this.avgDwellSeconds,
  });

  double get ctr =>
      impressions == 0 ? 0 : (imageClicks + profileClicks) / impressions;

  double get skipRate =>
      impressions == 0 ? 0 : skips / impressions;

  static const PromotionStats empty = PromotionStats(
    impressions: 0,
    skips: 0,
    closes: 0,
    imageClicks: 0,
    profileClicks: 0,
    avgDwellSeconds: 0,
  );
}
