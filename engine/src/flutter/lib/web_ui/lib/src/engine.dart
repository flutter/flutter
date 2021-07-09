// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@JS()
library engine;

// This file is transformed during the build process in order to make it a
// single library. Some notable transformations:
//
// 1. Imports of engine/* files are stripped out.
// 2. Exports of engine/* files are replaced with a part directive.
//
// The code that performs the transformations lives in:
// - https://github.com/flutter/engine/blob/master/web_sdk/sdk_rewriter.dart

import 'dart:async';
// Some of these names are used in services/buffers.dart for example.
// ignore: unused_import
import 'dart:collection'
    show ListBase, IterableBase, DoubleLinkedQueue, DoubleLinkedQueueEntry;
import 'dart:convert' hide Codec;
import 'dart:developer' as developer;
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:js_util' as js_util;
// ignore: unused_import
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:js/js.dart';
import 'package:meta/meta.dart';

import '../ui.dart' as ui;

export 'engine/alarm_clock.dart';

export 'engine/assets.dart';

import 'engine/browser_detection.dart';
export 'engine/browser_detection.dart';

export 'engine/canvas_pool.dart';

export 'engine/engine_canvas.dart';

export 'engine/frame_reference.dart';

import 'engine/host_node.dart';
export 'engine/host_node.dart';

export 'engine/html_image_codec.dart';

export 'engine/html/backdrop_filter.dart';

export 'engine/html/bitmap_canvas.dart';

export 'engine/html/canvas.dart';

export 'engine/html/clip.dart';

export 'engine/html/color_filter.dart';

export 'engine/html/debug_canvas_reuse_overlay.dart';

export 'engine/html/dom_canvas.dart';

export 'engine/html/image_filter.dart';

export 'engine/html/offscreen_canvas.dart';

export 'engine/html/offset.dart';

export 'engine/html/opacity.dart';

export 'engine/html/painting.dart';

export 'engine/html/path/path.dart';

export 'engine/html/path_to_svg_clip.dart';

export 'engine/html/path/conic.dart';

export 'engine/html/path/cubic.dart';

export 'engine/html/path/path_iterator.dart';

export 'engine/html/path/path_metrics.dart';

export 'engine/html/path/path_ref.dart';

export 'engine/html/path/path_to_svg.dart';

export 'engine/html/path/path_utils.dart';

export 'engine/html/path/path_windings.dart';

export 'engine/html/path/tangent.dart';

export 'engine/html/picture.dart';

export 'engine/html/platform_view.dart';

export 'engine/html/recording_canvas.dart';

export 'engine/html/render_vertices.dart';

import 'engine/html/scene.dart';
export 'engine/html/scene.dart';

export 'engine/html/scene_builder.dart';

export 'engine/html/shader_mask.dart';

export 'engine/html/shaders/image_shader.dart';

export 'engine/html/shaders/normalized_gradient.dart';

export 'engine/html/shaders/shader.dart';

export 'engine/html/shaders/shader_builder.dart';

export 'engine/html/shaders/vertex_shaders.dart';

export 'engine/html/shaders/webgl_context.dart';

export 'engine/html/surface.dart';

export 'engine/html/surface_stats.dart';

export 'engine/html/transform.dart';

import 'engine/keyboard_binding.dart';
export 'engine/keyboard_binding.dart';

import 'engine/keyboard.dart';
export 'engine/keyboard.dart';

export 'engine/key_map.dart';

import 'engine/mouse_cursor.dart';
export 'engine/mouse_cursor.dart';

import 'engine/navigation/history.dart';
export 'engine/navigation/history.dart';

import 'engine/navigation/js_url_strategy.dart';
export 'engine/navigation/js_url_strategy.dart';

import 'engine/navigation/url_strategy.dart';
export 'engine/navigation/url_strategy.dart';

export 'engine/onscreen_logging.dart';

export 'engine/picture.dart';

import 'engine/plugins.dart';
export 'engine/plugins.dart';

import 'engine/pointer_binding.dart';
export 'engine/pointer_binding.dart';

// This import is intentionally commented out because the analyzer says it's unused.
// import 'engine/pointer_converter.dart';
export 'engine/pointer_converter.dart';

import 'engine/profiler.dart';
export 'engine/profiler.dart';

export 'engine/rrect_renderer.dart';

import 'engine/semantics/accessibility.dart';
export 'engine/semantics/accessibility.dart';

export 'engine/semantics/checkable.dart';

export 'engine/semantics/image.dart';

export 'engine/semantics/incrementable.dart';

export 'engine/semantics/label_and_value.dart';

export 'engine/semantics/live_region.dart';

export 'engine/semantics/scrollable.dart';

import 'engine/semantics/semantics.dart';
export 'engine/semantics/semantics.dart';

export 'engine/semantics/semantics_helper.dart';

export 'engine/semantics/tappable.dart';

export 'engine/semantics/text_field.dart';

export 'engine/services/buffers.dart';

import 'engine/services/message_codec.dart';
export 'engine/services/message_codec.dart';

import 'engine/services/message_codecs.dart';
export 'engine/services/message_codecs.dart';

// This import is intentionally commented out because the analyzer says it's unused.
// import 'engine/services/serialization.dart';
export 'engine/services/serialization.dart';

export 'engine/shadow.dart';

import 'engine/test_embedding.dart';
export 'engine/test_embedding.dart';

export 'engine/text/font_collection.dart';

export 'engine/text/layout_service.dart';

export 'engine/text/line_break_properties.dart';

export 'engine/text/line_breaker.dart';

import 'engine/text/measurement.dart';
export 'engine/text/measurement.dart';

export 'engine/text/paint_service.dart';

export 'engine/text/paragraph.dart';

export 'engine/text/canvas_paragraph.dart';

export 'engine/text/ruler.dart';

export 'engine/text/text_direction.dart';

export 'engine/text/unicode_range.dart';

export 'engine/text/word_break_properties.dart';

export 'engine/text/word_breaker.dart';

export 'engine/text_editing/autofill_hint.dart';

export 'engine/text_editing/input_type.dart';

export 'engine/text_editing/text_capitalization.dart';

import 'engine/text_editing/text_editing.dart';
export 'engine/text_editing/text_editing.dart';

import 'engine/util.dart';
export 'engine/util.dart';

export 'engine/validators.dart';

export 'engine/vector_math.dart';

import 'engine/web_experiments.dart';
export 'engine/web_experiments.dart';

export 'engine/canvaskit/canvas.dart';

import 'engine/canvaskit/canvaskit_api.dart';
export 'engine/canvaskit/canvaskit_api.dart';

export 'engine/canvaskit/canvaskit_canvas.dart';

import 'engine/canvaskit/color_filter.dart';
export 'engine/canvaskit/color_filter.dart';

import 'engine/canvaskit/embedded_views.dart';
export 'engine/canvaskit/embedded_views.dart';

export 'engine/canvaskit/fonts.dart';

export 'engine/canvaskit/font_fallbacks.dart';

export 'engine/canvaskit/image.dart';

export 'engine/canvaskit/image_filter.dart';

import 'engine/canvaskit/initialization.dart';
export 'engine/canvaskit/initialization.dart';

export 'engine/canvaskit/interval_tree.dart';

export 'engine/canvaskit/layer.dart';

import 'engine/canvaskit/layer_scene_builder.dart';
export 'engine/canvaskit/layer_scene_builder.dart';

export 'engine/canvaskit/layer_tree.dart';

export 'engine/canvaskit/mask_filter.dart';

export 'engine/canvaskit/n_way_canvas.dart';

export 'engine/canvaskit/painting.dart';

export 'engine/canvaskit/path.dart';

export 'engine/canvaskit/path_metrics.dart';

export 'engine/canvaskit/picture.dart';

export 'engine/canvaskit/picture_recorder.dart';

import 'engine/canvaskit/rasterizer.dart';
export 'engine/canvaskit/rasterizer.dart';

export 'engine/canvaskit/raster_cache.dart';

export 'engine/canvaskit/shader.dart';

export 'engine/canvaskit/skia_object_cache.dart';

export 'engine/canvaskit/surface.dart';

export 'engine/canvaskit/surface_factory.dart';

export 'engine/canvaskit/text.dart';

export 'engine/canvaskit/util.dart';

export 'engine/canvaskit/vertices.dart';

part 'engine/clipboard.dart';
part 'engine/color_filter.dart';
part 'engine/dom_renderer.dart';
part 'engine/font_change_util.dart';
part 'engine/platform_dispatcher.dart';
part 'engine/platform_views.dart';
part 'engine/platform_views/content_manager.dart';
part 'engine/platform_views/message_handler.dart';
part 'engine/platform_views/slots.dart';
part 'engine/window.dart';

// The mode the app is running in.
// Keep these in sync with the same constants on the framework-side under foundation/constants.dart.
const bool kReleaseMode =
    bool.fromEnvironment('dart.vm.product', defaultValue: false);
const bool kProfileMode =
    bool.fromEnvironment('dart.vm.profile', defaultValue: false);
const bool kDebugMode = !kReleaseMode && !kProfileMode;
String get buildMode => kReleaseMode
    ? 'release'
    : kProfileMode
        ? 'profile'
        : 'debug';

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
void initializeEngine() {
  if (_engineInitialized) {
    return;
  }

  // Setup the hook that allows users to customize URL strategy before running
  // the app.
  _addUrlStrategyListener();

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
        frameTimingsOnVsync();

        // Reset immediately, because `frameHandler` can schedule more frames.
        waitingForAnimation = false;

        // We have to convert high-resolution time to `int` so we can construct
        // a `Duration` out of it. However, high-res time is supplied in
        // milliseconds as a double value, with sub-millisecond information
        // hidden in the fraction. So we first multiply it by 1000 to uncover
        // microsecond precision, and only then convert to `int`.
        final int highResTimeMicroseconds = (1000 * highResTime).toInt();

        // In Flutter terminology "building a frame" consists of "beginning
        // frame" and "drawing frame".
        //
        // We do not call `frameTimingsOnBuildFinish` from here because
        // part of the rasterization process, particularly in the HTML
        // renderer, takes place in the `SceneBuilder.build()`.
        frameTimingsOnBuildStart();
        if (EnginePlatformDispatcher.instance._onBeginFrame != null) {
          EnginePlatformDispatcher.instance.invokeOnBeginFrame(
              Duration(microseconds: highResTimeMicroseconds));
        }

        if (EnginePlatformDispatcher.instance._onDrawFrame != null) {
          // TODO(yjbanov): technically Flutter flushes microtasks between
          //                onBeginFrame and onDrawFrame. We don't, which hasn't
          //                been an issue yet, but eventually we'll have to
          //                implement it properly.
          EnginePlatformDispatcher.instance.invokeOnDrawFrame();
        }
      });
    }
  };

  Keyboard.initialize();
  MouseCursor.initialize();
}

void _addUrlStrategyListener() {
  _jsSetUrlStrategy = allowInterop((JsUrlStrategy? jsStrategy) {
    customUrlStrategy =
        jsStrategy == null ? null : CustomUrlStrategy.fromJs(jsStrategy);
  });
  registerHotRestartListener(() {
    _jsSetUrlStrategy = null;
  });
}

class NullTreeSanitizer implements html.NodeTreeSanitizer {
  @override
  void sanitizeTree(html.Node node) {}
}

/// The shared instance of PlatformViewManager shared across the engine to handle
/// rendering of PlatformViews into the web app.
/// TODO(dit): How to make this overridable from tests?
final PlatformViewManager platformViewManager = PlatformViewManager();

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
