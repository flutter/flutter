// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:ui/ui.dart' as ui;

import '../dom.dart';
import '../util.dart';
import 'canvas_provider.dart';
import 'rasterizer.dart';

/// A class which provides and manages [Surface] objects.
abstract class SurfaceProvider<C extends Surface, D extends CanvasProvider> {
  SurfaceProvider(this._canvasProvider, this._surfaceCreateFn);

  final D _canvasProvider;
  final C Function(D) _surfaceCreateFn;

  final List<C> _createdSurfaces = <C>[];

  C createSurface() {
    final C surface = _surfaceCreateFn(_canvasProvider);
    if (_resourceCacheMaxBytes != null) {
      surface.setSkiaResourceCacheMaxBytes(_resourceCacheMaxBytes!);
    }
    _createdSurfaces.add(surface);
    return surface;
  }

  void dispose() {
    for (final C surface in _createdSurfaces) {
      surface.dispose();
    }
    _createdSurfaces.clear();
  }

  int? _resourceCacheMaxBytes;

  void setSkiaResourceCacheMaxBytes(int bytes) {
    _resourceCacheMaxBytes = bytes;
    for (final C surface in _createdSurfaces) {
      surface.setSkiaResourceCacheMaxBytes(bytes);
    }
  }
}

/// A [SurfaceProvider] that creates [OffscreenSurface] objects.
class OffscreenSurfaceProvider extends SurfaceProvider<OffscreenSurface, OffscreenCanvasProvider> {
  OffscreenSurfaceProvider(super.canvasProvider, super.surfaceCreateFn);
}

/// A [SurfaceProvider] that creates [OnscreenSurface] objects.
class OnscreenSurfaceProvider extends SurfaceProvider<OnscreenSurface, OnscreenCanvasProvider> {
  OnscreenSurfaceProvider(super.canvasProvider, super.surfaceCreateFn);
}

/// The base interface for a rendering surface.
abstract class Surface {
  /// Sets the size of the underlying canvas.
  FutureOr<void> setSize(BitmapSize size);

  /// Converts a `ui.Image` into a `ByteData` object in the specified format.
  Future<ByteData?> rasterizeImage(ui.Image image, ui.ImageByteFormat format);

  /// Sets the maximum number of bytes for the GPU resource cache.
  void setSkiaResourceCacheMaxBytes(int bytes);

  /// Discards the old graphics context and creates a new one using the
  /// provided canvas object.
  ///
  /// This is called by the `SurfaceManager` in response to a
  /// `webglcontextlost` event.
  Future<void> recreateContextForCanvas(DomEventTarget newCanvas);

  /// Disposes of the surface and its resources.
  void dispose();

  /// A [Future] which completes when the [Surface] is initialized and ready to
  /// render pictures.
  Future<void> get initialized;

  /// The underlying canvas used to render the pixels.
  DomCanvasImageSource get canvasImageSource;

  /// Rasterizes the given [picture] to this canvas.
  Future<void> rasterizeToCanvas(ui.Picture picture);

  @visibleForTesting
  int get glContext;

  @visibleForTesting
  Future<void> triggerContextLoss();

  @visibleForTesting
  Future<void> get handledContextLossEvent;
}

/// A rendering surface that is optimized for producing `DomImageBitmap` objects.
///
/// This surface is not attached to the DOM and is used for off-screen rendering.
abstract class OffscreenSurface extends Surface {
  /// Rasterizes the given list of [pictures] into a list of `DomImageBitmap`
  /// objects.
  Future<List<DomImageBitmap>> rasterizeToImageBitmaps(List<ui.Picture> pictures);
}

/// A rendering surface that is also a `DisplayCanvas`.
///
/// This surface renders a picture directly to an on-screen canvas that is
/// part of the DOM.
abstract class OnscreenSurface extends Surface implements DisplayCanvas {}
