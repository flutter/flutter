// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/display_list_benchmarks_metal.h"
#include "flutter/display_list/display_list_benchmarks.h"

#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkSurface.h"

namespace flutter {
namespace testing {

void MetalCanvasProvider::InitializeSurface(const size_t width,
                                            const size_t height) {
  metal_context_ = std::make_unique<TestMetalContext>();
  metal_surface_ =
      TestMetalSurface::Create(*metal_context_, SkISize::Make(width, height));
  metal_surface_->GetSurface()->getCanvas()->clear(SK_ColorTRANSPARENT);
}

sk_sp<SkSurface> MetalCanvasProvider::GetSurface() {
  if (!metal_surface_) {
    return nullptr;
  }
  return metal_surface_->GetSurface();
}

sk_sp<SkSurface> MetalCanvasProvider::MakeOffscreenSurface(
    const size_t width,
    const size_t height) {
  metal_offscreen_surface_ =
      TestMetalSurface::Create(*metal_context_, SkISize::Make(width, height));
  return metal_offscreen_surface_->GetSurface();
}

RUN_DISPLAYLIST_BENCHMARKS(Metal)

}  // namespace testing
}  // namespace flutter
