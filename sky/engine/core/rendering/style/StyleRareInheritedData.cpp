/*
 * Copyright (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2010 Apple Inc.
 * All rights reserved.
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

#include "flutter/sky/engine/core/rendering/style/StyleRareInheritedData.h"

#include "flutter/sky/engine/core/rendering/style/AppliedTextDecoration.h"
#include "flutter/sky/engine/core/rendering/style/DataEquivalency.h"
#include "flutter/sky/engine/core/rendering/style/RenderStyle.h"
#include "flutter/sky/engine/core/rendering/style/RenderStyleConstants.h"
#include "flutter/sky/engine/core/rendering/style/ShadowList.h"
#include "flutter/sky/engine/core/rendering/style/StyleImage.h"

namespace blink {

StyleRareInheritedData::StyleRareInheritedData()
    : textStrokeWidth(RenderStyle::initialTextStrokeWidth()),
      indent(RenderStyle::initialTextIndent()),
      m_textStrokeColorIsCurrentColor(true),
      m_textFillColorIsCurrentColor(true),
      m_textEmphasisColorIsCurrentColor(true),
      userModify(READ_ONLY),
      wordBreak(RenderStyle::initialWordBreak()),
      overflowWrap(RenderStyle::initialOverflowWrap()),
      lineBreak(LineBreakAuto),
      userSelect(RenderStyle::initialUserSelect()),
      hyphens(HyphensManual),
      textEmphasisFill(TextEmphasisFillFilled),
      textEmphasisMark(TextEmphasisMarkNone),
      textEmphasisPosition(TextEmphasisPositionOver),
      m_textAlignLast(RenderStyle::initialTextAlignLast()),
      m_textJustify(RenderStyle::initialTextJustify()),
      m_textOrientation(TextOrientationVerticalRight),
      m_textIndentLine(RenderStyle::initialTextIndentLine()),
      m_textIndentType(RenderStyle::initialTextIndentLine()),
      m_lineBoxContain(RenderStyle::initialLineBoxContain()),
      m_imageRendering(RenderStyle::initialImageRendering()),
      m_textUnderlinePosition(RenderStyle::initialTextUnderlinePosition()),
      m_touchActionDelay(RenderStyle::initialTouchActionDelay()),
      m_subtreeWillChangeContents(false),
      hyphenationLimitBefore(-1),
      hyphenationLimitAfter(-1),
      hyphenationLimitLines(-1),
      m_tabSize(RenderStyle::initialTabSize()),
      tapHighlightColor(RenderStyle::initialTapHighlightColor()) {}

StyleRareInheritedData::StyleRareInheritedData(const StyleRareInheritedData& o)
    : RefCounted<StyleRareInheritedData>(),
      m_textStrokeColor(o.m_textStrokeColor),
      textStrokeWidth(o.textStrokeWidth),
      m_textFillColor(o.m_textFillColor),
      m_textEmphasisColor(o.m_textEmphasisColor),
      textShadow(o.textShadow),
      highlight(o.highlight),
      indent(o.indent),
      m_textStrokeColorIsCurrentColor(o.m_textStrokeColorIsCurrentColor),
      m_textFillColorIsCurrentColor(o.m_textFillColorIsCurrentColor),
      m_textEmphasisColorIsCurrentColor(o.m_textEmphasisColorIsCurrentColor),
      userModify(o.userModify),
      wordBreak(o.wordBreak),
      overflowWrap(o.overflowWrap),
      lineBreak(o.lineBreak),
      userSelect(o.userSelect),
      hyphens(o.hyphens),
      textEmphasisFill(o.textEmphasisFill),
      textEmphasisMark(o.textEmphasisMark),
      textEmphasisPosition(o.textEmphasisPosition),
      m_textAlignLast(o.m_textAlignLast),
      m_textJustify(o.m_textJustify),
      m_textOrientation(o.m_textOrientation),
      m_textIndentLine(o.m_textIndentLine),
      m_textIndentType(o.m_textIndentType),
      m_lineBoxContain(o.m_lineBoxContain),
      m_imageRendering(o.m_imageRendering),
      m_textUnderlinePosition(o.m_textUnderlinePosition),
      m_touchActionDelay(o.m_touchActionDelay),
      m_subtreeWillChangeContents(o.m_subtreeWillChangeContents),
      hyphenationLimitBefore(o.hyphenationLimitBefore),
      hyphenationLimitAfter(o.hyphenationLimitAfter),
      hyphenationLimitLines(o.hyphenationLimitLines),
      hyphenationString(o.hyphenationString),
      locale(o.locale),
      textEmphasisCustomMark(o.textEmphasisCustomMark),
      m_tabSize(o.m_tabSize),
      tapHighlightColor(o.tapHighlightColor),
      appliedTextDecorations(o.appliedTextDecorations) {}

StyleRareInheritedData::~StyleRareInheritedData() {}

bool StyleRareInheritedData::operator==(const StyleRareInheritedData& o) const {
  return m_textStrokeColor == o.m_textStrokeColor &&
         textStrokeWidth == o.textStrokeWidth &&
         m_textFillColor == o.m_textFillColor &&
         m_textEmphasisColor == o.m_textEmphasisColor &&
         tapHighlightColor == o.tapHighlightColor && shadowDataEquivalent(o) &&
         highlight == o.highlight && indent == o.indent &&
         m_textStrokeColorIsCurrentColor == o.m_textStrokeColorIsCurrentColor &&
         m_textFillColorIsCurrentColor == o.m_textFillColorIsCurrentColor &&
         m_textEmphasisColorIsCurrentColor ==
             o.m_textEmphasisColorIsCurrentColor &&
         userModify == o.userModify && wordBreak == o.wordBreak &&
         overflowWrap == o.overflowWrap && lineBreak == o.lineBreak &&
         userSelect == o.userSelect && hyphens == o.hyphens &&
         hyphenationLimitBefore == o.hyphenationLimitBefore &&
         hyphenationLimitAfter == o.hyphenationLimitAfter &&
         hyphenationLimitLines == o.hyphenationLimitLines &&
         textEmphasisFill == o.textEmphasisFill &&
         textEmphasisMark == o.textEmphasisMark &&
         textEmphasisPosition == o.textEmphasisPosition &&
         m_touchActionDelay == o.m_touchActionDelay &&
         m_textAlignLast == o.m_textAlignLast &&
         m_textJustify == o.m_textJustify &&
         m_textOrientation == o.m_textOrientation &&
         m_textIndentLine == o.m_textIndentLine &&
         m_textIndentType == o.m_textIndentType &&
         m_lineBoxContain == o.m_lineBoxContain &&
         m_subtreeWillChangeContents == o.m_subtreeWillChangeContents &&
         hyphenationString == o.hyphenationString && locale == o.locale &&
         textEmphasisCustomMark == o.textEmphasisCustomMark &&
         m_tabSize == o.m_tabSize && m_imageRendering == o.m_imageRendering &&
         m_textUnderlinePosition == o.m_textUnderlinePosition &&
         dataEquivalent(appliedTextDecorations, o.appliedTextDecorations);
}

bool StyleRareInheritedData::shadowDataEquivalent(
    const StyleRareInheritedData& o) const {
  return dataEquivalent(textShadow.get(), o.textShadow.get());
}

}  // namespace blink
