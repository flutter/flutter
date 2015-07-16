// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/events/touchscreen_device.h"

namespace ui {

// static
const int TouchscreenDevice::kInvalidId = 0;

TouchscreenDevice::TouchscreenDevice(int id,
                                     const gfx::Size& size,
                                     bool is_internal)
    : id(id), size(size), is_internal(is_internal) {
}

}  // namespace ui
