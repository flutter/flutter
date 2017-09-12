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

#include "flutter/sky/engine/core/rendering/line/BreakingContextInlineHeaders.h"

namespace blink {

InlineIterator BreakingContext::handleEndOfLine() {
  if (m_lineBreak == m_resolver.position() && !m_lineBreak.object()) {
    // we just add as much as possible
    if (m_blockStyle->whiteSpace() == PRE && !m_current.offset()) {
      m_lineBreak.moveTo(m_lastObject,
                         m_lastObject->isText() ? m_lastObject->length() : 0);
    } else if (m_lineBreak.object()) {
      // Don't ever break in the middle of a word if we can help it.
      // There's no room at all. We just have to be on this line,
      // even though we'll spill out.
      m_lineBreak.moveTo(m_current.object(), m_current.offset());
    }
  }

  // FIXME Bug 100049: We do not need to consume input in a multi-segment line
  // unless no segment will.
  if (m_lineBreak == m_resolver.position())
    m_lineBreak.increment();

  // Sanity check our midpoints.
  m_lineMidpointState.checkMidpoints(m_lineBreak);

  m_trailingObjects.updateMidpointsForTrailingObjects(
      m_lineMidpointState, m_lineBreak, TrailingObjects::CollapseFirstSpace);

  // We might have made lineBreak an iterator that points past the end
  // of the object. Do this adjustment to make it point to the start
  // of the next object instead to avoid confusing the rest of the
  // code.
  if (m_lineBreak.offset()) {
    // This loop enforces the invariant that line breaks should never point
    // at an empty inline. See http://crbug.com/305904.
    do {
      m_lineBreak.setOffset(m_lineBreak.offset() - 1);
      m_lineBreak.increment();
    } while (!m_lineBreak.atEnd() && isEmptyInline(m_lineBreak.object()));
  }

  m_lineInfo.incrementLineIndex();

  return m_lineBreak;
}

}  // namespace blink
