/*
 * Copyright (c) 2010, Google Inc. All rights reserved.
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
#include "core/inspector/JavaScriptCallFrame.h"

#include "bindings/core/v8/ScriptValue.h"
#include "bindings/core/v8/V8Binding.h"
#include <v8-debug.h>

namespace blink {

JavaScriptCallFrame::JavaScriptCallFrame(v8::Handle<v8::Context> debuggerContext, v8::Handle<v8::Object> callFrame)
    : m_isolate(v8::Isolate::GetCurrent())
    , m_debuggerContext(m_isolate, debuggerContext)
    , m_callFrame(m_isolate, callFrame)
{
}

JavaScriptCallFrame::~JavaScriptCallFrame()
{
}

JavaScriptCallFrame* JavaScriptCallFrame::caller()
{
    if (!m_caller) {
        v8::HandleScope handleScope(m_isolate);
        v8::Handle<v8::Context> debuggerContext = m_debuggerContext.newLocal(m_isolate);
        v8::Context::Scope contextScope(debuggerContext);
        v8::Handle<v8::Value> callerFrame = m_callFrame.newLocal(m_isolate)->Get(v8AtomicString(m_isolate, "caller"));
        if (callerFrame.IsEmpty() || !callerFrame->IsObject())
            return 0;
        m_caller = JavaScriptCallFrame::create(debuggerContext, v8::Handle<v8::Object>::Cast(callerFrame));
    }
    return m_caller.get();
}

int JavaScriptCallFrame::callV8FunctionReturnInt(const char* name) const
{
    v8::HandleScope handleScope(m_isolate);
    v8::Context::Scope contextScope(m_debuggerContext.newLocal(m_isolate));
    v8::Handle<v8::Object> callFrame = m_callFrame.newLocal(m_isolate);
    v8::Handle<v8::Function> func = v8::Handle<v8::Function>::Cast(callFrame->Get(v8AtomicString(m_isolate, name)));
    v8::Handle<v8::Value> result = func->Call(callFrame, 0, 0);
    if (result.IsEmpty() || !result->IsInt32())
        return 0;
    return result->Int32Value();
}

String JavaScriptCallFrame::callV8FunctionReturnString(const char* name) const
{
    v8::HandleScope handleScope(m_isolate);
    v8::Context::Scope contextScope(m_debuggerContext.newLocal(m_isolate));
    v8::Handle<v8::Object> callFrame = m_callFrame.newLocal(m_isolate);
    v8::Handle<v8::Function> func = v8::Handle<v8::Function>::Cast(callFrame->Get(v8AtomicString(m_isolate, name)));
    v8::Handle<v8::Value> result = func->Call(callFrame, 0, 0);
    return toCoreStringWithUndefinedOrNullCheck(result);
}

int JavaScriptCallFrame::sourceID() const
{
    return callV8FunctionReturnInt("sourceID");
}

int JavaScriptCallFrame::line() const
{
    return callV8FunctionReturnInt("line");
}

int JavaScriptCallFrame::column() const
{
    return callV8FunctionReturnInt("column");
}

String JavaScriptCallFrame::scriptName() const
{
    return callV8FunctionReturnString("scriptName");
}

String JavaScriptCallFrame::functionName() const
{
    return callV8FunctionReturnString("functionName");
}

v8::Handle<v8::Value> JavaScriptCallFrame::scopeChain() const
{
    v8::Handle<v8::Object> callFrame = m_callFrame.newLocal(m_isolate);
    v8::Handle<v8::Function> func = v8::Handle<v8::Function>::Cast(callFrame->Get(v8AtomicString(m_isolate, "scopeChain")));
    v8::Handle<v8::Array> scopeChain = v8::Handle<v8::Array>::Cast(func->Call(callFrame, 0, 0));
    v8::Handle<v8::Array> result = v8::Array::New(m_isolate, scopeChain->Length());
    for (uint32_t i = 0; i < scopeChain->Length(); i++)
        result->Set(i, scopeChain->Get(i));
    return result;
}

int JavaScriptCallFrame::scopeType(int scopeIndex) const
{
    v8::Handle<v8::Array> scopeType = v8::Handle<v8::Array>::Cast(m_callFrame.newLocal(m_isolate)->Get(v8AtomicString(m_isolate, "scopeType")));
    return scopeType->Get(scopeIndex)->Int32Value();
}

v8::Handle<v8::Value> JavaScriptCallFrame::thisObject() const
{
    return m_callFrame.newLocal(m_isolate)->Get(v8AtomicString(m_isolate, "thisObject"));
}

String JavaScriptCallFrame::stepInPositions() const
{
    return callV8FunctionReturnString("stepInPositions");
}

bool JavaScriptCallFrame::isAtReturn() const
{
    v8::HandleScope handleScope(m_isolate);
    v8::Context::Scope contextScope(m_debuggerContext.newLocal(m_isolate));
    v8::Handle<v8::Value> result = m_callFrame.newLocal(m_isolate)->Get(v8AtomicString(m_isolate, "isAtReturn"));
    if (result.IsEmpty() || !result->IsBoolean())
        return false;
    return result->BooleanValue();
}

v8::Handle<v8::Value> JavaScriptCallFrame::returnValue() const
{
    return m_callFrame.newLocal(m_isolate)->Get(v8AtomicString(m_isolate, "returnValue"));
}

v8::Handle<v8::Value> JavaScriptCallFrame::evaluateWithExceptionDetails(const String& expression)
{
    v8::Handle<v8::Object> callFrame = m_callFrame.newLocal(m_isolate);
    v8::Handle<v8::Function> evalFunction = v8::Handle<v8::Function>::Cast(callFrame->Get(v8AtomicString(m_isolate, "evaluate")));
    v8::Handle<v8::Value> argv[] = { v8String(m_debuggerContext.newLocal(m_isolate)->GetIsolate(), expression) };
    v8::TryCatch tryCatch;
    v8::Handle<v8::Value> result = evalFunction->Call(callFrame, WTF_ARRAY_LENGTH(argv), argv);

    v8::Handle<v8::Object> wrappedResult = v8::Object::New(m_isolate);
    if (tryCatch.HasCaught()) {
        wrappedResult->Set(v8::String::NewFromUtf8(m_isolate, "result"), tryCatch.Exception());
        wrappedResult->Set(v8::String::NewFromUtf8(m_isolate, "exceptionDetails"), createExceptionDetails(tryCatch.Message(), m_isolate));
    } else {
        wrappedResult->Set(v8::String::NewFromUtf8(m_isolate, "result"), result);
        wrappedResult->Set(v8::String::NewFromUtf8(m_isolate, "exceptionDetails"), v8::Undefined(m_isolate));
    }
    return wrappedResult;
}

v8::Handle<v8::Value> JavaScriptCallFrame::restart()
{
    v8::Handle<v8::Object> callFrame = m_callFrame.newLocal(m_isolate);
    v8::Handle<v8::Function> restartFunction = v8::Handle<v8::Function>::Cast(callFrame->Get(v8AtomicString(m_isolate, "restart")));
    v8::Debug::SetLiveEditEnabled(m_isolate, true);
    v8::Handle<v8::Value> result = restartFunction->Call(callFrame, 0, 0);
    v8::Debug::SetLiveEditEnabled(m_isolate, false);
    return result;
}

ScriptValue JavaScriptCallFrame::setVariableValue(ScriptState* scriptState, int scopeNumber, const String& variableName, const ScriptValue& newValue)
{
    ScriptState::Scope scriptScope(scriptState);
    v8::Handle<v8::Object> callFrame = m_callFrame.newLocal(m_isolate);
    v8::Handle<v8::Function> setVariableValueFunction = v8::Handle<v8::Function>::Cast(callFrame->Get(v8AtomicString(m_isolate, "setVariableValue")));
    v8::Handle<v8::Value> argv[] = {
        v8::Handle<v8::Value>(v8::Integer::New(m_isolate, scopeNumber)),
        v8String(m_isolate, variableName),
        newValue.v8Value()
    };
    return ScriptValue(scriptState, setVariableValueFunction->Call(callFrame, WTF_ARRAY_LENGTH(argv), argv));
}

v8::Handle<v8::Object> JavaScriptCallFrame::createExceptionDetails(v8::Handle<v8::Message> message, v8::Isolate* isolate)
{
    v8::Handle<v8::Object> exceptionDetails = v8::Object::New(isolate);
    exceptionDetails->Set(v8::String::NewFromUtf8(isolate, "text"), message->Get());
    exceptionDetails->Set(v8::String::NewFromUtf8(isolate, "url"), message->GetScriptOrigin().ResourceName());
    exceptionDetails->Set(v8::String::NewFromUtf8(isolate, "line"), v8::Integer::New(isolate, message->GetLineNumber()));
    exceptionDetails->Set(v8::String::NewFromUtf8(isolate, "column"), v8::Integer::New(isolate, message->GetStartColumn()));
    if (!message->GetStackTrace().IsEmpty())
        exceptionDetails->Set(v8::String::NewFromUtf8(isolate, "stackTrace"), message->GetStackTrace()->AsArray());
    else
        exceptionDetails->Set(v8::String::NewFromUtf8(isolate, "stackTrace"), v8::Undefined(isolate));
    return exceptionDetails;
}

} // namespace blink