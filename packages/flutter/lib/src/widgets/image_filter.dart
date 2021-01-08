// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'framework.dart';

/// Signature for a function that creates an [ImageFilter] for a given [Rect].
///
/// Used by [RenderImageFiltered] and the [ImageFiltered] widget.
typedef ImageFilterCallback = ImageFilter Function(Rect bounds);

/// Applies an [ImageFilter] to its child.
///
/// See also:
///
/// * [BackdropFilter], which applies an [ImageFilter] to everything
///   behind its child.
/// * [ColorFiltered], which applies a [ColorFilter] to its child.
@immutable
class ImageFiltered extends SingleChildRenderObjectWidget {
  /// Creates a widget that applies an [ImageFilter] to its child.
  ///
  /// The [imageFilter] must not be null.
  const ImageFiltered({
    Key? key,
    this.imageFilter,
    this.imageFilterCallback,
    Widget? child,
  }) : assert(imageFilter != null || imageFilterCallback != null,
              'One of imageFilter or imageFilterCallback should be non-null'),
       assert(imageFilter == null || imageFilterCallback == null,
              'Only one of imageFilter or imageFilterCallback should be non-null'),
       super(key: key, child: child);

  /// The image filter to apply to the child of this widget.
  final ImageFilter? imageFilter;

  /// The callback
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
    properties.add(DiagnosticsProperty<ImageFilter>('imageFilter', imageFilter));
  }
}

/// Applies an [ImageFilter] to its child.
class RenderImageFiltered extends RenderProxyBox {
  /// Creates a [RenderObject] that applies an [ImageFilter] to its child.
  ///
  /// One of the [imageFilter] or [imageFilterCallback] should not be null here
  /// or whenever the [paint] method is invoked.
  /// The [imageFilter] will be used if it is not null, otherwise the filter
  /// will be obtained from the [imageFilterCallback].
  RenderImageFiltered({
    required ImageFilter? imageFilter,
    required ImageFilterCallback? imageFilterCallback,
  })
      : assert(imageFilter != null || imageFilterCallback != null),
        _imageFilter = imageFilter,
        _imageFilterCallback = imageFilterCallback;

  /// The [ImageFilter] to apply to this child, or null if the filter will be supplied
  /// instead by the [imageFilterCallback].
  ///
  /// If the [imageFilter] is set to null here, then either it or the [imageFilterCallback]
  /// should be set to a non-null value before [paint] is called.
  ImageFilter? get imageFilter => _imageFilter;
  ImageFilter? _imageFilter;
  set imageFilter(ImageFilter? value) {
    if (value != _imageFilter) {
      _imageFilter = value;
      markNeedsPaint();
    }
  }

  /// Called to create the [ImageFilter] to apply to the child if the [imageFilter]
  /// property is null.
  ///
  /// The image filter callback is called with the current bounds of the child so that
  /// it can customize the filter to the size and location of the child.
  ///
  /// If the [imageFilterCallback] is set to null here, then either it or the [imageFilter]
  /// should be set to a non-null value before [paint] is called.
  ImageFilterCallback? get imageFilterCallback => _imageFilterCallback;
  ImageFilterCallback? _imageFilterCallback;
  set imageFilterCallback(ImageFilterCallback? value) {
    if (value != _imageFilterCallback) {
      _imageFilterCallback = value;
      markNeedsPaint();
    }
  }

  @override
  bool get alwaysNeedsCompositing => child != null;

  ImageFilter? _previousFilter;

  @override
  void paint(PaintingContext context, Offset offset) {
    assert(imageFilter != null || imageFilterCallback != null);
    ImageFilter newFilter = imageFilter ?? imageFilterCallback!(offset & size);
    if (_previousFilter == newFilter) {
      // Reuse the previous value if it is the same filter so that native layers
      // can detect the stability for caching and dirty region calculations.
      newFilter = _previousFilter!;
    } else {
      _previousFilter = newFilter;
    }
    if (layer == null) {
      layer = ImageFilterLayer(imageFilter: newFilter);
    } else {
      final ImageFilterLayer filterLayer = layer! as ImageFilterLayer;
      filterLayer.imageFilter = newFilter;
    }
    context.pushLayer(layer!, super.paint, offset);
  }
}
