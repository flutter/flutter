/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2003, 2004, 2006, 2007, 2008, 2009, 2010, 2011 Apple Inc. All
 * right reserved.
 * Copyright (C) 2010 Google Inc. All rights reserved.
 * Copyright (C) 2014 Adobe Systems Incorporated. All rights reserved.
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

#ifndef SKY_ENGINE_CORE_RENDERING_LINE_LINELAYOUTSTATE_H_
#define SKY_ENGINE_CORE_RENDERING_LINE_LINELAYOUTSTATE_H_

#include "flutter/sky/engine/core/rendering/RenderParagraph.h"
#include "flutter/sky/engine/platform/geometry/LayoutRect.h"

namespace blink {

// LineLayoutState keeps track of global information
// during an entire linebox tree layout pass (aka
// RenderParagraph::layoutChildren).
class LineLayoutState {
 public:
  LineLayoutState(bool fullLayout)
      : m_endLine(0),
        m_endLineLogicalTop(0),
        m_endLineMatched(false),
        m_hasInlineChild(false),
        m_isFullLayout(fullLayout),
        m_adjustedLogicalLineTop(0) {}

  void markForFullLayout() { m_isFullLayout = true; }
  bool isFullLayout() const { return m_isFullLayout; }

  bool endLineMatched() const { return m_endLineMatched; }
  void setEndLineMatched(bool endLineMatched) {
    m_endLineMatched = endLineMatched;
  }

  bool hasInlineChild() const { return m_hasInlineChild; }
  void setHasInlineChild(bool hasInlineChild) {
    m_hasInlineChild = hasInlineChild;
  }

  LineInfo& lineInfo() { return m_lineInfo; }
  const LineInfo& lineInfo() const { return m_lineInfo; }

  LayoutUnit endLineLogicalTop() const { return m_endLineLogicalTop; }
  void setEndLineLogicalTop(LayoutUnit logicalTop) {
    m_endLineLogicalTop = logicalTop;
  }

  RootInlineBox* endLine() const { return m_endLine; }
  void setEndLine(RootInlineBox* line) { m_endLine = line; }

  LayoutUnit adjustedLogicalLineTop() const { return m_adjustedLogicalLineTop; }
  void setAdjustedLogicalLineTop(LayoutUnit value) {
    m_adjustedLogicalLineTop = value;
  }

 private:
  RootInlineBox* m_endLine;
  LineInfo m_lineInfo;
  LayoutUnit m_endLineLogicalTop;
  bool m_endLineMatched;
  // FIXME(sky): Do we still need this?
  // Used as a performance optimization to avoid doing a full paint invalidation
  // when our floats change but we don't have any inline children.
  bool m_hasInlineChild;

  bool m_isFullLayout;

  LayoutUnit m_adjustedLogicalLineTop;
};

}  // namespace blink

#endif  // SKY_ENGINE_CORE_RENDERING_LINE_LINELAYOUTSTATE_H_
