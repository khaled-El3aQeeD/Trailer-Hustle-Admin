class SponsorData {
  final int id;
  final String name;
  final DateTime? createdAt;
  final String email;
  final String phone;
  final DateTime? updatedAt;

  const SponsorData({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.email,
    required this.phone,
    required this.updatedAt,
  });

  SponsorData copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    String? email,
    String? phone,
    DateTime? updatedAt,
  }) {
    return SponsorData(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'created_at': createdAt?.toUtc().toIso8601String(),
        'email': email,
        'phone': phone,
        'updated_at': updatedAt?.toUtc().toIso8601String(),
      };

  static DateTime? _tryParseDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is int) {
      final ms = v < 1000000000000 ? v * 1000 : v;
      return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    }
    if (v is num) {
      final i = v.toInt();
      final ms = i < 1000000000000 ? i * 1000 : i;
      return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    }
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  static String _firstNonEmpty(Iterable<Object?> values) {
    for (final v in values) {
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return '';
  }

  factory SponsorData.fromBusinessesRow(Map<String, dynamic> row) {
    final lower = <String, dynamic>{};
    for (final e in row.entries) {
      lower[e.key.toString()] = e.value;
      lower[e.key.toString().toLowerCase()] = e.value;
    }

    final id = (lower['id'] is int) ? lower['id'] as int : int.tryParse((lower['id'] ?? '0').toString()) ?? 0;

    final name = _firstNonEmpty([
      lower['display_name'],
      lower['displayname'],
      lower['business_name'],
      lower['businessname'],
      lower['company_name'],
      lower['companyname'],
      lower['name'],
      lower['title'],
    ]);

    final email = _firstNonEmpty([
      lower['contact_email'],
      lower['email'],
    ]);

    final phone = _firstNonEmpty([
      lower['business_contact_number'],
      lower['mobile_number'],
      lower['phone'],
      lower['phone_number'],
    ]);

    return SponsorData(
      id: id,
      name: name,
      createdAt: _tryParseDateTime(lower['createdat'] ?? lower['created_at']),
      email: email,
      phone: phone,
      updatedAt: _tryParseDateTime(lower['updatedat'] ?? lower['updated_at']),
    );
  }
}
