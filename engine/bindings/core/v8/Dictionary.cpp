/*
 * Copyright (C) 2010 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "bindings/core/v8/Dictionary.h"

#include "bindings/core/v8/ArrayValue.h"
#include "bindings/core/v8/ExceptionMessages.h"
#include "bindings/core/v8/ExceptionState.h"
#include "bindings/core/v8/V8Binding.h"
#include "bindings/core/v8/V8DOMError.h"
#include "bindings/core/v8/V8Element.h"
#include "bindings/core/v8/V8EventTarget.h"
#include "bindings/core/v8/V8MediaKeyError.h"
#include "bindings/core/v8/V8MessagePort.h"
#include "bindings/core/v8/V8Path2D.h"
#include "bindings/core/v8/V8VoidCallback.h"
#include "bindings/core/v8/V8Window.h"
#include "bindings/core/v8/custom/V8ArrayBufferViewCustom.h"
#include "bindings/core/v8/custom/V8Uint8ArrayCustom.h"
#include "wtf/MathExtras.h"

namespace blink {

Dictionary::Dictionary()
    : m_isolate(0)
{
}

Dictionary::Dictionary(const v8::Handle<v8::Value>& options, v8::Isolate* isolate)
    : m_options(options)
    , m_isolate(isolate)
{
    ASSERT(m_isolate);
}

Dictionary::~Dictionary()
{
}

Dictionary& Dictionary::operator=(const Dictionary& optionsObject)
{
    m_options = optionsObject.m_options;
    m_isolate = optionsObject.m_isolate;
    return *this;
}

Dictionary Dictionary::createEmpty(v8::Isolate* isolate)
{
    return Dictionary(v8::Object::New(isolate), isolate);
}

bool Dictionary::isObject() const
{
    return !isUndefinedOrNull() && m_options->IsObject();
}

bool Dictionary::isUndefinedOrNull() const
{
    if (m_options.IsEmpty())
        return true;
    return blink::isUndefinedOrNull(m_options);
}

bool Dictionary::hasProperty(const String& key) const
{
    if (isUndefinedOrNull())
        return false;
    v8::Local<v8::Object> options = m_options->ToObject();
    ASSERT(!options.IsEmpty());

    ASSERT(m_isolate);
    ASSERT(m_isolate == v8::Isolate::GetCurrent());
    v8::Handle<v8::String> v8Key = v8String(m_isolate, key);
    if (!options->Has(v8Key))
        return false;

    return true;
}

bool Dictionary::getKey(const String& key, v8::Local<v8::Value>& value) const
{
    if (isUndefinedOrNull())
        return false;
    v8::Local<v8::Object> options = m_options->ToObject();
    ASSERT(!options.IsEmpty());

    ASSERT(m_isolate);
    ASSERT(m_isolate == v8::Isolate::GetCurrent());
    v8::Handle<v8::String> v8Key = v8String(m_isolate, key);
    if (!options->Has(v8Key))
        return false;
    value = options->Get(v8Key);
    if (value.IsEmpty())
        return false;
    return true;
}

bool Dictionary::get(const String& key, v8::Local<v8::Value>& value) const
{
    return getKey(key, value);
}

bool Dictionary::getWithUndefinedOrNullCheck(const String& key, String& value) const
{
    v8::Local<v8::Value> v8Value;
    if (!getKey(key, v8Value) || blink::isUndefinedOrNull(v8Value))
        return false;

    TOSTRING_DEFAULT(V8StringResource<>, stringValue, v8Value, false);
    value = stringValue;
    return true;
}

bool Dictionary::getWithUndefinedOrNullCheck(const String& key, RefPtrWillBeMember<Element>& value) const
{
    v8::Local<v8::Value> v8Value;
    if (!getKey(key, v8Value) || blink::isUndefinedOrNull(v8Value))
        return false;

    value = V8Element::toNativeWithTypeCheck(m_isolate, v8Value);
    return true;
}

bool Dictionary::getWithUndefinedOrNullCheck(const String& key, RefPtrWillBeMember<Path2D>& value) const
{
    v8::Local<v8::Value> v8Value;
    if (!getKey(key, v8Value) || blink::isUndefinedOrNull(v8Value))
        return false;

    value = V8Path2D::toNativeWithTypeCheck(m_isolate, v8Value);
    return true;
}

bool Dictionary::get(const String& key, Dictionary& value) const
{
    v8::Local<v8::Value> v8Value;
    if (!getKey(key, v8Value))
        return false;

    if (v8Value->IsObject()) {
        ASSERT(m_isolate);
        ASSERT(m_isolate == v8::Isolate::GetCurrent());
        value = Dictionary(v8Value, m_isolate);
    }

    return true;
}

bool Dictionary::set(const String& key, const v8::Handle<v8::Value>& value)
{
    if (isUndefinedOrNull())
        return false;
    v8::Local<v8::Object> options = m_options->ToObject();
    ASSERT(!options.IsEmpty());

    return options->Set(v8String(m_isolate, key), value);
}

bool Dictionary::set(const String& key, const String& value)
{
    return set(key, v8String(m_isolate, value));
}

bool Dictionary::set(const String& key, unsigned value)
{
    return set(key, v8::Integer::NewFromUnsigned(m_isolate, value));
}

bool Dictionary::set(const String& key, const Dictionary& value)
{
    return set(key, value.v8Value());
}

bool Dictionary::convert(ConversionContext& context, const String& key, Dictionary& value) const
{
    ConversionContextScope scope(context);

    v8::Local<v8::Value> v8Value;
    if (!getKey(key, v8Value))
        return true;

    if (v8Value->IsObject())
        return get(key, value);

    if (context.isNullable() && blink::isUndefinedOrNull(v8Value))
        return true;

    context.throwTypeError(ExceptionMessages::incorrectPropertyType(key, "does not have a Dictionary type."));
    return false;
}

bool Dictionary::getOwnPropertiesAsStringHashMap(HashMap<String, String>& hashMap) const
{
    if (!isObject())
        return false;

    v8::Handle<v8::Object> options = m_options->ToObject();
    if (options.IsEmpty())
        return false;

    v8::Local<v8::Array> properties = options->GetOwnPropertyNames();
    if (properties.IsEmpty())
        return true;
    for (uint32_t i = 0; i < properties->Length(); ++i) {
        v8::Local<v8::String> key = properties->Get(i)->ToString();
        if (!options->Has(key))
            continue;

        v8::Local<v8::Value> value = options->Get(key);
        TOSTRING_DEFAULT(V8StringResource<>, stringKey, key, false);
        TOSTRING_DEFAULT(V8StringResource<>, stringValue, value, false);
        if (!static_cast<const String&>(stringKey).isEmpty())
            hashMap.set(stringKey, stringValue);
    }

    return true;
}

bool Dictionary::getOwnPropertyNames(Vector<String>& names) const
{
    if (!isObject())
        return false;

    v8::Handle<v8::Object> options = m_options->ToObject();
    if (options.IsEmpty())
        return false;

    v8::Local<v8::Array> properties = options->GetOwnPropertyNames();
    if (properties.IsEmpty())
        return true;
    for (uint32_t i = 0; i < properties->Length(); ++i) {
        v8::Local<v8::String> key = properties->Get(i)->ToString();
        if (!options->Has(key))
            continue;
        TOSTRING_DEFAULT(V8StringResource<>, stringKey, key, false);
        names.append(stringKey);
    }

    return true;
}

void Dictionary::ConversionContext::resetPerPropertyContext()
{
    if (m_dirty) {
        m_dirty = false;
        m_isNullable = false;
        m_propertyTypeName = "";
    }
}

Dictionary::ConversionContext& Dictionary::ConversionContext::setConversionType(const String& typeName, bool isNullable)
{
    ASSERT(!m_dirty);
    m_dirty = true;
    m_isNullable = isNullable;
    m_propertyTypeName = typeName;

    return *this;
}

void Dictionary::ConversionContext::throwTypeError(const String& detail)
{
    exceptionState().throwTypeError(detail);
}

} // namespace blink
