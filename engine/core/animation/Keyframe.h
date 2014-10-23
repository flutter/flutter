// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef Keyframe_h
#define Keyframe_h

#include "core/CSSPropertyNames.h"
#include "core/animation/AnimationEffect.h"
#include "core/animation/AnimationNode.h"
#include "core/animation/animatable/AnimatableValue.h"

namespace blink {

typedef HashSet<CSSPropertyID> PropertySet;

class Element;

// FIXME: Make Keyframe immutable
class Keyframe : public RefCountedWillBeGarbageCollectedFinalized<Keyframe> {
public:
    virtual ~Keyframe() { }

    void setOffset(double offset) { m_offset = offset; }
    double offset() const { return m_offset; }

    void setComposite(AnimationEffect::CompositeOperation composite) { m_composite = composite; }
    AnimationEffect::CompositeOperation composite() const { return m_composite; }

    void setEasing(PassRefPtr<TimingFunction> easing) { m_easing = easing; }
    TimingFunction& easing() const { return *m_easing; }

    static bool compareOffsets(const RefPtrWillBeMember<Keyframe>& a, const RefPtrWillBeMember<Keyframe>& b)
    {
        return a->offset() < b->offset();
    }

    virtual PropertySet properties() const = 0;

    virtual PassRefPtrWillBeRawPtr<Keyframe> clone() const = 0;
    PassRefPtrWillBeRawPtr<Keyframe> cloneWithOffset(double offset) const
    {
        RefPtrWillBeRawPtr<Keyframe> theClone = clone();
        theClone->setOffset(offset);
        return theClone.release();
    }

    virtual bool isAnimatableValueKeyframe() const { return false; }
    virtual bool isStringKeyframe() const { return false; }

    virtual void trace(Visitor*) { }

    class PropertySpecificKeyframe : public NoBaseWillBeGarbageCollectedFinalized<PropertySpecificKeyframe> {
    public:
        virtual ~PropertySpecificKeyframe() { }
        double offset() const { return m_offset; }
        TimingFunction& easing() const { return *m_easing; }
        AnimationEffect::CompositeOperation composite() const { return m_composite; }
        virtual PassOwnPtrWillBeRawPtr<PropertySpecificKeyframe> cloneWithOffset(double offset) const = 0;

        virtual const PassRefPtrWillBeRawPtr<AnimatableValue> getAnimatableValue() const = 0;

        virtual bool isAnimatableValuePropertySpecificKeyframe() const { return false; }
        virtual bool isStringPropertySpecificKeyframe() const { return false; }

        virtual PassOwnPtrWillBeRawPtr<PropertySpecificKeyframe> neutralKeyframe(double offset, PassRefPtr<TimingFunction> easing) const = 0;
        virtual PassRefPtrWillBeRawPtr<Interpolation> createInterpolation(CSSPropertyID, blink::Keyframe::PropertySpecificKeyframe* end, Element*) const = 0;

        virtual void trace(Visitor*) { }

    protected:
        PropertySpecificKeyframe(double offset, PassRefPtr<TimingFunction> easing, AnimationEffect::CompositeOperation);

        double m_offset;
        RefPtr<TimingFunction> m_easing;
        AnimationEffect::CompositeOperation m_composite;
    };

    virtual PassOwnPtrWillBeRawPtr<PropertySpecificKeyframe> createPropertySpecificKeyframe(CSSPropertyID) const = 0;

protected:
    Keyframe()
        : m_offset(nullValue())
        , m_composite(AnimationEffect::CompositeReplace)
        , m_easing(LinearTimingFunction::shared())
    {
    }
    Keyframe(double offset, AnimationEffect::CompositeOperation composite, PassRefPtr<TimingFunction> easing)
        : m_offset(offset)
        , m_composite(composite)
        , m_easing(easing)
    {
    }

    double m_offset;
    AnimationEffect::CompositeOperation m_composite;
    RefPtr<TimingFunction> m_easing;
};

}

#endif
