// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "third_party/skia/include/core/SkMatrix.h"
#include "third_party/skia/include/core/SkRRect.h"

namespace Skwasm {

inline SkMatrix createMatrix(const SkScalar* f) {
  return SkMatrix::MakeAll(f[0], f[1], f[2], f[3], f[4], f[5], f[6], f[7],
                           f[8]);
}

inline SkRRect createRRect(const SkScalar* f) {
  const SkScalar* twelveFloats = reinterpret_cast<const SkScalar*>(f);
  const SkRect* rect = reinterpret_cast<const SkRect*>(twelveFloats);
  const SkVector* radiiValues =
      reinterpret_cast<const SkVector*>(twelveFloats + 4);

  SkRRect rr;
  rr.setRectRadii(*rect, radiiValues);
  return rr;
}

}  // namespace Skwasm
