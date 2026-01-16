// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <vector>

#include "flutter/display_list/dl_vertices.h"
#include "flutter/skwasm/export.h"
#include "flutter/skwasm/helpers.h"
#include "flutter/skwasm/live_objects.h"

SKWASM_EXPORT Skwasm::sp_wrapper<flutter::DlVertices>* vertices_create(
    flutter::DlVertexMode vertex_mode,
    int vertex_count,
    flutter::DlPoint* positions,
    flutter::DlPoint* texture_coordinates,
    uint32_t* colors,
    int index_count,
    uint16_t* indices) {
  Skwasm::live_vertices_count++;
  std::vector<flutter::DlColor> dl_colors;
  flutter::DlColor* dl_color_pointer = nullptr;
  if (colors != nullptr) {
    dl_colors.resize(vertex_count);
    for (int i = 0; i < vertex_count; i++) {
      dl_colors[i] = flutter::DlColor(colors[i]);
    }
    dl_color_pointer = dl_colors.data();
  }
  return new Skwasm::sp_wrapper<flutter::DlVertices>(flutter::DlVertices::Make(
      vertex_mode, vertex_count, positions, texture_coordinates,
      dl_color_pointer, index_count, indices));
}

SKWASM_EXPORT void vertices_dispose(
    Skwasm::sp_wrapper<flutter::DlVertices>* vertices) {
  Skwasm::live_vertices_count--;
  delete vertices;
}
