// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/window/pointer_data.h"

namespace blink {

// If this value changes, update the pointer data unpacking code in hooks.dart.
static constexpr int kPointerDataFieldCount = 19;

static_assert(sizeof(PointerData) == sizeof(int64_t) * kPointerDataFieldCount,
              "PointerData has the wrong size");

void PointerData::Clear() {
  time_stamp = 0;
  pointer = 0;
  change = Change::kCancel;
  kind = DeviceKind::kTouch;
  physical_x = 0.0;
  physical_y = 0.0;
  buttons = 0;
  obscured = 0;
  pressure = 0.0;
  pressure_min = 0.0;
  pressure_max = 0.0;
  distance = 0.0;
  distance_max = 0.0;
  radius_major = 0.0;
  radius_minor = 0.0;
  radius_min = 0.0;
  radius_max = 0.0;
  orientation = 0.0;
  tilt = 0.0;
}

}  // namespace blink
