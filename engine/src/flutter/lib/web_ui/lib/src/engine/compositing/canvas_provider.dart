// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

/// Manages the lifecycle of raw canvas elements, abstracting away the differences
/// between onscreen and offscreen canvases.
///
/// This class is responsible for:
/// - Acquiring and releasing canvas elements.
/// - Resizing canvases.
/// - Attaching `webglcontextlost` event listeners and notifying the consumer.
abstract class CanvasProvider<C extends DomEventTarget> {
  final Map<C, DomEventListener> _eventListeners = <C, DomEventListener>{};

  /// Acquires a canvas element of a given `size`.
  ///
  /// The `onContextLost` callback will be invoked when the underlying rendering
  /// context for this canvas is lost.
  C acquireCanvas(BitmapSize size, {required ui.VoidCallback onContextLost}) {
    final C canvas = _createCanvas(size);
    final DomEventListener eventListener = createDomEventListener((DomEvent event) {
      onContextLost();
      // The canvas is no longer usable.
      releaseCanvas(canvas);
    });

    _eventListeners[canvas] = eventListener;
    canvas.addEventListener('webglcontextlost', eventListener);
    return canvas;
  }

  /// Resizes the `canvas` element to the new `size`.
  ///
  /// This method is responsible for updating the canvas element's dimensions
  /// and any associated properties (e.g., CSS styles for onscreen canvases).
  void resizeCanvas(C canvas, BitmapSize size);

  /// Releases a `canvas` element, allowing it to be pooled or disposed of.
  void releaseCanvas(C canvas) {
    final DomEventListener? listener = _eventListeners.remove(canvas);
    if (listener != null) {
      canvas.removeEventListener('webglcontextlost', listener);
    }
    detachCanvas(canvas);
  }

  /// Disposes of all canvases managed by this provider.
  void dispose() {
    List<C>.from(_eventListeners.keys).forEach(releaseCanvas);
    assert(_eventListeners.isEmpty);
  }

  /// Creates a canvas element.
  C _createCanvas(BitmapSize size);

  /// Detaches a canvas element from the DOM if necessary.
  void detachCanvas(C canvas);
}

/// A [CanvasProvider] that manages a pool of [dom.DomOffscreenCanvas] elements.
class OffscreenCanvasProvider extends CanvasProvider<DomOffscreenCanvas> {
  @override
  DomOffscreenCanvas _createCanvas(BitmapSize size) {
    return DomOffscreenCanvas(size.width, size.height);
  }

  @override
  void detachCanvas(DomOffscreenCanvas canvas) {
    // Nothing to do for offscreen canvases.
  }

  @override
  void resizeCanvas(DomOffscreenCanvas canvas, BitmapSize size) {
    canvas.width = size.width.toDouble();
    canvas.height = size.height.toDouble();
  }
}

/// A [CanvasProvider] that manages [dom.DomHTMLCanvasElement] elements.
class OnscreenCanvasProvider extends CanvasProvider<DomHTMLCanvasElement> {
  @override
  DomHTMLCanvasElement _createCanvas(BitmapSize size) {
    final DomHTMLCanvasElement canvas = createDomCanvasElement();
    resizeCanvas(canvas, size);
    return canvas;
  }

  @override
  void detachCanvas(DomHTMLCanvasElement canvas) {
    canvas.remove();
  }

  @override
  void resizeCanvas(DomHTMLCanvasElement canvas, BitmapSize size) {
    canvas.width = size.width.toDouble();
    canvas.height = size.height.toDouble();

    // When using an onscreen canvas, we also need to update the CSS size to
    // account for the device pixel ratio.
    final double ratio = EngineFlutterDisplay.instance.devicePixelRatio;
    final cssWidth = '${size.width / ratio}px';
    final cssHeight = '${size.height / ratio}px';
    canvas.style
      ..width = cssWidth
      ..height = cssHeight;
  }
}
