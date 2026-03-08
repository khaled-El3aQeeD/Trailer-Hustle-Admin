class UserData {
  /// Primary identifier (Supabase Auth `user.id` / UUID).
  ///
  /// In your Supabase schema this maps to `public."Businesses".id` (serial).
  final String id;

  /// Human-friendly, unique identifier visible in admin UI.
  ///
  /// Example: `TH-000123456`.
  /// In this project, this is intended to be persisted on your Businesses table
  /// (for example `public.businesses.business_number` or `public.businesses.customer_number`,
  /// depending on your schema).
  final String customerNumber;

  /// Basic profile fields. In this template these map to your Businesses table.
  final String name;
  final String email;
  final String phone;
  final String avatar;

  /// City + state as stored in Supabase.
  ///
  /// This app treats `Businesses.regularCityState` as the single source of truth
  /// and displays it as-is (e.g. "Austin, TX").
  final String regularCityState;

  /// Public website for the business.
  ///
  /// Common column names in Supabase schemas: `website`, `website_url`, `business_website`.
  final String website;

  /// Human-readable business category label.
  ///
  /// This is typically derived from `Businesses.category_id -> Categories.name`.
  final String categoryType;

  /// Account flags used in the admin dashboard.
  final bool isSubscribed;
  final bool isActive;
  final bool hasHustleProPlan;

  final DateTime createdAt;
  final DateTime updatedAt;

  const UserData({
    required this.id,
    required this.customerNumber,
    required this.name,
    required this.email,
    required this.phone,
    required this.avatar,
    required this.regularCityState,
    required this.website,
    required this.categoryType,
    required this.isSubscribed,
    required this.isActive,
    required this.hasHustleProPlan,
    required this.createdAt,
    required this.updatedAt,
  });

  UserData copyWith({
    String? id,
    String? customerNumber,
    String? name,
    String? email,
    String? phone,
    String? avatar,
    String? regularCityState,
    String? website,
    String? categoryType,
    bool? isSubscribed,
    bool? isActive,
    bool? hasHustleProPlan,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserData(
      id: id ?? this.id,
      customerNumber: customerNumber ?? this.customerNumber,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      regularCityState: regularCityState ?? this.regularCityState,
      website: website ?? this.website,
      categoryType: categoryType ?? this.categoryType,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      isActive: isActive ?? this.isActive,
      hasHustleProPlan: hasHustleProPlan ?? this.hasHustleProPlan,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    if (v is DateTime) return v.toUtc();
    return DateTime.tryParse(v.toString())?.toUtc() ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  static bool _parseBool(dynamic v, {required bool fallback}) {
    if (v == null) return fallback;
    if (v is bool) return v;
    final s = v.toString().trim().toLowerCase();
    if (s == 'true' || s == '1' || s == 'yes') return true;
    if (s == 'false' || s == '0' || s == 'no') return false;
    return fallback;
  }

  static bool _parseSubscribedFromStatus(dynamic v, {required bool fallback}) {
    if (v == null) return fallback;
    // Common patterns we see in real schemas.
    if (v is bool) return v;
    if (v is num) return v.toInt() != 0;
    final s = v.toString().trim().toLowerCase();
    if (s.isEmpty) return fallback;
    // Subscription status strings.
    if (s == 'active' || s == 'subscribed' || s == 'trialing' || s == 'trial' || s == 'paid') return true;
    if (s == 'inactive' || s == 'expired' || s == 'canceled' || s == 'cancelled' || s == 'unpaid') return false;
    // Numeric-ish strings.
    if (s == '1' || s == 'true' || s == 'yes') return true;
    if (s == '0' || s == 'false' || s == 'no') return false;
    return fallback;
  }

  static bool _parseActiveFromStatus(dynamic v, {required bool fallback}) {
    if (v == null) return fallback;
    if (v is bool) return v;
    if (v is num) return v.toInt() == 1;
    final s = v.toString().trim().toLowerCase();
    if (s == '1' || s == 'active' || s == 'true' || s == 'yes') return true;
    if (s == '0' || s == 'inactive' || s == 'false' || s == 'no') return false;
    return fallback;
  }

  static bool _parseHustleProFromSubscriptionType(dynamic v, {required bool fallback}) {
    if (v == null) return fallback;
    if (v is num) {
      // Convention used in many apps: 2 => “pro/premium”.
      return v.toInt() >= 2;
    }
    final s = v.toString().trim().toLowerCase();
    final n = int.tryParse(s);
    if (n != null) return n >= 2;
    if (s.contains('pro') || s.contains('premium')) return true;
    return fallback;
  }

  factory UserData.fromJson(Map<String, dynamic> json) {
    String categoryFromJoinedObject() {
      final v = json['Categories'] ?? json['Category'] ?? json['category'];
      if (v is Map) {
        final name = (v['name'] ?? v['title'] ?? '').toString().trim();
        if (name.isNotEmpty) return name;
      }
      return '';
    }

    // Your Businesses table uses `display_name` and `mobile_number`.
    // It also uses `subscriptionStatus` (string) and `status` (int).
    return UserData(
      id: (json['id'] ?? '').toString(),
      customerNumber: (json['customer_number'] ??
              json['business_number'] ??
              json['businessNumber'] ??
              json['customerNumber'] ??
              json['business_id'] ??
              json['businessId'] ??
              '')
          .toString(),
      email: (json['email'] ?? '').toString(),
      name: (json['display_name'] ?? json['name'] ?? json['business_name'] ?? json['company_name'] ?? json['title'] ?? '').toString(),
      phone: (json['mobile_number'] ?? json['business_contact_number'] ?? json['phone'] ?? json['phone_number'] ?? json['mobile'] ?? '').toString(),
      avatar: (json['profile_image'] ?? json['image'] ?? json['avatar_url'] ?? json['logo_url'] ?? json['image_url'] ?? json['avatar'] ?? json['logo'] ?? '').toString(),
      regularCityState: (json['regularCityState'] ?? json['regular_city_state'] ?? json['cityState'] ?? json['city_state'] ?? '').toString().trim(),
      website: (json['website'] ?? json['website_url'] ?? json['web_site'] ?? json['business_website'] ?? json['businessWebsite'] ?? json['url'] ?? '').toString().trim(),
      categoryType: (json['category_type'] ?? json['categoryType'] ?? json['category_name'] ?? json['categoryName'] ?? categoryFromJoinedObject()).toString().trim(),
      isSubscribed: _parseBool(
        json['is_subscribed'] ?? json['isSubscribed'],
        fallback: _parseSubscribedFromStatus(json['subscriptionStatus'] ?? json['subscription_status'], fallback: false),
      ),
      isActive: _parseBool(
        json['is_active'] ?? json['isActive'],
        fallback: _parseActiveFromStatus(json['status'] ?? json['account_status'], fallback: true),
      ),
      hasHustleProPlan: _parseBool(
        json['has_hustle_pro_plan'] ?? json['hasHustleProPlan'],
        fallback: _parseHustleProFromSubscriptionType(json['subscriptionType'] ?? json['subscription_type'], fallback: false),
      ),
      createdAt: _parseDate(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDate(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_number': customerNumber,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar_url': avatar,
      'regularCityState': regularCityState,
      'website': website,
      'categoryType': categoryType,
      'is_subscribed': isSubscribed,
      'is_active': isActive,
      'has_hustle_pro_plan': hasHustleProPlan,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }
}