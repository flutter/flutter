// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_NUMERICS_SAFE_MATH_H_
#define BASE_NUMERICS_SAFE_MATH_H_

#include "base/numerics/safe_math_impl.h"

namespace base {

namespace internal {

// CheckedNumeric implements all the logic and operators for detecting integer
// boundary conditions such as overflow, underflow, and invalid conversions.
// The CheckedNumeric type implicitly converts from floating point and integer
// data types, and contains overloads for basic arithmetic operations (i.e.: +,
// -, *, /, %).
//
// The following methods convert from CheckedNumeric to standard numeric values:
// IsValid() - Returns true if the underlying numeric value is valid (i.e. has
//             has not wrapped and is not the result of an invalid conversion).
// ValueOrDie() - Returns the underlying value. If the state is not valid this
//                call will crash on a CHECK.
// ValueOrDefault() - Returns the current value, or the supplied default if the
//                    state is not valid.
// ValueFloating() - Returns the underlying floating point value (valid only
//                   only for floating point CheckedNumeric types).
//
// Bitwise operations are explicitly not supported, because correct
// handling of some cases (e.g. sign manipulation) is ambiguous. Comparison
// operations are explicitly not supported because they could result in a crash
// on a CHECK condition. You should use patterns like the following for these
// operations:
// Bitwise operation:
//     CheckedNumeric<int> checked_int = untrusted_input_value;
//     int x = checked_int.ValueOrDefault(0) | kFlagValues;
// Comparison:
//   CheckedNumeric<size_t> checked_size;
//   CheckedNumeric<int> checked_size = untrusted_input_value;
//   checked_size = checked_size + HEADER LENGTH;
//   if (checked_size.IsValid() && checked_size.ValueOrDie() < buffer_size)
//     Do stuff...
template <typename T>
class CheckedNumeric {
 public:
  typedef T type;

  CheckedNumeric() {}

  // Copy constructor.
  template <typename Src>
  CheckedNumeric(const CheckedNumeric<Src>& rhs)
      : state_(rhs.ValueUnsafe(), rhs.validity()) {}

  template <typename Src>
  CheckedNumeric(Src value, RangeConstraint validity)
      : state_(value, validity) {}

  // This is not an explicit constructor because we implicitly upgrade regular
  // numerics to CheckedNumerics to make them easier to use.
  template <typename Src>
  CheckedNumeric(Src value)
      : state_(value) {
    static_assert(std::numeric_limits<Src>::is_specialized,
                  "Argument must be numeric.");
  }

  // This is not an explicit constructor because we want a seamless conversion
  // from StrictNumeric types.
  template <typename Src>
  CheckedNumeric(StrictNumeric<Src> value)
      : state_(static_cast<Src>(value)) {
  }

  // IsValid() is the public API to test if a CheckedNumeric is currently valid.
  bool IsValid() const { return validity() == RANGE_VALID; }

  // ValueOrDie() The primary accessor for the underlying value. If the current
  // state is not valid it will CHECK and crash.
  T ValueOrDie() const {
    CHECK(IsValid());
    return state_.value();
  }

  // ValueOrDefault(T default_value) A convenience method that returns the
  // current value if the state is valid, and the supplied default_value for
  // any other state.
  T ValueOrDefault(T default_value) const {
    return IsValid() ? state_.value() : default_value;
  }

  // ValueFloating() - Since floating point values include their validity state,
  // we provide an easy method for extracting them directly, without a risk of
  // crashing on a CHECK.
  T ValueFloating() const {
    static_assert(std::numeric_limits<T>::is_iec559, "Argument must be float.");
    return CheckedNumeric<T>::cast(*this).ValueUnsafe();
  }

  // validity() - DO NOT USE THIS IN EXTERNAL CODE - It is public right now for
  // tests and to avoid a big matrix of friend operator overloads. But the
  // values it returns are likely to change in the future.
  // Returns: current validity state (i.e. valid, overflow, underflow, nan).
  // TODO(jschuh): crbug.com/332611 Figure out and implement semantics for
  // saturation/wrapping so we can expose this state consistently and implement
  // saturated arithmetic.
  RangeConstraint validity() const { return state_.validity(); }

  // ValueUnsafe() - DO NOT USE THIS IN EXTERNAL CODE - It is public right now
  // for tests and to avoid a big matrix of friend operator overloads. But the
  // values it returns are likely to change in the future.
  // Returns: the raw numeric value, regardless of the current state.
  // TODO(jschuh): crbug.com/332611 Figure out and implement semantics for
  // saturation/wrapping so we can expose this state consistently and implement
  // saturated arithmetic.
  T ValueUnsafe() const { return state_.value(); }

  // Prototypes for the supported arithmetic operator overloads.
  template <typename Src> CheckedNumeric& operator+=(Src rhs);
  template <typename Src> CheckedNumeric& operator-=(Src rhs);
  template <typename Src> CheckedNumeric& operator*=(Src rhs);
  template <typename Src> CheckedNumeric& operator/=(Src rhs);
  template <typename Src> CheckedNumeric& operator%=(Src rhs);

  CheckedNumeric operator-() const {
    RangeConstraint validity;
    T value = CheckedNeg(state_.value(), &validity);
    // Negation is always valid for floating point.
    if (std::numeric_limits<T>::is_iec559)
      return CheckedNumeric<T>(value);

    validity = GetRangeConstraint(state_.validity() | validity);
    return CheckedNumeric<T>(value, validity);
  }

  CheckedNumeric Abs() const {
    RangeConstraint validity;
    T value = CheckedAbs(state_.value(), &validity);
    // Absolute value is always valid for floating point.
    if (std::numeric_limits<T>::is_iec559)
      return CheckedNumeric<T>(value);

    validity = GetRangeConstraint(state_.validity() | validity);
    return CheckedNumeric<T>(value, validity);
  }

  CheckedNumeric& operator++() {
    *this += 1;
    return *this;
  }

  CheckedNumeric operator++(int) {
    CheckedNumeric value = *this;
    *this += 1;
    return value;
  }

  CheckedNumeric& operator--() {
    *this -= 1;
    return *this;
  }

  CheckedNumeric operator--(int) {
    CheckedNumeric value = *this;
    *this -= 1;
    return value;
  }

  // These static methods behave like a convenience cast operator targeting
  // the desired CheckedNumeric type. As an optimization, a reference is
  // returned when Src is the same type as T.
  template <typename Src>
  static CheckedNumeric<T> cast(
      Src u,
      typename enable_if<std::numeric_limits<Src>::is_specialized, int>::type =
          0) {
    return u;
  }

  template <typename Src>
  static CheckedNumeric<T> cast(
      const CheckedNumeric<Src>& u,
      typename enable_if<!is_same<Src, T>::value, int>::type = 0) {
    return u;
  }

  static const CheckedNumeric<T>& cast(const CheckedNumeric<T>& u) { return u; }

 private:
  CheckedNumericState<T> state_;
};

// This is the boilerplate for the standard arithmetic operator overloads. A
// macro isn't the prettiest solution, but it beats rewriting these five times.
// Some details worth noting are:
//  * We apply the standard arithmetic promotions.
//  * We skip range checks for floating points.
//  * We skip range checks for destination integers with sufficient range.
// TODO(jschuh): extract these out into templates.
#define BASE_NUMERIC_ARITHMETIC_OPERATORS(NAME, OP, COMPOUND_OP)              \
  /* Binary arithmetic operator for CheckedNumerics of the same type. */      \
  template <typename T>                                                       \
  CheckedNumeric<typename ArithmeticPromotion<T>::type> operator OP(          \
      const CheckedNumeric<T>& lhs, const CheckedNumeric<T>& rhs) {           \
    typedef typename ArithmeticPromotion<T>::type Promotion;                  \
    /* Floating point always takes the fast path */                           \
    if (std::numeric_limits<T>::is_iec559)                                    \
      return CheckedNumeric<T>(lhs.ValueUnsafe() OP rhs.ValueUnsafe());       \
    if (IsIntegerArithmeticSafe<Promotion, T, T>::value)                      \
      return CheckedNumeric<Promotion>(                                       \
          lhs.ValueUnsafe() OP rhs.ValueUnsafe(),                             \
          GetRangeConstraint(rhs.validity() | lhs.validity()));               \
    RangeConstraint validity = RANGE_VALID;                                   \
    T result = static_cast<T>(Checked##NAME(                                  \
        static_cast<Promotion>(lhs.ValueUnsafe()),                            \
        static_cast<Promotion>(rhs.ValueUnsafe()),                            \
        &validity));                                                          \
    return CheckedNumeric<Promotion>(                                         \
        result,                                                               \
        GetRangeConstraint(validity | lhs.validity() | rhs.validity()));      \
  }                                                                           \
  /* Assignment arithmetic operator implementation from CheckedNumeric. */    \
  template <typename T>                                                       \
  template <typename Src>                                                     \
  CheckedNumeric<T>& CheckedNumeric<T>::operator COMPOUND_OP(Src rhs) {       \
    *this = CheckedNumeric<T>::cast(*this) OP CheckedNumeric<Src>::cast(rhs); \
    return *this;                                                             \
  }                                                                           \
  /* Binary arithmetic operator for CheckedNumeric of different type. */      \
  template <typename T, typename Src>                                         \
  CheckedNumeric<typename ArithmeticPromotion<T, Src>::type> operator OP(     \
      const CheckedNumeric<Src>& lhs, const CheckedNumeric<T>& rhs) {         \
    typedef typename ArithmeticPromotion<T, Src>::type Promotion;             \
    if (IsIntegerArithmeticSafe<Promotion, T, Src>::value)                    \
      return CheckedNumeric<Promotion>(                                       \
          lhs.ValueUnsafe() OP rhs.ValueUnsafe(),                             \
          GetRangeConstraint(rhs.validity() | lhs.validity()));               \
    return CheckedNumeric<Promotion>::cast(lhs)                               \
        OP CheckedNumeric<Promotion>::cast(rhs);                              \
  }                                                                           \
  /* Binary arithmetic operator for left CheckedNumeric and right numeric. */ \
  template <typename T, typename Src>                                         \
  CheckedNumeric<typename ArithmeticPromotion<T, Src>::type> operator OP(     \
      const CheckedNumeric<T>& lhs, Src rhs) {                                \
    typedef typename ArithmeticPromotion<T, Src>::type Promotion;             \
    if (IsIntegerArithmeticSafe<Promotion, T, Src>::value)                    \
      return CheckedNumeric<Promotion>(lhs.ValueUnsafe() OP rhs,              \
                                       lhs.validity());                       \
    return CheckedNumeric<Promotion>::cast(lhs)                               \
        OP CheckedNumeric<Promotion>::cast(rhs);                              \
  }                                                                           \
  /* Binary arithmetic operator for right numeric and left CheckedNumeric. */ \
  template <typename T, typename Src>                                         \
  CheckedNumeric<typename ArithmeticPromotion<T, Src>::type> operator OP(     \
      Src lhs, const CheckedNumeric<T>& rhs) {                                \
    typedef typename ArithmeticPromotion<T, Src>::type Promotion;             \
    if (IsIntegerArithmeticSafe<Promotion, T, Src>::value)                    \
      return CheckedNumeric<Promotion>(lhs OP rhs.ValueUnsafe(),              \
                                       rhs.validity());                       \
    return CheckedNumeric<Promotion>::cast(lhs)                               \
        OP CheckedNumeric<Promotion>::cast(rhs);                              \
  }

BASE_NUMERIC_ARITHMETIC_OPERATORS(Add, +, += )
BASE_NUMERIC_ARITHMETIC_OPERATORS(Sub, -, -= )
BASE_NUMERIC_ARITHMETIC_OPERATORS(Mul, *, *= )
BASE_NUMERIC_ARITHMETIC_OPERATORS(Div, /, /= )
BASE_NUMERIC_ARITHMETIC_OPERATORS(Mod, %, %= )

#undef BASE_NUMERIC_ARITHMETIC_OPERATORS

}  // namespace internal

using internal::CheckedNumeric;

}  // namespace base

#endif  // BASE_NUMERICS_SAFE_MATH_H_
