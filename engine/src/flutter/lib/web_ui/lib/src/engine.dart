// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is transformed during the build process into a single library with
// part files (`dart:_engine`) by performing the following:
//
//  - Replace all exports with part directives.
//  - Rewrite the libraries into `part of` part files without imports.
//  - Add imports to this file sufficient to cover the needs of `dart:_engine`.
//
// The code that performs the transformations lives in:
//
//  - https://github.com/flutter/engine/blob/main/web_sdk/sdk_rewriter.dart
// ignore: unnecessary_library_directive
library engine;

export 'engine/alarm_clock.dart';
export 'engine/app_bootstrap.dart';
export 'engine/browser_detection.dart';
export 'engine/canvaskit/canvas.dart';
export 'engine/canvaskit/canvaskit_api.dart';
export 'engine/canvaskit/canvaskit_canvas.dart';
export 'engine/canvaskit/color_filter.dart';
export 'engine/canvaskit/display_canvas_factory.dart';
export 'engine/canvaskit/embedded_views.dart';
export 'engine/canvaskit/fonts.dart';
export 'engine/canvaskit/image.dart';
export 'engine/canvaskit/image_filter.dart';
export 'engine/canvaskit/image_wasm_codecs.dart';
export 'engine/canvaskit/image_web_codecs.dart';
export 'engine/canvaskit/layer.dart';
export 'engine/canvaskit/layer_scene_builder.dart';
export 'engine/canvaskit/layer_tree.dart';
export 'engine/canvaskit/layer_visitor.dart';
export 'engine/canvaskit/mask_filter.dart';
export 'engine/canvaskit/multi_surface_rasterizer.dart';
export 'engine/canvaskit/n_way_canvas.dart';
export 'engine/canvaskit/native_memory.dart';
export 'engine/canvaskit/offscreen_canvas_rasterizer.dart';
export 'engine/canvaskit/overlay_scene_optimizer.dart';
export 'engine/canvaskit/painting.dart';
export 'engine/canvaskit/path.dart';
export 'engine/canvaskit/path_metrics.dart';
export 'engine/canvaskit/picture.dart';
export 'engine/canvaskit/picture_recorder.dart';
export 'engine/canvaskit/raster_cache.dart';
export 'engine/canvaskit/rasterizer.dart';
export 'engine/canvaskit/render_canvas.dart';
export 'engine/canvaskit/renderer.dart';
export 'engine/canvaskit/shader.dart';
export 'engine/canvaskit/surface.dart';
export 'engine/canvaskit/text.dart';
export 'engine/canvaskit/text_fragmenter.dart';
export 'engine/canvaskit/util.dart';
export 'engine/canvaskit/vertices.dart';
export 'engine/clipboard.dart';
export 'engine/color_filter.dart';
export 'engine/configuration.dart';
export 'engine/display.dart';
export 'engine/dom.dart';
export 'engine/font_change_util.dart';
export 'engine/font_fallback_data.dart';
export 'engine/font_fallbacks.dart';
export 'engine/fonts.dart';
export 'engine/frame_service.dart';
export 'engine/frame_timing_recorder.dart';
export 'engine/high_contrast.dart';
export 'engine/html_image_element_codec.dart';
export 'engine/image_decoder.dart';
export 'engine/image_format_detector.dart';
export 'engine/initialization.dart';
export 'engine/js_interop/js_app.dart';
export 'engine/js_interop/js_loader.dart';
export 'engine/js_interop/js_promise.dart';
export 'engine/js_interop/js_typed_data.dart';
export 'engine/key_map.g.dart';
export 'engine/keyboard_binding.dart';
export 'engine/layers.dart';
export 'engine/mouse/context_menu.dart';
export 'engine/mouse/cursor.dart';
export 'engine/mouse/prevent_default.dart';
export 'engine/navigation/history.dart';
export 'engine/noto_font.dart';
export 'engine/noto_font_encoding.dart';
export 'engine/onscreen_logging.dart';
export 'engine/platform_dispatcher.dart';
export 'engine/platform_dispatcher/app_lifecycle_state.dart';
export 'engine/platform_dispatcher/view_focus_binding.dart';
export 'engine/platform_views.dart';
export 'engine/platform_views/content_manager.dart';
export 'engine/platform_views/message_handler.dart';
export 'engine/platform_views/slots.dart';
export 'engine/plugins.dart';
export 'engine/pointer_binding.dart';
export 'engine/pointer_binding/event_position_helper.dart';
export 'engine/pointer_converter.dart';
export 'engine/profiler.dart';
export 'engine/raw_keyboard.dart';
export 'engine/renderer.dart';
export 'engine/rrect_renderer.dart';
export 'engine/safe_browser_api.dart';
export 'engine/scene_builder.dart';
export 'engine/scene_painting.dart';
export 'engine/scene_view.dart';
export 'engine/semantics/accessibility.dart';
export 'engine/semantics/checkable.dart';
export 'engine/semantics/expandable.dart';
export 'engine/semantics/focusable.dart';
export 'engine/semantics/header.dart';
export 'engine/semantics/heading.dart';
export 'engine/semantics/image.dart';
export 'engine/semantics/incrementable.dart';
export 'engine/semantics/label_and_value.dart';
export 'engine/semantics/link.dart';
export 'engine/semantics/live_region.dart';
export 'engine/semantics/platform_view.dart';
export 'engine/semantics/route.dart';
export 'engine/semantics/scrollable.dart';
export 'engine/semantics/semantics.dart';
export 'engine/semantics/semantics_helper.dart';
export 'engine/semantics/table.dart';
export 'engine/semantics/tabs.dart';
export 'engine/semantics/tappable.dart';
export 'engine/semantics/text_field.dart';
export 'engine/services/buffers.dart';
export 'engine/services/message_codec.dart';
export 'engine/services/message_codecs.dart';
export 'engine/services/serialization.dart';
export 'engine/shader_data.dart';
export 'engine/shadow.dart';
export 'engine/svg.dart';
export 'engine/test_embedding.dart';
export 'engine/text/line_breaker.dart';
export 'engine/text/paragraph.dart';
export 'engine/text_editing/autofill_hint.dart';
export 'engine/text_editing/composition_aware_mixin.dart';
export 'engine/text_editing/input_action.dart';
export 'engine/text_editing/input_type.dart';
export 'engine/text_editing/text_capitalization.dart';
export 'engine/text_editing/text_editing.dart';
export 'engine/util.dart';
export 'engine/validators.dart';
export 'engine/vector_math.dart';
export 'engine/view_embedder/dimensions_provider/custom_element_dimensions_provider.dart';
export 'engine/view_embedder/dimensions_provider/dimensions_provider.dart';
export 'engine/view_embedder/dimensions_provider/full_page_dimensions_provider.dart';
export 'engine/view_embedder/display_dpr_stream.dart';
export 'engine/view_embedder/dom_manager.dart';
export 'engine/view_embedder/embedding_strategy/custom_element_embedding_strategy.dart';
export 'engine/view_embedder/embedding_strategy/embedding_strategy.dart';
export 'engine/view_embedder/embedding_strategy/full_page_embedding_strategy.dart';
export 'engine/view_embedder/flutter_view_manager.dart';
export 'engine/view_embedder/global_html_attributes.dart';
export 'engine/view_embedder/hot_restart_cache_handler.dart';
export 'engine/view_embedder/style_manager.dart';
export 'engine/window.dart';
