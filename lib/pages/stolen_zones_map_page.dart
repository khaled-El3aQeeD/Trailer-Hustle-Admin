import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:trailerhustle_admin/models/stolen_report_data.dart';
import 'package:trailerhustle_admin/services/stolen_report_service.dart';

/// Full-screen admin workflow: draw one or more alert circles on a map
/// centered at a stolen trailer's reported coordinates, then fan out the
/// push to any Business inside the union of those circles.
///
/// If the admin draws no circles and clicks "Skip", the edge function
/// falls back to its radius-based geofence around the stolen location.
///
/// Pop result: `true` if a push was fired (either zones or radius mode),
/// `false`/`null` if the admin cancelled.
class StolenZonesMapPage extends StatefulWidget {
  const StolenZonesMapPage({
    super.key,
    required this.report,
    this.justApproved = false,
  });

  final StolenReportData report;

  /// When true, the page was opened immediately after approval — the header
  /// banner mentions the approval; otherwise it's a manual resend.
  final bool justApproved;

  @override
  State<StolenZonesMapPage> createState() => _StolenZonesMapPageState();
}

class _DraftZone {
  _DraftZone({required this.id, required this.center, this.radiusMiles = 25});

  final String id;
  LatLng center;
  double radiusMiles;
}

class _StolenZonesMapPageState extends State<StolenZonesMapPage> {
  static const _defaultRadiusMiles = 25.0;
  static const _minRadiusMiles = 1.0;
  static const _maxRadiusMiles = 200.0;
  static const _fallbackCenter = LatLng(39.5, -98.35); // continental US
  static const _fallbackZoom = 3.0;
  static const _stolenOriginZoom = 7.0;

  final Map<String, _DraftZone> _zones = {};
  String? _selectedZoneId;
  int _zoneCounter = 0;
  bool _sending = false;
  GoogleMapController? _mapController;

  /// Radius (in miles) the edge function will fall back to when the admin
  /// fires a radius-mode send. Loaded from `app_config` on init so the UI
  /// can preview the value and warn loudly when it's huge (e.g. 800 mi).
  int _fallbackRadiusMiles = 800;
  bool _loadingFallbackRadius = true;

  /// Above this threshold the radius send is treated as "large" and the
  /// confirmation dialog switches to a warning style. 250 mi already
  /// covers a multi-state region — anything above warrants a second look.
  static const int _largeRadiusThresholdMiles = 250;

  @override
  void initState() {
    super.initState();
    _loadFallbackRadius();
  }

  Future<void> _loadFallbackRadius() async {
    final r = await StolenReportService.getDefaultAlertRadiusMiles();
    if (!mounted) return;
    setState(() {
      _fallbackRadiusMiles = r;
      _loadingFallbackRadius = false;
    });
  }

  bool get _hasOrigin =>
      widget.report.stolenLat != null && widget.report.stolenLng != null;

  LatLng get _origin =>
      _hasOrigin
          ? LatLng(widget.report.stolenLat!, widget.report.stolenLng!)
          : _fallbackCenter;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapTap(LatLng pos) {
    if (_sending) return;
    setState(() {
      _zoneCounter += 1;
      final id = 'z$_zoneCounter';
      _zones[id] =
          _DraftZone(id: id, center: pos, radiusMiles: _defaultRadiusMiles);
      _selectedZoneId = id;
    });
  }

  void _selectZone(String id) {
    setState(() => _selectedZoneId = id);
  }

  void _removeSelected() {
    final id = _selectedZoneId;
    if (id == null) return;
    setState(() {
      _zones.remove(id);
      _selectedZoneId = null;
    });
  }

  void _updateRadius(double miles) {
    final id = _selectedZoneId;
    if (id == null) return;
    final z = _zones[id];
    if (z == null) return;
    setState(() {
      z.radiusMiles = miles.clamp(_minRadiusMiles, _maxRadiusMiles);
    });
  }

  Set<Circle> _circles() {
    return _zones.values.map((z) {
      final isSelected = z.id == _selectedZoneId;
      return Circle(
        circleId: CircleId(z.id),
        center: z.center,
        radius: z.radiusMiles * 1609.344, // miles -> meters
        fillColor: Colors.red.withValues(alpha: isSelected ? 0.18 : 0.10),
        strokeColor: isSelected
            ? Colors.red
            : Colors.redAccent.withValues(alpha: 0.6),
        strokeWidth: isSelected ? 3 : 2,
        consumeTapEvents: true,
        onTap: () => _selectZone(z.id),
      );
    }).toSet();
  }

  Set<Marker> _markers() {
    final markers = <Marker>{};
    if (_hasOrigin) {
      markers.add(
        Marker(
          markerId: const MarkerId('stolen_origin'),
          position: _origin,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: widget.report.displayName,
            snippet: widget.report.stolenLocation,
          ),
        ),
      );
    }
    // One small marker per zone center so admins can tap-to-select on web
    // even if Circle.onTap is flaky on this Maps JS version.
    for (final z in _zones.values) {
      markers.add(
        Marker(
          markerId: MarkerId('zone_${z.id}'),
          position: z.center,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            z.id == _selectedZoneId
                ? BitmapDescriptor.hueAzure
                : BitmapDescriptor.hueCyan,
          ),
          alpha: 0.85,
          consumeTapEvents: true,
          onTap: () => _selectZone(z.id),
        ),
      );
    }
    return markers;
  }

  Future<void> _sendZones() async {
    if (_zones.isEmpty || _sending) return;
    setState(() => _sending = true);
    final zones = _zones.values
        .map((z) => (
              centerLat: z.center.latitude,
              centerLng: z.center.longitude,
              radiusMiles: z.radiusMiles,
            ))
        .toList();
    final result = await StolenReportService.notifyNearby(
      reportId: widget.report.id,
      zones: zones,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    _showResultAndPop(result, mode: 'zones');
  }

  Future<void> _sendRadius() async {
    if (_sending) return;
    final confirmed = await _confirmRadiusSend();
    if (!confirmed || !mounted) return;
    setState(() => _sending = true);
    final result =
        await StolenReportService.notifyNearby(reportId: widget.report.id);
    if (!mounted) return;
    setState(() => _sending = false);
    _showResultAndPop(result, mode: 'radius');
  }

  /// Confirmation dialog shown before firing a radius-mode push. When the
  /// configured radius is large (>= [_largeRadiusThresholdMiles]) the dialog
  /// switches to a warning style so admins don't accidentally blast users
  /// hundreds of miles away with a single click.
  Future<bool> _confirmRadiusSend() async {
    final radius = _fallbackRadiusMiles;
    final isLarge = radius >= _largeRadiusThresholdMiles;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: !_sending,
      builder: (ctx) {
        return AlertDialog(
          icon: Icon(
            isLarge ? Icons.warning_amber_rounded : Icons.help_outline,
            size: 40,
            color: isLarge ? Colors.orange : null,
          ),
          title: Text(
            isLarge ? 'Large alert radius' : 'Send radius alert?',
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This will notify every user with a registered location '
                  'within $radius miles of the stolen location.',
                ),
                const SizedBox(height: 12),
                if (isLarge)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      '$radius miles covers a very large area — recipients '
                      'hundreds of miles away may treat this as spam. '
                      'Consider going back and drawing tighter zones on the '
                      'map instead.',
                      style: const TextStyle(fontSize: 13),
                    ),
                  )
                else
                  const Text(
                    'You can also cancel and draw tighter zones on the map '
                    'for a more targeted alert.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: isLarge
                  ? FilledButton.styleFrom(backgroundColor: Colors.orange)
                  : null,
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                isLarge ? 'Send anyway ($radius mi)' : 'Send ($radius mi)',
              ),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  void _showResultAndPop(
    ({int totalTargets, int totalSent, int totalFailed})? result, {
    required String mode,
  }) {
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Push fan-out failed')),
      );
      return;
    }
    final prefix = mode == 'zones' ? 'Zones' : 'Radius';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$prefix: notified ${result.totalSent}/${result.totalTargets} users'
          '${result.totalFailed > 0 ? ' (${result.totalFailed} failed)' : ''}',
        ),
      ),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return Scaffold(
        appBar: AppBar(title: const Text('Draw alert zones')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'The zone map is only available in the web admin dashboard.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final isWide = MediaQuery.of(context).size.width >= 900;
    final map = GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _origin,
        zoom: _hasOrigin ? _stolenOriginZoom : _fallbackZoom,
      ),
      onMapCreated: (c) => _mapController = c,
      onTap: _onMapTap,
      circles: _circles(),
      markers: _markers(),
      myLocationButtonEnabled: false,
      zoomControlsEnabled: true,
      compassEnabled: false,
      tiltGesturesEnabled: false,
      rotateGesturesEnabled: false,
    );

    final panel = _SidePanel(
      report: widget.report,
      justApproved: widget.justApproved,
      hasOrigin: _hasOrigin,
      zones: _zones.values.toList(growable: false),
      origin: _hasOrigin ? _origin : null,
      selectedZoneId: _selectedZoneId,
      sending: _sending,
      minRadius: _minRadiusMiles,
      maxRadius: _maxRadiusMiles,
      fallbackRadiusMiles: _fallbackRadiusMiles,
      loadingFallbackRadius: _loadingFallbackRadius,
      largeRadiusThresholdMiles: _largeRadiusThresholdMiles,
      onSelectZone: _selectZone,
      onRadiusChanged: _updateRadius,
      onRemoveSelected: _removeSelected,
      onSendZones: _sendZones,
      onSendRadius: _sendRadius,
      onCancel: () => Navigator.of(context).pop(false),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Draw alert zones'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed:
              _sending ? null : () => Navigator.of(context).pop(false),
          tooltip: 'Back',
        ),
      ),
      body: isWide
          ? Row(
              children: [
                Expanded(child: map),
                SizedBox(width: 340, child: panel),
              ],
            )
          : Column(
              children: [
                Expanded(child: map),
                SizedBox(
                  height: 320,
                  child: panel,
                ),
              ],
            ),
    );
  }
}

class _SidePanel extends StatelessWidget {
  const _SidePanel({
    required this.report,
    required this.justApproved,
    required this.hasOrigin,
    required this.zones,
    required this.origin,
    required this.selectedZoneId,
    required this.sending,
    required this.minRadius,
    required this.maxRadius,
    required this.fallbackRadiusMiles,
    required this.loadingFallbackRadius,
    required this.largeRadiusThresholdMiles,
    required this.onSelectZone,
    required this.onRadiusChanged,
    required this.onRemoveSelected,
    required this.onSendZones,
    required this.onSendRadius,
    required this.onCancel,
  });

  final StolenReportData report;
  final bool justApproved;
  final bool hasOrigin;
  final List<_DraftZone> zones;
  final LatLng? origin;
  final String? selectedZoneId;
  final bool sending;
  final double minRadius;
  final double maxRadius;
  final int fallbackRadiusMiles;
  final bool loadingFallbackRadius;
  final int largeRadiusThresholdMiles;
  final void Function(String id) onSelectZone;
  final void Function(double miles) onRadiusChanged;
  final VoidCallback onRemoveSelected;
  final VoidCallback onSendZones;
  final VoidCallback onSendRadius;
  final VoidCallback onCancel;

  _DraftZone? get _selected {
    final id = selectedZoneId;
    if (id == null) return null;
    for (final z in zones) {
      if (z.id == id) return z;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final canSendZones = zones.isNotEmpty && !sending;
    final canSendRadius = hasOrigin && !sending;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  justApproved
                      ? 'Approved — draw alert zones'
                      : 'Resend alert',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  report.displayName,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if ((report.stolenLocation ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    report.stolenLocation!.trim(),
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (!hasOrigin) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'No coordinates on this report — radius fallback is disabled. Draw at least one zone manually.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                const Text(
                  'Tap the map to drop a circle. Tap an existing circle to adjust its radius or remove it.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: zones.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No zones drawn yet.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: zones.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final z = zones[i];
                      final isSelected = z.id == selectedZoneId;
                      return ListTile(
                        dense: true,
                        selected: isSelected,
                        leading: Icon(
                          Icons.circle_outlined,
                          color: isSelected
                              ? Colors.red
                              : Colors.redAccent.withValues(alpha: 0.7),
                        ),
                        title: Text('Zone ${i + 1}'),
                        subtitle: Text(
                          '${z.radiusMiles.toStringAsFixed(0)} mi · '
                          '${z.center.latitude.toStringAsFixed(3)}, '
                          '${z.center.longitude.toStringAsFixed(3)}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        onTap: () => onSelectZone(z.id),
                      );
                    },
                  ),
          ),
          if (selected != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Radius: ${selected.radiusMiles.toStringAsFixed(0)} mi',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Slider(
                    value: selected.radiusMiles.clamp(minRadius, maxRadius),
                    min: minRadius,
                    max: maxRadius,
                    divisions: (maxRadius - minRadius).round(),
                    label: '${selected.radiusMiles.toStringAsFixed(0)} mi',
                    onChanged: sending ? null : onRadiusChanged,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: sending ? null : onRemoveSelected,
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Remove zone'),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  onPressed: canSendZones ? onSendZones : null,
                  icon: sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    zones.isEmpty
                        ? 'Send to zones (draw first)'
                        : 'Send to ${zones.length} zone${zones.length == 1 ? '' : 's'}',
                  ),
                ),
                const SizedBox(height: 8),
                Tooltip(
                  message: hasOrigin
                      ? 'Notify all users within $fallbackRadiusMiles mi of the stolen location. You will be asked to confirm.'
                      : 'No coordinates on this report — radius fallback unavailable.',
                  child: OutlinedButton.icon(
                    onPressed: canSendRadius ? onSendRadius : null,
                    icon: Icon(
                      Icons.radar,
                      color: fallbackRadiusMiles >= largeRadiusThresholdMiles
                          ? Colors.orange
                          : null,
                    ),
                    label: Text(
                      loadingFallbackRadius
                          ? 'Skip — send by radius'
                          : 'Skip — send by radius ($fallbackRadiusMiles mi)',
                    ),
                  ),
                ),
                if (!loadingFallbackRadius &&
                    fallbackRadiusMiles >= largeRadiusThresholdMiles &&
                    hasOrigin) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 14,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Large radius — covers a multi-state area.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                TextButton(
                  onPressed: sending ? null : onCancel,
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
