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

#ifndef SKY_ENGINE_BINDINGS_CORE_V8_V8PERCONTEXTDATA_H_
#define SKY_ENGINE_BINDINGS_CORE_V8_V8PERCONTEXTDATA_H_

#include "gin/public/context_holder.h"
#include "gin/public/gin_embedders.h"
#include "sky/engine/bindings/core/v8/CustomElementBinding.h"
#include "sky/engine/bindings/core/v8/ScopedPersistent.h"
#include "sky/engine/bindings/core/v8/V8PersistentValueMap.h"
#include "sky/engine/bindings/core/v8/WrapperTypeInfo.h"
#include "sky/engine/wtf/HashMap.h"
#include "sky/engine/wtf/PassOwnPtr.h"
#include "sky/engine/wtf/Vector.h"
#include "sky/engine/wtf/text/AtomicString.h"
#include "sky/engine/wtf/text/AtomicStringHash.h"
#include "v8/include/v8.h"

namespace blink {

class CustomElementDefinition;
class V8PerContextData;

enum V8ContextEmbedderDataField {
    v8ContextDebugIdIndex = static_cast<int>(gin::kDebugIdIndex),
    v8ContextPerContextDataIndex = static_cast<int>(gin::kPerContextDataStartIndex + gin::kEmbedderBlink),
};

class V8PerContextData {
public:
    static PassOwnPtr<V8PerContextData> create(v8::Handle<v8::Context>);

    static V8PerContextData* from(v8::Handle<v8::Context>);

    ~V8PerContextData();

    v8::Handle<v8::Context> context() { return m_context.newLocal(m_isolate); }

    // To create JS Wrapper objects, we create a cache of a 'boiler plate'
    // object, and then simply Clone that object each time we need a new one.
    // This is faster than going through the full object creation process.
    v8::Local<v8::Object> createWrapperFromCache(const WrapperTypeInfo* type)
    {
        v8::Local<v8::Object> boilerplate = m_wrapperBoilerplates.Get(type);
        return !boilerplate.IsEmpty() ? boilerplate->Clone() : createWrapperFromCacheSlowCase(type);
    }

    v8::Local<v8::Function> constructorForType(const WrapperTypeInfo* type)
    {
        v8::Local<v8::Function> function = m_constructorMap.Get(type);
        return (!function.IsEmpty()) ? function : constructorForTypeSlowCase(type);
    }

    v8::Local<v8::Object> prototypeForType(const WrapperTypeInfo*);

    void addCustomElementBinding(CustomElementDefinition*, PassOwnPtr<CustomElementBinding>);
    void clearCustomElementBinding(CustomElementDefinition*);
    CustomElementBinding* customElementBinding(CustomElementDefinition*);

private:
    V8PerContextData(v8::Handle<v8::Context>);

    v8::Local<v8::Object> createWrapperFromCacheSlowCase(const WrapperTypeInfo*);
    v8::Local<v8::Function> constructorForTypeSlowCase(const WrapperTypeInfo*);

    v8::Isolate* m_isolate;

    // For each possible type of wrapper, we keep a boilerplate object.
    // The boilerplate is used to create additional wrappers of the same type.
    typedef V8PersistentValueMap<const WrapperTypeInfo*, v8::Object, false> WrapperBoilerplateMap;
    WrapperBoilerplateMap m_wrapperBoilerplates;

    typedef V8PersistentValueMap<const WrapperTypeInfo*, v8::Function, false> ConstructorMap;
    ConstructorMap m_constructorMap;

    OwnPtr<gin::ContextHolder> m_contextHolder;

    ScopedPersistent<v8::Context> m_context;
    ScopedPersistent<v8::Value> m_errorPrototype;

    typedef WTF::HashMap<CustomElementDefinition*, OwnPtr<CustomElementBinding> > CustomElementBindingMap;
    OwnPtr<CustomElementBindingMap> m_customElementBindings;
};

class V8PerContextDebugData {
public:
    static bool setContextDebugData(v8::Handle<v8::Context>, const char* worldName, int debugId);
    static int contextDebugId(v8::Handle<v8::Context>);
};

} // namespace blink

#endif  // SKY_ENGINE_BINDINGS_CORE_V8_V8PERCONTEXTDATA_H_
