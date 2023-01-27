// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'badge_theme.dart';
import 'color_scheme.dart';
import 'theme.dart';

/// A Material Design "badge".
///
/// A badge's [label] conveys a small amount of information about its
/// [child], like a count or status. If the label is null then this is
/// a "small" badge that's displayed as a [smallSize] diameter filled
/// circle. Otherwise this is a [StadiumBorder] shaped "large" badge
/// with height [largeSize].
///
/// Badges are typically used to decorate the icon within a
/// BottomNavigationBarItem] or a [NavigationRailDestination]
/// or a button's icon, as in [TextButton.icon]. The badge's default
/// configuration is intended to work well with a default sized (24)
/// [Icon].
class Badge extends StatelessWidget {
  /// Create a Badge that stacks [label] on top of [child].
  ///
  /// If [label] is null then just a filled circle is displayed. Otherwise
  /// the [label] is displayed within a [StadiumBorder] shaped area.
  const Badge({
    super.key,
    this.backgroundColor,
    this.textColor,
    this.smallSize,
    this.largeSize,
    this.textStyle,
    this.padding,
    this.alignment,
    this.label,
    this.isLabelVisible = true,
    this.child,
  });

  /// Convenience constructor for creating a badge with a numeric
  /// label with 1-3 digits based on [count].
  ///
  /// Initializes [label] with a [Text] widget that contains [count].
  /// If [count] is greater than 999, then the label is '999+'.
  Badge.count({
    super.key,
    this.backgroundColor,
    this.textColor,
    this.smallSize,
    this.largeSize,
    this.textStyle,
    this.padding,
    this.alignment,
    required int count,
    this.isLabelVisible = true,
    this.child,
  }) : label = Text(count > 999 ? '999+' : '$count');

  /// The badge's fill color.
  ///
  /// Defaults to the [BadgeTheme]'s background color, or
  /// [ColorScheme.errorColor] if the theme value is null.
  final Color? backgroundColor;

  /// The color of the badge's [label] text.
  ///
  /// This color overrides the color of the label's [textStyle].
  ///
  /// Defaults to the [BadgeTheme]'s foreground color, or
  /// [ColorScheme.onError] if the theme value is null.
  final Color? textColor;

  /// The diameter of the badge if [label] is null.
  ///
  /// Defaults to the [BadgeTheme]'s small size, or 6 if the theme value
  /// is null.
  final double? smallSize;

  /// The badge's height if [label] is non-null.
  ///
  /// Defaults to the [BadgeTheme]'s large size, or 16 if the theme value
  /// is null. If the default value is overridden then it may be useful to
  /// also override [padding] and [alignment].
  final double? largeSize;

  /// The [DefaultTextStyle] for the badge's label.
  ///
  /// The text style's color is overwritten by the [textColor].
  ///
  /// This value is only used if [label] is non-null.
  ///
  /// Defaults to the [BadgeTheme]'s text style, or the overall theme's
  /// [TextTheme.labelSmall] if the badge theme's value is null. If
  /// the default text style is overridden then it may be useful to
  /// also override [largeSize], [padding], and [alignment].
  final TextStyle? textStyle;

  /// The padding added to the badge's label.
  ///
  /// This value is only used if [label] is non-null.
  ///
  /// Defaults to the [BadgeTheme]'s padding, or 4 pixels on the
  /// left and right if the theme's value is null.
  final EdgeInsetsGeometry? padding;

  /// The location of the [label] relative to the [child].
  ///
  /// This value is only used if [label] is non-null.
  ///
  /// Defaults to the [BadgeTheme]'s alignment, or `start = 12`
  /// and `top = -4` if the theme's value is null.
  final AlignmentDirectional? alignment;

  /// The badge's content, typically a [Text] widget that contains 1 to 4
  /// characters.
  ///
  /// If the label is null then this is a "small" badge that's
  /// displayed as a [smallSize] diameter filled circle. Otherwise
  /// this is a [StadiumBorder] shaped "large" badge with height [largeSize].
  final Widget? label;

  /// If false, the badge's [label] is not included.
  ///
  /// This flag is true by default. It's intended to make it convenient
  /// to create a badge that's only shown under certain conditions.
  final bool isLabelVisible;

  /// The widget that the badge is stacked on top of.
  ///
  /// Typically this is an default sized [Icon] that's part of a
  /// [BottomNavigationBarItem] or a [NavigationRailDestination].
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    if (!isLabelVisible) {
      return child ?? const SizedBox();
    }

    final BadgeThemeData badgeTheme = BadgeTheme.of(context);
    final BadgeThemeData defaults = _BadgeDefaultsM3(context);
    final double effectiveSmallSize = smallSize ?? badgeTheme.smallSize ?? defaults.smallSize!;
    final double effectiveLargeSize = largeSize ?? badgeTheme.largeSize ?? defaults.largeSize!;

    final Widget badge = DefaultTextStyle(
      style: (textStyle ?? badgeTheme.textStyle ?? defaults.textStyle!).copyWith(
        color: textColor ?? badgeTheme.textColor ?? defaults.textColor!,
      ),
      child: IntrinsicWidth(
        child: Container(
          height: label == null ? effectiveSmallSize : effectiveLargeSize,
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(
            color: backgroundColor ?? badgeTheme.backgroundColor ?? defaults.backgroundColor!,
            shape: const StadiumBorder(),
          ),
          padding: label == null ? null : (padding ?? badgeTheme.padding ?? defaults.padding!),
          alignment: label == null ? null : Alignment.center,
          child: label ?? SizedBox(width: effectiveSmallSize, height: effectiveSmallSize),
        ),
      ),
    );

    if (child == null) {
      return badge;
    }

    final AlignmentDirectional effectiveAlignment = alignment ?? badgeTheme.alignment ?? defaults.alignment!;
    return
      Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          child!,
          Positioned.directional(
            textDirection: Directionality.of(context),
            start: label == null ? null : effectiveAlignment.start,
            end: label == null ? 0 : null,
            top: label == null ? 0 : effectiveAlignment.y,
            child: badge,
          ),
        ],
      );
  }
}

// BEGIN GENERATED TOKEN PROPERTIES - Badge

// Do not edit by hand. The code between the "BEGIN GENERATED" and
// "END GENERATED" comments are generated from data in the Material
// Design token database by the script:
//   dev/tools/gen_defaults/bin/gen_defaults.dart.

// Token database version: v0_143

class _BadgeDefaultsM3 extends BadgeThemeData {
  _BadgeDefaultsM3(this.context) : super(
    smallSize: 6.0,
    largeSize: 16.0,
    padding: const EdgeInsets.symmetric(horizontal: 4),
    alignment: const AlignmentDirectional(12, -4),
  );

  final BuildContext context;
  late final ThemeData _theme = Theme.of(context);
  late final ColorScheme _colors = _theme.colorScheme;

  @override
  Color? get backgroundColor => _colors.error;

  @override
  Color? get textColor => _colors.onError;

  @override
  TextStyle? get textStyle => Theme.of(context).textTheme.labelSmall;
}

// END GENERATED TOKEN PROPERTIES - Badge
