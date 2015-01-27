// Copyright 2013, Google Inc.
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//    * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//    * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#include "config.h"
#include "bindings/core/dart/DartCSSStyleDeclaration.h"

#include "core/CSSPropertyNames.h"
#include "core/css/CSSPrimitiveValue.h"
#include "core/css/CSSStyleDeclaration.h"
#include "core/css/CSSValue.h"
#include "core/css/RuntimeCSSEnabled.h"
#include "core/css/parser/BisonCSSParser.h"
#include "wtf/ASCIICType.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefPtr.h"
#include "wtf/StdLibExtras.h"
#include "wtf/Vector.h"
#include "wtf/text/StringBuilder.h"
#include "wtf/text/StringConcatenate.h"

using namespace WTF;
using namespace std;

namespace blink {

struct CSSPropertyInfo {
    CSSPropertyID propID;
};

namespace DartCSSStyleDeclarationInternal {

void __setter__Callback(Dart_NativeArguments)
{
    // FIXME: proper implementation.
    DART_UNIMPLEMENTED();
}

static bool hasCSSPropertyNamePrefix(const String& propertyName, const char* prefix)
{
#ifndef NDEBUG
    ASSERT(*prefix);
    for (const char* p = prefix; *p; ++p)
        ASSERT(isASCIILower(*p));
    ASSERT(propertyName.length());
#endif

    if (toASCIILower(propertyName[0]) != prefix[0])
        return false;

    unsigned length = propertyName.length();
    for (unsigned i = 1; i < length; ++i) {
        if (!prefix[i])
            return isASCIIUpper(propertyName[i]);
        if (propertyName[i] != prefix[i])
            return false;
    }
    return false;
}

static CSSPropertyID cssResolvedPropertyID(const String& propertyName)
{
    unsigned length = propertyName.length();
    if (!length)
        return CSSPropertyInvalid;

    StringBuilder builder;
    builder.reserveCapacity(length);

    unsigned i = 0;
    bool hasSeenDash = false;

    if (hasCSSPropertyNamePrefix(propertyName, "css"))
        i += 3;
    else if (hasCSSPropertyNamePrefix(propertyName, "webkit"))
        builder.append('-');
    else if (isASCIIUpper(propertyName[0]))
        return CSSPropertyInvalid;

    bool hasSeenUpper = isASCIIUpper(propertyName[i]);

    builder.append(toASCIILower(propertyName[i++]));

    for (; i < length; ++i) {
        UChar c = propertyName[i];
        if (!isASCIIUpper(c)) {
            if (c == '-')
                hasSeenDash = true;
            builder.append(c);
        } else {
            hasSeenUpper = true;
            builder.append('-');
            builder.append(toASCIILower(c));
        }
    }

    // Reject names containing both dashes and upper-case characters, such as "border-rightColor".
    if (hasSeenDash && hasSeenUpper)
        return CSSPropertyInvalid;

    String propName = builder.toString();
    return cssPropertyID(propName);
}

// When getting properties on CSSStyleDeclarations, the name used from
// Javascript and the actual name of the property are not the same, so
// we have to do the following translation. The translation turns upper
// case characters into lower case characters and inserts dashes to
// separate words.
//
// Example: 'backgroundPositionY' -> 'background-position-y'
//
// Also, certain prefixes such as 'css-' are stripped.
static CSSPropertyInfo* cssPropertyInfo(const String& propertyName)
{
    typedef HashMap<String, CSSPropertyInfo*> CSSPropertyInfoMap;
    DEFINE_STATIC_LOCAL(CSSPropertyInfoMap, map, ());
    CSSPropertyInfo* propInfo = map.get(propertyName);
    if (!propInfo) {
        propInfo = new CSSPropertyInfo();
        propInfo->propID = cssResolvedPropertyID(propertyName);
        map.add(propertyName, propInfo);
    }
    if (propInfo->propID && RuntimeCSSEnabled::isCSSPropertyEnabled(propInfo->propID))
        return propInfo;
    return 0;
}

void propertyQuery(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        DartStringAdapter propertyName = DartUtilities::dartToString(args, 1, exception);
        if (exception)
            goto fail;

        // NOTE: cssPropertyInfo lookups incur several mallocs.
        // Successful lookups have the same cost the first time, but are cached.
        Dart_SetReturnValue(args, DartUtilities::boolToDart(
            cssPropertyInfo(propertyName)));
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

}

}
