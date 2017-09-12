/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2003, 2004, 2006, 2007, 2008, 2009, 2010, 2011 Apple Inc. All
 * right reserved.
 * Copyright (C) 2010 Google Inc. All rights reserved.
 * Copyright (C) 2013 Adobe Systems Incorporated.
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

#ifndef SKY_ENGINE_CORE_RENDERING_LINE_LINEINFO_H_
#define SKY_ENGINE_CORE_RENDERING_LINE_LINEINFO_H_

#include "flutter/sky/engine/core/rendering/line/LineWidth.h"

namespace blink {

class LineInfo {
 public:
  LineInfo()
      : m_isFirstLine(true),
        m_isLastLine(false),
        m_isEmpty(true),
        m_previousLineBrokeCleanly(true),
        m_runsFromLeadingWhitespace(0),
        m_lineIndex(0) {}

  bool isFirstLine() const { return m_isFirstLine; }
  bool isLastLine() const { return m_isLastLine; }
  bool isEmpty() const { return m_isEmpty; }
  bool previousLineBrokeCleanly() const { return m_previousLineBrokeCleanly; }
  unsigned runsFromLeadingWhitespace() const {
    return m_runsFromLeadingWhitespace;
  }
  void resetRunsFromLeadingWhitespace() { m_runsFromLeadingWhitespace = 0; }
  void incrementRunsFromLeadingWhitespace() { m_runsFromLeadingWhitespace++; }

  void setFirstLine(bool firstLine) { m_isFirstLine = firstLine; }
  void setLastLine(bool lastLine) { m_isLastLine = lastLine; }
  void setEmpty(bool empty, RenderBlock* block = 0, LineWidth* lineWidth = 0) {
    m_isEmpty = empty;
  }

  void incrementLineIndex() { ++m_lineIndex; }
  int lineIndex() const { return m_lineIndex; }

  void setPreviousLineBrokeCleanly(bool previousLineBrokeCleanly) {
    m_previousLineBrokeCleanly = previousLineBrokeCleanly;
  }

 private:
  bool m_isFirstLine;
  bool m_isLastLine;
  bool m_isEmpty;
  bool m_previousLineBrokeCleanly;
  unsigned m_runsFromLeadingWhitespace;
  int m_lineIndex;
};

}  // namespace blink

#endif  // SKY_ENGINE_CORE_RENDERING_LINE_LINEINFO_H_
