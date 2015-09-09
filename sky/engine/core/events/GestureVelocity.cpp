// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/events/GestureVelocity.h"

namespace blink {

GestureVelocity::GestureVelocity(bool valid, float x, float y)
    : m_is_valid(valid), m_x(x), m_y(y)
{
}

} // namespace blink
