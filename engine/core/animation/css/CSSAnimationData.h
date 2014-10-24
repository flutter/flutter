// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef CSSAnimationData_h
#define CSSAnimationData_h

#include "core/animation/Timing.h"
#include "core/animation/css/CSSTimingData.h"
#include "core/rendering/style/RenderStyleConstants.h"

namespace blink {

class CSSAnimationData final : public CSSTimingData {
public:
    static PassOwnPtrWillBeRawPtr<CSSAnimationData> create()
    {
        return adoptPtrWillBeNoop(new CSSAnimationData);
    }

    static PassOwnPtrWillBeRawPtr<CSSAnimationData> create(const CSSAnimationData& animationData)
    {
        return adoptPtrWillBeNoop(new CSSAnimationData(animationData));
    }

    bool animationsMatchForStyleRecalc(const CSSAnimationData& other) const;

    Timing convertToTiming(size_t index) const;

    const Vector<AtomicString>& nameList() const { return m_nameList; }
    const Vector<double>& iterationCountList() const { return m_iterationCountList; }
    const Vector<Timing::PlaybackDirection>& directionList() const { return m_directionList; }
    const Vector<Timing::FillMode>& fillModeList() const { return m_fillModeList; }
    const Vector<EAnimPlayState>& playStateList() const { return m_playStateList; }

    Vector<AtomicString>& nameList() { return m_nameList; }
    Vector<double>& iterationCountList() { return m_iterationCountList; }
    Vector<Timing::PlaybackDirection>& directionList() { return m_directionList; }
    Vector<Timing::FillMode>& fillModeList() { return m_fillModeList; }
    Vector<EAnimPlayState>& playStateList() { return m_playStateList; }

    static const AtomicString& initialName();
    static Timing::PlaybackDirection initialDirection() { return Timing::PlaybackDirectionNormal; }
    static Timing::FillMode initialFillMode() { return Timing::FillModeNone; }
    static double initialIterationCount() { return 1.0; }
    static EAnimPlayState initialPlayState() { return AnimPlayStatePlaying; }

private:
    CSSAnimationData();
    explicit CSSAnimationData(const CSSAnimationData&);

    Vector<AtomicString> m_nameList;
    Vector<double> m_iterationCountList;
    Vector<Timing::PlaybackDirection> m_directionList;
    Vector<Timing::FillMode> m_fillModeList;
    Vector<EAnimPlayState> m_playStateList;
};

} // namespace blink

#endif // CSSAnimationData_h
