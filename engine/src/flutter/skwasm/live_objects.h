// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SKWASM_LIVE_OBJECTS_H_
#define FLUTTER_SKWASM_LIVE_OBJECTS_H_

#include <cinttypes>

namespace Skwasm {

extern uint32_t live_line_break_buffer_count;
extern uint32_t live_unicode_position_buffer_count;
extern uint32_t live_line_metrics_count;
extern uint32_t live_text_box_list_count;
extern uint32_t live_paragraph_builder_count;
extern uint32_t live_paragraph_count;
extern uint32_t live_strut_style_count;
extern uint32_t live_text_style_count;
extern uint32_t live_animated_image_count;
extern uint32_t live_contour_measure_iter_count;
extern uint32_t live_contour_measure_count;
extern uint32_t live_data_count;
extern uint32_t live_color_filter_count;
extern uint32_t live_image_filter_count;
extern uint32_t live_mask_filter_count;
extern uint32_t live_typeface_count;
extern uint32_t live_font_collection_count;
extern uint32_t live_image_count;
extern uint32_t live_paint_count;
extern uint32_t live_path_count;
extern uint32_t live_picture_count;
extern uint32_t live_picture_recorder_count;
extern uint32_t live_shader_count;
extern uint32_t live_runtime_effect_count;
extern uint32_t live_string_count;
extern uint32_t live_string16_count;
extern uint32_t live_surface_count;
extern uint32_t live_vertices_count;

}  // namespace Skwasm

#endif  // FLUTTER_SKWASM_LIVE_OBJECTS_H_
