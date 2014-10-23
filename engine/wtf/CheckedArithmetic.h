/*
 * Copyright (C) 2011 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef CheckedArithmetic_h
#define CheckedArithmetic_h

#include "wtf/Assertions.h"
#include "wtf/EnumClass.h"
#include "wtf/TypeTraits.h"

#include <limits>
#include <stdint.h>

/* Checked<T>
 *
 * This class provides a mechanism to perform overflow-safe integer arithmetic
 * without having to manually ensure that you have all the required bounds checks
 * directly in your code.
 *
 * There are two modes of operation:
 *  - The default is Checked<T, CrashOnOverflow>, and crashes at the point
 *    and overflow has occurred.
 *  - The alternative is Checked<T, RecordOverflow>, which uses an additional
 *    byte of storage to track whether an overflow has occurred, subsequent
 *    unchecked operations will crash if an overflow has occured
 *
 * It is possible to provide a custom overflow handler, in which case you need
 * to support these functions:
 *  - void overflowed();
 *    This function is called when an operation has produced an overflow.
 *  - bool hasOverflowed();
 *    This function must return true if overflowed() has been called on an
 *    instance and false if it has not.
 *  - void clearOverflow();
 *    Used to reset overflow tracking when a value is being overwritten with
 *    a new value.
 *
 * Checked<T> works for all integer types, with the following caveats:
 *  - Mixing signedness of operands is only supported for types narrower than
 *    64bits.
 *  - It does have a performance impact, so tight loops may want to be careful
 *    when using it.
 *
 */

namespace WTF {

ENUM_CLASS(CheckedState)
{
    DidOverflow,
    DidNotOverflow
} ENUM_CLASS_END(CheckedState);

class CrashOnOverflow {
protected:
    NO_RETURN_DUE_TO_CRASH void overflowed()
    {
        CRASH();
    }

    void clearOverflow() { }

public:
    bool hasOverflowed() const { return false; }
};

class RecordOverflow {
protected:
    RecordOverflow()
        : m_overflowed(false)
    {
    }

    void overflowed()
    {
        m_overflowed = true;
    }

    void clearOverflow()
    {
        m_overflowed = false;
    }

public:
    bool hasOverflowed() const { return m_overflowed; }

private:
    unsigned char m_overflowed;
};

template <typename T, class OverflowHandler = CrashOnOverflow> class Checked;
template <typename T> struct RemoveChecked;
template <typename T> struct RemoveChecked<Checked<T> >;

template <typename Target, typename Source, bool targetSigned = std::numeric_limits<Target>::is_signed, bool sourceSigned = std::numeric_limits<Source>::is_signed> struct BoundsChecker;
template <typename Target, typename Source> struct BoundsChecker<Target, Source, false, false> {
    static bool inBounds(Source value)
    {
        // Same signedness so implicit type conversion will always increase precision
        // to widest type
        return value <= std::numeric_limits<Target>::max();
    }
};

template <typename Target, typename Source> struct BoundsChecker<Target, Source, true, true> {
    static bool inBounds(Source value)
    {
        // Same signedness so implicit type conversion will always increase precision
        // to widest type
        return std::numeric_limits<Target>::min() <= value && value <= std::numeric_limits<Target>::max();
    }
};

template <typename Target, typename Source> struct BoundsChecker<Target, Source, false, true> {
    static bool inBounds(Source value)
    {
        // Target is unsigned so any value less than zero is clearly unsafe
        if (value < 0)
            return false;
        // If our (unsigned) Target is the same or greater width we can
        // convert value to type Target without losing precision
        if (sizeof(Target) >= sizeof(Source))
            return static_cast<Target>(value) <= std::numeric_limits<Target>::max();
        // The signed Source type has greater precision than the target so
        // max(Target) -> Source will widen.
        return value <= static_cast<Source>(std::numeric_limits<Target>::max());
    }
};

template <typename Target, typename Source> struct BoundsChecker<Target, Source, true, false> {
    static bool inBounds(Source value)
    {
        // Signed target with an unsigned source
        if (sizeof(Target) <= sizeof(Source))
            return value <= static_cast<Source>(std::numeric_limits<Target>::max());
        // Target is Wider than Source so we're guaranteed to fit any value in
        // unsigned Source
        return true;
    }
};

template <typename Target, typename Source, bool CanElide = IsSameType<Target, Source>::value || (sizeof(Target) > sizeof(Source)) > struct BoundsCheckElider;
template <typename Target, typename Source> struct BoundsCheckElider<Target, Source, true> {
    static bool inBounds(Source) { return true; }
};
template <typename Target, typename Source> struct BoundsCheckElider<Target, Source, false> : public BoundsChecker<Target, Source> {
};

template <typename Target, typename Source> static inline bool isInBounds(Source value)
{
    return BoundsCheckElider<Target, Source>::inBounds(value);
}

template <typename T> struct RemoveChecked {
    typedef T CleanType;
    static const CleanType DefaultValue = 0;
};

template <typename T> struct RemoveChecked<Checked<T, CrashOnOverflow> > {
    typedef typename RemoveChecked<T>::CleanType CleanType;
    static const CleanType DefaultValue = 0;
};

template <typename T> struct RemoveChecked<Checked<T, RecordOverflow> > {
    typedef typename RemoveChecked<T>::CleanType CleanType;
    static const CleanType DefaultValue = 0;
};

// The ResultBase and SignednessSelector are used to workaround typeof not being
// available in MSVC
template <typename U, typename V, bool uIsBigger = (sizeof(U) > sizeof(V)), bool sameSize = (sizeof(U) == sizeof(V))> struct ResultBase;
template <typename U, typename V> struct ResultBase<U, V, true, false> {
    typedef U ResultType;
};

template <typename U, typename V> struct ResultBase<U, V, false, false> {
    typedef V ResultType;
};

template <typename U> struct ResultBase<U, U, false, true> {
    typedef U ResultType;
};

template <typename U, typename V, bool uIsSigned = std::numeric_limits<U>::is_signed, bool vIsSigned = std::numeric_limits<V>::is_signed> struct SignednessSelector;
template <typename U, typename V> struct SignednessSelector<U, V, true, true> {
    typedef U ResultType;
};

template <typename U, typename V> struct SignednessSelector<U, V, false, false> {
    typedef U ResultType;
};

template <typename U, typename V> struct SignednessSelector<U, V, true, false> {
    typedef V ResultType;
};

template <typename U, typename V> struct SignednessSelector<U, V, false, true> {
    typedef U ResultType;
};

template <typename U, typename V> struct ResultBase<U, V, false, true> {
    typedef typename SignednessSelector<U, V>::ResultType ResultType;
};

template <typename U, typename V> struct Result : ResultBase<typename RemoveChecked<U>::CleanType, typename RemoveChecked<V>::CleanType> {
};

template <typename LHS, typename RHS, typename ResultType = typename Result<LHS, RHS>::ResultType,
    bool lhsSigned = std::numeric_limits<LHS>::is_signed, bool rhsSigned = std::numeric_limits<RHS>::is_signed> struct ArithmeticOperations;

template <typename LHS, typename RHS, typename ResultType> struct ArithmeticOperations<LHS, RHS, ResultType, true, true> {
    // LHS and RHS are signed types

    // Helper function
    static inline bool signsMatch(LHS lhs, RHS rhs)
    {
        return (lhs ^ rhs) >= 0;
    }

    static inline bool add(LHS lhs, RHS rhs, ResultType& result) WARN_UNUSED_RETURN
    {
        if (signsMatch(lhs, rhs)) {
            if (lhs >= 0) {
                if ((std::numeric_limits<ResultType>::max() - rhs) < lhs)
                    return false;
            } else {
                ResultType temp = lhs - std::numeric_limits<ResultType>::min();
                if (rhs < -temp)
                    return false;
            }
        } // if the signs do not match this operation can't overflow
        result = lhs + rhs;
        return true;
    }

    static inline bool sub(LHS lhs, RHS rhs, ResultType& result) WARN_UNUSED_RETURN
    {
        if (!signsMatch(lhs, rhs)) {
            if (lhs >= 0) {
                if (lhs > std::numeric_limits<ResultType>::max() + rhs)
                    return false;
            } else {
                if (rhs > std::numeric_limits<ResultType>::max() + lhs)
                    return false;
            }
        } // if the signs match this operation can't overflow
        result = lhs - rhs;
        return true;
    }

    static inline bool multiply(LHS lhs, RHS rhs, ResultType& result) WARN_UNUSED_RETURN
    {
        if (signsMatch(lhs, rhs)) {
            if (lhs >= 0) {
                if (lhs && (std::numeric_limits<ResultType>::max() / lhs) < rhs)
                    return false;
            } else {
                if (static_cast<ResultType>(lhs) == std::numeric_limits<ResultType>::min() || static_cast<ResultType>(rhs) == std::numeric_limits<ResultType>::min())
                    return false;
                if ((std::numeric_limits<ResultType>::max() / -lhs) < -rhs)
                    return false;
            }
        } else {
            if (lhs < 0) {
                if (rhs && lhs < (std::numeric_limits<ResultType>::min() / rhs))
                    return false;
            } else {
                if (lhs && rhs < (std::numeric_limits<ResultType>::min() / lhs))
                    return false;
            }
        }
        result = lhs * rhs;
        return true;
    }

    static inline bool equals(LHS lhs, RHS rhs) { return lhs == rhs; }

};

template <typename LHS, typename RHS, typename ResultType> struct ArithmeticOperations<LHS, RHS, ResultType, false, false> {
    // LHS and RHS are unsigned types so bounds checks are nice and easy
    static inline bool add(LHS lhs, RHS rhs, ResultType& result) WARN_UNUSED_RETURN
    {
        ResultType temp = lhs + rhs;
        if (temp < lhs)
            return false;
        result = temp;
        return true;
    }

    static inline bool sub(LHS lhs, RHS rhs, ResultType& result) WARN_UNUSED_RETURN
    {
        ResultType temp = lhs - rhs;
        if (temp > lhs)
            return false;
        result = temp;
        return true;
    }

    static inline bool multiply(LHS lhs, RHS rhs, ResultType& result) WARN_UNUSED_RETURN
    {
        if (!lhs || !rhs) {
            result = 0;
            return true;
        }
        if (std::numeric_limits<ResultType>::max() / lhs < rhs)
            return false;
        result = lhs * rhs;
        return true;
    }

    static inline bool equals(LHS lhs, RHS rhs) { return lhs == rhs; }

};

template <typename ResultType> struct ArithmeticOperations<int, unsigned, ResultType, true, false> {
    static inline bool add(int64_t lhs, int64_t rhs, ResultType& result)
    {
        int64_t temp = lhs + rhs;
        if (temp < std::numeric_limits<ResultType>::min())
            return false;
        if (temp > std::numeric_limits<ResultType>::max())
            return false;
        result = static_cast<ResultType>(temp);
        return true;
    }

    static inline bool sub(int64_t lhs, int64_t rhs, ResultType& result)
    {
        int64_t temp = lhs - rhs;
        if (temp < std::numeric_limits<ResultType>::min())
            return false;
        if (temp > std::numeric_limits<ResultType>::max())
            return false;
        result = static_cast<ResultType>(temp);
        return true;
    }

    static inline bool multiply(int64_t lhs, int64_t rhs, ResultType& result)
    {
        int64_t temp = lhs * rhs;
        if (temp < std::numeric_limits<ResultType>::min())
            return false;
        if (temp > std::numeric_limits<ResultType>::max())
            return false;
        result = static_cast<ResultType>(temp);
        return true;
    }

    static inline bool equals(int lhs, unsigned rhs)
    {
        return static_cast<int64_t>(lhs) == static_cast<int64_t>(rhs);
    }
};

template <typename ResultType> struct ArithmeticOperations<unsigned, int, ResultType, false, true> {
    static inline bool add(int64_t lhs, int64_t rhs, ResultType& result)
    {
        return ArithmeticOperations<int, unsigned, ResultType>::add(rhs, lhs, result);
    }

    static inline bool sub(int64_t lhs, int64_t rhs, ResultType& result)
    {
        return ArithmeticOperations<int, unsigned, ResultType>::sub(lhs, rhs, result);
    }

    static inline bool multiply(int64_t lhs, int64_t rhs, ResultType& result)
    {
        return ArithmeticOperations<int, unsigned, ResultType>::multiply(rhs, lhs, result);
    }

    static inline bool equals(unsigned lhs, int rhs)
    {
        return ArithmeticOperations<int, unsigned, ResultType>::equals(rhs, lhs);
    }
};

template <typename U, typename V, typename R> static inline bool safeAdd(U lhs, V rhs, R& result)
{
    return ArithmeticOperations<U, V, R>::add(lhs, rhs, result);
}

template <typename U, typename V, typename R> static inline bool safeSub(U lhs, V rhs, R& result)
{
    return ArithmeticOperations<U, V, R>::sub(lhs, rhs, result);
}

template <typename U, typename V, typename R> static inline bool safeMultiply(U lhs, V rhs, R& result)
{
    return ArithmeticOperations<U, V, R>::multiply(lhs, rhs, result);
}

template <typename U, typename V> static inline bool safeEquals(U lhs, V rhs)
{
    return ArithmeticOperations<U, V>::equals(lhs, rhs);
}

enum ResultOverflowedTag { ResultOverflowed };

template <typename T, class OverflowHandler> class Checked : public OverflowHandler {
public:
    template <typename _T, class _OverflowHandler> friend class Checked;
    Checked()
        : m_value(0)
    {
    }

    Checked(ResultOverflowedTag)
        : m_value(0)
    {
        this->overflowed();
    }

    template <typename U> Checked(U value)
    {
        if (!isInBounds<T>(value))
            this->overflowed();
        m_value = static_cast<T>(value);
    }

    template <typename V> Checked(const Checked<T, V>& rhs)
        : m_value(rhs.m_value)
    {
        if (rhs.hasOverflowed())
            this->overflowed();
    }

    template <typename U> Checked(const Checked<U, OverflowHandler>& rhs)
        : OverflowHandler(rhs)
    {
        if (!isInBounds<T>(rhs.m_value))
            this->overflowed();
        m_value = static_cast<T>(rhs.m_value);
    }

    template <typename U, typename V> Checked(const Checked<U, V>& rhs)
    {
        if (rhs.hasOverflowed())
            this->overflowed();
        if (!isInBounds<T>(rhs.m_value))
            this->overflowed();
        m_value = static_cast<T>(rhs.m_value);
    }

    const Checked& operator=(Checked rhs)
    {
        this->clearOverflow();
        if (rhs.hasOverflowed())
            this->overflowed();
        m_value = static_cast<T>(rhs.m_value);
        return *this;
    }

    template <typename U> const Checked& operator=(U value)
    {
        return *this = Checked(value);
    }

    template <typename U, typename V> const Checked& operator=(const Checked<U, V>& rhs)
    {
        return *this = Checked(rhs);
    }

    // prefix
    const Checked& operator++()
    {
        if (m_value == std::numeric_limits<T>::max())
            this->overflowed();
        m_value++;
        return *this;
    }

    const Checked& operator--()
    {
        if (m_value == std::numeric_limits<T>::min())
            this->overflowed();
        m_value--;
        return *this;
    }

    // postfix operators
    const Checked operator++(int)
    {
        if (m_value == std::numeric_limits<T>::max())
            this->overflowed();
        return Checked(m_value++);
    }

    const Checked operator--(int)
    {
        if (m_value == std::numeric_limits<T>::min())
            this->overflowed();
        return Checked(m_value--);
    }

    // Boolean operators
    bool operator!() const
    {
        if (this->hasOverflowed())
            CRASH();
        return !m_value;
    }

    typedef void* (Checked::*UnspecifiedBoolType);
    operator UnspecifiedBoolType*() const
    {
        if (this->hasOverflowed())
            CRASH();
        return (m_value) ? reinterpret_cast<UnspecifiedBoolType*>(1) : 0;
    }

    // Value accessors. unsafeGet() will crash if there's been an overflow.
    T unsafeGet() const
    {
        if (this->hasOverflowed())
            CRASH();
        return m_value;
    }

    inline CheckedState safeGet(T& value) const WARN_UNUSED_RETURN
    {
        value = m_value;
        if (this->hasOverflowed())
            return CheckedState::DidOverflow;
        return CheckedState::DidNotOverflow;
    }

    // Mutating assignment
    template <typename U> const Checked operator+=(U rhs)
    {
        if (!safeAdd(m_value, rhs, m_value))
            this->overflowed();
        return *this;
    }

    template <typename U> const Checked operator-=(U rhs)
    {
        if (!safeSub(m_value, rhs, m_value))
            this->overflowed();
        return *this;
    }

    template <typename U> const Checked operator*=(U rhs)
    {
        if (!safeMultiply(m_value, rhs, m_value))
            this->overflowed();
        return *this;
    }

    const Checked operator*=(double rhs)
    {
        double result = rhs * m_value;
        // Handle +/- infinity and NaN
        if (!(std::numeric_limits<T>::min() <= result && std::numeric_limits<T>::max() >= result))
            this->overflowed();
        m_value = (T)result;
        return *this;
    }

    const Checked operator*=(float rhs)
    {
        return *this *= (double)rhs;
    }

    template <typename U, typename V> const Checked operator+=(Checked<U, V> rhs)
    {
        if (rhs.hasOverflowed())
            this->overflowed();
        return *this += rhs.m_value;
    }

    template <typename U, typename V> const Checked operator-=(Checked<U, V> rhs)
    {
        if (rhs.hasOverflowed())
            this->overflowed();
        return *this -= rhs.m_value;
    }

    template <typename U, typename V> const Checked operator*=(Checked<U, V> rhs)
    {
        if (rhs.hasOverflowed())
            this->overflowed();
        return *this *= rhs.m_value;
    }

    // Equality comparisons
    template <typename V> bool operator==(Checked<T, V> rhs)
    {
        return unsafeGet() == rhs.unsafeGet();
    }

    template <typename U> bool operator==(U rhs)
    {
        if (this->hasOverflowed())
            this->overflowed();
        return safeEquals(m_value, rhs);
    }

    template <typename U, typename V> const Checked operator==(Checked<U, V> rhs)
    {
        return unsafeGet() == Checked(rhs.unsafeGet());
    }

    template <typename U> bool operator!=(U rhs)
    {
        return !(*this == rhs);
    }

private:
    // Disallow implicit conversion of floating point to integer types
    Checked(float);
    Checked(double);
    void operator=(float);
    void operator=(double);
    void operator+=(float);
    void operator+=(double);
    void operator-=(float);
    void operator-=(double);
    T m_value;
};

template <typename U, typename V, typename OverflowHandler> static inline Checked<typename Result<U, V>::ResultType, OverflowHandler> operator+(Checked<U, OverflowHandler> lhs, Checked<V, OverflowHandler> rhs)
{
    U x = 0;
    V y = 0;
    bool overflowed = lhs.safeGet(x) == CheckedState::DidOverflow || rhs.safeGet(y) == CheckedState::DidOverflow;
    typename Result<U, V>::ResultType result = 0;
    overflowed |= !safeAdd(x, y, result);
    if (overflowed)
        return ResultOverflowed;
    return result;
}

template <typename U, typename V, typename OverflowHandler> static inline Checked<typename Result<U, V>::ResultType, OverflowHandler> operator-(Checked<U, OverflowHandler> lhs, Checked<V, OverflowHandler> rhs)
{
    U x = 0;
    V y = 0;
    bool overflowed = lhs.safeGet(x) == CheckedState::DidOverflow || rhs.safeGet(y) == CheckedState::DidOverflow;
    typename Result<U, V>::ResultType result = 0;
    overflowed |= !safeSub(x, y, result);
    if (overflowed)
        return ResultOverflowed;
    return result;
}

template <typename U, typename V, typename OverflowHandler> static inline Checked<typename Result<U, V>::ResultType, OverflowHandler> operator*(Checked<U, OverflowHandler> lhs, Checked<V, OverflowHandler> rhs)
{
    U x = 0;
    V y = 0;
    bool overflowed = lhs.safeGet(x) == CheckedState::DidOverflow || rhs.safeGet(y) == CheckedState::DidOverflow;
    typename Result<U, V>::ResultType result = 0;
    overflowed |= !safeMultiply(x, y, result);
    if (overflowed)
        return ResultOverflowed;
    return result;
}

template <typename U, typename V, typename OverflowHandler> static inline Checked<typename Result<U, V>::ResultType, OverflowHandler> operator+(Checked<U, OverflowHandler> lhs, V rhs)
{
    return lhs + Checked<V, OverflowHandler>(rhs);
}

template <typename U, typename V, typename OverflowHandler> static inline Checked<typename Result<U, V>::ResultType, OverflowHandler> operator-(Checked<U, OverflowHandler> lhs, V rhs)
{
    return lhs - Checked<V, OverflowHandler>(rhs);
}

template <typename U, typename V, typename OverflowHandler> static inline Checked<typename Result<U, V>::ResultType, OverflowHandler> operator*(Checked<U, OverflowHandler> lhs, V rhs)
{
    return lhs * Checked<V, OverflowHandler>(rhs);
}

template <typename U, typename V, typename OverflowHandler> static inline Checked<typename Result<U, V>::ResultType, OverflowHandler> operator+(U lhs, Checked<V, OverflowHandler> rhs)
{
    return Checked<U, OverflowHandler>(lhs) + rhs;
}

template <typename U, typename V, typename OverflowHandler> static inline Checked<typename Result<U, V>::ResultType, OverflowHandler> operator-(U lhs, Checked<V, OverflowHandler> rhs)
{
    return Checked<U, OverflowHandler>(lhs) - rhs;
}

template <typename U, typename V, typename OverflowHandler> static inline Checked<typename Result<U, V>::ResultType, OverflowHandler> operator*(U lhs, Checked<V, OverflowHandler> rhs)
{
    return Checked<U, OverflowHandler>(lhs) * rhs;
}

}

using WTF::Checked;
using WTF::CheckedState;
using WTF::RecordOverflow;

#endif
