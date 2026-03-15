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
    this.size,
    this.minSize,
    this.maxSize,
    this.shape,
    this.textStyle,
    this.iconTheme,
    this.boxShape,
    this.borderRadius,
    this.duration = const Duration(milliseconds: 200),
  }) : assert(size == null || (minSize == null && maxSize == null)),
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

  /// {@template flutter.widgets.RawAvatar.size}
  /// The size of the avatar in logical pixels.
  ///
  /// If [size] is specified, then neither [minSize] nor [maxSize] may be
  /// specified. Specifying [size] is equivalent to specifying both [minSize]
  /// and [maxSize] with the same value.
  ///
  /// If neither [size], [minSize], nor [maxSize] are specified, the avatar
  /// defaults to 40 logical pixels.
  /// {@endtemplate}
  final double? size;

  /// {@template flutter.widgets.RawAvatar.minSize}
  /// The minimum size of the avatar in logical pixels.
  ///
  /// If [minSize] is specified, then [size] must not also be specified.
  ///
  /// Defaults to zero.
  /// {@endtemplate}
  final double? minSize;

  /// {@template flutter.widgets.RawAvatar.maxSize}
  /// The maximum size of the avatar in logical pixels.
  ///
  /// If [maxSize] is specified, then [size] must not also be specified.
  ///
  /// Defaults to [double.infinity].
  /// {@endtemplate}
  final double? maxSize;

  // Default size if nothing is specified.
  static const double _defaultSize = 40.0;

  // Default min if only max is specified.
  static const double _defaultMinSize = 0.0;

  // Default max if only min is specified.
  static const double _defaultMaxSize = double.infinity;

  bool get _hasExplicitSize => size != null || minSize != null || maxSize != null;

  double get _effectiveMinSize {
    if (!_hasExplicitSize) {
      return _defaultSize;
    }
    return size ?? minSize ?? _defaultMinSize;
  }

  double get _effectiveMaxSize {
    if (!_hasExplicitSize) {
      return _defaultSize;
    }
    return size ?? maxSize ?? _defaultMaxSize;
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));

    final Decoration decoration = _effectiveDecoration(
      shape: shape,
      boxShape: boxShape,
      borderRadius: borderRadius,
      color: backgroundColor,
      image: backgroundImage,
      onError: onBackgroundImageError,
    );

    final Decoration? foregroundDecoration = foregroundImage != null
        ? _effectiveDecoration(
            shape: shape,
            boxShape: boxShape,
            borderRadius: borderRadius,
            image: foregroundImage,
            onError: onForegroundImageError,
          )
        : null;

    Widget avatar = AnimatedContainer(
      duration: duration,
      constraints: BoxConstraints(
        minHeight: _effectiveMinSize,
        minWidth: _effectiveMinSize,
        maxHeight: _effectiveMaxSize,
        maxWidth: _effectiveMaxSize,
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

    if (shape != null) {
      avatar = ClipPath(
        clipper: ShapeBorderClipper(shape: shape!),
        child: avatar,
      );
    }

    return avatar;
  }

  Decoration _effectiveDecoration({
    ShapeBorder? shape,
    BoxShape? boxShape,
    BorderRadius? borderRadius,
    Color? color,
    ImageProvider? image,
    ImageErrorListener? onError,
  }) {
    final DecorationImage? decorationImage = image != null
        ? DecorationImage(image: image, fit: BoxFit.cover, onError: onError)
        : null;

    if (shape != null) {
      return ShapeDecoration(shape: shape, color: color, image: decorationImage);
    }

    return BoxDecoration(
      shape: boxShape ?? BoxShape.circle,
      borderRadius: borderRadius,
      color: color,
      image: decorationImage,
    );
  }
}
