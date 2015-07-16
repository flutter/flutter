// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gfx/geometry/rect_conversions.h"

#include <algorithm>
#include <cmath>

#include "base/logging.h"
#include "ui/gfx/geometry/safe_integer_conversions.h"

namespace gfx {

Rect ToEnclosingRect(const RectF& rect) {
  int min_x = ToFlooredInt(rect.x());
  int min_y = ToFlooredInt(rect.y());
  float max_x = rect.right();
  float max_y = rect.bottom();
  int width = rect.width() == 0 ? 0 : std::max(ToCeiledInt(max_x) - min_x, 0);
  int height = rect.height() == 0 ? 0 : std::max(ToCeiledInt(max_y) - min_y, 0);
  return Rect(min_x, min_y, width, height);
}

Rect ToEnclosedRect(const RectF& rect) {
  int min_x = ToCeiledInt(rect.x());
  int min_y = ToCeiledInt(rect.y());
  float max_x = rect.right();
  float max_y = rect.bottom();
  int width = std::max(ToFlooredInt(max_x) - min_x, 0);
  int height = std::max(ToFlooredInt(max_y) - min_y, 0);
  return Rect(min_x, min_y, width, height);
}

Rect ToNearestRect(const RectF& rect) {
  float float_min_x = rect.x();
  float float_min_y = rect.y();
  float float_max_x = rect.right();
  float float_max_y = rect.bottom();

  int min_x = ToRoundedInt(float_min_x);
  int min_y = ToRoundedInt(float_min_y);
  int max_x = ToRoundedInt(float_max_x);
  int max_y = ToRoundedInt(float_max_y);

  // If these DCHECKs fail, you're using the wrong method, consider using
  // ToEnclosingRect or ToEnclosedRect instead.
  DCHECK(std::abs(min_x - float_min_x) < 0.01f);
  DCHECK(std::abs(min_y - float_min_y) < 0.01f);
  DCHECK(std::abs(max_x - float_max_x) < 0.01f);
  DCHECK(std::abs(max_y - float_max_y) < 0.01f);

  return Rect(min_x, min_y, max_x - min_x, max_y - min_y);
}

bool IsNearestRectWithinDistance(const gfx::RectF& rect, float distance) {
  float float_min_x = rect.x();
  float float_min_y = rect.y();
  float float_max_x = rect.right();
  float float_max_y = rect.bottom();

  int min_x = ToRoundedInt(float_min_x);
  int min_y = ToRoundedInt(float_min_y);
  int max_x = ToRoundedInt(float_max_x);
  int max_y = ToRoundedInt(float_max_y);

  return
      (std::abs(min_x - float_min_x) < distance) &&
      (std::abs(min_y - float_min_y) < distance) &&
      (std::abs(max_x - float_max_x) < distance) &&
      (std::abs(max_y - float_max_y) < distance);
}

Rect ToFlooredRectDeprecated(const RectF& rect) {
  return Rect(ToFlooredInt(rect.x()),
              ToFlooredInt(rect.y()),
              ToFlooredInt(rect.width()),
              ToFlooredInt(rect.height()));
}

}  // namespace gfx

