// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_BINDINGS_EXCEPTIONMESSAGES_H_
#define SKY_ENGINE_BINDINGS_EXCEPTIONMESSAGES_H_

#include "sky/engine/wtf/MathExtras.h"
#include "sky/engine/wtf/text/StringBuilder.h"
#include "sky/engine/wtf/text/WTFString.h"

namespace blink {

class Decimal;

class ExceptionMessages {
 public:
  enum BoundType {
    InclusiveBound,
    ExclusiveBound,
  };

  static String argumentNullOrIncorrectType(int argumentIndex,
                                            const String& expectedType);
  static String constructorNotCallableAsFunction(const char* type);

  static String failedToConstruct(const char* type, const String& detail);
  static String failedToEnumerate(const char* type, const String& detail);
  static String failedToExecute(const char* method,
                                const char* type,
                                const String& detail);
  static String failedToGet(const char* property,
                            const char* type,
                            const String& detail);
  static String failedToSet(const char* property,
                            const char* type,
                            const String& detail);
  static String failedToDelete(const char* property,
                               const char* type,
                               const String& detail);
  static String failedToGetIndexed(const char* type, const String& detail);
  static String failedToSetIndexed(const char* type, const String& detail);
  static String failedToDeleteIndexed(const char* type, const String& detail);

  template <typename NumType>
  static String formatNumber(NumType number) {
    return formatFiniteNumber(number);
  }

  static String incorrectPropertyType(const String& property,
                                      const String& detail);

  template <typename NumberType>
  static String indexExceedsMaximumBound(const char* name,
                                         NumberType given,
                                         NumberType bound) {
    bool eq = given == bound;
    StringBuilder result;
    result.appendLiteral("The ");
    result.append(name);
    result.appendLiteral(" provided (");
    result.append(formatNumber(given));
    result.appendLiteral(") is greater than ");
    result.append(eq ? "or equal to " : "");
    result.appendLiteral("the maximum bound (");
    result.append(formatNumber(bound));
    result.appendLiteral(").");
    return result.toString();
  }

  template <typename NumberType>
  static String indexExceedsMinimumBound(const char* name,
                                         NumberType given,
                                         NumberType bound) {
    bool eq = given == bound;
    StringBuilder result;
    result.appendLiteral("The ");
    result.append(name);
    result.appendLiteral(" provided (");
    result.append(formatNumber(given));
    result.appendLiteral(") is less than ");
    result.append(eq ? "or equal to " : "");
    result.appendLiteral("the minimum bound (");
    result.append(formatNumber(bound));
    result.appendLiteral(").");
    return result.toString();
  }

  template <typename NumberType>
  static String indexOutsideRange(const char* name,
                                  NumberType given,
                                  NumberType lowerBound,
                                  BoundType lowerType,
                                  NumberType upperBound,
                                  BoundType upperType) {
    StringBuilder result;
    result.appendLiteral("The ");
    result.append(name);
    result.appendLiteral(" provided (");
    result.append(formatNumber(given));
    result.appendLiteral(") is outside the range ");
    result.append(lowerType == ExclusiveBound ? '(' : '[');
    result.append(formatNumber(lowerBound));
    result.appendLiteral(", ");
    result.append(formatNumber(upperBound));
    result.append(upperType == ExclusiveBound ? ')' : ']');
    result.append('.');
    return result.toString();
  }

  static String invalidArity(const char* expected, unsigned provided);

  // If  > 0, the argument index that failed type check (1-indexed.)
  // If == 0, a (non-argument) value (e.g., a setter) failed the same check.
  static String notAnArrayTypeArgumentOrValue(int argumentIndex);
  static String notASequenceTypeProperty(const String& propertyName);
  static String notAFiniteNumber(double value,
                                 const char* name = "value provided");
  static String notAFiniteNumber(const Decimal& value,
                                 const char* name = "value provided");

  static String notEnoughArguments(unsigned expected, unsigned provided);

  static String readOnly(const char* detail = 0);

 private:
  template <typename NumType>
  static String formatFiniteNumber(NumType number) {
    if (number > 1e20 || number < -1e20)
      return String::format("%e", 1.0 * number);
    return String::number(number);
  }

  template <typename NumType>
  static String formatPotentiallyNonFiniteNumber(NumType number) {
    if (std::isnan(number))
      return "NaN";
    if (std::isinf(number))
      return number > 0 ? "Infinity" : "-Infinity";
    if (number > 1e20 || number < -1e20)
      return String::format("%e", number);
    return String::number(number);
  }

  static String ordinalNumber(int number);
};

template <>
String ExceptionMessages::formatNumber<float>(float number);
template <>
String ExceptionMessages::formatNumber<double>(double number);

}  // namespace blink

#endif  // SKY_ENGINE_BINDINGS_EXCEPTIONMESSAGES_H_
