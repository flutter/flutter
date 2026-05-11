# Safari CanvasKit memory

Flutter Web uses CanvasKit to render Flutter pictures into one or more canvas
surfaces. Safari's WebGL and canvas memory can remain resident longer than in
Chromium-based browsers, so a CanvasKit app that is stable in Chrome can have a
much higher physical footprint in Safari.

The web engine applies Safari-specific CanvasKit defaults to reduce this
footprint:

* `canvasKitForceCpuOnly` defaults to `true` in Safari. An app can still opt out
  by setting `canvasKitForceCpuOnly` in `window.flutterConfiguration` or by
  compiling with `FLUTTER_WEB_CANVASKIT_FORCE_CPU_ONLY=false`.
* `canvasKitMaximumSurfaces` defaults to `2` in Safari. A single surface can
  merge Flutter overlays with platform-view underlays, which can make platform
  views such as Google Maps disappear behind Flutter content. Two surfaces keep
  the underlay and overlay paths separate while reducing retained canvas state.
* The Safari CanvasKit rasterizer caps Skia's resource cache so GPU-backed
  resources are not allowed to grow to the same size as other browsers.

When changing these defaults, validate both memory and platform-view
composition. A useful regression test is a release-mode CanvasKit app that
places Flutter content above a platform view, waits for Safari WebContent memory
to stabilize, and checks that the platform view remains visible while memory
stays below the expected limit.
