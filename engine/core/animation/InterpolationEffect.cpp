// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/animation/InterpolationEffect.h"

namespace blink {

PassOwnPtr<Vector<RefPtr<Interpolation> > > InterpolationEffect::getActiveInterpolations(double fraction, double iterationDuration) const
{

    Vector<RefPtr<Interpolation> >* result = new Vector<RefPtr<Interpolation> >();

    for (size_t i = 0; i < m_interpolations.size(); ++i) {
        const InterpolationRecord* record = m_interpolations[i].get();
        if (fraction >= record->m_applyFrom && fraction < record->m_applyTo) {
            RefPtr<Interpolation> interpolation = record->m_interpolation;
            double localFraction = (fraction - record->m_start) / (record->m_end - record->m_start);
            if (record->m_easing)
                localFraction = record->m_easing->evaluate(localFraction, accuracyForDuration(iterationDuration));
            interpolation->interpolate(0, localFraction);
            result->append(interpolation);
        }
    }

    return adoptPtr(result);
}

}
