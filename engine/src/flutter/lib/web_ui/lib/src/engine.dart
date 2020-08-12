// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.10
@JS()
library engine;

import 'dart:async';
import 'dart:collection'
    show ListBase, IterableBase, DoubleLinkedQueue, DoubleLinkedQueueEntry;
import 'dart:convert' hide Codec;
import 'dart:developer' as developer;
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:js_util' as js_util;
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:js/js.dart';
import 'package:meta/meta.dart';

import '../ui.dart' as ui;

part 'engine/alarm_clock.dart';
part 'engine/assets.dart';
part 'engine/bitmap_canvas.dart';
part 'engine/browser_detection.dart';
part 'engine/browser_location.dart';
part 'engine/canvas_pool.dart';
part 'engine/clipboard.dart';
part 'engine/color_filter.dart';
part 'engine/compositor/canvas.dart';
part 'engine/compositor/canvas_kit_canvas.dart';
part 'engine/compositor/canvaskit_api.dart';
part 'engine/compositor/color_filter.dart';
part 'engine/compositor/embedded_views.dart';
part 'engine/compositor/fonts.dart';
part 'engine/compositor/image.dart';
part 'engine/compositor/image_filter.dart';
part 'engine/compositor/initialization.dart';
part 'engine/compositor/layer.dart';
part 'engine/compositor/layer_scene_builder.dart';
part 'engine/compositor/layer_tree.dart';
part 'engine/compositor/mask_filter.dart';
part 'engine/compositor/n_way_canvas.dart';
part 'engine/compositor/path.dart';
part 'engine/compositor/painting.dart';
part 'engine/compositor/path_metrics.dart';
part 'engine/compositor/picture.dart';
part 'engine/compositor/picture_recorder.dart';
part 'engine/compositor/platform_message.dart';
part 'engine/compositor/raster_cache.dart';
part 'engine/compositor/rasterizer.dart';
part 'engine/compositor/shader.dart';
part 'engine/compositor/skia_object_cache.dart';
part 'engine/compositor/surface.dart';
part 'engine/compositor/text.dart';
part 'engine/compositor/util.dart';
part 'engine/compositor/vertices.dart';
part 'engine/compositor/viewport_metrics.dart';
part 'engine/dom_canvas.dart';
part 'engine/dom_renderer.dart';
part 'engine/engine_canvas.dart';
part 'engine/frame_reference.dart';
part 'engine/history.dart';
part 'engine/html_image_codec.dart';
part 'engine/keyboard.dart';
part 'engine/mouse_cursor.dart';
part 'engine/onscreen_logging.dart';
part 'engine/picture.dart';
part 'engine/platform_views.dart';
part 'engine/plugins.dart';
part 'engine/pointer_binding.dart';
part 'engine/pointer_converter.dart';
part 'engine/profiler.dart';
part 'engine/rrect_renderer.dart';
part 'engine/semantics/accessibility.dart';
part 'engine/semantics/checkable.dart';
part 'engine/semantics/image.dart';
part 'engine/semantics/incrementable.dart';
part 'engine/semantics/label_and_value.dart';
part 'engine/semantics/live_region.dart';
part 'engine/semantics/scrollable.dart';
part 'engine/semantics/semantics.dart';
part 'engine/semantics/semantics_helper.dart';
part 'engine/semantics/tappable.dart';
part 'engine/semantics/text_field.dart';
part 'engine/services/buffers.dart';
part 'engine/services/message_codec.dart';
part 'engine/services/message_codecs.dart';
part 'engine/services/serialization.dart';
part 'engine/shadow.dart';
part 'engine/surface/backdrop_filter.dart';
part 'engine/surface/canvas.dart';
part 'engine/surface/clip.dart';
part 'engine/surface/debug_canvas_reuse_overlay.dart';
part 'engine/surface/image_filter.dart';
part 'engine/surface/offset.dart';
part 'engine/surface/opacity.dart';
part 'engine/surface/painting.dart';
part 'engine/surface/path/conic.dart';
part 'engine/surface/path/cubic.dart';
part 'engine/surface/path/path.dart';
part 'engine/surface/path/path_metrics.dart';
part 'engine/surface/path/path_ref.dart';
part 'engine/surface/path/path_to_svg.dart';
part 'engine/surface/path/path_utils.dart';
part 'engine/surface/path/path_windings.dart';
part 'engine/surface/path/tangent.dart';
part 'engine/surface/picture.dart';
part 'engine/surface/platform_view.dart';
part 'engine/surface/recording_canvas.dart';
part 'engine/surface/render_vertices.dart';
part 'engine/surface/scene.dart';
part 'engine/surface/scene_builder.dart';
part 'engine/surface/shader.dart';
part 'engine/surface/surface.dart';
part 'engine/surface/surface_stats.dart';
part 'engine/surface/transform.dart';
part 'engine/test_embedding.dart';
part 'engine/text/font_collection.dart';
part 'engine/text/line_break_properties.dart';
part 'engine/text/line_breaker.dart';
part 'engine/text/measurement.dart';
part 'engine/text/paragraph.dart';
part 'engine/text/ruler.dart';
part 'engine/text/unicode_range.dart';
part 'engine/text/word_break_properties.dart';
part 'engine/text/word_breaker.dart';
part 'engine/text_editing/autofill_hint.dart';
part 'engine/text_editing/input_type.dart';
part 'engine/text_editing/text_capitalization.dart';
part 'engine/text_editing/text_editing.dart';
part 'engine/ulps.dart';
part 'engine/util.dart';
part 'engine/validators.dart';
part 'engine/vector_math.dart';
part 'engine/web_experiments.dart';
part 'engine/window.dart';

/// A benchmark metric that includes frame-related computations prior to
/// submitting layer and picture operations to the underlying renderer, such as
/// HTML and CanvasKit. During this phase we compute transforms, clips, and
/// other information needed for rendering.
const String kProfilePrerollFrame = 'preroll_frame';

/// A benchmark metric that includes submitting layer and picture information
/// to the renderer.
const String kProfileApplyFrame = 'apply_frame';

bool _engineInitialized = false;

final List<ui.VoidCallback> _hotRestartListeners = <ui.VoidCallback>[];

/// Requests that [listener] is called just before hot restarting the app.
void registerHotRestartListener(ui.VoidCallback listener) {
  _hotRestartListeners.add(listener);
}

/// This method performs one-time initialization of the Web environment that
/// supports the Flutter framework.
///
/// This is only available on the Web, as native Flutter configures the
/// environment in the native embedder.
// TODO(yjbanov): we should refactor the code such that the framework does not
//                call this method directly.
void initializeEngine() {
  if (_engineInitialized) {
    return;
  }

  // Called by the Web runtime just before hot restarting the app.
  //
  // This extension cleans up resources that are registered with browser's
  // global singletons that Dart compiler is unable to clean-up automatically.
  //
  // This extension does not need to clean-up Dart statics. Those are cleaned
  // up by the compiler.
  developer.registerExtension('ext.flutter.disassemble', (_, __) {
    for (ui.VoidCallback listener in _hotRestartListeners) {
      listener();
    }
    return Future<developer.ServiceExtensionResponse>.value(
        developer.ServiceExtensionResponse.result('OK'));
  });

  _engineInitialized = true;

  // Calling this getter to force the DOM renderer to initialize before we
  // initialize framework bindings.
  domRenderer;

  WebExperiments.ensureInitialized();

  if (Profiler.isBenchmarkMode) {
    Profiler.ensureInitialized();
  }

  bool waitingForAnimation = false;
  scheduleFrameCallback = () {
    // We're asked to schedule a frame and call `frameHandler` when the frame
    // fires.
    if (!waitingForAnimation) {
      waitingForAnimation = true;
      html.window.requestAnimationFrame((num highResTime) {
        // Reset immediately, because `frameHandler` can schedule more frames.
        waitingForAnimation = false;

        // We have to convert high-resolution time to `int` so we can construct
        // a `Duration` out of it. However, high-res time is supplied in
        // milliseconds as a double value, with sub-millisecond information
        // hidden in the fraction. So we first multiply it by 1000 to uncover
        // microsecond precision, and only then convert to `int`.
        final int highResTimeMicroseconds = (1000 * highResTime).toInt();

        if (window._onBeginFrame != null) {
          window.invokeOnBeginFrame(
              Duration(microseconds: highResTimeMicroseconds));
        }

        if (window._onDrawFrame != null) {
          // TODO(yjbanov): technically Flutter flushes microtasks between
          //                onBeginFrame and onDrawFrame. We don't, which hasn't
          //                been an issue yet, but eventually we'll have to
          //                implement it properly.
          window.invokeOnDrawFrame();
        }
      });
    }
  };

  Keyboard.initialize();
  MouseCursor.initialize();
}

class _NullTreeSanitizer implements html.NodeTreeSanitizer {
  @override
  void sanitizeTree(html.Node node) {}
}

/// Converts a matrix represented using [Float64List] to one represented using
/// [Float32List].
///
/// 32-bit precision is sufficient because Flutter Engine itself (as well as
/// Skia) use 32-bit precision under the hood anyway.
///
/// 32-bit matrices require 2x less memory and in V8 they are allocated on the
/// JavaScript heap, thus avoiding a malloc.
///
/// See also:
/// * https://bugs.chromium.org/p/v8/issues/detail?id=9199
/// * https://bugs.chromium.org/p/v8/issues/detail?id=2022
Float32List toMatrix32(Float64List matrix64) {
  final Float32List matrix32 = Float32List(16);
  matrix32[15] = matrix64[15];
  matrix32[14] = matrix64[14];
  matrix32[13] = matrix64[13];
  matrix32[12] = matrix64[12];
  matrix32[11] = matrix64[11];
  matrix32[10] = matrix64[10];
  matrix32[9] = matrix64[9];
  matrix32[8] = matrix64[8];
  matrix32[7] = matrix64[7];
  matrix32[6] = matrix64[6];
  matrix32[5] = matrix64[5];
  matrix32[4] = matrix64[4];
  matrix32[3] = matrix64[3];
  matrix32[2] = matrix64[2];
  matrix32[1] = matrix64[1];
  matrix32[0] = matrix64[0];
  return matrix32;
}
