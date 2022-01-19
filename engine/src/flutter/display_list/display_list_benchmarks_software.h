// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_DISPLAY_LIST_BENCHMARKS_SOFTWARE_H_
#define FLUTTER_FLOW_DISPLAY_LIST_BENCHMARKS_SOFTWARE_H_

#include "flutter/display_list/display_list_benchmarks_canvas_provider.h"

#include "third_party/skia/include/core/SkSurface.h"

namespace flutter {
namespace testing {

class SoftwareCanvasProvider : public CanvasProvider {
 public:
  virtual ~SoftwareCanvasProvider() = default;
  void InitializeSurface(const size_t width, const size_t height) override;
  sk_sp<SkSurface> GetSurface() override { return surface_; }
  sk_sp<SkSurface> MakeOffscreenSurface(const size_t width,
                                        const size_t height) override;
  const std::string BackendName() override { return "Software"; }

 private:
  sk_sp<SkSurface> surface_;
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_FLOW_DISPLAY_LIST_BENCHMARKS_SOFTWARE_H_
