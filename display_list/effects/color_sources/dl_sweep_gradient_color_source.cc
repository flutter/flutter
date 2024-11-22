// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/effects/color_sources/dl_sweep_gradient_color_source.h"

namespace flutter {

DlSweepGradientColorSource::DlSweepGradientColorSource(DlPoint center,
                                                       DlScalar start,
                                                       DlScalar end,
                                                       uint32_t stop_count,
                                                       const DlColor* colors,
                                                       const float* stops,
                                                       DlTileMode tile_mode,
                                                       const DlMatrix* matrix)
    : DlGradientColorSourceBase(stop_count, tile_mode, matrix),
      center_(center),
      start_(start),
      end_(end) {
  store_color_stops(this + 1, colors, stops);
}

DlSweepGradientColorSource::DlSweepGradientColorSource(
    const DlSweepGradientColorSource* source)
    : DlGradientColorSourceBase(source->stop_count(),
                                source->tile_mode(),
                                source->matrix_ptr()),
      center_(source->center()),
      start_(source->start()),
      end_(source->end()) {
  store_color_stops(this + 1, source->colors(), source->stops());
}

std::shared_ptr<DlColorSource> DlSweepGradientColorSource::shared() const {
  return MakeSweep(center_, start_, end_, stop_count(), colors(), stops(),
                   tile_mode(), matrix_ptr());
}

bool DlSweepGradientColorSource::equals_(DlColorSource const& other) const {
  FML_DCHECK(other.type() == DlColorSourceType::kSweepGradient);
  auto that = static_cast<DlSweepGradientColorSource const*>(&other);
  return (center_ == that->center_ && start_ == that->start_ &&
          end_ == that->end_ && base_equals_(that));
}

}  // namespace flutter
