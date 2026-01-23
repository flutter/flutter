// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'theme.dart';

// Examples can assume:
// late String userAvatarUrl;

/// A circle that represents a user.
///
/// Typically used with a user's profile image, or, in the absence of
/// such an image, the user's initials. A given user's initials should
/// always be paired with the same background color, for consistency.
///
/// If [foregroundImage] fails then [backgroundImage] is used. If
/// [backgroundImage] fails too, [backgroundColor] is used.
///
/// The [onBackgroundImageError] parameter must be null if the [backgroundImage]
/// is null.
/// The [onForegroundImageError] parameter must be null if the [foregroundImage]
/// is null.
///
/// {@tool snippet}
///
/// If the avatar is to have an image, the image should be specified in the
/// [backgroundImage] property:
///
/// ```dart
/// CircleAvatar(
///   backgroundImage: NetworkImage(userAvatarUrl),
/// )
/// ```
/// {@end-tool}
///
/// The image will be cropped to have a circle shape.
///
/// {@tool snippet}
///
/// If the avatar is to just have the user's initials, they are typically
/// provided using a [Text] widget as the [child] and a [backgroundColor]:
///
/// ```dart
/// CircleAvatar(
///   backgroundColor: Colors.brown.shade800,
///   child: const Text('AH'),
/// )
/// ```
/// {@end-tool}
///
/// This widget is backed by [RawAvatar] and uses [ShapeDecoration] internally.
///
/// See also:
///
///  * [Chip], for representing users or concepts in long form.
///  * [ListTile], which can combine an icon (such as a [CircleAvatar]) with
///    some text for a fixed height list entry.
///  * [RawAvatar], the underlying widget that powers [CircleAvatar].
///  * <https://material.io/design/components/chips.html#input-chips>
class CircleAvatar extends StatefulWidget {
  /// Creates a circle that represents a user.
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

  /// The widget below this widget in the tree.
  ///
  /// Typically a [Text] widget. If the [CircleAvatar] is to have an image, use
  /// [backgroundImage] instead.
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

  /// The background image of the circle. Changing the background
  /// image will cause the avatar to animate to the new image.
  ///
  /// Typically used as a fallback image for [foregroundImage].
  ///
  /// If the [CircleAvatar] is to have the user's initials, use [child] instead.
  final ImageProvider? backgroundImage;

  /// The foreground image of the circle.
  ///
  /// Typically used as profile image. For fallback use [backgroundImage].
  final ImageProvider? foregroundImage;

  /// An optional error callback for errors emitted when loading
  /// [backgroundImage].
  final ImageErrorListener? onBackgroundImageError;

  /// An optional error callback for errors emitted when loading
  /// [foregroundImage].
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
  State<CircleAvatar> createState() => _CircleAvatarState();
}

class _CircleAvatarState extends State<CircleAvatar> {
  // The duration for animating theme changes.
  static const Duration _kTextStyleChangeDuration = Duration(milliseconds: 200);

  // Whether the foreground image has failed to load.
  bool _foregroundImageFailed = false;

  @override
  void didUpdateWidget(CircleAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset the failed state if the foreground image changes.
    if (widget.foregroundImage != oldWidget.foregroundImage) {
      _foregroundImageFailed = false;
    }
  }

  void _handleForegroundImageError(Object exception, StackTrace? stackTrace) {
    setState(() {
      _foregroundImageFailed = true;
    });
    widget.onForegroundImageError?.call(exception, stackTrace);
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    final ThemeData theme = Theme.of(context);
    final Color? effectiveForegroundColor =
        widget.foregroundColor ??
        (theme.useMaterial3 ? theme.colorScheme.onPrimaryContainer : null);
    final TextStyle effectiveTextStyle = theme.useMaterial3
        ? theme.textTheme.titleMedium!
        : theme.primaryTextTheme.titleMedium!;
    TextStyle textStyle = effectiveTextStyle.copyWith(color: effectiveForegroundColor);
    Color? effectiveBackgroundColor =
        widget.backgroundColor ?? (theme.useMaterial3 ? theme.colorScheme.primaryContainer : null);
    if (effectiveBackgroundColor == null) {
      effectiveBackgroundColor = switch (ThemeData.estimateBrightnessForColor(textStyle.color!)) {
        Brightness.dark => theme.primaryColorLight,
        Brightness.light => theme.primaryColorDark,
      };
    } else if (effectiveForegroundColor == null) {
      textStyle = switch (ThemeData.estimateBrightnessForColor(widget.backgroundColor!)) {
        Brightness.dark => textStyle.copyWith(color: theme.primaryColorLight),
        Brightness.light => textStyle.copyWith(color: theme.primaryColorDark),
      };
    }

    final Widget? childContent = widget.child == null
        ? null
        : Center(
            child: MediaQuery.withNoTextScaling(
              child: IconTheme(
                data: theme.iconTheme.copyWith(color: textStyle.color),
                child: DefaultTextStyle(style: textStyle, child: widget.child!),
              ),
            ),
          );

    // Convert radius to constraints (diameter = radius * 2)
    final BoxConstraints? constraints;
    if (widget.radius != null) {
      final double diameter = widget.radius! * 2.0;
      constraints = BoxConstraints.tightFor(width: diameter, height: diameter);
    } else if (widget.minRadius != null || widget.maxRadius != null) {
      constraints = BoxConstraints(
        minWidth: widget.minRadius != null ? widget.minRadius! * 2.0 : 0.0,
        minHeight: widget.minRadius != null ? widget.minRadius! * 2.0 : 0.0,
        maxWidth: widget.maxRadius != null ? widget.maxRadius! * 2.0 : double.infinity,
        maxHeight: widget.maxRadius != null ? widget.maxRadius! * 2.0 : double.infinity,
      );
    } else {
      constraints = null;
    }

    // Determine which image to show: foregroundImage (if not failed) or backgroundImage as fallback.
    final ImageProvider? effectiveImage;
    final ImageErrorListener? effectiveOnImageError;
    if (widget.foregroundImage != null && !_foregroundImageFailed) {
      effectiveImage = widget.foregroundImage;
      effectiveOnImageError = _handleForegroundImageError;
    } else {
      effectiveImage = widget.backgroundImage;
      effectiveOnImageError = widget.onBackgroundImageError;
    }

    return RawAvatar(
      constraints: constraints,
      shape: const CircleBorder(),
      backgroundColor: effectiveBackgroundColor,
      image: effectiveImage,
      onImageError: effectiveOnImageError,
      child: AnimatedDefaultTextStyle(
        style: textStyle,
        duration: _kTextStyleChangeDuration,
        child: childContent ?? const SizedBox.shrink(),
      ),
    );
  }
}
