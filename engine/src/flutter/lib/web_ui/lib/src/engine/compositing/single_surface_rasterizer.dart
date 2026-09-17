// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

/// A [Rasterizer] that uses a single on-screen canvas surface to do
/// all the rendering with HTML-in-Canvas compositing.
class SingleSurfaceRasterizer extends Rasterizer {
  SingleSurfaceRasterizer(OnscreenSurface Function(OnscreenCanvasProvider) surfaceCreateFn)
    : _surfaceProvider = OnscreenSurfaceProvider(OnscreenCanvasProvider(), surfaceCreateFn);

  SingleSurfaceRasterizer.offscreen(
    OffscreenSurface Function(OffscreenCanvasProvider) surfaceCreateFn,
  ) : _surfaceProvider = OffscreenSurfaceProvider(OffscreenCanvasProvider(), surfaceCreateFn);

  final SurfaceProvider _surfaceProvider;

  @override
  @visibleForTesting
  SurfaceProvider get surfaceProvider => _surfaceProvider;

  Surface get offscreenSurface => _surfaceProvider.createSurface();

  @override
  SingleSurfaceViewRasterizer createViewRasterizer(EngineFlutterView view) {
    return _viewRasterizers.putIfAbsent(
      view,
      () => SingleSurfaceViewRasterizer(
        view,
        this,
        _surfaceProvider.createSurface() as CkOnscreenSurface,
      ),
    );
  }

  final Map<EngineFlutterView, SingleSurfaceViewRasterizer> _viewRasterizers =
      <EngineFlutterView, SingleSurfaceViewRasterizer>{};

  void debugClear() {
    _viewRasterizers.clear();
  }

  @override
  void setResourceCacheMaxBytes(int bytes) {
    _surfaceProvider.setSkiaResourceCacheMaxBytes(bytes);
  }

  @override
  void dispose() {
    _surfaceProvider.dispose();
    for (final SingleSurfaceViewRasterizer viewRasterizer in _viewRasterizers.values) {
      viewRasterizer.dispose();
    }
    _viewRasterizers.clear();
  }

  @override
  Surface createPictureToImageSurface() {
    return _surfaceProvider.createSurface();
  }
}

class SingleSurfaceViewRasterizer extends ViewRasterizer {
  SingleSurfaceViewRasterizer(super.view, this.rasterizer, this.surface) {
    sceneElement.appendChild(surface.hostElement);
    _setupRepaintListeners();
  }

  final SingleSurfaceRasterizer rasterizer;
  final CkOnscreenSurface surface;
  Set<int> _activeViewIds = <int>{};
  bool _isDisposed = false;
  DomEventListener? _repaintListener;

  void _setupRepaintListeners() {
    final htmlCanvas = surface.canvas as DomHTMLCanvasElement;
    final DomEventListener listener = createDomEventListener((DomEvent event) {
      if (!_isDisposed) {
        EnginePlatformDispatcher.instance.scheduleFrame();
      }
    });
    _repaintListener = listener;
    htmlCanvas.addEventListener('paint', listener);
    htmlCanvas.addEventListener('input', listener);
    htmlCanvas.addEventListener('change', listener);
  }

  void _removeRepaintListeners() {
    final DomEventListener? listener = _repaintListener;
    if (listener != null) {
      final htmlCanvas = surface.canvas as DomHTMLCanvasElement;
      htmlCanvas.removeEventListener('paint', listener);
      htmlCanvas.removeEventListener('input', listener);
      htmlCanvas.removeEventListener('change', listener);
      _repaintListener = null;
    }
  }

  @override
  Future<void> prepareToDraw() async {
    surface.setSize(currentFrameSize);
  }

  @override
  Future<void> draw(LayerTree layerTree, FrameTimingRecorder? recorder) async {
    final ui.Size frameSize = view.physicalSize;
    if (frameSize.isEmpty) {
      recorder?.recordBuildFinish();
      recorder?.recordRasterStart();
      recorder?.recordRasterFinish();
      return;
    }
    currentFrameSize = BitmapSize.fromSize(frameSize);
    surface.setSize(currentFrameSize);

    final Frame compositorFrame = context.acquireFrame();
    recorder?.recordBuildFinish();
    recorder?.recordRasterStart();

    layerTree.preroll(compositorFrame);

    final SkSurface skSurface = surface.skSurface!;
    final canvas = CkCanvas.fromSkCanvas(skSurface.getCanvas());
    canvas.clear(const ui.Color(0x00000000));

    final paintVisitor = PaintVisitor(canvas, surface);
    if (layerTree.rootLayer.needsPainting) {
      layerTree.rootLayer.accept(paintVisitor);
    }
    skSurface.flush();
    paintVisitor.disposeTransientImages();

    final Set<int> unmountedViews = _activeViewIds.difference(paintVisitor.renderedViewIds);
    for (final viewId in unmountedViews) {
      final DomElement? element = PlatformViewManager.instance.getSlottedContent(viewId);
      if (element != null) {
        try {
          (surface.canvas as DomHTMLCanvasElement).clearElementGeometry(element);
        } catch (_) {
          // Guard for environments where CanvasDrawElement is not enabled.
        }
        element.remove();
      }
      surface.textureCache.disposeView(viewId);
    }
    _activeViewIds = paintVisitor.renderedViewIds;

    recorder?.recordRasterFinish();
  }

  @override
  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _removeRepaintListeners();
    rasterizer._viewRasterizers.remove(view);
    surface.dispose();
    super.dispose();
  }
}
