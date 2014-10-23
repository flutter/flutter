/*
 * (C) 1999 Lars Knoll (knoll@kde.org)
 * (C) 2000 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2004, 2005, 2006, 2009, 2010, 2011 Apple Inc. All rights reserved.
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

#ifndef InlineTextBox_h
#define InlineTextBox_h

#include "core/rendering/InlineBox.h"
#include "core/rendering/RenderText.h" // so textRenderer() can be inline
#include "platform/text/TextRun.h"
#include "wtf/Forward.h"

namespace blink {

struct CompositionUnderline;
class DocumentMarker;
class GraphicsContext;

const unsigned short cNoTruncation = USHRT_MAX;
const unsigned short cFullTruncation = USHRT_MAX - 1;

class InlineTextBox : public InlineBox {
public:
    InlineTextBox(RenderObject& obj)
        : InlineBox(obj)
        , m_prevTextBox(0)
        , m_nextTextBox(0)
        , m_start(0)
        , m_len(0)
        , m_truncation(cNoTruncation)
    {
    }

    RenderText& renderer() const { return toRenderText(InlineBox::renderer()); }

    virtual void destroy() OVERRIDE FINAL;

    InlineTextBox* prevTextBox() const { return m_prevTextBox; }
    InlineTextBox* nextTextBox() const { return m_nextTextBox; }
    void setNextTextBox(InlineTextBox* n) { m_nextTextBox = n; }
    void setPreviousTextBox(InlineTextBox* p) { m_prevTextBox = p; }

    // FIXME: These accessors should ASSERT(!isDirty()). See https://bugs.webkit.org/show_bug.cgi?id=97264
    unsigned start() const { return m_start; }
    unsigned end() const { return m_len ? m_start + m_len - 1 : m_start; }
    unsigned len() const { return m_len; }

    void setStart(unsigned start) { m_start = start; }
    void setLen(unsigned len) { m_len = len; }

    void offsetRun(int d) { ASSERT(!isDirty()); m_start += d; }

    unsigned short truncation() { return m_truncation; }

    virtual void markDirty() OVERRIDE FINAL;

    using InlineBox::hasHyphen;
    using InlineBox::setHasHyphen;
    using InlineBox::canHaveLeadingExpansion;
    using InlineBox::setCanHaveLeadingExpansion;

    static inline bool compareByStart(const InlineTextBox* first, const InlineTextBox* second) { return first->start() < second->start(); }

    virtual int baselinePosition(FontBaseline) const OVERRIDE FINAL;
    virtual LayoutUnit lineHeight() const OVERRIDE FINAL;

    bool getEmphasisMarkPosition(RenderStyle*, TextEmphasisPosition&) const;

    LayoutRect logicalOverflowRect() const;
    void setLogicalOverflowRect(const LayoutRect&);
    LayoutUnit logicalTopVisualOverflow() const { return logicalOverflowRect().y(); }
    LayoutUnit logicalBottomVisualOverflow() const { return logicalOverflowRect().maxY(); }

#ifndef NDEBUG
    virtual void showBox(int = 0) const OVERRIDE;
    virtual const char* boxName() const OVERRIDE;
#endif

    enum RotationDirection { Counterclockwise, Clockwise };
    static AffineTransform rotation(const FloatRect& boxRect, RotationDirection);
private:
    LayoutUnit selectionTop();
    LayoutUnit selectionBottom();
    LayoutUnit selectionHeight();

    // charactersWithHyphen, if provided, must not be destroyed before the TextRun.
    TextRun constructTextRun(RenderStyle*, const Font&, StringBuilder* charactersWithHyphen = 0) const;
    TextRun constructTextRun(RenderStyle*, const Font&, StringView, int maximumLength, StringBuilder* charactersWithHyphen = 0) const;

public:
    TextRun constructTextRunForInspector(RenderStyle*, const Font&) const;
    virtual FloatRect calculateBoundaries() const OVERRIDE { return FloatRect(x(), y(), width(), height()); }

    virtual LayoutRect localSelectionRect(int startPos, int endPos);
    bool isSelected(int startPos, int endPos) const;
    void selectionStartEnd(int& sPos, int& ePos);

protected:
    virtual void paint(PaintInfo&, const LayoutPoint&, LayoutUnit lineTop, LayoutUnit lineBottom) OVERRIDE;
    virtual bool nodeAtPoint(const HitTestRequest&, HitTestResult&, const HitTestLocation& locationInContainer, const LayoutPoint& accumulatedOffset, LayoutUnit lineTop, LayoutUnit lineBottom) OVERRIDE;

private:
    virtual void deleteLine() OVERRIDE FINAL;
    virtual void extractLine() OVERRIDE FINAL;
    virtual void attachLine() OVERRIDE FINAL;

public:
    virtual RenderObject::SelectionState selectionState() OVERRIDE FINAL;

private:
    virtual void clearTruncation() OVERRIDE FINAL { m_truncation = cNoTruncation; }
    virtual float placeEllipsisBox(bool flowIsLTR, float visibleLeftEdge, float visibleRightEdge, float ellipsisWidth, float &truncatedWidth, bool& foundBox) OVERRIDE FINAL;

public:
    virtual bool isLineBreak() const OVERRIDE FINAL;

    void setExpansion(int newExpansion)
    {
        m_logicalWidth -= expansion();
        InlineBox::setExpansion(newExpansion);
        m_logicalWidth += newExpansion;
    }

private:
    virtual bool isInlineTextBox() const OVERRIDE FINAL { return true; }

public:
    virtual int caretMinOffset() const OVERRIDE FINAL;
    virtual int caretMaxOffset() const OVERRIDE FINAL;

private:
    float textPos() const; // returns the x position relative to the left start of the text line.

public:
    virtual int offsetForPosition(float x, bool includePartialGlyphs = true) const;
    virtual float positionForOffset(int offset) const;

    bool containsCaretOffset(int offset) const; // false for offset after line break

    // Fills a vector with the pixel width of each character.
    void characterWidths(Vector<float>&) const;

private:
    InlineTextBox* m_prevTextBox; // The previous box that also uses our RenderObject
    InlineTextBox* m_nextTextBox; // The next box that also uses our RenderObject

    int m_start;
    unsigned short m_len;

    unsigned short m_truncation; // Where to truncate when text overflow is applied.  We use special constants to
                      // denote no truncation (the whole run paints) and full truncation (nothing paints at all).

    unsigned underlinePaintStart(const CompositionUnderline&);
    unsigned underlinePaintEnd(const CompositionUnderline&);

protected:
    void paintSingleCompositionBackgroundRun(GraphicsContext*, const FloatPoint& boxOrigin, RenderStyle*, const Font&, Color backgroundColor, int startPos, int endPos);
    void paintCompositionBackgrounds(GraphicsContext*, const FloatPoint& boxOrigin, RenderStyle*, const Font&, bool useCustomUnderlines);
    void paintDocumentMarkers(GraphicsContext*, const FloatPoint& boxOrigin, RenderStyle*, const Font&, bool background);
    void paintCompositionUnderline(GraphicsContext*, const FloatPoint& boxOrigin, const CompositionUnderline&);

    // These functions both paint markers and update the DocumentMarker's renderedRect.
    virtual void paintDocumentMarker(GraphicsContext*, const FloatPoint& boxOrigin, DocumentMarker*, RenderStyle*, const Font&, bool grammar);
    virtual void paintTextMatchMarker(GraphicsContext*, const FloatPoint& boxOrigin, DocumentMarker*, RenderStyle*, const Font&);

private:
    void paintDecoration(GraphicsContext*, const FloatPoint& boxOrigin, TextDecoration);
    void paintSelection(GraphicsContext*, const FloatPoint& boxOrigin, RenderStyle*, const Font&, Color textColor);

    TextRun::ExpansionBehavior expansionBehavior() const
    {
        return (canHaveLeadingExpansion() ? TextRun::AllowLeadingExpansion : TextRun::ForbidLeadingExpansion)
            | (expansion() && nextLeafChild() ? TextRun::AllowTrailingExpansion : TextRun::ForbidTrailingExpansion);
    }
};

DEFINE_INLINE_BOX_TYPE_CASTS(InlineTextBox);

void alignSelectionRectToDevicePixels(FloatRect&);

inline AffineTransform InlineTextBox::rotation(const FloatRect& boxRect, RotationDirection rotationDirection)
{
    return rotationDirection == Clockwise ? AffineTransform(0, 1, -1, 0, boxRect.x() + boxRect.maxY(), boxRect.maxY() - boxRect.x())
        : AffineTransform(0, -1, 1, 0, boxRect.x() - boxRect.maxY(), boxRect.x() + boxRect.maxY());
}

} // namespace blink

#endif // InlineTextBox_h
