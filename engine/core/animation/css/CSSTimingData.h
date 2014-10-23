// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef CSSTimingData_h
#define CSSTimingData_h

#include "platform/animation/TimingFunction.h"
#include "platform/heap/Handle.h"
#include "wtf/Vector.h"

namespace blink {

struct Timing;

class CSSTimingData : public NoBaseWillBeGarbageCollectedFinalized<CSSTimingData> {
public:
    ~CSSTimingData() { }

    void trace(Visitor*) { }

    const Vector<double>& delayList() const { return m_delayList; }
    const Vector<double>& durationList() const { return m_durationList; }
    const Vector<RefPtr<TimingFunction> >& timingFunctionList() const { return m_timingFunctionList; }

    Vector<double>& delayList() { return m_delayList; }
    Vector<double>& durationList() { return m_durationList; }
    Vector<RefPtr<TimingFunction> >& timingFunctionList() { return m_timingFunctionList; }

    static double initialDelay() { return 0; }
    static double initialDuration() { return 0; }
    static PassRefPtr<TimingFunction> initialTimingFunction() { return CubicBezierTimingFunction::preset(CubicBezierTimingFunction::Ease); }

    template <class T> static const T& getRepeated(const Vector<T>& v, size_t index) { return v[index % v.size()]; }

protected:
    CSSTimingData();
    explicit CSSTimingData(const CSSTimingData&);

    Timing convertToTiming(size_t index) const;

private:
    Vector<double> m_delayList;
    Vector<double> m_durationList;
    Vector<RefPtr<TimingFunction> > m_timingFunctionList;
};

} // namespace blink

#endif // CSSTimingData_h
