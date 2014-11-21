/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

#ifndef V8ArrayBufferCustom_h
#define V8ArrayBufferCustom_h

#include "sky/engine/bindings/core/v8/V8Binding.h"
#include "sky/engine/bindings/core/v8/V8DOMWrapper.h"
#include "sky/engine/bindings/core/v8/WrapperTypeInfo.h"
#include "sky/engine/wtf/ArrayBuffer.h"
#include "v8/include/v8.h"

namespace blink {

class V8ArrayBufferDeallocationObserver final: public WTF::ArrayBufferDeallocationObserver {
public:
    virtual void arrayBufferDeallocated(unsigned sizeInBytes) override
    {
        v8::Isolate::GetCurrent()->AdjustAmountOfExternalAllocatedMemory(-static_cast<int>(sizeInBytes));
    }
    static V8ArrayBufferDeallocationObserver* instanceTemplate();

protected:
    virtual void blinkAllocatedMemory(unsigned sizeInBytes) override
    {
        v8::Isolate::GetCurrent()->AdjustAmountOfExternalAllocatedMemory(static_cast<int>(sizeInBytes));
    }
};

class V8ArrayBuffer {
public:
    static bool hasInstance(v8::Handle<v8::Value>, v8::Isolate*);
    static ArrayBuffer* toNative(v8::Handle<v8::Object>);
    static ArrayBuffer* toNativeWithTypeCheck(v8::Isolate*, v8::Handle<v8::Value>);
    static void refObject(ScriptWrappableBase* internalPointer);
    static void derefObject(ScriptWrappableBase* internalPointer);
    static const WrapperTypeInfo wrapperTypeInfo;
    static const int internalFieldCount = v8DefaultWrapperInternalFieldCount;

    static inline ScriptWrappableBase* toScriptWrappableBase(ArrayBuffer* impl)
    {
        return reinterpret_cast<ScriptWrappableBase*>(impl);
    }

    static inline ArrayBuffer* fromInternalPointer(ScriptWrappableBase* internalPointer)
    {
        return reinterpret_cast<ArrayBuffer*>(internalPointer);
    }

private:
    friend v8::Handle<v8::Object> wrap(ArrayBuffer*, v8::Handle<v8::Object> creationContext, v8::Isolate*);
    static v8::Handle<v8::Object> createWrapper(PassRefPtr<ArrayBuffer>, v8::Handle<v8::Object> creationContext, v8::Isolate*);
};

inline v8::Handle<v8::Object> wrap(ArrayBuffer* impl, v8::Handle<v8::Object> creationContext, v8::Isolate* isolate)
{
    ASSERT(impl);
    ASSERT(!DOMDataStore::containsWrapper<V8ArrayBuffer>(impl, isolate));
    return V8ArrayBuffer::createWrapper(impl, creationContext, isolate);
}

inline v8::Handle<v8::Value> toV8(ArrayBuffer* impl, v8::Handle<v8::Object> creationContext, v8::Isolate* isolate)
{
    if (UNLIKELY(!impl))
        return v8::Null(isolate);
    v8::Handle<v8::Value> wrapper = DOMDataStore::getWrapper<V8ArrayBuffer>(impl, isolate);
    if (!wrapper.IsEmpty())
        return wrapper;
    return wrap(impl, creationContext, isolate);
}

template<class CallbackInfo>
inline void v8SetReturnValue(const CallbackInfo& info, ArrayBuffer* impl)
{
    if (UNLIKELY(!impl)) {
        v8SetReturnValueNull(info);
        return;
    }
    if (DOMDataStore::setReturnValueFromWrapper<V8ArrayBuffer>(info.GetReturnValue(), impl))
        return;
    v8::Handle<v8::Object> wrapper = wrap(impl, info.Holder(), info.GetIsolate());
    v8SetReturnValue(info, wrapper);
}

template<class CallbackInfo>
inline void v8SetReturnValueForMainWorld(const CallbackInfo& info, ArrayBuffer* impl)
{
    ASSERT(DOMWrapperWorld::current(info.GetIsolate()).isMainWorld());
    if (UNLIKELY(!impl)) {
        v8SetReturnValueNull(info);
        return;
    }
    if (DOMDataStore::setReturnValueFromWrapperForMainWorld<V8ArrayBuffer>(info.GetReturnValue(), impl))
        return;
    v8::Handle<v8::Value> wrapper = wrap(impl, info.Holder(), info.GetIsolate());
    v8SetReturnValue(info, wrapper);
}

template<class CallbackInfo, class Wrappable>
inline void v8SetReturnValueFast(const CallbackInfo& info, ArrayBuffer* impl, Wrappable* wrappable)
{
    if (UNLIKELY(!impl)) {
        v8SetReturnValueNull(info);
        return;
    }
    if (DOMDataStore::setReturnValueFromWrapperFast<V8ArrayBuffer>(info.GetReturnValue(), impl, info.Holder(), wrappable))
        return;
    v8::Handle<v8::Object> wrapper = wrap(impl, info.Holder(), info.GetIsolate());
    v8SetReturnValue(info, wrapper);
}

inline v8::Handle<v8::Value> toV8(PassRefPtr< ArrayBuffer > impl, v8::Handle<v8::Object> creationContext, v8::Isolate* isolate)
{
    return toV8(impl.get(), creationContext, isolate);
}

template<class CallbackInfo>
inline void v8SetReturnValue(const CallbackInfo& info, PassRefPtr< ArrayBuffer > impl)
{
    v8SetReturnValue(info, impl.get());
}

template<class CallbackInfo>
inline void v8SetReturnValueForMainWorld(const CallbackInfo& info, PassRefPtr< ArrayBuffer > impl)
{
    v8SetReturnValueForMainWorld(info, impl.get());
}

template<class CallbackInfo, class Wrappable>
inline void v8SetReturnValueFast(const CallbackInfo& info, PassRefPtr< ArrayBuffer > impl, Wrappable* wrappable)
{
    v8SetReturnValueFast(info, impl.get(), wrappable);
}

} // namespace blink

#endif // V8ArrayBufferCustom_h
