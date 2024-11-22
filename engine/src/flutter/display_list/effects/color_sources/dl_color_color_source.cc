// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/effects/color_sources/dl_color_color_source.h"

namespace flutter {

bool DlColorColorSource::equals_(DlColorSource const& other) const {
  FML_DCHECK(other.type() == DlColorSourceType::kColor);
  auto that = static_cast<DlColorColorSource const*>(&other);
  return color_ == that->color_;
}

}  // namespace flutter
