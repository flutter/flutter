// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/animation/SampledEffect.h"

#include "core/animation/StyleInterpolation.h"

namespace blink {

SampledEffect::SampledEffect(Animation* animation, PassOwnPtrWillBeRawPtr<WillBeHeapVector<RefPtrWillBeMember<Interpolation> > > interpolations)
    : m_animation(animation)
#if !ENABLE(OILPAN)
    , m_player(animation->player())
#endif
    , m_interpolations(interpolations)
    , m_sequenceNumber(animation->player()->sequenceNumber())
    , m_priority(animation->priority())
{
    ASSERT(m_interpolations && !m_interpolations->isEmpty());
}

bool SampledEffect::canChange() const
{
#if ENABLE(OILPAN)
    return m_animation;
#else
    if (!m_animation)
        return false;
    // FIXME: This check won't be needed when Animation and AnimationPlayer are moved to Oilpan.
    return !m_player->canFree();
#endif
}

void SampledEffect::clear()
{
#if !ENABLE(OILPAN)
    m_player = nullptr;
#endif
    m_animation = nullptr;
    m_interpolations->clear();
}

void SampledEffect::removeReplacedInterpolationsIfNeeded(const BitArray<numCSSProperties>& replacedProperties)
{
    if (canChange() && m_animation->isCurrent())
        return;

    size_t dest = 0;
    for (size_t i = 0; i < m_interpolations->size(); i++) {
        if (!replacedProperties.get(toStyleInterpolation(m_interpolations->at(i).get())->id()))
            m_interpolations->at(dest++) = m_interpolations->at(i);
    }
    m_interpolations->shrink(dest);
}

void SampledEffect::trace(Visitor* visitor)
{
    visitor->trace(m_animation);
#if ENABLE(OILPAN)
    visitor->trace(m_interpolations);
#endif
}

} // namespace blink
