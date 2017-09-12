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

#ifndef SKY_ENGINE_PLATFORM_GEOMETRY_LAYOUTBOXEXTENT_H_
#define SKY_ENGINE_PLATFORM_GEOMETRY_LAYOUTBOXEXTENT_H_

#include "flutter/sky/engine/platform/LayoutUnit.h"
#include "flutter/sky/engine/platform/PlatformExport.h"
#include "flutter/sky/engine/platform/text/TextDirection.h"

namespace blink {

class PLATFORM_EXPORT LayoutBoxExtent {
 public:
  LayoutBoxExtent() : m_top(0), m_right(0), m_bottom(0), m_left(0) {}
  LayoutBoxExtent(LayoutUnit top,
                  LayoutUnit right,
                  LayoutUnit bottom,
                  LayoutUnit left)
      : m_top(top), m_right(right), m_bottom(bottom), m_left(left) {}

  inline LayoutUnit top() const { return m_top; }
  inline LayoutUnit right() const { return m_right; }
  inline LayoutUnit bottom() const { return m_bottom; }
  inline LayoutUnit left() const { return m_left; }

  inline void setTop(LayoutUnit value) { m_top = value; }
  inline void setRight(LayoutUnit value) { m_right = value; }
  inline void setBottom(LayoutUnit value) { m_bottom = value; }
  inline void setLeft(LayoutUnit value) { m_left = value; }

  LayoutUnit logicalTop() const;
  LayoutUnit logicalBottom() const;
  LayoutUnit logicalLeft() const;
  LayoutUnit logicalRight() const;

  LayoutUnit before() const;
  LayoutUnit after() const;
  LayoutUnit start(TextDirection) const;
  LayoutUnit end(TextDirection) const;

  void setBefore(LayoutUnit);
  void setAfter(LayoutUnit);
  void setStart(TextDirection, LayoutUnit);
  void setEnd(TextDirection, LayoutUnit);

  LayoutUnit& mutableLogicalLeft();
  LayoutUnit& mutableLogicalRight();

  LayoutUnit& mutableBefore();
  LayoutUnit& mutableAfter();

 private:
  LayoutUnit m_top;
  LayoutUnit m_right;
  LayoutUnit m_bottom;
  LayoutUnit m_left;
};

}  // namespace blink

#endif  // SKY_ENGINE_PLATFORM_GEOMETRY_LAYOUTBOXEXTENT_H_
