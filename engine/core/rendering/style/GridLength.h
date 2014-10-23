/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
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

#ifndef GridLength_h
#define GridLength_h

#include "platform/Length.h"

namespace blink {

// This class wraps the <track-breadth> which can be either a <percentage>, <length>, min-content, max-content
// or <flex>. This class avoids spreading the knowledge of <flex> throughout the rendering directory by adding
// an new unit to Length.h.
class GridLength {
public:
    GridLength(const Length& length)
        : m_length(length)
        , m_flex(0)
        , m_type(LengthType)
    {
    }

    explicit GridLength(double flex)
        : m_flex(flex)
        , m_type(FlexType)
    {
    }

    bool isLength() const { return m_type == LengthType; }
    bool isFlex() const { return m_type == FlexType; }

    const Length& length() const { ASSERT(isLength()); return m_length; }

    double flex() const { ASSERT(isFlex()); return m_flex; }

    bool operator==(const GridLength& o) const
    {
        return m_length == o.m_length && m_flex == o.m_flex && m_type == o.m_type;
    }

    bool isContentSized() const { return m_type == LengthType && (m_length.isAuto() || m_length.isMinContent() || m_length.isMaxContent()); }

private:
    // Ideally we would put the 2 following fields in a union, but Length has a constructor,
    // a destructor and a copy assignment which isn't allowed.
    Length m_length;
    double m_flex;
    enum GridLengthType {
        LengthType,
        FlexType
    };
    GridLengthType m_type;
};

} // namespace blink

#endif // GridLength_h
