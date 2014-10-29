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

#include "config.h"
#include "platform/geometry/LayoutBoxExtent.h"

#include "wtf/Assertions.h"

namespace blink {

LayoutUnit LayoutBoxExtent::logicalTop() const
{
    return isHorizontalWritingMode() ? m_top : m_left;
}

LayoutUnit LayoutBoxExtent::logicalBottom() const
{
    return isHorizontalWritingMode() ? m_bottom : m_right;
}

LayoutUnit LayoutBoxExtent::logicalLeft() const
{
    return isHorizontalWritingMode() ? m_left : m_top;
}

LayoutUnit LayoutBoxExtent::logicalRight() const
{
    return isHorizontalWritingMode() ? m_right : m_bottom;
}

LayoutUnit LayoutBoxExtent::before() const
{
    // FIXME(sky): Remove
    return m_top;
}

LayoutUnit LayoutBoxExtent::after() const
{
    // FIXME(sky): Remove
    return m_bottom;
}

LayoutUnit LayoutBoxExtent::start(TextDirection direction) const
{
    if (isHorizontalWritingMode())
        return isLeftToRightDirection(direction) ? m_left : m_right;
    return isLeftToRightDirection(direction) ? m_top : m_bottom;
}

LayoutUnit LayoutBoxExtent::end(TextDirection direction) const
{
    if (isHorizontalWritingMode())
        return isLeftToRightDirection(direction) ? m_right : m_left;
    return isLeftToRightDirection(direction) ? m_bottom : m_top;
}

void LayoutBoxExtent::setBefore(LayoutUnit value)
{
    // FIXME(sky): Remove
    m_top = value;
}

void LayoutBoxExtent::setAfter(LayoutUnit value)
{
    // FIXME(sky): Remove
    m_bottom = value;
}

void LayoutBoxExtent::setStart(TextDirection direction, LayoutUnit value)
{
    if (isHorizontalWritingMode()) {
        if (isLeftToRightDirection(direction))
            m_left = value;
        else
            m_right = value;
    } else {
        if (isLeftToRightDirection(direction))
            m_top = value;
        else
            m_bottom = value;
    }
}

void LayoutBoxExtent::setEnd(TextDirection direction, LayoutUnit value)
{
    if (isHorizontalWritingMode()) {
        if (isLeftToRightDirection(direction))
            m_right = value;
        else
            m_left = value;
    } else {
        if (isLeftToRightDirection(direction))
            m_bottom = value;
        else
            m_top = value;
    }
}

LayoutUnit& LayoutBoxExtent::mutableLogicalLeft()
{
    return isHorizontalWritingMode() ? m_left : m_top;
}

LayoutUnit& LayoutBoxExtent::mutableLogicalRight()
{
    return isHorizontalWritingMode() ? m_right : m_bottom;
}

LayoutUnit& LayoutBoxExtent::mutableBefore()
{
    return isHorizontalWritingMode() ?
        (isFlippedBlocksWritingMode() ? m_bottom : m_top) :
        (isFlippedBlocksWritingMode() ? m_right: m_left);
}

LayoutUnit& LayoutBoxExtent::mutableAfter()
{
    return isHorizontalWritingMode() ?
        (isFlippedBlocksWritingMode() ? m_top : m_bottom) :
        (isFlippedBlocksWritingMode() ? m_left: m_right);
}

} // namespace blink
