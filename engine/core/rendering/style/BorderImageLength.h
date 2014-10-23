/*
 * Copyright (c) 2013, Opera Software ASA. All rights reserved.
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
 *     * Neither the name of Opera Software ASA nor the names of its
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

#ifndef BorderImageLength_h
#define BorderImageLength_h

#include "platform/Length.h"

namespace blink {

// Represents an individual computed border image width or outset.
//
// http://www.w3.org/TR/css3-background/#border-image-width
// http://www.w3.org/TR/css3-background/#border-image-outset
class BorderImageLength {
public:
    BorderImageLength(double number)
        : m_number(number)
        , m_type(NumberType)
    {
    }

    BorderImageLength(const Length& length)
        : m_length(length)
        , m_number(0)
        , m_type(LengthType)
    {
    }

    bool isNumber() const { return m_type == NumberType; }
    bool isLength() const { return m_type == LengthType; }

    const Length& length() const { ASSERT(isLength()); return m_length; }
    Length& length() { ASSERT(isLength()); return m_length; }

    double number() const { ASSERT(isNumber()); return m_number; }

    bool operator==(const BorderImageLength& other) const
    {
        return m_type == other.m_type && m_length == other.m_length && m_number == other.m_number;
    }

    bool isZero() const
    {
        return (isLength() && m_length.isZero()) || (isNumber() && m_number);
    }

private:
    // Ideally we would put the 2 following fields in a union, but Length has a constructor,
    // a destructor and a copy assignment which isn't allowed.
    Length m_length;
    double m_number;
    enum {
        LengthType,
        NumberType
    } m_type;
};

} // namespace blink

#endif // BorderImageLength_h
