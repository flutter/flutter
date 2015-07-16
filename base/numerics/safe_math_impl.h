// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_NUMERICS_SAFE_MATH_IMPL_H_
#define BASE_NUMERICS_SAFE_MATH_IMPL_H_

#include <stdint.h>

#include <cmath>
#include <cstdlib>
#include <limits>

#include "base/numerics/safe_conversions.h"
#include "base/template_util.h"

namespace base {
namespace internal {

// Everything from here up to the floating point operations is portable C++,
// but it may not be fast. This code could be split based on
// platform/architecture and replaced with potentially faster implementations.

// Integer promotion templates used by the portable checked integer arithmetic.
template <size_t Size, bool IsSigned>
struct IntegerForSizeAndSign;
template <>
struct IntegerForSizeAndSign<1, true> {
  typedef int8_t type;
};
template <>
struct IntegerForSizeAndSign<1, false> {
  typedef uint8_t type;
};
template <>
struct IntegerForSizeAndSign<2, true> {
  typedef int16_t type;
};
template <>
struct IntegerForSizeAndSign<2, false> {
  typedef uint16_t type;
};
template <>
struct IntegerForSizeAndSign<4, true> {
  typedef int32_t type;
};
template <>
struct IntegerForSizeAndSign<4, false> {
  typedef uint32_t type;
};
template <>
struct IntegerForSizeAndSign<8, true> {
  typedef int64_t type;
};
template <>
struct IntegerForSizeAndSign<8, false> {
  typedef uint64_t type;
};

// WARNING: We have no IntegerForSizeAndSign<16, *>. If we ever add one to
// support 128-bit math, then the ArithmeticPromotion template below will need
// to be updated (or more likely replaced with a decltype expression).

template <typename Integer>
struct UnsignedIntegerForSize {
  typedef typename enable_if<
      std::numeric_limits<Integer>::is_integer,
      typename IntegerForSizeAndSign<sizeof(Integer), false>::type>::type type;
};

template <typename Integer>
struct SignedIntegerForSize {
  typedef typename enable_if<
      std::numeric_limits<Integer>::is_integer,
      typename IntegerForSizeAndSign<sizeof(Integer), true>::type>::type type;
};

template <typename Integer>
struct TwiceWiderInteger {
  typedef typename enable_if<
      std::numeric_limits<Integer>::is_integer,
      typename IntegerForSizeAndSign<
          sizeof(Integer) * 2,
          std::numeric_limits<Integer>::is_signed>::type>::type type;
};

template <typename Integer>
struct PositionOfSignBit {
  static const typename enable_if<std::numeric_limits<Integer>::is_integer,
                                  size_t>::type value = 8 * sizeof(Integer) - 1;
};

// Helper templates for integer manipulations.

template <typename T>
bool HasSignBit(T x) {
  // Cast to unsigned since right shift on signed is undefined.
  return !!(static_cast<typename UnsignedIntegerForSize<T>::type>(x) >>
            PositionOfSignBit<T>::value);
}

// This wrapper undoes the standard integer promotions.
template <typename T>
T BinaryComplement(T x) {
  return ~x;
}

// Here are the actual portable checked integer math implementations.
// TODO(jschuh): Break this code out from the enable_if pattern and find a clean
// way to coalesce things into the CheckedNumericState specializations below.

template <typename T>
typename enable_if<std::numeric_limits<T>::is_integer, T>::type
CheckedAdd(T x, T y, RangeConstraint* validity) {
  // Since the value of x+y is undefined if we have a signed type, we compute
  // it using the unsigned type of the same size.
  typedef typename UnsignedIntegerForSize<T>::type UnsignedDst;
  UnsignedDst ux = static_cast<UnsignedDst>(x);
  UnsignedDst uy = static_cast<UnsignedDst>(y);
  UnsignedDst uresult = ux + uy;
  // Addition is valid if the sign of (x + y) is equal to either that of x or
  // that of y.
  if (std::numeric_limits<T>::is_signed) {
    if (HasSignBit(BinaryComplement((uresult ^ ux) & (uresult ^ uy))))
      *validity = RANGE_VALID;
    else  // Direction of wrap is inverse of result sign.
      *validity = HasSignBit(uresult) ? RANGE_OVERFLOW : RANGE_UNDERFLOW;

  } else {  // Unsigned is either valid or overflow.
    *validity = BinaryComplement(x) >= y ? RANGE_VALID : RANGE_OVERFLOW;
  }
  return static_cast<T>(uresult);
}

template <typename T>
typename enable_if<std::numeric_limits<T>::is_integer, T>::type
CheckedSub(T x, T y, RangeConstraint* validity) {
  // Since the value of x+y is undefined if we have a signed type, we compute
  // it using the unsigned type of the same size.
  typedef typename UnsignedIntegerForSize<T>::type UnsignedDst;
  UnsignedDst ux = static_cast<UnsignedDst>(x);
  UnsignedDst uy = static_cast<UnsignedDst>(y);
  UnsignedDst uresult = ux - uy;
  // Subtraction is valid if either x and y have same sign, or (x-y) and x have
  // the same sign.
  if (std::numeric_limits<T>::is_signed) {
    if (HasSignBit(BinaryComplement((uresult ^ ux) & (ux ^ uy))))
      *validity = RANGE_VALID;
    else  // Direction of wrap is inverse of result sign.
      *validity = HasSignBit(uresult) ? RANGE_OVERFLOW : RANGE_UNDERFLOW;

  } else {  // Unsigned is either valid or underflow.
    *validity = x >= y ? RANGE_VALID : RANGE_UNDERFLOW;
  }
  return static_cast<T>(uresult);
}

// Integer multiplication is a bit complicated. In the fast case we just
// we just promote to a twice wider type, and range check the result. In the
// slow case we need to manually check that the result won't be truncated by
// checking with division against the appropriate bound.
template <typename T>
typename enable_if<
    std::numeric_limits<T>::is_integer && sizeof(T) * 2 <= sizeof(uintmax_t),
    T>::type
CheckedMul(T x, T y, RangeConstraint* validity) {
  typedef typename TwiceWiderInteger<T>::type IntermediateType;
  IntermediateType tmp =
      static_cast<IntermediateType>(x) * static_cast<IntermediateType>(y);
  *validity = DstRangeRelationToSrcRange<T>(tmp);
  return static_cast<T>(tmp);
}

template <typename T>
typename enable_if<std::numeric_limits<T>::is_integer&& std::numeric_limits<
                       T>::is_signed&&(sizeof(T) * 2 > sizeof(uintmax_t)),
                   T>::type
CheckedMul(T x, T y, RangeConstraint* validity) {
  // If either side is zero then the result will be zero.
  if (!x || !y) {
    return RANGE_VALID;

  } else if (x > 0) {
    if (y > 0)
      *validity =
          x <= std::numeric_limits<T>::max() / y ? RANGE_VALID : RANGE_OVERFLOW;
    else
      *validity = y >= std::numeric_limits<T>::min() / x ? RANGE_VALID
                                                         : RANGE_UNDERFLOW;

  } else {
    if (y > 0)
      *validity = x >= std::numeric_limits<T>::min() / y ? RANGE_VALID
                                                         : RANGE_UNDERFLOW;
    else
      *validity =
          y >= std::numeric_limits<T>::max() / x ? RANGE_VALID : RANGE_OVERFLOW;
  }

  return x * y;
}

template <typename T>
typename enable_if<std::numeric_limits<T>::is_integer &&
                       !std::numeric_limits<T>::is_signed &&
                       (sizeof(T) * 2 > sizeof(uintmax_t)),
                   T>::type
CheckedMul(T x, T y, RangeConstraint* validity) {
  *validity = (y == 0 || x <= std::numeric_limits<T>::max() / y)
                  ? RANGE_VALID
                  : RANGE_OVERFLOW;
  return x * y;
}

// Division just requires a check for an invalid negation on signed min/-1.
template <typename T>
T CheckedDiv(
    T x,
    T y,
    RangeConstraint* validity,
    typename enable_if<std::numeric_limits<T>::is_integer, int>::type = 0) {
  if (std::numeric_limits<T>::is_signed && x == std::numeric_limits<T>::min() &&
      y == static_cast<T>(-1)) {
    *validity = RANGE_OVERFLOW;
    return std::numeric_limits<T>::min();
  }

  *validity = RANGE_VALID;
  return x / y;
}

template <typename T>
typename enable_if<
    std::numeric_limits<T>::is_integer&& std::numeric_limits<T>::is_signed,
    T>::type
CheckedMod(T x, T y, RangeConstraint* validity) {
  *validity = y > 0 ? RANGE_VALID : RANGE_INVALID;
  return x % y;
}

template <typename T>
typename enable_if<
    std::numeric_limits<T>::is_integer && !std::numeric_limits<T>::is_signed,
    T>::type
CheckedMod(T x, T y, RangeConstraint* validity) {
  *validity = RANGE_VALID;
  return x % y;
}

template <typename T>
typename enable_if<
    std::numeric_limits<T>::is_integer&& std::numeric_limits<T>::is_signed,
    T>::type
CheckedNeg(T value, RangeConstraint* validity) {
  *validity =
      value != std::numeric_limits<T>::min() ? RANGE_VALID : RANGE_OVERFLOW;
  // The negation of signed min is min, so catch that one.
  return -value;
}

template <typename T>
typename enable_if<
    std::numeric_limits<T>::is_integer && !std::numeric_limits<T>::is_signed,
    T>::type
CheckedNeg(T value, RangeConstraint* validity) {
  // The only legal unsigned negation is zero.
  *validity = value ? RANGE_UNDERFLOW : RANGE_VALID;
  return static_cast<T>(
      -static_cast<typename SignedIntegerForSize<T>::type>(value));
}

template <typename T>
typename enable_if<
    std::numeric_limits<T>::is_integer&& std::numeric_limits<T>::is_signed,
    T>::type
CheckedAbs(T value, RangeConstraint* validity) {
  *validity =
      value != std::numeric_limits<T>::min() ? RANGE_VALID : RANGE_OVERFLOW;
  return static_cast<T>(std::abs(value));
}

template <typename T>
typename enable_if<
    std::numeric_limits<T>::is_integer && !std::numeric_limits<T>::is_signed,
    T>::type
CheckedAbs(T value, RangeConstraint* validity) {
  // Absolute value of a positive is just its identiy.
  *validity = RANGE_VALID;
  return value;
}

// These are the floating point stubs that the compiler needs to see. Only the
// negation operation is ever called.
#define BASE_FLOAT_ARITHMETIC_STUBS(NAME)                        \
  template <typename T>                                          \
  typename enable_if<std::numeric_limits<T>::is_iec559, T>::type \
  Checked##NAME(T, T, RangeConstraint*) {                        \
    NOTREACHED();                                                \
    return 0;                                                    \
  }

BASE_FLOAT_ARITHMETIC_STUBS(Add)
BASE_FLOAT_ARITHMETIC_STUBS(Sub)
BASE_FLOAT_ARITHMETIC_STUBS(Mul)
BASE_FLOAT_ARITHMETIC_STUBS(Div)
BASE_FLOAT_ARITHMETIC_STUBS(Mod)

#undef BASE_FLOAT_ARITHMETIC_STUBS

template <typename T>
typename enable_if<std::numeric_limits<T>::is_iec559, T>::type CheckedNeg(
    T value,
    RangeConstraint*) {
  return -value;
}

template <typename T>
typename enable_if<std::numeric_limits<T>::is_iec559, T>::type CheckedAbs(
    T value,
    RangeConstraint*) {
  return std::abs(value);
}

// Floats carry around their validity state with them, but integers do not. So,
// we wrap the underlying value in a specialization in order to hide that detail
// and expose an interface via accessors.
enum NumericRepresentation {
  NUMERIC_INTEGER,
  NUMERIC_FLOATING,
  NUMERIC_UNKNOWN
};

template <typename NumericType>
struct GetNumericRepresentation {
  static const NumericRepresentation value =
      std::numeric_limits<NumericType>::is_integer
          ? NUMERIC_INTEGER
          : (std::numeric_limits<NumericType>::is_iec559 ? NUMERIC_FLOATING
                                                         : NUMERIC_UNKNOWN);
};

template <typename T, NumericRepresentation type =
                          GetNumericRepresentation<T>::value>
class CheckedNumericState {};

// Integrals require quite a bit of additional housekeeping to manage state.
template <typename T>
class CheckedNumericState<T, NUMERIC_INTEGER> {
 private:
  T value_;
  RangeConstraint validity_;

 public:
  template <typename Src, NumericRepresentation type>
  friend class CheckedNumericState;

  CheckedNumericState() : value_(0), validity_(RANGE_VALID) {}

  template <typename Src>
  CheckedNumericState(Src value, RangeConstraint validity)
      : value_(static_cast<T>(value)),
        validity_(GetRangeConstraint(validity |
                                     DstRangeRelationToSrcRange<T>(value))) {
    static_assert(std::numeric_limits<Src>::is_specialized,
                  "Argument must be numeric.");
  }

  // Copy constructor.
  template <typename Src>
  CheckedNumericState(const CheckedNumericState<Src>& rhs)
      : value_(static_cast<T>(rhs.value())),
        validity_(GetRangeConstraint(
            rhs.validity() | DstRangeRelationToSrcRange<T>(rhs.value()))) {}

  template <typename Src>
  explicit CheckedNumericState(
      Src value,
      typename enable_if<std::numeric_limits<Src>::is_specialized, int>::type =
          0)
      : value_(static_cast<T>(value)),
        validity_(DstRangeRelationToSrcRange<T>(value)) {}

  RangeConstraint validity() const { return validity_; }
  T value() const { return value_; }
};

// Floating points maintain their own validity, but need translation wrappers.
template <typename T>
class CheckedNumericState<T, NUMERIC_FLOATING> {
 private:
  T value_;

 public:
  template <typename Src, NumericRepresentation type>
  friend class CheckedNumericState;

  CheckedNumericState() : value_(0.0) {}

  template <typename Src>
  CheckedNumericState(
      Src value,
      RangeConstraint validity,
      typename enable_if<std::numeric_limits<Src>::is_integer, int>::type = 0) {
    switch (DstRangeRelationToSrcRange<T>(value)) {
      case RANGE_VALID:
        value_ = static_cast<T>(value);
        break;

      case RANGE_UNDERFLOW:
        value_ = -std::numeric_limits<T>::infinity();
        break;

      case RANGE_OVERFLOW:
        value_ = std::numeric_limits<T>::infinity();
        break;

      case RANGE_INVALID:
        value_ = std::numeric_limits<T>::quiet_NaN();
        break;

      default:
        NOTREACHED();
    }
  }

  template <typename Src>
  explicit CheckedNumericState(
      Src value,
      typename enable_if<std::numeric_limits<Src>::is_specialized, int>::type =
          0)
      : value_(static_cast<T>(value)) {}

  // Copy constructor.
  template <typename Src>
  CheckedNumericState(const CheckedNumericState<Src>& rhs)
      : value_(static_cast<T>(rhs.value())) {}

  RangeConstraint validity() const {
    return GetRangeConstraint(value_ <= std::numeric_limits<T>::max(),
                              value_ >= -std::numeric_limits<T>::max());
  }
  T value() const { return value_; }
};

// For integers less than 128-bit and floats 32-bit or larger, we can distil
// C/C++ arithmetic promotions down to two simple rules:
// 1. The type with the larger maximum exponent always takes precedence.
// 2. The resulting type must be promoted to at least an int.
// The following template specializations implement that promotion logic.
enum ArithmeticPromotionCategory {
  LEFT_PROMOTION,
  RIGHT_PROMOTION,
  DEFAULT_PROMOTION
};

template <typename Lhs,
          typename Rhs = Lhs,
          ArithmeticPromotionCategory Promotion =
              (MaxExponent<Lhs>::value > MaxExponent<Rhs>::value)
                  ? (MaxExponent<Lhs>::value > MaxExponent<int>::value
                         ? LEFT_PROMOTION
                         : DEFAULT_PROMOTION)
                  : (MaxExponent<Rhs>::value > MaxExponent<int>::value
                         ? RIGHT_PROMOTION
                         : DEFAULT_PROMOTION) >
struct ArithmeticPromotion;

template <typename Lhs, typename Rhs>
struct ArithmeticPromotion<Lhs, Rhs, LEFT_PROMOTION> {
  typedef Lhs type;
};

template <typename Lhs, typename Rhs>
struct ArithmeticPromotion<Lhs, Rhs, RIGHT_PROMOTION> {
  typedef Rhs type;
};

template <typename Lhs, typename Rhs>
struct ArithmeticPromotion<Lhs, Rhs, DEFAULT_PROMOTION> {
  typedef int type;
};

// We can statically check if operations on the provided types can wrap, so we
// can skip the checked operations if they're not needed. So, for an integer we
// care if the destination type preserves the sign and is twice the width of
// the source.
template <typename T, typename Lhs, typename Rhs>
struct IsIntegerArithmeticSafe {
  static const bool value = !std::numeric_limits<T>::is_iec559 &&
                            StaticDstRangeRelationToSrcRange<T, Lhs>::value ==
                                NUMERIC_RANGE_CONTAINED &&
                            sizeof(T) >= (2 * sizeof(Lhs)) &&
                            StaticDstRangeRelationToSrcRange<T, Rhs>::value !=
                                NUMERIC_RANGE_CONTAINED &&
                            sizeof(T) >= (2 * sizeof(Rhs));
};

}  // namespace internal
}  // namespace base

#endif  // BASE_NUMERICS_SAFE_MATH_IMPL_H_
