// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <vector>

#include "flutter/display_list/display_list_blend_mode.h"
#include "flutter/display_list/display_list_color.h"
#include "flutter/display_list/display_list_sampling_options.h"
#include "flutter/display_list/display_list_tile_mode.h"
#include "impeller/entity/entity.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/matrix.h"
#include "third_party/skia/include/core/SkColor.h"
#include "third_party/skia/include/core/SkMatrix.h"
#include "third_party/skia/include/core/SkPoint.h"

namespace impeller {

#define UNIMPLEMENTED \
  FML_DLOG(ERROR) << "Unimplemented detail in " << __FUNCTION__;

BlendMode ToBlendMode(flutter::DlBlendMode mode);

Entity::TileMode ToTileMode(flutter::DlTileMode tile_mode);

impeller::SamplerDescriptor ToSamplerDescriptor(
    const flutter::DlImageSampling options);

impeller::SamplerDescriptor ToSamplerDescriptor(
    const flutter::DlFilterMode options);

Matrix ToMatrix(const SkMatrix& m);

Point ToPoint(const SkPoint& point);

Color ToColor(const SkColor& color);

std::vector<Color> ToColors(const flutter::DlColor colors[], int count);

std::vector<Matrix> ToRSXForms(const SkRSXform xform[], int count);

// Convert display list colors + stops into impeller colors and stops, taking
// care to ensure that the stops always start with 0.0 and end with 1.0.
template <typename T>
void ConvertStops(T* gradient,
                  std::vector<Color>* colors,
                  std::vector<float>* stops) {
  FML_DCHECK(gradient->stop_count() >= 2);

  auto* dl_colors = gradient->colors();
  auto* dl_stops = gradient->stops();
  if (dl_stops[0] != 0.0) {
    colors->emplace_back(ToColor(dl_colors[0]));
    stops->emplace_back(0);
  }
  for (auto i = 0; i < gradient->stop_count(); i++) {
    colors->emplace_back(ToColor(dl_colors[i]));
    stops->emplace_back(dl_stops[i]);
  }
  if (stops->back() != 1.0) {
    colors->emplace_back(colors->back());
    stops->emplace_back(1.0);
  }
}

}  // namespace impeller
