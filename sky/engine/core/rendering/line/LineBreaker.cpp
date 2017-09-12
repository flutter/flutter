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

#include "flutter/sky/engine/core/rendering/line/LineBreaker.h"

#include "flutter/sky/engine/core/rendering/line/BreakingContextInlineHeaders.h"

namespace blink {

void LineBreaker::skipLeadingWhitespace(
    InlineBidiResolver& resolver,
    LineInfo& lineInfo,
    FloatingObject* lastFloatFromPreviousLine,
    LineWidth& width) {
  while (!resolver.position().atEnd() &&
         !requiresLineBox(resolver.position(), lineInfo, LeadingWhitespace)) {
    RenderObject* object = resolver.position().object();
    if (object->isOutOfFlowPositioned() &&
        object->style()->isOriginalDisplayInlineType()) {
      resolver.runs().addRun(createRun(0, 1, object, resolver));
      lineInfo.incrementRunsFromLeadingWhitespace();
    }
    resolver.position().increment(&resolver);
  }
  resolver.commitExplicitEmbedding(resolver.runs());
}

void LineBreaker::reset() {
  m_positionedObjects.clear();
  m_hyphenated = false;
  m_ellipsized = false;
}

InlineIterator LineBreaker::nextLineBreak(
    InlineBidiResolver& resolver,
    LineInfo& lineInfo,
    RenderTextInfo& renderTextInfo,
    FloatingObject* lastFloatFromPreviousLine,
    WordMeasurements& wordMeasurements) {
  reset();

  ASSERT(resolver.position().root() == m_block);

  bool appliedStartWidth = resolver.position().offset() > 0;

  LineWidth width(
      *m_block, lineInfo.isFirstLine(),
      requiresIndent(lineInfo.isFirstLine(),
                     lineInfo.previousLineBrokeCleanly(), m_block->style()));

  skipLeadingWhitespace(resolver, lineInfo, lastFloatFromPreviousLine, width);

  if (resolver.position().atEnd())
    return resolver.position();

  BreakingContext context(resolver, lineInfo, width, renderTextInfo,
                          lastFloatFromPreviousLine, appliedStartWidth,
                          m_block);

  while (context.currentObject()) {
    context.initializeForCurrentObject();
    if (context.currentObject()->isOutOfFlowPositioned()) {
      context.handleOutOfFlowPositioned(m_positionedObjects);
    } else if (context.currentObject()->isRenderInline()) {
      context.handleEmptyInline();
    } else if (context.currentObject()->isReplaced()) {
      context.handleReplaced();
    } else if (context.currentObject()->isText()) {
      if (context.handleText(wordMeasurements, m_hyphenated, m_ellipsized)) {
        // We've hit a hard text line break. Our line break iterator is updated,
        // so go ahead and early return.
        return context.lineBreak();
      }
    } else {
      ASSERT_NOT_REACHED();
    }

    if (context.atEnd())
      return context.handleEndOfLine();

    context.commitAndUpdateLineBreakIfNeeded();

    if (context.atEnd())
      return context.handleEndOfLine();

    context.increment();
  }

  context.clearLineBreakIfFitsOnLine();

  return context.handleEndOfLine();
}

}  // namespace blink
