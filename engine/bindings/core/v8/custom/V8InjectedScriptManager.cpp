/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
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

#include "sky/engine/config.h"
#include "sky/engine/core/inspector/InjectedScriptManager.h"

#include "bindings/core/v8/V8InjectedScriptHost.h"
#include "bindings/core/v8/V8Window.h"
#include "sky/engine/bindings/core/v8/BindingSecurity.h"
#include "sky/engine/bindings/core/v8/ScopedPersistent.h"
#include "sky/engine/bindings/core/v8/ScriptDebugServer.h"
#include "sky/engine/bindings/core/v8/ScriptValue.h"
#include "sky/engine/bindings/core/v8/V8Binding.h"
#include "sky/engine/bindings/core/v8/V8ObjectConstructor.h"
#include "sky/engine/bindings/core/v8/V8ScriptRunner.h"
#include "sky/engine/core/frame/LocalDOMWindow.h"
#include "sky/engine/core/inspector/InjectedScriptHost.h"
#include "sky/engine/wtf/RefPtr.h"

namespace blink {

InjectedScriptManager::CallbackData* InjectedScriptManager::createCallbackData(InjectedScriptManager* injectedScriptManager)
{
    OwnPtr<InjectedScriptManager::CallbackData> callbackData = adoptPtr(new InjectedScriptManager::CallbackData());
    InjectedScriptManager::CallbackData* callbackDataPtr = callbackData.get();
    callbackData->injectedScriptManager = injectedScriptManager;
    m_callbackDataSet.add(callbackData.release());
    return callbackDataPtr;
}

void InjectedScriptManager::removeCallbackData(InjectedScriptManager::CallbackData* callbackData)
{
    ASSERT(m_callbackDataSet.contains(callbackData));
    m_callbackDataSet.remove(callbackData);
}

static v8::Local<v8::Object> createInjectedScriptHostV8Wrapper(PassRefPtr<InjectedScriptHost> host, InjectedScriptManager* injectedScriptManager, v8::Handle<v8::Object> creationContext, v8::Isolate* isolate)
{
    ASSERT(host);

    v8::Handle<v8::Object> wrapper = V8DOMWrapper::createWrapper(creationContext, &V8InjectedScriptHost::wrapperTypeInfo, V8InjectedScriptHost::toScriptWrappableBase(host.get()), isolate);
    if (UNLIKELY(wrapper.IsEmpty()))
        return wrapper;

    // Create a weak reference to the v8 wrapper of InspectorBackend to deref
    // InspectorBackend when the wrapper is garbage collected.
    InjectedScriptManager::CallbackData* callbackData = injectedScriptManager->createCallbackData(injectedScriptManager);
    callbackData->host = host.get();
    callbackData->handle.set(isolate, wrapper);
    callbackData->handle.setWeak(callbackData, &InjectedScriptManager::setWeakCallback);

    V8DOMWrapper::setNativeInfo(wrapper, &V8InjectedScriptHost::wrapperTypeInfo, V8InjectedScriptHost::toScriptWrappableBase(host.get()));
    ASSERT(V8DOMWrapper::isDOMWrapper(wrapper));
    return wrapper;
}

ScriptValue InjectedScriptManager::createInjectedScript(const String& scriptSource, ScriptState* inspectedScriptState, int id)
{
    v8::Isolate* isolate = inspectedScriptState->isolate();
    ScriptState::Scope scope(inspectedScriptState);

    // Call custom code to create InjectedScripHost wrapper specific for the context
    // instead of calling toV8() that would create the
    // wrapper in the current context.
    // FIXME: make it possible to use generic bindings factory for InjectedScriptHost.
    v8::Local<v8::Object> scriptHostWrapper = createInjectedScriptHostV8Wrapper(m_injectedScriptHost, this, inspectedScriptState->context()->Global(), inspectedScriptState->isolate());
    if (scriptHostWrapper.IsEmpty())
        return ScriptValue();

    // Inject javascript into the context. The compiled script is supposed to evaluate into
    // a single anonymous function(it's anonymous to avoid cluttering the global object with
    // inspector's stuff) the function is called a few lines below with InjectedScriptHost wrapper,
    // injected script id and explicit reference to the inspected global object. The function is expected
    // to create and configure InjectedScript instance that is going to be used by the inspector.
    v8::Local<v8::Value> value = V8ScriptRunner::compileAndRunInternalScript(v8String(isolate, scriptSource), isolate);
    ASSERT(!value.IsEmpty());
    ASSERT(value->IsFunction());

    v8::Local<v8::Object> windowGlobal = inspectedScriptState->context()->Global();
    v8::Handle<v8::Value> info[] = { scriptHostWrapper, windowGlobal, v8::Number::New(inspectedScriptState->isolate(), id) };
    v8::Local<v8::Value> injectedScriptValue = V8ScriptRunner::callInternalFunction(v8::Local<v8::Function>::Cast(value), windowGlobal, WTF_ARRAY_LENGTH(info), info, inspectedScriptState->isolate());
    return ScriptValue(inspectedScriptState, injectedScriptValue);
}

void InjectedScriptManager::setWeakCallback(const v8::WeakCallbackData<v8::Object, InjectedScriptManager::CallbackData>& data)
{
    InjectedScriptManager::CallbackData* callbackData = data.GetParameter();
    callbackData->injectedScriptManager->removeCallbackData(callbackData);
}

} // namespace blink
