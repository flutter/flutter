// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/material.dart';
library;

import 'basic.dart';
import 'container.dart';
import 'framework.dart';
import 'text.dart';

/// A raw avatar widget that represents a user.
///
/// This widget provides the core functionality for avatars with customizable
/// shape, background/foreground colors, and images. It handles sizing
/// constraints and builds the appropriate decorations.
///
/// {@tool snippet}
/// This example shows how to create a circular avatar with a background image:
///
/// ```dart
/// RawAvatar(
///   size: 100.0,
///   shape: const CircleBorder(),
///   backgroundImage: NetworkImage('https://example.com/avatar.png'),
/// )
/// ```
/// {@end-tool}
///
/// {@tool snippet}
/// This example shows how to create a rounded rectangle avatar with initials:
///
/// ```dart
/// RawAvatar(
///   size: 60.0,
///   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
///   backgroundColor: Colors.blue,
///   child: Text('AB'),
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [CircleAvatar], a Material Design styled circular avatar.
class RawAvatar extends StatelessWidget {
  /// Creates a raw avatar widget.
  ///
  /// The [size] and [minSize]/[maxSize] parameters are mutually exclusive.
  ///
  /// The [onBackgroundImageError] parameter must be null if the [backgroundImage]
  /// is null. The [onForegroundImageError] parameter must be null if the
  /// [foregroundImage] is null.
  const RawAvatar({
    super.key,
    this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.backgroundImage,
    this.foregroundImage,
    this.onBackgroundImageError,
    this.onForegroundImageError,
    this.shape,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.size,
    this.minSize,
    this.maxSize,
  }) : assert(size == null || (minSize == null && maxSize == null)),
       assert(backgroundImage != null || onBackgroundImageError == null),
       assert(foregroundImage != null || onForegroundImageError == null);

  /// The widget below this widget in the tree.
  ///
  /// Typically a [Text] widget containing initials, or an [Icon].
  final Widget? child;

  /// The color with which to fill the avatar.
  final Color? backgroundColor;

  /// The default text color for text in the avatar.
  final Color? foregroundColor;

  /// The background image of the avatar.
  ///
  /// Typically used as a fallback image for [foregroundImage].
  ///
  /// If the [RawAvatar] is to have the user's initials, use [child] instead.
  final ImageProvider? backgroundImage;

  /// The foreground image of the avatar.
  ///
  /// Typically used as profile image. For fallback use [backgroundImage].
  final ImageProvider? foregroundImage;

  /// An optional error callback for errors emitted when loading
  /// [backgroundImage].
  final ImageErrorListener? onBackgroundImageError;

  /// An optional error callback for errors emitted when loading
  /// [foregroundImage].
  final ImageErrorListener? onForegroundImageError;

  /// The shape of the avatar.
  ///
  /// Common shapes include [CircleBorder] for circular avatars and
  /// [RoundedRectangleBorder] for rounded rectangle avatars.
  ///
  /// If null, no shape clipping is applied.
  final ShapeBorder? shape;

  /// How the image should be inscribed into the avatar.
  ///
  /// This applies to both [backgroundImage] and [foregroundImage].
  final BoxFit fit;

  /// How to align the image within the avatar.
  ///
  /// This applies to both [backgroundImage] and [foregroundImage].
  final AlignmentGeometry alignment;

  /// The size of the avatar (both width and height).
  ///
  /// If [size] is specified, then neither [minSize] nor [maxSize] may be
  /// specified. Specifying [size] is equivalent to specifying a [minSize]
  /// and [maxSize], both with the value of [size].
  final double? size;

  /// The minimum size of the avatar (both width and height).
  ///
  /// If [minSize] is specified, then [size] must not also be specified.
  ///
  /// Defaults to zero.
  final double? minSize;

  /// The maximum size of the avatar (both width and height).
  ///
  /// If [maxSize] is specified, then [size] must not also be specified.
  ///
  /// Defaults to [double.infinity].
  final double? maxSize;

  // The default size if nothing is specified.
  static const double _defaultSize = 40.0;

  // The default min if only the max is specified.
  static const double _defaultMinSize = 0.0;

  // The default max if only the min is specified.
  static const double _defaultMaxSize = double.infinity;

  double get _minSize {
    if (size == null && minSize == null && maxSize == null) {
      return _defaultSize;
    }
    return size ?? minSize ?? _defaultMinSize;
  }

  double get _maxSize {
    if (size == null && minSize == null && maxSize == null) {
      return _defaultSize;
    }
    return size ?? maxSize ?? _defaultMaxSize;
  }

  @override
  Widget build(BuildContext context) {
    final double minDimension = _minSize;
    final double maxDimension = _maxSize;

    final Decoration? decoration =
        (backgroundColor != null || backgroundImage != null || shape != null)
        ? ShapeDecoration(
            color: backgroundColor,
            image: backgroundImage != null
                ? DecorationImage(
                    image: backgroundImage!,
                    onError: onBackgroundImageError,
                    fit: fit,
                    alignment: alignment,
                  )
                : null,
            shape: shape ?? const Border(),
          )
        : null;

    final Decoration? foregroundDecoration = foregroundImage != null
        ? ShapeDecoration(
            image: DecorationImage(
              image: foregroundImage!,
              onError: onForegroundImageError,
              fit: fit,
              alignment: alignment,
            ),
            shape: shape ?? const Border(),
          )
        : null;

    return Container(
      constraints: BoxConstraints(
        minHeight: minDimension,
        minWidth: minDimension,
        maxWidth: maxDimension,
        maxHeight: maxDimension,
      ),
      decoration: decoration,
      foregroundDecoration: foregroundDecoration,
      child: child != null
          ? DefaultTextStyle.merge(
              style: TextStyle(color: foregroundColor),
              child: child!,
            )
          : null,
    );
  }
}
