// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'framework.dart';

// Examples can assume:
// late AnimationController controller;

/// Applies an [ImageFilter] to its child.
///
/// For example, an [ImageFilter.blur] can be applied to blur a child that
/// needs to be obscured, or an [ImageFilter.matrix] can be used to apply a
/// bitmap transform to a child at a small trade-off of quality for performance.
///
/// {@tool snippet}
///
/// This example makes the text blurry:
///
/// ```dart
/// ImageFiltered(
///   imageFilter: ui.ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
///   child: const Text('I am blurry'),
/// )
/// ```
/// {@end-tool}
///
/// {@tool snippet}
///
/// This example makes the text (or other complicated widget) rotate
/// around its center based on an [AnimationController] value.
///
/// ```dart
/// ImageFiltered(
///   imageFilterCallback: (Rect bounds) => ui.ImageFilter.matrix(
///     (
///       Matrix4.identity()
///         ..translate(bounds.center.dx, bounds.center.dy)
///         ..rotateZ(controller.value * math.pi * 2.0)
///         ..translate(- bounds.center.dx, - bounds.center.dy)
///     ).storage,
///   ),
///   child: Text('<Insert complicated rendering child here>'),
/// )
/// ```
/// {@end-tool}
///
/// The [ImageFilter] can either be supplied directly at construction time
/// using the [imageFilter] property or it can be generated during the paint
/// operation using the [imageFilterCallback] function. Only one of these
/// properties can be specified and the other must be null.
///
/// The [imageFilter] property will suffice for most [ImageFilter] objects
/// that don't depend on the coordinate location of their source pixels, such
/// as an [ImageFilter.blur].
///
/// The [imageFilterCallback] function will be called with the bounds of
/// the eventual RenderObject after layout so that an [ImageFilter] (such
/// as [ImageFilter.matrix]) that might have different values depending on
/// the bounds of the child can be properly constructed.
///
/// See also:
///
/// * [BackdropFilter], which applies an [ImageFilter] to everything
///   behind its child.
/// * [ColorFiltered], which applies a [ColorFilter] to its child.
/// * [ShaderMask], which applies a shader as a mask to its child.
@immutable
class ImageFiltered extends SingleChildRenderObjectWidget {
  /// Creates a widget that applies an [ImageFilter] to its child.
  ///
  /// Only one of the [imageFilter] or the [imageFilterCallback] should be
  /// specified and the other must be null.
  const ImageFiltered({
    Key? key,
    this.imageFilter,
    this.imageFilterCallback,
    Widget? child,
  }) : assert(imageFilter != null || imageFilterCallback != null,
              'One of imageFilter or imageFilterCallback should be specified'),
       assert(imageFilter == null || imageFilterCallback == null,
              'Only one of imageFilter or imageFilterCallback should be specified'),
       super(key: key, child: child);

  /// The image filter to apply to the child of this widget, or null if the
  /// [imageFilterCallback] is being used to construct a customized filter
  /// for every layout.
  final ui.ImageFilter? imageFilter;

  /// The callback to be used to generate an [ImageFilter] after layout that
  /// might need to be computed based on the bounds of the child, or null if
  /// the filter was specified directly using the [imageFilter] property.
  final ImageFilterCallback? imageFilterCallback;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderImageFiltered(
      imageFilter: imageFilter,
      imageFilterCallback: imageFilterCallback,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderImageFiltered renderObject) {
    renderObject
      ..imageFilter = imageFilter
      ..imageFilterCallback = imageFilterCallback;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ui.ImageFilter>('imageFilter', imageFilter));
  }
}
