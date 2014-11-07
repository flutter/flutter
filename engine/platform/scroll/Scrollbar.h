/*
 * Copyright (C) 2004, 2006 Apple Computer, Inc.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef Scrollbar_h
#define Scrollbar_h

#include "platform/Timer.h"
#include "platform/Widget.h"
#include "platform/scroll/ScrollTypes.h"
#include "platform/scroll/Scrollbar.h"
#include "wtf/MathExtras.h"
#include "wtf/PassRefPtr.h"

namespace blink {

class GraphicsContext;
class IntRect;
class PlatformGestureEvent;
class PlatformMouseEvent;
class ScrollableArea;

class PLATFORM_EXPORT Scrollbar final : public Widget {
public:
    static PassRefPtr<Scrollbar> create(ScrollableArea*, ScrollbarOrientation);

    virtual ~Scrollbar();

    void invalidateRect(const IntRect&);

    ScrollbarOverlayStyle scrollbarOverlayStyle() const;
    bool isScrollableAreaActive() const;

    ScrollbarOrientation orientation() const { return m_orientation; }
    bool isLeftSideVerticalScrollbar() const;

    int value() const { return lroundf(m_currentPos); }
    float currentPos() const { return m_currentPos; }
    int visibleSize() const { return m_visibleSize; }
    int totalSize() const { return m_totalSize; }
    int maximum() const { return m_totalSize - m_visibleSize; }

    ScrollbarPart pressedPart() const { return m_pressedPart; }
    ScrollbarPart hoveredPart() const { return m_hoveredPart; }

    bool enabled() const { return m_enabled; }
    void setEnabled(bool);

    // Called by the ScrollableArea when the scroll offset changes.
    void offsetDidChange();

    void disconnectFromScrollableArea() { m_scrollableArea = 0; }
    ScrollableArea* scrollableArea() const { return m_scrollableArea; }

    int pressedPos() const { return m_pressedPos; }

    void setHoveredPart(ScrollbarPart);
    void setPressedPart(ScrollbarPart);

    void setProportion(int visibleSize, int totalSize);
    void setPressedPos(int p) { m_pressedPos = p; }

    virtual void paint(GraphicsContext*, const IntRect& damageRect) override;

    bool isOverlayScrollbar() const;
    bool shouldParticipateInHitTesting();

    bool gestureEvent(const PlatformGestureEvent&);

    // These methods are used for platform scrollbars to give :hover feedback.  They will not get called
    // when the mouse went down in a scrollbar, since it is assumed the scrollbar will start
    // grabbing all events in that case anyway.
    void mouseMoved(const PlatformMouseEvent&);
    void mouseEntered();
    void mouseExited();

    // Used by some platform scrollbars to know when they've been released from capture.
    void mouseUp(const PlatformMouseEvent&);
    void mouseDown(const PlatformMouseEvent&);

    virtual IntRect convertToContainingView(const IntRect&) const override;
    virtual IntRect convertFromContainingView(const IntRect&) const override;

    virtual IntPoint convertToContainingView(const IntPoint&) const override;
    virtual IntPoint convertFromContainingView(const IntPoint&) const override;

    void moveThumb(int pos);

    static int scrollbarThickness();

    void invalidateParts()
    {
        invalidatePart(BackTrackPart);
        invalidatePart(ThumbPart);
        invalidatePart(ForwardTrackPart);
    }

    void invalidatePart(ScrollbarPart);

    bool shouldCenterOnThumb(const PlatformMouseEvent&);
    bool shouldSnapBackToDragOrigin(const PlatformMouseEvent&);

    // The position of the thumb relative to the track.
    int thumbPosition();
    // The length of the thumb along the axis of the scrollbar.
    int thumbLength();
    // The position of the track relative to the scrollbar.
    int trackPosition();
    // The length of the track along the axis of the scrollbar.
    int trackLength();

    IntRect trackRect();
    IntRect thumbRect();
    int thumbThickness();

    int minimumThumbLength();

    void splitTrack(const IntRect& track, IntRect& startTrack, IntRect& thumb, IntRect& endTrack);

    void paintThumb(GraphicsContext*, const IntRect&);

    double initialAutoscrollTimerDelay() { return 0.25; }
    double autoscrollTimerDelay() { return 0.05; }

protected:
    Scrollbar(ScrollableArea*, ScrollbarOrientation);

    void updateThumb();

    void autoscrollTimerFired(Timer<Scrollbar>*);
    void startTimerIfNeeded(double delay);
    void stopTimerIfNeeded();
    void autoscrollPressedPart(double delay);
    ScrollDirection pressedPartScrollDirection();
    ScrollGranularity pressedPartScrollGranularity();

    ScrollableArea* m_scrollableArea;
    ScrollbarOrientation m_orientation;

    int m_visibleSize;
    int m_totalSize;
    float m_currentPos;
    float m_dragOrigin;

    ScrollbarPart m_hoveredPart;
    ScrollbarPart m_pressedPart;
    int m_pressedPos;
    float m_scrollPos;
    int m_documentDragPos;

    bool m_enabled;

    Timer<Scrollbar> m_scrollTimer;
    bool m_overlapsResizer;

private:
    virtual bool isScrollbar() const override { return true; }

    float scrollableAreaCurrentPos() const;
};

DEFINE_TYPE_CASTS(Scrollbar, Widget, widget, widget->isScrollbar(), widget.isScrollbar());

} // namespace blink

#endif // Scrollbar_h
