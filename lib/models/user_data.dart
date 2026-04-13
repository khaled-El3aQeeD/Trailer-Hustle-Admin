class UserData {
  /// Primary identifier (Supabase Auth `user.id` / UUID).
  ///
  /// In your Supabase schema this maps to `public."Businesses".id` (serial).
  final String id;

  /// Human-friendly, unique identifier visible in admin UI.
  ///
  /// Example: `TH-000123456`.
  final String customerNumber;

  /// Basic profile fields.
  final String name;
  final String email;
  final String phone;
  final String avatar;

  /// City + state as stored in Supabase (e.g. "Austin, TX").
  final String regularCityState;

  /// Public website for the business.
  final String website;

  /// Human-readable business category label.
  final String categoryType;

  /// Account flags used in the admin dashboard.
  final bool isSubscribed;
  final bool isActive;
  final bool hasHustleProPlan;

  /// Subscription tier: 'free', 'lite', or 'pro'.
  final String subscriptionTier;

  final DateTime createdAt;
  final DateTime updatedAt;

  // ── NEW FIELDS for full profile ──

  /// Supabase Auth UID (stored as `social_id` in Businesses table).
  final String socialId;

  /// Login provider: 0 = email/phone, 1 = google, 2 = apple.
  final int socialType;

  /// Secondary / alternate contact email.
  final String contactEmail;

  /// Country dial code for phone (e.g. 1 for US).
  final String countryCode;

  /// Business description / About Us.
  final String description;

  /// Social media handles.
  final String instagram;
  final String facebook;
  final String youtube;
  final String twitter;
  final String tiktok;

  /// Geo-location.
  final String location;
  final double latitude;
  final double longitude;
  final String zipCode;

  /// Business-specific contact.
  final String businessContactNumber;
  final String businessCountryCode;

  /// Cover image (separate from profile avatar).
  final String coverImage;

  /// Profile completion & verification flags.
  final bool isVerify;
  final int completeProfile;
  final bool isFeatured;

  /// Accent color hex string.
  final String color;

  /// Last login epoch timestamp.
  final int loginTime;

  /// Device type: 1=iOS, 2=Android.
  final int deviceType;

  /// Subscription end date.
  final DateTime? subscriptionEndDate;

  /// Category ID (raw FK, used for editing).
  final int? categoryId;

  /// Auth identity providers from `auth.identities` table.
  ///
  /// Values like `['email', 'phone', 'google', 'apple']`.
  /// Empty list means auth providers haven't been fetched yet.
  final List<String> authProviders;

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
    this.subscriptionTier = 'free',
    required this.createdAt,
    required this.updatedAt,
    this.socialId = '',
    this.socialType = 0,
    this.contactEmail = '',
    this.countryCode = '',
    this.description = '',
    this.instagram = '',
    this.facebook = '',
    this.youtube = '',
    this.twitter = '',
    this.tiktok = '',
    this.location = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.zipCode = '',
    this.businessContactNumber = '',
    this.businessCountryCode = '',
    this.coverImage = '',
    this.isVerify = false,
    this.completeProfile = 0,
    this.isFeatured = false,
    this.color = '',
    this.loginTime = 0,
    this.deviceType = 0,
    this.subscriptionEndDate,
    this.categoryId,
    this.authProviders = const [],
  });

  /// Computed login method label based on auth.identities providers (preferred)
  /// or fallback to social_type + heuristics.
  ///
  /// Returns the *primary* login method. Use [loginMethods] for a complete list.
  String get loginMethod {
    if (authProviders.isNotEmpty) return _normalizeProvider(authProviders.first);
    // Fallback to social_type when auth providers haven't been fetched
    if (socialType == 1) return 'Google';
    if (socialType == 2) return 'Apple';
    if (email.contains('privaterelay.appleid.com')) return 'Apple';
    if (email.trim().isNotEmpty) return 'Email';
    if (phone.trim().isNotEmpty) return 'Phone';
    return 'Email';
  }

  /// All detected authentication providers for this account.
  ///
  /// Prefers data from `auth.identities` when available. Falls back to
  /// social_type + heuristics otherwise.
  List<String> get loginMethods {
    if (authProviders.isNotEmpty) {
      return authProviders.map(_normalizeProvider).toList();
    }
    // Fallback to social_type
    if (socialType == 1) return const ['Google'];
    if (socialType == 2) return const ['Apple'];
    if (email.contains('privaterelay.appleid.com')) return const ['Apple'];

    final methods = <String>[];
    if (email.trim().isNotEmpty) methods.add('Email');
    if (phone.trim().isNotEmpty) methods.add('Phone');
    return methods.isEmpty ? const ['Email'] : methods;
  }

  /// Normalize raw Supabase identity provider strings to display labels.
  static String _normalizeProvider(String raw) {
    switch (raw.toLowerCase()) {
      case 'email':
        return 'Email';
      case 'phone':
        return 'Phone';
      case 'google':
        return 'Google';
      case 'apple':
        return 'Apple';
      default:
        // Capitalize first letter for unknown providers
        return raw.isEmpty ? raw : '${raw[0].toUpperCase()}${raw.substring(1)}';
    }
  }

  /// Whether the email is an Apple Private Relay.
  bool get isPrivateRelay => email.contains('privaterelay.appleid.com');

  /// Last login as DateTime (from epoch seconds). Returns null if 0.
  DateTime? get lastLoginDate =>
      loginTime > 0 ? DateTime.fromMillisecondsSinceEpoch(loginTime * 1000, isUtc: true) : null;

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
    String? subscriptionTier,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? socialId,
    int? socialType,
    String? contactEmail,
    String? countryCode,
    String? description,
    String? instagram,
    String? facebook,
    String? youtube,
    String? twitter,
    String? tiktok,
    String? location,
    double? latitude,
    double? longitude,
    String? zipCode,
    String? businessContactNumber,
    String? businessCountryCode,
    String? coverImage,
    bool? isVerify,
    int? completeProfile,
    bool? isFeatured,
    String? color,
    int? loginTime,
    int? deviceType,
    DateTime? subscriptionEndDate,
    int? categoryId,
    List<String>? authProviders,
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
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      socialId: socialId ?? this.socialId,
      socialType: socialType ?? this.socialType,
      contactEmail: contactEmail ?? this.contactEmail,
      countryCode: countryCode ?? this.countryCode,
      description: description ?? this.description,
      instagram: instagram ?? this.instagram,
      facebook: facebook ?? this.facebook,
      youtube: youtube ?? this.youtube,
      twitter: twitter ?? this.twitter,
      tiktok: tiktok ?? this.tiktok,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      zipCode: zipCode ?? this.zipCode,
      businessContactNumber: businessContactNumber ?? this.businessContactNumber,
      businessCountryCode: businessCountryCode ?? this.businessCountryCode,
      coverImage: coverImage ?? this.coverImage,
      isVerify: isVerify ?? this.isVerify,
      completeProfile: completeProfile ?? this.completeProfile,
      isFeatured: isFeatured ?? this.isFeatured,
      color: color ?? this.color,
      loginTime: loginTime ?? this.loginTime,
      deviceType: deviceType ?? this.deviceType,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
      categoryId: categoryId ?? this.categoryId,
      authProviders: authProviders ?? this.authProviders,
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
  static int _parseInt(dynamic v, {required int fallback}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().trim()) ?? fallback;
  }

  static int? _parseNullableInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().trim());
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().trim()) ?? 0.0;
  }  /// Derive subscription tier from subscriptionType (smallint in DB).
  /// 0 or null → 'free', 1 → 'lite', 2+ → 'pro'.
  /// Also accepts string values like 'free', 'lite', 'pro'.
  static String _parseTierFromSubscriptionType(dynamic v, {required bool isSubscribed}) {
    if (v == null) return isSubscribed ? 'lite' : 'free';
    if (v is num) {
      final n = v.toInt();
      if (n <= 0) return 'free';
      if (n == 1) return 'lite';
      return 'pro';
    }
    final s = v.toString().trim().toLowerCase();
    if (s == 'free') return 'free';
    if (s == 'lite' || s == 'basic') return 'lite';
    if (s == 'pro' || s == 'premium') return 'pro';
    final n = int.tryParse(s);
    if (n != null) {
      if (n <= 0) return 'free';
      if (n == 1) return 'lite';
      return 'pro';
    }
    return isSubscribed ? 'lite' : 'free';
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
    final isSubscribed = _parseBool(
      json['is_subscribed'] ?? json['isSubscribed'],
      fallback: _parseSubscribedFromStatus(json['subscriptionStatus'] ?? json['subscription_status'], fallback: false),
    );
    final subscriptionTypeRaw = json['subscriptionType'] ?? json['subscription_type'];
    final tier = _parseTierFromSubscriptionType(subscriptionTypeRaw, isSubscribed: isSubscribed);

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
      isSubscribed: isSubscribed,
      isActive: _parseBool(
        json['is_active'] ?? json['isActive'],
        fallback: _parseActiveFromStatus(json['status'] ?? json['account_status'], fallback: true),
      ),
      hasHustleProPlan: _parseBool(
        json['has_hustle_pro_plan'] ?? json['hasHustleProPlan'],
        fallback: _parseHustleProFromSubscriptionType(subscriptionTypeRaw, fallback: false),
      ),
      subscriptionTier: tier,
      createdAt: _parseDate(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDate(json['updated_at'] ?? json['updatedAt']),
      // New fields
      socialId: (json['social_id'] ?? json['socialId'] ?? '').toString(),
      socialType: _parseInt(json['social_type'] ?? json['socialType'], fallback: 0),
      contactEmail: (json['contact_email'] ?? json['contactEmail'] ?? '').toString(),
      countryCode: (json['country_code'] ?? json['countryCode'] ?? '').toString(),
      description: (json['description'] ?? json['about'] ?? json['bio'] ?? '').toString(),
      instagram: (json['instagram'] ?? '').toString(),
      facebook: (json['facebook'] ?? '').toString(),
      youtube: (json['youtube'] ?? '').toString(),
      twitter: (json['twitter'] ?? '').toString(),
      tiktok: (json['tiktok'] ?? '').toString(),
      location: (json['location'] ?? json['address'] ?? '').toString(),
      latitude: _parseDouble(json['latitude'] ?? json['lat']),
      longitude: _parseDouble(json['longitude'] ?? json['lng'] ?? json['lon']),
      zipCode: (json['zip_code'] ?? json['zipCode'] ?? json['postal_code'] ?? '').toString(),
      businessContactNumber: (json['business_contact_number'] ?? json['businessContactNumber'] ?? '').toString(),
      businessCountryCode: (json['business_country_code'] ?? json['businessCountryCode'] ?? '').toString(),
      coverImage: (json['image'] ?? json['cover_image'] ?? json['coverImage'] ?? '').toString(),
      isVerify: _parseBool(json['is_verify'] ?? json['isVerify'] ?? json['is_verified'], fallback: false),
      completeProfile: _parseInt(json['complete_profile'] ?? json['completeProfile'], fallback: 0),
      isFeatured: _parseBool(json['is_featured'] ?? json['isFeatured'], fallback: false),
      color: (json['color'] ?? '').toString(),
      loginTime: _parseInt(json['loginTime'] ?? json['login_time'] ?? json['last_login'], fallback: 0),
      deviceType: _parseInt(json['device_type'] ?? json['deviceType'], fallback: 0),
      subscriptionEndDate: json['subscriptionEndDate'] != null || json['subscription_end_date'] != null
          ? _parseDate(json['subscriptionEndDate'] ?? json['subscription_end_date'])
          : null,
      categoryId: _parseNullableInt(json['category_id'] ?? json['categoryId']),
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
      'subscriptionTier': subscriptionTier,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'social_id': socialId,
      'social_type': socialType,
      'contact_email': contactEmail,
      'country_code': countryCode,
      'description': description,
      'instagram': instagram,
      'facebook': facebook,
      'youtube': youtube,
      'twitter': twitter,
      'tiktok': tiktok,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'zip_code': zipCode,
      'business_contact_number': businessContactNumber,
      'business_country_code': businessCountryCode,
      'image': coverImage,
      'is_verify': isVerify,
      'complete_profile': completeProfile,
      'is_featured': isFeatured,
      'color': color,
      'loginTime': loginTime,
      'device_type': deviceType,
      if (subscriptionEndDate != null)
        'subscriptionEndDate': subscriptionEndDate!.toUtc().toIso8601String(),
      if (categoryId != null) 'category_id': categoryId,
    };
  }
}