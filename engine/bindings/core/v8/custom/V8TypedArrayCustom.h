/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
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

#ifndef V8TypedArrayCustom_h
#define V8TypedArrayCustom_h

#include "sky/engine/bindings/core/v8/V8Binding.h"
#include "sky/engine/bindings/core/v8/V8DOMWrapper.h"
#include "sky/engine/bindings/core/v8/WrapperTypeInfo.h"
#include "sky/engine/bindings/core/v8/custom/V8ArrayBufferCustom.h"
#include "sky/engine/wtf/ArrayBuffer.h"
#include "v8/include/v8.h"

namespace blink {

template<typename T>
class TypedArrayTraits
{ };

template<typename TypedArray>
class V8TypedArray {
public:
    static bool hasInstance(v8::Handle<v8::Value> value, v8::Isolate*)
    {
        return TypedArrayTraits<TypedArray>::IsInstance(value);
    }

    static TypedArray* toNative(v8::Handle<v8::Object>);
    static TypedArray* toNativeWithTypeCheck(v8::Isolate*, v8::Handle<v8::Value>);
    static void refObject(ScriptWrappableBase* internalPointer);
    static void derefObject(ScriptWrappableBase* internalPointer);
    static const WrapperTypeInfo wrapperTypeInfo;
    static const int internalFieldCount = v8DefaultWrapperInternalFieldCount;

    static v8::Handle<v8::Object> wrap(TypedArray* impl, v8::Handle<v8::Object> creationContext, v8::Isolate* isolate)
    {
        ASSERT(impl);
        ASSERT(!DOMDataStore::containsWrapper<Binding>(impl, isolate));
        return V8TypedArray<TypedArray>::createWrapper(impl, creationContext, isolate);
    }

    static v8::Handle<v8::Value> toV8(TypedArray* impl, v8::Handle<v8::Object> creationContext, v8::Isolate* isolate)
    {
        if (UNLIKELY(!impl))
            return v8::Null(isolate);
        v8::Handle<v8::Value> wrapper = DOMDataStore::getWrapper<Binding>(impl, isolate);
        if (!wrapper.IsEmpty())
            return wrapper;
        return wrap(impl, creationContext, isolate);
    }

    template<typename CallbackInfo>
    static void v8SetReturnValue(const CallbackInfo& info, TypedArray* impl)
    {
        if (UNLIKELY(!impl)) {
            v8SetReturnValueNull(info);
            return;
        }
        if (DOMDataStore::setReturnValueFromWrapper<Binding>(info.GetReturnValue(), impl))
            return;
        v8::Handle<v8::Object> wrapper = wrap(impl, info.Holder(), info.GetIsolate());
        info.GetReturnValue().Set(wrapper);
    }

    template<typename CallbackInfo>
    static void v8SetReturnValueForMainWorld(const CallbackInfo& info, TypedArray* impl)
    {
        ASSERT(DOMWrapperWorld::current(info.GetIsolate()).isMainWorld());
        if (UNLIKELY(!impl)) {
            v8SetReturnValueNull(info);
            return;
        }
        if (DOMDataStore::setReturnValueFromWrapperForMainWorld<Binding>(info.GetReturnValue(), impl))
            return;
        v8::Handle<v8::Value> wrapper = wrap(impl, info.Holder(), info.GetIsolate());
        info.GetReturnValue().Set(wrapper);
    }

    template<class CallbackInfo, class Wrappable>
    static void v8SetReturnValueFast(const CallbackInfo& info, TypedArray* impl, Wrappable* wrappable)
    {
        if (UNLIKELY(!impl)) {
            v8SetReturnValueNull(info);
            return;
        }
        if (DOMDataStore::setReturnValueFromWrapperFast<Binding>(info.GetReturnValue(), impl, info.Holder(), wrappable))
            return;
        v8::Handle<v8::Object> wrapper = wrap(impl, info.Holder(), info.GetIsolate());
        info.GetReturnValue().Set(wrapper);
    }

    static inline ScriptWrappableBase* toScriptWrappableBase(TypedArray* impl)
    {
        return reinterpret_cast<ScriptWrappableBase*>(static_cast<void*>(impl));
    }

    static inline TypedArray* fromInternalPointer(ScriptWrappableBase* internalPointer)
    {
        return reinterpret_cast<TypedArray*>(static_cast<void*>(internalPointer));
    }
private:
    typedef TypedArrayTraits<TypedArray> Traits;
    typedef typename Traits::V8Type V8Type;
    typedef V8TypedArray<TypedArray> Binding;

    static v8::Handle<v8::Object> createWrapper(PassRefPtr<TypedArray>, v8::Handle<v8::Object> creationContext, v8::Isolate*);
};

template<typename TypedArray>
class TypedArrayWrapperTraits {
public:
    static const WrapperTypeInfo* info() { return &V8TypedArray<TypedArray>::wrapperTypeInfo; }
};


template <typename TypedArray>
v8::Handle<v8::Object> V8TypedArray<TypedArray>::createWrapper(PassRefPtr<TypedArray> impl, v8::Handle<v8::Object> creationContext, v8::Isolate* isolate)
{
    ASSERT(impl.get());
    ASSERT(!DOMDataStore::containsWrapper<Binding>(impl.get(), isolate));

    RefPtr<ArrayBuffer> buffer = impl->buffer();
    v8::Local<v8::Value> v8Buffer = blink::toV8(buffer.get(), creationContext, isolate);

    ASSERT(v8Buffer->IsArrayBuffer());

    v8::Local<v8::Object> wrapper = V8Type::New(v8Buffer.As<v8::ArrayBuffer>(), impl->byteOffset(), Traits::length(impl.get()));

    V8DOMWrapper::associateObjectWithWrapper<Binding>(impl, &wrapperTypeInfo, wrapper, isolate);
    return wrapper;
}

template <typename TypedArray>
TypedArray* V8TypedArray<TypedArray>::toNative(v8::Handle<v8::Object> object)
{
    ASSERT(Traits::IsInstance(object));
    void* typedarrayPtr = object->GetAlignedPointerFromInternalField(v8DOMWrapperObjectIndex);
    if (typedarrayPtr)
        return reinterpret_cast<TypedArray*>(typedarrayPtr);

    v8::Handle<V8Type> view = object.As<V8Type>();
    RefPtr<ArrayBuffer> arrayBuffer = V8ArrayBuffer::toNative(view->Buffer());
    RefPtr<TypedArray> typedArray = TypedArray::create(arrayBuffer, view->ByteOffset(), Traits::length(view));
    ASSERT(typedArray.get());
    V8DOMWrapper::associateObjectWithWrapper<Binding>(typedArray.release(), &wrapperTypeInfo, object, v8::Isolate::GetCurrent());

    typedarrayPtr = object->GetAlignedPointerFromInternalField(v8DOMWrapperObjectIndex);
    ASSERT(typedarrayPtr);
    return reinterpret_cast<TypedArray*>(typedarrayPtr);
}

template <typename TypedArray>
TypedArray* V8TypedArray<TypedArray>::toNativeWithTypeCheck(v8::Isolate* isolate, v8::Handle<v8::Value> value)
{
    return V8TypedArray<TypedArray>::hasInstance(value, isolate) ? V8TypedArray<TypedArray>::toNative(v8::Handle<v8::Object>::Cast(value)) : 0;
}

template <typename TypedArray>
const WrapperTypeInfo V8TypedArray<TypedArray>::wrapperTypeInfo = {
    gin::kEmbedderBlink,
    0,
    V8TypedArray<TypedArray>::refObject,
    V8TypedArray<TypedArray>::derefObject,
    0, 0, 0, 0, 0, 0,
    WrapperTypeInfo::WrapperTypeObjectPrototype,
    WrapperTypeInfo::ObjectClassId,
    WrapperTypeInfo::Independent,
};

template <typename TypedArray>
void V8TypedArray<TypedArray>::refObject(ScriptWrappableBase* internalPointer)
{
    fromInternalPointer(internalPointer)->ref();
}

template <typename TypedArray>
void V8TypedArray<TypedArray>::derefObject(ScriptWrappableBase* internalPointer)
{
    fromInternalPointer(internalPointer)->deref();
}

} // namespace blink

#endif // V8TypedArrayCustom_h
