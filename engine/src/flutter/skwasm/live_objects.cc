// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/skwasm/live_objects.h"

#include "flutter/skwasm/export.h"

uint32_t Skwasm::live_line_break_buffer_count = 0;
uint32_t Skwasm::live_unicode_position_buffer_count = 0;
uint32_t Skwasm::live_line_metrics_count = 0;
uint32_t Skwasm::live_text_box_list_count = 0;
uint32_t Skwasm::live_paragraph_builder_count = 0;
uint32_t Skwasm::live_paragraph_count = 0;
uint32_t Skwasm::live_strut_style_count = 0;
uint32_t Skwasm::live_text_style_count = 0;
uint32_t Skwasm::live_animated_image_count = 0;
uint32_t Skwasm::live_contour_measure_iter_count = 0;
uint32_t Skwasm::live_contour_measure_count = 0;
uint32_t Skwasm::live_data_count = 0;
uint32_t Skwasm::live_color_filter_count = 0;
uint32_t Skwasm::live_image_filter_count = 0;
uint32_t Skwasm::live_mask_filter_count = 0;
uint32_t Skwasm::live_typeface_count = 0;
uint32_t Skwasm::live_font_collection_count = 0;
uint32_t Skwasm::live_image_count = 0;
uint32_t Skwasm::live_paint_count = 0;
uint32_t Skwasm::live_path_count = 0;
uint32_t Skwasm::live_picture_count = 0;
uint32_t Skwasm::live_picture_recorder_count = 0;
uint32_t Skwasm::live_shader_count = 0;
uint32_t Skwasm::live_runtime_effect_count = 0;
uint32_t Skwasm::live_string_count = 0;
uint32_t Skwasm::live_string16_count = 0;
uint32_t Skwasm::live_surface_count = 0;
uint32_t Skwasm::live_vertices_count = 0;

namespace {
struct LiveObjectCounts {
  uint32_t line_break_buffer_count;
  uint32_t unicode_position_buffer_count;
  uint32_t line_metrics_count;
  uint32_t text_box_list_count;
  uint32_t paragraph_builder_count;
  uint32_t paragraph_count;
  uint32_t strut_style_count;
  uint32_t text_style_count;
  uint32_t animated_image_count;
  uint32_t contour_measure_iter_count;
  uint32_t contour_measure_count;
  uint32_t data_count;
  uint32_t color_filter_count;
  uint32_t image_filter_count;
  uint32_t mask_filter_count;
  uint32_t typeface_count;
  uint32_t font_collection_count;
  uint32_t image_count;
  uint32_t paint_count;
  uint32_t path_count;
  uint32_t picture_count;
  uint32_t picture_recorder_count;
  uint32_t shader_count;
  uint32_t runtime_effect_count;
  uint32_t string_count;
  uint32_t string16_count;
  uint32_t surface_count;
  uint32_t vertices_count;
};
}  // namespace

SKWASM_EXPORT void skwasm_getLiveObjectCounts(LiveObjectCounts* counts) {
  counts->line_break_buffer_count = Skwasm::live_line_break_buffer_count;
  counts->unicode_position_buffer_count =
      Skwasm::live_unicode_position_buffer_count;
  counts->line_metrics_count = Skwasm::live_line_metrics_count;
  counts->text_box_list_count = Skwasm::live_text_box_list_count;
  counts->paragraph_builder_count = Skwasm::live_paragraph_builder_count;
  counts->paragraph_count = Skwasm::live_paragraph_count;
  counts->strut_style_count = Skwasm::live_strut_style_count;
  counts->text_style_count = Skwasm::live_text_style_count;
  counts->animated_image_count = Skwasm::live_animated_image_count;
  counts->contour_measure_iter_count = Skwasm::live_contour_measure_iter_count;
  counts->contour_measure_count = Skwasm::live_contour_measure_count;
  counts->data_count = Skwasm::live_data_count;
  counts->color_filter_count = Skwasm::live_color_filter_count;
  counts->image_filter_count = Skwasm::live_image_filter_count;
  counts->mask_filter_count = Skwasm::live_mask_filter_count;
  counts->typeface_count = Skwasm::live_typeface_count;
  counts->font_collection_count = Skwasm::live_font_collection_count;
  counts->image_count = Skwasm::live_image_count;
  counts->paint_count = Skwasm::live_paint_count;
  counts->path_count = Skwasm::live_path_count;
  counts->picture_count = Skwasm::live_picture_count;
  counts->picture_recorder_count = Skwasm::live_picture_recorder_count;
  counts->shader_count = Skwasm::live_shader_count;
  counts->runtime_effect_count = Skwasm::live_runtime_effect_count;
  counts->string_count = Skwasm::live_string_count;
  counts->string16_count = Skwasm::live_string16_count;
  counts->surface_count = Skwasm::live_surface_count;
  counts->vertices_count = Skwasm::live_vertices_count;
}
