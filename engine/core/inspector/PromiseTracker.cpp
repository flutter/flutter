// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/inspector/PromiseTracker.h"

#include "bindings/core/v8/ScopedPersistent.h"
#include "bindings/core/v8/ScriptCallStackFactory.h"
#include "bindings/core/v8/ScriptState.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/WeakPtr.h"

namespace blink {

class PromiseTracker::PromiseData : public RefCounted<PromiseData> {
public:
    PromiseData(v8::Isolate* isolate, int promiseHash, v8::Handle<v8::Object> promise)
        : m_promiseHash(promiseHash)
        , m_promise(isolate, promise)
        , m_status(0)
        , m_weakPtrFactory(this)
        {
    }

    int promiseHash() const { return m_promiseHash; }
    ScopedPersistent<v8::Object>& promise() { return m_promise; }

private:
    friend class PromiseTracker;

    int m_promiseHash;

    ScopedPersistent<v8::Object> m_promise;
    ScriptCallFrame m_callFrame;
    ScopedPersistent<v8::Object> m_parentPromise;
    int m_status;

    WeakPtrFactory<PromiseData> m_weakPtrFactory;
};

static int indexOf(PromiseTracker::PromiseDataVector* vector, const ScopedPersistent<v8::Object>& promise)
{
    for (size_t index = 0; index < vector->size(); ++index) {
        if (vector->at(index)->promise() == promise)
            return index;
    }
    return -1;
}

namespace {

class PromiseDataWrapper {
public:
    PromiseDataWrapper(WeakPtr<PromiseTracker::PromiseData> data, PromiseTracker::PromiseDataMap* map)
        : m_data(data)
        , m_promiseDataMap(map)
    {
    }

    static void didRemovePromise(const v8::WeakCallbackData<v8::Object, PromiseDataWrapper>& data)
    {
        OwnPtr<PromiseDataWrapper> wrapper = adoptPtr(data.GetParameter());
        WeakPtr<PromiseTracker::PromiseData> promiseData = wrapper->m_data;
        if (!promiseData)
            return;
        PromiseTracker::PromiseDataMap* map = wrapper->m_promiseDataMap;
        int promiseHash = promiseData->promiseHash();
        PromiseTracker::PromiseDataVector* vector = &map->find(promiseHash)->value;
        int index = indexOf(vector, promiseData->promise());
        ASSERT(index >= 0);
        vector->remove(index);
        if (vector->size() == 0)
            map->remove(promiseHash);
    }

private:
    WeakPtr<PromiseTracker::PromiseData> m_data;
    PromiseTracker::PromiseDataMap* m_promiseDataMap;
};

}

PromiseTracker::PromiseTracker()
    : m_isEnabled(false)
{
}

PromiseTracker::~PromiseTracker()
{
}

void PromiseTracker::enable()
{
    m_isEnabled = true;
}

void PromiseTracker::disable()
{
    m_isEnabled = false;
    clear();
}

void PromiseTracker::clear()
{
    m_promiseDataMap.clear();
}

void PromiseTracker::didReceiveV8PromiseEvent(ScriptState* scriptState, v8::Handle<v8::Object> promise, v8::Handle<v8::Value> parentPromise, int status)
{
    ASSERT(isEnabled());

    int promiseHash = promise->GetIdentityHash();
    PromiseDataVector* vector;
    PromiseDataMap::iterator it = m_promiseDataMap.find(promiseHash);
    if (it != m_promiseDataMap.end())
        vector = &it->value;
    else
        vector = &m_promiseDataMap.add(promiseHash, PromiseDataVector()).storedValue->value;

    v8::Isolate* isolate = scriptState->isolate();
    RefPtr<PromiseData> data;
    int index = indexOf(vector, ScopedPersistent<v8::Object>(isolate, promise));
    if (index == -1) {
        data = adoptRef(new PromiseData(isolate, promiseHash, promise));
        OwnPtr<PromiseDataWrapper> wrapper = adoptPtr(new PromiseDataWrapper(data->m_weakPtrFactory.createWeakPtr(), &m_promiseDataMap));
        data->m_promise.setWeak(wrapper.leakPtr(), &PromiseDataWrapper::didRemovePromise);
        vector->append(data);
    } else {
        data = vector->at(index);
    }

    if (!parentPromise.IsEmpty()) {
        ASSERT(parentPromise->IsObject());
        data->m_parentPromise.set(isolate, parentPromise->ToObject());
    } else {
        data->m_status = status;
        if (!status) {
            v8::Handle<v8::StackTrace> stackTrace(v8::StackTrace::CurrentStackTrace(isolate, 1));
            RefPtr<ScriptCallStack> stack = createScriptCallStack(stackTrace, 1, isolate);
            if (stack->size())
                data->m_callFrame = stack->at(0);
        }
    }
}

} // namespace blink
