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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"

#define WTF_STRINGTYPEADAPTER_COPIED_WTF_STRING() (++wtfStringCopyCount)

static int wtfStringCopyCount;

#include "wtf/text/WTFString.h"
#include <gtest/gtest.h>

namespace {

#define EXPECT_N_WTF_STRING_COPIES(count, expr) \
    do { \
        wtfStringCopyCount = 0; \
        String __testString = expr; \
        (void)__testString; \
        EXPECT_EQ(count, wtfStringCopyCount) << #expr; \
    } while (false)

TEST(WTF, DISABLED_StringOperators)
{
    String string("String");
    AtomicString atomicString("AtomicString");
    const char* literal = "ASCIILiteral";

    EXPECT_EQ(0, wtfStringCopyCount);

    EXPECT_N_WTF_STRING_COPIES(2, string + string);
    EXPECT_N_WTF_STRING_COPIES(2, string + atomicString);
    EXPECT_N_WTF_STRING_COPIES(2, atomicString + string);
    EXPECT_N_WTF_STRING_COPIES(2, atomicString + atomicString);

    EXPECT_N_WTF_STRING_COPIES(1, "C string" + string);
    EXPECT_N_WTF_STRING_COPIES(1, string + "C string");
    EXPECT_N_WTF_STRING_COPIES(1, "C string" + atomicString);
    EXPECT_N_WTF_STRING_COPIES(1, atomicString + "C string");

    EXPECT_N_WTF_STRING_COPIES(1, literal + string);
    EXPECT_N_WTF_STRING_COPIES(1, string + literal);
    EXPECT_N_WTF_STRING_COPIES(1, literal + atomicString);
    EXPECT_N_WTF_STRING_COPIES(1, atomicString + literal);

    EXPECT_N_WTF_STRING_COPIES(2, "C string" + string + "C string" + string);
    EXPECT_N_WTF_STRING_COPIES(2, "C string" + (string + "C string" + string));
    EXPECT_N_WTF_STRING_COPIES(2, ("C string" + string) + ("C string" + string));
    EXPECT_N_WTF_STRING_COPIES(2, string + "C string" + string + "C string");
    EXPECT_N_WTF_STRING_COPIES(2, string + ("C string" + string + "C string"));
    EXPECT_N_WTF_STRING_COPIES(2, (string + "C string") + (string + "C string"));

    EXPECT_N_WTF_STRING_COPIES(2, literal + string + literal + string);
    EXPECT_N_WTF_STRING_COPIES(2, literal + (string + literal + string));
    EXPECT_N_WTF_STRING_COPIES(2, (literal + string) + (literal + string));
    EXPECT_N_WTF_STRING_COPIES(2, string + literal + string + literal);
    EXPECT_N_WTF_STRING_COPIES(2, string + (literal + string + literal));
    EXPECT_N_WTF_STRING_COPIES(2, (string + literal) + (string + literal));

    EXPECT_N_WTF_STRING_COPIES(2, literal + string + "C string" + string);
    EXPECT_N_WTF_STRING_COPIES(2, literal + (string + "C string" + string));
    EXPECT_N_WTF_STRING_COPIES(2, (literal + string) + ("C string" + string));
    EXPECT_N_WTF_STRING_COPIES(2, "C string" + string + literal + string);
    EXPECT_N_WTF_STRING_COPIES(2, "C string" + (string + literal + string));
    EXPECT_N_WTF_STRING_COPIES(2, ("C string" + string) + (literal + string));

    EXPECT_N_WTF_STRING_COPIES(2, literal + atomicString + "C string" + atomicString);
    EXPECT_N_WTF_STRING_COPIES(2, literal + (atomicString + "C string" + atomicString));
    EXPECT_N_WTF_STRING_COPIES(2, (literal + atomicString) + ("C string" + atomicString));
    EXPECT_N_WTF_STRING_COPIES(2, "C string" + atomicString + literal + atomicString);
    EXPECT_N_WTF_STRING_COPIES(2, "C string" + (atomicString + literal + atomicString));
    EXPECT_N_WTF_STRING_COPIES(2, ("C string" + atomicString) + (literal + atomicString));

    EXPECT_N_WTF_STRING_COPIES(2, literal + atomicString + "C string" + string);
    EXPECT_N_WTF_STRING_COPIES(2, literal + (atomicString + "C string" + string));
    EXPECT_N_WTF_STRING_COPIES(2, (literal + atomicString) + ("C string" + string));
    EXPECT_N_WTF_STRING_COPIES(2, "C string" + atomicString + literal + string);
    EXPECT_N_WTF_STRING_COPIES(2, "C string" + (atomicString + literal + string));
    EXPECT_N_WTF_STRING_COPIES(2, ("C string" + atomicString) + (literal + string));

    EXPECT_N_WTF_STRING_COPIES(2, literal + string + "C string" + atomicString);
    EXPECT_N_WTF_STRING_COPIES(2, literal + (string + "C string" + atomicString));
    EXPECT_N_WTF_STRING_COPIES(2, (literal + string) + ("C string" + atomicString));
    EXPECT_N_WTF_STRING_COPIES(2, "C string" + string + literal + atomicString);
    EXPECT_N_WTF_STRING_COPIES(2, "C string" + (string + literal + atomicString));
    EXPECT_N_WTF_STRING_COPIES(2, ("C string" + string) + (literal + atomicString));

    EXPECT_N_WTF_STRING_COPIES(2, "C string" + atomicString + "C string" + atomicString);
    EXPECT_N_WTF_STRING_COPIES(2, "C string" + (atomicString + "C string" + atomicString));
    EXPECT_N_WTF_STRING_COPIES(2, ("C string" + atomicString) + ("C string" + atomicString));
    EXPECT_N_WTF_STRING_COPIES(2, atomicString + "C string" + atomicString + "C string");
    EXPECT_N_WTF_STRING_COPIES(2, atomicString + ("C string" + atomicString + "C string"));
    EXPECT_N_WTF_STRING_COPIES(2, (atomicString + "C string") + (atomicString + "C string"));

    EXPECT_N_WTF_STRING_COPIES(2, literal + atomicString + literal + atomicString);
    EXPECT_N_WTF_STRING_COPIES(2, literal + (atomicString + literal + atomicString));
    EXPECT_N_WTF_STRING_COPIES(2, (literal + atomicString) + (literal + atomicString));
    EXPECT_N_WTF_STRING_COPIES(2, atomicString + literal + atomicString + literal);
    EXPECT_N_WTF_STRING_COPIES(2, atomicString + (literal + atomicString + literal));
    EXPECT_N_WTF_STRING_COPIES(2, (atomicString + literal) + (atomicString + literal));

    EXPECT_N_WTF_STRING_COPIES(2, "C string" + string + "C string" + atomicString);
    EXPECT_N_WTF_STRING_COPIES(2, "C string" + (string + "C string" + atomicString));
    EXPECT_N_WTF_STRING_COPIES(2, ("C string" + string) + ("C string" + atomicString));
    EXPECT_N_WTF_STRING_COPIES(2, string + "C string" + atomicString + "C string");
    EXPECT_N_WTF_STRING_COPIES(2, string + ("C string" + atomicString + "C string"));
    EXPECT_N_WTF_STRING_COPIES(2, (string + "C string") + (atomicString + "C string"));

    EXPECT_N_WTF_STRING_COPIES(2, literal + string + literal + atomicString);
    EXPECT_N_WTF_STRING_COPIES(2, literal + (string + literal + atomicString));
    EXPECT_N_WTF_STRING_COPIES(2, (literal + string) + (literal + atomicString));
    EXPECT_N_WTF_STRING_COPIES(2, string + literal + atomicString + literal);
    EXPECT_N_WTF_STRING_COPIES(2, string + (literal + atomicString + literal));
    EXPECT_N_WTF_STRING_COPIES(2, (string + literal) + (atomicString + literal));

    EXPECT_N_WTF_STRING_COPIES(2, "C string" + atomicString + "C string" + string);
    EXPECT_N_WTF_STRING_COPIES(2, "C string" + (atomicString + "C string" + string));
    EXPECT_N_WTF_STRING_COPIES(2, ("C string" + atomicString) + ("C string" + string));
    EXPECT_N_WTF_STRING_COPIES(2, atomicString + "C string" + string + "C string");
    EXPECT_N_WTF_STRING_COPIES(2, atomicString + ("C string" + string + "C string"));
    EXPECT_N_WTF_STRING_COPIES(2, (atomicString + "C string") + (string + "C string"));

    EXPECT_N_WTF_STRING_COPIES(2, literal + atomicString + literal + string);
    EXPECT_N_WTF_STRING_COPIES(2, literal + (atomicString + literal + string));
    EXPECT_N_WTF_STRING_COPIES(2, (literal + atomicString) + (literal + string));
    EXPECT_N_WTF_STRING_COPIES(2, atomicString + literal + string + literal);
    EXPECT_N_WTF_STRING_COPIES(2, atomicString + (literal + string + literal));
    EXPECT_N_WTF_STRING_COPIES(2, (atomicString + literal) + (string + literal));

#if COMPILER(MSVC)
    EXPECT_N_WTF_STRING_COPIES(1, L"wide string" + string);
    EXPECT_N_WTF_STRING_COPIES(1, string + L"wide string");
    EXPECT_N_WTF_STRING_COPIES(1, L"wide string" + atomicString);
    EXPECT_N_WTF_STRING_COPIES(1, atomicString + L"wide string");

    EXPECT_N_WTF_STRING_COPIES(2, L"wide string" + string + L"wide string" + string);
    EXPECT_N_WTF_STRING_COPIES(2, L"wide string" + (string + L"wide string" + string));
    EXPECT_N_WTF_STRING_COPIES(2, (L"wide string" + string) + (L"wide string" + string));
    EXPECT_N_WTF_STRING_COPIES(2, string + L"wide string" + string + L"wide string");
    EXPECT_N_WTF_STRING_COPIES(2, string + (L"wide string" + string + L"wide string"));
    EXPECT_N_WTF_STRING_COPIES(2, (string + L"wide string") + (string + L"wide string"));

    EXPECT_N_WTF_STRING_COPIES(2, L"wide string" + atomicString + L"wide string" + atomicString);
    EXPECT_N_WTF_STRING_COPIES(2, L"wide string" + (atomicString + L"wide string" + atomicString));
    EXPECT_N_WTF_STRING_COPIES(2, (L"wide string" + atomicString) + (L"wide string" + atomicString));
    EXPECT_N_WTF_STRING_COPIES(2, atomicString + L"wide string" + atomicString + L"wide string");
    EXPECT_N_WTF_STRING_COPIES(2, atomicString + (L"wide string" + atomicString + L"wide string"));
    EXPECT_N_WTF_STRING_COPIES(2, (atomicString + L"wide string") + (atomicString + L"wide string"));

    EXPECT_N_WTF_STRING_COPIES(2, L"wide string" + string + L"wide string" + atomicString);
    EXPECT_N_WTF_STRING_COPIES(2, L"wide string" + (string + L"wide string" + atomicString));
    EXPECT_N_WTF_STRING_COPIES(2, (L"wide string" + string) + (L"wide string" + atomicString));
    EXPECT_N_WTF_STRING_COPIES(2, string + L"wide string" + atomicString + L"wide string");
    EXPECT_N_WTF_STRING_COPIES(2, string + (L"wide string" + atomicString + L"wide string"));
    EXPECT_N_WTF_STRING_COPIES(2, (string + L"wide string") + (atomicString + L"wide string"));

    EXPECT_N_WTF_STRING_COPIES(2, L"wide string" + atomicString + L"wide string" + string);
    EXPECT_N_WTF_STRING_COPIES(2, L"wide string" + (atomicString + L"wide string" + string));
    EXPECT_N_WTF_STRING_COPIES(2, (L"wide string" + atomicString) + (L"wide string" + string));
    EXPECT_N_WTF_STRING_COPIES(2, atomicString + L"wide string" + string + L"wide string");
    EXPECT_N_WTF_STRING_COPIES(2, atomicString + (L"wide string" + string + L"wide string"));
    EXPECT_N_WTF_STRING_COPIES(2, (atomicString + L"wide string") + (string + L"wide string"));
#endif
}

} // namespace
