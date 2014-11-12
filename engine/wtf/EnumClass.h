/*
 * Copyright (C) 2013 Apple Inc. All rights reserved.
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

#ifndef WTF_EnumClass_h
#define WTF_EnumClass_h

#include "wtf/Compiler.h"

namespace WTF {

// How to define a type safe enum list using the ENUM_CLASS macros?
// ===============================================================
// To get an enum list like this:
//
//     enum class MyEnums {
//         Value1,
//         Value2,
//         ...
//         ValueN
//     };
//
// ... write this:
//
//     ENUM_CLASS(MyEnums) {
//         Value1,
//         Value2,
//         ...
//         ValueN
//     } ENUM_CLASS_END(MyEnums);
//
// The ENUM_CLASS macros will use C++11's enum class if the compiler supports it.
// Otherwise, it will use the EnumClass template below.

#if COMPILER_SUPPORTS(CXX_STRONG_ENUMS)

#define ENUM_CLASS(__enumName) \
    enum class __enumName

#define ENUM_CLASS_END(__enumName)

#else // !COMPILER_SUPPORTS(CXX_STRONG_ENUMS)

// How to define a type safe enum list using the EnumClass template?
// ================================================================
// Definition should be a struct that encapsulates an enum list.
// The enum list should be names Enums.
//
// Here's an example of how to define a type safe enum named MyEnum using
// the EnumClass template:
//
//     struct MyEnumDefinition {
//         enum Enums {
//             ValueDefault,
//             Value1,
//             ...
//             ValueN
//         };
//     };
//     typedef EnumClass<MyEnumDefinition, MyEnumDefinition::ValueDefault> MyEnum;
//
// With that, you can now use MyEnum enum values as follow:
//
//     MyEnum value1; // value1 is assigned MyEnum::ValueDefault by default.
//     MyEnum value2 = MyEnum::Value1; // value2 is assigned MyEnum::Value1;

template <typename Definition>
class EnumClass : public Definition {
    typedef enum Definition::Enums Value;
public:
    ALWAYS_INLINE EnumClass() { }
    ALWAYS_INLINE EnumClass(Value value) : m_value(value) { }

    ALWAYS_INLINE Value value() const { return m_value; }

    ALWAYS_INLINE bool operator==(const EnumClass other) { return m_value == other.m_value; }
    ALWAYS_INLINE bool operator!=(const EnumClass other) { return m_value != other.m_value; }
    ALWAYS_INLINE bool operator<(const EnumClass other) { return m_value < other.m_value; }
    ALWAYS_INLINE bool operator<=(const EnumClass other) { return m_value <= other.m_value; }
    ALWAYS_INLINE bool operator>(const EnumClass other) { return m_value > other.m_value; }
    ALWAYS_INLINE bool operator>=(const EnumClass other) { return m_value >= other.m_value; }

    ALWAYS_INLINE bool operator==(const Value value) { return m_value == value; }
    ALWAYS_INLINE bool operator!=(const Value value) { return m_value != value; }
    ALWAYS_INLINE bool operator<(const Value value) { return m_value < value; }
    ALWAYS_INLINE bool operator<=(const Value value) { return m_value <= value; }
    ALWAYS_INLINE bool operator>(const Value value) { return m_value > value; }
    ALWAYS_INLINE bool operator>=(const Value value) { return m_value >= value; }

    ALWAYS_INLINE operator Value() { return m_value; }

private:
    Value m_value;
};

#define ENUM_CLASS(__enumName) \
    struct __enumName ## Definition { \
        enum Enums

#define ENUM_CLASS_END(__enumName) \
        ; \
    }; \
    typedef EnumClass< __enumName ## Definition > __enumName

#endif // !COMPILER_SUPPORTS(CXX_STRONG_ENUMS)

} // namespace WTF

#if !COMPILER_SUPPORTS(CXX_STRONG_ENUMS)
using WTF::EnumClass;
#endif

#endif // WTF_EnumClass_h
