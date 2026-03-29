/// Model for admin_notifications table rows.
///
/// Type mapping:
/// - 8  = Brand Partner Request
/// - 10 = New Trailer Make Added
/// - 11 = Contact Us Submission
/// - 13 = Reported Chat
class AdminNotificationData {
  final int id;
  final int userId;
  final int type;
  final int notificationType;
  final String title;
  final String description;
  final int isRead;
  final String name;
  final String email;
  final String? submitterImage;
  final int? sourceId;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AdminNotificationData({
    required this.id,
    required this.userId,
    required this.type,
    required this.notificationType,
    required this.title,
    required this.description,
    required this.isRead,
    required this.name,
    required this.email,
    this.submitterImage,
    this.sourceId,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isUnread => isRead == 0;

  /// Human-readable category label
  String get categoryLabel => switch (type) {
        8 => 'Brand Partner Request',
        10 => 'New Trailer Make',
        11 => 'Contact Us',
        13 => 'Reported Chat',
        _ => 'Notification',
      };

  /// Short identifier for the submitter (name, email, or user ID fallback)
  String get submitterDisplay {
    if (name.isNotEmpty) return name;
    if (email.isNotEmpty) return email;
    if (userId > 0) return 'User #$userId';
    return 'Unknown';
  }

  factory AdminNotificationData.fromJson(Map<String, dynamic> json) {
    return AdminNotificationData(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      type: json['type'] as int? ?? 0,
      notificationType: json['notification_type'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      isRead: json['is_read'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      submitterImage: json['submitter_image'] as String?,
      sourceId: json['source_id'] as int?,
      deletedAt: _tryParse(json['deletedAt']),
      createdAt: _tryParse(json['createdAt']) ?? DateTime.now(),
      updatedAt: _tryParse(json['updatedAt']) ?? DateTime.now(),
    );
  }

  static DateTime? _tryParse(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  /// Return a copy with is_read set to 1 (read).
  AdminNotificationData copyWithRead() => AdminNotificationData(
        id: id,
        userId: userId,
        type: type,
        notificationType: notificationType,
        title: title,
        description: description,
        isRead: 1,
        name: name,
        email: email,
        submitterImage: submitterImage,
        sourceId: sourceId,
        deletedAt: deletedAt,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

  /// The 4 notification types tracked by the admin dashboard.
  static const List<int> trackedTypes = [8, 10, 11, 13];
}
