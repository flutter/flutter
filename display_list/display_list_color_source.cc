// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/display_list_color_source.h"
#include "flutter/display_list/display_list_sampling_options.h"

namespace flutter {

std::shared_ptr<DlColorSource> DlColorSource::From(SkShader* sk_shader) {
  if (sk_shader == nullptr) {
    return nullptr;
  }
  {
    SkMatrix local_matrix;
    SkTileMode xy[2];
    SkImage* image = sk_shader->isAImage(&local_matrix, xy);
    if (image) {
      return std::make_shared<DlImageColorSource>(
          sk_ref_sp(image), ToDl(xy[0]), ToDl(xy[1]), DlImageSampling::kLinear,
          &local_matrix);
    }
  }
  // Skia provides |SkShader->asAGradient(&info)| method to access the
  // parameters of a gradient, but the info object being filled has a number
  // of parameters which are missing, including the local matrix in every
  // gradient, and the sweep angles in the sweep gradients.
  //
  // Since we can't reproduce every Gradient, and customers rely on using
  // gradients with matrices in text code, we have to just use an Unknown
  // ColorSource to express all gradients.
  // (see: https://github.com/flutter/flutter/issues/102947)
  return std::make_shared<DlUnknownColorSource>(sk_ref_sp(sk_shader));
}

static void DlGradientDeleter(void* p) {
  // Some of our target environments would prefer a sized delete,
  // but other target environments do not have that operator.
  // Use an unsized delete until we get better agreement in the
  // environments.
  // See https://github.com/flutter/flutter/issues/100327
  ::operator delete(p);
}

std::shared_ptr<DlColorSource> DlColorSource::MakeLinear(
    const SkPoint start_point,
    const SkPoint end_point,
    uint32_t stop_count,
    const DlColor* colors,
    const float* stops,
    DlTileMode tile_mode,
    const SkMatrix* matrix) {
  size_t needed = sizeof(DlLinearGradientColorSource) +
                  (stop_count * (sizeof(uint32_t) + sizeof(float)));

  void* storage = ::operator new(needed);

  std::shared_ptr<DlLinearGradientColorSource> ret;
  ret.reset(new (storage)
                DlLinearGradientColorSource(start_point, end_point, stop_count,
                                            colors, stops, tile_mode, matrix),
            DlGradientDeleter);
  return std::move(ret);
}

std::shared_ptr<DlColorSource> DlColorSource::MakeRadial(
    SkPoint center,
    SkScalar radius,
    uint32_t stop_count,
    const DlColor* colors,
    const float* stops,
    DlTileMode tile_mode,
    const SkMatrix* matrix) {
  size_t needed = sizeof(DlRadialGradientColorSource) +
                  (stop_count * (sizeof(uint32_t) + sizeof(float)));

  void* storage = ::operator new(needed);

  std::shared_ptr<DlRadialGradientColorSource> ret;
  ret.reset(new (storage) DlRadialGradientColorSource(
                center, radius, stop_count, colors, stops, tile_mode, matrix),
            DlGradientDeleter);
  return std::move(ret);
}

std::shared_ptr<DlColorSource> DlColorSource::MakeConical(
    SkPoint start_center,
    SkScalar start_radius,
    SkPoint end_center,
    SkScalar end_radius,
    uint32_t stop_count,
    const DlColor* colors,
    const float* stops,
    DlTileMode tile_mode,
    const SkMatrix* matrix) {
  size_t needed = sizeof(DlConicalGradientColorSource) +
                  (stop_count * (sizeof(uint32_t) + sizeof(float)));

  void* storage = ::operator new(needed);

  std::shared_ptr<DlConicalGradientColorSource> ret;
  ret.reset(new (storage) DlConicalGradientColorSource(
                start_center, start_radius, end_center, end_radius, stop_count,
                colors, stops, tile_mode, matrix),
            DlGradientDeleter);
  return std::move(ret);
}

std::shared_ptr<DlColorSource> DlColorSource::MakeSweep(
    SkPoint center,
    SkScalar start,
    SkScalar end,
    uint32_t stop_count,
    const DlColor* colors,
    const float* stops,
    DlTileMode tile_mode,
    const SkMatrix* matrix) {
  size_t needed = sizeof(DlSweepGradientColorSource) +
                  (stop_count * (sizeof(uint32_t) + sizeof(float)));

  void* storage = ::operator new(needed);

  std::shared_ptr<DlSweepGradientColorSource> ret;
  ret.reset(new (storage)
                DlSweepGradientColorSource(center, start, end, stop_count,
                                           colors, stops, tile_mode, matrix),
            DlGradientDeleter);
  return std::move(ret);
}

}  // namespace flutter
