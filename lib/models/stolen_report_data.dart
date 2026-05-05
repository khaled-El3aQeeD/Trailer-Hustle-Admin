/// Model for `public.stolen_trailer_reports` rows used by the admin dashboard.
class StolenReportData {
  final int id;
  final int trailerId;
  final int reporterId;
  final String status; // pending | approved | rejected | cancelled | retrieved

  // snapshot
  final String? trailerName;
  final String? vin;
  final String? trailerType;
  final String? manufacturer;
  final String? photoUrl;
  final String? contactName;
  final String? contactEmail;
  final String? contactPhone;

  // user-supplied
  final String? color;
  final String? plate;
  final DateTime? stolenAt;
  final String? stolenLocation;
  final double? stolenLat;
  final double? stolenLng;
  final double? rewardAmount;
  final String? rewardCurrency;
  final String? additionalInfo;

  // moderation
  final String? adminNote;
  final int? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime? approvedAt;
  final DateTime? retrievedAt;
  final DateTime? cancelledAt;

  final DateTime createdAt;
  final DateTime updatedAt;

  const StolenReportData({
    required this.id,
    required this.trailerId,
    required this.reporterId,
    required this.status,
    this.trailerName,
    this.vin,
    this.trailerType,
    this.manufacturer,
    this.photoUrl,
    this.contactName,
    this.contactEmail,
    this.contactPhone,
    this.color,
    this.plate,
    this.stolenAt,
    this.stolenLocation,
    this.stolenLat,
    this.stolenLng,
    this.rewardAmount,
    this.rewardCurrency,
    this.additionalInfo,
    this.adminNote,
    this.reviewedBy,
    this.reviewedAt,
    this.approvedAt,
    this.retrievedAt,
    this.cancelledAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRetrieved => status == 'retrieved';
  bool get isRejected => status == 'rejected';
  bool get isCancelled => status == 'cancelled';
  bool get isActive => isPending || isApproved;

  String get statusLabel => switch (status) {
        'pending' => 'Pending review',
        'approved' => 'Approved',
        'rejected' => 'Rejected',
        'cancelled' => 'Cancelled by reporter',
        'retrieved' => 'Retrieved',
        _ => status,
      };

  String get displayName {
    final parts = <String>[];
    if ((manufacturer ?? '').trim().isNotEmpty) parts.add(manufacturer!.trim());
    if ((trailerName ?? '').trim().isNotEmpty) parts.add(trailerName!.trim());
    if (parts.isEmpty) return 'Trailer #$trailerId';
    return parts.join(' ');
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  factory StolenReportData.fromJson(Map<String, dynamic> j) {
    return StolenReportData(
      id: j['id'] as int,
      trailerId: j['trailer_id'] as int,
      reporterId: j['reporter_id'] as int,
      status: (j['status'] as String?) ?? 'pending',
      trailerName: j['trailer_name'] as String?,
      vin: j['vin'] as String?,
      trailerType: j['trailer_type'] as String?,
      manufacturer: j['manufacturer'] as String?,
      photoUrl: j['photo_url'] as String?,
      contactName: j['contact_name'] as String?,
      contactEmail: j['contact_email'] as String?,
      contactPhone: j['contact_phone'] as String?,
      color: j['color'] as String?,
      plate: j['plate'] as String?,
      stolenAt: _parseDate(j['stolen_at']),
      stolenLocation: j['stolen_location'] as String?,
      stolenLat: _parseDouble(j['stolen_lat']),
      stolenLng: _parseDouble(j['stolen_lng']),
      rewardAmount: _parseDouble(j['reward_amount']),
      rewardCurrency: j['reward_currency'] as String?,
      additionalInfo: j['additional_info'] as String?,
      adminNote: j['admin_note'] as String?,
      reviewedBy: _parseInt(j['reviewed_by']),
      reviewedAt: _parseDate(j['reviewed_at']),
      approvedAt: _parseDate(j['approved_at']),
      retrievedAt: _parseDate(j['retrieved_at']),
      cancelledAt: _parseDate(j['cancelled_at']),
      createdAt: _parseDate(j['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(j['updated_at']) ?? DateTime.now(),
    );
  }
}
