/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2004, 2005, 2006, 2009, 2010 Apple Inc. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 *
 */

#ifndef RenderWidget_h
#define RenderWidget_h

#include "core/rendering/RenderReplaced.h"
#include "platform/Widget.h"

namespace blink {

class RenderWidget : public RenderReplaced {
public:
    virtual ~RenderWidget();

    Widget* widget() const;

    void updateOnWidgetChange();
    void updateWidgetPosition();
    void widgetPositionsUpdated();

#if !ENABLE(OILPAN)
    void ref() { ++m_refCount; }
    void deref();
#endif
    virtual bool isWidget() const override final { return true; }
    bool updateWidgetGeometry();

protected:
    explicit RenderWidget(Element*);

    virtual void styleDidChange(StyleDifference, const RenderStyle* oldStyle) override final;
    virtual void layout() override;
    virtual void paint(PaintInfo&, const LayoutPoint&) override;
    virtual CursorDirective getCursor(const LayoutPoint&, Cursor&) const override final;
    virtual bool nodeAtPoint(const HitTestRequest&, HitTestResult&, const HitTestLocation& locationInContainer, const LayoutPoint& accumulatedOffset, HitTestAction) override;

    virtual void paintContents(PaintInfo&, const LayoutPoint&);

private:
    virtual void willBeDestroyed() override final;
    virtual void destroy() override final;

    bool setWidgetGeometry(const LayoutRect&);
#if !ENABLE(OILPAN)
    int m_refCount;
#endif
};

DEFINE_RENDER_OBJECT_TYPE_CASTS(RenderWidget, isWidget());

} // namespace blink

#endif // RenderWidget_h
