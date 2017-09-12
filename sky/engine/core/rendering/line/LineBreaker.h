/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2003, 2004, 2006, 2007, 2008, 2009, 2010, 2011 Apple Inc. All
 * right reserved.
 * Copyright (C) 2010 Google Inc. All rights reserved.
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

#ifndef SKY_ENGINE_CORE_RENDERING_LINE_LINEBREAKER_H_
#define SKY_ENGINE_CORE_RENDERING_LINE_LINEBREAKER_H_

#include "flutter/sky/engine/core/rendering/InlineIterator.h"
#include "flutter/sky/engine/core/rendering/line/LineInfo.h"
#include "flutter/sky/engine/wtf/Vector.h"

namespace blink {

enum WhitespacePosition { LeadingWhitespace, TrailingWhitespace };

struct RenderTextInfo;

class LineBreaker {
 public:
  friend class BreakingContext;
  LineBreaker(RenderParagraph* block) : m_block(block) { reset(); }

  InlineIterator nextLineBreak(InlineBidiResolver&,
                               LineInfo&,
                               RenderTextInfo&,
                               FloatingObject* lastFloatFromPreviousLine,
                               WordMeasurements&);

  bool lineWasHyphenated() { return m_hyphenated; }
  bool lineWasEllipsized() { return m_ellipsized; }
  const Vector<RenderBox*>& positionedObjects() { return m_positionedObjects; }

 private:
  void reset();

  void skipLeadingWhitespace(InlineBidiResolver&,
                             LineInfo&,
                             FloatingObject* lastFloatFromPreviousLine,
                             LineWidth&);

  RenderParagraph* m_block;
  bool m_hyphenated;
  bool m_ellipsized;
  Vector<RenderBox*> m_positionedObjects;
};

}  // namespace blink

#endif  // SKY_ENGINE_CORE_RENDERING_LINE_LINEBREAKER_H_
