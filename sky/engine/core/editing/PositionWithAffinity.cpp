// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/sky/engine/core/editing/PositionWithAffinity.h"

namespace blink {

PositionWithAffinity::PositionWithAffinity(RenderObject* renderer,
                                           int offset,
                                           EAffinity affinity)
    : m_renderer(renderer), m_offset(offset), m_affinity(affinity) {}

PositionWithAffinity::~PositionWithAffinity() {}

}  // namespace blink
