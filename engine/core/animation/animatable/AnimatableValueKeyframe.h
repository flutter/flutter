// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef AnimatableValueKeyframe_h
#define AnimatableValueKeyframe_h

#include "core/animation/Keyframe.h"
#include "core/animation/animatable/AnimatableValue.h"

namespace blink {

class AnimatableValueKeyframe : public Keyframe {
public:
    static PassRefPtrWillBeRawPtr<AnimatableValueKeyframe> create()
    {
        return adoptRefWillBeNoop(new AnimatableValueKeyframe);
    }
    void setPropertyValue(CSSPropertyID property, PassRefPtrWillBeRawPtr<AnimatableValue> value)
    {
        m_propertyValues.add(property, value);
    }
    void clearPropertyValue(CSSPropertyID property) { m_propertyValues.remove(property); }
    AnimatableValue* propertyValue(CSSPropertyID property) const
    {
        ASSERT(m_propertyValues.contains(property));
        return m_propertyValues.get(property);
    }
    virtual PropertySet properties() const override;

    virtual void trace(Visitor*) override;

    class PropertySpecificKeyframe : public Keyframe::PropertySpecificKeyframe {
    public:
        PropertySpecificKeyframe(double offset, PassRefPtr<TimingFunction> easing, const AnimatableValue*, AnimationEffect::CompositeOperation);

        AnimatableValue* value() const { return m_value.get(); }
        virtual const PassRefPtrWillBeRawPtr<AnimatableValue> getAnimatableValue() const override final { return m_value; }

        virtual PassOwnPtrWillBeRawPtr<Keyframe::PropertySpecificKeyframe> neutralKeyframe(double offset, PassRefPtr<TimingFunction> easing) const override final;
        virtual PassRefPtrWillBeRawPtr<Interpolation> createInterpolation(CSSPropertyID, blink::Keyframe::PropertySpecificKeyframe* end, Element*) const override final;

        virtual void trace(Visitor*) override;

    private:
        PropertySpecificKeyframe(double offset, PassRefPtr<TimingFunction> easing, PassRefPtrWillBeRawPtr<AnimatableValue>);

        virtual PassOwnPtrWillBeRawPtr<Keyframe::PropertySpecificKeyframe> cloneWithOffset(double offset) const override;
        virtual bool isAnimatableValuePropertySpecificKeyframe() const override { return true; }

        RefPtrWillBeMember<AnimatableValue> m_value;
    };

private:
    AnimatableValueKeyframe() { }

    AnimatableValueKeyframe(const AnimatableValueKeyframe& copyFrom);

    virtual PassRefPtrWillBeRawPtr<Keyframe> clone() const override;
    virtual PassOwnPtrWillBeRawPtr<Keyframe::PropertySpecificKeyframe> createPropertySpecificKeyframe(CSSPropertyID) const override;

    virtual bool isAnimatableValueKeyframe() const override { return true; }

    typedef WillBeHeapHashMap<CSSPropertyID, RefPtrWillBeMember<AnimatableValue> > PropertyValueMap;
    PropertyValueMap m_propertyValues;
};

typedef AnimatableValueKeyframe::PropertySpecificKeyframe AnimatableValuePropertySpecificKeyframe;

DEFINE_TYPE_CASTS(AnimatableValueKeyframe, Keyframe, value, value->isAnimatableValueKeyframe(), value.isAnimatableValueKeyframe());
DEFINE_TYPE_CASTS(AnimatableValuePropertySpecificKeyframe, Keyframe::PropertySpecificKeyframe, value, value->isAnimatableValuePropertySpecificKeyframe(), value.isAnimatableValuePropertySpecificKeyframe());

}

#endif
