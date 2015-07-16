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

#ifndef SKY_ENGINE_PLATFORM_WIDGET_H_
#define SKY_ENGINE_PLATFORM_WIDGET_H_

#include "sky/engine/platform/PlatformExport.h"
#include "sky/engine/platform/geometry/FloatPoint.h"
#include "sky/engine/platform/geometry/IntRect.h"
#include "sky/engine/wtf/Forward.h"
#include "sky/engine/wtf/RefCounted.h"

namespace blink {

class Event;
class GraphicsContext;
class HostWindow;

// The Widget class serves as a base class for Scrollbar and FrameView.
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

    virtual bool isFrameView() const { return false; }

    virtual HostWindow* hostWindow() const { ASSERT_NOT_REACHED(); return 0; }
    Widget* parent() const { return m_parent; }
    Widget* root() const;

    // Virtual methods to convert points to/from the containing ScrollView
    virtual IntRect convertToContainingView(const IntRect& localRect) const { return localRect; }
    virtual IntRect convertFromContainingView(const IntRect& localRect) const { return localRect; }
    virtual IntPoint convertToContainingView(const IntPoint& localPoint) const  { return localPoint; }
    virtual IntPoint convertFromContainingView(const IntPoint& localPoint) const { return localPoint; }

private:
    Widget* m_parent;
    IntRect m_frame;
};

} // namespace blink

#endif  // SKY_ENGINE_PLATFORM_WIDGET_H_
