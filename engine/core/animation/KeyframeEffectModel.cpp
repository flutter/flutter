/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "core/animation/KeyframeEffectModel.h"

#include "core/StylePropertyShorthand.h"
#include "core/animation/AnimationNode.h"
#include "platform/geometry/FloatBox.h"
#include "platform/transforms/TransformationMatrix.h"
#include "wtf/text/StringHash.h"

namespace blink {

PropertySet KeyframeEffectModelBase::properties() const
{
    PropertySet result;
    if (!m_keyframes.size()) {
        return result;
    }
    result = m_keyframes[0]->properties();
    for (size_t i = 1; i < m_keyframes.size(); i++) {
        PropertySet extras = m_keyframes[i]->properties();
        for (PropertySet::const_iterator it = extras.begin(); it != extras.end(); ++it) {
            result.add(*it);
        }
    }
    return result;
}

PassOwnPtrWillBeRawPtr<WillBeHeapVector<RefPtrWillBeMember<Interpolation> > > KeyframeEffectModelBase::sample(int iteration, double fraction, double iterationDuration) const
{
    ASSERT(iteration >= 0);
    ASSERT(!isNull(fraction));
    ensureKeyframeGroups();
    ensureInterpolationEffect();

    return m_interpolationEffect->getActiveInterpolations(fraction, iterationDuration);
}

KeyframeEffectModelBase::KeyframeVector KeyframeEffectModelBase::normalizedKeyframes(const KeyframeVector& keyframes)
{
    double lastOffset = 0;
    KeyframeVector result;
    result.reserveCapacity(keyframes.size());

    for (size_t i = 0; i < keyframes.size(); ++i) {
        double offset = keyframes[i]->offset();
        if (!isNull(offset)) {
            ASSERT(offset >= 0);
            ASSERT(offset <= 1);
            ASSERT(offset >= lastOffset);
            lastOffset = offset;
        }
        result.append(keyframes[i]->clone());
    }

    if (result.isEmpty()) {
        return result;
    }

    if (isNull(result.last()->offset()))
        result.last()->setOffset(1);

    if (result.size() > 1 && isNull(result[0]->offset()))
        result[0]->setOffset(0);

    size_t lastIndex = 0;
    lastOffset = result[0]->offset();
    for (size_t i = 1; i < result.size(); ++i) {
        double offset = result[i]->offset();
        if (!isNull(offset)) {
            for (size_t j = 1; j < i - lastIndex; ++j)
                result[lastIndex + j]->setOffset(lastOffset + (offset - lastOffset) * j / (i - lastIndex));
            lastIndex = i;
            lastOffset = offset;
        }
    }

    return result;
}


void KeyframeEffectModelBase::ensureKeyframeGroups() const
{
    if (m_keyframeGroups)
        return;

    m_keyframeGroups = adoptPtrWillBeNoop(new KeyframeGroupMap);
    const KeyframeVector keyframes = normalizedKeyframes(getFrames());
    for (KeyframeVector::const_iterator keyframeIter = keyframes.begin(); keyframeIter != keyframes.end(); ++keyframeIter) {
        const Keyframe* keyframe = keyframeIter->get();
        PropertySet keyframeProperties = keyframe->properties();
        for (PropertySet::const_iterator propertyIter = keyframeProperties.begin(); propertyIter != keyframeProperties.end(); ++propertyIter) {
            CSSPropertyID property = *propertyIter;
            ASSERT_WITH_MESSAGE(!isExpandedShorthand(property), "Web Animations: Encountered shorthand CSS property (%d) in normalized keyframes.", property);
            KeyframeGroupMap::iterator groupIter = m_keyframeGroups->find(property);
            PropertySpecificKeyframeGroup* group;
            if (groupIter == m_keyframeGroups->end())
                group = m_keyframeGroups->add(property, adoptPtrWillBeNoop(new PropertySpecificKeyframeGroup)).storedValue->value.get();
            else
                group = groupIter->value.get();

            group->appendKeyframe(keyframe->createPropertySpecificKeyframe(property));
        }
    }

    // Add synthetic keyframes.
    for (KeyframeGroupMap::iterator iter = m_keyframeGroups->begin(); iter != m_keyframeGroups->end(); ++iter) {
        iter->value->addSyntheticKeyframeIfRequired(this);
        iter->value->removeRedundantKeyframes();
    }
}

void KeyframeEffectModelBase::ensureInterpolationEffect(Element* element) const
{
    if (m_interpolationEffect)
        return;
    m_interpolationEffect = InterpolationEffect::create();

    for (KeyframeGroupMap::const_iterator iter = m_keyframeGroups->begin(); iter != m_keyframeGroups->end(); ++iter) {
        const PropertySpecificKeyframeVector& keyframes = iter->value->keyframes();
        ASSERT(keyframes[0]->composite() == AnimationEffect::CompositeReplace);
        for (size_t i = 0; i < keyframes.size() - 1; i++) {
            ASSERT(keyframes[i + 1]->composite() == AnimationEffect::CompositeReplace);
            double applyFrom = i ? keyframes[i]->offset() : (-std::numeric_limits<double>::infinity());
            double applyTo = i == keyframes.size() - 2 ? std::numeric_limits<double>::infinity() : keyframes[i + 1]->offset();
            if (applyTo == 1)
                applyTo = std::numeric_limits<double>::infinity();

            m_interpolationEffect->addInterpolation(keyframes[i]->createInterpolation(iter->key, keyframes[i + 1].get(), element),
                &keyframes[i]->easing(), keyframes[i]->offset(), keyframes[i + 1]->offset(), applyFrom, applyTo);
        }
    }
}

bool KeyframeEffectModelBase::isReplaceOnly()
{
    ensureKeyframeGroups();
    for (KeyframeGroupMap::iterator iter = m_keyframeGroups->begin(); iter != m_keyframeGroups->end(); ++iter) {
        const PropertySpecificKeyframeVector& keyframeVector = iter->value->keyframes();
        for (size_t i = 0; i < keyframeVector.size(); ++i) {
            if (keyframeVector[i]->composite() != AnimationEffect::CompositeReplace)
                return false;
        }
    }
    return true;
}

void KeyframeEffectModelBase::trace(Visitor* visitor)
{
    visitor->trace(m_keyframes);
    visitor->trace(m_interpolationEffect);
#if ENABLE_OILPAN
    visitor->trace(m_keyframeGroups);
#endif
    AnimationEffect::trace(visitor);
}

Keyframe::PropertySpecificKeyframe::PropertySpecificKeyframe(double offset, PassRefPtr<TimingFunction> easing, AnimationEffect::CompositeOperation composite)
    : m_offset(offset)
    , m_easing(easing)
    , m_composite(composite)
{
}

void KeyframeEffectModelBase::PropertySpecificKeyframeGroup::appendKeyframe(PassOwnPtrWillBeRawPtr<Keyframe::PropertySpecificKeyframe> keyframe)
{
    ASSERT(m_keyframes.isEmpty() || m_keyframes.last()->offset() <= keyframe->offset());
    m_keyframes.append(keyframe);
}

void KeyframeEffectModelBase::PropertySpecificKeyframeGroup::removeRedundantKeyframes()
{
    // As an optimization, removes keyframes in the following categories, as
    // they will never be used by sample().
    // - End keyframes with the same offset as their neighbor
    // - Interior keyframes with the same offset as both their neighbors
    // Note that synthetic keyframes must be added before this method is
    // called.
    ASSERT(m_keyframes.size() >= 2);
    for (int i = m_keyframes.size() - 1; i >= 0; --i) {
        double offset = m_keyframes[i]->offset();
        bool hasSameOffsetAsPreviousNeighbor = !i || m_keyframes[i - 1]->offset() == offset;
        bool hasSameOffsetAsNextNeighbor = i == static_cast<int>(m_keyframes.size() - 1) || m_keyframes[i + 1]->offset() == offset;
        if (hasSameOffsetAsPreviousNeighbor && hasSameOffsetAsNextNeighbor)
            m_keyframes.remove(i);
    }
    ASSERT(m_keyframes.size() >= 2);
}

void KeyframeEffectModelBase::PropertySpecificKeyframeGroup::addSyntheticKeyframeIfRequired(const KeyframeEffectModelBase* context)
{
    ASSERT(!m_keyframes.isEmpty());
    if (m_keyframes.first()->offset() != 0.0)
        m_keyframes.insert(0, m_keyframes.first()->neutralKeyframe(0, nullptr));
    if (m_keyframes.last()->offset() != 1.0)
        appendKeyframe(m_keyframes.last()->neutralKeyframe(1, nullptr));
}

void KeyframeEffectModelBase::PropertySpecificKeyframeGroup::trace(Visitor* visitor)
{
#if ENABLE(OILPAN)
    visitor->trace(m_keyframes);
#endif
}

} // namespace
