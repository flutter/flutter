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

#include "bindings/core/v8/ArrayValue.h"
#include "bindings/core/v8/DictionaryHelperForBindings.h"
#include "bindings/core/v8/ExceptionMessages.h"
#include "bindings/core/v8/ExceptionState.h"
#include "bindings/core/v8/V8Binding.h"
#include "bindings/core/v8/V8DOMError.h"
#include "bindings/core/v8/V8Element.h"
#include "bindings/core/v8/V8EventTarget.h"
#include "bindings/core/v8/V8MediaKeyError.h"
#include "bindings/core/v8/V8Path2D.h"
#include "bindings/core/v8/V8VoidCallback.h"
#include "bindings/core/v8/V8Window.h"
#include "bindings/core/v8/custom/V8ArrayBufferViewCustom.h"
#include "bindings/core/v8/custom/V8Uint8ArrayCustom.h"
#include "wtf/MathExtras.h"

namespace blink {

template <>
bool DictionaryHelper::get(const Dictionary& dictionary, const String& key, v8::Local<v8::Value>& value)
{
    return dictionary.get(key, value);
}

template <>
bool DictionaryHelper::get(const Dictionary& dictionary, const String& key, Dictionary& value)
{
    return dictionary.get(key, value);
}

template <>
bool DictionaryHelper::get(const Dictionary& dictionary, const String& key, bool& value)
{
    v8::Local<v8::Value> v8Value;
    if (!dictionary.get(key, v8Value))
        return false;

    v8::Local<v8::Boolean> v8Bool = v8Value->ToBoolean();
    if (v8Bool.IsEmpty())
        return false;
    value = v8Bool->Value();
    return true;
}

template <>
bool DictionaryHelper::convert(const Dictionary& dictionary, Dictionary::ConversionContext& context, const String& key, bool& value)
{
    Dictionary::ConversionContextScope scope(context);
    DictionaryHelper::get(dictionary, key, value);
    return true;
}

template <>
bool DictionaryHelper::get(const Dictionary& dictionary, const String& key, int32_t& value)
{
    v8::Local<v8::Value> v8Value;
    if (!dictionary.get(key, v8Value))
        return false;

    v8::Local<v8::Int32> v8Int32 = v8Value->ToInt32();
    if (v8Int32.IsEmpty())
        return false;
    value = v8Int32->Value();
    return true;
}

template <>
bool DictionaryHelper::get(const Dictionary& dictionary, const String& key, double& value, bool& hasValue)
{
    v8::Local<v8::Value> v8Value;
    if (!dictionary.get(key, v8Value)) {
        hasValue = false;
        return false;
    }

    hasValue = true;
    TONATIVE_DEFAULT(v8::Local<v8::Number>, v8Number, v8Value->ToNumber(), false);
    if (v8Number.IsEmpty())
        return false;
    value = v8Number->Value();
    return true;
}

template <>
bool DictionaryHelper::get(const Dictionary& dictionary, const String& key, double& value)
{
    bool unused;
    return DictionaryHelper::get(dictionary, key, value, unused);
}

template <>
bool DictionaryHelper::convert(const Dictionary& dictionary, Dictionary::ConversionContext& context, const String& key, double& value)
{
    Dictionary::ConversionContextScope scope(context);

    bool hasValue = false;
    if (!DictionaryHelper::get(dictionary, key, value, hasValue) && hasValue) {
        context.throwTypeError(ExceptionMessages::incorrectPropertyType(key, "is not of type 'double'."));
        return false;
    }
    return true;
}

template<typename StringType>
bool getStringType(const Dictionary& dictionary, const String& key, StringType& value)
{
    v8::Local<v8::Value> v8Value;
    if (!dictionary.get(key, v8Value))
        return false;

    TOSTRING_DEFAULT(V8StringResource<>, stringValue, v8Value, false);
    value = stringValue;
    return true;
}

template <>
bool DictionaryHelper::get(const Dictionary& dictionary, const String& key, String& value)
{
    return getStringType(dictionary, key, value);
}

template <>
bool DictionaryHelper::get(const Dictionary& dictionary, const String& key, AtomicString& value)
{
    return getStringType(dictionary, key, value);
}

template <>
bool DictionaryHelper::convert(const Dictionary& dictionary, Dictionary::ConversionContext& context, const String& key, String& value)
{
    Dictionary::ConversionContextScope scope(context);

    v8::Local<v8::Value> v8Value;
    if (!dictionary.get(key, v8Value))
        return true;

    TOSTRING_DEFAULT(V8StringResource<>, stringValue, v8Value, false);
    value = stringValue;
    return true;
}

template <>
bool DictionaryHelper::get(const Dictionary& dictionary, const String& key, ScriptValue& value)
{
    v8::Local<v8::Value> v8Value;
    if (!dictionary.get(key, v8Value))
        return false;

    value = ScriptValue(ScriptState::current(dictionary.isolate()), v8Value);
    return true;
}

template <>
bool DictionaryHelper::convert(const Dictionary& dictionary, Dictionary::ConversionContext& context, const String& key, ScriptValue& value)
{
    Dictionary::ConversionContextScope scope(context);

    DictionaryHelper::get(dictionary, key, value);
    return true;
}

template<typename NumericType>
bool getNumericType(const Dictionary& dictionary, const String& key, NumericType& value)
{
    v8::Local<v8::Value> v8Value;
    if (!dictionary.get(key, v8Value))
        return false;

    v8::Local<v8::Int32> v8Int32 = v8Value->ToInt32();
    if (v8Int32.IsEmpty())
        return false;
    value = static_cast<NumericType>(v8Int32->Value());
    return true;
}

template <>
bool DictionaryHelper::get(const Dictionary& dictionary, const String& key, short& value)
{
    return getNumericType<short>(dictionary, key, value);
}

template <>
bool DictionaryHelper::get(const Dictionary& dictionary, const String& key, unsigned short& value)
{
    return getNumericType<unsigned short>(dictionary, key, value);
}

template <>
bool DictionaryHelper::get(const Dictionary& dictionary, const String& key, unsigned& value)
{
    return getNumericType<unsigned>(dictionary, key, value);
}

template <>
bool DictionaryHelper::get(const Dictionary& dictionary, const String& key, unsigned long& value)
{
    v8::Local<v8::Value> v8Value;
    if (!dictionary.get(key, v8Value))
        return false;

    v8::Local<v8::Integer> v8Integer = v8Value->ToInteger();
    if (v8Integer.IsEmpty())
        return false;
    value = static_cast<unsigned long>(v8Integer->Value());
    return true;
}

template <>
bool DictionaryHelper::get(const Dictionary& dictionary, const String& key, unsigned long long& value)
{
    v8::Local<v8::Value> v8Value;
    if (!dictionary.get(key, v8Value))
        return false;

    TONATIVE_DEFAULT(v8::Local<v8::Number>, v8Number, v8Value->ToNumber(), false);
    if (v8Number.IsEmpty())
        return false;
    double d = v8Number->Value();
    doubleToInteger(d, value);
    return true;
}

template <>
bool DictionaryHelper::get(const Dictionary& dictionary, const String& key, RefPtr<LocalDOMWindow>& value)
{
    v8::Local<v8::Value> v8Value;
    if (!dictionary.get(key, v8Value))
        return false;

    // We need to handle a DOMWindow specially, because a DOMWindow wrapper
    // exists on a prototype chain of v8Value.
    value = toDOMWindow(v8Value, dictionary.isolate());
    return true;
}

template <>
bool DictionaryHelper::get(const Dictionary& dictionary, const String& key, HashSet<AtomicString>& value)
{
    v8::Local<v8::Value> v8Value;
    if (!dictionary.get(key, v8Value))
        return false;

    // FIXME: Support array-like objects
    if (!v8Value->IsArray())
        return false;

    ASSERT(dictionary.isolate());
    ASSERT(dictionary.isolate() == v8::Isolate::GetCurrent());
    v8::Local<v8::Array> v8Array = v8::Local<v8::Array>::Cast(v8Value);
    for (size_t i = 0; i < v8Array->Length(); ++i) {
        v8::Local<v8::Value> indexedValue = v8Array->Get(v8::Integer::New(dictionary.isolate(), i));
        TOSTRING_DEFAULT(V8StringResource<>, stringValue, indexedValue, false);
        value.add(stringValue);
    }

    return true;
}

template <>
bool DictionaryHelper::convert(const Dictionary& dictionary, Dictionary::ConversionContext& context, const String& key, HashSet<AtomicString>& value)
{
    Dictionary::ConversionContextScope scope(context);

    v8::Local<v8::Value> v8Value;
    if (!dictionary.get(key, v8Value))
        return true;

    if (context.isNullable() && blink::isUndefinedOrNull(v8Value))
        return true;

    if (!v8Value->IsArray()) {
        context.throwTypeError(ExceptionMessages::notASequenceTypeProperty(key));
        return false;
    }

    return DictionaryHelper::get(dictionary, key, value);
}

template <>
bool DictionaryHelper::get(const Dictionary& dictionary, const String& key, RefPtr<EventTarget>& value)
{
    v8::Local<v8::Value> v8Value;
    if (!dictionary.get(key, v8Value))
        return false;

    value = nullptr;
    // We need to handle a LocalDOMWindow specially, because a LocalDOMWindow wrapper
    // exists on a prototype chain of v8Value.
    if (v8Value->IsObject()) {
        v8::Handle<v8::Object> wrapper = v8::Handle<v8::Object>::Cast(v8Value);
        v8::Handle<v8::Object> window = V8Window::findInstanceInPrototypeChain(wrapper, dictionary.isolate());
        if (!window.IsEmpty()) {
            value = toWrapperTypeInfo(window)->toEventTarget(window);
            return true;
        }
    }

    if (V8DOMWrapper::isDOMWrapper(v8Value)) {
        v8::Handle<v8::Object> wrapper = v8::Handle<v8::Object>::Cast(v8Value);
        value = toWrapperTypeInfo(wrapper)->toEventTarget(wrapper);
    }
    return true;
}

template <>
bool DictionaryHelper::get(const Dictionary& dictionary, const String& key, Vector<String>& value)
{
    v8::Local<v8::Value> v8Value;
    if (!dictionary.get(key, v8Value))
        return false;

    if (!v8Value->IsArray())
        return false;

    v8::Local<v8::Array> v8Array = v8::Local<v8::Array>::Cast(v8Value);
    for (size_t i = 0; i < v8Array->Length(); ++i) {
        v8::Local<v8::Value> indexedValue = v8Array->Get(v8::Uint32::New(dictionary.isolate(), i));
        TOSTRING_DEFAULT(V8StringResource<>, stringValue, indexedValue, false);
        value.append(stringValue);
    }

    return true;
}

template <>
bool DictionaryHelper::convert(const Dictionary& dictionary, Dictionary::ConversionContext& context, const String& key, Vector<String>& value)
{
    Dictionary::ConversionContextScope scope(context);

    v8::Local<v8::Value> v8Value;
    if (!dictionary.get(key, v8Value))
        return true;

    if (context.isNullable() && blink::isUndefinedOrNull(v8Value))
        return true;

    if (!v8Value->IsArray()) {
        context.throwTypeError(ExceptionMessages::notASequenceTypeProperty(key));
        return false;
    }

    return DictionaryHelper::get(dictionary, key, value);
}

template <>
bool DictionaryHelper::get(const Dictionary& dictionary, const String& key, ArrayValue& value)
{
    v8::Local<v8::Value> v8Value;
    if (!dictionary.get(key, v8Value))
        return false;

    if (!v8Value->IsArray())
        return false;

    ASSERT(dictionary.isolate());
    ASSERT(dictionary.isolate() == v8::Isolate::GetCurrent());
    value = ArrayValue(v8::Local<v8::Array>::Cast(v8Value), dictionary.isolate());
    return true;
}

template <>
bool DictionaryHelper::convert(const Dictionary& dictionary, Dictionary::ConversionContext& context, const String& key, ArrayValue& value)
{
    Dictionary::ConversionContextScope scope(context);

    v8::Local<v8::Value> v8Value;
    if (!dictionary.get(key, v8Value))
        return true;

    if (context.isNullable() && blink::isUndefinedOrNull(v8Value))
        return true;

    if (!v8Value->IsArray()) {
        context.throwTypeError(ExceptionMessages::notASequenceTypeProperty(key));
        return false;
    }

    return DictionaryHelper::get(dictionary, key, value);
}

template <>
struct DictionaryHelperTraits<Uint8Array> {
    typedef V8Uint8Array type;
};

template <>
struct DictionaryHelperTraits<ArrayBufferView> {
    typedef V8ArrayBufferView type;
};

template <>
struct DictionaryHelperTraits<MediaKeyError> {
    typedef V8MediaKeyError type;
};

template <>
struct DictionaryHelperTraits<DOMError> {
    typedef V8DOMError type;
};

template bool DictionaryHelper::get(const Dictionary&, const String& key, RefPtr<Uint8Array>& value);
template bool DictionaryHelper::get(const Dictionary&, const String& key, RefPtr<ArrayBufferView>& value);
template bool DictionaryHelper::get(const Dictionary&, const String& key, RefPtr<MediaKeyError>& value);
template bool DictionaryHelper::get(const Dictionary&, const String& key, RefPtr<DOMError>& value);

template <typename T>
struct IntegralTypeTraits {
};

template <>
struct IntegralTypeTraits<uint8_t> {
    static inline uint8_t toIntegral(v8::Handle<v8::Value> value, IntegerConversionConfiguration configuration, ExceptionState& exceptionState)
    {
        return toUInt8(value, configuration, exceptionState);
    }
    static const String typeName() { return "UInt8"; }
};

template <>
struct IntegralTypeTraits<int8_t> {
    static inline int8_t toIntegral(v8::Handle<v8::Value> value, IntegerConversionConfiguration configuration, ExceptionState& exceptionState)
    {
        return toInt8(value, configuration, exceptionState);
    }
    static const String typeName() { return "Int8"; }
};

template <>
struct IntegralTypeTraits<unsigned short> {
    static inline uint16_t toIntegral(v8::Handle<v8::Value> value, IntegerConversionConfiguration configuration, ExceptionState& exceptionState)
    {
        return toUInt16(value, configuration, exceptionState);
    }
    static const String typeName() { return "UInt16"; }
};

template <>
struct IntegralTypeTraits<short> {
    static inline int16_t toIntegral(v8::Handle<v8::Value> value, IntegerConversionConfiguration configuration, ExceptionState& exceptionState)
    {
        return toInt16(value, configuration, exceptionState);
    }
    static const String typeName() { return "Int16"; }
};

template <>
struct IntegralTypeTraits<unsigned> {
    static inline uint32_t toIntegral(v8::Handle<v8::Value> value, IntegerConversionConfiguration configuration, ExceptionState& exceptionState)
    {
        return toUInt32(value, configuration, exceptionState);
    }
    static const String typeName() { return "UInt32"; }
};

template <>
struct IntegralTypeTraits<unsigned long> {
    static inline uint32_t toIntegral(v8::Handle<v8::Value> value, IntegerConversionConfiguration configuration, ExceptionState& exceptionState)
    {
        return toUInt32(value, configuration, exceptionState);
    }
    static const String typeName() { return "UInt32"; }
};

template <>
struct IntegralTypeTraits<int> {
    static inline int32_t toIntegral(v8::Handle<v8::Value> value, IntegerConversionConfiguration configuration, ExceptionState& exceptionState)
    {
        return toInt32(value, configuration, exceptionState);
    }
    static const String typeName() { return "Int32"; }
};

template <>
struct IntegralTypeTraits<long> {
    static inline int32_t toIntegral(v8::Handle<v8::Value> value, IntegerConversionConfiguration configuration, ExceptionState& exceptionState)
    {
        return toInt32(value, configuration, exceptionState);
    }
    static const String typeName() { return "Int32"; }
};

template <>
struct IntegralTypeTraits<unsigned long long> {
    static inline unsigned long long toIntegral(v8::Handle<v8::Value> value, IntegerConversionConfiguration configuration, ExceptionState& exceptionState)
    {
        return toUInt64(value, configuration, exceptionState);
    }
    static const String typeName() { return "UInt64"; }
};

template <>
struct IntegralTypeTraits<long long> {
    static inline long long toIntegral(v8::Handle<v8::Value> value, IntegerConversionConfiguration configuration, ExceptionState& exceptionState)
    {
        return toInt64(value, configuration, exceptionState);
    }
    static const String typeName() { return "Int64"; }
};

template<typename T>
bool DictionaryHelper::convert(const Dictionary& dictionary, Dictionary::ConversionContext& context, const String& key, T& value)
{
    Dictionary::ConversionContextScope scope(context);

    v8::Local<v8::Value> v8Value;
    if (!dictionary.get(key, v8Value))
        return true;

    value = IntegralTypeTraits<T>::toIntegral(v8Value, NormalConversion, context.exceptionState());
    if (context.exceptionState().throwIfNeeded())
        return false;

    return true;
}

template bool DictionaryHelper::convert(const Dictionary&, Dictionary::ConversionContext&, const String& key, uint8_t& value);
template bool DictionaryHelper::convert(const Dictionary&, Dictionary::ConversionContext&, const String& key, int8_t& value);
template bool DictionaryHelper::convert(const Dictionary&, Dictionary::ConversionContext&, const String& key, unsigned short& value);
template bool DictionaryHelper::convert(const Dictionary&, Dictionary::ConversionContext&, const String& key, short& value);
template bool DictionaryHelper::convert(const Dictionary&, Dictionary::ConversionContext&, const String& key, unsigned& value);
template bool DictionaryHelper::convert(const Dictionary&, Dictionary::ConversionContext&, const String& key, unsigned long& value);
template bool DictionaryHelper::convert(const Dictionary&, Dictionary::ConversionContext&, const String& key, int& value);
template bool DictionaryHelper::convert(const Dictionary&, Dictionary::ConversionContext&, const String& key, long& value);
template bool DictionaryHelper::convert(const Dictionary&, Dictionary::ConversionContext&, const String& key, long long& value);
template bool DictionaryHelper::convert(const Dictionary&, Dictionary::ConversionContext&, const String& key, unsigned long long& value);

template<typename T>
bool DictionaryHelper::convert(const Dictionary& dictionary, Dictionary::ConversionContext& context, const String& key, Nullable<T>& value)
{
    Dictionary::ConversionContextScope scope(context);

    v8::Local<v8::Value> v8Value;
    if (!dictionary.get(key, v8Value))
        return true;

    if (context.isNullable() && blink::isUndefinedOrNull(v8Value)) {
        value = Nullable<T>();
        return true;
    }

    T converted = IntegralTypeTraits<T>::toIntegral(v8Value, NormalConversion, context.exceptionState());

    if (context.exceptionState().throwIfNeeded())
        return false;

    value = Nullable<T>(converted);
    return true;
}

template bool DictionaryHelper::convert(const Dictionary&, Dictionary::ConversionContext&, const String& key, Nullable<uint8_t>& value);
template bool DictionaryHelper::convert(const Dictionary&, Dictionary::ConversionContext&, const String& key, Nullable<int8_t>& value);
template bool DictionaryHelper::convert(const Dictionary&, Dictionary::ConversionContext&, const String& key, Nullable<unsigned short>& value);
template bool DictionaryHelper::convert(const Dictionary&, Dictionary::ConversionContext&, const String& key, Nullable<short>& value);
template bool DictionaryHelper::convert(const Dictionary&, Dictionary::ConversionContext&, const String& key, Nullable<unsigned>& value);
template bool DictionaryHelper::convert(const Dictionary&, Dictionary::ConversionContext&, const String& key, Nullable<unsigned long>& value);
template bool DictionaryHelper::convert(const Dictionary&, Dictionary::ConversionContext&, const String& key, Nullable<int>& value);
template bool DictionaryHelper::convert(const Dictionary&, Dictionary::ConversionContext&, const String& key, Nullable<long>& value);
template bool DictionaryHelper::convert(const Dictionary&, Dictionary::ConversionContext&, const String& key, Nullable<long long>& value);
template bool DictionaryHelper::convert(const Dictionary&, Dictionary::ConversionContext&, const String& key, Nullable<unsigned long long>& value);

template bool DictionaryHelper::convert(const Dictionary&, Dictionary::ConversionContext&, const String& key, RefPtr<LocalDOMWindow>& value);
template bool DictionaryHelper::convert(const Dictionary&, Dictionary::ConversionContext&, const String& key, RefPtr<Uint8Array>& value);
template bool DictionaryHelper::convert(const Dictionary&, Dictionary::ConversionContext&, const String& key, RefPtr<ArrayBufferView>& value);
template bool DictionaryHelper::convert(const Dictionary&, Dictionary::ConversionContext&, const String& key, RefPtr<MediaKeyError>& value);
template bool DictionaryHelper::convert(const Dictionary&, Dictionary::ConversionContext&, const String& key, RefPtr<EventTarget>& value);

} // namespace blink
