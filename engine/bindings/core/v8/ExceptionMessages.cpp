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

#include "config.h"
#include "bindings/core/v8/ExceptionMessages.h"

#include "platform/Decimal.h"
#include "wtf/MathExtras.h"

namespace blink {

String ExceptionMessages::failedToConstruct(const char* type, const String& detail)
{
    return "Failed to construct '" + String(type) + (!detail.isEmpty() ? String("': " + detail) : String("'"));
}

String ExceptionMessages::failedToEnumerate(const char* type, const String& detail)
{
    return "Failed to enumerate the properties of '" + String(type) + (!detail.isEmpty() ? String("': " + detail) : String("'"));
}

String ExceptionMessages::failedToExecute(const char* method, const char* type, const String& detail)
{
    return "Failed to execute '" + String(method) + "' on '" + String(type) + (!detail.isEmpty() ? String("': " + detail) : String("'"));
}

String ExceptionMessages::failedToGet(const char* property, const char* type, const String& detail)
{
    return "Failed to read the '" + String(property) + "' property from '" + String(type) + "': " + detail;
}

String ExceptionMessages::failedToSet(const char* property, const char* type, const String& detail)
{
    return "Failed to set the '" + String(property) + "' property on '" + String(type) + "': " + detail;
}

String ExceptionMessages::failedToDelete(const char* property, const char* type, const String& detail)
{
    return "Failed to delete the '" + String(property) + "' property from '" + String(type) + "': " + detail;
}

String ExceptionMessages::failedToGetIndexed(const char* type, const String& detail)
{
    return "Failed to read an indexed property from '" + String(type) + "': " + detail;
}

String ExceptionMessages::failedToSetIndexed(const char* type, const String& detail)
{
    return "Failed to set an indexed property on '" + String(type) + "': " + detail;
}

String ExceptionMessages::failedToDeleteIndexed(const char* type, const String& detail)
{
    return "Failed to delete an indexed property from '" + String(type) + "': " + detail;
}

String ExceptionMessages::constructorNotCallableAsFunction(const char* type)
{
    return failedToConstruct(type, "Please use the 'new' operator, this DOM object constructor cannot be called as a function.");
}

String ExceptionMessages::incorrectPropertyType(const String& property, const String& detail)
{
    return "The '" + property + "' property " + detail;
}

String ExceptionMessages::invalidArity(const char* expected, unsigned provided)
{
    return "Valid arities are: " + String(expected) + ", but " + String::number(provided) + " arguments provided.";
}

String ExceptionMessages::argumentNullOrIncorrectType(int argumentIndex, const String& expectedType)
{
    return "The " + ordinalNumber(argumentIndex) + " argument provided is either null, or an invalid " + expectedType + " object.";
}

String ExceptionMessages::notAnArrayTypeArgumentOrValue(int argumentIndex)
{
    String kind;
    if (argumentIndex) // method argument
        kind = ordinalNumber(argumentIndex) + " argument";
    else // value, e.g. attribute setter
        kind = "value provided";
    return "The " + kind + " is neither an array, nor does it have indexed properties.";
}

String ExceptionMessages::notASequenceTypeProperty(const String& propertyName)
{
    return "'" + propertyName + "' property is neither an array, nor does it have indexed properties.";
}

String ExceptionMessages::notEnoughArguments(unsigned expected, unsigned provided)
{
    return String::number(expected) + " argument" + (expected > 1 ? "s" : "") + " required, but only " + String::number(provided) + " present.";
}

String ExceptionMessages::notAFiniteNumber(double value, const char* name)
{
    ASSERT(!std::isfinite(value));
    return String::format("The %s is %s.", name, std::isinf(value) ? "infinite" : "not a number");
}

String ExceptionMessages::notAFiniteNumber(const Decimal& value, const char* name)
{
    ASSERT(!value.isFinite());
    return String::format("The %s is %s.", name, value.isInfinity() ? "infinite" : "not a number");
}

String ExceptionMessages::ordinalNumber(int number)
{
    String suffix("th");
    switch (number % 10) {
    case 1:
        if (number % 100 != 11)
            suffix = "st";
        break;
    case 2:
        if (number % 100 != 12)
            suffix = "nd";
        break;
    case 3:
        if (number % 100 != 13)
            suffix = "rd";
        break;
    }
    return String::number(number) + suffix;
}

String ExceptionMessages::readOnly(const char* detail)
{
    DEFINE_STATIC_LOCAL(String, readOnly, ("This object is read-only."));
    return detail ? String::format("This object is read-only, because %s.", detail) : readOnly;
}

template <>
String ExceptionMessages::formatNumber<float>(float number)
{
    return formatPotentiallyNonFiniteNumber(number);
}

template <>
String ExceptionMessages::formatNumber<double>(double number)
{
    return formatPotentiallyNonFiniteNumber(number);
}

} // namespace blink
