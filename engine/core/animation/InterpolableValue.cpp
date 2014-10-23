// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/animation/InterpolableValue.h"

namespace blink {

DEFINE_EMPTY_DESTRUCTOR_WILL_BE_REMOVED(InterpolableValue);

PassOwnPtrWillBeRawPtr<InterpolableValue> InterpolableNumber::interpolate(const InterpolableValue &to, const double progress) const
{
    const InterpolableNumber& toNumber = toInterpolableNumber(to);
    if (!progress)
        return create(m_value);
    if (progress == 1)
        return create(toNumber.m_value);
    return create(m_value * (1 - progress) + toNumber.m_value * progress);
}

PassOwnPtrWillBeRawPtr<InterpolableValue> InterpolableBool::interpolate(const InterpolableValue &to, const double progress) const
{
    if (progress < 0.5) {
        return clone();
    }
    return to.clone();
}

PassOwnPtrWillBeRawPtr<InterpolableValue> InterpolableList::interpolate(const InterpolableValue &to, const double progress) const
{
    const InterpolableList& toList = toInterpolableList(to);
    ASSERT(toList.m_size == m_size);

    if (!progress) {
        return create(*this);
    }
    if (progress == 1) {
        return InterpolableList::create(toList);
    }

    OwnPtrWillBeRawPtr<InterpolableList> result = create(m_size);
    for (size_t i = 0; i < m_size; i++) {
        ASSERT(m_values[i]);
        ASSERT(toList.m_values[i]);
        result->set(i, m_values[i]->interpolate(*(toList.m_values[i]), progress));
    }
    return result.release();
}

void InterpolableList::trace(Visitor* visitor)
{
#if ENABLE_OILPAN
    visitor->trace(m_values);
#endif
    InterpolableValue::trace(visitor);
}

PassOwnPtrWillBeRawPtr<InterpolableValue> InterpolableAnimatableValue::interpolate(const InterpolableValue &other, const double percentage) const
{
    const InterpolableAnimatableValue& otherValue = toInterpolableAnimatableValue(other);
    if (!percentage)
        return create(m_value);
    if (percentage == 1)
        return create(otherValue.m_value);
    return create(AnimatableValue::interpolate(m_value.get(), otherValue.m_value.get(), percentage));
}

void InterpolableAnimatableValue::trace(Visitor* visitor)
{
    visitor->trace(m_value);
    InterpolableValue::trace(visitor);
}

}
