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

#include "config.h"
#include "platform/geometry/FloatRoundedRect.h"

#include <algorithm>

namespace blink {

FloatRoundedRect::FloatRoundedRect(float x, float y, float width, float height)
    : m_rect(x, y, width, height)
{
}

FloatRoundedRect::FloatRoundedRect(const FloatRect& rect, const Radii& radii)
    : m_rect(rect)
    , m_radii(radii)
{
}

FloatRoundedRect::FloatRoundedRect(const FloatRect& rect, const FloatSize& topLeft, const FloatSize& topRight, const FloatSize& bottomLeft, const FloatSize& bottomRight)
    : m_rect(rect)
    , m_radii(topLeft, topRight, bottomLeft, bottomRight)
{
}

bool FloatRoundedRect::Radii::isZero() const
{
    return m_topLeft.isZero() && m_topRight.isZero() && m_bottomLeft.isZero() && m_bottomRight.isZero();
}

void FloatRoundedRect::Radii::scale(float factor)
{
    if (factor == 1)
        return;

    // If either radius on a corner becomes zero, reset both radii on that corner.
    m_topLeft.scale(factor);
    if (!m_topLeft.width() || !m_topLeft.height())
        m_topLeft = FloatSize();
    m_topRight.scale(factor);
    if (!m_topRight.width() || !m_topRight.height())
        m_topRight = FloatSize();
    m_bottomLeft.scale(factor);
    if (!m_bottomLeft.width() || !m_bottomLeft.height())
        m_bottomLeft = FloatSize();
    m_bottomRight.scale(factor);
    if (!m_bottomRight.width() || !m_bottomRight.height())
        m_bottomRight = FloatSize();

}

void FloatRoundedRect::Radii::expand(float topWidth, float bottomWidth, float leftWidth, float rightWidth)
{
    if (m_topLeft.width() > 0 && m_topLeft.height() > 0) {
        m_topLeft.setWidth(std::max<float>(0, m_topLeft.width() + leftWidth));
        m_topLeft.setHeight(std::max<float>(0, m_topLeft.height() + topWidth));
    }
    if (m_topRight.width() > 0 && m_topRight.height() > 0) {
        m_topRight.setWidth(std::max<float>(0, m_topRight.width() + rightWidth));
        m_topRight.setHeight(std::max<float>(0, m_topRight.height() + topWidth));
    }
    if (m_bottomLeft.width() > 0 && m_bottomLeft.height() > 0) {
        m_bottomLeft.setWidth(std::max<float>(0, m_bottomLeft.width() + leftWidth));
        m_bottomLeft.setHeight(std::max<float>(0, m_bottomLeft.height() + bottomWidth));
    }
    if (m_bottomRight.width() > 0 && m_bottomRight.height() > 0) {
        m_bottomRight.setWidth(std::max<float>(0, m_bottomRight.width() + rightWidth));
        m_bottomRight.setHeight(std::max<float>(0, m_bottomRight.height() + bottomWidth));
    }
}

static inline float cornerRectIntercept(float y, const FloatRect& cornerRect)
{
    ASSERT(cornerRect.height() > 0);
    return cornerRect.width() * sqrt(1 - (y * y) / (cornerRect.height() * cornerRect.height()));
}

bool FloatRoundedRect::xInterceptsAtY(float y, float& minXIntercept, float& maxXIntercept) const
{
    if (y < rect().y() || y >  rect().maxY())
        return false;

    if (!isRounded()) {
        minXIntercept = rect().x();
        maxXIntercept = rect().maxX();
        return true;
    }

    const FloatRect& topLeftRect = topLeftCorner();
    const FloatRect& bottomLeftRect = bottomLeftCorner();

    if (!topLeftRect.isEmpty() && y >= topLeftRect.y() && y < topLeftRect.maxY())
        minXIntercept = topLeftRect.maxX() - cornerRectIntercept(topLeftRect.maxY() - y, topLeftRect);
    else if (!bottomLeftRect.isEmpty() && y >= bottomLeftRect.y() && y <= bottomLeftRect.maxY())
        minXIntercept =  bottomLeftRect.maxX() - cornerRectIntercept(y - bottomLeftRect.y(), bottomLeftRect);
    else
        minXIntercept = m_rect.x();

    const FloatRect& topRightRect = topRightCorner();
    const FloatRect& bottomRightRect = bottomRightCorner();

    if (!topRightRect.isEmpty() && y >= topRightRect.y() && y <= topRightRect.maxY())
        maxXIntercept = topRightRect.x() + cornerRectIntercept(topRightRect.maxY() - y, topRightRect);
    else if (!bottomRightRect.isEmpty() && y >= bottomRightRect.y() && y <= bottomRightRect.maxY())
        maxXIntercept = bottomRightRect.x() + cornerRectIntercept(y - bottomRightRect.y(), bottomRightRect);
    else
        maxXIntercept = m_rect.maxX();

    return true;
}

} // namespace blink
