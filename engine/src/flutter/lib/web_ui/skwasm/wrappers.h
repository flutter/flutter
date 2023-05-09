// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <emscripten/html5_webgl.h>
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/skia/modules/skparagraph/include/FontCollection.h"
#include "third_party/skia/modules/skparagraph/include/TypefaceFontProvider.h"

namespace Skwasm {

struct SurfaceWrapper {
  EMSCRIPTEN_WEBGL_CONTEXT_HANDLE context;
  sk_sp<GrDirectContext> grContext;
  sk_sp<SkSurface> surface;
};

struct CanvasWrapper {
  EMSCRIPTEN_WEBGL_CONTEXT_HANDLE context;
  SkCanvas* canvas;
};

inline void makeCurrent(EMSCRIPTEN_WEBGL_CONTEXT_HANDLE handle) {
  if (!handle)
    return;

  int result = emscripten_webgl_make_context_current(handle);
  if (result != EMSCRIPTEN_RESULT_SUCCESS) {
    printf("make_context failed: %d", result);
  }
}

struct FlutterFontCollection {
  sk_sp<skia::textlayout::FontCollection> collection;
  sk_sp<skia::textlayout::TypefaceFontProvider> provider;
};

}  // namespace Skwasm
