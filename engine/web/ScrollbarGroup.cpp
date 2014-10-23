/*
 * Copyright (C) 2011 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "web/ScrollbarGroup.h"

#include "core/frame/FrameView.h"
#include "platform/scroll/Scrollbar.h"
#include "platform/scroll/Scrollbar.h"
#include "public/platform/WebRect.h"

namespace blink {

ScrollbarGroup::ScrollbarGroup(FrameView* frameView, const IntRect& frameRect)
    : m_frameRect(frameRect)
{
}

ScrollbarGroup::~ScrollbarGroup()
{
}

void ScrollbarGroup::setLastMousePosition(const IntPoint& point)
{
    m_lastMousePosition = point;
}

int ScrollbarGroup::scrollSize(ScrollbarOrientation orientation) const
{
    return 0;
}

void ScrollbarGroup::setScrollOffset(const IntPoint& offset)
{
}

void ScrollbarGroup::invalidateScrollbarRect(Scrollbar* scrollbar, const IntRect& rect)
{
}

void ScrollbarGroup::invalidateScrollCornerRect(const IntRect&)
{
}

bool ScrollbarGroup::isActive() const
{
    return true;
}

void ScrollbarGroup::setFrameRect(const IntRect& frameRect)
{
    m_frameRect = frameRect;
}

IntRect ScrollbarGroup::scrollableAreaBoundingBox() const
{
    return m_frameRect;
}

bool ScrollbarGroup::isScrollCornerVisible() const
{
    return false;
}

void ScrollbarGroup::getTickmarks(Vector<IntRect>& tickmarks) const
{
}

IntPoint ScrollbarGroup::convertFromContainingViewToScrollbar(const Scrollbar* scrollbar, const IntPoint& parentPoint) const
{
    return IntPoint();
}

Scrollbar* ScrollbarGroup::horizontalScrollbar() const
{
    return 0;
}

Scrollbar* ScrollbarGroup::verticalScrollbar() const
{
    return 0;
}

IntPoint ScrollbarGroup::scrollPosition() const
{
    return IntPoint();
}

IntPoint ScrollbarGroup::minimumScrollPosition() const
{
    return IntPoint();
}

IntPoint ScrollbarGroup::maximumScrollPosition() const
{
    return IntPoint(contentsSize().width() - visibleWidth(), contentsSize().height() - visibleHeight());
}

int ScrollbarGroup::visibleHeight() const
{
    return 0;
}

int ScrollbarGroup::visibleWidth() const
{
    return 0;
}

IntSize ScrollbarGroup::contentsSize() const
{
    return IntSize();
}

IntSize ScrollbarGroup::overhangAmount() const
{
    return IntSize();
}

IntPoint ScrollbarGroup::lastKnownMousePosition() const
{
    return m_lastMousePosition;
}

bool ScrollbarGroup::scrollbarsCanBeActive() const
{
    return true;
}

bool ScrollbarGroup::userInputScrollable(ScrollbarOrientation orientation) const
{
    return false;
}

bool ScrollbarGroup::shouldPlaceVerticalScrollbarOnLeft() const
{
    return false;
}

int ScrollbarGroup::pageStep(ScrollbarOrientation orientation) const
{
    return 1;
}

} // namespace blink
