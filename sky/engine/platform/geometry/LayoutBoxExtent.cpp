/*
 * Copyright (c) 2012, Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "flutter/sky/engine/platform/geometry/LayoutBoxExtent.h"

#include "flutter/sky/engine/wtf/Assertions.h"

namespace blink {

LayoutUnit LayoutBoxExtent::logicalTop() const {
  return m_top;
}

LayoutUnit LayoutBoxExtent::logicalBottom() const {
  return m_bottom;
}

LayoutUnit LayoutBoxExtent::logicalLeft() const {
  return m_left;
}

LayoutUnit LayoutBoxExtent::logicalRight() const {
  return m_right;
}

LayoutUnit LayoutBoxExtent::before() const {
  // FIXME(sky): Remove
  return m_top;
}

LayoutUnit LayoutBoxExtent::after() const {
  // FIXME(sky): Remove
  return m_bottom;
}

LayoutUnit LayoutBoxExtent::start(TextDirection direction) const {
  return isLeftToRightDirection(direction) ? m_left : m_right;
}

LayoutUnit LayoutBoxExtent::end(TextDirection direction) const {
  return isLeftToRightDirection(direction) ? m_right : m_left;
}

void LayoutBoxExtent::setBefore(LayoutUnit value) {
  // FIXME(sky): Remove
  m_top = value;
}

void LayoutBoxExtent::setAfter(LayoutUnit value) {
  // FIXME(sky): Remove
  m_bottom = value;
}

void LayoutBoxExtent::setStart(TextDirection direction, LayoutUnit value) {
  if (isLeftToRightDirection(direction))
    m_left = value;
  else
    m_right = value;
}

void LayoutBoxExtent::setEnd(TextDirection direction, LayoutUnit value) {
  if (isLeftToRightDirection(direction))
    m_right = value;
  else
    m_left = value;
}

LayoutUnit& LayoutBoxExtent::mutableLogicalLeft() {
  return m_left;
}

LayoutUnit& LayoutBoxExtent::mutableLogicalRight() {
  return m_right;
}

LayoutUnit& LayoutBoxExtent::mutableBefore() {
  return m_top;
}

LayoutUnit& LayoutBoxExtent::mutableAfter() {
  return m_bottom;
}

}  // namespace blink
