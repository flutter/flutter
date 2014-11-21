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

#ifndef SKY_ENGINE_BINDINGS_CORE_V8_V8DOMWRAPPER_H_
#define SKY_ENGINE_BINDINGS_CORE_V8_V8DOMWRAPPER_H_

#include "sky/engine/bindings/core/v8/DOMDataStore.h"
#include "sky/engine/bindings/core/v8/ScriptWrappable.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RawPtr.h"
#include "sky/engine/wtf/text/AtomicString.h"
#include "v8/include/v8.h"

namespace blink {

class Node;
struct WrapperTypeInfo;

class V8DOMWrapper {
public:
    static v8::Local<v8::Object> createWrapper(v8::Handle<v8::Object> creationContext, const WrapperTypeInfo*, ScriptWrappableBase* internalPointer, v8::Isolate*);

    template<typename V8T, typename T>
    static v8::Handle<v8::Object> associateObjectWithWrapper(PassRefPtr<T>, const WrapperTypeInfo*, v8::Handle<v8::Object>, v8::Isolate*);
    template<typename V8T, typename T>
    static v8::Handle<v8::Object> associateObjectWithWrapper(RawPtr<T> object, const WrapperTypeInfo* wrapperTypeInfo, v8::Handle<v8::Object> wrapper, v8::Isolate* isolate)
    {
        return associateObjectWithWrapper<V8T, T>(object.get(), wrapperTypeInfo, wrapper, isolate);
    }
    template<typename V8T, typename T>
    static v8::Handle<v8::Object> associateObjectWithWrapper(T*, const WrapperTypeInfo*, v8::Handle<v8::Object>, v8::Isolate*);
    static v8::Handle<v8::Object> associateObjectWithWrapperNonTemplate(ScriptWrappable*, const WrapperTypeInfo*, v8::Handle<v8::Object>, v8::Isolate*);
    static v8::Handle<v8::Object> associateObjectWithWrapperNonTemplate(Node*, const WrapperTypeInfo*, v8::Handle<v8::Object>, v8::Isolate*);
    static void setNativeInfo(v8::Handle<v8::Object>, const WrapperTypeInfo*, ScriptWrappableBase* internalPointer);
    static void setNativeInfoForHiddenWrapper(v8::Handle<v8::Object>, const WrapperTypeInfo*, ScriptWrappableBase* internalPointer);
    static void clearNativeInfo(v8::Handle<v8::Object>, const WrapperTypeInfo*);

    static bool isDOMWrapper(v8::Handle<v8::Value>);
};

inline void V8DOMWrapper::setNativeInfo(v8::Handle<v8::Object> wrapper, const WrapperTypeInfo* wrapperTypeInfo, ScriptWrappableBase* internalPointer)
{
    ASSERT(wrapper->InternalFieldCount() >= 2);
    ASSERT(internalPointer);
    ASSERT(wrapperTypeInfo);
    wrapper->SetAlignedPointerInInternalField(v8DOMWrapperObjectIndex, internalPointer);
    wrapper->SetAlignedPointerInInternalField(v8DOMWrapperTypeIndex, const_cast<WrapperTypeInfo*>(wrapperTypeInfo));
}

inline void V8DOMWrapper::setNativeInfoForHiddenWrapper(v8::Handle<v8::Object> wrapper, const WrapperTypeInfo* wrapperTypeInfo, ScriptWrappableBase* internalPointer)
{
    // see WindowProxy::installDOMWindow() comment for why this version is needed and safe.
    ASSERT(wrapper->InternalFieldCount() >= 2);
    ASSERT(internalPointer);
    ASSERT(wrapperTypeInfo);
    wrapper->SetAlignedPointerInInternalField(v8DOMWrapperObjectIndex, internalPointer);
    wrapper->SetAlignedPointerInInternalField(v8DOMWrapperTypeIndex, const_cast<WrapperTypeInfo*>(wrapperTypeInfo));
}

inline void V8DOMWrapper::clearNativeInfo(v8::Handle<v8::Object> wrapper, const WrapperTypeInfo* wrapperTypeInfo)
{
    ASSERT(wrapper->InternalFieldCount() >= 2);
    ASSERT(wrapperTypeInfo);
    // clearNativeInfo() is used only by NP objects, which are not garbage collected.
    wrapper->SetAlignedPointerInInternalField(v8DOMWrapperTypeIndex, const_cast<WrapperTypeInfo*>(wrapperTypeInfo));
    wrapper->SetAlignedPointerInInternalField(v8DOMWrapperObjectIndex, 0);
}

template<typename V8T, typename T>
inline v8::Handle<v8::Object> V8DOMWrapper::associateObjectWithWrapper(PassRefPtr<T> object, const WrapperTypeInfo* wrapperTypeInfo, v8::Handle<v8::Object> wrapper, v8::Isolate* isolate)
{
    setNativeInfo(wrapper, wrapperTypeInfo, V8T::toScriptWrappableBase(object.get()));
    ASSERT(isDOMWrapper(wrapper));
    DOMDataStore::setWrapper<V8T>(object.leakRef(), wrapper, isolate, wrapperTypeInfo);
    return wrapper;
}

inline v8::Handle<v8::Object> V8DOMWrapper::associateObjectWithWrapperNonTemplate(ScriptWrappable* impl, const WrapperTypeInfo* wrapperTypeInfo, v8::Handle<v8::Object> wrapper, v8::Isolate* isolate)
{
    wrapperTypeInfo->refObject(impl->toScriptWrappableBase());
    setNativeInfo(wrapper, wrapperTypeInfo, impl->toScriptWrappableBase());
    ASSERT(isDOMWrapper(wrapper));
    DOMDataStore::setWrapperNonTemplate(impl, wrapper, isolate, wrapperTypeInfo);
    return wrapper;
}

inline v8::Handle<v8::Object> V8DOMWrapper::associateObjectWithWrapperNonTemplate(Node* node, const WrapperTypeInfo* wrapperTypeInfo, v8::Handle<v8::Object> wrapper, v8::Isolate* isolate)
{
    wrapperTypeInfo->refObject(ScriptWrappable::fromObject(node)->toScriptWrappableBase());
    setNativeInfo(wrapper, wrapperTypeInfo, ScriptWrappable::fromObject(node)->toScriptWrappableBase());
    ASSERT(isDOMWrapper(wrapper));
    DOMDataStore::setWrapperNonTemplate(node, wrapper, isolate, wrapperTypeInfo);
    return wrapper;
}

class V8WrapperInstantiationScope {
public:
    V8WrapperInstantiationScope(v8::Handle<v8::Object> creationContext, v8::Isolate* isolate)
        : m_didEnterContext(false)
        , m_context(isolate->GetCurrentContext())
    {
        // creationContext should not be empty. Because if we have an
        // empty creationContext, we will end up creating
        // a new object in the context currently entered. This is wrong.
        RELEASE_ASSERT(!creationContext.IsEmpty());
        v8::Handle<v8::Context> contextForWrapper = creationContext->CreationContext();
        // For performance, we enter the context only if the currently running context
        // is different from the context that we are about to enter.
        if (contextForWrapper == m_context)
            return;
        m_context = v8::Local<v8::Context>::New(isolate, contextForWrapper);
        m_didEnterContext = true;
        m_context->Enter();
    }

    ~V8WrapperInstantiationScope()
    {
        if (!m_didEnterContext)
            return;
        m_context->Exit();
    }

    v8::Handle<v8::Context> context() const { return m_context; }

private:
    bool m_didEnterContext;
    v8::Handle<v8::Context> m_context;
};

} // namespace blink

#endif  // SKY_ENGINE_BINDINGS_CORE_V8_V8DOMWRAPPER_H_
