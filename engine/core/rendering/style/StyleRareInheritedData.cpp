/*
 * Copyright (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2010 Apple Inc. All rights reserved.
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

#include "sky/engine/config.h"
#include "sky/engine/core/rendering/style/StyleRareInheritedData.h"

#include "sky/engine/core/rendering/style/AppliedTextDecoration.h"
#include "sky/engine/core/rendering/style/CursorData.h"
#include "sky/engine/core/rendering/style/DataEquivalency.h"
#include "sky/engine/core/rendering/style/QuotesData.h"
#include "sky/engine/core/rendering/style/RenderStyle.h"
#include "sky/engine/core/rendering/style/RenderStyleConstants.h"
#include "sky/engine/core/rendering/style/ShadowList.h"
#include "sky/engine/core/rendering/style/StyleImage.h"

namespace blink {

struct SameSizeAsStyleRareInheritedData : public RefCounted<SameSizeAsStyleRareInheritedData> {
    void* styleImage;
    Color firstColor;
    float firstFloat;
    Color colors[2];
    void* ownPtrs[1];
    AtomicString atomicStrings[4];
    void* refPtrs[3];
    Length lengths[1];
    unsigned m_bitfields[2];
    short pagedMediaShorts[2];
    unsigned unsigneds[1];
    short hyphenationShorts[3];

    Color touchColors;
};

COMPILE_ASSERT(sizeof(StyleRareInheritedData) == sizeof(SameSizeAsStyleRareInheritedData), StyleRareInheritedData_should_bit_pack);

StyleRareInheritedData::StyleRareInheritedData()
    : listStyleImage(RenderStyle::initialListStyleImage())
    , textStrokeWidth(RenderStyle::initialTextStrokeWidth())
    , indent(RenderStyle::initialTextIndent())
    , widows(RenderStyle::initialWidows())
    , orphans(RenderStyle::initialOrphans())
    , m_hasAutoWidows(true)
    , m_hasAutoOrphans(true)
    , m_textStrokeColorIsCurrentColor(true)
    , m_textFillColorIsCurrentColor(true)
    , m_textEmphasisColorIsCurrentColor(true)
    , userModify(READ_ONLY)
    , wordBreak(RenderStyle::initialWordBreak())
    , overflowWrap(RenderStyle::initialOverflowWrap())
    , lineBreak(LineBreakAuto)
    , userSelect(RenderStyle::initialUserSelect())
    , speak(SpeakNormal)
    , hyphens(HyphensManual)
    , textEmphasisFill(TextEmphasisFillFilled)
    , textEmphasisMark(TextEmphasisMarkNone)
    , textEmphasisPosition(TextEmphasisPositionOver)
    , m_textAlignLast(RenderStyle::initialTextAlignLast())
    , m_textJustify(RenderStyle::initialTextJustify())
    , m_textOrientation(TextOrientationVerticalRight)
    , m_textIndentLine(RenderStyle::initialTextIndentLine())
    , m_textIndentType(RenderStyle::initialTextIndentLine())
    , m_lineBoxContain(RenderStyle::initialLineBoxContain())
    , m_imageRendering(RenderStyle::initialImageRendering())
    , m_textUnderlinePosition(RenderStyle::initialTextUnderlinePosition())
    , m_touchActionDelay(RenderStyle::initialTouchActionDelay())
    , m_subtreeWillChangeContents(false)
    , hyphenationLimitBefore(-1)
    , hyphenationLimitAfter(-1)
    , hyphenationLimitLines(-1)
    , m_tabSize(RenderStyle::initialTabSize())
    , tapHighlightColor(RenderStyle::initialTapHighlightColor())
{
}

StyleRareInheritedData::StyleRareInheritedData(const StyleRareInheritedData& o)
    : RefCounted<StyleRareInheritedData>()
    , listStyleImage(o.listStyleImage)
    , m_textStrokeColor(o.m_textStrokeColor)
    , textStrokeWidth(o.textStrokeWidth)
    , m_textFillColor(o.m_textFillColor)
    , m_textEmphasisColor(o.m_textEmphasisColor)
    , textShadow(o.textShadow)
    , highlight(o.highlight)
    , cursorData(o.cursorData)
    , indent(o.indent)
    , widows(o.widows)
    , orphans(o.orphans)
    , m_hasAutoWidows(o.m_hasAutoWidows)
    , m_hasAutoOrphans(o.m_hasAutoOrphans)
    , m_textStrokeColorIsCurrentColor(o.m_textStrokeColorIsCurrentColor)
    , m_textFillColorIsCurrentColor(o.m_textFillColorIsCurrentColor)
    , m_textEmphasisColorIsCurrentColor(o.m_textEmphasisColorIsCurrentColor)
    , userModify(o.userModify)
    , wordBreak(o.wordBreak)
    , overflowWrap(o.overflowWrap)
    , lineBreak(o.lineBreak)
    , userSelect(o.userSelect)
    , speak(o.speak)
    , hyphens(o.hyphens)
    , textEmphasisFill(o.textEmphasisFill)
    , textEmphasisMark(o.textEmphasisMark)
    , textEmphasisPosition(o.textEmphasisPosition)
    , m_textAlignLast(o.m_textAlignLast)
    , m_textJustify(o.m_textJustify)
    , m_textOrientation(o.m_textOrientation)
    , m_textIndentLine(o.m_textIndentLine)
    , m_textIndentType(o.m_textIndentType)
    , m_lineBoxContain(o.m_lineBoxContain)
    , m_imageRendering(o.m_imageRendering)
    , m_textUnderlinePosition(o.m_textUnderlinePosition)
    , m_touchActionDelay(o.m_touchActionDelay)
    , m_subtreeWillChangeContents(o.m_subtreeWillChangeContents)
    , hyphenationString(o.hyphenationString)
    , hyphenationLimitBefore(o.hyphenationLimitBefore)
    , hyphenationLimitAfter(o.hyphenationLimitAfter)
    , hyphenationLimitLines(o.hyphenationLimitLines)
    , locale(o.locale)
    , textEmphasisCustomMark(o.textEmphasisCustomMark)
    , m_tabSize(o.m_tabSize)
    , tapHighlightColor(o.tapHighlightColor)
    , appliedTextDecorations(o.appliedTextDecorations)
{
}

StyleRareInheritedData::~StyleRareInheritedData()
{
}

bool StyleRareInheritedData::operator==(const StyleRareInheritedData& o) const
{
    return m_textStrokeColor == o.m_textStrokeColor
        && textStrokeWidth == o.textStrokeWidth
        && m_textFillColor == o.m_textFillColor
        && m_textEmphasisColor == o.m_textEmphasisColor
        && tapHighlightColor == o.tapHighlightColor
        && shadowDataEquivalent(o)
        && highlight == o.highlight
        && dataEquivalent(cursorData.get(), o.cursorData.get())
        && indent == o.indent
        && widows == o.widows
        && orphans == o.orphans
        && m_hasAutoWidows == o.m_hasAutoWidows
        && m_hasAutoOrphans == o.m_hasAutoOrphans
        && m_textStrokeColorIsCurrentColor == o.m_textStrokeColorIsCurrentColor
        && m_textFillColorIsCurrentColor == o.m_textFillColorIsCurrentColor
        && m_textEmphasisColorIsCurrentColor == o.m_textEmphasisColorIsCurrentColor
        && userModify == o.userModify
        && wordBreak == o.wordBreak
        && overflowWrap == o.overflowWrap
        && lineBreak == o.lineBreak
        && userSelect == o.userSelect
        && speak == o.speak
        && hyphens == o.hyphens
        && hyphenationLimitBefore == o.hyphenationLimitBefore
        && hyphenationLimitAfter == o.hyphenationLimitAfter
        && hyphenationLimitLines == o.hyphenationLimitLines
        && textEmphasisFill == o.textEmphasisFill
        && textEmphasisMark == o.textEmphasisMark
        && textEmphasisPosition == o.textEmphasisPosition
        && m_touchActionDelay == o.m_touchActionDelay
        && m_textAlignLast == o.m_textAlignLast
        && m_textJustify == o.m_textJustify
        && m_textOrientation == o.m_textOrientation
        && m_textIndentLine == o.m_textIndentLine
        && m_textIndentType == o.m_textIndentType
        && m_lineBoxContain == o.m_lineBoxContain
        && m_subtreeWillChangeContents == o.m_subtreeWillChangeContents
        && hyphenationString == o.hyphenationString
        && locale == o.locale
        && textEmphasisCustomMark == o.textEmphasisCustomMark
        && quotesDataEquivalent(o)
        && m_tabSize == o.m_tabSize
        && m_imageRendering == o.m_imageRendering
        && m_textUnderlinePosition == o.m_textUnderlinePosition
        && dataEquivalent(listStyleImage.get(), o.listStyleImage.get())
        && dataEquivalent(appliedTextDecorations, o.appliedTextDecorations);
}

bool StyleRareInheritedData::shadowDataEquivalent(const StyleRareInheritedData& o) const
{
    return dataEquivalent(textShadow.get(), o.textShadow.get());
}

bool StyleRareInheritedData::quotesDataEquivalent(const StyleRareInheritedData& o) const
{
    return dataEquivalent(quotes, o.quotes);
}

} // namespace blink
