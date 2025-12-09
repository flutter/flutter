// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "export.h"
#include "helpers.h"
#include "live_objects.h"

#include "flutter/display_list/dl_vertices.h"

using namespace flutter;
using namespace Skwasm;

SKWASM_EXPORT sp_wrapper<DlVertices>* vertices_create(
    DlVertexMode vertexMode,
    int vertexCount,
    DlPoint* positions,
    DlPoint* textureCoordinates,
    uint32_t* colors,
    int indexCount,
    uint16_t* indices) {
  liveVerticesCount++;
  std::vector<DlColor> dlColors;
  DlColor* dlColorPointer = nullptr;
  if (colors != nullptr) {
    dlColors.resize(vertexCount);
    for (int i = 0; i < vertexCount; i++) {
      dlColors[i] = DlColor(colors[i]);
    }
    dlColorPointer = dlColors.data();
  }
  return new sp_wrapper<DlVertices>(
      DlVertices::Make(vertexMode, vertexCount, positions, textureCoordinates,
                       dlColorPointer, indexCount, indices));
}

SKWASM_EXPORT void vertices_dispose(sp_wrapper<DlVertices>* vertices) {
  liveVerticesCount--;
  delete vertices;
}
