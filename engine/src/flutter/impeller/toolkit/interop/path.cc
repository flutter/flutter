// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/toolkit/interop/path.h"

#include "third_party/skia/include/core/SkRect.h"

namespace impeller::interop {

Path::Path(const SkPath& path) : path_(SkPathBuilder(path)) {}

Path::~Path() = default;

SkPath Path::GetPath() const {
  return path_.snapshot();
}

ImpellerRect Path::GetBounds() const {
  const auto bounds = path_.computeFiniteBounds().value_or(SkRect());
  return ImpellerRect{
      .x = bounds.x(),
      .y = bounds.y(),
      .width = bounds.width(),
      .height = bounds.height(),
  };
}

}  // namespace impeller::interop
