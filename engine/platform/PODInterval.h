/*
 * Copyright (C) 2010 Google Inc. All rights reserved.
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

#ifndef PODInterval_h
#define PODInterval_h

#ifndef NDEBUG
#include "wtf/text/StringBuilder.h"
#endif

namespace blink {

// Class representing a closed interval which can hold an arbitrary
// Plain Old Datatype (POD) as its endpoints and a piece of user
// data. An important characteristic for the algorithms we use is that
// if two intervals have identical endpoints but different user data,
// they are not considered to be equal. This situation can arise when
// representing the vertical extents of bounding boxes of overlapping
// triangles, where the pointer to the triangle is the user data of
// the interval.
//
// *Note* that the destructors of type T and UserData will *not* be
// called by this class. They must not allocate any memory that is
// required to be cleaned up in their destructors.
//
// The following constructors and operators must be implemented on
// type T:
//
//   - Copy constructor (if user data is desired)
//   - operator<
//   - operator==
//   - operator=
//
// If the UserData type is specified, it must support a copy
// constructor and assignment operator.
//
// In debug mode, printing of intervals and the data they contain is
// enabled. This requires the following template specializations to be
// available:
//
//   template<> struct ValueToString<T> {
//       static String string(const T& t);
//   };
//   template<> struct ValueToString<UserData> {
//       static String string(const UserData& t);
//   };
//
// Note that this class requires a copy constructor and assignment
// operator in order to be stored in the red-black tree.

#ifndef NDEBUG
template<class T>
struct ValueToString;
#endif

template<class T, class UserData = void*>
class PODInterval {
public:
    // Constructor from endpoints. This constructor only works when the
    // UserData type is a pointer or other type which can be initialized
    // with 0.
    PODInterval(const T& low, const T& high)
        : m_low(low)
        , m_high(high)
        , m_data(0)
        , m_maxHigh(high)
    {
    }

    // Constructor from two endpoints plus explicit user data.
    PODInterval(const T& low, const T& high, const UserData data)
        : m_low(low)
        , m_high(high)
        , m_data(data)
        , m_maxHigh(high)
    {
    }

    const T& low() const { return m_low; }
    const T& high() const { return m_high; }
    const UserData& data() const { return m_data; }

    bool overlaps(const T& low, const T& high) const
    {
        if (this->high() < low)
            return false;
        if (high < this->low())
            return false;
        return true;
    }

    bool overlaps(const PODInterval& other) const
    {
        return overlaps(other.low(), other.high());
    }

    // Returns true if this interval is "less" than the other. The
    // comparison is performed on the low endpoints of the intervals.
    bool operator<(const PODInterval& other) const
    {
        return low() < other.low();
    }

    // Returns true if this interval is strictly equal to the other,
    // including comparison of the user data.
    bool operator==(const PODInterval& other) const
    {
        return (low() == other.low() && high() == other.high() && data() == other.data());
    }

    const T& maxHigh() const { return m_maxHigh; }
    void setMaxHigh(const T& maxHigh) { m_maxHigh = maxHigh; }

#ifndef NDEBUG
    // Support for printing PODIntervals.
    String toString() const
    {
        StringBuilder builder;
        builder.appendLiteral("[PODInterval (");
        builder.append(ValueToString<T>::string(low()));
        builder.appendLiteral(", ");
        builder.append(ValueToString<T>::string(high()));
        builder.appendLiteral("), data=");
        builder.append(ValueToString<UserData>::string(data()));
        builder.appendLiteral(", maxHigh=");
        builder.append(ValueToString<T>::string(maxHigh()));
        builder.append(']');
        return builder.toString();
    }
#endif

private:
    T m_low;
    T m_high;
    UserData m_data;
    T m_maxHigh;
};

} // namespace blink

#endif // PODInterval_h
