// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_DISPLAY_LIST_BENCHMARKS_CANVAS_PROVIDER_H_
#define FLUTTER_FLOW_DISPLAY_LIST_BENCHMARKS_CANVAS_PROVIDER_H_

#include "flutter/fml/mapping.h"
#include "flutter/testing/testing.h"

#include "third_party/skia/include/core/SkData.h"
#include "third_party/skia/include/core/SkSurface.h"

namespace flutter {
namespace testing {

class CanvasProvider {
 public:
  virtual ~CanvasProvider() = default;
  virtual const std::string BackendName() = 0;
  virtual void InitializeSurface(const size_t width, const size_t height) = 0;
  virtual sk_sp<SkSurface> GetSurface() = 0;
  virtual sk_sp<SkSurface> MakeOffscreenSurface(const size_t width,
                                                const size_t height) = 0;

  virtual bool Snapshot(std::string filename) {
#ifdef BENCHMARKS_NO_SNAPSHOT
    return false;
#else
    auto image = GetSurface()->makeImageSnapshot();
    if (!image) {
      return false;
    }
    auto raster = image->makeRasterImage();
    if (!raster) {
      return false;
    }
    auto data = raster->encodeToData();
    if (!data) {
      return false;
    }
    fml::NonOwnedMapping mapping(static_cast<const uint8_t*>(data->data()),
                                 data->size());
    return WriteAtomically(OpenFixturesDirectory(), filename.c_str(), mapping);
#endif
  }
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_FLOW_DISPLAY_LIST_BENCHMARKS_CANVAS_PROVIDER_H_
