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
///   backgroundColor: Colors.brown,
///   child: const Text('AH'),
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [RawAvatar], the low-level widget that renders the avatar.
///  * [Chip], for representing users or concepts inline.
///  * [ListTile], which can combine an icon (such as a [CircleAvatar])
///    with text in a fixed-height row.
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
  }) : assert(radius == null || (minRadius == null && maxRadius == null)),
       assert(backgroundImage != null || onBackgroundImageError == null),
       assert(foregroundImage != null || onForegroundImageError == null);

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

  /// {@macro flutter.widgets.RawAvatar.radius}
  final double? radius;

  /// {@macro flutter.widgets.RawAvatar.minRadius}
  final double? minRadius;

  /// {@macro flutter.widgets.RawAvatar.maxRadius}
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

    return RawAvatar(
      backgroundColor: effectiveBackgroundColor,
      textStyle: textStyle,
      iconTheme: theme.iconTheme.copyWith(color: textStyle.color),
      radius: radius,
      minRadius: minRadius,
      maxRadius: maxRadius,
      backgroundImage: backgroundImage,
      foregroundImage: foregroundImage,
      onBackgroundImageError: onBackgroundImageError,
      onForegroundImageError: onForegroundImageError,
      boxShape: BoxShape.circle,
      child: child,
    );
  }
}
