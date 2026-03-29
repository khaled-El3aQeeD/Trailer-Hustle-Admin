import 'package:trailerhustle_admin/models/giveaway_participant.dart';
import 'package:trailerhustle_admin/services/giveaway_service.dart';

class Giveaway {
  final String id;
  final String title;
  final String description;
  final String image;
  final String termsAndConditions;
  final String? howToParticipate;
  final int sponsorId;
  /// True when the giveaway exists but is not yet published/active.
  final bool isDraft;
  final DateTime scheduledArchiveAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;
  final String? winnerUserId;
  final List<GiveawayParticipant> participants;

  Giveaway({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.termsAndConditions,
    required this.sponsorId,
    this.howToParticipate,
    this.isDraft = false,
    required this.scheduledArchiveAt,
    required this.createdAt,
    required this.updatedAt,
    required this.participants,
    this.archivedAt,
    this.winnerUserId,
  });

  bool get isArchived => archivedAt != null;

  bool isDueForArchive(DateTime now) {
    if (isDraft) return false;
    return isArchived || now.isAfter(scheduledArchiveAt) || now.isAtSameMomentAs(scheduledArchiveAt);
  }

  Giveaway copyWith({
    String? title,
    String? description,
    String? image,
    String? termsAndConditions,
    String? howToParticipate,
    int? sponsorId,
    bool? isDraft,
    DateTime? scheduledArchiveAt,
    DateTime? updatedAt,
    DateTime? archivedAt,
    String? winnerUserId,
    List<GiveawayParticipant>? participants,
  }) => Giveaway(
    id: id,
    title: title ?? this.title,
    description: description ?? this.description,
    image: image ?? this.image,
    termsAndConditions: termsAndConditions ?? this.termsAndConditions,
    sponsorId: sponsorId ?? this.sponsorId,
    howToParticipate: howToParticipate ?? this.howToParticipate,
    isDraft: isDraft ?? this.isDraft,
    scheduledArchiveAt: scheduledArchiveAt ?? this.scheduledArchiveAt,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    archivedAt: archivedAt ?? this.archivedAt,
    winnerUserId: winnerUserId ?? this.winnerUserId,
    participants: participants ?? this.participants,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'image': image,
    'terms_and_conditions': termsAndConditions,
    'how_to_participate': howToParticipate,
    'sponsor_id': sponsorId,
    'is_draft': isDraft,
    'scheduled_archive_at': scheduledArchiveAt.toUtc().toIso8601String(),
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'archived_at': archivedAt?.toUtc().toIso8601String(),
    'winner_user_id': winnerUserId,
    'participants': participants.map((p) => p.toJson()).toList(),
  };

  static Giveaway fromJson(Map<String, dynamic> json) {
    dynamic pick(String snake, String camel) => json.containsKey(snake) ? json[snake] : json[camel];

    DateTime parseDate(dynamic v) => DateTime.parse(v.toString()).toLocal();
    final participants = (json['participants'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(GiveawayParticipant.fromJson)
            .toList() ??
        <GiveawayParticipant>[];

    return Giveaway(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (pick('description', 'description') ?? '').toString(),
      image: (pick('image', 'image') ?? '').toString(),
      termsAndConditions: (pick('terms_and_conditions', 'termsAndConditions') ?? pick('termsAndConditions', 'terms_and_conditions') ?? '').toString(),
      howToParticipate: pick('how_to_participate', 'howToParticipate')?.toString(),
      sponsorId: int.tryParse((pick('sponsor_id', 'sponsorId') ?? '0').toString()) ?? 0,
      isDraft: pick('is_draft', 'isDraft') == true || pick('is_draft', 'isDraft')?.toString() == 'true',
      scheduledArchiveAt: parseDate(pick('scheduled_archive_at', 'winnerAnnouncementDate') ?? pick('scheduled_archive_at', 'scheduledArchiveAt')),
      createdAt: parseDate(pick('created_at', 'createdAt')),
      updatedAt: parseDate(pick('updated_at', 'updatedAt')),
      archivedAt: pick('archived_at', 'archivedAt') == null ? null : parseDate(pick('archived_at', 'archivedAt')),
      winnerUserId: pick('winner_user_id', 'winnerUserId')?.toString(),
      participants: participants,
    );
  }

  /// Map your existing Supabase `Giveaways` row (camelCase keys) into the app model.
  ///
  /// Current Supabase schema stores `isArchived` (0 or 1) separately from
  /// `isDeclared`. A giveaway is considered archived if:
  ///   - `isArchived` == 1 (date expired, set by server cron), OR
  ///   - `isDeclared` == 1 (winner picked), OR
  ///   - `winnerAnnouncementDate` is in the past (client-side safety)
  ///
  /// `scheduledArchiveAt` <- `winnerAnnouncementDate`
  static Giveaway fromSupabaseRow({
    required Map<String, dynamic> row,
    required List<GiveawayParticipant> participants,
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();
    final createdAt = DateTime.parse(row['createdAt'].toString()).toLocal();
    final updatedAt = DateTime.parse(row['updatedAt'].toString()).toLocal();
    final announcement = DateTime.parse(row['winnerAnnouncementDate'].toString()).toLocal();
    final isDeclared = (row['isDeclared'] ?? 0).toString() == '1';
    final isArchivedFlag = (row['isArchived'] ?? 0).toString() == '1';
    final isPast = t.isAfter(announcement) || t.isAtSameMomentAs(announcement);

    final winnerUserId = (row['winnerUserId'] ?? row['winner_user_id'])?.toString();

    return Giveaway(
      id: (row['id'] ?? '').toString(),
      title: (row['title'] ?? '').toString(),
      description: (row['description'] ?? '').toString(),
      image: GiveawayService.resolveStorageUrl(row['image']) ?? (row['image'] ?? '').toString(),
      termsAndConditions: (row['termsAndConditions'] ?? row['terms_and_conditions'] ?? '').toString(),
      howToParticipate: row['howToParticipate']?.toString(),
      sponsorId: (row['sponsorId'] is int)
          ? (row['sponsorId'] as int)
          : int.tryParse((row['sponsorId'] ?? '0').toString()) ?? 0,
      isDraft: false,
      scheduledArchiveAt: announcement,
      createdAt: createdAt,
      updatedAt: updatedAt,
      archivedAt: (isDeclared || isArchivedFlag || isPast) ? announcement : null,
      winnerUserId: (winnerUserId == null || winnerUserId.trim().isEmpty) ? null : winnerUserId,
      participants: participants,
    );
  }
}
