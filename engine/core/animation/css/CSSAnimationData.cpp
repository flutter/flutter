// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/animation/css/CSSAnimationData.h"

#include "core/animation/Timing.h"

namespace blink {

CSSAnimationData::CSSAnimationData()
{
    m_nameList.append(initialName());
    m_iterationCountList.append(initialIterationCount());
    m_directionList.append(initialDirection());
    m_fillModeList.append(initialFillMode());
    m_playStateList.append(initialPlayState());
}

CSSAnimationData::CSSAnimationData(const CSSAnimationData& other)
    : CSSTimingData(other)
    , m_nameList(other.m_nameList)
    , m_iterationCountList(other.m_iterationCountList)
    , m_directionList(other.m_directionList)
    , m_fillModeList(other.m_fillModeList)
    , m_playStateList(other.m_playStateList)
{
}

const AtomicString& CSSAnimationData::initialName()
{
    DEFINE_STATIC_LOCAL(const AtomicString, name, ("none", AtomicString::ConstructFromLiteral));
    return name;
}

bool CSSAnimationData::animationsMatchForStyleRecalc(const CSSAnimationData& other) const
{
    return m_nameList == other.m_nameList && m_playStateList == other.m_playStateList;
}

Timing CSSAnimationData::convertToTiming(size_t index) const
{
    ASSERT(index < m_nameList.size());
    Timing timing = CSSTimingData::convertToTiming(index);

    timing.iterationCount = getRepeated(m_iterationCountList, index);
    timing.direction = getRepeated(m_directionList, index);
    timing.fillMode = getRepeated(m_fillModeList, index);
    timing.assertValid();
    return timing;
}

} // namespace blink
