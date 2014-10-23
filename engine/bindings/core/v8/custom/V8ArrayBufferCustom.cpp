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
#include "bindings/core/v8/custom/V8ArrayBufferCustom.h"

#include "bindings/core/v8/V8Binding.h"
#include "wtf/ArrayBuffer.h"
#include "wtf/StdLibExtras.h"

namespace blink {

using namespace WTF;

V8ArrayBufferDeallocationObserver* V8ArrayBufferDeallocationObserver::instanceTemplate()
{
    DEFINE_STATIC_LOCAL(V8ArrayBufferDeallocationObserver, deallocationObserver, ());
    return &deallocationObserver;
}

const WrapperTypeInfo V8ArrayBuffer::wrapperTypeInfo = {
    gin::kEmbedderBlink,
    0,
    V8ArrayBuffer::refObject,
    V8ArrayBuffer::derefObject,
    V8ArrayBuffer::createPersistentHandle,
    0, 0, 0, 0, 0, 0,
    WrapperTypeInfo::WrapperTypeObjectPrototype,
    WrapperTypeInfo::ObjectClassId,
    WrapperTypeInfo::Independent,
    WrapperTypeInfo::RefCountedObject
};

bool V8ArrayBuffer::hasInstance(v8::Handle<v8::Value> value, v8::Isolate*)
{
    return value->IsArrayBuffer();
}

void V8ArrayBuffer::refObject(ScriptWrappableBase* internalPointer)
{
    fromInternalPointer(internalPointer)->ref();
}

void V8ArrayBuffer::derefObject(ScriptWrappableBase* internalPointer)
{
    fromInternalPointer(internalPointer)->deref();
}

WrapperPersistentNode* V8ArrayBuffer::createPersistentHandle(ScriptWrappableBase* internalPointer)
{
    ASSERT_NOT_REACHED();
    return 0;
}

v8::Handle<v8::Object> V8ArrayBuffer::createWrapper(PassRefPtr<ArrayBuffer> impl, v8::Handle<v8::Object> creationContext, v8::Isolate* isolate)
{
    ASSERT(impl.get());
    ASSERT(!DOMDataStore::containsWrapper<V8ArrayBuffer>(impl.get(), isolate));

    v8::Handle<v8::Object> wrapper = v8::ArrayBuffer::New(isolate, impl->data(), impl->byteLength());
    impl->setDeallocationObserver(V8ArrayBufferDeallocationObserver::instanceTemplate());

    V8DOMWrapper::associateObjectWithWrapper<V8ArrayBuffer>(impl, &wrapperTypeInfo, wrapper, isolate);
    return wrapper;
}

ArrayBuffer* V8ArrayBuffer::toNative(v8::Handle<v8::Object> object)
{
    ASSERT(object->IsArrayBuffer());
    v8::Local<v8::ArrayBuffer> v8buffer = object.As<v8::ArrayBuffer>();
    if (v8buffer->IsExternal()) {
        RELEASE_ASSERT(toWrapperTypeInfo(object)->ginEmbedder == gin::kEmbedderBlink);
        return reinterpret_cast<ArrayBuffer*>(blink::toScriptWrappableBase(object));
    }

    v8::ArrayBuffer::Contents v8Contents = v8buffer->Externalize();
    ArrayBufferContents contents(v8Contents.Data(), v8Contents.ByteLength(),
        V8ArrayBufferDeallocationObserver::instanceTemplate());
    RefPtr<ArrayBuffer> buffer = ArrayBuffer::create(contents);
    V8DOMWrapper::associateObjectWithWrapper<V8ArrayBuffer>(buffer.release(), &wrapperTypeInfo, object, v8::Isolate::GetCurrent());

    return reinterpret_cast<ArrayBuffer*>(blink::toScriptWrappableBase(object));
}

ArrayBuffer* V8ArrayBuffer::toNativeWithTypeCheck(v8::Isolate* isolate, v8::Handle<v8::Value> value)
{
    return V8ArrayBuffer::hasInstance(value, isolate) ? V8ArrayBuffer::toNative(v8::Handle<v8::Object>::Cast(value)) : 0;
}

template<>
v8::Handle<v8::Value> toV8NoInline(ArrayBuffer* impl, v8::Handle<v8::Object> creationContext, v8::Isolate* isolate)
{
    return toV8(impl, creationContext, isolate);
}

} // namespace blink
