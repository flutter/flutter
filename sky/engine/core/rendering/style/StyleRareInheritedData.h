/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 *           (C) 2000 Antti Koivisto (koivisto@kde.org)
 *           (C) 2000 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2003, 2005, 2006, 2007, 2008 Apple Inc. All rights reserved.
 * Copyright (C) 2006 Graham Dennis (graham.dennis@gmail.com)
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

#ifndef SKY_ENGINE_CORE_RENDERING_STYLE_STYLERAREINHERITEDDATA_H_
#define SKY_ENGINE_CORE_RENDERING_STYLE_STYLERAREINHERITEDDATA_H_

#include "flutter/sky/engine/core/rendering/style/DataRef.h"
#include "flutter/sky/engine/core/rendering/style/StyleColor.h"
#include "flutter/sky/engine/platform/Length.h"
#include "flutter/sky/engine/platform/graphics/Color.h"
#include "flutter/sky/engine/wtf/PassRefPtr.h"
#include "flutter/sky/engine/wtf/RefCounted.h"
#include "flutter/sky/engine/wtf/RefVector.h"
#include "flutter/sky/engine/wtf/text/AtomicString.h"

namespace blink {

class AppliedTextDecoration;
class ShadowList;
class StyleImage;

typedef RefVector<AppliedTextDecoration> AppliedTextDecorationList;

// This struct is for rarely used inherited CSS3, CSS2, and WebKit-specific
// properties. By grouping them together, we save space, and only allocate this
// object when someone actually uses one of these properties.
class StyleRareInheritedData : public RefCounted<StyleRareInheritedData> {
 public:
  static PassRefPtr<StyleRareInheritedData> create() {
    return adoptRef(new StyleRareInheritedData);
  }
  PassRefPtr<StyleRareInheritedData> copy() const {
    return adoptRef(new StyleRareInheritedData(*this));
  }
  ~StyleRareInheritedData();

  bool operator==(const StyleRareInheritedData& o) const;
  bool operator!=(const StyleRareInheritedData& o) const {
    return !(*this == o);
  }
  bool shadowDataEquivalent(const StyleRareInheritedData&) const;

  StyleColor textStrokeColor() const {
    return m_textStrokeColorIsCurrentColor ? StyleColor::currentColor()
                                           : StyleColor(m_textStrokeColor);
  }
  StyleColor textFillColor() const {
    return m_textFillColorIsCurrentColor ? StyleColor::currentColor()
                                         : StyleColor(m_textFillColor);
  }
  StyleColor textEmphasisColor() const {
    return m_textEmphasisColorIsCurrentColor ? StyleColor::currentColor()
                                             : StyleColor(m_textEmphasisColor);
  }

  void setTextStrokeColor(const StyleColor& color) {
    m_textStrokeColor = color.resolve(Color());
    m_textStrokeColorIsCurrentColor = color.isCurrentColor();
  }
  void setTextFillColor(const StyleColor& color) {
    m_textFillColor = color.resolve(Color());
    m_textFillColorIsCurrentColor = color.isCurrentColor();
  }
  void setTextEmphasisColor(const StyleColor& color) {
    m_textEmphasisColor = color.resolve(Color());
    m_textEmphasisColorIsCurrentColor = color.isCurrentColor();
  }

  Color m_textStrokeColor;
  float textStrokeWidth;
  Color m_textFillColor;
  Color m_textEmphasisColor;

  RefPtr<ShadowList>
      textShadow;  // Our text shadow information for shadowed text drawing.
  AtomicString
      highlight;  // Apple-specific extension for custom highlight rendering.

  Length indent;

  unsigned m_textStrokeColorIsCurrentColor : 1;
  unsigned m_textFillColorIsCurrentColor : 1;
  unsigned m_textEmphasisColorIsCurrentColor : 1;

  unsigned userModify : 2;            // EUserModify (editing)
  unsigned wordBreak : 2;             // EWordBreak
  unsigned overflowWrap : 1;          // EOverflowWrap
  unsigned lineBreak : 3;             // LineBreak
  unsigned userSelect : 2;            // EUserSelect
  unsigned hyphens : 2;               // Hyphens
  unsigned textEmphasisFill : 1;      // TextEmphasisFill
  unsigned textEmphasisMark : 3;      // TextEmphasisMark
  unsigned textEmphasisPosition : 1;  // TextEmphasisPosition
  unsigned m_textAlignLast : 3;       // TextAlignLast
  unsigned m_textJustify : 2;         // TextJustify
  unsigned m_textOrientation : 2;     // TextOrientation
  unsigned m_textIndentLine : 1;      // TextIndentEachLine
  unsigned m_textIndentType : 1;      // TextIndentHanging
  unsigned m_lineBoxContain : 7;      // LineBoxContain
  // CSS Image Values Level 3
  unsigned m_imageRendering : 3;         // EImageRendering
  unsigned m_textUnderlinePosition : 1;  // TextUnderlinePosition
  unsigned m_touchActionDelay : 1;       // TouchActionDelay

  // Though will-change is not itself an inherited property, the intent
  // expressed by 'will-change: contents' includes descendants.
  unsigned m_subtreeWillChangeContents : 1;

  short hyphenationLimitBefore;
  short hyphenationLimitAfter;
  short hyphenationLimitLines;
  AtomicString hyphenationString;

  AtomicString locale;

  AtomicString textEmphasisCustomMark;

  unsigned m_tabSize;

  Color tapHighlightColor;

  RefPtr<AppliedTextDecorationList> appliedTextDecorations;

 private:
  StyleRareInheritedData();
  StyleRareInheritedData(const StyleRareInheritedData&);
};

}  // namespace blink

#endif  // SKY_ENGINE_CORE_RENDERING_STYLE_STYLERAREINHERITEDDATA_H_
