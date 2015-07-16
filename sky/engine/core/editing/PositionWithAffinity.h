// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file./*

#ifndef SKY_ENGINE_CORE_EDITING_POSITIONWITHAFFINITY_H_
#define SKY_ENGINE_CORE_EDITING_POSITIONWITHAFFINITY_H_

#include "sky/engine/core/dom/Position.h"
#include "sky/engine/core/editing/TextAffinity.h"

namespace blink {

class PositionWithAffinity {
    DISALLOW_ALLOCATION();
public:
    PositionWithAffinity(const Position&, EAffinity = DOWNSTREAM);
    PositionWithAffinity();
    ~PositionWithAffinity();

    EAffinity affinity() const { return m_affinity; }
    const Position& position() const { return m_position; }

private:
    Position m_position;
    EAffinity m_affinity;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_EDITING_POSITIONWITHAFFINITY_H_
