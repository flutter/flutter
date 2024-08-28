// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:ui/src/engine/scene_painting.dart';
import 'package:ui/src/engine/vector_math.dart';
import 'package:ui/ui.dart' as ui;

class EngineRootLayer with PictureEngineLayer {}

class BackdropFilterLayer
  with PictureEngineLayer
  implements ui.BackdropFilterEngineLayer {}
class BackdropFilterOperation implements LayerOperation {
  BackdropFilterOperation(this.filter, this.mode);

  final ui.ImageFilter filter;
  final ui.BlendMode mode;

  @override
  ui.Rect mapRect(ui.Rect contentRect) => contentRect;

  @override
  void pre(SceneCanvas canvas, ui.Rect contentRect) {
    canvas.saveLayerWithFilter(contentRect, ui.Paint()..blendMode = mode, filter);
  }

  @override
  void post(SceneCanvas canvas, ui.Rect contentRect) {
    canvas.restore();
  }

  @override
  PlatformViewStyling createPlatformViewStyling() => const PlatformViewStyling();

  // The backdrop filter actually has an effect on the scene even if it contains
  // no pictures, so we return true here.
  @override
  bool get shouldDrawIfEmpty => true;
}

class ClipPathLayer
  with PictureEngineLayer
  implements ui.ClipPathEngineLayer {}
class ClipPathOperation implements LayerOperation {
  ClipPathOperation(this.path, this.clip);

  final ScenePath path;
  final ui.Clip clip;

  @override
  ui.Rect mapRect(ui.Rect contentRect) => contentRect.intersect(path.getBounds());

  @override
  void pre(SceneCanvas canvas, ui.Rect contentRect) {
    canvas.save();
    canvas.clipPath(path, doAntiAlias: clip != ui.Clip.hardEdge);
    if (clip == ui.Clip.antiAliasWithSaveLayer) {
      canvas.saveLayer(path.getBounds(), ui.Paint());
    }
  }

  @override
  void post(SceneCanvas canvas, ui.Rect contentRect) {
    if (clip == ui.Clip.antiAliasWithSaveLayer) {
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  PlatformViewStyling createPlatformViewStyling() {
    return PlatformViewStyling(clip: PlatformViewPathClip(path));
  }

  @override
  bool get shouldDrawIfEmpty => false;
}

class ClipRectLayer
  with PictureEngineLayer
  implements ui.ClipRectEngineLayer {}
class ClipRectOperation implements LayerOperation {
  const ClipRectOperation(this.rect, this.clip);

  final ui.Rect rect;
  final ui.Clip clip;

  @override
  ui.Rect mapRect(ui.Rect contentRect) => contentRect.intersect(rect);

  @override
  void pre(SceneCanvas canvas, ui.Rect contentRect) {
    canvas.save();
    canvas.clipRect(rect, doAntiAlias: clip != ui.Clip.hardEdge);
    if (clip == ui.Clip.antiAliasWithSaveLayer) {
      canvas.saveLayer(rect, ui.Paint());
    }
  }

  @override
  void post(SceneCanvas canvas, ui.Rect contentRect) {
    if (clip == ui.Clip.antiAliasWithSaveLayer) {
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  PlatformViewStyling createPlatformViewStyling() {
    return PlatformViewStyling(clip: PlatformViewRectClip(rect));
  }

  @override
  bool get shouldDrawIfEmpty => false;
}

class ClipRRectLayer
  with PictureEngineLayer
  implements ui.ClipRRectEngineLayer {}
class ClipRRectOperation implements LayerOperation {
  const ClipRRectOperation(this.rrect, this.clip);

  final ui.RRect rrect;
  final ui.Clip clip;

  @override
  ui.Rect mapRect(ui.Rect contentRect) => contentRect.intersect(rrect.outerRect);

  @override
  void pre(SceneCanvas canvas, ui.Rect contentRect) {
    canvas.save();
    canvas.clipRRect(rrect, doAntiAlias: clip != ui.Clip.hardEdge);
    if (clip == ui.Clip.antiAliasWithSaveLayer) {
      canvas.saveLayer(rrect.outerRect, ui.Paint());
    }
  }

  @override
  void post(SceneCanvas canvas, ui.Rect contentRect) {
    if (clip == ui.Clip.antiAliasWithSaveLayer) {
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  PlatformViewStyling createPlatformViewStyling() {
    return PlatformViewStyling(clip: PlatformViewRRectClip(rrect));
  }

  @override
  bool get shouldDrawIfEmpty => false;
}

class ColorFilterLayer
  with PictureEngineLayer
  implements ui.ColorFilterEngineLayer {}
class ColorFilterOperation implements LayerOperation {
  ColorFilterOperation(this.filter);

  final ui.ColorFilter filter;

  @override
  ui.Rect mapRect(ui.Rect contentRect) => contentRect;

  @override
  void pre(SceneCanvas canvas, ui.Rect contentRect) {
    canvas.saveLayer(contentRect, ui.Paint()..colorFilter = filter);
  }

  @override
  void post(SceneCanvas canvas, ui.Rect contentRect) {
    canvas.restore();
  }

  @override
  PlatformViewStyling createPlatformViewStyling() => const PlatformViewStyling();

  @override
  bool get shouldDrawIfEmpty => false;
}

class ImageFilterLayer
  with PictureEngineLayer
  implements ui.ImageFilterEngineLayer {}
class ImageFilterOperation implements LayerOperation {
  ImageFilterOperation(this.filter, this.offset);

  final SceneImageFilter filter;
  final ui.Offset offset;

  @override
  ui.Rect mapRect(ui.Rect contentRect) => filter.filterBounds(contentRect);

  @override
  void pre(SceneCanvas canvas, ui.Rect contentRect) {
    if (offset != ui.Offset.zero) {
      canvas.save();
      canvas.translate(offset.dx, offset.dy);
    }
    final ui.Rect adjustedContentRect = filter.filterBounds(contentRect);
    canvas.saveLayer(adjustedContentRect, ui.Paint()..imageFilter = filter);
  }

  @override
  void post(SceneCanvas canvas, ui.Rect contentRect) {
    if (offset != ui.Offset.zero) {
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  PlatformViewStyling createPlatformViewStyling() {
    if (offset != ui.Offset.zero) {
      return PlatformViewStyling(
        position: PlatformViewPosition.offset(offset)
      );
    } else {
      return const PlatformViewStyling();
    }
  }

  @override
  bool get shouldDrawIfEmpty => false;
}

class OffsetLayer
  with PictureEngineLayer
  implements ui.OffsetEngineLayer {}
class OffsetOperation implements LayerOperation {
  OffsetOperation(this.dx, this.dy);

  final double dx;
  final double dy;

  @override
  ui.Rect mapRect(ui.Rect contentRect) => contentRect.shift(ui.Offset(dx, dy));

  @override
  void pre(SceneCanvas canvas, ui.Rect cullRect) {
    canvas.save();
    canvas.translate(dx, dy);
  }

  @override
  void post(SceneCanvas canvas, ui.Rect contentRect) {
    canvas.restore();
  }

  @override
  PlatformViewStyling createPlatformViewStyling() => PlatformViewStyling(
    position: PlatformViewPosition.offset(ui.Offset(dx, dy))
  );

  @override
  bool get shouldDrawIfEmpty => false;
}

class OpacityLayer
  with PictureEngineLayer
  implements ui.OpacityEngineLayer {}
class OpacityOperation implements LayerOperation {
  OpacityOperation(this.alpha, this.offset);

  final int alpha;
  final ui.Offset offset;

  @override
  ui.Rect mapRect(ui.Rect contentRect) => contentRect.shift(offset);

  @override
  void pre(SceneCanvas canvas, ui.Rect cullRect) {
    if (offset != ui.Offset.zero) {
      canvas.save();
      canvas.translate(offset.dx, offset.dy);
      cullRect = cullRect.shift(-offset);
    }
    canvas.saveLayer(
      cullRect,
      ui.Paint()..color = ui.Color.fromARGB(alpha, 0, 0, 0)
    );
  }

  @override
  void post(SceneCanvas canvas, ui.Rect contentRect) {
    canvas.restore();
    if (offset != ui.Offset.zero) {
      canvas.restore();
    }
  }

  @override
  PlatformViewStyling createPlatformViewStyling() => PlatformViewStyling(
    position: offset != ui.Offset.zero ? PlatformViewPosition.offset(offset) : const PlatformViewPosition.zero(),
    opacity: alpha.toDouble() / 255.0,
  );

  @override
  bool get shouldDrawIfEmpty => false;
}

class TransformLayer
  with PictureEngineLayer
  implements ui.TransformEngineLayer {}
class TransformOperation implements LayerOperation {
  TransformOperation(this.transform);

  final Float64List transform;

  Matrix4? _memoizedMatrix;
  Matrix4 get matrix => _memoizedMatrix ?? (_memoizedMatrix = Matrix4.fromFloat32List(toMatrix32(transform)));

  @override
  ui.Rect mapRect(ui.Rect contentRect) => matrix.transformRect(contentRect);

  @override
  void pre(SceneCanvas canvas, ui.Rect cullRect) {
    canvas.save();
    canvas.transform(transform);
  }

  @override
  void post(SceneCanvas canvas, ui.Rect contentRect) {
    canvas.restore();
  }

  @override
  PlatformViewStyling createPlatformViewStyling() => PlatformViewStyling(
    position: PlatformViewPosition.transform(matrix),
  );

  @override
  bool get shouldDrawIfEmpty => false;
}

class ShaderMaskLayer
  with PictureEngineLayer
  implements ui.ShaderMaskEngineLayer {}
class ShaderMaskOperation implements LayerOperation {
  ShaderMaskOperation(this.shader, this.maskRect, this.blendMode);

  final ui.Shader shader;
  final ui.Rect maskRect;
  final ui.BlendMode blendMode;

  @override
  ui.Rect mapRect(ui.Rect contentRect) => contentRect;

  @override
  void pre(SceneCanvas canvas, ui.Rect contentRect) {
    canvas.saveLayer(
      contentRect,
      ui.Paint(),
    );
  }

  @override
  void post(SceneCanvas canvas, ui.Rect contentRect) {
    canvas.save();
    canvas.translate(maskRect.left, maskRect.top);
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, maskRect.width, maskRect.height),
      ui.Paint()
        ..blendMode = blendMode
        ..shader = shader
    );
    canvas.restore();
    canvas.restore();
  }

  @override
  PlatformViewStyling createPlatformViewStyling() => const PlatformViewStyling();

  @override
  bool get shouldDrawIfEmpty => false;
}

class PlatformView {
  PlatformView(this.viewId, this.bounds, this.styling);

  final int viewId;

  // The bounds of this platform view, in the layer's local coordinate space.
  final ui.Rect bounds;

  final PlatformViewStyling styling;
}

sealed class LayerSlice {
  void dispose();
}

// A slice that contains one or more platform views to be rendered.
class PlatformViewSlice implements LayerSlice {
  PlatformViewSlice(this.views, this.occlusionRect);

  List<PlatformView> views;

  // A conservative estimate of what area platform views in this slice may cover.
  // This is expressed in the coordinate space of the parent.
  ui.Rect? occlusionRect;

  @override
  void dispose() {}
}

// A slice that contains flutter content to be rendered int he form of a single
// ScenePicture.
class PictureSlice implements LayerSlice {
  PictureSlice(this.picture);

  ScenePicture picture;

  @override
  void dispose() => picture.dispose();
}

mixin PictureEngineLayer implements ui.EngineLayer {
  // Each layer is represented as a series of "slices" which contain either
  // flutter content or platform views. Slices in this list are ordered from
  // bottom to top.
  List<LayerSlice> slices = <LayerSlice>[];

  @override
  void dispose() {
    for (final LayerSlice slice in slices) {
      slice.dispose();
    }
  }
}

abstract class LayerOperation {
  const LayerOperation();

  // Given an input content rectangle, this returns a conservative estimate of
  // the covering rectangle of the content after it has been processed by the
  // layer operation.
  ui.Rect mapRect(ui.Rect contentRect);

  void pre(SceneCanvas canvas, ui.Rect contentRect);
  void post(SceneCanvas canvas, ui.Rect contentRect);

  PlatformViewStyling createPlatformViewStyling();

  /// Indicates whether this operation's `pre` and `post` methods should be
  /// invoked even if it contains no pictures. (Most operations don't need to
  /// actually be performed at all if they don't contain any pictures.)
  bool get shouldDrawIfEmpty;
}

class PictureDrawCommand {
  PictureDrawCommand(this.offset, this.picture);

  ui.Offset offset;
  ui.Picture picture;
}

// Represents how a platform view should be positioned in the scene.
// This object is immutable, so it can be reused across different platform
// views that have the same positioning.
class PlatformViewPosition {
  // No transformation at all. We leave both fields null.
  const PlatformViewPosition.zero() : offset = null, transform = null;

  // A simple offset is the most common scenario. In those cases, we only
  // store the offset and leave the transform as null
  const PlatformViewPosition.offset(this.offset) : transform = null;

  // In more complex cases, we store the transform. In those cases, the offset
  // is left as null.
  const PlatformViewPosition.transform(this.transform) : offset = null;

  bool get isZero => (offset == null) && (transform == null);

  final ui.Offset? offset;
  final Matrix4? transform;

  static PlatformViewPosition combine(PlatformViewPosition outer, PlatformViewPosition inner) {
    // We try to reuse existing objects if possible, if they are immutable.
    if (outer.isZero) {
      return inner;
    }
    if (inner.isZero) {
      return outer;
    }
    final ui.Offset? outerOffset = outer.offset;
    final ui.Offset? innerOffset = inner.offset;
    if (outerOffset != null && innerOffset != null) {
      // Both positions are simple offsets, so they can be combined cheaply
      // into another offset.
      return PlatformViewPosition.offset(outerOffset + innerOffset);
    }

    // Otherwise, at least one of the positions involves a matrix transform.
    final Matrix4 innerTransform;
    final Matrix4 outerTransform;
    if (innerOffset != null) {
      innerTransform = Matrix4.translationValues(innerOffset.dx, innerOffset.dy, 0);
    } else {
      innerTransform = inner.transform!;
    }
    if (outerOffset != null) {
      outerTransform = Matrix4.translationValues(outerOffset.dx, outerOffset.dy, 0);
    } else {
      outerTransform = outer.transform!;
    }
    return PlatformViewPosition.transform(outerTransform.multiplied(innerTransform));
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! PlatformViewPosition) {
      return false;
    }
    return (offset == other.offset) && (transform == other.transform);
  }

  @override
  int get hashCode {
    return Object.hash(offset, transform);
  }
}

// Represents the styling to be performed on a platform view when it is
// composited. This object is immutable so that it can be reused with different
// platform views that have the same styling.
class PlatformViewStyling {
  const PlatformViewStyling({
    this.position = const PlatformViewPosition.zero(),
    this.clip = const PlatformViewNoClip(),
    this.opacity = 1.0
  });

  bool get isDefault => position.isZero && (opacity == 1.0) && clip is PlatformViewNoClip;

  final PlatformViewPosition position;
  final double opacity;
  final PlatformViewClip clip;

  static PlatformViewStyling combine(PlatformViewStyling outer, PlatformViewStyling inner) {
    // Attempt to reuse one of the existing immutable objects.
    if (outer.isDefault) {
      return inner;
    }
    if (inner.isDefault) {
      return outer;
    }
    return PlatformViewStyling(
      position: PlatformViewPosition.combine(outer.position, inner.position),
      clip: PlatformViewClip.combine(outer.clip, inner.clip.positioned(outer.position)),
      opacity: outer.opacity * inner.opacity,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! PlatformViewStyling) {
      return false;
    }
    return (position == other.position) && (opacity == other.opacity) && (clip == other.clip);
  }

  @override
  int get hashCode {
    return Object.hash(position, opacity, clip);
  }
}

sealed class PlatformViewClip {
  PlatformViewClip positioned(PlatformViewPosition position);

  /// The largest rectangle that is entirely inside the clip region. All
  /// inside of this region is unclipped.
  ui.Rect get innerRect;

  /// The bounding rectangle of the clip region. All content outside of this
  /// region is clipped.
  ui.Rect get outerRect;

  ScenePath get toPath;

  static bool rectCovers(ui.Rect covering, ui.Rect covered) {
    return covering.left <= covered.left &&
      covering.right >= covered.right &&
      covering.top <= covered.top &&
      covering.bottom >= covered.bottom;
  }

  static PlatformViewClip combine(PlatformViewClip outer, PlatformViewClip inner) {
    if (outer is PlatformViewNoClip) {
      return inner;
    }
    if (inner is PlatformViewNoClip) {
      return outer;
    }

    if (rectCovers(outer.innerRect, inner.outerRect)) {
      return inner;
    }

    if (rectCovers(inner.innerRect, outer.outerRect)) {
      return outer;
    }

    return PlatformViewPathClip(
      ui.Path.combine(ui.PathOperation.intersect, outer.toPath, inner.toPath) as ScenePath
    );
  }
}

class PlatformViewNoClip implements PlatformViewClip {
  const PlatformViewNoClip();

  @override
  PlatformViewClip positioned(PlatformViewPosition positioned) {
    return this;
  }

  @override
  ScenePath get toPath => ui.Path() as ScenePath;

  @override
  bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == PlatformViewNoClip);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  ui.Rect get innerRect => ui.Rect.zero;

  @override
  ui.Rect get outerRect => ui.Rect.zero;
}

class PlatformViewRectClip implements PlatformViewClip {
  PlatformViewRectClip(this.rect);

  final ui.Rect rect;

  @override
  PlatformViewClip positioned(PlatformViewPosition position) {
    if (position.isZero) {
      return this;
    }
    final ui.Offset? offset = position.offset;
    if (offset != null) {
      return PlatformViewRectClip(rect.shift(offset));
    } else {
      return PlatformViewPathClip(toPath.transform(position.transform!.toFloat64()) as ScenePath);
    }
  }

  @override
  ScenePath get toPath => (ui.Path() as ScenePath)..addRect(rect);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is PlatformViewRectClip && rect == other.rect;
  }

  @override
  int get hashCode => Object.hash(runtimeType, rect);

  @override
  ui.Rect get innerRect => rect;

  @override
  ui.Rect get outerRect => rect;
}

class PlatformViewRRectClip implements PlatformViewClip {
  PlatformViewRRectClip(this.rrect);

  final ui.RRect rrect;

  @override
  PlatformViewClip positioned(PlatformViewPosition position) {
    if (position.isZero) {
      return this;
    }
    final ui.Offset? offset = position.offset;
    if (offset != null) {
      return PlatformViewRRectClip(rrect.shift(offset));
    } else {
      return PlatformViewPathClip(toPath.transform(position.transform!.toFloat64()) as ScenePath);
    }
  }

  @override
  ScenePath get toPath => (ui.Path() as ScenePath)..addRRect(rrect);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is PlatformViewRRectClip && rrect == other.rrect;
  }

  @override
  int get hashCode => Object.hash(runtimeType, rrect);

  @override
  ui.Rect get innerRect => rrect.safeInnerRect;

  @override
  ui.Rect get outerRect => rrect.outerRect;
}

class PlatformViewPathClip implements PlatformViewClip {
  PlatformViewPathClip(this.path);

  final ScenePath path;

  @override
  PlatformViewClip positioned(PlatformViewPosition position) {
    if (position.isZero) {
      return this;
    }

    final ui.Offset? offset = position.offset;
    if (offset != null) {
      return PlatformViewPathClip(path.shift(offset) as ScenePath);
    } else {
      return PlatformViewPathClip(path.transform(position.transform!.toFloat64()) as ScenePath);
    }
  }

  @override
  ScenePath get toPath => path;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is PlatformViewPathClip && path == other.path;
  }

  @override
  int get hashCode => Object.hash(runtimeType, path);

  @override
  ui.Rect get innerRect => ui.Rect.zero;

  @override
  ui.Rect get outerRect => path.getBounds();
}

class LayerBuilder {
  factory LayerBuilder.rootLayer() {
    return LayerBuilder._(null, EngineRootLayer(), null);
  }

  factory LayerBuilder.childLayer({
    required LayerBuilder parent,
    required PictureEngineLayer layer,
    required LayerOperation operation
  }) {
    return LayerBuilder._(parent, layer, operation);
  }

  LayerBuilder._(
    this.parent,
    this.layer,
    this.operation);

  @visibleForTesting
  static (ui.PictureRecorder, SceneCanvas) Function(ui.Rect)? debugRecorderFactory;

  final LayerBuilder? parent;
  final PictureEngineLayer layer;
  final LayerOperation? operation;
  final List<PictureDrawCommand> pendingPictures = <PictureDrawCommand>[];
  List<PlatformView> pendingPlatformViews = <PlatformView>[];
  ui.Rect? picturesRect;
  ui.Rect? platformViewRect;

  PlatformViewStyling? _memoizedPlatformViewStyling;

  PlatformViewStyling get platformViewStyling {
    return _memoizedPlatformViewStyling ??= operation?.createPlatformViewStyling() ?? const PlatformViewStyling();
  }

  (ui.PictureRecorder, SceneCanvas) _createRecorder(ui.Rect rect) {
    if (debugRecorderFactory != null) {
      return debugRecorderFactory!(rect);
    }
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final SceneCanvas canvas = ui.Canvas(recorder, rect) as SceneCanvas;
    return (recorder, canvas);
  }

  void flushSlices() {
    if (pendingPictures.isNotEmpty || (operation?.shouldDrawIfEmpty ?? false)) {
      // Merge the existing draw commands into a single picture and add a slice
      // with that picture to the slice list.
      final ui.Rect drawnRect = picturesRect ?? ui.Rect.zero;
      final ui.Rect rect = operation?.mapRect(drawnRect) ?? drawnRect;
      final (ui.PictureRecorder recorder, SceneCanvas canvas) = _createRecorder(rect);

      operation?.pre(canvas, rect);
      for (final PictureDrawCommand command in pendingPictures) {
        if (command.offset != ui.Offset.zero) {
          canvas.save();
          canvas.translate(command.offset.dx, command.offset.dy);
          canvas.drawPicture(command.picture);
          canvas.restore();
        } else {
          canvas.drawPicture(command.picture);
        }
      }
      operation?.post(canvas, rect);
      final ui.Picture picture = recorder.endRecording();
      layer.slices.add(PictureSlice(picture as ScenePicture));
    }

    if (pendingPlatformViews.isNotEmpty) {
      // Take any pending platform views and lower them into a platform view
      // slice.
      ui.Rect? occlusionRect = platformViewRect;
      if (occlusionRect != null && operation != null) {
        occlusionRect = operation!.mapRect(occlusionRect);
      }
      layer.slices.add(PlatformViewSlice(pendingPlatformViews, occlusionRect));
    }

    pendingPictures.clear();
    pendingPlatformViews = <PlatformView>[];

    // All the pictures and platform views have been lowered into slices. Clear
    // our occlusion rectangles.
    picturesRect = null;
    platformViewRect = null;
  }

  void addPicture(
    ui.Offset offset,
    ui.Picture picture, {
    bool isComplexHint = false,
    bool willChangeHint = false
  }) {
    final ui.Rect cullRect = (picture as ScenePicture).cullRect;
    final ui.Rect shiftedRect = cullRect.shift(offset);

    final ui.Rect? currentPlatformViewRect = platformViewRect;
    if (currentPlatformViewRect != null) {
      // Whenever we add a picture to our layer, we try to see if the picture
      // will overlap with any platform views that are currently on top of our
      // drawing surface. If they don't overlap with the platform views, they
      // can be grouped with the existing pending pictures.
      if (pendingPictures.isEmpty || currentPlatformViewRect.overlaps(shiftedRect)) {
        // If they do overlap with the platform views, however, we should flush
        // all the current content into slices and start anew with a fresh
        // group of pictures and platform views that will be rendered on top of
        // the previous content. Note that we also flush if we have no pending
        // pictures to group with. This is the case when platform views are
        // the first thing in our stack of objects to composite, and it doesn't
        // make sense to try to put a picture slice below the first platform
        // view slice, even if the picture doesn't overlap.
        flushSlices();
      }
    }
    pendingPictures.add(PictureDrawCommand(offset, picture));
    picturesRect = picturesRect?.expandToInclude(shiftedRect) ?? shiftedRect;
  }

  void addPlatformView(
    int viewId, {
    ui.Offset offset = ui.Offset.zero,
    double width = 0.0,
    double height = 0.0
  }) {
    final ui.Rect bounds = ui.Rect.fromLTWH(offset.dx, offset.dy, width, height);
    platformViewRect = platformViewRect?.expandToInclude(bounds) ?? bounds;
    pendingPlatformViews.add(PlatformView(viewId, bounds, platformViewStyling));
  }

  void mergeLayer(PictureEngineLayer layer) {
    // When we merge layers, we attempt to merge slices as much as possible as
    // well, based on ordering of pictures and platform views and reusing the
    // occlusion logic for determining where we can lower each picture.
    for (final LayerSlice slice in layer.slices) {
      switch (slice) {
        case PictureSlice():
          addPicture(ui.Offset.zero, slice.picture);
        case PlatformViewSlice():
          final ui.Rect? occlusionRect = slice.occlusionRect;
          if (occlusionRect != null) {
            platformViewRect = platformViewRect?.expandToInclude(occlusionRect) ?? occlusionRect;
          }
          for (final PlatformView view in slice.views) {
            // Merge the platform view styling of this layer with the nested
            // platform views.
            final PlatformViewStyling styling = PlatformViewStyling.combine(
              platformViewStyling,
              view.styling,
            );
            pendingPlatformViews.add(PlatformView(view.viewId, view.bounds, styling));
          }
      }
    }
  }

  PictureEngineLayer build() {
    // Lower any pending pictures or platform views to their respective slices.
    flushSlices();
    return layer;
  }
}
