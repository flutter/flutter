// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "bindings/core/v8/ScriptWrappable.h"

#include "bindings/core/v8/DOMDataStore.h"
#include "bindings/core/v8/V8DOMWrapper.h"

namespace blink {

struct SameSizeAsScriptWrappableBase { };

COMPILE_ASSERT(sizeof(ScriptWrappableBase) <= sizeof(SameSizeAsScriptWrappableBase), ScriptWrappableBase_should_stay_small);

struct SameSizeAsScriptWrappable : public ScriptWrappableBase {
    virtual ~SameSizeAsScriptWrappable() { }
    uintptr_t m_wrapperOrTypeInfo;
};

COMPILE_ASSERT(sizeof(ScriptWrappable) <= sizeof(SameSizeAsScriptWrappable), ScriptWrappable_should_stay_small);

namespace {

class ScriptWrappableBaseProtector {
    WTF_MAKE_NONCOPYABLE(ScriptWrappableBaseProtector);
public:
    ScriptWrappableBaseProtector(ScriptWrappableBase* scriptWrappableBase, const WrapperTypeInfo* wrapperTypeInfo)
        : m_scriptWrappableBase(scriptWrappableBase), m_wrapperTypeInfo(wrapperTypeInfo)
    {
        m_wrapperTypeInfo->refObject(m_scriptWrappableBase);
    }
    ~ScriptWrappableBaseProtector()
    {
        m_wrapperTypeInfo->derefObject(m_scriptWrappableBase);
    }

private:
    ScriptWrappableBase* m_scriptWrappableBase;
    const WrapperTypeInfo* m_wrapperTypeInfo;
};

} // namespace

v8::Handle<v8::Object> ScriptWrappable::wrap(v8::Handle<v8::Object> creationContext, v8::Isolate* isolate)
{
    const WrapperTypeInfo* wrapperTypeInfo = this->wrapperTypeInfo();

    // It's possible that no one except for the new wrapper owns this object at
    // this moment, so we have to prevent GC to collect this object until the
    // object gets associated with the wrapper.
    ScriptWrappableBaseProtector protect(this, wrapperTypeInfo);

    ASSERT(!DOMDataStore::containsWrapperNonTemplate(this, isolate));

    v8::Handle<v8::Object> wrapper = V8DOMWrapper::createWrapper(creationContext, wrapperTypeInfo, toScriptWrappableBase(), isolate);
    if (UNLIKELY(wrapper.IsEmpty()))
        return wrapper;

    wrapperTypeInfo->installConditionallyEnabledProperties(wrapper, isolate);
    return associateWithWrapper(wrapperTypeInfo, wrapper, isolate);
}

v8::Handle<v8::Object> ScriptWrappable::associateWithWrapper(const WrapperTypeInfo* wrapperTypeInfo, v8::Handle<v8::Object> wrapper, v8::Isolate* isolate)
{
    return V8DOMWrapper::associateObjectWithWrapperNonTemplate(this, wrapperTypeInfo, wrapper, isolate);
}

} // namespace blink
