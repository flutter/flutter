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
/// shape, background color, and image. It handles sizing constraints and
/// builds the appropriate decorations.
///
/// {@tool snippet}
/// This example shows how to create a circular avatar with an image:
///
/// ```dart
/// RawAvatar(
///   constraints: BoxConstraints.tight(Size.square(100.0)),
///   shape: const CircleBorder(),
///   image: NetworkImage('https://example.com/avatar.png'),
/// )
/// ```
/// {@end-tool}
///
/// {@tool snippet}
/// This example shows how to create a rounded rectangle avatar with initials:
///
/// ```dart
/// RawAvatar(
///   constraints: BoxConstraints.tight(Size.square(60.0)),
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
  /// The [onImageError] parameter must be null if [image] is null.
  const RawAvatar({
    super.key,
    this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.image,
    this.onImageError,
    this.shape,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.constraints,
  }) : assert(image != null || onImageError == null);

  /// The widget below this widget in the tree.
  ///
  /// Typically a [Text] widget containing initials, or an [Icon].
  final Widget? child;

  /// The color with which to fill the avatar's background.
  final Color? backgroundColor;

  /// The default text color for text in the avatar.
  final Color? foregroundColor;

  /// The image to display in the avatar.
  ///
  /// If the [RawAvatar] is to have the user's initials, use [child] instead.
  final ImageProvider? image;

  /// An optional error callback for errors emitted when loading [image].
  final ImageErrorListener? onImageError;

  /// The shape of the avatar.
  ///
  /// Common shapes include [CircleBorder] for circular avatars and
  /// [RoundedRectangleBorder] for rounded rectangle avatars.
  ///
  /// If null, no shape clipping is applied.
  final ShapeBorder? shape;

  /// How the image should be inscribed into the avatar.
  final BoxFit fit;

  /// How to align the image within the avatar.
  final AlignmentGeometry alignment;

  /// The constraints for the avatar's size.
  ///
  /// If null, defaults to a tight constraint of 40x40 logical pixels.
  final BoxConstraints? constraints;

  // The default constraints if nothing is specified.
  static const BoxConstraints _defaultConstraints = BoxConstraints.tightFor(
    width: 40.0,
    height: 40.0,
  );

  @override
  Widget build(BuildContext context) {
    final Decoration? decoration = (backgroundColor != null || image != null || shape != null)
        ? ShapeDecoration(
            color: backgroundColor,
            image: image != null
                ? DecorationImage(
                    image: image!,
                    onError: onImageError,
                    fit: fit,
                    alignment: alignment,
                  )
                : null,
            shape: shape ?? const Border(),
          )
        : null;

    return Container(
      constraints: constraints ?? _defaultConstraints,
      decoration: decoration,
      child: child != null
          ? DefaultTextStyle.merge(
              style: TextStyle(color: foregroundColor),
              child: child!,
            )
          : null,
    );
  }
}
