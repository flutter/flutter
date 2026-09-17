# Implementation Plan: HTML-in-Canvas Prototype for Flutter Web (Hackathon PoC)

## 1. Executive Summary & Problem Statement

Currently, Flutter Web uses a hybrid DOM/Canvas composition model to interleave Platform Views (arbitrary HTML elements such as `<video>`, `<input>`, `<iframe>`) with Flutter vector drawings:
- When platform views intersect or interleave with Flutter drawings, Flutter Engine splits rendering into multiple `<canvas>` elements (up to 8 on-screen WebGL/2D canvases).
- The Engine maintains a heavy, complex pipeline:
  - `MeasureVisitor`: Computes spatial 2D bounding boxes of all pictures and platform views.
  - `OcclusionMap` (`occlusion_map.dart`): Calculates non-overlapping canvas layers using spatial 2D interval trees.
  - `PlatformViewEmbedder` (`embedder.dart`): An 880+ line subsystem that reconstructs CSS mutator trees (nested `<div>`s with CSS `clip-path` SVG strings, transforms, and opacities) and executes Longest Increasing Subsequence (LIS) DOM reconciliation every frame.
  - Canvas overlays (`multi_surface_rasterizer.dart`, `offscreen_canvas_rasterizer.dart`): Multiple live WebGL contexts or expensive `createImageBitmap` offscreen transfers that waste GPU memory and cause context loss bugs.
  - Inability to use Skia shaders, blurs, and `BackdropFilter` over HTML elements because DOM elements live outside Skia's render target.

The **WICG HTML-in-Canvas** specification (`chrome://flags/#canvas-draw-element`, [WICG/html-in-canvas](https://github.com/WICG/html-in-canvas)) introduces `<canvas content="drawable">` and `<element drawable>`, allowing HTML DOM elements to be drawn directly into WebGL/2D canvas contexts while delegating layout, styling, and hit-testing back to the browser engine via `updateElementGeometry()`.

### The Hackathon PoC Goal
Replace Flutter Web's multi-surface compositing engine with a single-surface CanvasKit rasterizer assuming HTML-in-Canvas works natively.
1. **The Upside**: Delete ~1,500+ lines of complex engine code (`PlatformViewEmbedder`, `OcclusionMap`, `MeasureVisitor`, multi-surface rasterizers) and enable advanced Skia graphical effects (`BackdropFilter`) over live HTML elements.
2. **The Downside**: Demonstrate the security limitation of Read-Back-Allowed Rendering (cross-origin `<iframe>`s such as Google Maps fail or render blank due to pixel extraction restrictions).

---

## 2. Technical Architecture & Design Decisions

```
+-------------------------------------------------------------------------------+
|                             Flutter Framework                                 |
|      (Widget Tree -> RenderObjects -> LayerTree: Pictures & PlatformViews)    |
+---------------------------------------+---------------------------------------+
                                        |
                                        v
+-------------------------------------------------------------------------------+
|                       Flutter Web Engine (CanvasKit)                          |
|                                                                               |
|  [OLD PIPELINE (DELETED)]:                                                    |
|    - Preroll -> MeasureVisitor -> OcclusionMap -> OptimizeComposition        |
|    - PlatformViewEmbedder -> LIS Diffing -> CSS Clip Chains -> Multi-Canvases |
|                                                                               |
|  [NEW PIPELINE (SINGLE SURFACE)]:                                             |
|    1. PrerollVisitor (Records bounds)                                         |
|    2. PaintVisitor (Direct to SkCanvas):                                      |
|       - PictureLayer: skCanvas.drawPicture()                                  |
|       - PlatformViewLayer:                                                    |
|           a. Ensure <flt-platform-view drawable> inside <canvas content="drawable"> |
|           b. Texture upload via gl.texElementSubImage2D                       |
|           c. Wrap in SkImage via skSurface.makeImageFromTexture               |
|           d. skCanvas.drawImageRect(...)                                      |
|           e. canvas.updateElementGeometry(element, { canvasTransform })       |
|       - BackdropFilterLayer:                                                  |
|           * skCanvas.saveLayer() with SkImageFilter (Blurs both Flutter vector |
|             drawings AND underlying HTML platform view elements in 1 pass!)   |
+---------------------------------------+---------------------------------------+
                                        |
                                        v
+-------------------------------------------------------------------------------+
|                             Browser DOM & GPU                                 |
|                                                                               |
|   <flt-glass-pane>                                                            |
|     <canvas id="flutter-view-0" content="drawable" tabindex="0">              |
|       <flt-platform-view drawable id="flt-pv-1">                              |
|         <input ... /> or <video ... />                                        |
|       </flt-platform-view>                                                    |
|     </canvas>                                                                 |
|   </flt-glass-pane>                                                           |
+-------------------------------------------------------------------------------+
```

### Architectural Decisions & Resolution of Technical Requirements:
1. **Renderer Backend**: **CanvasKit on the main thread** (`--web-renderer canvaskit`).
2. **Direct WebGL Texture Binding (Option B)**:
   - Use raw WebGL `gl.texElementSubImage2D` to upload the element into a pre-allocated `WebGLTexture`.
   - Wrap the texture via CanvasKit's built-in `skSurface.makeImageFromTexture(glTexture, imageInfo)`. CanvasKit's internal implementation of `makeImageFromTexture` invokes `this._resetContext()`, ensuring Skia's `GrContext` WebGL state cache remains synchronized.
   - Expose `makeImageFromTexture` on `SkSurface` in `canvaskit_api.dart`.
   - Maintain a `PlatformViewTextureCache` to reuse `WebGLTexture` and dispose old `SkImage` handles with `skImage.delete()`, avoiding WASM heap memory leaks.
3. **Integration Strategy**: **Full in-place replacement and deletion** to produce a clean, dramatic `git diff --stat` for the hackathon presentation.
4. **WICG Spec Compliance**:
   - The canvas element must have the `content="drawable"` attribute (`canvas.setAttribute('content', 'drawable')`).
   - Platform views have `drawable`: `element.setAttribute('drawable', '')`.
   - `updateElementGeometry(element, { canvasTransform: domMatrix })` expects canvas CSS coordinate space. Because CanvasKit pre-scales the root matrix by `devicePixelRatio` (`dpr`), we un-scale the CTM by `1 / dpr` to ensure hit-testing alignment.
5. **Frame Scheduling**:
   - Driven by Flutter's `PlatformDispatcher.instance.scheduleFrame()`.
   - A debounced listener on `canvas.addEventListener('paint', ...)` requests a Flutter frame when internal DOM elements invalidate, avoiding infinite busy-loops when idle.
   - Frame 0 guard: Newly mounted elements may not have an initial visual snapshot in Blink; `visitPlatformView` catches initial snapshot exceptions and renders a placeholder until frame 1.
6. **Active View Lifecycle**:
   - Unmounted platform views are tracked; when a view is omitted from a frame, the engine invokes `canvas.clearElementGeometry(element)` and removes the DOM node.

---

## 3. Alternatives Considered & Ruled Out

| Alternative | Rationale for Rejection |
| :--- | :--- |
| **Skwasm (Web Worker) Implementation** | Transferring DOM elements or `ElementImage` handles across Web Worker thread boundaries via `postMessage` or C++ WebIDL bindings requires complex browser support and offscreen-canvas plumbing that would jeopardize the hackathon timeline. |
| **Dual-Pipeline / Feature Flag (`--enable-html-in-canvas`)** | Retaining the old `PlatformViewEmbedder` code behind runtime checks obfuscates the core narrative of the hackathon: showing coworkers exactly how much complexity and code can be permanently deleted. |
| **Intermediate 2D Canvas / ImageBitmap Blit (Option A)** | Bypassing direct WebGL texture uploads through an offscreen 2D canvas introduces an extra memory copy per frame, whereas CanvasKit already contains the `skSurface.makeImageFromTexture` binding. |
| **Browser-driven Scheduling (Option B - `canvas.onpaint` driving everything)** | Re-inverting Flutter's execution model so that the browser's `onpaint` hook dictates the entire widget tree build phase would cause regressions in Flutter's microtask and animation scheduler. |

---

## 4. Irrefutable Evidence Plan

As agreed during the Grill session, the prototype's success will be irrefutably demonstrated through:

1. **The Interactive Showcase App (`engine/src/flutter/lib/web_ui/dev/html_in_canvas_demo/`)**:
   - **Scene 1 (The Holy Grail: Backdrop Filter over HTML)**:
     A live HTML element (e.g., an animated HTML `<video>`, input element, or rich HTML text) positioned underneath a draggable Flutter modal dialog with `BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10))`. Demonstrates live, real-time GPU blur over HTML content rendered in a single canvas.
   - **Scene 2 (Single-Canvas Interleaving & Interaction)**:
     - Layer 0: Flutter vector drawing (background gradient/shapes).
     - Layer 1: HTML Platform View (interactive HTML button / text field).
     - Layer 2: Flutter vector drawing (floating action button / overlapping animated shapes).
     - Verification: Inspect DOM in Chrome DevTools to prove **strictly 1 `<canvas>` exists** and that clicks/typing into the HTML input work through `canvas.updateElementGeometry`.
   - **Scene 3 (The Security Downside Demo)**:
     Embed a cross-origin `<iframe>` (Google Maps or Wikipedia). Demonstrate that Chromium's Read-Back-Allowed Rendering blocks pixel extraction, causing the iframe to render blank or throw a security exception, illustrating the fundamental architectural trade-off.

2. **The Codebase Simplification (`git diff --stat`)**:
   - A draft Pull Request / diff showing **over 1,500 lines of complex engine code deleted** across `PlatformViewEmbedder`, `OcclusionMap`, `MeasureVisitor`, and multi-surface canvas pools.

---

## 5. Detailed Component & File Changes

### A. Files to Delete

1. `engine/src/flutter/lib/web_ui/lib/src/engine/compositing/composition.dart` (~265 lines):
   - Delete `createOptimizedComposition`, `Composition`, `CompositionCanvas`.
2. `engine/src/flutter/lib/web_ui/lib/src/engine/occlusion_map.dart` (~150 lines):
   - Delete `OcclusionMap` and spatial interval trees.
3. `engine/src/flutter/lib/web_ui/lib/src/engine/platform_views/embedder.dart` (~884 lines):
   - Delete `PlatformViewEmbedder`, mutator stack generation, CSS `clip-path` SVG string generation, and LIS diffing.
4. `engine/src/flutter/lib/web_ui/lib/src/engine/compositing/multi_surface_rasterizer.dart` (~96 lines):
   - Delete multi-canvas on-screen WebGL overlay rasterizer.
5. `engine/src/flutter/lib/web_ui/lib/src/engine/compositing/offscreen_canvas_rasterizer.dart` (~101 lines):
   - Delete offscreen multi-surface bitmap transfer rasterizer.

### B. Files to Modify

#### 1. `engine/src/flutter/lib/web_ui/lib/src/engine.dart` (Central Exports)
- Remove export directives for deleted files: `composition.dart`, `embedder.dart`, `occlusion_map.dart`, `multi_surface_rasterizer.dart`, `offscreen_canvas_rasterizer.dart`.
- Export new `single_surface_rasterizer.dart`.

#### 2. `engine/src/flutter/lib/web_ui/lib/src/engine/dom.dart` (JS Interop Bindings)
- Add Blink HTML-in-Canvas extension methods:
  ```dart
  extension DomHTMLCanvasElementDrawElementExtension on DomHTMLCanvasElement {
    @JS('updateElementGeometry')
    external void updateElementGeometry(DomElement element, JSAny? options);

    @JS('clearElementGeometry')
    external void clearElementGeometry(DomElement element);
  }

  extension WebGLRenderingContextDrawElementExtension on WebGLContext {
    @JS('texElementSubImage2D')
    external void texElementSubImage2D(
      int target,
      int level,
      int xoffset,
      int yoffset,
      DomElement element,
    );
  }
  ```

#### 3. `engine/src/flutter/lib/web_ui/lib/src/engine/canvaskit/canvaskit_api.dart`
- Expose `makeImageFromTexture` on `SkSurface`:
  ```dart
  @JS('window.flutterCanvasKit.Surface')
  extension type SkSurface(JSObject _) implements JSObject {
    ...
    @JS('makeImageFromTexture')
    external SkImage? makeImageFromTexture(WebGLTexture texture, SkPartialImageInfo info);
  }
  ```

#### 4. `engine/src/flutter/lib/web_ui/lib/src/engine/canvaskit/surface.dart`
- In `CkOnscreenSurface`:
  - When acquiring canvas: `canvas.setAttribute('content', 'drawable')` and `canvas.setAttribute('tabindex', '0')`.
  - Expose `WebGLContext get glContextObject => (canvas as DomHTMLCanvasElement).getGlContext(webGLVersion);`.
  - Wire debounced `canvas.addEventListener('paint', ...)` to `PlatformDispatcher.instance.scheduleFrame()`.
  - Maintain `PlatformViewTextureCache` to manage WebGL textures and `SkImage` lifecycles.

#### 5. `engine/src/flutter/lib/web_ui/lib/src/engine/compositing/single_surface_rasterizer.dart` (New File)
- Implement `SingleSurfaceRasterizer` and `SingleSurfaceViewRasterizer`:
  ```dart
  class SingleSurfaceRasterizer extends Rasterizer {
    SingleSurfaceRasterizer(this._surfaceCreateFn)
      : _surfaceProvider = OnscreenSurfaceProvider(OnscreenCanvasProvider(), _surfaceCreateFn);

    final OnscreenSurface Function(OnscreenCanvasProvider) _surfaceCreateFn;
    final OnscreenSurfaceProvider _surfaceProvider;

    @override
    SingleSurfaceViewRasterizer createViewRasterizer(EngineFlutterView view) {
      return SingleSurfaceViewRasterizer(view, this, _surfaceProvider.createSurface());
    }
    ...
  }

  class SingleSurfaceViewRasterizer extends ViewRasterizer {
    SingleSurfaceViewRasterizer(super.view, this.rasterizer, this.surface);
    final SingleSurfaceRasterizer rasterizer;
    final CkOnscreenSurface surface;

    @override
    Future<void> draw(LayerTree layerTree, FrameTimingRecorder? recorder) async {
      final ui.Size frameSize = view.physicalSize;
      if (frameSize.isEmpty) return;
      currentFrameSize = BitmapSize.fromSize(frameSize);
      surface.setSize(currentFrameSize);

      final Frame compositorFrame = context.acquireFrame(null);
      recorder?.recordBuildFinish();
      recorder?.recordRasterStart();

      final SkSurface skSurface = surface.skSurface!;
      final CkCanvas canvas = CkCanvas.fromSkCanvas(skSurface.getCanvas());
      canvas.clear(const ui.Color(0x00000000));

      layerTree.paint(canvas, surface);
      skSurface.flush();

      recorder?.recordRasterFinish();
    }
  }
  ```

#### 6. `engine/src/flutter/lib/web_ui/lib/src/engine/layer/layer_tree.dart`
- In `Frame`:
  - Remove `layerTree.measure(this, size)` and `viewEmbedder?.optimizeComposition()`.
  - `Frame.raster` only executes `layerTree.preroll` and `layerTree.paint`.
- In `LayerTree`:
  - Update `paint(CkCanvas canvas, CkOnscreenSurface surface)` to directly traverse the tree using `PaintVisitor`.

#### 7. `engine/src/flutter/lib/web_ui/lib/src/engine/layer/layer_visitor.dart`
- Remove `MeasureVisitor` completely.
- In `PrerollVisitor`:
  - Remove `PlatformViewEmbedder` dependency. Simply record bounding boxes.
- In `PaintVisitor`:
  - Receives `final CkCanvas canvas;` and `final CkOnscreenSurface surface;`.
  - In `visitPlatformView(PlatformViewLayer layer)`:
    ```dart
    final DomElement? element = PlatformViewManager.instance.getSlottedContent(layer.viewId);
    if (element == null) return;

    // 1. Ensure element is marked drawable and mounted inside the <canvas content="drawable">
    element.setAttribute('drawable', '');
    if (element.parent != surface.canvas) {
      (surface.canvas as DomElement).append(element);
    }

    // 2. Upload to WebGL texture
    final WebGLTexture glTexture = surface.textureCache.getOrCreateTexture(layer.viewId);
    final WebGLContext gl = surface.glContextObject;
    gl.bindTexture(gl.TEXTURE_2D, glTexture);
    try {
      gl.texElementSubImage2D(gl.TEXTURE_2D, 0, 0, 0, element);
    } catch (e) {
      // Frame 0 guard: Blink snapshot may not be ready yet
      return;
    }

    // 3. Wrap in SkImage via CanvasKit
    final SkImage? skImage = surface.skSurface!.makeImageFromTexture(
      glTexture,
      SkPartialImageInfo(
        width: layer.size.width,
        height: layer.size.height,
        alphaType: canvasKit.AlphaType.Premul,
        colorType: canvasKit.ColorType.RGBA_8888,
        colorSpace: SkColorSpaceSRGB,
      ),
    );
    if (skImage != null) {
      canvas.drawImageRect(
        CkImageDelegate(skImage),
        ui.Rect.fromLTWH(0, 0, layer.size.width, layer.size.height),
        ui.Rect.fromLTWH(layer.offset.dx, layer.offset.dy, layer.size.width, layer.size.height),
        CkPaint(),
      );
      skImage.delete(); // Free C++ WASM handle after draw call
    }

    // 4. Update element geometry with DPR-unscaled matrix
    final double dpr = EngineFlutterDisplay.instance.devicePixelRatio;
    final Matrix4 currentMatrix = canvas.getLocalToDevice();
    final Matrix4 cssMatrix = Matrix4.diagonal3Values(1 / dpr, 1 / dpr, 1.0) * currentMatrix;
    final DOMMatrix domMatrix = DOMMatrix(cssMatrix.storage.toJS);
    (surface.canvas as DomHTMLCanvasElement).updateElementGeometry(
      element,
      JSObject(canvasTransform: domMatrix),
    );
    ```

#### 8. `engine/src/flutter/lib/web_ui/lib/src/engine/view_embedder/style_manager.dart`
- In `styleSceneHost`:
  - Remove `sceneHost.style.pointerEvents = 'none';`.

#### 9. `engine/src/flutter/lib/web_ui/lib/src/engine/canvaskit/renderer.dart`
- In `_createRasterizer()`:
  - Return `SingleSurfaceRasterizer((OnscreenCanvasProvider p) => CkOnscreenSurface(p))`.

---

## 6. Execution Steps & Verification Plan

1. **Phase 2 Complete**: Master doc audited and approved.
2. **Phase 3 (Implementation in Fresh Context via `my-workflow-execute`)**:
   - Step 1: Add CanvasKit `makeImageFromTexture` Dart binding and Blink JS interop bindings in `dom.dart` and `canvaskit_api.dart`.
   - Step 2: Delete `composition.dart`, `occlusion_map.dart`, `embedder.dart`, `multi_surface_rasterizer.dart`, and `offscreen_canvas_rasterizer.dart`.
   - Step 3: Implement `SingleSurfaceRasterizer` and update `LayerTree` and `PaintVisitor`.
   - Step 4: Implement the interactive demo app in `engine/src/flutter/lib/web_ui/dev/html_in_canvas_demo/`.
3. **Phase 4 (Evidence Gathering & Presentation)**:
   - Launch demo app in Chrome with `--enable-blink-features=CanvasDrawElement`.
   - Record `git diff --stat` demonstrating net ~1,500+ lines of code deleted.
