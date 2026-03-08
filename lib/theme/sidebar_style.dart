import 'package:flutter/material.dart';

import 'package:forui/forui.dart';
import '../core/constants.dart';

FSidebarStyle sidebarStyle({
  required FColors colors,
  required FTypography typography,
  required FStyle style,
}) => FSidebarStyle(
  decoration: BoxDecoration(),
  groupStyle: _sidebarGroupStyle(
    colors: colors,
    typography: typography,
    style: style,
  ),
  constraints: const BoxConstraints.tightFor(
    width: DashboardConstants.sidebarWidth,
  ),
  headerPadding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
  contentPadding: const EdgeInsets.symmetric(vertical: 12),
  footerPadding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
);

FSidebarGroupStyle _sidebarGroupStyle({
  required FColors colors,
  required FTypography typography,
  required FStyle style,
}) => FSidebarGroupStyle(
  labelStyle: typography.sm.copyWith(
    color: colors.mutedForeground,
    overflow: TextOverflow.ellipsis,
    fontWeight: FontWeight.w500,
  ),
  actionStyle: FWidgetStateMap({
    WidgetState.hovered | WidgetState.pressed: IconThemeData(
      color: colors.primary,
      size: 18,
    ),
    WidgetState.any: IconThemeData(color: colors.mutedForeground, size: 18),
  }),
  tappableStyle: style.tappableStyle,
  focusedOutlineStyle: style.focusedOutlineStyle,
  itemStyle: _sidebarItemStyle(
    colors: colors,
    typography: typography,
    style: style,
  ),
  padding: const EdgeInsets.symmetric(horizontal: 12),
  headerSpacing: 8,
  headerPadding: const EdgeInsets.fromLTRB(12, 0, 8, 10),
  childrenSpacing: 2,
  childrenPadding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
);

FSidebarItemStyle _sidebarItemStyle({
  required FColors colors,
  required FTypography typography,
  required FStyle style,
}) => FSidebarItemStyle(
  textStyle: FWidgetStateMap({
    WidgetState.disabled: typography.sm.copyWith(
      color: colors.mutedForeground,
      height: 1,
      overflow: TextOverflow.ellipsis,
    ),
    WidgetState.any: typography.sm.copyWith(
      color: colors.foreground,
      height: 1,
      overflow: TextOverflow.ellipsis,
    ),
  }),
  iconStyle: FWidgetStateMap({
    WidgetState.disabled: IconThemeData(
      color: colors.mutedForeground,
      size: 14,
    ),
    WidgetState.any: IconThemeData(color: colors.foreground, size: 14),
  }),
  collapsibleIconStyle: FWidgetStateMap({
    WidgetState.disabled: IconThemeData(
      color: colors.mutedForeground,
      size: 14,
    ),
    WidgetState.any: IconThemeData(color: colors.foreground, size: 14),
  }),
  backgroundColor: FWidgetStateMap({
    WidgetState.disabled: Colors.transparent,
    WidgetState.selected | WidgetState.hovered | WidgetState.pressed: colors
        .hover(colors.secondary),
    WidgetState.any: Colors.transparent,
  }),
  borderRadius: style.borderRadius,
  tappableStyle: style.tappableStyle.copyWith(
    bounceTween: FTappableStyle.noBounceTween,
  ),
  focusedOutlineStyle: style.focusedOutlineStyle.copyWith(spacing: 0),
  iconSpacing: 8,
  collapsibleIconSpacing: 8,
  expandDuration: const Duration(milliseconds: 200),
  expandCurve: Curves.easeOutCubic,
  collapseDuration: const Duration(milliseconds: 150),
  collapseCurve: Curves.easeInCubic,
  childrenSpacing: 2,
  childrenPadding: const EdgeInsets.only(left: 26, top: 2),
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
);
