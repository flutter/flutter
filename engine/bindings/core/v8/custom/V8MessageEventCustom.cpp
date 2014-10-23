/*
 * Copyright (C) 2009 Google Inc. All rights reserved.
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
#include "bindings/core/v8/V8MessageEvent.h"

#include "bindings/core/v8/SerializedScriptValue.h"
#include "bindings/core/v8/V8Binding.h"
#include "bindings/core/v8/V8HiddenValue.h"
#include "bindings/core/v8/V8MessagePort.h"
#include "bindings/core/v8/V8Window.h"
#include "bindings/core/v8/custom/V8ArrayBufferCustom.h"
#include "core/events/MessageEvent.h"

namespace blink {

// Ensures a wrapper is created for the data to return now so that V8 knows how
// much memory is used via the wrapper. To keep the wrapper alive, it's set to
// the wrapper of the MessageEvent as a hidden value.
static void ensureWrapperCreatedAndAssociated(MessageEvent* eventImpl, v8::Handle<v8::Object> eventWrapper, v8::Isolate* isolate)
{
    switch (eventImpl->dataType()) {
    case MessageEvent::DataTypeScriptValue:
    case MessageEvent::DataTypeSerializedScriptValue:
        break;
    case MessageEvent::DataTypeString: {
        String stringValue = eventImpl->dataAsString();
        V8HiddenValue::setHiddenValue(isolate, eventWrapper, V8HiddenValue::stringData(isolate), v8String(isolate, stringValue));
        break;
    }
    case MessageEvent::DataTypeArrayBuffer:
        V8HiddenValue::setHiddenValue(isolate, eventWrapper, V8HiddenValue::arrayBufferData(isolate), toV8(eventImpl->dataAsArrayBuffer(), eventWrapper, isolate));
        break;
    }
}

v8::Handle<v8::Object> wrap(MessageEvent* impl, v8::Handle<v8::Object> creationContext, v8::Isolate* isolate)
{
    ASSERT(impl);
    ASSERT(!DOMDataStore::containsWrapper<V8MessageEvent>(impl, isolate));
    v8::Handle<v8::Object> wrapper = V8MessageEvent::createWrapper(impl, creationContext, isolate);
    ensureWrapperCreatedAndAssociated(impl, wrapper, isolate);
    return wrapper;
}

void V8MessageEvent::dataAttributeGetterCustom(const v8::PropertyCallbackInfo<v8::Value>& info)
{
    MessageEvent* event = V8MessageEvent::toNative(info.Holder());

    v8::Handle<v8::Value> result;
    switch (event->dataType()) {
    case MessageEvent::DataTypeScriptValue: {
        result = V8HiddenValue::getHiddenValue(info.GetIsolate(), info.Holder(), V8HiddenValue::data(info.GetIsolate()));
        if (result.IsEmpty()) {
            if (!event->dataAsSerializedScriptValue()) {
                // If we're in an isolated world and the event was created in the main world,
                // we need to find the 'data' property on the main world wrapper and clone it.
                v8::Local<v8::Value> mainWorldData = V8HiddenValue::getHiddenValueFromMainWorldWrapper(info.GetIsolate(), event, V8HiddenValue::data(info.GetIsolate()));
                if (!mainWorldData.IsEmpty())
                    event->setSerializedData(SerializedScriptValue::createAndSwallowExceptions(mainWorldData, info.GetIsolate()));
            }
            if (event->dataAsSerializedScriptValue())
                result = event->dataAsSerializedScriptValue()->deserialize(info.GetIsolate());
            else
                result = v8::Null(info.GetIsolate());
        }
        break;
    }

    case MessageEvent::DataTypeSerializedScriptValue:
        if (SerializedScriptValue* serializedValue = event->dataAsSerializedScriptValue()) {
            MessagePortArray ports = event->ports();
            result = serializedValue->deserialize(info.GetIsolate(), &ports);
        } else {
            result = v8::Null(info.GetIsolate());
        }
        break;

    case MessageEvent::DataTypeString: {
        result = V8HiddenValue::getHiddenValue(info.GetIsolate(), info.Holder(), V8HiddenValue::stringData(info.GetIsolate()));
        if (result.IsEmpty()) {
            String stringValue = event->dataAsString();
            result = v8String(info.GetIsolate(), stringValue);
        }
        break;
    }

    case MessageEvent::DataTypeArrayBuffer:
        result = V8HiddenValue::getHiddenValue(info.GetIsolate(), info.Holder(), V8HiddenValue::arrayBufferData(info.GetIsolate()));
        if (result.IsEmpty())
            result = toV8(event->dataAsArrayBuffer(), info.Holder(), info.GetIsolate());
        break;
    }

    // Overwrite the data attribute so it returns the cached result in future invocations.
    // This custom getter handler will not be called again.
    v8::PropertyAttribute dataAttr = static_cast<v8::PropertyAttribute>(v8::DontDelete | v8::ReadOnly);
    info.Holder()->ForceSet(v8AtomicString(info.GetIsolate(), "data"), result, dataAttr);
    v8SetReturnValue(info, result);
}

void V8MessageEvent::initMessageEventMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    MessageEvent* event = V8MessageEvent::toNative(info.Holder());
    TOSTRING_VOID(V8StringResource<>, typeArg, info[0]);
    TONATIVE_VOID(bool, canBubbleArg, info[1]->BooleanValue());
    TONATIVE_VOID(bool, cancelableArg, info[2]->BooleanValue());
    v8::Handle<v8::Value> dataArg = info[3];
    TOSTRING_VOID(V8StringResource<>, originArg, info[4]);
    TOSTRING_VOID(V8StringResource<>, lastEventIdArg, info[5]);
    LocalDOMWindow* sourceArg = toDOMWindow(info[6], info.GetIsolate());
    OwnPtrWillBeRawPtr<MessagePortArray> portArray = nullptr;
    const int portArrayIndex = 7;
    if (!isUndefinedOrNull(info[portArrayIndex])) {
        portArray = adoptPtrWillBeNoop(new MessagePortArray);
        bool success = false;
        *portArray = toRefPtrWillBeMemberNativeArray<MessagePort, V8MessagePort>(info[portArrayIndex], portArrayIndex + 1, info.GetIsolate(), &success);
        if (!success)
            return;
    }
    event->initMessageEvent(typeArg, canBubbleArg, cancelableArg, originArg, lastEventIdArg, sourceArg, portArray.release());

    if (!dataArg.IsEmpty()) {
        V8HiddenValue::setHiddenValue(info.GetIsolate(), info.Holder(), V8HiddenValue::data(info.GetIsolate()), dataArg);
        if (DOMWrapperWorld::current(info.GetIsolate()).isIsolatedWorld())
            event->setSerializedData(SerializedScriptValue::createAndSwallowExceptions(dataArg, info.GetIsolate()));
    }
}

} // namespace blink
