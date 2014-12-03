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

#ifndef SKY_ENGINE_BINDINGS_CORE_V8_DOMDATASTORE_H_
#define SKY_ENGINE_BINDINGS_CORE_V8_DOMDATASTORE_H_

#include "sky/engine/bindings/core/v8/DOMWrapperMap.h"
#include "sky/engine/bindings/core/v8/DOMWrapperWorld.h"
#include "sky/engine/bindings/core/v8/ScriptWrappable.h"
#include "sky/engine/bindings/core/v8/WrapperTypeInfo.h"
#include "sky/engine/wtf/Noncopyable.h"
#include "sky/engine/wtf/StdLibExtras.h"
#include "v8/include/v8.h"

namespace blink {

class Node;

class DOMDataStore {
    WTF_MAKE_NONCOPYABLE(DOMDataStore);
public:
    explicit DOMDataStore(bool isMainWorld);
    ~DOMDataStore();

    static DOMDataStore& current(v8::Isolate*);

    // We can use a wrapper stored in a ScriptWrappable when we're in the main world.
    // This method does the fast check if we're in the main world. If this method returns true,
    // it is guaranteed that we're in the main world. On the other hand, if this method returns
    // false, nothing is guaranteed (we might be in the main world).
    template<typename T>
    static bool canUseScriptWrappable(T* object)
    {
        return ScriptWrappable::wrapperCanBeStoredInObject(object);
    }

    static bool canUseScriptWrappableNonTemplate(Node* object)
    {
        return true;
    }

    template<typename V8T, typename T, typename Wrappable>
    static bool setReturnValueFromWrapperFast(v8::ReturnValue<v8::Value> returnValue, T* object, v8::Local<v8::Object> holder, Wrappable* wrappable)
    {
        if (canUseScriptWrappable(object)) {
            ScriptWrappable::assertWrapperSanity<V8T, T>(object, object);
            return ScriptWrappable::fromObject(object)->setReturnValue(returnValue);
        }
        // The second fastest way to check if we're in the main world is to check if
        // the wrappable's wrapper is the same as the holder.
        // FIXME: Investigate if it's worth having this check for performance.
        if (holderContainsWrapper(holder, wrappable)) {
            if (ScriptWrappable::wrapperCanBeStoredInObject(object)) {
                ScriptWrappable::assertWrapperSanity<V8T, T>(object, object);
                return ScriptWrappable::fromObject(object)->setReturnValue(returnValue);
            }
            return DOMWrapperWorld::mainWorld().domDataStore().m_wrapperMap.setReturnValueFrom(returnValue, V8T::toScriptWrappableBase(object));
        }
        return current(returnValue.GetIsolate()).template setReturnValueFrom<V8T>(returnValue, object);
    }

    template<typename V8T, typename T>
    static bool setReturnValueFromWrapper(v8::ReturnValue<v8::Value> returnValue, T* object)
    {
        if (canUseScriptWrappable(object)) {
            ScriptWrappable::assertWrapperSanity<V8T, T>(object, object);
            return ScriptWrappable::fromObject(object)->setReturnValue(returnValue);
        }
        return current(returnValue.GetIsolate()).template setReturnValueFrom<V8T>(returnValue, object);
    }

    template<typename V8T, typename T>
    static bool setReturnValueFromWrapperForMainWorld(v8::ReturnValue<v8::Value> returnValue, T* object)
    {
        if (ScriptWrappable::wrapperCanBeStoredInObject(object))
            return ScriptWrappable::fromObject(object)->setReturnValue(returnValue);
        return DOMWrapperWorld::mainWorld().domDataStore().m_wrapperMap.setReturnValueFrom(returnValue, V8T::toScriptWrappableBase(object));
    }

    template<typename V8T, typename T>
    static v8::Handle<v8::Object> getWrapper(T* object, v8::Isolate* isolate)
    {
        if (canUseScriptWrappable(object)) {
            v8::Handle<v8::Object> result = ScriptWrappable::fromObject(object)->newLocalWrapper(isolate);
            // Security: always guard against malicious tampering.
            ScriptWrappable::assertWrapperSanity<V8T, T>(result, object);
            return result;
        }
        return current(isolate).template get<V8T>(object, isolate);
    }

    static v8::Handle<v8::Object> getWrapperNonTemplate(ScriptWrappableBase* object, v8::Isolate* isolate)
    {
        return current(isolate).getNonTemplate(object, isolate);
    }

    static v8::Handle<v8::Object> getWrapperNonTemplate(ScriptWrappable* object, v8::Isolate* isolate)
    {
        return current(isolate).getNonTemplate(object, isolate);
    }

    static v8::Handle<v8::Object> getWrapperNonTemplate(Node* node, v8::Isolate* isolate)
    {
        if (canUseScriptWrappableNonTemplate(node)) {
            v8::Handle<v8::Object> result = ScriptWrappable::fromObject(node)->newLocalWrapper(isolate);
            // Security: always guard against malicious tampering.
            ScriptWrappable::fromObject(node)->assertWrapperSanity(result);
            return result;
        }
        return current(isolate).getNonTemplate(ScriptWrappable::fromObject(node), isolate);
    }

    template<typename V8T, typename T>
    static void setWrapperReference(const v8::Persistent<v8::Object>& parent, T* child, v8::Isolate* isolate)
    {
        if (canUseScriptWrappable(child)) {
            ScriptWrappable::assertWrapperSanity<V8T, T>(child, child);
            ScriptWrappable::fromObject(child)->setReference(parent, isolate);
            return;
        }
        current(isolate).template setReference<V8T>(parent, child, isolate);
    }

    template<typename V8T, typename T>
    static void setWrapper(T* object, v8::Handle<v8::Object> wrapper, v8::Isolate* isolate, const WrapperTypeInfo* wrapperTypeInfo)
    {
        if (canUseScriptWrappable(object)) {
            ScriptWrappable::fromObject(object)->setWrapper(wrapper, isolate, wrapperTypeInfo);
            return;
        }
        return current(isolate).template set<V8T>(object, wrapper, isolate, wrapperTypeInfo);
    }

    static void setWrapperNonTemplate(ScriptWrappableBase* object, v8::Handle<v8::Object> wrapper, v8::Isolate* isolate, const WrapperTypeInfo* wrapperTypeInfo)
    {
        return current(isolate).setNonTemplate(object, wrapper, isolate, wrapperTypeInfo);
    }

    static void setWrapperNonTemplate(ScriptWrappable* object, v8::Handle<v8::Object> wrapper, v8::Isolate* isolate, const WrapperTypeInfo* wrapperTypeInfo)
    {
        return current(isolate).setNonTemplate(object, wrapper, isolate, wrapperTypeInfo);
    }

    static void setWrapperNonTemplate(Node* node, v8::Handle<v8::Object> wrapper, v8::Isolate* isolate, const WrapperTypeInfo* wrapperTypeInfo)
    {
        if (canUseScriptWrappableNonTemplate(node)) {
            ScriptWrappable::fromObject(node)->setWrapper(wrapper, isolate, wrapperTypeInfo);
            return;
        }
        return current(isolate).setNonTemplate(ScriptWrappable::fromObject(node), wrapper, isolate, wrapperTypeInfo);
    }

    template<typename V8T, typename T>
    static bool containsWrapper(T* object, v8::Isolate* isolate)
    {
        return current(isolate).template containsWrapper<V8T>(object);
    }

    static bool containsWrapperNonTemplate(ScriptWrappableBase* object, v8::Isolate* isolate)
    {
        return current(isolate).containsWrapperNonTemplate(object);
    }

    static bool containsWrapperNonTemplate(ScriptWrappable* object, v8::Isolate* isolate)
    {
        return current(isolate).containsWrapperNonTemplate(object);
    }

    template<typename V8T, typename T>
    v8::Handle<v8::Object> get(T* object, v8::Isolate* isolate)
    {
        if (ScriptWrappable::wrapperCanBeStoredInObject(object) && m_isMainWorld)
            return ScriptWrappable::fromObject(object)->newLocalWrapper(isolate);
        return m_wrapperMap.newLocal(V8T::toScriptWrappableBase(object), isolate);
    }

    v8::Handle<v8::Object> getNonTemplate(ScriptWrappableBase* object, v8::Isolate* isolate)
    {
        return m_wrapperMap.newLocal(object->toScriptWrappableBase(), isolate);
    }

    v8::Handle<v8::Object> getNonTemplate(ScriptWrappable* object, v8::Isolate* isolate)
    {
        if (m_isMainWorld)
            return object->newLocalWrapper(isolate);
        return m_wrapperMap.newLocal(object->toScriptWrappableBase(), isolate);
    }

    template<typename V8T, typename T>
    void setReference(const v8::Persistent<v8::Object>& parent, T* child, v8::Isolate* isolate)
    {
        if (ScriptWrappable::wrapperCanBeStoredInObject(child) && m_isMainWorld) {
            ScriptWrappable::fromObject(child)->setReference(parent, isolate);
            return;
        }
        m_wrapperMap.setReference(parent, V8T::toScriptWrappableBase(child), isolate);
    }

    template<typename V8T, typename T>
    bool setReturnValueFrom(v8::ReturnValue<v8::Value> returnValue, T* object)
    {
        if (ScriptWrappable::wrapperCanBeStoredInObject(object) && m_isMainWorld)
            return ScriptWrappable::fromObject(object)->setReturnValue(returnValue);
        return m_wrapperMap.setReturnValueFrom(returnValue, V8T::toScriptWrappableBase(object));
    }

    template<typename V8T, typename T>
    bool containsWrapper(T* object)
    {
        if (ScriptWrappable::wrapperCanBeStoredInObject(object) && m_isMainWorld)
            return ScriptWrappable::fromObject(object)->containsWrapper();
        return m_wrapperMap.containsKey(V8T::toScriptWrappableBase(object));
    }

    bool containsWrapperNonTemplate(ScriptWrappableBase* object)
    {
        return m_wrapperMap.containsKey(object->toScriptWrappableBase());
    }

    bool containsWrapperNonTemplate(ScriptWrappable* object)
    {
        if (m_isMainWorld)
            return object->containsWrapper();
        return m_wrapperMap.containsKey(object->toScriptWrappableBase());
    }

private:
    template<typename V8T, typename T>
    void set(T* object, v8::Handle<v8::Object> wrapper, v8::Isolate* isolate, const WrapperTypeInfo* wrapperTypeInfo)
    {
        ASSERT(object);
        ASSERT(!wrapper.IsEmpty());
        if (ScriptWrappable::wrapperCanBeStoredInObject(object) && m_isMainWorld) {
            ScriptWrappable::fromObject(object)->setWrapper(wrapper, isolate, wrapperTypeInfo);
            return;
        }
        m_wrapperMap.set(V8T::toScriptWrappableBase(object), wrapper, wrapperTypeInfo);
    }

    void setNonTemplate(ScriptWrappableBase* object, v8::Handle<v8::Object> wrapper, v8::Isolate* isolate, const WrapperTypeInfo* wrapperTypeInfo)
    {
        ASSERT(object);
        ASSERT(!wrapper.IsEmpty());
        m_wrapperMap.set(object->toScriptWrappableBase(), wrapper, wrapperTypeInfo);
    }

    void setNonTemplate(ScriptWrappable* object, v8::Handle<v8::Object> wrapper, v8::Isolate* isolate, const WrapperTypeInfo* wrapperTypeInfo)
    {
        ASSERT(object);
        ASSERT(!wrapper.IsEmpty());
        if (m_isMainWorld) {
            ScriptWrappable::fromObject(object)->setWrapper(wrapper, isolate, wrapperTypeInfo);
            return;
        }
        m_wrapperMap.set(object->toScriptWrappableBase(), wrapper, wrapperTypeInfo);
    }

    static bool holderContainsWrapper(v8::Local<v8::Object>, void*)
    {
        return false;
    }

    static bool holderContainsWrapper(v8::Local<v8::Object> holder, ScriptWrappable* wrappable)
    {
        // Verify our assumptions about the main world.
        ASSERT(wrappable);
        ASSERT(!wrappable->containsWrapper() || !wrappable->isEqualTo(holder) || current(v8::Isolate::GetCurrent()).m_isMainWorld);
        return wrappable->isEqualTo(holder);
    }

    bool m_isMainWorld;
    DOMWrapperMap<ScriptWrappableBase> m_wrapperMap;
};

template <>
inline void DOMWrapperMap<ScriptWrappableBase>::PersistentValueMapTraits::Dispose(
    v8::Isolate* isolate,
    v8::UniquePersistent<v8::Object> value,
    ScriptWrappableBase* key)
{
    RELEASE_ASSERT(!value.IsEmpty()); // See crbug.com/368095.
    releaseObject(v8::Local<v8::Object>::New(isolate, value));
}

} // namespace blink

#endif  // SKY_ENGINE_BINDINGS_CORE_V8_DOMDATASTORE_H_
