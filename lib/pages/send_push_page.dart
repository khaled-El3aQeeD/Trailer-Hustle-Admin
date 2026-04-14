import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';
import 'package:trailerhustle_admin/core/constants.dart';
import 'package:trailerhustle_admin/models/landing_screen.dart';
import 'package:trailerhustle_admin/services/push_notification_service.dart';
import 'package:trailerhustle_admin/widgets/campaign_history_table.dart';
import 'package:trailerhustle_admin/widgets/dashboard_header.dart';
import 'package:trailerhustle_admin/widgets/notification_preview_card.dart';
import 'package:trailerhustle_admin/widgets/recipient_selector.dart';
import 'package:trailerhustle_admin/widgets/sidebar.dart';
import 'package:trailerhustle_admin/widgets/adaptive_sidebar.dart';
import 'package:trailerhustle_admin/services/sidebar_controller.dart';

class SendPushPage extends StatefulWidget {
  const SendPushPage({super.key});

  @override
  State<SendPushPage> createState() => _SendPushPageState();
}

class _SendPushPageState extends State<SendPushPage> {
  // Form
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  // Recipients
  List<PushRecipient> _recipients = [];
  Map<int, String> _categories = {};
  Set<int> _selectedIds = {};
  bool _loadingRecipients = true;
  String? _recipientsError;

  // Campaigns history
  List<PushCampaign> _campaigns = [];
  bool _loadingCampaigns = true;

  // Sending state
  bool _sending = false;

  // Landing screen
  LandingScreen _selectedLanding = LandingScreen.defaultScreen;
  bool _manuallyOverridden = false;
  String? _autoDetectSource;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onComposeChanged);
    _bodyController.addListener(_onComposeChanged);

    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _onComposeChanged() {
    if (!_manuallyOverridden) {
      _runAutoDetect();
    }
    setState(() {});
  }

  void _runAutoDetect() {
    final title = _titleController.text;
    final body = _bodyController.text;
    final detected = LandingScreen.detectFromContent(title, body);

    // Figure out which field triggered the match for the hint text
    if (detected != LandingScreen.defaultScreen) {
      final titleLower = title.toLowerCase();
      String? matchedKeyword;
      bool inTitle = false;
      for (final kw in detected.keywords) {
        if (titleLower.contains(kw)) {
          matchedKeyword = kw.toUpperCase();
          inTitle = true;
          break;
        }
      }
      if (matchedKeyword == null) {
        final bodyLower = body.toLowerCase();
        for (final kw in detected.keywords) {
          if (bodyLower.contains(kw)) {
            matchedKeyword = kw.toUpperCase();
            break;
          }
        }
      }
      _autoDetectSource = matchedKeyword != null
          ? 'Auto-detected from "$matchedKeyword" in ${inTitle ? 'title' : 'body'}'
          : null;
    } else {
      _autoDetectSource = null;
    }

    _selectedLanding = detected;
  }

  Future<void> _loadData() async {
    setState(() {
      _loadingRecipients = true;
      _loadingCampaigns = true;
      _recipientsError = null;
    });

    try {
      final results = await Future.wait([
        PushNotificationService.fetchEligibleRecipients(),
        PushNotificationService.fetchCategories(),
        PushNotificationService.fetchCampaigns(),
      ]);

      if (!mounted) return;
      setState(() {
        _recipients = results[0] as List<PushRecipient>;
        _categories = results[1] as Map<int, String>;
        _campaigns = results[2] as List<PushCampaign>;
        _loadingRecipients = false;
        _loadingCampaigns = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _recipientsError = e.toString();
        _loadingRecipients = false;
        _loadingCampaigns = false;
      });
    }
  }

  bool get _canSend =>
      _titleController.text.trim().isNotEmpty &&
      _bodyController.text.trim().isNotEmpty &&
      _selectedIds.isNotEmpty &&
      !_sending;

  String get _filterSummary {
    if (_selectedIds.length == _recipients.length && _recipients.isNotEmpty) {
      return 'All Users (${_selectedIds.length})';
    }
    return '${_selectedIds.length} specific users';
  }

  Future<void> _confirmAndSend() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    final count = _selectedIds.length;
    final sendAll = count == _recipients.length && _recipients.isNotEmpty;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final colors = Theme.of(ctx).colorScheme;
        final textTheme = Theme.of(ctx).textTheme;
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: colors.error, size: 24),
              const SizedBox(width: 8),
              const Text('Confirm Push Notification'),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ConfirmRow(label: 'Title', value: title),
                const SizedBox(height: 8),
                _ConfirmRow(
                    label: 'Body',
                    value: body.length > 100
                        ? '${body.substring(0, 100)}...'
                        : body),
                const SizedBox(height: 8),
                _ConfirmRow(
                    label: 'Recipients', value: '$count users'),
                const SizedBox(height: 8),
                _ConfirmRow(label: 'Filters', value: _filterSummary),
                const SizedBox(height: 8),
                _ConfirmRow(
                    label: 'Landing',
                    value: '${_selectedLanding.label} — ${_selectedLanding.hint}'),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.errorContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'This will immediately send a push notification to $count device${count == 1 ? '' : 's'}. This action cannot be undone.',
                    style: textTheme.bodySmall
                        ?.copyWith(color: colors.error),
                  ),
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
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
              ),
              child: Text('Send to $count'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _sending = true);

    final result = await PushNotificationService.sendPush(
      title: title,
      body: body,
      userIds: _selectedIds.toList(),
      sendToAll: sendAll,
      filterSummary: _filterSummary,
      notificationType: _selectedLanding.notificationType,
    );

    if (!mounted) return;

    setState(() => _sending = false);

    if (result.success) {
      _titleController.clear();
      _bodyController.clear();
      setState(() {
        _selectedIds = {};
        _selectedLanding = LandingScreen.defaultScreen;
        _manuallyOverridden = false;
        _autoDetectSource = null;
      });

      // Refresh campaigns
      PushNotificationService.fetchCampaigns().then((c) {
        if (mounted) setState(() => _campaigns = c);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Push notification sent to ${result.totalSent} users',
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${result.error ?? 'Unknown error'}'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _toggleSidebar() {
    context.read<SidebarController>().toggle();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile =
        context.theme.breakpoints.md > MediaQuery.of(context).size.width;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    context.read<SidebarController>().autoCollapseIfNeeded(screenWidth);

    return Scaffold(
      backgroundColor: context.theme.colors.primaryForeground,
      drawer: isMobile
          ? Container(
              color: context.theme.colors.background,
              child: const Sidebar(),
            )
          : null,
      body: Row(
        children: [
          if (!isMobile) const AdaptiveSidebar(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: context.theme.colors.background,
                          borderRadius: BorderRadius.circular(
                              DashboardConstants.containerBorderRadius),
                          boxShadow: [
                            BoxShadow(
                              color: context.theme.colors.primary
                                  .withValues(alpha: 0.13),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DashboardHeader(
                              pageTitle: 'Send Push Notification',
                              onSidebarToggle:
                                  isMobile ? null : _toggleSidebar,
                            ),
                            Padding(
                              padding: const EdgeInsets.all(
                                  DashboardConstants.contentPadding),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ── Compose Section ──
                                  _buildComposeSection(
                                      colors, textTheme, isMobile),
                                  const SizedBox(height: 24),

                                  // ── Recipients Section ──
                                  _buildSectionHeader(
                                    'Select Recipients',
                                    Icons.group_outlined,
                                    colors,
                                    textTheme,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildRecipientsSection(colors, textTheme),
                                  const SizedBox(height: 16),

                                  // ── Send Bar ──
                                  _buildSendBar(colors, textTheme),
                                  const SizedBox(height: 32),

                                  // ── Campaign History ──
                                  _buildSectionHeader(
                                    'Recent Campaigns',
                                    Icons.history,
                                    colors,
                                    textTheme,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildHistorySection(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposeSection(
      ColorScheme colors, TextTheme textTheme, bool isMobile) {
    final composeForm = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Compose',
          Icons.edit_outlined,
          colors,
          textTheme,
        ),
        const SizedBox(height: 12),
        // Title field
        TextField(
          controller: _titleController,
          maxLength: 255,
          decoration: InputDecoration(
            labelText: 'Title',
            hintText: 'e.g. Holiday Sale!',
            counterText: '${_titleController.text.length}/255',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Body field
        TextField(
          controller: _bodyController,
          maxLines: 4,
          maxLength: 1000,
          decoration: InputDecoration(
            labelText: 'Body',
            hintText: 'Write the notification message...',
            counterText: '${_bodyController.text.length}/1000',
            alignLabelWithHint: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Landing screen dropdown
        _buildLandingScreenDropdown(),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          composeForm,
          const SizedBox(height: 16),
          NotificationPreviewCard(
            title: _titleController.text,
            body: _bodyController.text,
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: composeForm),
        const SizedBox(width: 24),
        NotificationPreviewCard(
          title: _titleController.text,
          body: _bodyController.text,
        ),
      ],
    );
  }

  Widget _buildLandingScreenDropdown() {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.ads_click, size: 18, color: colors.primary),
            const SizedBox(width: 6),
            Text(
              'Landing Screen',
              style: textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedLanding.notificationType,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
          items: LandingScreen.all.map((screen) {
            return DropdownMenuItem<String>(
              value: screen.notificationType,
              child: Row(
                children: [
                  Icon(screen.icon, size: 18,
                      color: colors.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(screen.label),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;
            final screen = LandingScreen.fromType(value);
            if (screen == null) return;
            setState(() {
              _selectedLanding = screen;
              _manuallyOverridden = true;
              _autoDetectSource = null;
            });
          },
        ),
        const SizedBox(height: 6),
        // Hint text
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _autoDetectSource != null
                  ? Icons.auto_awesome
                  : Icons.info_outline,
              size: 14,
              color: _autoDetectSource != null
                  ? colors.primary
                  : colors.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                _autoDetectSource != null
                    ? '$_autoDetectSource. ${_selectedLanding.hint}.'
                    : _manuallyOverridden
                        ? _selectedLanding.hint
                        : 'No keyword detected — defaulting to Notifications. ${_selectedLanding.hint}.',
                style: textTheme.bodySmall?.copyWith(
                  color: _autoDetectSource != null
                      ? colors.primary
                      : colors.onSurfaceVariant,
                  fontStyle: _autoDetectSource != null
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
              ),
            ),
            if (_manuallyOverridden)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _manuallyOverridden = false;
                    _runAutoDetect();
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    'Reset',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecipientsSection(ColorScheme colors, TextTheme textTheme) {
    if (_loadingRecipients) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_recipientsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.error_outline, color: colors.error, size: 32),
              const SizedBox(height: 8),
              Text('Failed to load recipients',
                  style: textTheme.bodyMedium?.copyWith(color: colors.error)),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_recipients.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text(
            'No users with push tokens found',
            style:
                textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
        ),
      );
    }

    return RecipientSelector(
      recipients: _recipients,
      categories: _categories,
      selectedIds: _selectedIds,
      onSelectionChanged: (ids) => setState(() => _selectedIds = ids),
    );
  }

  Widget _buildSendBar(ColorScheme colors, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline,
              size: 18, color: colors.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _selectedIds.isEmpty
                  ? 'Select recipients to send a push notification'
                  : 'Ready to send to ${_selectedIds.length} user${_selectedIds.length == 1 ? '' : 's'} — $_filterSummary',
              style: textTheme.bodySmall
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 16),
          if (_sending)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          else
            FilledButton.icon(
              onPressed: _canSend ? _confirmAndSend : null,
              icon: const Icon(Icons.campaign, size: 18),
              label: Text(
                _selectedIds.isEmpty
                    ? 'Send Now'
                    : 'Send to ${_selectedIds.length}',
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    if (_loadingCampaigns) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: CircularProgressIndicator(),
        ),
      );
    }
    return CampaignHistoryTable(campaigns: _campaigns);
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    ColorScheme colors,
    TextTheme textTheme,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: colors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  final String label;
  final String value;
  const _ConfirmRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(value, style: textTheme.bodySmall),
        ),
      ],
    );
  }
}
