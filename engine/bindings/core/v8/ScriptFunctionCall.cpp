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
#include "bindings/core/v8/ScriptFunctionCall.h"

#include "bindings/core/v8/ScriptController.h"
#include "bindings/core/v8/ScriptState.h"
#include "bindings/core/v8/ScriptValue.h"
#include "bindings/core/v8/V8Binding.h"
#include "bindings/core/v8/V8ObjectConstructor.h"
#include "bindings/core/v8/V8ScriptRunner.h"

#include <v8.h>

namespace blink {

void ScriptCallArgumentHandler::appendArgument(const ScriptValue& argument)
{
    if (argument.scriptState() != m_scriptState) {
        appendUndefinedArgument();
        return;
    }
    m_arguments.append(argument);
}

void ScriptCallArgumentHandler::appendArgument(const String& argument)
{
    v8::Isolate* isolate = m_scriptState->isolate();
    ScriptState::Scope scope(m_scriptState.get());
    m_arguments.append(ScriptValue(m_scriptState.get(), v8String(isolate, argument)));
}

void ScriptCallArgumentHandler::appendArgument(const char* argument)
{
    v8::Isolate* isolate = m_scriptState->isolate();
    ScriptState::Scope scope(m_scriptState.get());
    m_arguments.append(ScriptValue(m_scriptState.get(), v8String(isolate, argument)));
}

void ScriptCallArgumentHandler::appendArgument(long argument)
{
    v8::Isolate* isolate = m_scriptState->isolate();
    ScriptState::Scope scope(m_scriptState.get());
    m_arguments.append(ScriptValue(m_scriptState.get(), v8::Number::New(isolate, argument)));
}

void ScriptCallArgumentHandler::appendArgument(long long argument)
{
    v8::Isolate* isolate = m_scriptState->isolate();
    ScriptState::Scope scope(m_scriptState.get());
    m_arguments.append(ScriptValue(m_scriptState.get(), v8::Number::New(isolate, argument)));
}

void ScriptCallArgumentHandler::appendArgument(unsigned argument)
{
    v8::Isolate* isolate = m_scriptState->isolate();
    ScriptState::Scope scope(m_scriptState.get());
    m_arguments.append(ScriptValue(m_scriptState.get(), v8::Number::New(isolate, argument)));
}

void ScriptCallArgumentHandler::appendArgument(unsigned long argument)
{
    v8::Isolate* isolate = m_scriptState->isolate();
    ScriptState::Scope scope(m_scriptState.get());
    m_arguments.append(ScriptValue(m_scriptState.get(), v8::Number::New(isolate, argument)));
}

void ScriptCallArgumentHandler::appendArgument(int argument)
{
    v8::Isolate* isolate = m_scriptState->isolate();
    ScriptState::Scope scope(m_scriptState.get());
    m_arguments.append(ScriptValue(m_scriptState.get(), v8::Number::New(isolate, argument)));
}

void ScriptCallArgumentHandler::appendArgument(bool argument)
{
    v8::Isolate* isolate = m_scriptState->isolate();
    m_arguments.append(ScriptValue(m_scriptState.get(), v8Boolean(argument, isolate)));
}

void ScriptCallArgumentHandler::appendArgument(const Vector<ScriptValue>& argument)
{
    v8::Isolate* isolate = m_scriptState->isolate();
    ScriptState::Scope scope(m_scriptState.get());
    v8::Handle<v8::Array> result = v8::Array::New(isolate, argument.size());
    for (size_t i = 0; i < argument.size(); ++i) {
        if (argument[i].scriptState() != m_scriptState)
            result->Set(v8::Integer::New(isolate, i), v8::Undefined(isolate));
        else
            result->Set(v8::Integer::New(isolate, i), argument[i].v8Value());
    }
    m_arguments.append(ScriptValue(m_scriptState.get(), result));
}

void ScriptCallArgumentHandler::appendUndefinedArgument()
{
    v8::Isolate* isolate = m_scriptState->isolate();
    m_arguments.append(ScriptValue(m_scriptState.get(), v8::Undefined(isolate)));
}

ScriptFunctionCall::ScriptFunctionCall(const ScriptValue& thisObject, const String& name)
    : ScriptCallArgumentHandler(thisObject.scriptState())
    , m_thisObject(thisObject)
    , m_name(name)
{
}

ScriptValue ScriptFunctionCall::call(bool& hadException, bool reportExceptions)
{
    ScriptState::Scope scope(m_scriptState.get());
    v8::TryCatch tryCatch;
    tryCatch.SetVerbose(reportExceptions);

    v8::Handle<v8::Object> thisObject = v8::Handle<v8::Object>::Cast(m_thisObject.v8Value());
    v8::Local<v8::Value> value = thisObject->Get(v8String(m_scriptState->isolate(), m_name));
    if (tryCatch.HasCaught()) {
        hadException = true;
        return ScriptValue();
    }

    ASSERT(value->IsFunction());

    v8::Local<v8::Function> function = v8::Local<v8::Function>::Cast(value);
    OwnPtr<v8::Handle<v8::Value>[]> info = adoptArrayPtr(new v8::Handle<v8::Value>[m_arguments.size()]);
    for (size_t i = 0; i < m_arguments.size(); ++i) {
        info[i] = m_arguments[i].v8Value();
        ASSERT(!info[i].IsEmpty());
    }

    v8::Local<v8::Value> result = V8ScriptRunner::callFunction(function, m_scriptState->executionContext(), thisObject, m_arguments.size(), info.get(), m_scriptState->isolate());
    if (tryCatch.HasCaught()) {
        hadException = true;
        return ScriptValue();
    }

    return ScriptValue(m_scriptState.get(), result);
}

ScriptValue ScriptFunctionCall::call()
{
    bool hadException = false;
    return call(hadException);
}

ScriptValue ScriptFunctionCall::construct(bool& hadException, bool reportExceptions)
{
    ScriptState::Scope scope(m_scriptState.get());
    v8::TryCatch tryCatch;
    tryCatch.SetVerbose(reportExceptions);

    v8::Handle<v8::Object> thisObject = v8::Handle<v8::Object>::Cast(m_thisObject.v8Value());
    v8::Local<v8::Value> value = thisObject->Get(v8String(m_scriptState->isolate(), m_name));
    if (tryCatch.HasCaught()) {
        hadException = true;
        return ScriptValue();
    }

    ASSERT(value->IsFunction());

    v8::Local<v8::Function> constructor = v8::Local<v8::Function>::Cast(value);
    OwnPtr<v8::Handle<v8::Value>[]> info = adoptArrayPtr(new v8::Handle<v8::Value>[m_arguments.size()]);
    for (size_t i = 0; i < m_arguments.size(); ++i)
        info[i] = m_arguments[i].v8Value();

    v8::Local<v8::Object> result = V8ObjectConstructor::newInstance(m_scriptState->isolate(), constructor, m_arguments.size(), info.get());
    if (tryCatch.HasCaught()) {
        hadException = true;
        return ScriptValue();
    }

    return ScriptValue(m_scriptState.get(), result);
}

} // namespace blink
