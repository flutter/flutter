// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_BINDINGS_CORE_V8_V8HIDDENVALUE_H_
#define SKY_ENGINE_BINDINGS_CORE_V8_V8HIDDENVALUE_H_

#include "sky/engine/bindings/core/v8/ScopedPersistent.h"
#include "sky/engine/bindings/core/v8/ScriptPromiseProperties.h"
#include "v8/include/v8.h"

namespace blink {

class ScriptWrappable;

#define V8_HIDDEN_VALUES(V) \
    V(arrayBufferData) \
    V(customElementAttachedCallback) \
    V(customElementAttributeChangedCallback) \
    V(customElementCreatedCallback) \
    V(customElementDetachedCallback) \
    V(customElementDocument) \
    V(customElementIsInterfacePrototypeObject) \
    V(customElementNamespaceURI) \
    V(customElementTagName) \
    V(callback) \
    V(condition) \
    V(data) \
    V(detail) \
    V(document) \
    V(error) \
    V(event) \
    V(idbCursorRequest) \
    V(port1) \
    V(port2) \
    V(state) \
    V(stringData) \
    V(scriptState) \
    V(thenableHiddenPromise) \
    V(toStringString) \
    SCRIPT_PROMISE_PROPERTIES(V, Promise)  \
    SCRIPT_PROMISE_PROPERTIES(V, Resolver)

class V8HiddenValue {
public:
#define V8_DECLARE_METHOD(name) static v8::Handle<v8::String> name(v8::Isolate* isolate);
    V8_HIDDEN_VALUES(V8_DECLARE_METHOD);
#undef V8_DECLARE_METHOD

    static v8::Local<v8::Value> getHiddenValue(v8::Isolate*, v8::Handle<v8::Object>, v8::Handle<v8::String>);
    static bool setHiddenValue(v8::Isolate*, v8::Handle<v8::Object>, v8::Handle<v8::String>, v8::Handle<v8::Value>);
    static bool deleteHiddenValue(v8::Isolate*, v8::Handle<v8::Object>, v8::Handle<v8::String>);
    static v8::Local<v8::Value> getHiddenValueFromMainWorldWrapper(v8::Isolate*, ScriptWrappable*, v8::Handle<v8::String>);

private:
#define V8_DECLARE_FIELD(name) ScopedPersistent<v8::String> m_##name;
    V8_HIDDEN_VALUES(V8_DECLARE_FIELD);
#undef V8_DECLARE_FIELD
};

} // namespace blink

#endif  // SKY_ENGINE_BINDINGS_CORE_V8_V8HIDDENVALUE_H_
