// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/display_list_builder_multiplexer.h"

namespace flutter {

void DisplayListBuilderMultiplexer::addBuilder(DisplayListBuilder* builder) {
  builders_.push_back(builder);
}

void DisplayListBuilderMultiplexer::saveLayer(
    const SkRect* bounds,
    const DlPaint* paint,
    const DlImageFilter* backdrop_filter) {
  for (auto* builder : builders_) {
    builder->saveLayer(bounds, paint, backdrop_filter);
  }
}

void DisplayListBuilderMultiplexer::restore() {
  for (auto* builder : builders_) {
    builder->restore();
  }
}

}  // namespace flutter
