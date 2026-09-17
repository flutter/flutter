# HTML-in-Canvas Compositing Demo

An interactive showcase application demonstrating the next-generation Flutter Web **Single Surface Rasterizer** and Blink **HTML-in-Canvas (`texElementSubImage2D`)** compositing architecture.

## Overview

Previously, Flutter Web's CanvasKit renderer used a complex `MultiSurfaceRasterizer` and `PlatformViewEmbedder`. Every platform view split the canvas tree into multiple DOM layers (`<flt-canvas-container>`, `<flt-platform-view-slot>`, overlays), requiring manual occlusion culling, clipping overlays, and DOM reordering.

With the **SingleSurfaceRasterizer** and Blink's `CanvasDrawElement` (`texElementSubImage2D`) feature:
1. **Single Surface**: Only one `<canvas content="drawable">` is ever created.
2. **Direct WebGL Ingestion**: HTML elements are slotted as drawable children inside `<canvas>` and uploaded directly into WebGL textures via `gl.texElementSubImage2D(gl.TEXTURE_2D, 0, 0, 0, element)`.
3. **Hardware Skia Compositing**: Textures are wrapped in `SkImage` handles using CanvasKit's `makeImageFromTexture` and drawn directly into the Skia render pipeline with native clipping, transforms, opacity, and image filters (such as `BackdropFilter`).
4. **Hit-Testing & Input**: Blink's `updateElementGeometry(element, {canvasTransform})` passes the DPR-unscaled transformation matrix to Blink, allowing native input focus, text selection, and mouse events to work seamlessly without synthetic event forwarding.

---

## Showcase Scenes

The demo application includes three interactive scenes:

### 1. BackdropFilter Blur over Live HTML
- An interactive HTML platform view containing an editable text `<input>` and styled cards.
- A floating Flutter Skia frosted-glass overlay with `BackdropFilter` (Gaussian blur $\sigma = 20$) sweeps smoothly across the HTML element.
- Demonstrates true hardware filtering over live DOM elements that was impossible with multi-surface DOM slicing.

### 2. Multi-Layer Interleaving (Canvas - HTML - Canvas - HTML - Canvas)
- Five alternating layers rendered in a single frame:
  1. Base Flutter canvas background (animated radial gradient grid).
  2. HTML platform view #1 (video/animation card with glowing border).
  3. Intermediate Flutter vector graphics (orbiting glowing particle ring).
  4. HTML platform view #2 (interactive form / statistics card).
  5. Top Flutter foreground (hud telemetry, custom cursor, and control badges).
- Demonstrates zero DOM layering: all five layers composite cleanly into a single WebGL surface.

### 3. Cross-Origin Security (CORS Isolation)
- Tests loading cross-origin content into the HTML-in-Canvas pipeline.
- Demonstrates graceful fallback when cross-origin taints occur (WebGL texture error handling), protecting canvas readback integrity while maintaining render stability.

---

## Running the Demo

### Step 1: Build the Demo

From `engine/src/flutter/lib/web_ui`:

```bash
# Compile main.dart to JavaScript using the Flutter prebuilt Dart SDK
../../prebuilts/linux-x64/dart-sdk/bin/dart compile js -o dev/html_in_canvas_demo/main.dart.js dev/html_in_canvas_demo/main.dart
```

### Step 2: Ensure CanvasKit Prebuilts are Available

Symlink the local CanvasKit build:

```bash
ln -s ../../../../out/wasm_release/canvaskit dev/html_in_canvas_demo/canvaskit
```

*(Alternatively, pass `?canvaskit=https://unpkg.com/canvaskit-wasm@0.39.1/bin/` in the URL)*.

### Step 3: Launch Local Web Server

```bash
python3 -m http.server 8080 --directory dev/html_in_canvas_demo
```

### Step 4: Launch Chrome with Blink Feature Flag

The `CanvasDrawElement` feature requires Chrome 124+ with the experimental feature enabled:

```bash
google-chrome --enable-blink-features=CanvasDrawElement http://localhost:8080
```

---

## Keyboard Controls

- Press **`1`**: Switch to Scene 1 (BackdropFilter over HTML).
- Press **`2`**: Switch to Scene 2 (3-Layer Interleaving).
- Press **`3`**: Switch to Scene 3 (Cross-Origin Security).
- Use the on-screen navigation buttons or tab header to change scenes.
