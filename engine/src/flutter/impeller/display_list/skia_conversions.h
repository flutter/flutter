// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_DISPLAY_LIST_SKIA_CONVERSIONS_H_
#define FLUTTER_IMPELLER_DISPLAY_LIST_SKIA_CONVERSIONS_H_

#include "flutter/display_list/dl_blend_mode.h"
#include "flutter/display_list/dl_color.h"
#include "flutter/display_list/dl_sampling_options.h"
#include "flutter/impeller/core/sampler_descriptor.h"
#include "flutter/impeller/geometry/color.h"

namespace impeller {
namespace skia_conversions {

Color ToColor(const flutter::DlColor& color);

impeller::SamplerDescriptor ToSamplerDescriptor(
    const flutter::DlImageSampling options);

}  // namespace skia_conversions
}  // namespace impeller

#endif  // FLUTTER_IMPELLER_DISPLAY_LIST_SKIA_CONVERSIONS_H_
