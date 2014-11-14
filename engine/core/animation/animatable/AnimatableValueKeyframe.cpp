// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/animation/animatable/AnimatableValueKeyframe.h"

#include "core/animation/LegacyStyleInterpolation.h"

namespace blink {

AnimatableValueKeyframe::AnimatableValueKeyframe(const AnimatableValueKeyframe& copyFrom)
    : Keyframe(copyFrom.m_offset, copyFrom.m_composite, copyFrom.m_easing)
{
    for (PropertyValueMap::const_iterator iter = copyFrom.m_propertyValues.begin(); iter != copyFrom.m_propertyValues.end(); ++iter)
        setPropertyValue(iter->key, iter->value.get());
}

PropertySet AnimatableValueKeyframe::properties() const
{
    // This is not used in time-critical code, so we probably don't need to
    // worry about caching this result.
    PropertySet properties;
    for (PropertyValueMap::const_iterator iter = m_propertyValues.begin(); iter != m_propertyValues.end(); ++iter)
        properties.add(*iter.keys());
    return properties;
}

PassRefPtr<Keyframe> AnimatableValueKeyframe::clone() const
{
    return adoptRef(new AnimatableValueKeyframe(*this));
}

PassOwnPtr<Keyframe::PropertySpecificKeyframe> AnimatableValueKeyframe::createPropertySpecificKeyframe(CSSPropertyID property) const
{
    return adoptPtr(new PropertySpecificKeyframe(offset(), &easing(), propertyValue(property), composite()));
}

AnimatableValueKeyframe::PropertySpecificKeyframe::PropertySpecificKeyframe(double offset, PassRefPtr<TimingFunction> easing, const AnimatableValue* value, AnimationEffect::CompositeOperation op)
    : Keyframe::PropertySpecificKeyframe(offset, easing, op)
    , m_value(const_cast<AnimatableValue*>(value))
{ }

AnimatableValueKeyframe::PropertySpecificKeyframe::PropertySpecificKeyframe(double offset, PassRefPtr<TimingFunction> easing, PassRefPtr<AnimatableValue> value)
    : Keyframe::PropertySpecificKeyframe(offset, easing, AnimationEffect::CompositeReplace)
    , m_value(value)
{
    ASSERT(!isNull(m_offset));
}

PassOwnPtr<Keyframe::PropertySpecificKeyframe> AnimatableValueKeyframe::PropertySpecificKeyframe::cloneWithOffset(double offset) const
{
    Keyframe::PropertySpecificKeyframe* theClone = new PropertySpecificKeyframe(offset, m_easing, m_value);
    return adoptPtr(theClone);
}

PassRefPtr<Interpolation> AnimatableValueKeyframe::PropertySpecificKeyframe::createInterpolation(CSSPropertyID property, Keyframe::PropertySpecificKeyframe* end, Element*) const
{
    AnimatableValuePropertySpecificKeyframe* to = toAnimatableValuePropertySpecificKeyframe(end);
    return LegacyStyleInterpolation::create(value(), to->value(), property);
}

PassOwnPtr<Keyframe::PropertySpecificKeyframe> AnimatableValueKeyframe::PropertySpecificKeyframe::neutralKeyframe(double offset, PassRefPtr<TimingFunction> easing) const
{
    return adoptPtr(new AnimatableValueKeyframe::PropertySpecificKeyframe(offset, easing, AnimatableValue::neutralValue(), AnimationEffect::CompositeAdd));
}

}
