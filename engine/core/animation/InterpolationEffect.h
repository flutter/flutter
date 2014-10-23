// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef InterpolationEffect_h
#define InterpolationEffect_h

#include "core/animation/Interpolation.h"
#include "platform/animation/TimingFunction.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/RefCounted.h"

namespace blink {

class InterpolationEffect : public RefCountedWillBeGarbageCollected<InterpolationEffect> {
public:
    static PassRefPtrWillBeRawPtr<InterpolationEffect> create() { return adoptRefWillBeNoop(new InterpolationEffect()); }

    PassOwnPtrWillBeRawPtr<WillBeHeapVector<RefPtrWillBeMember<Interpolation> > > getActiveInterpolations(double fraction, double iterationDuration) const;

    void addInterpolation(PassRefPtrWillBeRawPtr<Interpolation> interpolation, PassRefPtr<TimingFunction> easing, double start, double end, double applyFrom, double applyTo)
    {
        m_interpolations.append(InterpolationRecord::create(interpolation, easing, start, end, applyFrom, applyTo));
    }

    void trace(Visitor*);

private:
    InterpolationEffect()
    {
    }

    class InterpolationRecord : public NoBaseWillBeGarbageCollectedFinalized<InterpolationRecord> {
    public:
        RefPtrWillBeMember<Interpolation> m_interpolation;
        RefPtr<TimingFunction> m_easing;
        double m_start;
        double m_end;
        double m_applyFrom;
        double m_applyTo;

        static PassOwnPtrWillBeRawPtr<InterpolationRecord> create(PassRefPtrWillBeRawPtr<Interpolation> interpolation, PassRefPtr<TimingFunction> easing, double start, double end, double applyFrom, double applyTo)
        {
            return adoptPtrWillBeNoop(new InterpolationRecord(interpolation, easing, start, end, applyFrom, applyTo));
        }

        void trace(Visitor*);

    private:
        InterpolationRecord(PassRefPtrWillBeRawPtr<Interpolation> interpolation, PassRefPtr<TimingFunction> easing, double start, double end, double applyFrom, double applyTo)
            : m_interpolation(interpolation)
            , m_easing(easing)
            , m_start(start)
            , m_end(end)
            , m_applyFrom(applyFrom)
            , m_applyTo(applyTo)
        {
        }
    };

    WillBeHeapVector<OwnPtrWillBeMember<InterpolationRecord> > m_interpolations;
};

}

#endif
