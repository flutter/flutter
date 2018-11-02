// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/window/pointer_data.h"

#include <string.h>

namespace blink {

// If this value changes, update the pointer data unpacking code in hooks.dart.
static constexpr int kPointerDataFieldCount = 21;

static_assert(sizeof(PointerData) == sizeof(int64_t) * kPointerDataFieldCount,
              "PointerData has the wrong size");

void PointerData::Clear() {
  memset(this, 0, sizeof(PointerData));
}

}  // namespace blink
