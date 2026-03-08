class GiveawayParticipant {
  final String userId;
  /// Best-effort company/business name.
  ///
  /// Derived from `users.company_name` (if present) or `users.name`.
  final String companyName;

  /// Optional profile photo/avatar URL.
  final String? avatarUrl;

  /// Optional user display name.
  final String? name;

  /// Optional user email.
  final String? email;

  /// Optional phone/contact number.
  final String? phone;

  /// When the participant entered the competition.
  ///
  /// Typically mapped from `giveawayparticipants.created_at` / `createdAt`.
  final DateTime? enteredAt;

  GiveawayParticipant({required this.userId, required this.companyName, this.avatarUrl, this.name, this.email, this.phone, this.enteredAt});

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'company_name': companyName,
    'avatar_url': avatarUrl,
    'name': name,
    'email': email,
    'phone': phone,
    'entered_at': enteredAt?.toUtc().toIso8601String(),
  };

  static GiveawayParticipant fromJson(Map<String, dynamic> json) => GiveawayParticipant(
    userId: (json['user_id'] ?? '').toString(),
    companyName: (json['company_name'] ?? '').toString(),
    avatarUrl: (json['avatar_url'] ?? '').toString().trim().isEmpty ? null : (json['avatar_url'] ?? '').toString(),
    name: (json['name'] ?? '').toString().trim().isEmpty ? null : (json['name'] ?? '').toString(),
    email: (json['email'] ?? '').toString().trim().isEmpty ? null : (json['email'] ?? '').toString(),
    phone: (json['phone'] ?? '').toString().trim().isEmpty ? null : (json['phone'] ?? '').toString(),
    enteredAt: () {
      final raw = json['entered_at'] ?? json['enteredAt'] ?? json['created_at'] ?? json['createdAt'];
      if (raw == null) return null;
      if (raw is DateTime) return raw;
      final s = raw.toString().trim();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    }(),
  );
}
