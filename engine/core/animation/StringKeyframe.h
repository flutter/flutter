// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef StringKeyframe_h
#define StringKeyframe_h

#include "core/animation/Keyframe.h"
#include "core/css/StylePropertySet.h"

namespace blink {

class StyleSheetContents;

class StringKeyframe : public Keyframe {
public:
    static PassRefPtrWillBeRawPtr<StringKeyframe> create()
    {
        return adoptRefWillBeNoop(new StringKeyframe);
    }
    void setPropertyValue(CSSPropertyID, const String& value, StyleSheetContents*);
    void clearPropertyValue(CSSPropertyID property) { m_propertySet->removeProperty(property); }
    CSSValue* propertyValue(CSSPropertyID property) const
    {
        int index = m_propertySet->findPropertyIndex(property);
        RELEASE_ASSERT(index >= 0);
        return m_propertySet->propertyAt(static_cast<unsigned>(index)).value();
    }
    virtual PropertySet properties() const OVERRIDE;

    virtual void trace(Visitor*) OVERRIDE;

    class PropertySpecificKeyframe : public Keyframe::PropertySpecificKeyframe {
    public:
        PropertySpecificKeyframe(double offset, PassRefPtr<TimingFunction> easing, CSSValue*, AnimationEffect::CompositeOperation);

        CSSValue* value() const { return m_value.get(); }
        virtual const PassRefPtrWillBeRawPtr<AnimatableValue> getAnimatableValue() const OVERRIDE FINAL {
            return m_animatableValueCache.get();
        }

        virtual PassOwnPtrWillBeRawPtr<Keyframe::PropertySpecificKeyframe> neutralKeyframe(double offset, PassRefPtr<TimingFunction> easing) const OVERRIDE FINAL;
        virtual PassRefPtrWillBeRawPtr<Interpolation> createInterpolation(CSSPropertyID, blink::Keyframe::PropertySpecificKeyframe* end, Element*) const OVERRIDE FINAL;

        virtual void trace(Visitor*) OVERRIDE;

    private:
        PropertySpecificKeyframe(double offset, PassRefPtr<TimingFunction> easing, CSSValue*);

        virtual PassOwnPtrWillBeRawPtr<Keyframe::PropertySpecificKeyframe> cloneWithOffset(double offset) const;
        virtual bool isStringPropertySpecificKeyframe() const OVERRIDE { return true; }

        RefPtrWillBeMember<CSSValue> m_value;
        mutable RefPtrWillBeMember<AnimatableValue> m_animatableValueCache;
    };

private:
    StringKeyframe()
        : m_propertySet(MutableStylePropertySet::create())
    { }

    StringKeyframe(const StringKeyframe& copyFrom);

    virtual PassRefPtrWillBeRawPtr<Keyframe> clone() const OVERRIDE;
    virtual PassOwnPtrWillBeRawPtr<Keyframe::PropertySpecificKeyframe> createPropertySpecificKeyframe(CSSPropertyID) const OVERRIDE;

    virtual bool isStringKeyframe() const OVERRIDE { return true; }

    RefPtrWillBeMember<MutableStylePropertySet> m_propertySet;
};

typedef StringKeyframe::PropertySpecificKeyframe StringPropertySpecificKeyframe;

DEFINE_TYPE_CASTS(StringKeyframe, Keyframe, value, value->isStringKeyframe(), value.isStringKeyframe());
DEFINE_TYPE_CASTS(StringPropertySpecificKeyframe, Keyframe::PropertySpecificKeyframe, value, value->isStringPropertySpecificKeyframe(), value.isStringPropertySpecificKeyframe());

}

#endif
