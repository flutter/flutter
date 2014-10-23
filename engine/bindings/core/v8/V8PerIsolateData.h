/*
 * Copyright (C) 2009 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef V8PerIsolateData_h
#define V8PerIsolateData_h

#include "bindings/core/v8/ScopedPersistent.h"
#include "bindings/core/v8/ScriptState.h"
#include "bindings/core/v8/V8HiddenValue.h"
#include "bindings/core/v8/WrapperTypeInfo.h"
#include "gin/public/gin_embedders.h"
#include "gin/public/isolate_holder.h"
#include "wtf/Forward.h"
#include "wtf/HashMap.h"
#include "wtf/OwnPtr.h"
#include "wtf/Vector.h"
#include <v8.h>

namespace blink {

class DOMDataStore;
class GCEventData;
class StringCache;
struct WrapperTypeInfo;

class ExternalStringVisitor;

typedef WTF::Vector<DOMDataStore*> DOMDataStoreList;

class V8PerIsolateData {
public:
    static v8::Isolate* initialize();
    static V8PerIsolateData* from(v8::Isolate* isolate)
    {
        ASSERT(isolate);
        ASSERT(isolate->GetData(gin::kEmbedderBlink));
        return static_cast<V8PerIsolateData*>(isolate->GetData(gin::kEmbedderBlink));
    }
    static void dispose(v8::Isolate*);
    static v8::Isolate* mainThreadIsolate();

    v8::Isolate* isolate() { return m_isolateHolder->isolate(); }

    v8::Handle<v8::FunctionTemplate> toStringTemplate();

    StringCache* stringCache() { return m_stringCache.get(); }

    v8::Persistent<v8::Value>& ensureLiveRoot();

    int recursionLevel() const { return m_recursionLevel; }
    int incrementRecursionLevel() { return ++m_recursionLevel; }
    int decrementRecursionLevel() { return --m_recursionLevel; }
    bool isHandlingRecursionLevelError() const { return m_isHandlingRecursionLevelError; }
    void setIsHandlingRecursionLevelError(bool value) { m_isHandlingRecursionLevelError = value; }

    bool performingMicrotaskCheckpoint() const { return m_performingMicrotaskCheckpoint; }
    void setPerformingMicrotaskCheckpoint(bool performingMicrotaskCheckpoint) { m_performingMicrotaskCheckpoint = performingMicrotaskCheckpoint; }

#if ENABLE(ASSERT)
    int internalScriptRecursionLevel() const { return m_internalScriptRecursionLevel; }
    int incrementInternalScriptRecursionLevel() { return ++m_internalScriptRecursionLevel; }
    int decrementInternalScriptRecursionLevel() { return --m_internalScriptRecursionLevel; }
#endif

    GCEventData* gcEventData() { return m_gcEventData.get(); }
    V8HiddenValue* hiddenValue() { return m_hiddenValue.get(); }

    v8::Handle<v8::FunctionTemplate> domTemplate(void* domTemplateKey, v8::FunctionCallback = 0, v8::Handle<v8::Value> data = v8::Handle<v8::Value>(), v8::Handle<v8::Signature> = v8::Handle<v8::Signature>(), int length = 0);
    v8::Handle<v8::FunctionTemplate> existingDOMTemplate(void* domTemplateKey);
    void setDOMTemplate(void* domTemplateKey, v8::Handle<v8::FunctionTemplate>);

    bool hasInstance(const WrapperTypeInfo*, v8::Handle<v8::Value>);
    v8::Handle<v8::Object> findInstanceInPrototypeChain(const WrapperTypeInfo*, v8::Handle<v8::Value>);

    v8::Local<v8::Context> ensureScriptRegexpContext();

    const char* previousSamplingState() const { return m_previousSamplingState; }
    void setPreviousSamplingState(const char* name) { m_previousSamplingState = name; }

private:
    V8PerIsolateData();
    ~V8PerIsolateData();

    typedef HashMap<const void*, v8::Eternal<v8::FunctionTemplate> > DOMTemplateMap;
    DOMTemplateMap& currentDOMTemplateMap();
    bool hasInstance(const WrapperTypeInfo*, v8::Handle<v8::Value>, DOMTemplateMap&);
    v8::Handle<v8::Object> findInstanceInPrototypeChain(const WrapperTypeInfo*, v8::Handle<v8::Value>, DOMTemplateMap&);

    OwnPtr<gin::IsolateHolder> m_isolateHolder;
    DOMTemplateMap m_domTemplateMapForMainWorld;
    DOMTemplateMap m_domTemplateMapForNonMainWorld;
    ScopedPersistent<v8::FunctionTemplate> m_toStringTemplate;
    OwnPtr<StringCache> m_stringCache;
    OwnPtr<V8HiddenValue> m_hiddenValue;
    ScopedPersistent<v8::Value> m_liveRoot;
    RefPtr<ScriptState> m_scriptRegexpScriptState;

    const char* m_previousSamplingState;

    bool m_constructorMode;
    friend class ConstructorMode;

    int m_recursionLevel;
    bool m_isHandlingRecursionLevelError;

#if ENABLE(ASSERT)
    int m_internalScriptRecursionLevel;
#endif
    OwnPtr<GCEventData> m_gcEventData;
    bool m_performingMicrotaskCheckpoint;
};

} // namespace blink

#endif // V8PerIsolateData_h
