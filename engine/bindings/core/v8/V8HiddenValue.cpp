// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "bindings/core/v8/V8HiddenValue.h"

#include "bindings/core/v8/ScriptWrappable.h"
#include "bindings/core/v8/V8Binding.h"

namespace blink {

#define V8_DEFINE_METHOD(name) \
v8::Handle<v8::String> V8HiddenValue::name(v8::Isolate* isolate)    \
{ \
    V8HiddenValue* hiddenValue = V8PerIsolateData::from(isolate)->hiddenValue(); \
    if (hiddenValue->m_##name.isEmpty()) { \
        hiddenValue->m_##name.set(isolate, v8AtomicString(isolate, #name)); \
    } \
    return hiddenValue->m_##name.newLocal(isolate); \
}

V8_HIDDEN_VALUES(V8_DEFINE_METHOD);

v8::Local<v8::Value> V8HiddenValue::getHiddenValue(v8::Isolate* isolate, v8::Handle<v8::Object> object, v8::Handle<v8::String> key)
{
    return object->GetHiddenValue(key);
}

bool V8HiddenValue::setHiddenValue(v8::Isolate* isolate, v8::Handle<v8::Object> object, v8::Handle<v8::String> key, v8::Handle<v8::Value> value)
{
    return object->SetHiddenValue(key, value);
}

bool V8HiddenValue::deleteHiddenValue(v8::Isolate* isolate, v8::Handle<v8::Object> object, v8::Handle<v8::String> key)
{
    return object->DeleteHiddenValue(key);
}

v8::Local<v8::Value> V8HiddenValue::getHiddenValueFromMainWorldWrapper(v8::Isolate* isolate, ScriptWrappable* wrappable, v8::Handle<v8::String> key)
{
    v8::Local<v8::Object> wrapper = wrappable->newLocalWrapper(isolate);
    return wrapper.IsEmpty() ? v8::Local<v8::Value>() : getHiddenValue(isolate, wrapper, key);
}

} // namespace blink
