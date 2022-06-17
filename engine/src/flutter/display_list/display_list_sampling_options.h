// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_DISPLAY_LIST_SAMPLING_OPTIONS_H_
#define FLUTTER_DISPLAY_LIST_DISPLAY_LIST_SAMPLING_OPTIONS_H_

#include "include/core/SkColorSpace.h"
#include "include/core/SkSamplingOptions.h"
namespace flutter {

enum class DlFilterMode {
  kNearest,  // single sample point (nearest neighbor)
  kLinear,   // interporate between 2x2 sample points (bilinear interpolation)

  kLast = kLinear,
};

inline DlFilterMode ToDl(const SkFilterMode filter_mode) {
  return static_cast<DlFilterMode>(filter_mode);
}

inline SkFilterMode ToSk(const DlFilterMode filter_mode) {
  return static_cast<SkFilterMode>(filter_mode);
}

enum class DlImageSampling {
  kNearestNeighbor,
  kLinear,
  kMipmapLinear,
  kCubic,
};

inline DlImageSampling ToDl(const SkSamplingOptions& so) {
  if (so.useCubic) {
    return DlImageSampling::kCubic;
  }
  if (so.filter == SkFilterMode::kLinear) {
    if (so.mipmap == SkMipmapMode::kNone) {
      return DlImageSampling::kLinear;
    }
    if (so.mipmap == SkMipmapMode::kLinear) {
      return DlImageSampling::kMipmapLinear;
    }
  }
  return DlImageSampling::kNearestNeighbor;
}

inline SkSamplingOptions ToSk(DlImageSampling sampling) {
  switch (sampling) {
    case DlImageSampling::kCubic:
      return SkSamplingOptions(SkCubicResampler{1 / 3.0f, 1 / 3.0f});
    case DlImageSampling::kLinear:
      return SkSamplingOptions(SkFilterMode::kLinear);
    case DlImageSampling::kMipmapLinear:
      return SkSamplingOptions(SkFilterMode::kLinear, SkMipmapMode::kLinear);
    case DlImageSampling::kNearestNeighbor:
      return SkSamplingOptions(SkFilterMode::kNearest);
  }
}

}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_DISPLAY_LIST_SAMPLING_OPTIONS_H_
