/*
 * Copyright (C) 2009 Google Inc. All rights reserved.
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
#include "bindings/core/v8/V8StringResource.h"

#include "bindings/core/v8/V8Binding.h"
#include "core/inspector/BindingVisitors.h"
#include "wtf/MainThread.h"

namespace blink {

template<class StringClass> struct StringTraits {
    static const StringClass& fromStringResource(WebCoreStringResourceBase*);
    template <typename V8StringTrait>
    static StringClass fromV8String(v8::Handle<v8::String>, int);
};

template<>
struct StringTraits<String> {
    static const String& fromStringResource(WebCoreStringResourceBase* resource)
    {
        return resource->webcoreString();
    }
    template <typename V8StringTrait>
    static String fromV8String(v8::Handle<v8::String>, int);
};

template<>
struct StringTraits<AtomicString> {
    static const AtomicString& fromStringResource(WebCoreStringResourceBase* resource)
    {
        return resource->atomicString();
    }
    template <typename V8StringTrait>
    static AtomicString fromV8String(v8::Handle<v8::String>, int);
};

struct V8StringTwoBytesTrait {
    typedef UChar CharType;
    ALWAYS_INLINE static void write(v8::Handle<v8::String> v8String, CharType* buffer, int length)
    {
        v8String->Write(reinterpret_cast<uint16_t*>(buffer), 0, length);
    }
};

struct V8StringOneByteTrait {
    typedef LChar CharType;
    ALWAYS_INLINE static void write(v8::Handle<v8::String> v8String, CharType* buffer, int length)
    {
        v8String->WriteOneByte(buffer, 0, length);
    }
};

template <typename V8StringTrait>
String StringTraits<String>::fromV8String(v8::Handle<v8::String> v8String, int length)
{
    ASSERT(v8String->Length() == length);
    typename V8StringTrait::CharType* buffer;
    String result = String::createUninitialized(length, buffer);
    V8StringTrait::write(v8String, buffer, length);
    return result;
}

template <typename V8StringTrait>
AtomicString StringTraits<AtomicString>::fromV8String(v8::Handle<v8::String> v8String, int length)
{
    ASSERT(v8String->Length() == length);
    static const int inlineBufferSize = 32 / sizeof(typename V8StringTrait::CharType);
    if (length <= inlineBufferSize) {
        typename V8StringTrait::CharType inlineBuffer[inlineBufferSize];
        V8StringTrait::write(v8String, inlineBuffer, length);
        return AtomicString(inlineBuffer, length);
    }
    typename V8StringTrait::CharType* buffer;
    String string = String::createUninitialized(length, buffer);
    V8StringTrait::write(v8String, buffer, length);
    return AtomicString(string);
}

template<typename StringType>
StringType v8StringToWebCoreString(v8::Handle<v8::String> v8String, ExternalMode external)
{
    {
        // This portion of this function is very hot in certain Dromeao benchmarks.
        v8::String::Encoding encoding;
        v8::String::ExternalStringResourceBase* resource = v8String->GetExternalStringResourceBase(&encoding);
        if (LIKELY(!!resource)) {
            WebCoreStringResourceBase* base;
            if (encoding == v8::String::ONE_BYTE_ENCODING)
                base = static_cast<WebCoreStringResource8*>(resource);
            else
                base = static_cast<WebCoreStringResource16*>(resource);
            return StringTraits<StringType>::fromStringResource(base);
        }
    }

    int length = v8String->Length();
    if (UNLIKELY(!length))
        return StringType("");

    bool oneByte = v8String->ContainsOnlyOneByte();
    StringType result(oneByte ? StringTraits<StringType>::template fromV8String<V8StringOneByteTrait>(v8String, length) : StringTraits<StringType>::template fromV8String<V8StringTwoBytesTrait>(v8String, length));

    if (external != Externalize || !v8String->CanMakeExternal())
        return result;

    if (result.is8Bit()) {
        WebCoreStringResource8* stringResource = new WebCoreStringResource8(result);
        if (UNLIKELY(!v8String->MakeExternal(stringResource)))
            delete stringResource;
    } else {
        WebCoreStringResource16* stringResource = new WebCoreStringResource16(result);
        if (UNLIKELY(!v8String->MakeExternal(stringResource)))
            delete stringResource;
    }
    return result;
}

// Explicitly instantiate the above template with the expected parameterizations,
// to ensure the compiler generates the code; otherwise link errors can result in GCC 4.4.
template String v8StringToWebCoreString<String>(v8::Handle<v8::String>, ExternalMode);
template AtomicString v8StringToWebCoreString<AtomicString>(v8::Handle<v8::String>, ExternalMode);

// Fast but non thread-safe version.
String int32ToWebCoreStringFast(int value)
{
    // Caching of small strings below is not thread safe: newly constructed AtomicString
    // are not safely published.
    ASSERT(isMainThread());

    // Most numbers used are <= 100. Even if they aren't used there's very little cost in using the space.
    const int kLowNumbers = 100;
    DEFINE_STATIC_LOCAL(Vector<AtomicString>, lowNumbers, (kLowNumbers + 1));
    String webCoreString;
    if (0 <= value && value <= kLowNumbers) {
        webCoreString = lowNumbers[value];
        if (!webCoreString) {
            AtomicString valueString = AtomicString::number(value);
            lowNumbers[value] = valueString;
            webCoreString = valueString;
        }
    } else {
        webCoreString = String::number(value);
    }
    return webCoreString;
}

String int32ToWebCoreString(int value)
{
    // If we are on the main thread (this should always true for non-workers), call the faster one.
    if (isMainThread())
        return int32ToWebCoreStringFast(value);
    return String::number(value);
}

} // namespace blink
