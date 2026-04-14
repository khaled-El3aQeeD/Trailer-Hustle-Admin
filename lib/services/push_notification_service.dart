import 'package:flutter/foundation.dart';
import 'package:trailerhustle_admin/supabase/supabase_config.dart';

class PushCampaign {
  final int id;
  final String title;
  final String body;
  final String? filterSummary;
  final String? notificationType;
  final int totalTargets;
  final int totalSent;
  final int totalFailed;
  final String status;
  final DateTime createdAt;
  final DateTime? completedAt;

  const PushCampaign({
    required this.id,
    required this.title,
    required this.body,
    this.filterSummary,
    this.notificationType,
    required this.totalTargets,
    required this.totalSent,
    required this.totalFailed,
    required this.status,
    required this.createdAt,
    this.completedAt,
  });

  factory PushCampaign.fromJson(Map<String, dynamic> json) {
    return PushCampaign(
      id: json['id'] as int,
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      filterSummary: json['filter_summary']?.toString(),
      notificationType: json['notification_type']?.toString(),
      totalTargets: (json['total_targets'] as int?) ?? 0,
      totalSent: (json['total_sent'] as int?) ?? 0,
      totalFailed: (json['total_failed'] as int?) ?? 0,
      status: (json['status'] ?? 'unknown').toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())
          : null,
    );
  }
}

class SendPushResult {
  final bool success;
  final int? campaignId;
  final int totalTargets;
  final int totalSent;
  final int totalFailed;
  final String? error;

  const SendPushResult({
    required this.success,
    this.campaignId,
    this.totalTargets = 0,
    this.totalSent = 0,
    this.totalFailed = 0,
    this.error,
  });
}

class PushNotificationService {
  /// Send a push notification via the edge function.
  static Future<SendPushResult> sendPush({
    required String title,
    required String body,
    required List<int> userIds,
    required bool sendToAll,
    String? filterSummary,
    String notificationType = '4',
  }) async {
    try {
      final response = await SupabaseConfig.client.functions.invoke(
        'send-push-notification',
        body: {
          'title': title,
          'body': body,
          'user_ids': userIds,
          'send_to_all': sendToAll,
          'filter_summary': filterSummary,
          'notification_type': notificationType,
        },
      );

      if (response.status != 200) {
        final errorMsg =
            (response.data is Map ? response.data['error'] : null) ??
                'Request failed with status ${response.status}';
        return SendPushResult(success: false, error: errorMsg.toString());
      }

      final data = response.data as Map<String, dynamic>;
      return SendPushResult(
        success: data['success'] == true,
        campaignId: data['campaign_id'] as int?,
        totalTargets: (data['total_targets'] as int?) ?? 0,
        totalSent: (data['total_sent'] as int?) ?? 0,
        totalFailed: (data['total_failed'] as int?) ?? 0,
        error: data['error']?.toString(),
      );
    } catch (e) {
      debugPrint('PushNotificationService.sendPush error: $e');
      return SendPushResult(success: false, error: e.toString());
    }
  }

  /// Fetch recent campaigns for the history table.
  static Future<List<PushCampaign>> fetchCampaigns({int limit = 20}) async {
    try {
      final rows = await SupabaseConfig.client
          .from('push_campaigns')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      return (rows as List)
          .map((r) =>
              PushCampaign.fromJson((r as Map).cast<String, dynamic>()))
          .toList();
    } catch (e) {
      debugPrint('PushNotificationService.fetchCampaigns error: $e');
      return [];
    }
  }

  /// Fetch users eligible for push (have device_token, active).
  /// Returns minimal data needed for the recipient selector.
  static Future<List<PushRecipient>> fetchEligibleRecipients() async {
    try {
      final all = <Map<String, dynamic>>[];
      const pageSize = 1000;
      int offset = 0;

      while (true) {
        final batch = await SupabaseConfig.client
            .from('Businesses')
            .select(
                'id, display_name, email, device_token, category_id, subscriptionType, regularCityState, status')
            .not('device_token', 'is', null)
            .neq('device_token', '')
            .order('id', ascending: true)
            .range(offset, offset + pageSize - 1);

        final list = (batch as List)
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();
        all.addAll(list);
        if (list.length < pageSize) break;
        offset += pageSize;
      }

      return all.map(PushRecipient.fromJson).toList();
    } catch (e) {
      debugPrint('PushNotificationService.fetchEligibleRecipients error: $e');
      return [];
    }
  }

  /// Fetch category names for filter dropdowns.
  static Future<Map<int, String>> fetchCategories() async {
    try {
      final rows = await SupabaseConfig.client
          .from('Categories')
          .select('id, name')
          .order('position', ascending: true);

      final map = <int, String>{};
      for (final r in (rows as List)) {
        final id = r['id'] as int?;
        final name = (r['name'] ?? '').toString().trim();
        if (id != null && name.isNotEmpty) {
          map[id] = name;
        }
      }
      return map;
    } catch (e) {
      debugPrint('PushNotificationService.fetchCategories error: $e');
      return {};
    }
  }
}

class PushRecipient {
  final int id;
  final String name;
  final String email;
  final int? categoryId;
  final String subscriptionTier;
  final String location;
  final bool isActive;

  const PushRecipient({
    required this.id,
    required this.name,
    required this.email,
    this.categoryId,
    required this.subscriptionTier,
    required this.location,
    required this.isActive,
  });

  factory PushRecipient.fromJson(Map<String, dynamic> json) {
    final subType = json['subscriptionType'];
    final tier = subType == 2
        ? 'pro'
        : subType == 1
            ? 'lite'
            : 'free';
    return PushRecipient(
      id: json['id'] as int,
      name: (json['display_name'] ?? '').toString().trim(),
      email: (json['email'] ?? '').toString().trim(),
      categoryId: json['category_id'] as int?,
      subscriptionTier: tier,
      location: (json['regularCityState'] ?? '').toString().trim(),
      isActive: (json['status'] as int?) == 1,
    );
  }
}
