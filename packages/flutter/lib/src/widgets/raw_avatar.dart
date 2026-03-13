// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

// Examples can assume:
// late String userAvatarUrl;

/// A shape that represents a user.
///
/// Typically used with a user's profile image, or, in the absence of
/// such an image, the user's initials.
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
/// RawAvatar(
///   shape: const CircleBorder(),
///   backgroundImage: NetworkImage(userAvatarUrl),
/// )
/// ```
/// {@end-tool}
///
/// The image will be cropped to the specified [shape].
///
/// {@tool snippet}
///
/// If the avatar is to just have the user's initials, they are typically
/// provided using a [Text] widget as the [child] and a [backgroundColor]:
///
/// ```dart
/// RawAvatar(
///   backgroundColor: Color(0xFF42221A),
///   shape: const CircleBorder(),
///   child: const Text('AH'),
/// )
/// ```
/// {@end-tool}
class RawAvatar extends StatelessWidget {
  /// Creates a shape that represents a user.
  const RawAvatar({
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
    this.shape,
    this.textStyle,
    this.iconTheme,
    this.boxShape,
    this.borderRadius,
    this.duration = const Duration(milliseconds: 200),
  }) : assert(radius == null || (minRadius == null && maxRadius == null)),
       assert(backgroundImage != null || onBackgroundImageError == null),
       assert(foregroundImage != null || onForegroundImageError == null),
       assert(shape == null || boxShape == null),
       assert(boxShape != BoxShape.circle || borderRadius == null);

  /// {@template flutter.widgets.RawAvatar.child}
  /// The widget below this widget in the tree.
  ///
  /// Typically a [Text] widget used to display the user's initials.
  ///
  /// If the avatar is intended to display an image, prefer using
  /// [backgroundImage] or [foregroundImage] instead.
  /// {@endtemplate}
  final Widget? child;

  /// {@template flutter.widgets.RawAvatar.backgroundColor}
  /// The color used to fill the avatar's shape.
  ///
  /// When this value changes, the avatar animates smoothly to the new color.
  /// {@endtemplate}
  final Color? backgroundColor;

  /// {@template flutter.widgets.RawAvatar.foregroundColor}
  /// The default text color used by [child].
  ///
  /// This is typically used when displaying initials inside the avatar.
  /// {@endtemplate}
  final Color? foregroundColor;

  /// {@template flutter.widgets.RawAvatar.textStyle}
  /// The default text style for text displayed inside the avatar.
  ///
  /// If the [child] is a [Text] widget, this style will be used as the
  /// default text style.
  /// {@endtemplate}
  final TextStyle? textStyle;

  /// {@template flutter.widgets.RawAvatar.iconTheme}
  /// The icon theme used for icons inside the avatar.
  ///
  /// This allows customizing the size and color of icons used as [child].
  /// {@endtemplate}
  final IconThemeData? iconTheme;

  /// {@template flutter.widgets.RawAvatar.backgroundImage}
  /// The background image displayed inside the avatar.
  ///
  /// This image is typically used as a fallback when [foregroundImage]
  /// fails to load.
  ///
  /// If the avatar is intended to display initials instead, use [child].
  ///
  /// When this value changes, the avatar animates smoothly to the new image.
  /// {@endtemplate}
  final ImageProvider? backgroundImage;

  /// {@template flutter.widgets.RawAvatar.foregroundImage}
  /// The foreground image displayed inside the avatar.
  ///
  /// This image is typically used as the user's profile image.
  ///
  /// If loading this image fails, [backgroundImage] will be used instead.
  /// {@endtemplate}
  final ImageProvider? foregroundImage;

  /// {@template flutter.widgets.RawAvatar.onBackgroundImageError}
  /// Called when an error occurs while loading [backgroundImage].
  ///
  /// Must be null if [backgroundImage] is null.
  /// {@endtemplate}
  final ImageErrorListener? onBackgroundImageError;

  /// {@template flutter.widgets.RawAvatar.onForegroundImageError}
  /// Called when an error occurs while loading [foregroundImage].
  ///
  /// Must be null if [foregroundImage] is null.
  /// {@endtemplate}
  final ImageErrorListener? onForegroundImageError;

  /// {@template flutter.widgets.RawAvatar.shape}
  /// The shape used to paint the avatar.
  ///
  /// If provided, the avatar is painted using a [ShapeDecoration] with the
  /// given [ShapeBorder].
  ///
  /// When this is specified, [boxShape] and [borderRadius] must be null.
  ///
  /// If none of [shape], [boxShape], or [borderRadius] are provided, the avatar
  /// defaults to a circular shape using [CircleBorder].
  /// {@endtemplate}
  final ShapeBorder? shape;

  /// {@template flutter.widgets.RawAvatar.boxShape}
  /// The basic shape used to paint the avatar when using a [BoxDecoration].
  ///
  /// If this is [BoxShape.circle], the avatar is rendered as a circle.
  ///
  /// If this is [BoxShape.rectangle], the avatar is rendered as a rectangle.
  /// In this case, [borderRadius] may also be provided to create rounded
  /// rectangle corners.
  ///
  /// If [shape] is provided, this value is ignored.
  /// {@endtemplate}
  final BoxShape? boxShape;

  /// {@template flutter.widgets.RawAvatar.borderRadius}
  /// The border radius used when [boxShape] is [BoxShape.rectangle].
  ///
  /// This allows creating rounded rectangle avatars.
  ///
  /// Must be null if [boxShape] is [BoxShape.circle].
  ///
  /// If [shape] is provided, this value is ignored.
  /// {@endtemplate}
  final BorderRadius? borderRadius;

  /// The duration of the animation for changes in properties.
  final Duration duration;

  /// {@template flutter.widgets.RawAvatar.radius}
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
  /// {@endtemplate}
  final double? radius;

  /// {@template flutter.widgets.RawAvatar.minRadius}
  /// The minimum size of the avatar, expressed as the radius (half the
  /// diameter).
  ///
  /// If [minRadius] is specified, then [radius] must not also be specified.
  ///
  /// Defaults to zero.
  ///
  /// Constraint changes are animated, but size changes due to the environment
  /// itself changing are not. For example, changing the [minRadius] from 10 to
  /// 20 when the avatar is in an unconstrained environment will cause
  /// the avatar to animate from a 20 pixel diameter to a 40 pixel diameter.
  /// However, if the [minRadius] is 40 and the avatar has a parent
  /// [SizedBox] whose size changes instantaneously from 20 pixels to 40 pixels,
  /// the size will snap to 40 pixels instantly.
  /// {@endtemplate}
  final double? minRadius;

  /// {@template flutter.widgets.RawAvatar.maxRadius}
  /// The maximum size of the avatar, expressed as the radius (half the
  /// diameter).
  ///
  /// If [maxRadius] is specified, then [radius] must not also be specified.
  ///
  /// Defaults to [double.infinity].
  ///
  /// Constraint changes are animated, but size changes due to the environment
  /// itself changing are not. For example, changing the [maxRadius] from 10 to
  /// 20 when the avatar is in an unconstrained environment will cause
  /// the avatar to animate from a 20 pixel diameter to a 40 pixel diameter.
  /// However, if the [maxRadius] is 40 and the avatar has a parent
  /// [SizedBox] whose size changes instantaneously from 20 pixels to 40 pixels,
  /// the size will snap to 40 pixels instantly.
  /// {@endtemplate}
  final double? maxRadius;

  // The default radius if nothing is specified.
  static const double _defaultRadius = 20.0;

  // The default min if only the max is specified.
  static const double _defaultMinRadius = 0.0;

  // The default max if only the min is specified.
  static const double _defaultMaxRadius = double.infinity;

  double get _minDiameter {
    if (radius == null && minRadius == null && maxRadius == null) {
      return _defaultRadius * 2.0;
    }
    return 2.0 * (radius ?? minRadius ?? _defaultMinRadius);
  }

  double get _maxDiameter {
    if (radius == null && minRadius == null && maxRadius == null) {
      return _defaultRadius * 2.0;
    }
    return 2.0 * (radius ?? maxRadius ?? _defaultMaxRadius);
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));

    final double minDiameter = _minDiameter;
    final double maxDiameter = _maxDiameter;

    final Decoration decoration = _buildDecoration(
      shape: shape,
      boxShape: boxShape,
      borderRadius: borderRadius,
      color: backgroundColor,
      image: backgroundImage,
      onError: onBackgroundImageError,
    );

    final Decoration? foregroundDecoration = foregroundImage != null
        ? _buildDecoration(
            shape: shape,
            boxShape: boxShape,
            borderRadius: borderRadius,
            image: foregroundImage,
            onError: onForegroundImageError,
          )
        : null;

    return AnimatedContainer(
      duration: duration,
      constraints: BoxConstraints(
        minHeight: minDiameter,
        minWidth: minDiameter,
        maxHeight: maxDiameter,
        maxWidth: maxDiameter,
      ),
      decoration: decoration,
      foregroundDecoration: foregroundDecoration,
      child: child == null
          ? null
          : Center(
              child: MediaQuery.withNoTextScaling(
                child: IconTheme(
                  data: iconTheme ?? const IconThemeData(),
                  child: DefaultTextStyle(style: textStyle ?? const TextStyle(), child: child!),
                ),
              ),
            ),
    );
  }

  Decoration _buildDecoration({
    ShapeBorder? shape,
    BoxShape? boxShape,
    BorderRadius? borderRadius,
    Color? color,
    ImageProvider? image,
    ImageErrorListener? onError,
  }) {
    if (shape != null) {
      return ShapeDecoration(
        shape: shape,
        color: color,
        image: image != null
            ? DecorationImage(image: image, fit: BoxFit.cover, onError: onError)
            : null,
      );
    }

    final BoxShape effectiveShape = boxShape ?? BoxShape.circle;

    return BoxDecoration(
      shape: effectiveShape,
      borderRadius: effectiveShape == BoxShape.rectangle ? borderRadius : null,
      color: color,
      image: image != null
          ? DecorationImage(image: image, fit: BoxFit.cover, onError: onError)
          : null,
    );
  }
}
