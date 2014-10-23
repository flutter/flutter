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

#ifndef ScrollbarGroup_h
#define ScrollbarGroup_h

#include "platform/scroll/ScrollableArea.h"

#include "wtf/RefPtr.h"

namespace blink {

class FrameView;

class ScrollbarGroup FINAL : public ScrollableArea {
public:
    ScrollbarGroup(FrameView*, const IntRect& frameRect);
    virtual ~ScrollbarGroup();

    void setLastMousePosition(const IntPoint&);
    void setFrameRect(const IntRect&);

    // ScrollableArea methods
    virtual int scrollSize(ScrollbarOrientation) const OVERRIDE;
    virtual void setScrollOffset(const IntPoint&) OVERRIDE;
    virtual void invalidateScrollbarRect(Scrollbar*, const IntRect&) OVERRIDE;
    virtual void invalidateScrollCornerRect(const IntRect&) OVERRIDE;
    virtual bool isActive() const OVERRIDE;
    virtual IntRect scrollCornerRect() const OVERRIDE { return IntRect(); }
    virtual bool isScrollCornerVisible() const OVERRIDE;
    virtual void getTickmarks(Vector<IntRect>&) const OVERRIDE;
    virtual IntPoint convertFromContainingViewToScrollbar(const Scrollbar*, const IntPoint& parentPoint) const OVERRIDE;
    virtual Scrollbar* horizontalScrollbar() const OVERRIDE;
    virtual Scrollbar* verticalScrollbar() const OVERRIDE;
    virtual IntPoint scrollPosition() const OVERRIDE;
    virtual IntPoint minimumScrollPosition() const OVERRIDE;
    virtual IntPoint maximumScrollPosition() const OVERRIDE;
    virtual int visibleHeight() const OVERRIDE;
    virtual int visibleWidth() const OVERRIDE;
    virtual IntSize contentsSize() const OVERRIDE;
    virtual IntSize overhangAmount() const OVERRIDE;
    virtual IntPoint lastKnownMousePosition() const OVERRIDE;
    virtual bool scrollbarsCanBeActive() const OVERRIDE;
    virtual IntRect scrollableAreaBoundingBox() const OVERRIDE;
    virtual bool userInputScrollable(ScrollbarOrientation) const OVERRIDE;
    virtual bool shouldPlaceVerticalScrollbarOnLeft() const OVERRIDE;
    virtual int pageStep(ScrollbarOrientation) const OVERRIDE;

private:
    IntPoint m_lastMousePosition;
    IntRect m_frameRect;
};

} // namespace blink

#endif
