// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gfx/geometry/vector2d_conversions.h"

#include "ui/gfx/geometry/safe_integer_conversions.h"

namespace gfx {

Vector2d ToFlooredVector2d(const Vector2dF& vector2d) {
  int x = ToFlooredInt(vector2d.x());
  int y = ToFlooredInt(vector2d.y());
  return Vector2d(x, y);
}

Vector2d ToCeiledVector2d(const Vector2dF& vector2d) {
  int x = ToCeiledInt(vector2d.x());
  int y = ToCeiledInt(vector2d.y());
  return Vector2d(x, y);
}

Vector2d ToRoundedVector2d(const Vector2dF& vector2d) {
  int x = ToRoundedInt(vector2d.x());
  int y = ToRoundedInt(vector2d.y());
  return Vector2d(x, y);
}

}  // namespace gfx

