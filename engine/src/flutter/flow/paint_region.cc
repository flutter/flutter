// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/paint_region.h"

namespace flutter {

SkRect PaintRegion::ComputeBounds() const {
  SkRect res = SkRect::MakeEmpty();
  for (const auto& r : *this) {
    res.join(r);
  }
  return res;
}

}  // namespace flutter
