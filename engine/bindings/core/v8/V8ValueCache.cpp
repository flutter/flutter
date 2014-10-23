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
#include "bindings/core/v8/V8ValueCache.h"

#include "bindings/core/v8/V8Binding.h"
#include "wtf/text/StringHash.h"

namespace blink {

StringCacheMapTraits::MapType* StringCacheMapTraits::MapFromWeakCallbackData(
    const v8::WeakCallbackData<v8::String, WeakCallbackDataType>& data)
{
    return &(V8PerIsolateData::from(data.GetIsolate())->stringCache()->m_stringCache);
}


void StringCacheMapTraits::Dispose(
    v8::Isolate* isolate, v8::UniquePersistent<v8::String> value, StringImpl* key)
{
    V8PerIsolateData::from(isolate)->stringCache()->InvalidateLastString();
    key->deref();
}


StringCache::~StringCache()
{
    // The MapType::Dispose callback calls StringCache::InvalidateLastString,
    // which will only work while the destructor has not yet finished. Thus,
    // we need to clear the map before the destructor has completed.
    m_stringCache.Clear();
}

static v8::Local<v8::String> makeExternalString(const String& string, v8::Isolate* isolate)
{
    if (string.is8Bit()) {
        WebCoreStringResource8* stringResource = new WebCoreStringResource8(string);
        v8::Local<v8::String> newString = v8::String::NewExternal(isolate, stringResource);
        if (newString.IsEmpty())
            delete stringResource;
        return newString;
    }

    WebCoreStringResource16* stringResource = new WebCoreStringResource16(string);
    v8::Local<v8::String> newString = v8::String::NewExternal(isolate, stringResource);
    if (newString.IsEmpty())
        delete stringResource;
    return newString;
}

v8::Handle<v8::String> StringCache::v8ExternalStringSlow(StringImpl* stringImpl, v8::Isolate* isolate)
{
    if (!stringImpl->length())
        return v8::String::Empty(isolate);

    StringCacheMapTraits::MapType::PersistentValueReference cachedV8String = m_stringCache.GetReference(stringImpl);
    if (!cachedV8String.IsEmpty()) {
        m_lastStringImpl = stringImpl;
        m_lastV8String = cachedV8String;
        return m_lastV8String.NewLocal(isolate);
    }

    return createStringAndInsertIntoCache(stringImpl, isolate);
}

void StringCache::setReturnValueFromStringSlow(v8::ReturnValue<v8::Value> returnValue, StringImpl* stringImpl)
{
    if (!stringImpl->length()) {
        returnValue.SetEmptyString();
        return;
    }

    StringCacheMapTraits::MapType::PersistentValueReference cachedV8String = m_stringCache.GetReference(stringImpl);
    if (!cachedV8String.IsEmpty()) {
        m_lastStringImpl = stringImpl;
        m_lastV8String = cachedV8String;
        m_lastV8String.SetReturnValue(returnValue);
        return;
    }

    returnValue.Set(createStringAndInsertIntoCache(stringImpl, returnValue.GetIsolate()));
}

v8::Local<v8::String> StringCache::createStringAndInsertIntoCache(StringImpl* stringImpl, v8::Isolate* isolate)
{
    ASSERT(!m_stringCache.Contains(stringImpl));
    ASSERT(stringImpl->length());

    v8::Local<v8::String> newString = makeExternalString(String(stringImpl), isolate);
    if (newString.IsEmpty())
        return newString;

    v8::UniquePersistent<v8::String> wrapper(isolate, newString);

    stringImpl->ref();
    wrapper.MarkIndependent();
    m_stringCache.Set(stringImpl, wrapper.Pass(), &m_lastV8String);
    m_lastStringImpl = stringImpl;

    return newString;
}

void StringCache::InvalidateLastString()
{
    m_lastStringImpl = nullptr;
    m_lastV8String.Reset();
}

} // namespace blink
