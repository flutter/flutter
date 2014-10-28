/*
 * Copyright (C) 2004, 2005, 2006 Apple Computer, Inc.  All rights reserved.
 * Copyright (C) 2008 Collabora Ltd.  All rights reserved.
 * Copyright (C) 2013 Google Inc.  All rights reserved.
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

#ifndef Widget_h
#define Widget_h

#include "platform/PlatformExport.h"
#include "platform/geometry/FloatPoint.h"
#include "platform/geometry/IntRect.h"
#include "wtf/Forward.h"
#include "wtf/RefCounted.h"

namespace blink {

class Event;
class GraphicsContext;
class HostWindow;

// The Widget class serves as a base class for three kinds of objects:
// (1) Scrollable areas (ScrollView)
// (2) Scrollbars (Scrollbar)
// (3) Plugins (PluginView)
//
// Widgets are connected in a hierarchy, with the restriction that plugins and
// scrollbars are always leaves of the tree. Only ScrollViews can have children
// (and therefore the Widget class has no concept of children).
class PLATFORM_EXPORT Widget : public RefCounted<Widget> {
public:
    Widget();
    virtual ~Widget();

    int x() const { return frameRect().x(); }
    int y() const { return frameRect().y(); }
    int width() const { return frameRect().width(); }
    int height() const { return frameRect().height(); }
    IntSize size() const { return frameRect().size(); }
    IntPoint location() const { return frameRect().location(); }

    virtual void setFrameRect(const IntRect& frame) { m_frame = frame; }
    const IntRect& frameRect() const { return m_frame; }
    IntRect boundsRect() const { return IntRect(0, 0, width(),  height()); }

    void resize(int w, int h) { setFrameRect(IntRect(x(), y(), w, h)); }
    void resize(const IntSize& s) { setFrameRect(IntRect(location(), s)); }
    void move(int x, int y) { setFrameRect(IntRect(x, y, width(), height())); }
    void move(const IntPoint& p) { setFrameRect(IntRect(p, size())); }

    virtual void paint(GraphicsContext*, const IntRect&) { }
    void invalidate() { invalidateRect(boundsRect()); }
    virtual void invalidateRect(const IntRect&) = 0;

    bool isSelfVisible() const { return m_selfVisible; } // Whether or not we have been explicitly marked as visible or not.
    bool isParentVisible() const { return m_parentVisible; } // Whether or not our parent is visible.
    bool isVisible() const { return m_selfVisible && m_parentVisible; } // Whether or not we are actually visible.
    virtual void setParentVisible(bool visible) { m_parentVisible = visible; }
    void setSelfVisible(bool v) { m_selfVisible = v; }

    virtual bool isFrameView() const { return false; }
    virtual bool isScrollbar() const { return false; }
    virtual bool isScrollView() const { return false; }

    virtual HostWindow* hostWindow() const { ASSERT_NOT_REACHED(); return 0; }
    virtual void setParent(Widget*);
    Widget* parent() const { return m_parent; }
    Widget* root() const;

    virtual void handleEvent(Event*) { }

    IntRect convertToRootView(const IntRect&) const;
    IntRect convertFromRootView(const IntRect&) const;

    IntPoint convertToRootView(const IntPoint&) const;
    IntPoint convertFromRootView(const IntPoint&) const;

    // It is important for cross-platform code to realize that Mac has flipped coordinates. Therefore any code
    // that tries to convert the location of a rect using the point-based convertFromContainingWindow will end
    // up with an inaccurate rect. Always make sure to use the rect-based convertFromContainingWindow method
    // when converting window rects.
    IntRect convertToContainingWindow(const IntRect&) const;
    IntRect convertFromContainingWindow(const IntRect&) const;

    IntPoint convertToContainingWindow(const IntPoint&) const;
    IntPoint convertFromContainingWindow(const IntPoint&) const;
    FloatPoint convertFromContainingWindow(const FloatPoint&) const;

    // Virtual methods to convert points to/from the containing ScrollView
    virtual IntRect convertToContainingView(const IntRect&) const;
    virtual IntRect convertFromContainingView(const IntRect&) const;
    virtual IntPoint convertToContainingView(const IntPoint&) const;
    virtual IntPoint convertFromContainingView(const IntPoint&) const;

    // Virtual methods to convert points to/from child widgets
    virtual IntPoint convertChildToSelf(const Widget*, const IntPoint&) const;
    virtual IntPoint convertSelfToChild(const Widget*, const IntPoint&) const;

private:
    Widget* m_parent;
    IntRect m_frame;
    bool m_selfVisible;
    bool m_parentVisible;
};

} // namespace blink

#endif // Widget_h
