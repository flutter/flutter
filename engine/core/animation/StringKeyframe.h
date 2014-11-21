// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef StringKeyframe_h
#define StringKeyframe_h

#include "sky/engine/core/animation/Keyframe.h"
#include "sky/engine/core/css/StylePropertySet.h"

namespace blink {

class StyleSheetContents;

class StringKeyframe : public Keyframe {
public:
    static PassRefPtr<StringKeyframe> create()
    {
        return adoptRef(new StringKeyframe);
    }
    void setPropertyValue(CSSPropertyID, const String& value, StyleSheetContents*);
    void clearPropertyValue(CSSPropertyID property) { m_propertySet->removeProperty(property); }
    CSSValue* propertyValue(CSSPropertyID property) const
    {
        int index = m_propertySet->findPropertyIndex(property);
        RELEASE_ASSERT(index >= 0);
        return m_propertySet->propertyAt(static_cast<unsigned>(index)).value();
    }
    virtual PropertySet properties() const override;

    class PropertySpecificKeyframe : public Keyframe::PropertySpecificKeyframe {
    public:
        PropertySpecificKeyframe(double offset, PassRefPtr<TimingFunction> easing, CSSValue*, AnimationEffect::CompositeOperation);

        CSSValue* value() const { return m_value.get(); }
        virtual const PassRefPtr<AnimatableValue> getAnimatableValue() const override final {
            return m_animatableValueCache.get();
        }

        virtual PassOwnPtr<Keyframe::PropertySpecificKeyframe> neutralKeyframe(double offset, PassRefPtr<TimingFunction> easing) const override final;
        virtual PassRefPtr<Interpolation> createInterpolation(CSSPropertyID, blink::Keyframe::PropertySpecificKeyframe* end, Element*) const override final;

    private:
        PropertySpecificKeyframe(double offset, PassRefPtr<TimingFunction> easing, CSSValue*);

        virtual PassOwnPtr<Keyframe::PropertySpecificKeyframe> cloneWithOffset(double offset) const;
        virtual bool isStringPropertySpecificKeyframe() const override { return true; }

        RefPtr<CSSValue> m_value;
        mutable RefPtr<AnimatableValue> m_animatableValueCache;
    };

private:
    StringKeyframe()
        : m_propertySet(MutableStylePropertySet::create())
    { }

    StringKeyframe(const StringKeyframe& copyFrom);

    virtual PassRefPtr<Keyframe> clone() const override;
    virtual PassOwnPtr<Keyframe::PropertySpecificKeyframe> createPropertySpecificKeyframe(CSSPropertyID) const override;

    virtual bool isStringKeyframe() const override { return true; }

    RefPtr<MutableStylePropertySet> m_propertySet;
};

typedef StringKeyframe::PropertySpecificKeyframe StringPropertySpecificKeyframe;

DEFINE_TYPE_CASTS(StringKeyframe, Keyframe, value, value->isStringKeyframe(), value.isStringKeyframe());
DEFINE_TYPE_CASTS(StringPropertySpecificKeyframe, Keyframe::PropertySpecificKeyframe, value, value->isStringPropertySpecificKeyframe(), value.isStringPropertySpecificKeyframe());

}

#endif
