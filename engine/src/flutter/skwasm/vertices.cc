// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <vector>

#include "flutter/display_list/dl_vertices.h"
#include "flutter/skwasm/export.h"
#include "flutter/skwasm/helpers.h"
#include "flutter/skwasm/live_objects.h"

SKWASM_EXPORT Skwasm::sp_wrapper<flutter::DlVertices>* vertices_create(
    flutter::DlVertexMode vertexMode,
    int vertexCount,
    flutter::DlPoint* positions,
    flutter::DlPoint* textureCoordinates,
    uint32_t* colors,
    int indexCount,
    uint16_t* indices) {
  Skwasm::liveVerticesCount++;
  std::vector<flutter::DlColor> dlColors;
  flutter::DlColor* dlColorPointer = nullptr;
  if (colors != nullptr) {
    dlColors.resize(vertexCount);
    for (int i = 0; i < vertexCount; i++) {
      dlColors[i] = flutter::DlColor(colors[i]);
    }
    dlColorPointer = dlColors.data();
  }
  return new Skwasm::sp_wrapper<flutter::DlVertices>(flutter::DlVertices::Make(
      vertexMode, vertexCount, positions, textureCoordinates, dlColorPointer,
      indexCount, indices));
}

SKWASM_EXPORT void vertices_dispose(
    Skwasm::sp_wrapper<flutter::DlVertices>* vertices) {
  Skwasm::liveVerticesCount--;
  delete vertices;
}
