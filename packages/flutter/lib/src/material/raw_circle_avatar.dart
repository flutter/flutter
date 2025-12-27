// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'circle_avatar.dart';
library;

import 'package:flutter/widgets.dart';

import 'constants.dart';

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
/// This widget is not themed. For a Material themed version, see [CircleAvatar].
class RawCircleAvatar extends StatelessWidget {
  /// Creates a circle that represents a user.
  const RawCircleAvatar({
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
  /// Typically a [Text] widget. If the [RawCircleAvatar] is to have an image, use
  /// [backgroundImage] instead.
  final Widget? child;

  /// The color with which to fill the circle. Changing the background
  /// color will cause the avatar to animate to the new color.
  final Color? backgroundColor;

  /// The default text color for text in the circle.
  final Color? foregroundColor;

  /// The background image of the circle. Changing the background
  /// image will cause the avatar to animate to the new image.
  ///
  /// Typically used as a fallback image for [foregroundImage].
  ///
  /// If the [RawCircleAvatar] is to have the user's initials, use [child] instead.
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
  final double? radius;

  /// The minimum size of the avatar, expressed as the radius (half the
  /// diameter).
  ///
  /// If [minRadius] is specified, then [radius] must not also be specified.
  ///
  /// Defaults to zero.
  final double? minRadius;

  /// The maximum size of the avatar, expressed as the radius (half the
  /// diameter).
  ///
  /// If [maxRadius] is specified, then [radius] must not also be specified.
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
    return AnimatedContainer(
      constraints: BoxConstraints(
        minHeight: minDiameter,
        minWidth: minDiameter,
        maxWidth: maxDiameter,
        maxHeight: maxDiameter,
      ),
      duration: kThemeChangeDuration,
      decoration: BoxDecoration(
        color: backgroundColor,
        image: backgroundImage != null
            ? DecorationImage(
                image: backgroundImage!,
                onError: onBackgroundImageError,
                fit: BoxFit.cover,
              )
            : null,
        shape: BoxShape.circle,
      ),
      foregroundDecoration: foregroundImage != null
          ? BoxDecoration(
              image: DecorationImage(
                image: foregroundImage!,
                onError: onForegroundImageError,
                fit: BoxFit.cover,
              ),
              shape: BoxShape.circle,
            )
          : null,
      child: child == null
          ? null
          : Center(
              // Need to disable text scaling here so that the text doesn't
              // escape the avatar when the textScaleFactor is large.
              child: MediaQuery.withNoTextScaling(child: child!),
            ),
    );
  }
}
