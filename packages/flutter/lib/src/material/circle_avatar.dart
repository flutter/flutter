// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'chip.dart';
/// @docImport 'color_scheme.dart';
/// @docImport 'list_tile.dart';
library;

import 'package:flutter/widgets.dart';

import 'theme.dart';

/// A circular avatar typically used to represent a user.
///
/// Usually displays a user's profile image, or, in the absence of an image,
/// the user's initials.
///
/// If [foregroundImage] fails then [backgroundImage] is used. If
/// [backgroundImage] fails too, [backgroundColor] is used.
///
/// The image is always clipped to a circular shape.
///
/// {@tool snippet}
///
/// If the avatar is to have an image:
///
/// ```dart
/// CircleAvatar(
///   backgroundImage: NetworkImage(userAvatarUrl),
/// )
/// ```
/// {@end-tool}
///
/// {@tool snippet}
///
/// If the avatar is to show the user's initials:
///
/// ```dart
/// CircleAvatar(
///   backgroundColor: Colors.brown.shade800,
///   child: const Text('AH'),
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [RawAvatar], the low-level widget that renders the avatar.
///  * [Chip], for representing users or concepts in long form.
///  * [ListTile], which can combine an icon (such as a [CircleAvatar]) with
///    some text for a fixed height list entry.
///  * <https://material.io/design/components/chips.html#input-chips>
class CircleAvatar extends StatelessWidget {
  /// Creates a circular avatar.
  const CircleAvatar({
    super.key,
    this.child,
    this.backgroundColor,
    this.backgroundImage,
    this.foregroundImage,
    this.onBackgroundImageError,
    this.onForegroundImageError,
    this.foregroundColor,
    this.radius,
    this.minRadius,
    this.maxRadius,
  }) : assert(radius == null || (minRadius == null && maxRadius == null));

  /// {@macro flutter.widgets.RawAvatar.child}
  final Widget? child;

  /// The color with which to fill the circle. Changing the background
  /// color will cause the avatar to animate to the new color.
  ///
  /// If a [backgroundColor] is not specified and [ThemeData.useMaterial3] is true,
  /// [ColorScheme.primaryContainer] will be used, otherwise the theme's
  /// [ThemeData.primaryColorLight] is used with dark foreground colors, and
  /// [ThemeData.primaryColorDark] with light foreground colors.
  final Color? backgroundColor;

  /// The default text color for text in the circle.
  ///
  /// Defaults to the primary text theme color if no [backgroundColor] is
  /// specified.
  ///
  /// If a [foregroundColor] is not specified and [ThemeData.useMaterial3] is true,
  /// [ColorScheme.onPrimaryContainer] will be used, otherwise the theme's
  /// [ThemeData.primaryColorLight] for dark background colors, and
  /// [ThemeData.primaryColorDark] for light background colors.
  final Color? foregroundColor;

  /// {@macro flutter.widgets.RawAvatar.backgroundImage}
  final ImageProvider? backgroundImage;

  /// {@macro flutter.widgets.RawAvatar.foregroundImage}
  final ImageProvider? foregroundImage;

  /// {@macro flutter.widgets.RawAvatar.onBackgroundImageError}
  final ImageErrorListener? onBackgroundImageError;

  /// {@macro flutter.widgets.RawAvatar.onForegroundImageError}
  final ImageErrorListener? onForegroundImageError;

  /// The size of the avatar, expressed as the radius (half the diameter).
  ///
  /// If [radius] is specified, then neither [minRadius] nor [maxRadius] may be
  /// specified. Specifying [radius] is equivalent to specifying a [minRadius]
  /// and [maxRadius], both with the value of [radius].
  ///
  /// If neither [minRadius] nor [maxRadius] are specified, defaults to 20
  /// logical pixels. This is the appropriate size for use with
  /// [ListTile.leading].
  ///
  /// Changes to the [radius] are animated (including changing from an explicit
  /// [radius] to a [minRadius]/[maxRadius] pair or vice versa).
  final double? radius;

  /// The minimum size of the avatar, expressed as the radius (half the
  /// diameter).
  ///
  /// If [minRadius] is specified, then [radius] must not also be specified.
  ///
  /// Defaults to zero.
  ///
  /// Constraint changes are animated, but size changes due to the environment
  /// itself changing are not. For example, changing the [minRadius] from 10 to
  /// 20 when the [CircleAvatar] is in an unconstrained environment will cause
  /// the avatar to animate from a 20 pixel diameter to a 40 pixel diameter.
  /// However, if the [minRadius] is 40 and the [CircleAvatar] has a parent
  /// [SizedBox] whose size changes instantaneously from 20 pixels to 40 pixels,
  /// the size will snap to 40 pixels instantly.
  final double? minRadius;

  /// The maximum size of the avatar, expressed as the radius (half the
  /// diameter).
  ///
  /// If [maxRadius] is specified, then [radius] must not also be specified.
  ///
  /// Defaults to [double.infinity].
  ///
  /// Constraint changes are animated, but size changes due to the environment
  /// itself changing are not. For example, changing the [maxRadius] from 10 to
  /// 20 when the [CircleAvatar] is in an unconstrained environment will cause
  /// the avatar to animate from a 20 pixel diameter to a 40 pixel diameter.
  /// However, if the [maxRadius] is 40 and the [CircleAvatar] has a parent
  /// [SizedBox] whose size changes instantaneously from 20 pixels to 40 pixels,
  /// the size will snap to 40 pixels instantly.
  final double? maxRadius;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    final ThemeData theme = Theme.of(context);
    final Color? effectiveForegroundColor =
        foregroundColor ?? (theme.useMaterial3 ? theme.colorScheme.onPrimaryContainer : null);
    final TextStyle effectiveTextStyle = theme.useMaterial3
        ? theme.textTheme.titleMedium!
        : theme.primaryTextTheme.titleMedium!;
    TextStyle textStyle = effectiveTextStyle.copyWith(color: effectiveForegroundColor);
    Color? effectiveBackgroundColor =
        backgroundColor ?? (theme.useMaterial3 ? theme.colorScheme.primaryContainer : null);
    if (effectiveBackgroundColor == null) {
      effectiveBackgroundColor = switch (ThemeData.estimateBrightnessForColor(textStyle.color!)) {
        Brightness.dark => theme.primaryColorLight,
        Brightness.light => theme.primaryColorDark,
      };
    } else if (effectiveForegroundColor == null) {
      textStyle = switch (ThemeData.estimateBrightnessForColor(backgroundColor!)) {
        Brightness.dark => textStyle.copyWith(color: theme.primaryColorLight),
        Brightness.light => textStyle.copyWith(color: theme.primaryColorDark),
      };
    }

    final double? size = radius != null ? radius! * 2 : null;
    final double? minSize = minRadius != null ? minRadius! * 2 : null;
    final double? maxSize = maxRadius != null ? maxRadius! * 2 : null;

    return RawAvatar(
      backgroundColor: effectiveBackgroundColor,
      textStyle: textStyle,
      iconTheme: theme.iconTheme.copyWith(color: textStyle.color),
      size: size,
      minSize: minSize,
      maxSize: maxSize,
      backgroundImage: backgroundImage,
      foregroundImage: foregroundImage,
      onBackgroundImageError: onBackgroundImageError,
      onForegroundImageError: onForegroundImageError,
      boxShape: BoxShape.circle,
      child: child,
    );
  }
}
