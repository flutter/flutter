// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/effects/dl_color_source.h"

#include "flutter/display_list/dl_sampling_options.h"
#include "flutter/display_list/effects/dl_runtime_effect.h"
#include "flutter/fml/logging.h"

namespace flutter {

static void DlGradientDeleter(void* p) {
  // Some of our target environments would prefer a sized delete,
  // but other target environments do not have that operator.
  // Use an unsized delete until we get better agreement in the
  // environments.
  // See https://github.com/flutter/flutter/issues/100327
  ::operator delete(p);
}

std::shared_ptr<DlLinearGradientColorSource> DlColorSource::MakeLinear(
    const SkPoint start_point,
    const SkPoint end_point,
    uint32_t stop_count,
    const DlColor* colors,
    const float* stops,
    DlTileMode tile_mode,
    const SkMatrix* matrix) {
  size_t needed = sizeof(DlLinearGradientColorSource) +
                  (stop_count * (sizeof(DlColor) + sizeof(float)));

  void* storage = ::operator new(needed);

  std::shared_ptr<DlLinearGradientColorSource> ret;
  ret.reset(new (storage)
                DlLinearGradientColorSource(start_point, end_point, stop_count,
                                            colors, stops, tile_mode, matrix),
            DlGradientDeleter);
  return ret;
}

std::shared_ptr<DlRadialGradientColorSource> DlColorSource::MakeRadial(
    SkPoint center,
    SkScalar radius,
    uint32_t stop_count,
    const DlColor* colors,
    const float* stops,
    DlTileMode tile_mode,
    const SkMatrix* matrix) {
  size_t needed = sizeof(DlRadialGradientColorSource) +
                  (stop_count * (sizeof(DlColor) + sizeof(float)));

  void* storage = ::operator new(needed);

  std::shared_ptr<DlRadialGradientColorSource> ret;
  ret.reset(new (storage) DlRadialGradientColorSource(
                center, radius, stop_count, colors, stops, tile_mode, matrix),
            DlGradientDeleter);
  return ret;
}

std::shared_ptr<DlConicalGradientColorSource> DlColorSource::MakeConical(
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
                  (stop_count * (sizeof(DlColor) + sizeof(float)));

  void* storage = ::operator new(needed);

  std::shared_ptr<DlConicalGradientColorSource> ret;
  ret.reset(new (storage) DlConicalGradientColorSource(
                start_center, start_radius, end_center, end_radius, stop_count,
                colors, stops, tile_mode, matrix),
            DlGradientDeleter);
  return ret;
}

std::shared_ptr<DlSweepGradientColorSource> DlColorSource::MakeSweep(
    SkPoint center,
    SkScalar start,
    SkScalar end,
    uint32_t stop_count,
    const DlColor* colors,
    const float* stops,
    DlTileMode tile_mode,
    const SkMatrix* matrix) {
  size_t needed = sizeof(DlSweepGradientColorSource) +
                  (stop_count * (sizeof(DlColor) + sizeof(float)));

  void* storage = ::operator new(needed);

  std::shared_ptr<DlSweepGradientColorSource> ret;
  ret.reset(new (storage)
                DlSweepGradientColorSource(center, start, end, stop_count,
                                           colors, stops, tile_mode, matrix),
            DlGradientDeleter);
  return ret;
}

std::shared_ptr<DlRuntimeEffectColorSource> DlColorSource::MakeRuntimeEffect(
    sk_sp<DlRuntimeEffect> runtime_effect,
    std::vector<std::shared_ptr<DlColorSource>> samplers,
    std::shared_ptr<std::vector<uint8_t>> uniform_data) {
  FML_DCHECK(uniform_data != nullptr);
  return std::make_shared<DlRuntimeEffectColorSource>(
      std::move(runtime_effect), std::move(samplers), std::move(uniform_data));
}

}  // namespace flutter
