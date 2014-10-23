/* -*- Mode: C++; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*- */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/. */

/* Provides checked integers, detecting integer overflow and divide-by-0. */

// Necessary modifications are made to the original CheckedInt.h file when
// incorporating it into WebKit:
// 1) Comment out #define MOZ_CHECKEDINT_ENABLE_MOZ_ASSERTS
// 2) Comment out #include "mozilla/StandardInteger.h"
// 3) Define MOZ_DELETE
// 4) Change namespace mozilla to namespace blink

#ifndef mozilla_CheckedInt_h_
#define mozilla_CheckedInt_h_

/*
 * Build options. Comment out these #defines to disable the corresponding
 * optional feature. Disabling features may be useful for code using
 * CheckedInt outside of Mozilla (e.g. WebKit)
 */

// Enable usage of MOZ_STATIC_ASSERT to check for unsupported types.
// If disabled, static asserts are replaced by regular assert().
// #define MOZ_CHECKEDINT_ENABLE_MOZ_ASSERTS

/*
 * End of build options
 */

#ifdef MOZ_CHECKEDINT_ENABLE_MOZ_ASSERTS
#  include "mozilla/Assertions.h"
#else
#  ifndef MOZ_STATIC_ASSERT
#    include <cassert>
#    define MOZ_STATIC_ASSERT(cond, reason) assert((cond) && reason)
#    define MOZ_ASSERT(cond, reason) assert((cond) && reason)
#  endif
#endif

// #include "mozilla/StandardInteger.h"

#ifndef MOZ_DELETE
#define MOZ_DELETE
#endif

#include <climits>

namespace blink {

namespace detail {

/*
 * Step 1: manually record supported types
 *
 * What's nontrivial here is that there are different families of integer
 * types: basic integer types and stdint types. It is merrily undefined which
 * types from one family may be just typedefs for a type from another family.
 *
 * For example, on GCC 4.6, aside from the basic integer types, the only other
 * type that isn't just a typedef for some of them, is int8_t.
 */

struct UnsupportedType {};

template<typename IntegerType>
struct IsSupportedPass2
{
    static const bool value = false;
};

template<typename IntegerType>
struct IsSupported
{
    static const bool value = IsSupportedPass2<IntegerType>::value;
};

template<>
struct IsSupported<int8_t>
{ static const bool value = true; };

template<>
struct IsSupported<uint8_t>
{ static const bool value = true; };

template<>
struct IsSupported<int16_t>
{ static const bool value = true; };

template<>
struct IsSupported<uint16_t>
{ static const bool value = true; };

template<>
struct IsSupported<int32_t>
{ static const bool value = true; };

template<>
struct IsSupported<uint32_t>
{ static const bool value = true; };

template<>
struct IsSupported<int64_t>
{ static const bool value = true; };

template<>
struct IsSupported<uint64_t>
{ static const bool value = true; };


template<>
struct IsSupportedPass2<char>
{ static const bool value = true; };

template<>
struct IsSupportedPass2<unsigned char>
{ static const bool value = true; };

template<>
struct IsSupportedPass2<short>
{ static const bool value = true; };

template<>
struct IsSupportedPass2<unsigned short>
{ static const bool value = true; };

template<>
struct IsSupportedPass2<int>
{ static const bool value = true; };

template<>
struct IsSupportedPass2<unsigned>
{ static const bool value = true; };

template<>
struct IsSupportedPass2<long>
{ static const bool value = true; };

template<>
struct IsSupportedPass2<unsigned long>
{ static const bool value = true; };


/*
 * Step 2: some integer-traits kind of stuff.
 */

template<size_t Size, bool Signedness>
struct StdintTypeForSizeAndSignedness
{};

template<>
struct StdintTypeForSizeAndSignedness<1, true>
{ typedef int8_t   Type; };

template<>
struct StdintTypeForSizeAndSignedness<1, false>
{ typedef uint8_t  Type; };

template<>
struct StdintTypeForSizeAndSignedness<2, true>
{ typedef int16_t  Type; };

template<>
struct StdintTypeForSizeAndSignedness<2, false>
{ typedef uint16_t Type; };

template<>
struct StdintTypeForSizeAndSignedness<4, true>
{ typedef int32_t  Type; };

template<>
struct StdintTypeForSizeAndSignedness<4, false>
{ typedef uint32_t Type; };

template<>
struct StdintTypeForSizeAndSignedness<8, true>
{ typedef int64_t  Type; };

template<>
struct StdintTypeForSizeAndSignedness<8, false>
{ typedef uint64_t Type; };

template<typename IntegerType>
struct UnsignedType
{
    typedef typename StdintTypeForSizeAndSignedness<sizeof(IntegerType),
                                                    false>::Type Type;
};

template<typename IntegerType>
struct IsSigned
{
    static const bool value = IntegerType(-1) <= IntegerType(0);
};

template<typename IntegerType, size_t Size = sizeof(IntegerType)>
struct TwiceBiggerType
{
    typedef typename StdintTypeForSizeAndSignedness<
                       sizeof(IntegerType) * 2,
                       IsSigned<IntegerType>::value
                     >::Type Type;
};

template<typename IntegerType>
struct TwiceBiggerType<IntegerType, 8>
{
    typedef UnsupportedType Type;
};

template<typename IntegerType>
struct PositionOfSignBit
{
    static const size_t value = CHAR_BIT * sizeof(IntegerType) - 1;
};

template<typename IntegerType>
struct MinValue
{
  private:
    typedef typename UnsignedType<IntegerType>::Type UnsignedIntegerType;
    static const size_t PosOfSignBit = PositionOfSignBit<IntegerType>::value;

  public:
    // Bitwise ops may return a larger type, that's why we cast explicitly.
    // In C++, left bit shifts on signed values is undefined by the standard
    // unless the shifted value is representable.
    // Notice that signed-to-unsigned conversions are always well-defined in
    // the standard as the value congruent to 2**n, as expected. By contrast,
    // unsigned-to-signed is only well-defined if the value is representable.
    static const IntegerType value =
        IsSigned<IntegerType>::value
        ? IntegerType(UnsignedIntegerType(1) << PosOfSignBit)
        : IntegerType(0);
};

template<typename IntegerType>
struct MaxValue
{
    // Tricksy, but covered by the unit test.
    // Relies heavily on the type of MinValue<IntegerType>::value
    // being IntegerType.
    static const IntegerType value = ~MinValue<IntegerType>::value;
};

/*
 * Step 3: Implement the actual validity checks.
 *
 * Ideas taken from IntegerLib, code different.
 */

template<typename T>
inline bool
HasSignBit(T x)
{
  // In C++, right bit shifts on negative values is undefined by the standard.
  // Notice that signed-to-unsigned conversions are always well-defined in the
  // standard, as the value congruent modulo 2**n as expected. By contrast,
  // unsigned-to-signed is only well-defined if the value is representable.
  return bool(typename UnsignedType<T>::Type(x)
                >> PositionOfSignBit<T>::value);
}

// Bitwise ops may return a larger type, so it's good to use this inline
// helper guaranteeing that the result is really of type T.
template<typename T>
inline T
BinaryComplement(T x)
{
  return ~x;
}

template<typename T,
         typename U,
         bool IsTSigned = IsSigned<T>::value,
         bool IsUSigned = IsSigned<U>::value>
struct DoesRangeContainRange
{
};

template<typename T, typename U, bool Signedness>
struct DoesRangeContainRange<T, U, Signedness, Signedness>
{
    static const bool value = sizeof(T) >= sizeof(U);
};

template<typename T, typename U>
struct DoesRangeContainRange<T, U, true, false>
{
    static const bool value = sizeof(T) > sizeof(U);
};

template<typename T, typename U>
struct DoesRangeContainRange<T, U, false, true>
{
    static const bool value = false;
};

template<typename T,
         typename U,
         bool IsTSigned = IsSigned<T>::value,
         bool IsUSigned = IsSigned<U>::value,
         bool DoesTRangeContainURange = DoesRangeContainRange<T, U>::value>
struct IsInRangeImpl {};

template<typename T, typename U, bool IsTSigned, bool IsUSigned>
struct IsInRangeImpl<T, U, IsTSigned, IsUSigned, true>
{
    static bool run(U)
    {
       return true;
    }
};

template<typename T, typename U>
struct IsInRangeImpl<T, U, true, true, false>
{
    static bool run(U x)
    {
      return x <= MaxValue<T>::value && x >= MinValue<T>::value;
    }
};

template<typename T, typename U>
struct IsInRangeImpl<T, U, false, false, false>
{
    static bool run(U x)
    {
      return x <= MaxValue<T>::value;
    }
};

template<typename T, typename U>
struct IsInRangeImpl<T, U, true, false, false>
{
    static bool run(U x)
    {
      return sizeof(T) > sizeof(U) || x <= U(MaxValue<T>::value);
    }
};

template<typename T, typename U>
struct IsInRangeImpl<T, U, false, true, false>
{
    static bool run(U x)
    {
      return sizeof(T) >= sizeof(U)
             ? x >= 0
             : x >= 0 && x <= U(MaxValue<T>::value);
    }
};

template<typename T, typename U>
inline bool
IsInRange(U x)
{
  return IsInRangeImpl<T, U>::run(x);
}

template<typename T>
inline bool
IsAddValid(T x, T y)
{
  // Addition is valid if the sign of x+y is equal to either that of x or that
  // of y. Since the value of x+y is undefined if we have a signed type, we
  // compute it using the unsigned type of the same size.
  // Beware! These bitwise operations can return a larger integer type,
  // if T was a small type like int8_t, so we explicitly cast to T.

  typename UnsignedType<T>::Type ux = x;
  typename UnsignedType<T>::Type uy = y;
  typename UnsignedType<T>::Type result = ux + uy;
  return IsSigned<T>::value
         ? HasSignBit(BinaryComplement(T((result ^ x) & (result ^ y))))
         : BinaryComplement(x) >= y;
}

template<typename T>
inline bool
IsSubValid(T x, T y)
{
  // Subtraction is valid if either x and y have same sign, or x-y and x have
  // same sign. Since the value of x-y is undefined if we have a signed type,
  // we compute it using the unsigned type of the same size.
  typename UnsignedType<T>::Type ux = x;
  typename UnsignedType<T>::Type uy = y;
  typename UnsignedType<T>::Type result = ux - uy;

  return IsSigned<T>::value
         ? HasSignBit(BinaryComplement(T((result ^ x) & (x ^ y))))
         : x >= y;
}

template<typename T,
         bool IsSigned = IsSigned<T>::value,
         bool TwiceBiggerTypeIsSupported =
           IsSupported<typename TwiceBiggerType<T>::Type>::value>
struct IsMulValidImpl {};

template<typename T, bool IsSigned>
struct IsMulValidImpl<T, IsSigned, true>
{
    static bool run(T x, T y)
    {
      typedef typename TwiceBiggerType<T>::Type TwiceBiggerType;
      TwiceBiggerType product = TwiceBiggerType(x) * TwiceBiggerType(y);
      return IsInRange<T>(product);
    }
};

template<typename T>
struct IsMulValidImpl<T, true, false>
{
    static bool run(T x, T y)
    {
      const T max = MaxValue<T>::value;
      const T min = MinValue<T>::value;

      if (x == 0 || y == 0)
        return true;

      if (x > 0) {
        return y > 0
               ? x <= max / y
               : y >= min / x;
      }

      // If we reach this point, we know that x < 0.
      return y > 0
             ? x >= min / y
             : y >= max / x;
    }
};

template<typename T>
struct IsMulValidImpl<T, false, false>
{
    static bool run(T x, T y)
    {
      return y == 0 ||  x <= MaxValue<T>::value / y;
    }
};

template<typename T>
inline bool
IsMulValid(T x, T y)
{
  return IsMulValidImpl<T>::run(x, y);
}

template<typename T>
inline bool
IsDivValid(T x, T y)
{
  // Keep in mind that in the signed case, min/-1 is invalid because abs(min)>max.
  return y != 0 &&
         !(IsSigned<T>::value && x == MinValue<T>::value && y == T(-1));
}

// This is just to shut up msvc warnings about negating unsigned ints.
template<typename T, bool IsSigned = IsSigned<T>::value>
struct OppositeIfSignedImpl
{
    static T run(T x) { return -x; }
};
template<typename T>
struct OppositeIfSignedImpl<T, false>
{
    static T run(T x) { return x; }
};
template<typename T>
inline T
OppositeIfSigned(T x)
{
  return OppositeIfSignedImpl<T>::run(x);
}

} // namespace detail


/*
 * Step 4: Now define the CheckedInt class.
 */

/**
 * @class CheckedInt
 * @brief Integer wrapper class checking for integer overflow and other errors
 * @param T the integer type to wrap. Can be any type among the following:
 *            - any basic integer type such as |int|
 *            - any stdint type such as |int8_t|
 *
 * This class implements guarded integer arithmetic. Do a computation, check
 * that isValid() returns true, you then have a guarantee that no problem, such
 * as integer overflow, happened during this computation, and you can call
 * value() to get the plain integer value.
 *
 * The arithmetic operators in this class are guaranteed not to raise a signal
 * (e.g. in case of a division by zero).
 *
 * For example, suppose that you want to implement a function that computes
 * (x+y)/z, that doesn't crash if z==0, and that reports on error (divide by
 * zero or integer overflow). You could code it as follows:
   @code
   bool computeXPlusYOverZ(int x, int y, int z, int *result)
   {
       CheckedInt<int> checkedResult = (CheckedInt<int>(x) + y) / z;
       if (checkedResult.isValid()) {
           *result = checkedResult.value();
           return true;
       } else {
           return false;
       }
   }
   @endcode
 *
 * Implicit conversion from plain integers to checked integers is allowed. The
 * plain integer is checked to be in range before being casted to the
 * destination type. This means that the following lines all compile, and the
 * resulting CheckedInts are correctly detected as valid or invalid:
 * @code
   // 1 is of type int, is found to be in range for uint8_t, x is valid
   CheckedInt<uint8_t> x(1);
   // -1 is of type int, is found not to be in range for uint8_t, x is invalid
   CheckedInt<uint8_t> x(-1);
   // -1 is of type int, is found to be in range for int8_t, x is valid
   CheckedInt<int8_t> x(-1);
   // 1000 is of type int16_t, is found not to be in range for int8_t,
   // x is invalid
   CheckedInt<int8_t> x(int16_t(1000));
   // 3123456789 is of type uint32_t, is found not to be in range for int32_t,
   // x is invalid
   CheckedInt<int32_t> x(uint32_t(3123456789));
 * @endcode
 * Implicit conversion from
 * checked integers to plain integers is not allowed. As shown in the
 * above example, to get the value of a checked integer as a normal integer,
 * call value().
 *
 * Arithmetic operations between checked and plain integers is allowed; the
 * result type is the type of the checked integer.
 *
 * Checked integers of different types cannot be used in the same arithmetic
 * expression.
 *
 * There are convenience typedefs for all stdint types, of the following form
 * (these are just 2 examples):
   @code
   typedef CheckedInt<int32_t> CheckedInt32;
   typedef CheckedInt<uint16_t> CheckedUint16;
   @endcode
 */
template<typename T>
class CheckedInt
{
  protected:
    T mValue;
    bool mIsValid;

    template<typename U>
    CheckedInt(U value, bool isValid) : mValue(value), mIsValid(isValid)
    {
      MOZ_STATIC_ASSERT(detail::IsSupported<T>::value,
                        "This type is not supported by CheckedInt");
    }

  public:
    /**
     * Constructs a checked integer with given @a value. The checked integer is
     * initialized as valid or invalid depending on whether the @a value
     * is in range.
     *
     * This constructor is not explicit. Instead, the type of its argument is a
     * separate template parameter, ensuring that no conversion is performed
     * before this constructor is actually called. As explained in the above
     * documentation for class CheckedInt, this constructor checks that its
     * argument is valid.
     */
    template<typename U>
    CheckedInt(U value)
      : mValue(T(value)),
        mIsValid(detail::IsInRange<T>(value))
    {
      MOZ_STATIC_ASSERT(detail::IsSupported<T>::value,
                        "This type is not supported by CheckedInt");
    }

    /** Constructs a valid checked integer with initial value 0 */
    CheckedInt() : mValue(0), mIsValid(true)
    {
      MOZ_STATIC_ASSERT(detail::IsSupported<T>::value,
                        "This type is not supported by CheckedInt");
    }

    /** @returns the actual value */
    T value() const
    {
      MOZ_ASSERT(mIsValid, "Invalid checked integer (division by zero or integer overflow)");
      return mValue;
    }

    /**
     * @returns true if the checked integer is valid, i.e. is not the result
     * of an invalid operation or of an operation involving an invalid checked
     * integer
     */
    bool isValid() const
    {
      return mIsValid;
    }

    template<typename U>
    friend CheckedInt<U> operator +(const CheckedInt<U>& lhs,
                                    const CheckedInt<U>& rhs);
    template<typename U>
    CheckedInt& operator +=(U rhs);
    template<typename U>
    friend CheckedInt<U> operator -(const CheckedInt<U>& lhs,
                                    const CheckedInt<U> &rhs);
    template<typename U>
    CheckedInt& operator -=(U rhs);
    template<typename U>
    friend CheckedInt<U> operator *(const CheckedInt<U>& lhs,
                                    const CheckedInt<U> &rhs);
    template<typename U>
    CheckedInt& operator *=(U rhs);
    template<typename U>
    friend CheckedInt<U> operator /(const CheckedInt<U>& lhs,
                                    const CheckedInt<U> &rhs);
    template<typename U>
    CheckedInt& operator /=(U rhs);

    CheckedInt operator -() const
    {
      // Circumvent msvc warning about - applied to unsigned int.
      // if we're unsigned, the only valid case anyway is 0
      // in which case - is a no-op.
      T result = detail::OppositeIfSigned(mValue);
      /* Help the compiler perform RVO (return value optimization). */
      return CheckedInt(result,
                        mIsValid && detail::IsSubValid(T(0),
                                                       mValue));
    }

    /**
     * @returns true if the left and right hand sides are valid
     * and have the same value.
     *
     * Note that these semantics are the reason why we don't offer
     * a operator!=. Indeed, we'd want to have a!=b be equivalent to !(a==b)
     * but that would mean that whenever a or b is invalid, a!=b
     * is always true, which would be very confusing.
     *
     * For similar reasons, operators <, >, <=, >= would be very tricky to
     * specify, so we just avoid offering them.
     *
     * Notice that these == semantics are made more reasonable by these facts:
     *  1. a==b implies equality at the raw data level
     *     (the converse is false, as a==b is never true among invalids)
     *  2. This is similar to the behavior of IEEE floats, where a==b
     *     means that a and b have the same value *and* neither is NaN.
     */
    bool operator ==(const CheckedInt& other) const
    {
      return mIsValid && other.mIsValid && mValue == other.mValue;
    }

    /** prefix ++ */
    CheckedInt& operator++()
    {
      *this += 1;
      return *this;
    }

    /** postfix ++ */
    CheckedInt operator++(int)
    {
      CheckedInt tmp = *this;
      *this += 1;
      return tmp;
    }

    /** prefix -- */
    CheckedInt& operator--()
    {
      *this -= 1;
      return *this;
    }

    /** postfix -- */
    CheckedInt operator--(int)
    {
      CheckedInt tmp = *this;
      *this -= 1;
      return tmp;
    }

  private:
    /**
     * The !=, <, <=, >, >= operators are disabled:
     * see the comment on operator==.
     */
    template<typename U>
    bool operator !=(U other) const MOZ_DELETE;
    template<typename U>
    bool operator <(U other) const MOZ_DELETE;
    template<typename U>
    bool operator <=(U other) const MOZ_DELETE;
    template<typename U>
    bool operator >(U other) const MOZ_DELETE;
    template<typename U>
    bool operator >=(U other) const MOZ_DELETE;
};

#define MOZ_CHECKEDINT_BASIC_BINARY_OPERATOR(NAME, OP)                \
template<typename T>                                                  \
inline CheckedInt<T> operator OP(const CheckedInt<T> &lhs,            \
                                 const CheckedInt<T> &rhs)            \
{                                                                     \
  if (!detail::Is##NAME##Valid(lhs.mValue, rhs.mValue))               \
    return CheckedInt<T>(0, false);                                   \
                                                                      \
  return CheckedInt<T>(lhs.mValue OP rhs.mValue,                      \
                       lhs.mIsValid && rhs.mIsValid);                 \
}

MOZ_CHECKEDINT_BASIC_BINARY_OPERATOR(Add, +)
MOZ_CHECKEDINT_BASIC_BINARY_OPERATOR(Sub, -)
MOZ_CHECKEDINT_BASIC_BINARY_OPERATOR(Mul, *)
MOZ_CHECKEDINT_BASIC_BINARY_OPERATOR(Div, /)

#undef MOZ_CHECKEDINT_BASIC_BINARY_OPERATOR

// Implement castToCheckedInt<T>(x), making sure that
//  - it allows x to be either a CheckedInt<T> or any integer type
//    that can be casted to T
//  - if x is already a CheckedInt<T>, we just return a reference to it,
//    instead of copying it (optimization)

namespace detail {

template<typename T, typename U>
struct CastToCheckedIntImpl
{
    typedef CheckedInt<T> ReturnType;
    static CheckedInt<T> run(U u) { return u; }
};

template<typename T>
struct CastToCheckedIntImpl<T, CheckedInt<T> >
{
    typedef const CheckedInt<T>& ReturnType;
    static const CheckedInt<T>& run(const CheckedInt<T>& u) { return u; }
};

} // namespace detail

template<typename T, typename U>
inline typename detail::CastToCheckedIntImpl<T, U>::ReturnType
castToCheckedInt(U u)
{
  return detail::CastToCheckedIntImpl<T, U>::run(u);
}

#define MOZ_CHECKEDINT_CONVENIENCE_BINARY_OPERATORS(OP, COMPOUND_OP)  \
template<typename T>                                              \
template<typename U>                                              \
CheckedInt<T>& CheckedInt<T>::operator COMPOUND_OP(U rhs)         \
{                                                                 \
  *this = *this OP castToCheckedInt<T>(rhs);                      \
  return *this;                                                   \
}                                                                 \
template<typename T, typename U>                                  \
inline CheckedInt<T> operator OP(const CheckedInt<T> &lhs, U rhs) \
{                                                                 \
  return lhs OP castToCheckedInt<T>(rhs);                         \
}                                                                 \
template<typename T, typename U>                                  \
inline CheckedInt<T> operator OP(U lhs, const CheckedInt<T> &rhs) \
{                                                                 \
  return castToCheckedInt<T>(lhs) OP rhs;                         \
}

MOZ_CHECKEDINT_CONVENIENCE_BINARY_OPERATORS(+, +=)
MOZ_CHECKEDINT_CONVENIENCE_BINARY_OPERATORS(*, *=)
MOZ_CHECKEDINT_CONVENIENCE_BINARY_OPERATORS(-, -=)
MOZ_CHECKEDINT_CONVENIENCE_BINARY_OPERATORS(/, /=)

#undef MOZ_CHECKEDINT_CONVENIENCE_BINARY_OPERATORS

template<typename T, typename U>
inline bool
operator ==(const CheckedInt<T> &lhs, U rhs)
{
  return lhs == castToCheckedInt<T>(rhs);
}

template<typename T, typename U>
inline bool
operator ==(U  lhs, const CheckedInt<T> &rhs)
{
  return castToCheckedInt<T>(lhs) == rhs;
}

// Convenience typedefs.
typedef CheckedInt<int8_t>   CheckedInt8;
typedef CheckedInt<uint8_t>  CheckedUint8;
typedef CheckedInt<int16_t>  CheckedInt16;
typedef CheckedInt<uint16_t> CheckedUint16;
typedef CheckedInt<int32_t>  CheckedInt32;
typedef CheckedInt<uint32_t> CheckedUint32;
typedef CheckedInt<int64_t>  CheckedInt64;
typedef CheckedInt<uint64_t> CheckedUint64;

} // namespace blink

#endif /* mozilla_CheckedInt_h_ */
