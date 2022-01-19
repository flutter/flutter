// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/display_list_benchmarks_software.h"
#include "flutter/display_list/display_list_benchmarks.h"

namespace flutter {
namespace testing {

void SoftwareCanvasProvider::InitializeSurface(const size_t width,
                                               const size_t height) {
  surface_ = SkSurface::MakeRasterN32Premul(width, height);
  surface_->getCanvas()->clear(SK_ColorTRANSPARENT);
}

sk_sp<SkSurface> SoftwareCanvasProvider::MakeOffscreenSurface(
    const size_t width,
    const size_t height) {
  auto surface = SkSurface::MakeRasterN32Premul(width, height);
  surface->getCanvas()->clear(SK_ColorTRANSPARENT);
  return surface;
}

RUN_DISPLAYLIST_BENCHMARKS(Software)

}  // namespace testing
}  // namespace flutter
