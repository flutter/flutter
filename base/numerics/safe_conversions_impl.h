// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_NUMERICS_SAFE_CONVERSIONS_IMPL_H_
#define BASE_NUMERICS_SAFE_CONVERSIONS_IMPL_H_

#include <limits>

#include "base/template_util.h"

namespace base {
namespace internal {

// The std library doesn't provide a binary max_exponent for integers, however
// we can compute one by adding one to the number of non-sign bits. This allows
// for accurate range comparisons between floating point and integer types.
template <typename NumericType>
struct MaxExponent {
  static const int value = std::numeric_limits<NumericType>::is_iec559
                               ? std::numeric_limits<NumericType>::max_exponent
                               : (sizeof(NumericType) * 8 + 1 -
                                  std::numeric_limits<NumericType>::is_signed);
};

enum IntegerRepresentation {
  INTEGER_REPRESENTATION_UNSIGNED,
  INTEGER_REPRESENTATION_SIGNED
};

// A range for a given nunmeric Src type is contained for a given numeric Dst
// type if both numeric_limits<Src>::max() <= numeric_limits<Dst>::max() and
// numeric_limits<Src>::min() >= numeric_limits<Dst>::min() are true.
// We implement this as template specializations rather than simple static
// comparisons to ensure type correctness in our comparisons.
enum NumericRangeRepresentation {
  NUMERIC_RANGE_NOT_CONTAINED,
  NUMERIC_RANGE_CONTAINED
};

// Helper templates to statically determine if our destination type can contain
// maximum and minimum values represented by the source type.

template <
    typename Dst,
    typename Src,
    IntegerRepresentation DstSign = std::numeric_limits<Dst>::is_signed
                                            ? INTEGER_REPRESENTATION_SIGNED
                                            : INTEGER_REPRESENTATION_UNSIGNED,
    IntegerRepresentation SrcSign =
        std::numeric_limits<Src>::is_signed
            ? INTEGER_REPRESENTATION_SIGNED
            : INTEGER_REPRESENTATION_UNSIGNED >
struct StaticDstRangeRelationToSrcRange;

// Same sign: Dst is guaranteed to contain Src only if its range is equal or
// larger.
template <typename Dst, typename Src, IntegerRepresentation Sign>
struct StaticDstRangeRelationToSrcRange<Dst, Src, Sign, Sign> {
  static const NumericRangeRepresentation value =
      MaxExponent<Dst>::value >= MaxExponent<Src>::value
          ? NUMERIC_RANGE_CONTAINED
          : NUMERIC_RANGE_NOT_CONTAINED;
};

// Unsigned to signed: Dst is guaranteed to contain source only if its range is
// larger.
template <typename Dst, typename Src>
struct StaticDstRangeRelationToSrcRange<Dst,
                                        Src,
                                        INTEGER_REPRESENTATION_SIGNED,
                                        INTEGER_REPRESENTATION_UNSIGNED> {
  static const NumericRangeRepresentation value =
      MaxExponent<Dst>::value > MaxExponent<Src>::value
          ? NUMERIC_RANGE_CONTAINED
          : NUMERIC_RANGE_NOT_CONTAINED;
};

// Signed to unsigned: Dst cannot be statically determined to contain Src.
template <typename Dst, typename Src>
struct StaticDstRangeRelationToSrcRange<Dst,
                                        Src,
                                        INTEGER_REPRESENTATION_UNSIGNED,
                                        INTEGER_REPRESENTATION_SIGNED> {
  static const NumericRangeRepresentation value = NUMERIC_RANGE_NOT_CONTAINED;
};

enum RangeConstraint {
  RANGE_VALID = 0x0,  // Value can be represented by the destination type.
  RANGE_UNDERFLOW = 0x1,  // Value would overflow.
  RANGE_OVERFLOW = 0x2,  // Value would underflow.
  RANGE_INVALID = RANGE_UNDERFLOW | RANGE_OVERFLOW  // Invalid (i.e. NaN).
};

// Helper function for coercing an int back to a RangeContraint.
inline RangeConstraint GetRangeConstraint(int integer_range_constraint) {
  DCHECK(integer_range_constraint >= RANGE_VALID &&
         integer_range_constraint <= RANGE_INVALID);
  return static_cast<RangeConstraint>(integer_range_constraint);
}

// This function creates a RangeConstraint from an upper and lower bound
// check by taking advantage of the fact that only NaN can be out of range in
// both directions at once.
inline RangeConstraint GetRangeConstraint(bool is_in_upper_bound,
                                   bool is_in_lower_bound) {
  return GetRangeConstraint((is_in_upper_bound ? 0 : RANGE_OVERFLOW) |
                            (is_in_lower_bound ? 0 : RANGE_UNDERFLOW));
}

template <
    typename Dst,
    typename Src,
    IntegerRepresentation DstSign = std::numeric_limits<Dst>::is_signed
                                            ? INTEGER_REPRESENTATION_SIGNED
                                            : INTEGER_REPRESENTATION_UNSIGNED,
    IntegerRepresentation SrcSign = std::numeric_limits<Src>::is_signed
                                            ? INTEGER_REPRESENTATION_SIGNED
                                            : INTEGER_REPRESENTATION_UNSIGNED,
    NumericRangeRepresentation DstRange =
        StaticDstRangeRelationToSrcRange<Dst, Src>::value >
struct DstRangeRelationToSrcRangeImpl;

// The following templates are for ranges that must be verified at runtime. We
// split it into checks based on signedness to avoid confusing casts and
// compiler warnings on signed an unsigned comparisons.

// Dst range is statically determined to contain Src: Nothing to check.
template <typename Dst,
          typename Src,
          IntegerRepresentation DstSign,
          IntegerRepresentation SrcSign>
struct DstRangeRelationToSrcRangeImpl<Dst,
                                      Src,
                                      DstSign,
                                      SrcSign,
                                      NUMERIC_RANGE_CONTAINED> {
  static RangeConstraint Check(Src value) { return RANGE_VALID; }
};

// Signed to signed narrowing: Both the upper and lower boundaries may be
// exceeded.
template <typename Dst, typename Src>
struct DstRangeRelationToSrcRangeImpl<Dst,
                                      Src,
                                      INTEGER_REPRESENTATION_SIGNED,
                                      INTEGER_REPRESENTATION_SIGNED,
                                      NUMERIC_RANGE_NOT_CONTAINED> {
  static RangeConstraint Check(Src value) {
    return std::numeric_limits<Dst>::is_iec559
               ? GetRangeConstraint((value < std::numeric_limits<Dst>::max()),
                                    (value > -std::numeric_limits<Dst>::max()))
               : GetRangeConstraint((value < std::numeric_limits<Dst>::max()),
                                    (value > std::numeric_limits<Dst>::min()));
  }
};

// Unsigned to unsigned narrowing: Only the upper boundary can be exceeded.
template <typename Dst, typename Src>
struct DstRangeRelationToSrcRangeImpl<Dst,
                                      Src,
                                      INTEGER_REPRESENTATION_UNSIGNED,
                                      INTEGER_REPRESENTATION_UNSIGNED,
                                      NUMERIC_RANGE_NOT_CONTAINED> {
  static RangeConstraint Check(Src value) {
    return GetRangeConstraint(value < std::numeric_limits<Dst>::max(), true);
  }
};

// Unsigned to signed: The upper boundary may be exceeded.
template <typename Dst, typename Src>
struct DstRangeRelationToSrcRangeImpl<Dst,
                                      Src,
                                      INTEGER_REPRESENTATION_SIGNED,
                                      INTEGER_REPRESENTATION_UNSIGNED,
                                      NUMERIC_RANGE_NOT_CONTAINED> {
  static RangeConstraint Check(Src value) {
    return sizeof(Dst) > sizeof(Src)
               ? RANGE_VALID
               : GetRangeConstraint(
                     value < static_cast<Src>(std::numeric_limits<Dst>::max()),
                     true);
  }
};

// Signed to unsigned: The upper boundary may be exceeded for a narrower Dst,
// and any negative value exceeds the lower boundary.
template <typename Dst, typename Src>
struct DstRangeRelationToSrcRangeImpl<Dst,
                                      Src,
                                      INTEGER_REPRESENTATION_UNSIGNED,
                                      INTEGER_REPRESENTATION_SIGNED,
                                      NUMERIC_RANGE_NOT_CONTAINED> {
  static RangeConstraint Check(Src value) {
    return (MaxExponent<Dst>::value >= MaxExponent<Src>::value)
               ? GetRangeConstraint(true, value >= static_cast<Src>(0))
               : GetRangeConstraint(
                     value < static_cast<Src>(std::numeric_limits<Dst>::max()),
                     value >= static_cast<Src>(0));
  }
};

template <typename Dst, typename Src>
inline RangeConstraint DstRangeRelationToSrcRange(Src value) {
  static_assert(std::numeric_limits<Src>::is_specialized,
                "Argument must be numeric.");
  static_assert(std::numeric_limits<Dst>::is_specialized,
                "Result must be numeric.");
  return DstRangeRelationToSrcRangeImpl<Dst, Src>::Check(value);
}

}  // namespace internal
}  // namespace base

#endif  // BASE_NUMERICS_SAFE_CONVERSIONS_IMPL_H_
