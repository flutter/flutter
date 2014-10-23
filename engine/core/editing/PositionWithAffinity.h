// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file./*

#ifndef PositionWithAffinity_h
#define PositionWithAffinity_h

#include "core/dom/Position.h"
#include "core/editing/TextAffinity.h"

namespace blink {

class PositionWithAffinity {
    DISALLOW_ALLOCATION();
public:
    PositionWithAffinity(const Position&, EAffinity = DOWNSTREAM);
    PositionWithAffinity();
    ~PositionWithAffinity();

    EAffinity affinity() const { return m_affinity; }
    const Position& position() const { return m_position; }

    void trace(Visitor*);

private:
    Position m_position;
    EAffinity m_affinity;
};

} // namespace blink

#endif // PositionWithAffinity_h
