/*
 * Copyright (C) 2004, 2006, 2008 Apple Inc. All rights reserved.
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

#include "config.h"
#include "platform/scroll/Scrollbar.h"

#include "platform/graphics/GraphicsContext.h"
#include "platform/PlatformGestureEvent.h"
#include "platform/PlatformMouseEvent.h"
#include "platform/scroll/ScrollableArea.h"
#include "platform/scroll/ScrollAnimator.h"
#include "platform/scroll/Scrollbar.h"
#include "public/platform/Platform.h"
#include "public/platform/WebPoint.h"
#include "public/platform/WebRect.h"
#include "public/platform/WebScrollbarBehavior.h"
#include "public/platform/WebThemeEngine.h"

#if ((OS(POSIX) && !OS(MACOSX)) || OS(WIN))
// The position of the scrollbar thumb affects the appearance of the steppers, so
// when the thumb moves, we have to invalidate them for painting.
#define THUMB_POSITION_AFFECTS_BUTTONS
#endif

namespace blink {

static const int kThumbThickness = 3;
static const int kScrollbarMargin = 3;

PassRefPtr<Scrollbar> Scrollbar::create(ScrollableArea* scrollableArea, ScrollbarOrientation orientation)
{
    return adoptRef(new Scrollbar(scrollableArea, orientation));
}

Scrollbar::Scrollbar(ScrollableArea* scrollableArea, ScrollbarOrientation orientation)
    : m_scrollableArea(scrollableArea)
    , m_orientation(orientation)
    , m_visibleSize(0)
    , m_totalSize(0)
    , m_currentPos(0)
    , m_dragOrigin(0)
    , m_hoveredPart(NoPart)
    , m_pressedPart(NoPart)
    , m_pressedPos(0)
    , m_scrollPos(0)
    , m_documentDragPos(0)
    , m_enabled(true)
    , m_scrollTimer(this, &Scrollbar::autoscrollTimerFired)
    , m_overlapsResizer(false)
{
    // FIXME: This is ugly and would not be necessary if we fix cross-platform code to actually query for
    // scrollbar thickness and use it when sizing scrollbars (rather than leaving one dimension of the scrollbar
    // alone when sizing).
    int thickness = scrollbarThickness();
    Widget::setFrameRect(IntRect(0, 0, thickness, thickness));

    m_currentPos = scrollableAreaCurrentPos();
}

Scrollbar::~Scrollbar()
{
    stopTimerIfNeeded();
}

ScrollbarOverlayStyle Scrollbar::scrollbarOverlayStyle() const
{
    return m_scrollableArea ? m_scrollableArea->scrollbarOverlayStyle() : ScrollbarOverlayStyleDefault;
}

bool Scrollbar::isScrollableAreaActive() const
{
    return m_scrollableArea && m_scrollableArea->isActive();
}

bool Scrollbar::isLeftSideVerticalScrollbar() const
{
    if (m_orientation == VerticalScrollbar && m_scrollableArea)
        return m_scrollableArea->shouldPlaceVerticalScrollbarOnLeft();
    return false;
}

void Scrollbar::offsetDidChange()
{
    ASSERT(m_scrollableArea);

    float position = scrollableAreaCurrentPos();
    if (position == m_currentPos)
        return;

    int oldThumbPosition = thumbPosition();
    m_currentPos = position;
    updateThumb();
    if (m_pressedPart == ThumbPart)
        setPressedPos(m_pressedPos + thumbPosition() - oldThumbPosition);
}

void Scrollbar::setProportion(int visibleSize, int totalSize)
{
    if (visibleSize == m_visibleSize && totalSize == m_totalSize)
        return;

    m_visibleSize = visibleSize;
    m_totalSize = totalSize;

    updateThumb();
}

void Scrollbar::updateThumb()
{
#ifdef THUMB_POSITION_AFFECTS_BUTTONS
    invalidate();
#else
    invalidateParts();
#endif
}

void Scrollbar::paint(GraphicsContext* context, const IntRect& damageRect)
{
    if (!frameRect().intersects(damageRect))
        return;

    IntRect startTrackRect;
    IntRect thumbRect;
    IntRect endTrackRect;
    splitTrack(trackRect(), startTrackRect, thumbRect, endTrackRect);
    if (damageRect.intersects(thumbRect))
        paintThumb(context, thumbRect);
}

void Scrollbar::autoscrollTimerFired(Timer<Scrollbar>*)
{
    autoscrollPressedPart(autoscrollTimerDelay());
}

static bool thumbUnderMouse(Scrollbar* scrollbar)
{
    int thumbPos = scrollbar->trackPosition() + scrollbar->thumbPosition();
    int thumbLength = scrollbar->thumbLength();
    return scrollbar->pressedPos() >= thumbPos && scrollbar->pressedPos() < thumbPos + thumbLength;
}

void Scrollbar::autoscrollPressedPart(double delay)
{
    // Don't do anything for the thumb or if nothing was pressed.
    if (m_pressedPart == ThumbPart || m_pressedPart == NoPart)
        return;

    // Handle the track.
    if ((m_pressedPart == BackTrackPart || m_pressedPart == ForwardTrackPart) && thumbUnderMouse(this)) {
        invalidatePart(m_pressedPart);
        setHoveredPart(ThumbPart);
        return;
    }

    // Handle the arrows and track.
    if (m_scrollableArea && m_scrollableArea->scroll(pressedPartScrollDirection(), pressedPartScrollGranularity()))
        startTimerIfNeeded(delay);
}

void Scrollbar::startTimerIfNeeded(double delay)
{
    // Don't do anything for the thumb.
    if (m_pressedPart == ThumbPart)
        return;

    // Handle the track.  We halt track scrolling once the thumb is level
    // with us.
    if ((m_pressedPart == BackTrackPart || m_pressedPart == ForwardTrackPart) && thumbUnderMouse(this)) {
        invalidatePart(m_pressedPart);
        setHoveredPart(ThumbPart);
        return;
    }

    // We can't scroll if we've hit the beginning or end.
    ScrollDirection dir = pressedPartScrollDirection();
    if (dir == ScrollUp || dir == ScrollLeft) {
        if (m_currentPos == 0)
            return;
    } else {
        if (m_currentPos == maximum())
            return;
    }

    m_scrollTimer.startOneShot(delay, FROM_HERE);
}

void Scrollbar::stopTimerIfNeeded()
{
    if (m_scrollTimer.isActive())
        m_scrollTimer.stop();
}

ScrollDirection Scrollbar::pressedPartScrollDirection()
{
    if (m_orientation == HorizontalScrollbar) {
        if (m_pressedPart == BackTrackPart)
            return ScrollLeft;
        return ScrollRight;
    } else {
        if (m_pressedPart == BackTrackPart)
            return ScrollUp;
        return ScrollDown;
    }
}

ScrollGranularity Scrollbar::pressedPartScrollGranularity()
{
    // FIXME(sky): Remove
    return ScrollByPage;
}

void Scrollbar::moveThumb(int pos)
{
    if (!m_scrollableArea)
        return;

    int delta = pos - m_pressedPos;

    // Drag the thumb.
    int thumbPos = thumbPosition();
    int thumbLen = thumbLength();
    int trackLen = trackLength();
    if (delta > 0)
        delta = std::min(trackLen - thumbLen - thumbPos, delta);
    else if (delta < 0)
        delta = std::max(-thumbPos, delta);

    float minPos = m_scrollableArea->minimumScrollPosition(m_orientation);
    float maxPos = m_scrollableArea->maximumScrollPosition(m_orientation);
    if (delta) {
        float newPosition = static_cast<float>(thumbPos + delta) * (maxPos - minPos) / (trackLen - thumbLen) + minPos;
        m_scrollableArea->scrollToOffsetWithoutAnimation(m_orientation, newPosition);
    }
}

void Scrollbar::setHoveredPart(ScrollbarPart part)
{
    if (part == m_hoveredPart)
        return;

    if (m_pressedPart == NoPart) {  // When there's a pressed part, we don't draw a hovered state, so there's no reason to invalidate.
        invalidatePart(part);
        invalidatePart(m_hoveredPart);
    }
    m_hoveredPart = part;
}

void Scrollbar::setPressedPart(ScrollbarPart part)
{
    if (m_pressedPart != NoPart)
        invalidatePart(m_pressedPart);
    m_pressedPart = part;
    if (m_pressedPart != NoPart)
        invalidatePart(m_pressedPart);
    else if (m_hoveredPart != NoPart)  // When we no longer have a pressed part, we can start drawing a hovered state on the hovered part.
        invalidatePart(m_hoveredPart);
}

bool Scrollbar::gestureEvent(const PlatformGestureEvent& evt)
{
    switch (evt.type()) {
    case PlatformEvent::GestureTapDown:
        // FIXME(sky): Is setting the pressed part needed since we only have overlay scrollbars?
        setPressedPart(NoPart);
        m_pressedPos = orientation() == HorizontalScrollbar ? convertFromContainingWindow(evt.position()).x() : convertFromContainingWindow(evt.position()).y();
        return true;
    case PlatformEvent::GestureTapDownCancel:
    case PlatformEvent::GestureScrollBegin:
        if (m_pressedPart != ThumbPart)
            return false;
        m_scrollPos = m_pressedPos;
        return true;
    case PlatformEvent::GestureScrollUpdate:
    case PlatformEvent::GestureScrollUpdateWithoutPropagation:
        if (m_pressedPart != ThumbPart)
            return false;
        m_scrollPos += orientation() == HorizontalScrollbar ? evt.deltaX() : evt.deltaY();
        moveThumb(m_scrollPos);
        return true;
    case PlatformEvent::GestureScrollEnd:
    case PlatformEvent::GestureLongPress:
    case PlatformEvent::GestureFlingStart:
        m_scrollPos = 0;
        m_pressedPos = 0;
        setPressedPart(NoPart);
        return false;
    case PlatformEvent::GestureTap: {
        if (m_pressedPart != ThumbPart && m_pressedPart != NoPart && m_scrollableArea
            && m_scrollableArea->scroll(pressedPartScrollDirection(), pressedPartScrollGranularity())) {
            return true;
        }
        m_scrollPos = 0;
        m_pressedPos = 0;
        setPressedPart(NoPart);
        return false;
    }
    default:
        // By default, we assume that gestures don't deselect the scrollbar.
        return true;
    }
}

void Scrollbar::mouseMoved(const PlatformMouseEvent& evt)
{
    if (m_pressedPart == ThumbPart) {
        if (shouldSnapBackToDragOrigin(evt)) {
            if (m_scrollableArea)
                m_scrollableArea->scrollToOffsetWithoutAnimation(m_orientation, m_dragOrigin + m_scrollableArea->minimumScrollPosition(m_orientation));
        } else {
            moveThumb(m_orientation == HorizontalScrollbar ?
                      convertFromContainingWindow(evt.position()).x() :
                      convertFromContainingWindow(evt.position()).y());
        }
        return;
    }

    if (m_pressedPart != NoPart)
        m_pressedPos = orientation() == HorizontalScrollbar ? convertFromContainingWindow(evt.position()).x() : convertFromContainingWindow(evt.position()).y();

    // FIXME(sky): Cleanup this code now that part is always NoPart.
    ScrollbarPart part = NoPart;
    if (part != m_hoveredPart) {
        if (m_pressedPart != NoPart) {
            if (part == m_pressedPart) {
                // The mouse is moving back over the pressed part.  We
                // need to start up the timer action again.
                startTimerIfNeeded(autoscrollTimerDelay());
                invalidatePart(m_pressedPart);
            } else if (m_hoveredPart == m_pressedPart) {
                // The mouse is leaving the pressed part.  Kill our timer
                // if needed.
                stopTimerIfNeeded();
                invalidatePart(m_pressedPart);
            }
        }

        setHoveredPart(part);
    }

    return;
}

void Scrollbar::mouseEntered()
{
    if (m_scrollableArea)
        m_scrollableArea->mouseEnteredScrollbar(this);
}

void Scrollbar::mouseExited()
{
    if (m_scrollableArea)
        m_scrollableArea->mouseExitedScrollbar(this);
    setHoveredPart(NoPart);
}

void Scrollbar::mouseUp(const PlatformMouseEvent& mouseEvent)
{
    setPressedPart(NoPart);
    m_pressedPos = 0;
    stopTimerIfNeeded();

    if (m_scrollableArea) {
        // m_hoveredPart won't be updated until the next mouseMoved or mouseDown, so we have to hit test
        // to really know if the mouse has exited the scrollbar on a mouseUp.
        m_scrollableArea->mouseExitedScrollbar(this);
    }
}

void Scrollbar::mouseDown(const PlatformMouseEvent& evt)
{
    // Early exit for right click
    if (evt.button() == RightButton)
        return;

    // FIXME(sky): Do we still need setPressedPart now that we only set it to NoPart?
    setPressedPart(NoPart);
    int pressedPos = orientation() == HorizontalScrollbar ? convertFromContainingWindow(evt.position()).x() : convertFromContainingWindow(evt.position()).y();

    if ((m_pressedPart == BackTrackPart || m_pressedPart == ForwardTrackPart) && shouldCenterOnThumb(evt)) {
        setHoveredPart(ThumbPart);
        setPressedPart(ThumbPart);
        m_dragOrigin = m_currentPos;
        int thumbLen = thumbLength();
        int desiredPos = pressedPos;
        // Set the pressed position to the middle of the thumb so that when we do the move, the delta
        // will be from the current pixel position of the thumb to the new desired position for the thumb.
        m_pressedPos = trackPosition() + thumbPosition() + thumbLen / 2;
        moveThumb(desiredPos);
        return;
    } else if (m_pressedPart == ThumbPart)
        m_dragOrigin = m_currentPos;

    m_pressedPos = pressedPos;

    autoscrollPressedPart(initialAutoscrollTimerDelay());
}

void Scrollbar::setEnabled(bool e)
{
    if (m_enabled == e)
        return;
    m_enabled = e;
    invalidate();
}

bool Scrollbar::isOverlayScrollbar() const
{
    // FIXME(sky): Remove
    return true;
}

bool Scrollbar::shouldParticipateInHitTesting()
{
    // Non-overlay scrollbars should always participate in hit testing.
    if (!isOverlayScrollbar())
        return true;
    return m_scrollableArea->scrollAnimator()->shouldScrollbarParticipateInHitTesting(this);
}

void Scrollbar::invalidateRect(const IntRect& rect)
{
    if (m_scrollableArea)
        m_scrollableArea->invalidateScrollbar(this, rect);
}

IntRect Scrollbar::convertToContainingView(const IntRect& localRect) const
{
    if (m_scrollableArea)
        return m_scrollableArea->convertFromScrollbarToContainingView(this, localRect);

    return Widget::convertToContainingView(localRect);
}

IntRect Scrollbar::convertFromContainingView(const IntRect& parentRect) const
{
    if (m_scrollableArea)
        return m_scrollableArea->convertFromContainingViewToScrollbar(this, parentRect);

    return Widget::convertFromContainingView(parentRect);
}

IntPoint Scrollbar::convertToContainingView(const IntPoint& localPoint) const
{
    if (m_scrollableArea)
        return m_scrollableArea->convertFromScrollbarToContainingView(this, localPoint);

    return Widget::convertToContainingView(localPoint);
}

IntPoint Scrollbar::convertFromContainingView(const IntPoint& parentPoint) const
{
    if (m_scrollableArea)
        return m_scrollableArea->convertFromContainingViewToScrollbar(this, parentPoint);

    return Widget::convertFromContainingView(parentPoint);
}

float Scrollbar::scrollableAreaCurrentPos() const
{
    if (!m_scrollableArea)
        return 0;

    if (m_orientation == HorizontalScrollbar)
        return m_scrollableArea->scrollPosition().x() - m_scrollableArea->minimumScrollPosition().x();

    return m_scrollableArea->scrollPosition().y() - m_scrollableArea->minimumScrollPosition().y();
}

int Scrollbar::scrollbarThickness()
{
    return kThumbThickness + kScrollbarMargin;
}

void Scrollbar::invalidatePart(ScrollbarPart part)
{
    if (part == NoPart)
        return;

    IntRect result;

    IntRect beforeThumbRect, thumbRect, afterThumbRect;
    splitTrack(trackRect(), beforeThumbRect, thumbRect, afterThumbRect);
    if (part == BackTrackPart)
        result = beforeThumbRect;
    else if (part == ForwardTrackPart)
        result = afterThumbRect;
    else
        result = thumbRect;

    result.moveBy(-location());
    invalidateRect(result);
}

void Scrollbar::paintScrollCorner(GraphicsContext* context, const IntRect& cornerRect)
{
    if (cornerRect.isEmpty())
        return;
    blink::Platform::current()->themeEngine()->paint(context->canvas(), blink::WebThemeEngine::PartScrollbarCorner, blink::WebThemeEngine::StateNormal, blink::WebRect(cornerRect), 0);
}

bool Scrollbar::shouldCenterOnThumb(const PlatformMouseEvent& evt)
{
    return blink::Platform::current()->scrollbarBehavior()->shouldCenterOnThumb(static_cast<blink::WebScrollbarBehavior::Button>(evt.button()), evt.shiftKey(), evt.altKey());
}

bool Scrollbar::shouldSnapBackToDragOrigin(const PlatformMouseEvent& evt)
{
    IntPoint mousePosition = convertFromContainingWindow(evt.position());
    mousePosition.move(x(), y());
    return blink::Platform::current()->scrollbarBehavior()->shouldSnapBackToDragOrigin(mousePosition, trackRect(), orientation() == HorizontalScrollbar);
}

int Scrollbar::thumbPosition()
{
    if (!totalSize())
        return 0;

    int trackLen = trackLength();
    float proportion = static_cast<float>(currentPos()) / totalSize();
    return round(proportion * trackLen);
}

int Scrollbar::thumbLength()
{
    int trackLen = trackLength();

    if (!totalSize())
        return trackLen;

    float proportion = static_cast<float>(visibleSize()) / totalSize();
    int length = round(proportion * trackLen);
    length = std::min(std::max(length, minimumThumbLength()), trackLen);
    return length;
}

int Scrollbar::trackPosition()
{
    IntRect rect = trackRect();
    return (orientation() == HorizontalScrollbar) ? rect.x() - x() : rect.y() - y();
}

int Scrollbar::trackLength()
{
    IntRect rect = trackRect();
    return (orientation() == HorizontalScrollbar) ? rect.width() : rect.height();
}

IntRect Scrollbar::trackRect()
{
    IntRect rect = frameRect();
    if (orientation() == HorizontalScrollbar)
        rect.inflateX(-kScrollbarMargin);
    else
        rect.inflateY(-kScrollbarMargin);
    return rect;
}

IntRect Scrollbar::thumbRect()
{
    IntRect track = trackRect();
    IntRect startTrackRect;
    IntRect thumbRect;
    IntRect endTrackRect;
    splitTrack(track, startTrackRect, thumbRect, endTrackRect);

    return thumbRect;
}

int Scrollbar::thumbThickness()
{
    return kThumbThickness;
}

int Scrollbar::minimumThumbLength()
{
    return scrollbarThickness();
}

void Scrollbar::splitTrack(const IntRect& trackRect, IntRect& beforeThumbRect, IntRect& thumbRect, IntRect& afterThumbRect)
{
    // This function won't even get called unless we're big enough to have some combination of these three rects where at least
    // one of them is non-empty.
    int thumbPos = thumbPosition();
    if (orientation() == HorizontalScrollbar) {
        thumbRect = IntRect(trackRect.x() + thumbPos, trackRect.y(), thumbLength(), height());
        beforeThumbRect = IntRect(trackRect.x(), trackRect.y(), thumbPos + thumbRect.width() / 2, trackRect.height());
        afterThumbRect = IntRect(trackRect.x() + beforeThumbRect.width(), trackRect.y(), trackRect.maxX() - beforeThumbRect.maxX(), trackRect.height());
    } else {
        thumbRect = IntRect(trackRect.x(), trackRect.y() + thumbPos, width(), thumbLength());
        beforeThumbRect = IntRect(trackRect.x(), trackRect.y(), trackRect.width(), thumbPos + thumbRect.height() / 2);
        afterThumbRect = IntRect(trackRect.x(), trackRect.y() + beforeThumbRect.height(), trackRect.width(), trackRect.maxY() - beforeThumbRect.maxY());
    }
}

void Scrollbar::paintThumb(GraphicsContext* context, const IntRect& rect)
{
    // FIXME(sky): This function appears to be dead code.
    IntRect thumbRect = rect;
    if (orientation() == HorizontalScrollbar) {
        thumbRect.setHeight(thumbRect.height() - kScrollbarMargin);
    } else {
        thumbRect.setWidth(thumbRect.width() - kScrollbarMargin);
        if (isLeftSideVerticalScrollbar())
            thumbRect.setX(thumbRect.x() + kScrollbarMargin);
    }

    DEFINE_STATIC_LOCAL(Color, color, (128, 128, 128, 128));
    context->fillRect(thumbRect, color);
}

} // namespace blink
