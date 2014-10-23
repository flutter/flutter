// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/animation/InterpolationEffect.h"

namespace blink {

PassOwnPtrWillBeRawPtr<WillBeHeapVector<RefPtrWillBeMember<Interpolation> > > InterpolationEffect::getActiveInterpolations(double fraction, double iterationDuration) const
{

    WillBeHeapVector<RefPtrWillBeMember<Interpolation> >* result = new WillBeHeapVector<RefPtrWillBeMember<Interpolation> >();

    for (size_t i = 0; i < m_interpolations.size(); ++i) {
        const InterpolationRecord* record = m_interpolations[i].get();
        if (fraction >= record->m_applyFrom && fraction < record->m_applyTo) {
            RefPtrWillBeRawPtr<Interpolation> interpolation = record->m_interpolation;
            double localFraction = (fraction - record->m_start) / (record->m_end - record->m_start);
            if (record->m_easing)
                localFraction = record->m_easing->evaluate(localFraction, accuracyForDuration(iterationDuration));
            interpolation->interpolate(0, localFraction);
            result->append(interpolation);
        }
    }

    return adoptPtrWillBeNoop(result);
}

void InterpolationEffect::InterpolationRecord::trace(Visitor* visitor)
{
    visitor->trace(m_interpolation);
}

void InterpolationEffect::trace(Visitor* visitor)
{
#if ENABLE_OILPAN
    visitor->trace(m_interpolations);
#endif
}

}
