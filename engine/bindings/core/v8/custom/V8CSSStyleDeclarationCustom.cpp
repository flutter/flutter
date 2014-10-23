/*
 * Copyright (C) 2007-2011 Google Inc. All rights reserved.
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
#include "bindings/core/v8/V8CSSStyleDeclaration.h"

#include "bindings/core/v8/ExceptionState.h"
#include "bindings/core/v8/V8Binding.h"
#include "core/CSSPropertyNames.h"
#include "core/css/CSSPrimitiveValue.h"
#include "core/css/CSSPropertyMetadata.h"
#include "core/css/CSSStyleDeclaration.h"
#include "core/css/CSSValue.h"
#include "core/css/parser/BisonCSSParser.h"
#include "core/events/EventTarget.h"
#include "wtf/ASCIICType.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefPtr.h"
#include "wtf/StdLibExtras.h"
#include "wtf/Vector.h"
#include "wtf/text/StringBuilder.h"
#include "wtf/text/StringConcatenate.h"

using namespace WTF;

namespace blink {

// Check for a CSS prefix.
// Passed prefix is all lowercase.
// First character of the prefix within the property name may be upper or lowercase.
// Other characters in the prefix within the property name must be lowercase.
// The prefix within the property name must be followed by a capital letter.
static bool hasCSSPropertyNamePrefix(const String& propertyName, const char* prefix)
{
#if ENABLE(ASSERT)
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

struct CSSPropertyInfo {
    CSSPropertyID propID;
};

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
static CSSPropertyInfo* cssPropertyInfo(v8::Handle<v8::String> v8PropertyName)
{
    String propertyName = toCoreString(v8PropertyName);
    typedef HashMap<String, CSSPropertyInfo*> CSSPropertyInfoMap;
    DEFINE_STATIC_LOCAL(CSSPropertyInfoMap, map, ());
    CSSPropertyInfo* propInfo = map.get(propertyName);
    if (!propInfo) {
        propInfo = new CSSPropertyInfo();
        propInfo->propID = cssResolvedPropertyID(propertyName);
        map.add(propertyName, propInfo);
    }
    if (!propInfo->propID)
        return 0;
    ASSERT(CSSPropertyMetadata::isEnabledProperty(propInfo->propID));
    return propInfo;
}

void V8CSSStyleDeclaration::namedPropertyEnumeratorCustom(const v8::PropertyCallbackInfo<v8::Array>& info)
{
    typedef Vector<String, numCSSProperties - 1> PreAllocatedPropertyVector;
    DEFINE_STATIC_LOCAL(PreAllocatedPropertyVector, propertyNames, ());
    static unsigned propertyNamesLength = 0;

    if (propertyNames.isEmpty()) {
        for (int id = firstCSSProperty; id <= lastCSSProperty; ++id) {
            CSSPropertyID propertyId = static_cast<CSSPropertyID>(id);
            if (CSSPropertyMetadata::isEnabledProperty(propertyId))
                propertyNames.append(getJSPropertyName(propertyId));
        }
        std::sort(propertyNames.begin(), propertyNames.end(), codePointCompareLessThan);
        propertyNamesLength = propertyNames.size();
    }

    v8::Handle<v8::Array> properties = v8::Array::New(info.GetIsolate(), propertyNamesLength);
    for (unsigned i = 0; i < propertyNamesLength; ++i) {
        String key = propertyNames.at(i);
        ASSERT(!key.isNull());
        properties->Set(v8::Integer::New(info.GetIsolate(), i), v8String(info.GetIsolate(), key));
    }

    v8SetReturnValue(info, properties);
}

void V8CSSStyleDeclaration::namedPropertyQueryCustom(v8::Local<v8::String> v8Name, const v8::PropertyCallbackInfo<v8::Integer>& info)
{
    // NOTE: cssPropertyInfo lookups incur several mallocs.
    // Successful lookups have the same cost the first time, but are cached.
    if (cssPropertyInfo(v8Name)) {
        v8SetReturnValueInt(info, 0);
        return;
    }
}

void V8CSSStyleDeclaration::namedPropertyGetterCustom(v8::Local<v8::String> name, const v8::PropertyCallbackInfo<v8::Value>& info)
{
    // First look for API defined attributes on the style declaration object.
    if (info.Holder()->HasRealNamedCallbackProperty(name))
        return;

    // Search the style declaration.
    CSSPropertyInfo* propInfo = cssPropertyInfo(name);

    // Do not handle non-property names.
    if (!propInfo)
        return;

    CSSStyleDeclaration* impl = V8CSSStyleDeclaration::toNative(info.Holder());
    RefPtrWillBeRawPtr<CSSValue> cssValue = impl->getPropertyCSSValueInternal(static_cast<CSSPropertyID>(propInfo->propID));
    if (cssValue) {
        v8SetReturnValueStringOrNull(info, cssValue->cssText(), info.GetIsolate());
        return;
    }

    String result = impl->getPropertyValueInternal(static_cast<CSSPropertyID>(propInfo->propID));
    v8SetReturnValueString(info, result, info.GetIsolate());
}

void V8CSSStyleDeclaration::namedPropertySetterCustom(v8::Local<v8::String> name, v8::Local<v8::Value> value, const v8::PropertyCallbackInfo<v8::Value>& info)
{
    CSSStyleDeclaration* impl = V8CSSStyleDeclaration::toNative(info.Holder());
    CSSPropertyInfo* propInfo = cssPropertyInfo(name);
    if (!propInfo)
        return;

    TOSTRING_VOID(V8StringResource<TreatNullAsNullString>, propertyValue, value);
    ExceptionState exceptionState(ExceptionState::SetterContext, getPropertyName(static_cast<CSSPropertyID>(propInfo->propID)), "CSSStyleDeclaration", info.Holder(), info.GetIsolate());
    impl->setPropertyInternal(static_cast<CSSPropertyID>(propInfo->propID), propertyValue, false, exceptionState);

    if (exceptionState.throwIfNeeded())
        return;

    v8SetReturnValue(info, value);
}

} // namespace blink
