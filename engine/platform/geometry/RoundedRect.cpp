/*
 * Copyright (C) 2003, 2006, 2009 Apple Inc. All rights reserved.
 * Copyright (C) 2010 Google Inc. All rights reserved.
 * Copyright (C) 2013 Xidorn Quan (quanxunzhen@gmail.com)
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "platform/geometry/RoundedRect.h"

#include "wtf/Assertions.h"
#include <algorithm>

namespace blink {

bool RoundedRect::Radii::isZero() const
{
    return m_topLeft.isZero() && m_topRight.isZero() && m_bottomLeft.isZero() && m_bottomRight.isZero();
}

void RoundedRect::Radii::scale(float factor)
{
    if (factor == 1)
        return;

    // If either radius on a corner becomes zero, reset both radii on that corner.
    m_topLeft.scale(factor);
    if (!m_topLeft.width() || !m_topLeft.height())
        m_topLeft = IntSize();
    m_topRight.scale(factor);
    if (!m_topRight.width() || !m_topRight.height())
        m_topRight = IntSize();
    m_bottomLeft.scale(factor);
    if (!m_bottomLeft.width() || !m_bottomLeft.height())
        m_bottomLeft = IntSize();
    m_bottomRight.scale(factor);
    if (!m_bottomRight.width() || !m_bottomRight.height())
        m_bottomRight = IntSize();

}

void RoundedRect::Radii::expand(int topWidth, int bottomWidth, int leftWidth, int rightWidth)
{
    if (m_topLeft.width() > 0 && m_topLeft.height() > 0) {
        m_topLeft.setWidth(std::max<int>(0, m_topLeft.width() + leftWidth));
        m_topLeft.setHeight(std::max<int>(0, m_topLeft.height() + topWidth));
    }
    if (m_topRight.width() > 0 && m_topRight.height() > 0) {
        m_topRight.setWidth(std::max<int>(0, m_topRight.width() + rightWidth));
        m_topRight.setHeight(std::max<int>(0, m_topRight.height() + topWidth));
    }
    if (m_bottomLeft.width() > 0 && m_bottomLeft.height() > 0) {
        m_bottomLeft.setWidth(std::max<int>(0, m_bottomLeft.width() + leftWidth));
        m_bottomLeft.setHeight(std::max<int>(0, m_bottomLeft.height() + bottomWidth));
    }
    if (m_bottomRight.width() > 0 && m_bottomRight.height() > 0) {
        m_bottomRight.setWidth(std::max<int>(0, m_bottomRight.width() + rightWidth));
        m_bottomRight.setHeight(std::max<int>(0, m_bottomRight.height() + bottomWidth));
    }
}

void RoundedRect::inflateWithRadii(int size)
{
    IntRect old = m_rect;

    m_rect.inflate(size);
    // Considering the inflation factor of shorter size to scale the radii seems appropriate here
    float factor;
    if (m_rect.width() < m_rect.height())
        factor = old.width() ? (float)m_rect.width() / old.width() : int(0);
    else
        factor = old.height() ? (float)m_rect.height() / old.height() : int(0);

    m_radii.scale(factor);
}

void RoundedRect::Radii::includeLogicalEdges(const RoundedRect::Radii& edges, bool isHorizontal, bool includeLogicalLeftEdge, bool includeLogicalRightEdge)
{
    if (includeLogicalLeftEdge) {
        if (isHorizontal)
            m_bottomLeft = edges.bottomLeft();
        else
            m_topRight = edges.topRight();
        m_topLeft = edges.topLeft();
    }

    if (includeLogicalRightEdge) {
        if (isHorizontal)
            m_topRight = edges.topRight();
        else
            m_bottomLeft = edges.bottomLeft();
        m_bottomRight = edges.bottomRight();
    }
}

void RoundedRect::Radii::excludeLogicalEdges(bool isHorizontal, bool excludeLogicalLeftEdge, bool excludeLogicalRightEdge)
{
    if (excludeLogicalLeftEdge) {
        if (isHorizontal)
            m_bottomLeft = IntSize();
        else
            m_topRight = IntSize();
        m_topLeft = IntSize();
    }

    if (excludeLogicalRightEdge) {
        if (isHorizontal)
            m_topRight = IntSize();
        else
            m_bottomLeft = IntSize();
        m_bottomRight = IntSize();
    }
}

RoundedRect::RoundedRect(int x, int y, int width, int height)
    : m_rect(x, y, width, height)
{
}

RoundedRect::RoundedRect(const IntRect& rect, const Radii& radii)
    : m_rect(rect)
    , m_radii(radii)
{
}

RoundedRect::RoundedRect(const IntRect& rect, const IntSize& topLeft, const IntSize& topRight, const IntSize& bottomLeft, const IntSize& bottomRight)
    : m_rect(rect)
    , m_radii(topLeft, topRight, bottomLeft, bottomRight)
{
}

IntRect RoundedRect::radiusCenterRect() const
{
    ASSERT(isRenderable());
    int minX = m_rect.x() + std::max(m_radii.topLeft().width(), m_radii.bottomLeft().width());
    int minY = m_rect.y() + std::max(m_radii.topLeft().height(), m_radii.topRight().height());
    int maxX = m_rect.maxX() - std::max(m_radii.topRight().width(), m_radii.bottomRight().width());
    int maxY = m_rect.maxY() - std::max(m_radii.bottomLeft().height(), m_radii.bottomRight().height());
    return IntRect(minX, minY, maxX - minX, maxY - minY);
}

void RoundedRect::includeLogicalEdges(const Radii& edges, bool isHorizontal, bool includeLogicalLeftEdge, bool includeLogicalRightEdge)
{
    m_radii.includeLogicalEdges(edges, isHorizontal, includeLogicalLeftEdge, includeLogicalRightEdge);
}

void RoundedRect::excludeLogicalEdges(bool isHorizontal, bool excludeLogicalLeftEdge, bool excludeLogicalRightEdge)
{
    m_radii.excludeLogicalEdges(isHorizontal, excludeLogicalLeftEdge, excludeLogicalRightEdge);
}

bool RoundedRect::isRenderable() const
{
    return m_radii.topLeft().width() + m_radii.topRight().width() <= m_rect.width()
        && m_radii.bottomLeft().width() + m_radii.bottomRight().width() <= m_rect.width()
        && m_radii.topLeft().height() + m_radii.bottomLeft().height() <= m_rect.height()
        && m_radii.topRight().height() + m_radii.bottomRight().height() <= m_rect.height();
}

void RoundedRect::adjustRadii()
{
    int maxRadiusWidth = std::max(m_radii.topLeft().width() + m_radii.topRight().width(), m_radii.bottomLeft().width() + m_radii.bottomRight().width());
    int maxRadiusHeight = std::max(m_radii.topLeft().height() + m_radii.bottomLeft().height(), m_radii.topRight().height() + m_radii.bottomRight().height());

    if (maxRadiusWidth <= 0 || maxRadiusHeight <= 0) {
        m_radii.scale(0.0f);
        return;
    }
    float widthRatio = static_cast<float>(m_rect.width()) / maxRadiusWidth;
    float heightRatio = static_cast<float>(m_rect.height()) / maxRadiusHeight;
    m_radii.scale(widthRatio < heightRatio ? widthRatio : heightRatio);
}

bool RoundedRect::intersectsQuad(const FloatQuad& quad) const
{
    FloatRect rect(m_rect);
    if (!quad.intersectsRect(rect))
        return false;

    const IntSize& topLeft = m_radii.topLeft();
    if (!topLeft.isEmpty()) {
        FloatRect rect(m_rect.x(), m_rect.y(), topLeft.width(), topLeft.height());
        if (quad.intersectsRect(rect)) {
            FloatPoint center(m_rect.x() + topLeft.width(), m_rect.y() + topLeft.height());
            FloatSize size(topLeft.width(), topLeft.height());
            if (!quad.intersectsEllipse(center, size))
                return false;
        }
    }

    const IntSize& topRight = m_radii.topRight();
    if (!topRight.isEmpty()) {
        FloatRect rect(m_rect.maxX() - topRight.width(), m_rect.y(), topRight.width(), topRight.height());
        if (quad.intersectsRect(rect)) {
            FloatPoint center(m_rect.maxX() - topRight.width(), m_rect.y() + topRight.height());
            FloatSize size(topRight.width(), topRight.height());
            if (!quad.intersectsEllipse(center, size))
                return false;
        }
    }

    const IntSize& bottomLeft = m_radii.bottomLeft();
    if (!bottomLeft.isEmpty()) {
        FloatRect rect(m_rect.x(), m_rect.maxY() - bottomLeft.height(), bottomLeft.width(), bottomLeft.height());
        if (quad.intersectsRect(rect)) {
            FloatPoint center(m_rect.x() + bottomLeft.width(), m_rect.maxY() - bottomLeft.height());
            FloatSize size(bottomLeft.width(), bottomLeft.height());
            if (!quad.intersectsEllipse(center, size))
                return false;
        }
    }

    const IntSize& bottomRight = m_radii.bottomRight();
    if (!bottomRight.isEmpty()) {
        FloatRect rect(m_rect.maxX() - bottomRight.width(), m_rect.maxY() - bottomRight.height(), bottomRight.width(), bottomRight.height());
        if (quad.intersectsRect(rect)) {
            FloatPoint center(m_rect.maxX() - bottomRight.width(), m_rect.maxY() - bottomRight.height());
            FloatSize size(bottomRight.width(), bottomRight.height());
            if (!quad.intersectsEllipse(center, size))
                return false;
        }
    }

    return true;
}

} // namespace blink
