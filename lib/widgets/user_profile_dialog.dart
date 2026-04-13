import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:flutter/foundation.dart';
import 'package:trailerhustle_admin/models/service_item_data.dart';
import 'package:trailerhustle_admin/models/trailer_data.dart';
import 'package:trailerhustle_admin/models/user_data.dart';
import 'package:trailerhustle_admin/services/service_item_service.dart';
import 'package:trailerhustle_admin/services/product_service.dart';
import 'package:trailerhustle_admin/services/trailer_service.dart';

/// Business details pop-up (used for Businesses table records).
///
/// Opens from the Businesses table (View action) and sidebar footer user card.
///
/// Design goals:
/// - Much wider dialog on desktop (double-width feel)
/// - AirBnB-style cards (rounded, light borders, soft shadows)
/// - Top tabs for: Summary, Trailers, Services & Products, Branches
class UserProfileDialog extends StatelessWidget {
  const UserProfileDialog({super.key, required this.user, this.initialTabIndex = 0});
  final UserData user;
  final int initialTabIndex;

  /// Expose tab builders so the full-page [UserProfilePage] can reuse them.
  static Widget buildSummaryTab(BuildContext context, {required UserData user, required String name, required String email, required String phone, required String cityState}) {
    return _BusinessSummaryTab(user: user, name: name, email: email, phone: phone, cityState: cityState, website: user.website);
  }

  static Widget buildTrailersTab({required UserData user}) {
    return _TrailersTab(user: user);
  }

  static Widget buildServicesTab({required UserData user}) {
    return _ServicesTab(user: user);
  }



  static Future<void> show(BuildContext context, {required UserData user, int initialTabIndex = 0}) async {
    final mq = MediaQuery.of(context);
    final width = mq.size.width;
    final height = mq.size.height;
    final isCompact = width < 640;
    final safeTabIndex = initialTabIndex.clamp(0, 2);

    if (isCompact) {
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: FractionallySizedBox(
                heightFactor: 0.92,
                child: _DialogSurface(
                  child: UserProfileDialog(user: user, initialTabIndex: safeTabIndex),
                ),
              ),
            ),
          );
        },
      );
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        // Make the desktop dialog ~60% wider than the previous “double-width” feel,
        // while still respecting the available viewport.
        //
        // Important: on many laptop screens you physically can't get a full +60%
        // width increase without overflowing. So we:
        // 1) scale the previous “comfortable desktop” width by 1.6
        // 2) cap at ~96% of the viewport
        // 3) slightly reduce dialog inset padding
        final baseWidth = (width * 0.70).clamp(720.0, 1120.0);
        final maxWidth = (baseWidth * 1.6).clamp(720.0, width * 0.96);
        final maxHeight = (height * 0.86).clamp(520.0, 860.0);
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth, minWidth: 720, maxHeight: maxHeight),
            child: _DialogSurface(
              child: UserProfileDialog(user: user, initialTabIndex: safeTabIndex),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final email = user.email.trim().isEmpty ? '—' : user.email.trim();
    final phone = user.phone.trim().isEmpty ? '—' : user.phone.trim();
    final name = user.name.trim().isEmpty ? '—' : user.name.trim();
    final cityState = user.regularCityState.trim().isEmpty ? '—' : user.regularCityState.trim();

    return DefaultTabController(
      length: 3,
      initialIndex: initialTabIndex.clamp(0, 2),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 14, 12),
            child: Row(
              children: [
                FAvatar(image: NetworkImage(user.avatar), size: 56),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.typography.lg.copyWith(fontWeight: FontWeight.w800, color: theme.colors.foreground),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              email,
                              style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                          _Pill(
                            icon: Icons.confirmation_number_outlined,
                            text: user.customerNumber.trim().isEmpty ? 'Business ID —' : 'Business ID ${user.customerNumber.trim()}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(FIcons.x),
                  iconSize: 16,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(38, 38),
                    padding: EdgeInsets.zero,
                    foregroundColor: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colors.muted.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colors.border),
              ),
              child: TabBar(
                dividerColor: Colors.transparent,
                labelColor: theme.colors.foreground,
                unselectedLabelColor: theme.colors.mutedForeground,
                labelStyle: theme.typography.sm.copyWith(fontWeight: FontWeight.w800),
                unselectedLabelStyle: theme.typography.sm.copyWith(fontWeight: FontWeight.w700),
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: theme.colors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.colors.border),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colors.foreground.withValues(alpha: 0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                tabs: const [
                  Tab(text: 'Business Summary'),
                  Tab(text: 'Trailers'),
                  Tab(text: 'Services & Products'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              children: [
                _BusinessSummaryTab(user: user, name: name, email: email, phone: phone, cityState: cityState, website: user.website),
                _TrailersTab(user: user),
                _ServicesTab(user: user),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrailersTab extends StatefulWidget {
  const _TrailersTab({required this.user});
  final UserData user;

  @override
  State<_TrailersTab> createState() => _TrailersTabState();
}

class _ServicesTab extends StatefulWidget {
  const _ServicesTab({required this.user});
  final UserData user;

  @override
  State<_ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends State<_ServicesTab> {
  Future<({List<ServiceItemData> services, List<ServiceItemData> products})>? _future;
  int _modeIndex = 0; // 0 = services, 1 = products

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<({List<ServiceItemData> services, List<ServiceItemData> products})> _load() async {
    final businessId = int.tryParse(widget.user.id.trim());
    if (businessId == null) {
      debugPrint('Services tab: could not parse business id from user.id="${widget.user.id}"');
      return (services: const <ServiceItemData>[], products: const <ServiceItemData>[]);
    }

    // Fetch from both sources in parallel
    final results = await Future.wait([
      ServiceItemService.fetchServicesForBusiness(businessId: businessId),
      ProductService.fetchProductsForBusiness(businessId: businessId),
    ]);

    final serviceItems = results[0];
    final productItems = results[1];

    // Split serviceItems into services vs products (from the services table)
    final services = <ServiceItemData>[];
    final productsFromServices = <ServiceItemData>[];
    for (final item in serviceItems) {
      final type = item.type.trim().toLowerCase();
      if (type.contains('product')) {
        productsFromServices.add(item);
      } else {
        services.add(item);
      }
    }

    // Merge products from both tables (Products table + services table)
    final allProducts = [...productItems, ...productsFromServices];

    return (services: services, products: allProducts);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return FutureBuilder<({List<ServiceItemData> services, List<ServiceItemData> products})>(
      future: _future,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final err = snapshot.error;

        if (isLoading) {
          return const _ServicesLoadingState();
        }

        if (err != null) {
          debugPrint('Services tab load error: $err');
          return _ServicesErrorState(
            message: err.toString(),
            onRetry: () => setState(() => _future = _load()),
          );
        }

        final data = snapshot.data;
        final services = data?.services ?? const <ServiceItemData>[];
        final products = data?.products ?? const <ServiceItemData>[];

        if (services.isEmpty && products.isEmpty) {
          final businessId = int.tryParse(widget.user.id.trim());
          final hint = businessId == null
              ? 'This business record has a non-numeric id ("${widget.user.id}").'
              : 'No services or products found for business id ($businessId).';
          debugPrint('Services tab empty-state debug hint: $hint');
          return const _ServicesEmptyState();
        }

        final showingProducts = _modeIndex == 1;
        final visibleItems = showingProducts ? products : services;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
          child: Column(
            children: [
              _AirbnbCard(
                title: showingProducts
                    ? 'Products (${visibleItems.length})'
                    : 'Services (${visibleItems.length})',
                icon: Icons.storefront_outlined,
                child: Column(
                  children: [
                    _ServicesProductsSubmenu(
                      selectedIndex: _modeIndex,
                      servicesCount: services.length,
                      productsCount: products.length,
                      onChanged: (value) => setState(() => _modeIndex = value),
                    ),
                    const SizedBox(height: 12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: visibleItems.isEmpty
                          ? _ServicesProductsEmptyPanel(
                              key: ValueKey('empty-$_modeIndex'),
                              modeIndex: _modeIndex,
                            )
                          : Column(
                              key: ValueKey('list-$_modeIndex'),
                              children: [
                                for (final s in visibleItems) ...[
                                  _ServiceItemRow(item: s),
                                  if (s != visibleItems.last) const SizedBox(height: 10),
                                ],
                              ],
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Source: Supabase services & Products tables • Showing ${showingProducts ? 'products' : 'services'}',
                  style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ServicesProductsSubmenu extends StatelessWidget {
  const _ServicesProductsSubmenu({
    required this.selectedIndex,
    required this.servicesCount,
    required this.productsCount,
    required this.onChanged,
  });

  final int selectedIndex;
  final int servicesCount;
  final int productsCount;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: theme.colors.muted.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SegmentedButton<int>(
            segments: [
              ButtonSegment<int>(
                value: 0,
                label: Text('Services ($servicesCount)'),
                icon: Icon(Icons.design_services_outlined, color: theme.colors.foreground),
              ),
              ButtonSegment<int>(
                value: 1,
                label: Text('Products ($productsCount)'),
                icon: Icon(Icons.shopping_bag_outlined, color: theme.colors.foreground),
              ),
            ],
            selected: {selectedIndex},
            showSelectedIcon: false,
            style: ButtonStyle(
              textStyle: WidgetStatePropertyAll(theme.typography.sm.copyWith(fontWeight: FontWeight.w900)),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return theme.colors.primaryForeground;
                return theme.colors.foreground;
              }),
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return theme.colors.primary;
                return Colors.transparent;
              }),
              side: WidgetStatePropertyAll(BorderSide(color: theme.colors.border)),
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            ),
            onSelectionChanged: (values) {
              final v = values.isEmpty ? 0 : values.first;
              onChanged(v);
            },
          );
        },
      ),
    );
  }
}

class _ServicesProductsEmptyPanel extends StatelessWidget {
  const _ServicesProductsEmptyPanel({super.key, required this.modeIndex});
  final int modeIndex;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final isProducts = modeIndex == 1;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colors.muted.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: theme.colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colors.border),
            ),
            alignment: Alignment.center,
            child: Icon(isProducts ? Icons.shopping_bag_outlined : Icons.design_services_outlined, size: 18, color: theme.colors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isProducts
                  ? 'No products yet.'
                  : 'No services yet.',
              style: theme.typography.sm.copyWith(color: theme.colors.foreground, height: 1.35, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServicesLoadingState extends StatelessWidget {
  const _ServicesLoadingState();

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
      child: _AirbnbCard(
        title: 'Services & Products',
        icon: Icons.storefront_outlined,
        child: Column(
          children: [
            for (var i = 0; i < 4; i++) ...[
              Container(
                width: double.infinity,
                height: 84,
                decoration: BoxDecoration(
                  color: theme.colors.muted.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colors.border),
                ),
              ),
              if (i != 3) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _ServicesEmptyState extends StatelessWidget {
  const _ServicesEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
      child: _AirbnbCard(
        title: 'Services & Products',
        icon: Icons.storefront_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This user has not created any products or services yet.',
              style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServicesErrorState extends StatelessWidget {
  const _ServicesErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
      child: _AirbnbCard(
        title: 'Services & Products',
        icon: Icons.storefront_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Could not load services from Supabase.',
              style: theme.typography.sm.copyWith(fontWeight: FontWeight.w900, color: theme.colors.foreground),
            ),
            const SizedBox(height: 8),
            Text(message, style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground, height: 1.4)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FButton(
                    onPress: onRetry,
                    style: FButtonStyle.primary(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.refresh, size: 18, color: theme.colors.primaryForeground),
                        SizedBox(width: 8),
                        Text('Retry', style: TextStyle(color: theme.colors.primaryForeground)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceItemRow extends StatelessWidget {
  const _ServiceItemRow({required this.item});
  final ServiceItemData item;

  String _subtitle() {
    final parts = <String>[];
    if (item.type.trim().isNotEmpty) parts.add(item.type.trim());
    if (item.description.trim().isNotEmpty) parts.add(item.description.trim());
    return parts.isEmpty ? '—' : parts.join(' · ');
  }

  String _priceText() {
    if (item.price <= 0) return '—';
    final cur = item.currency.trim().isEmpty ? 'USD' : item.currency.trim().toUpperCase();
    final amt = item.price.toStringAsFixed(item.price % 1 == 0 ? 0 : 2);
    return '$cur $amt';
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colors.muted.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 84,
              height: 64,
              color: theme.colors.muted.withValues(alpha: 0.20),
              child: item.image.trim().isEmpty
                  ? Icon(Icons.storefront_outlined, color: theme.colors.mutedForeground, size: 22)
                  : Image.network(
                      item.image,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image_outlined, color: theme.colors.mutedForeground, size: 22),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: theme.typography.sm.copyWith(fontWeight: FontWeight.w900, color: theme.colors.foreground),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _subtitle(),
                  style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground, height: 1.3, fontWeight: FontWeight.w800),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colors.background,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: theme.colors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.payments_outlined, size: 14, color: theme.colors.primary),
                    const SizedBox(width: 6),
                    Text(
                      _priceText(),
                      style: theme.typography.xs.copyWith(fontWeight: FontWeight.w900, color: theme.colors.foreground),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: item.isActive ? theme.colors.secondary.withValues(alpha: 0.14) : theme.colors.muted.withValues(alpha: 0.30),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: theme.colors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.isActive ? Icons.check_circle_outline : Icons.pause_circle_outline,
                      size: 14,
                      color: item.isActive ? theme.colors.secondary : theme.colors.mutedForeground,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.isActive ? 'Active' : 'Inactive',
                      style: theme.typography.xs.copyWith(fontWeight: FontWeight.w900, color: theme.colors.foreground),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrailersTabState extends State<_TrailersTab> {
  Future<List<TrailerData>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  /// Primary trailer image resolved from the `trailerimages` table.
  /// Keyed by trailer id.
  Map<int, String> _primaryImages = const {};

  Future<List<TrailerData>> _load() async {
    final businessId = int.tryParse(widget.user.id.trim());
    if (businessId == null) {
      debugPrint('Trailers tab: could not parse business id from user.id="${widget.user.id}"');
      return const <TrailerData>[];
    }
    final trailers = await TrailerService.fetchTrailersForBusiness(businessId: businessId);

    // Fetch primary images from trailerimages table (same approach as mobile)
    final trailerIds = trailers.map((t) => t.id).where((id) => id > 0).toList();
    if (trailerIds.isNotEmpty) {
      _primaryImages = await TrailerService.fetchPrimaryTrailerImagesByTrailerIds(trailerIds: trailerIds);
    }
    return trailers;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return FutureBuilder<List<TrailerData>>(
      future: _future,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final err = snapshot.error;
        final trailers = snapshot.data ?? const <TrailerData>[];

        if (isLoading) {
          return const _TrailersLoadingState();
        }

        if (err != null) {
          debugPrint('Trailers tab load error: $err');
          return _TrailersErrorState(
            message: err.toString(),
            onRetry: () => setState(() => _future = _load()),
          );
        }

        if (trailers.isEmpty) {
          final businessId = int.tryParse(widget.user.id.trim());
          final hint = businessId == null
              ? 'This business record has a non-numeric id ("${widget.user.id}").\nThe Trailers table expects bussinessid to be a number.'
              : 'No trailers found in Supabase table "Trailers" for bussinessid=$businessId.';

          return _TrailersEmptyState(hint: hint);
        }

        // Sort: active trailers first, then removed.
        final sorted = List<TrailerData>.of(trailers)
          ..sort((a, b) {
            if (a.isDeleted != b.isDeleted) return a.isDeleted ? 1 : -1;
            return 0;
          });
        final activeCount = sorted.where((t) => !t.isDeleted).length;
        final removedCount = sorted.where((t) => t.isDeleted).length;
        final headerParts = <String>[];
        if (activeCount > 0) headerParts.add('$activeCount Active');
        if (removedCount > 0) headerParts.add('$removedCount Removed');
        final headerLabel = headerParts.isEmpty
            ? 'Trailers (${sorted.length})'
            : 'Trailers (${headerParts.join(' · ')})';

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
          child: Column(
            children: [
              _AirbnbCard(
                title: headerLabel,
                icon: Icons.local_shipping_outlined,
                child: Column(
                  children: [
                    for (final t in sorted) ...[
                      _TrailerRow(trailer: t, resolvedImageUrl: _primaryImages[t.id]),
                      if (t != sorted.last) const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Source: Supabase Trailers table',
                  style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TrailersLoadingState extends StatelessWidget {
  const _TrailersLoadingState();

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
      child: _AirbnbCard(
        title: 'Trailers',
        icon: Icons.local_shipping_outlined,
        child: Column(
          children: [
            for (var i = 0; i < 4; i++) ...[
              Container(
                width: double.infinity,
                height: 84,
                decoration: BoxDecoration(
                  color: theme.colors.muted.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colors.border),
                ),
              ),
              if (i != 3) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrailersEmptyState extends StatelessWidget {
  const _TrailersEmptyState({required this.hint});
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
      child: _AirbnbCard(
        title: 'Trailers',
        icon: Icons.local_shipping_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No trailers are linked to this business yet.',
              style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground, height: 1.45),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colors.muted.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: theme.colors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colors.border),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.info_outline, size: 18, color: theme.colors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      hint,
                      style: theme.typography.sm.copyWith(color: theme.colors.foreground, height: 1.35, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrailersErrorState extends StatelessWidget {
  const _TrailersErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
      child: _AirbnbCard(
        title: 'Trailers',
        icon: Icons.local_shipping_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Could not load trailers from Supabase.', style: theme.typography.sm.copyWith(fontWeight: FontWeight.w900, color: theme.colors.foreground)),
            const SizedBox(height: 8),
            Text(message, style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground, height: 1.4)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FButton(
                    onPress: onRetry,
                    style: FButtonStyle.primary(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.refresh, size: 18, color: theme.colors.primaryForeground),
                        SizedBox(width: 8),
                        Text('Retry', style: TextStyle(color: theme.colors.primaryForeground)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrailerRow extends StatelessWidget {
  const _TrailerRow({required this.trailer, this.resolvedImageUrl});
  final TrailerData trailer;
  /// Primary image URL resolved from the `trailerimages` table.
  final String? resolvedImageUrl;

  String _primaryTitle() {
    final name = (trailer.trailerName ?? '').trim();
    if (name.isNotEmpty) return name;
    final dn = trailer.displayName.trim();
    if (dn.isNotEmpty) return dn;
    return 'Trailer #${trailer.id}';
  }

  String _subtitle() {
    final parts = <String>[];
    if (trailer.winNumber.trim().isNotEmpty) parts.add('WIN ${trailer.winNumber.trim()}');
    if (trailer.loadCapacity > 0) parts.add('Capacity ${trailer.loadCapacity}');
    if (trailer.length > 0 && trailer.width > 0) {
      final lu = trailer.lengthUnit.trim().isEmpty ? '' : ' ${trailer.lengthUnit.trim()}';
      final wu = trailer.widthUnit.trim().isEmpty ? '' : ' ${trailer.widthUnit.trim()}';
      parts.add('${trailer.length}$lu × ${trailer.width}$wu');
    }
    return parts.isEmpty ? '—' : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final deleted = trailer.isDeleted;
    return Opacity(
      opacity: deleted ? 0.55 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => TrailerDetailsDialog.show(context, trailer: trailer, resolvedImageUrl: resolvedImageUrl),
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          hoverColor: theme.colors.muted.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: deleted
                  ? theme.colors.destructive.withValues(alpha: 0.06)
                  : theme.colors.muted.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: deleted
                    ? theme.colors.destructive.withValues(alpha: 0.25)
                    : theme.colors.border,
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 84,
                    height: 64,
                    color: theme.colors.muted.withValues(alpha: 0.20),
                    child: () {
                      // Prefer the image from the trailerimages table; fall back to Trailers.image
                      final raw = (resolvedImageUrl ?? '').trim().isNotEmpty
                          ? resolvedImageUrl!.trim()
                          : trailer.image.trim();
                      if (raw.isEmpty) {
                        return Icon(Icons.image_not_supported_outlined, color: theme.colors.mutedForeground, size: 22);
                      }
                      final url = TrailerService.resolveTrailerImageUrl(raw);
                      return Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image_outlined, color: theme.colors.mutedForeground, size: 22),
                      );
                    }(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _primaryTitle(),
                        style: theme.typography.sm.copyWith(fontWeight: FontWeight.w900, color: theme.colors.foreground),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _subtitle(),
                        style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground, height: 1.3, fontWeight: FontWeight.w800),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: deleted
                        ? theme.colors.destructive.withValues(alpha: 0.12)
                        : const Color(0xFF22C55E).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: deleted
                          ? theme.colors.destructive.withValues(alpha: 0.35)
                          : const Color(0xFF22C55E).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        deleted ? Icons.remove_circle : Icons.check_circle,
                        size: 14,
                        color: deleted ? theme.colors.destructive : const Color(0xFF22C55E),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        deleted ? 'Removed' : 'Active',
                        style: theme.typography.xs.copyWith(
                          fontWeight: FontWeight.w900,
                          color: deleted ? theme.colors.destructive : const Color(0xFF22C55E),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colors.background,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: theme.colors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tag, size: 14, color: theme.colors.primary),
                      const SizedBox(width: 6),
                      Text('#${trailer.id}', style: theme.typography.xs.copyWith(fontWeight: FontWeight.w900, color: theme.colors.foreground)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(Icons.chevron_right, size: 18, color: theme.colors.mutedForeground),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TrailerDetailsDialog extends StatelessWidget {
  const TrailerDetailsDialog({super.key, required this.trailer, this.resolvedImageUrl});
  final TrailerData trailer;
  final String? resolvedImageUrl;

  static Future<void> show(BuildContext context, {required TrailerData trailer, String? resolvedImageUrl}) async {
    final mq = MediaQuery.of(context);
    final width = mq.size.width;
    final height = mq.size.height;
    final isCompact = width < 640;

    if (isCompact) {
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: FractionallySizedBox(
                heightFactor: 0.92,
                child: _DialogSurface(child: TrailerDetailsDialog(trailer: trailer, resolvedImageUrl: resolvedImageUrl)),
              ),
            ),
          );
        },
      );
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final maxWidth = (width * 0.62).clamp(560.0, 820.0);
        final maxHeight = (height * 0.86).clamp(520.0, 860.0);
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
            child: _DialogSurface(child: TrailerDetailsDialog(trailer: trailer, resolvedImageUrl: resolvedImageUrl)),
          ),
        );
      },
    );
  }

  static String _formatDateTime(BuildContext context, DateTime dt) {
    if (dt.millisecondsSinceEpoch == 0) return '—';
    final local = dt.toLocal();
    final ml = MaterialLocalizations.of(context);
    final date = ml.formatFullDate(local);
    final time = ml.formatTimeOfDay(TimeOfDay.fromDateTime(local), alwaysUse24HourFormat: false);
    return '$date · $time';
  }

  String _title() {
    final name = (trailer.trailerName ?? '').trim();
    if (name.isNotEmpty) return name;
    final dn = trailer.displayName.trim();
    if (dn.isNotEmpty) return dn;
    return 'Trailer #${trailer.id}';
  }

  String _sizeText() {
    if (trailer.length <= 0 || trailer.width <= 0) return '—';
    final lu = trailer.lengthUnit.trim().isEmpty ? '' : ' ${trailer.lengthUnit.trim()}';
    final wu = trailer.widthUnit.trim().isEmpty ? '' : ' ${trailer.widthUnit.trim()}';
    return '${trailer.length}$lu × ${trailer.width}$wu';
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final created = _formatDateTime(context, trailer.createdAt);
    final updated = _formatDateTime(context, trailer.updatedAt);
    final win = trailer.winNumber.trim().isEmpty ? '—' : trailer.winNumber.trim();
    final email = (trailer.email ?? '').trim().isEmpty ? '—' : (trailer.email ?? '').trim();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 14, 12),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.colors.primary.withValues(alpha: 0.20), theme.colors.primary.withValues(alpha: 0.06)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colors.border),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.local_shipping_outlined, size: 22, color: theme.colors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title(),
                      style: theme.typography.lg.copyWith(fontWeight: FontWeight.w900, color: theme.colors.foreground),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Trailer #${trailer.id} · Business ${trailer.businessId}',
                      style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground, fontWeight: FontWeight.w800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(FIcons.x),
                iconSize: 16,
                style: IconButton.styleFrom(
                  minimumSize: const Size(38, 38),
                  padding: EdgeInsets.zero,
                  foregroundColor: theme.colors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
            child: Column(
              children: [
                _AirbnbCard(
                  title: 'Trailer photo',
                  icon: Icons.image_outlined,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: () {
                        final raw = (resolvedImageUrl ?? '').trim().isNotEmpty
                            ? resolvedImageUrl!.trim()
                            : trailer.image.trim();
                        if (raw.isEmpty) {
                          return Container(
                            color: theme.colors.muted.withValues(alpha: 0.35),
                            alignment: Alignment.center,
                            child: Text('No image', style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground, fontWeight: FontWeight.w800)),
                          );
                        }
                        final url = TrailerService.resolveTrailerImageUrl(raw);
                        return Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: theme.colors.muted.withValues(alpha: 0.35),
                              alignment: Alignment.center,
                              child: Text('Could not load image', style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground)),
                            );
                          },
                        );
                      }(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _AirbnbCard(
                  title: 'Details',
                  icon: Icons.receipt_long_outlined,
                  child: Column(
                    children: [
                      _FactRow(icon: Icons.tag, label: 'Trailer ID', value: '#${trailer.id}'),
                      const SizedBox(height: 10),
                      _FactRow(icon: Icons.confirmation_number_outlined, label: 'Business ID', value: trailer.businessId.toString()),
                      const SizedBox(height: 10),
                      _FactRow(icon: Icons.badge_outlined, label: 'Display name', value: trailer.displayName.trim().isEmpty ? '—' : trailer.displayName.trim()),
                      const SizedBox(height: 10),
                      _FactRow(icon: Icons.drive_file_rename_outline, label: 'Trailer name', value: (trailer.trailerName ?? '').trim().isEmpty ? '—' : (trailer.trailerName ?? '').trim()),
                      const SizedBox(height: 10),
                      _FactRow(icon: Icons.numbers, label: 'WIN number', value: win),
                      const SizedBox(height: 10),
                      _FactRow(icon: Icons.straighten_outlined, label: 'Size', value: _sizeText()),
                      const SizedBox(height: 10),
                      _FactRow(icon: Icons.scale_outlined, label: 'Load capacity', value: trailer.loadCapacity > 0 ? trailer.loadCapacity.toString() : '—'),
                      const SizedBox(height: 10),
                      _FactRow(icon: FIcons.mail, label: 'Email', value: email),
                      const SizedBox(height: 10),
                      _FactRow(icon: Icons.schedule_outlined, label: 'Created', value: created),
                      const SizedBox(height: 10),
                      _FactRow(icon: Icons.update_outlined, label: 'Updated', value: updated),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DialogSurface extends StatelessWidget {
  const _DialogSurface({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      decoration: BoxDecoration(
        color: theme.colors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colors.border),
        boxShadow: [
          BoxShadow(
            color: theme.colors.foreground.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colors.muted.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colors.mutedForeground),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: theme.typography.xs.copyWith(fontWeight: FontWeight.w800, color: theme.colors.foreground),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessSummaryTab extends StatelessWidget {
  const _BusinessSummaryTab({required this.user, required this.name, required this.email, required this.phone, required this.cityState, required this.website});
  final UserData user;
  final String name;
  final String email;
  final String phone;
  final String cityState;
  final String website;

  static String _formatDateTime(BuildContext context, DateTime dt) {
    if (dt.millisecondsSinceEpoch == 0) return '—';
    final local = dt.toLocal();
    final ml = MaterialLocalizations.of(context);
    final date = ml.formatFullDate(local);
    final time = ml.formatTimeOfDay(TimeOfDay.fromDateTime(local), alwaysUse24HourFormat: false);
    return '$date · $time';
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final createdAt = _formatDateTime(context, user.createdAt);
    final updatedAt = _formatDateTime(context, user.updatedAt);
    final websiteValue = website.trim().isEmpty ? '—' : website.trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 860;
              final left = Expanded(
                child: _AirbnbCard(
                  title: 'Quick facts',
                  icon: Icons.receipt_long_outlined,
                  child: Column(
                    children: [
                      _FactRow(icon: Icons.badge_outlined, label: 'Business ID', value: user.customerNumber.trim().isEmpty ? '—' : user.customerNumber.trim()),
                      const SizedBox(height: 10),
                      _FactRow(icon: FIcons.mail, label: 'E-mail', value: email),
                      const SizedBox(height: 10),
                      _FactRow(icon: FIcons.phone, label: 'Phone', value: phone),
                      const SizedBox(height: 10),
                      _FactRow(icon: Icons.map_outlined, label: 'City, State', value: cityState),
                      const SizedBox(height: 10),
                      _FactRow(icon: Icons.language_outlined, label: 'Website', value: websiteValue),
                    ],
                  ),
                ),
              );

              final right = Expanded(
                child: Column(
                  children: [
                    _AirbnbCard(
                      title: 'Status',
                      icon: Icons.verified_outlined,
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _StatusChip(
                            label: '${user.subscriptionTier[0].toUpperCase()}${user.subscriptionTier.substring(1)} tier',
                            icon: Icons.workspace_premium_outlined,
                            tone: user.subscriptionTier == 'pro' ? _ChipTone.good : (user.subscriptionTier == 'lite' ? _ChipTone.good : _ChipTone.neutral),
                          ),
                          _StatusChip(
                            label: user.isActive ? 'Active' : 'Inactive',
                            icon: Icons.toggle_on_outlined,
                            tone: user.isActive ? _ChipTone.good : _ChipTone.bad,
                          ),
                          _StatusChip(
                            label: user.hasHustleProPlan ? 'Is Featured' : 'Not featured',
                            icon: Icons.auto_awesome_outlined,
                            tone: user.hasHustleProPlan ? _ChipTone.good : _ChipTone.neutral,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _AirbnbCard(
                      title: 'Business photo',
                      icon: Icons.image_outlined,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: AspectRatio(
                          aspectRatio: 16 / 8,
                          child: Image.network(
                            user.avatar,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: theme.colors.muted.withValues(alpha: 0.35),
                                alignment: Alignment.center,
                                child: Text('Could not load image', style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground)),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );

              if (isNarrow) {
                return Column(children: [left, const SizedBox(height: 12), right]);
              }
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [left, const SizedBox(width: 12), right]);
            },
          ),
          const SizedBox(height: 12),
          _AirbnbCard(
            title: 'All details',
            icon: Icons.account_box_outlined,
            child: _DetailsGrid(
              items: [
                _DetailItem(label: 'User ID', value: user.id.trim().isEmpty ? '—' : user.id.trim(), icon: Icons.fingerprint_outlined),
                _DetailItem(label: 'Business ID', value: user.customerNumber.trim().isEmpty ? '—' : user.customerNumber.trim(), icon: Icons.confirmation_number_outlined),
                _DetailItem(label: 'Business name', value: name, icon: Icons.badge_outlined),
                _DetailItem(label: 'E-mail', value: email, icon: FIcons.mail),
                _DetailItem(label: 'Phone', value: phone, icon: FIcons.phone),
                _DetailItem(label: 'City, State', value: cityState, icon: Icons.map_outlined),
                _DetailItem(label: 'Website', value: websiteValue, icon: Icons.language_outlined),
                _DetailItem(label: 'Tier', value: '${user.subscriptionTier[0].toUpperCase()}${user.subscriptionTier.substring(1)}', icon: Icons.workspace_premium_outlined),
                _DetailItem(label: 'Active', value: user.isActive ? 'Yes' : 'No', icon: Icons.toggle_on_outlined),
                _DetailItem(label: 'Featured', value: user.hasHustleProPlan ? 'Yes' : 'No', icon: Icons.auto_awesome_outlined),
                _DetailItem(label: 'Created', value: createdAt, icon: Icons.schedule_outlined),
                _DetailItem(label: 'Updated', value: updatedAt, icon: Icons.update_outlined),
                _DetailItem(label: 'Avatar URL', value: user.avatar.trim().isEmpty ? '—' : user.avatar.trim(), icon: Icons.link_outlined),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailItem {
  const _DetailItem({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;
}

class _DetailsGrid extends StatelessWidget {
  const _DetailsGrid({required this.items});
  final List<_DetailItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTwoCol = constraints.maxWidth >= 820;
        if (!isTwoCol) {
          return Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                _FactRow(icon: items[i].icon, label: items[i].label, value: items[i].value),
                if (i != items.length - 1) const SizedBox(height: 10),
              ],
            ],
          );
        }

        final left = <_DetailItem>[];
        final right = <_DetailItem>[];
        for (var i = 0; i < items.length; i++) {
          (i.isEven ? left : right).add(items[i]);
        }

        Widget col(List<_DetailItem> colItems) {
          return Expanded(
            child: Column(
              children: [
                for (var i = 0; i < colItems.length; i++) ...[
                  _FactRow(icon: colItems[i].icon, label: colItems[i].label, value: colItems[i].value),
                  if (i != colItems.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
          );
        }

        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [col(left), const SizedBox(width: 12), col(right)]);
      },
    );
  }
}

class _EmptyCollectionTab extends StatelessWidget {
  const _EmptyCollectionTab({required this.title, required this.description, required this.icon});
  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
      child: Column(
        children: [
          _AirbnbCard(
            title: title,
            icon: icon,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(description, style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground, height: 1.45)),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colors.muted.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: theme.colors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.colors.border),
                        ),
                        alignment: Alignment.center,
                        child: Icon(Icons.auto_awesome_outlined, size: 18, color: theme.colors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Next step: connect a Supabase table for $title and we can render real items here.',
                          style: theme.typography.sm.copyWith(color: theme.colors.foreground, height: 1.35, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AirbnbCard extends StatelessWidget {
  const _AirbnbCard({required this.title, required this.icon, required this.child});
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colors.border),
        boxShadow: [
          BoxShadow(
            color: theme.colors.foreground.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colors.primary.withValues(alpha: 0.20),
                      theme.colors.primary.withValues(alpha: 0.06),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colors.border),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: theme.colors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.typography.sm.copyWith(fontWeight: FontWeight.w900, color: theme.colors.foreground),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colors.muted.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: theme.colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colors.border),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: theme.colors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.typography.xs.copyWith(fontWeight: FontWeight.w800, color: theme.colors.mutedForeground)),
                const SizedBox(height: 4),
                Text(value, style: theme.typography.sm.copyWith(fontWeight: FontWeight.w800, color: theme.colors.foreground, height: 1.25)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _ChipTone { good, neutral, bad }

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.icon, required this.tone});
  final String label;
  final IconData icon;
  final _ChipTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final Color tint;
    final Color fg;
    switch (tone) {
      case _ChipTone.good:
        tint = theme.colors.secondary.withValues(alpha: 0.14);
        fg = theme.colors.secondary;
        break;
      case _ChipTone.bad:
        tint = theme.colors.destructive.withValues(alpha: 0.14);
        fg = theme.colors.destructive;
        break;
      case _ChipTone.neutral:
        tint = theme.colors.muted.withValues(alpha: 0.30);
        fg = theme.colors.mutedForeground;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 8),
          Text(label, style: theme.typography.sm.copyWith(fontWeight: FontWeight.w900, color: theme.colors.foreground)),
        ],
      ),
    );
  }
}
