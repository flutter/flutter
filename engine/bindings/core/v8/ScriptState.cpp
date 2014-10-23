// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "bindings/core/v8/ScriptState.h"

#include "bindings/core/v8/V8Binding.h"
#include "core/dom/ExecutionContext.h"
#include "core/frame/LocalFrame.h"

namespace blink {

PassRefPtr<ScriptState> ScriptState::create(v8::Handle<v8::Context> context, PassRefPtr<DOMWrapperWorld> world)
{
    RefPtr<ScriptState> scriptState = adoptRef(new ScriptState(context, world));
    // This ref() is for keeping this ScriptState alive as long as the v8::Context is alive.
    // This is deref()ed in the weak callback of the v8::Context.
    scriptState->ref();
    return scriptState;
}

static void weakCallback(const v8::WeakCallbackData<v8::Context, ScriptState>& data)
{
    data.GetValue()->SetAlignedPointerInEmbedderData(v8ContextPerContextDataIndex, 0);
    data.GetParameter()->clearContext();
    data.GetParameter()->deref();
}

ScriptState::ScriptState(v8::Handle<v8::Context> context, PassRefPtr<DOMWrapperWorld> world)
    : m_isolate(context->GetIsolate())
    , m_context(m_isolate, context)
    , m_world(world)
    , m_perContextData(V8PerContextData::create(context))
{
    ASSERT(m_world);
    m_context.setWeak(this, &weakCallback);
    context->SetAlignedPointerInEmbedderData(v8ContextPerContextDataIndex, this);
}

ScriptState::~ScriptState()
{
    ASSERT(!m_perContextData);
    ASSERT(m_context.isEmpty());
}

bool ScriptState::evalEnabled() const
{
    v8::HandleScope handleScope(m_isolate);
    return context()->IsCodeGenerationFromStringsAllowed();
}

void ScriptState::setEvalEnabled(bool enabled)
{
    v8::HandleScope handleScope(m_isolate);
    return context()->AllowCodeGenerationFromStrings(enabled);
}

ScriptValue ScriptState::getFromGlobalObject(const char* name)
{
    v8::HandleScope handleScope(m_isolate);
    v8::Local<v8::Value> v8Value = context()->Global()->Get(v8AtomicString(isolate(), name));
    return ScriptValue(this, v8Value);
}

ExecutionContext* ScriptState::executionContext() const
{
    v8::HandleScope scope(m_isolate);
    return toExecutionContext(context());
}

void ScriptState::setExecutionContext(ExecutionContext*)
{
    ASSERT_NOT_REACHED();
}

LocalDOMWindow* ScriptState::domWindow() const
{
    v8::HandleScope scope(m_isolate);
    return toDOMWindow(context());
}

ScriptState* ScriptState::forMainWorld(LocalFrame* frame)
{
    v8::Isolate* isolate = toIsolate(frame);
    v8::HandleScope handleScope(isolate);
    return ScriptState::from(toV8Context(frame, DOMWrapperWorld::mainWorld()));
}

PassRefPtr<ScriptStateForTesting> ScriptStateForTesting::create(v8::Handle<v8::Context> context, PassRefPtr<DOMWrapperWorld> world)
{
    RefPtr<ScriptStateForTesting> scriptState = adoptRef(new ScriptStateForTesting(context, world));
    // This ref() is for keeping this ScriptState alive as long as the v8::Context is alive.
    // This is deref()ed in the weak callback of the v8::Context.
    scriptState->ref();
    return scriptState;
}

ScriptStateForTesting::ScriptStateForTesting(v8::Handle<v8::Context> context, PassRefPtr<DOMWrapperWorld> world)
    : ScriptState(context, world)
{
}

ExecutionContext* ScriptStateForTesting::executionContext() const
{
    return m_executionContext;
}

void ScriptStateForTesting::setExecutionContext(ExecutionContext* executionContext)
{
    m_executionContext = executionContext;
}

}
