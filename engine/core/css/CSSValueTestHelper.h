/*
 * Copyright (c) 2013, Google Inc. All rights reserved.
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

/**
 * Make testing with gtest and gmock nicer by adding pretty print and other
 * helper functions.
 */

#ifndef CSSValueTestHelper_h
#define CSSValueTestHelper_h

#include "core/css/CSSPrimitiveValue.h"
#include "core/css/CSSValue.h"

#include <iostream>

namespace testing {
namespace internal {

// gtest tests won't compile with clang when trying to EXPECT_EQ a class that
// has the "template<typename T> operator T*()" private.
// (See https://code.google.com/p/googletest/issues/detail?id=442)
//
// Work around is to define this custom IsNullLiteralHelper.
char(&IsNullLiteralHelper(const blink::CSSValue&))[2];

}
}

namespace blink {

inline bool operator==(const CSSValue& a, const CSSValue& b)
{
    return a.equals(b);
}

inline void PrintTo(const CSSValue& cssValue, ::std::ostream* os, const char* typeName = "CSSValue")
{
    *os << typeName << "(" << cssValue.cssText().utf8().data() << ")";
}

inline void PrintTo(const CSSPrimitiveValue& cssValue, ::std::ostream* os, const char* typeName = "CSSPrimitiveValue")
{
    PrintTo(static_cast<const CSSValue&>(cssValue), os, typeName);
}

}

#endif
