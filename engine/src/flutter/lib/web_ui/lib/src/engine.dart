// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library engine;

import 'dart:async';
import 'dart:collection' show ListBase;
import 'dart:convert' hide Codec;
import 'dart:developer' as developer;
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:js_util' as js_util;
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../ui.dart' as ui;

part 'engine/alarm_clock.dart';
part 'engine/assets.dart';
part 'engine/bitmap_canvas.dart';
part 'engine/browser_detection.dart';
part 'engine/browser_location.dart';
part 'engine/compositor/canvas.dart';
part 'engine/compositor/engine_delegate.dart';
part 'engine/compositor/fonts.dart';
part 'engine/compositor/image.dart';
part 'engine/compositor/initialization.dart';
part 'engine/compositor/layer.dart';
part 'engine/compositor/layer_scene_builder.dart';
part 'engine/compositor/layer_tree.dart';
part 'engine/compositor/path.dart';
part 'engine/compositor/picture.dart';
part 'engine/compositor/picture_recorder.dart';
part 'engine/compositor/platform_message.dart';
part 'engine/compositor/raster_cache.dart';
part 'engine/compositor/rasterizer.dart';
part 'engine/compositor/recording_canvas.dart';
part 'engine/compositor/runtime_delegate.dart';
part 'engine/compositor/surface.dart';
part 'engine/compositor/util.dart';
part 'engine/compositor/viewport_metrics.dart';
part 'engine/conic.dart';
part 'engine/dom_canvas.dart';
part 'engine/dom_renderer.dart';
part 'engine/engine_canvas.dart';
part 'engine/history.dart';
part 'engine/houdini_canvas.dart';
part 'engine/html_image_codec.dart';
part 'engine/keyboard.dart';
part 'engine/onscreen_logging.dart';
part 'engine/path_to_svg.dart';
part 'engine/platform_views.dart';
part 'engine/pointer_binding.dart';
part 'engine/recording_canvas.dart';
part 'engine/semantics/accessibility.dart';
part 'engine/semantics/checkable.dart';
part 'engine/semantics/image.dart';
part 'engine/semantics/incrementable.dart';
part 'engine/semantics/label_and_value.dart';
part 'engine/semantics/live_region.dart';
part 'engine/semantics/scrollable.dart';
part 'engine/semantics/semantics.dart';
part 'engine/semantics/tappable.dart';
part 'engine/semantics/text_field.dart';
part 'engine/services/buffers.dart';
part 'engine/services/message_codec.dart';
part 'engine/services/message_codecs.dart';
part 'engine/services/serialization.dart';
part 'engine/shader.dart';
part 'engine/shadow.dart';
part 'engine/surface/backdrop_filter.dart';
part 'engine/surface/clip.dart';
part 'engine/surface/debug_canvas_reuse_overlay.dart';
part 'engine/surface/offset.dart';
part 'engine/surface/opacity.dart';
part 'engine/surface/picture.dart';
part 'engine/surface/platform_view.dart';
part 'engine/surface/scene.dart';
part 'engine/surface/surface.dart';
part 'engine/surface/transform.dart';
part 'engine/test_embedding.dart';
part 'engine/text/font_collection.dart';
part 'engine/text/line_breaker.dart';
part 'engine/text/measurement.dart';
part 'engine/text/paragraph.dart';
part 'engine/text/ruler.dart';
part 'engine/text/unicode_range.dart';
part 'engine/text/word_break_properties.dart';
part 'engine/text/word_breaker.dart';
part 'engine/text_editing.dart';
part 'engine/util.dart';
part 'engine/validators.dart';
part 'engine/vector_math.dart';
part 'engine/window.dart';

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
void webOnlyInitializeEngine() {
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

  bool waitingForAnimation = false;
  ui.webOnlyScheduleFrameCallback = () {
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

        if (ui.window.onBeginFrame != null) {
          ui.window
              .onBeginFrame(Duration(microseconds: highResTimeMicroseconds));
        }

        if (ui.window.onDrawFrame != null) {
          // TODO(yjbanov): technically Flutter flushes microtasks between
          //                onBeginFrame and onDrawFrame. We don't, which hasn't
          //                been an issue yet, but eventually we'll have to
          //                implement it properly.
          ui.window.onDrawFrame();
        }
      });
    }
  };

  Keyboard.initialize();
}

class _NullTreeSanitizer implements html.NodeTreeSanitizer {
  @override
  void sanitizeTree(html.Node node) {}
}
