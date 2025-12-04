// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_WEB_UI_SKWASM_HELPERS_H_
#define FLUTTER_LIB_WEB_UI_SKWASM_HELPERS_H_

#include "flutter/display_list/dl_sampling_options.h"
#include "flutter/display_list/geometry/dl_geometry_types.h"

#include "third_party/skia/include/core/SkMatrix.h"
#include "third_party/skia/include/core/SkRRect.h"
#include "third_party/skia/include/core/SkSamplingOptions.h"

namespace Skwasm {

template <typename T>
class sp_wrapper {
 public:
  sp_wrapper(std::shared_ptr<T> ptr) : _ptr(std::move(ptr)) {}

  const std::shared_ptr<T>& shared() { return _ptr; }

  T* raw() { return _ptr.get(); }

 private:
  std::shared_ptr<T> _ptr;
};

inline flutter::DlMatrix createDlMatrixFrom3x3(const flutter::DlScalar* f) {
  // clang-format off
  return flutter::DlMatrix(
    f[0], f[3], 0, f[6],
    f[1], f[4], 0, f[7],
    0, 0, 1, 0,
    f[2], f[5], 0, f[8]
  );
  // clang-format on
}

inline SkMatrix createSkMatrix(const SkScalar* f) {
  return SkMatrix::MakeAll(f[0], f[1], f[2], f[3], f[4], f[5], f[6], f[7],
                           f[8]);
}

inline flutter::DlRect createDlRect(const float* f) {
  return flutter::DlRect::MakeLTRB(f[0], f[1], f[2], f[3]);
}

inline flutter::DlRoundingRadii createDlRadii(const float* f) {
  // Flutter has radii in TL,TR,BR,BL (clockwise) order,
  // but Impeller uses TL,TR,BL,BR (zig-zag) order
  impeller::RoundingRadii radii = {
      .top_left = flutter::DlSize(f[0], f[1]),
      .top_right = flutter::DlSize(f[2], f[3]),
      .bottom_left = flutter::DlSize(f[6], f[7]),
      .bottom_right = flutter::DlSize(f[4], f[5]),
  };
  return radii;
}

inline flutter::DlRoundRect createDlRRect(const float* f) {
  return flutter::DlRoundRect::MakeRectRadii(createDlRect(f),
                                             createDlRadii(f + 4));
}

inline SkRRect createSkRRect(const SkScalar* f) {
  const SkRect* rect = reinterpret_cast<const SkRect*>(f);
  const SkVector* radiiValues = reinterpret_cast<const SkVector*>(f + 4);
  SkRRect rr;
  rr.setRectRadii(*rect, radiiValues);
  return rr;
}

// This must be kept in sync with the `ImageByteFormat` enum in dart:ui.
enum class ImageByteFormat {
  rawRgba,
  rawStraightRgba,
  rawUnmodified,
  png,
};

// This needs to be kept in sync with the "FilterQuality" enum in dart:ui
enum class FilterQuality {
  none,
  low,
  medium,
  high,
};

inline flutter::DlFilterMode filterModeForQuality(FilterQuality quality) {
  switch (quality) {
    case FilterQuality::none:
      return flutter::DlFilterMode::kNearest;
    case FilterQuality::low:
    case FilterQuality::medium:
    case FilterQuality::high:
      return flutter::DlFilterMode::kLinear;
  }
}

inline flutter::DlImageSampling samplingOptionsForQuality(
    FilterQuality quality) {
  switch (quality) {
    case FilterQuality::none:
      return flutter::DlImageSampling::kNearestNeighbor;
    case FilterQuality::low:
      return flutter::DlImageSampling::kLinear;
    case FilterQuality::medium:
      return flutter::DlImageSampling::kMipmapLinear;
    case FilterQuality::high:
      return flutter::DlImageSampling::kCubic;
  }
}
}  // namespace Skwasm

#endif  // FLUTTER_LIB_WEB_UI_SKWASM_HELPERS_H_
