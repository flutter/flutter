/**
 * Copyright (C) 2003, 2006 Apple Computer, Inc.
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
 */

#ifndef EllipsisBox_h
#define EllipsisBox_h

#include "core/rendering/InlineBox.h"

namespace blink {

class HitTestRequest;
class HitTestResult;

class EllipsisBox FINAL : public InlineBox {
public:
    EllipsisBox(RenderObject& obj, const AtomicString& ellipsisStr, InlineFlowBox* parent,
        int width, int height, int x, int y, bool firstLine, bool isVertical, InlineBox* markupBox)
        : InlineBox(obj, FloatPoint(x, y), width, firstLine, true, false, false, isVertical, 0, 0, parent)
        , m_shouldPaintMarkupBox(markupBox)
        , m_height(height)
        , m_str(ellipsisStr)
        , m_selectionState(RenderObject::SelectionNone)
    {
        setHasVirtualLogicalHeight();
    }

    virtual void paint(PaintInfo&, const LayoutPoint&, LayoutUnit lineTop, LayoutUnit lineBottom) OVERRIDE;
    virtual bool nodeAtPoint(const HitTestRequest&, HitTestResult&, const HitTestLocation& locationInContainer, const LayoutPoint& accumulatedOffset, LayoutUnit lineTop, LayoutUnit lineBottom) OVERRIDE;
    void setSelectionState(RenderObject::SelectionState s) { m_selectionState = s; }
    IntRect selectionRect();

    virtual float virtualLogicalHeight() const OVERRIDE { return m_height; }
private:
    void paintMarkupBox(PaintInfo&, const LayoutPoint& paintOffset, LayoutUnit lineTop, LayoutUnit lineBottom, RenderStyle*);
    int height() const { return m_height; }
    virtual RenderObject::SelectionState selectionState() OVERRIDE { return m_selectionState; }
    void paintSelection(GraphicsContext*, const FloatPoint&, RenderStyle*, const Font&);
    InlineBox* markupBox() const;

    bool m_shouldPaintMarkupBox;
    int m_height;
    AtomicString m_str;
    RenderObject::SelectionState m_selectionState;
};

} // namespace blink

#endif // EllipsisBox_h
