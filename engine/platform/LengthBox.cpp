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
#include "platform/LengthBox.h"

namespace blink {

const Length& LengthBox::logicalLeft(WritingMode writingMode) const
{
    return isHorizontalWritingMode(writingMode) ? m_left : m_top;
}

const Length& LengthBox::logicalRight(WritingMode writingMode) const
{
    return isHorizontalWritingMode(writingMode) ? m_right : m_bottom;
}

const Length& LengthBox::before(WritingMode writingMode) const
{
    switch (writingMode) {
    case TopToBottomWritingMode:
        return m_top;
    case BottomToTopWritingMode:
        return m_bottom;
    case LeftToRightWritingMode:
        return m_left;
    case RightToLeftWritingMode:
        return m_right;
    }
    ASSERT_NOT_REACHED();
    return m_top;
}

const Length& LengthBox::after(WritingMode writingMode) const
{
    switch (writingMode) {
    case TopToBottomWritingMode:
        return m_bottom;
    case BottomToTopWritingMode:
        return m_top;
    case LeftToRightWritingMode:
        return m_right;
    case RightToLeftWritingMode:
        return m_left;
    }
    ASSERT_NOT_REACHED();
    return m_bottom;
}

const Length& LengthBox::start(WritingMode writingMode, TextDirection direction) const
{
    if (isHorizontalWritingMode(writingMode))
        return isLeftToRightDirection(direction) ? m_left : m_right;
    return isLeftToRightDirection(direction) ? m_top : m_bottom;
}

const Length& LengthBox::end(WritingMode writingMode, TextDirection direction) const
{
    if (isHorizontalWritingMode(writingMode))
        return isLeftToRightDirection(direction) ? m_right : m_left;
    return isLeftToRightDirection(direction) ? m_bottom : m_top;
}

} // namespace blink
