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

#ifndef SKY_ENGINE_CORE_RENDERING_STYLE_BORDERDATA_H_
#define SKY_ENGINE_CORE_RENDERING_STYLE_BORDERDATA_H_

#include "flutter/sky/engine/core/rendering/style/BorderValue.h"
#include "flutter/sky/engine/platform/LengthSize.h"
#include "flutter/sky/engine/platform/geometry/IntRect.h"

namespace blink {

class BorderData {
  friend class RenderStyle;

 public:
  BorderData()
      : m_topLeft(Length(0, Fixed), Length(0, Fixed)),
        m_topRight(Length(0, Fixed), Length(0, Fixed)),
        m_bottomLeft(Length(0, Fixed), Length(0, Fixed)),
        m_bottomRight(Length(0, Fixed), Length(0, Fixed)) {}
  bool hasBorder() const {
    return m_left.nonZero() || m_right.nonZero() || m_top.nonZero() ||
           m_bottom.nonZero();
  }

  bool hasBorderRadius() const {
    if (!m_topLeft.width().isZero())
      return true;
    if (!m_topRight.width().isZero())
      return true;
    if (!m_bottomLeft.width().isZero())
      return true;
    if (!m_bottomRight.width().isZero())
      return true;
    return false;
  }

  unsigned borderLeftWidth() const {
    if ((m_left.style() == BNONE || m_left.style() == BHIDDEN))
      return 0;
    return m_left.width();
  }

  unsigned borderRightWidth() const {
    if ((m_right.style() == BNONE || m_right.style() == BHIDDEN))
      return 0;
    return m_right.width();
  }

  unsigned borderTopWidth() const {
    if ((m_top.style() == BNONE || m_top.style() == BHIDDEN))
      return 0;
    return m_top.width();
  }

  unsigned borderBottomWidth() const {
    if ((m_bottom.style() == BNONE || m_bottom.style() == BHIDDEN))
      return 0;
    return m_bottom.width();
  }

  bool operator==(const BorderData& o) const {
    return m_left == o.m_left && m_right == o.m_right && m_top == o.m_top &&
           m_bottom == o.m_bottom && m_topLeft == o.m_topLeft &&
           m_topRight == o.m_topRight && m_bottomLeft == o.m_bottomLeft &&
           m_bottomRight == o.m_bottomRight;
  }

  bool visuallyEqual(const BorderData& o) const {
    return m_left.visuallyEqual(o.m_left) && m_right.visuallyEqual(o.m_right) &&
           m_top.visuallyEqual(o.m_top) && m_bottom.visuallyEqual(o.m_bottom) &&
           m_topLeft == o.m_topLeft && m_topRight == o.m_topRight &&
           m_bottomLeft == o.m_bottomLeft && m_bottomRight == o.m_bottomRight;
  }

  bool operator!=(const BorderData& o) const { return !(*this == o); }

  const BorderValue& left() const { return m_left; }
  const BorderValue& right() const { return m_right; }
  const BorderValue& top() const { return m_top; }
  const BorderValue& bottom() const { return m_bottom; }

  const LengthSize& topLeft() const { return m_topLeft; }
  const LengthSize& topRight() const { return m_topRight; }
  const LengthSize& bottomLeft() const { return m_bottomLeft; }
  const LengthSize& bottomRight() const { return m_bottomRight; }

 private:
  BorderValue m_left;
  BorderValue m_right;
  BorderValue m_top;
  BorderValue m_bottom;

  LengthSize m_topLeft;
  LengthSize m_topRight;
  LengthSize m_bottomLeft;
  LengthSize m_bottomRight;
};

}  // namespace blink

#endif  // SKY_ENGINE_CORE_RENDERING_STYLE_BORDERDATA_H_
