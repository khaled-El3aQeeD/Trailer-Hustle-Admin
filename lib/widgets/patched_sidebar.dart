import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Patched version of FSidebar that fixes debugFillProperties assertion issues
/// This is a copy of Forui 0.14.1's FSidebar with diagnostic fixes
class PatchedFSidebar extends StatelessWidget {
  final FSidebarStyle? style;
  final Widget? header;
  final Widget? footer;
  final List<Widget> children;
  final ScrollController? controller;

  const PatchedFSidebar({
    super.key,
    this.style,
    this.header,
    this.footer,
    required this.children,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final effectiveStyle = style ?? theme.sidebarStyle;

    return ConstrainedBox(
      constraints: effectiveStyle.constraints,
      child: Container(
        decoration: effectiveStyle.decoration,
        child: Column(
          children: [
            if (header != null)
              Padding(
                padding: effectiveStyle.headerPadding,
                child: header!,
              ),
            Expanded(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  controller: controller,
                  padding: effectiveStyle.contentPadding,
                  child: Column(
                    children: children,
                  ),
                ),
              ),
            ),
            if (footer != null)
              Padding(
                padding: effectiveStyle.footerPadding,
                child: footer!,
              ),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    // Safe diagnostic properties - avoid null ifTrue/ifFalse
    properties.add(
      DiagnosticsProperty<FSidebarStyle?>('style', style, defaultValue: null),
    );
    properties.add(
      DiagnosticsProperty<Widget?>('header', header, defaultValue: null),
    );
    properties.add(
      DiagnosticsProperty<Widget?>('footer', footer, defaultValue: null),
    );
    properties.add(IntProperty('children count', children.length));
  }
}

/// Patched version of FSidebarGroup
class PatchedFSidebarGroup extends StatelessWidget {
  final Widget? label;
  final List<Widget> children;
  final FSidebarGroupStyle? style;

  const PatchedFSidebarGroup({
    super.key,
    this.label,
    required this.children,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final effectiveStyle = style ?? theme.sidebarStyle.groupStyle;

    return Padding(
      padding: effectiveStyle.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null)
            Padding(
              padding: effectiveStyle.headerPadding,
              child: DefaultTextStyle.merge(
                style: effectiveStyle.labelStyle,
                child: label!,
              ),
            ),
          SizedBox(height: effectiveStyle.headerSpacing),
          ...children.map(
            (child) => Padding(
              padding: EdgeInsets.only(bottom: effectiveStyle.childrenSpacing),
              child: child,
            ),
          ),
          Padding(padding: effectiveStyle.childrenPadding),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    // Safe diagnostic properties
    properties.add(
      DiagnosticsProperty<Widget?>('label', label, defaultValue: null),
    );
    properties.add(IntProperty('children count', children.length));
    properties.add(
      DiagnosticsProperty<FSidebarGroupStyle?>(
        'style',
        style,
        defaultValue: null,
      ),
    );
  }
}

/// Patched version of FSidebarItem
class PatchedFSidebarItem extends StatefulWidget {
  final Widget? icon;
  final Widget label;
  final bool selected;
  final VoidCallback? onPress;
  final List<Widget>? children;
  final bool initiallyExpanded;
  final FSidebarItemStyle? style;

  const PatchedFSidebarItem({
    super.key,
    this.icon,
    required this.label,
    this.selected = false,
    this.onPress,
    this.children,
    this.initiallyExpanded = false,
    this.style,
  });

  @override
  State<PatchedFSidebarItem> createState() => _PatchedFSidebarItemState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    // Safe diagnostic properties - ensure no null ifTrue/ifFalse
    properties.add(
      DiagnosticsProperty<Widget?>('icon', icon, defaultValue: null),
    );
    properties.add(DiagnosticsProperty<Widget>('label', label));
    properties.add(
      FlagProperty(
        'selected',
        value: selected,
        ifTrue: 'selected',
        defaultValue: false,
      ),
    );
    properties.add(
      ObjectFlagProperty<VoidCallback>(
        'onPress',
        onPress,
        ifPresent: 'has callback',
      ),
    );
    properties.add(
      FlagProperty(
        'initiallyExpanded',
        value: initiallyExpanded,
        ifTrue: 'initially expanded',
        defaultValue: false,
      ),
    );
    if (children != null) {
      properties.add(IntProperty('children count', children!.length));
    }
  }
}

class _PatchedFSidebarItemState extends State<PatchedFSidebarItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _isExpanded = widget.initiallyExpanded;
    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final effectiveStyle =
        widget.style ?? theme.sidebarStyle.groupStyle.itemStyle;
    final hasChildren = widget.children?.isNotEmpty ?? false;

    final currentState = <WidgetState>{
      if (widget.selected) WidgetState.selected,
      if (_isHovered) WidgetState.hovered,
    };

    return Column(
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: () {
              if (hasChildren) {
                _toggleExpansion();
              }
              widget.onPress?.call();
            },
            child: Container(
              width: double.infinity,
              padding: effectiveStyle.padding,
              decoration: BoxDecoration(
                color: effectiveStyle.backgroundColor.resolve(currentState),
                borderRadius: effectiveStyle.borderRadius,
              ),
              child: Row(
                children: [
                  if (widget.icon != null) ...[
                    IconTheme.merge(
                      data: effectiveStyle.iconStyle.resolve(currentState),
                      child: widget.icon!,
                    ),
                    SizedBox(width: effectiveStyle.iconSpacing),
                  ],
                  Expanded(
                    child: DefaultTextStyle.merge(
                      style: effectiveStyle.textStyle.resolve(currentState),
                      child: widget.label,
                    ),
                  ),
                  if (hasChildren) ...[
                    SizedBox(width: effectiveStyle.collapsibleIconSpacing),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.25 : 0.0,
                      duration: effectiveStyle.expandDuration,
                      child: IconTheme.merge(
                        data: effectiveStyle.collapsibleIconStyle.resolve(
                          currentState,
                        ),
                        child: const Icon(Icons.chevron_right),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (hasChildren)
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Padding(
              padding: effectiveStyle.childrenPadding,
              child: Column(
                children: widget.children!
                    .map(
                      (child) => Padding(
                        padding: EdgeInsets.only(
                          bottom: effectiveStyle.childrenSpacing,
                        ),
                        child: child,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
      ],
    );
  }
}

// Extension to access FSidebar components
extension FSidebarPatched on Never {
  static Widget sidebar({
    Key? key,
    FSidebarStyle? style,
    Widget? header,
    Widget? footer,
    required List<Widget> children,
    ScrollController? controller,
  }) => PatchedFSidebar(
    key: key,
    style: style,
    header: header,
    footer: footer,
    controller: controller,
    children: children,
  );

  static Widget group({
    Key? key,
    Widget? label,
    FSidebarGroupStyle? style,
    required List<Widget> children,
  }) => PatchedFSidebarGroup(
    key: key,
    label: label,
    style: style,
    children: children,
  );

  static Widget item({
    Key? key,
    Widget? icon,
    required Widget label,
    bool selected = false,
    VoidCallback? onPress,
    bool initiallyExpanded = false,
    FSidebarItemStyle? style,
    List<Widget>? children,
  }) => PatchedFSidebarItem(
    key: key,
    icon: icon,
    label: label,
    selected: selected,
    onPress: onPress,
    initiallyExpanded: initiallyExpanded,
    style: style,
    children: children,
  );
}
