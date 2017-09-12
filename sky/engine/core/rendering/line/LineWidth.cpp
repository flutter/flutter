/*
 * Copyright (C) 2013 Adobe Systems Incorporated. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer.
 * 2. Redistributions in binary form must reproduce the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer in the documentation and/or other materials
 *    provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "flutter/sky/engine/core/rendering/line/LineWidth.h"

#include "flutter/sky/engine/core/rendering/RenderBlock.h"
#include "flutter/sky/engine/core/rendering/RenderParagraph.h"

namespace blink {

LineWidth::LineWidth(RenderParagraph& block,
                     bool isFirstLine,
                     IndentTextOrNot shouldIndentText)
    : m_block(block),
      m_uncommittedWidth(0),
      m_committedWidth(0),
      m_trailingWhitespaceWidth(0),
      m_left(0),
      m_right(0),
      m_availableWidth(0),
      m_shouldIndentText(shouldIndentText) {
  updateAvailableWidth();
}

void LineWidth::updateAvailableWidth() {
  m_left = m_block.logicalLeftOffsetForLine(shouldIndentText()).toFloat();
  m_right = m_block.logicalRightOffsetForLine(shouldIndentText()).toFloat();
  computeAvailableWidthFromLeftAndRight();
}

void LineWidth::commit() {
  m_committedWidth += m_uncommittedWidth;
  m_uncommittedWidth = 0;
}

void LineWidth::updateLineDimension(LayoutUnit newLineTop,
                                    LayoutUnit newLineWidth,
                                    const float& newLineLeft,
                                    const float& newLineRight) {
  if (newLineWidth <= m_availableWidth)
    return;

  m_block.setLogicalHeight(newLineTop);
  m_availableWidth = newLineWidth.toFloat();
  m_left = newLineLeft;
  m_right = newLineRight;
}

void LineWidth::fitBelowFloats(bool isFirstLine) {
  ASSERT(!m_committedWidth);
  ASSERT(!fitsOnLine());

  LayoutUnit floatLogicalBottom;
  LayoutUnit lastFloatLogicalBottom = m_block.logicalHeight();
  float newLineWidth = m_availableWidth;
  float newLineLeft = m_left;
  float newLineRight = m_right;

  while (true) {
    floatLogicalBottom = lastFloatLogicalBottom;
    if (floatLogicalBottom <= lastFloatLogicalBottom)
      break;

    newLineLeft =
        m_block.logicalLeftOffsetForLine(shouldIndentText()).toFloat();
    newLineRight =
        m_block.logicalRightOffsetForLine(shouldIndentText()).toFloat();
    newLineWidth = std::max(0.0f, newLineRight - newLineLeft);

    lastFloatLogicalBottom = floatLogicalBottom;

    if (newLineWidth >= m_uncommittedWidth)
      break;
  }
  updateLineDimension(lastFloatLogicalBottom, newLineWidth, newLineLeft,
                      newLineRight);
}

void LineWidth::computeAvailableWidthFromLeftAndRight() {
  m_availableWidth = max(0.0f, m_right - m_left);
}

}  // namespace blink
