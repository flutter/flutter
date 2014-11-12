/*
 * Copyright (c) 2010-2011 Google Inc. All rights reserved.
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
#include "bindings/core/v8/ScriptDebugServer.h"

#include "bindings/core/v8/ScopedPersistent.h"
#include "bindings/core/v8/ScriptCallStackFactory.h"
#include "bindings/core/v8/ScriptController.h"
#include "bindings/core/v8/ScriptSourceCode.h"
#include "bindings/core/v8/ScriptValue.h"
#include "bindings/core/v8/V8Binding.h"
#include "bindings/core/v8/V8JavaScriptCallFrame.h"
#include "bindings/core/v8/V8ScriptRunner.h"
#include "core/inspector/JavaScriptCallFrame.h"
#include "core/inspector/ScriptDebugListener.h"
#include "platform/JSONValues.h"
#include "public/platform/Platform.h"
#include "public/platform/WebData.h"
#include "wtf/StdLibExtras.h"
#include "wtf/Vector.h"
#include "wtf/dtoa/utils.h"
#include "wtf/text/CString.h"

namespace blink {

namespace {

class ClientDataImpl : public v8::Debug::ClientData {
public:
    ClientDataImpl(PassOwnPtr<ScriptDebugServer::Task> task) : m_task(task) { }
    virtual ~ClientDataImpl() { }
    ScriptDebugServer::Task* task() const { return m_task.get(); }
private:
    OwnPtr<ScriptDebugServer::Task> m_task;
};

const char stepIntoV8MethodName[] = "stepIntoStatement";
const char stepOutV8MethodName[] = "stepOutOfFunction";
}

v8::Local<v8::Value> ScriptDebugServer::callDebuggerMethod(const char* functionName, int argc, v8::Handle<v8::Value> argv[])
{
    v8::Handle<v8::Object> debuggerScript = m_debuggerScript.newLocal(m_isolate);
    v8::Handle<v8::Function> function = v8::Local<v8::Function>::Cast(debuggerScript->Get(v8AtomicString(m_isolate, functionName)));
    ASSERT(m_isolate->InContext());
    return V8ScriptRunner::callInternalFunction(function, debuggerScript, argc, argv, m_isolate);
}

ScriptDebugServer::ScriptDebugServer(v8::Isolate* isolate)
    : m_pauseOnExceptionsState(DontPauseOnExceptions)
    , m_breakpointsActivated(true)
    , m_isolate(isolate)
    , m_runningNestedMessageLoop(false)
{
}

ScriptDebugServer::~ScriptDebugServer()
{
}

String ScriptDebugServer::setBreakpoint(const String& sourceID, const ScriptBreakpoint& scriptBreakpoint, int* actualLineNumber, int* actualColumnNumber, bool interstatementLocation)
{
    v8::HandleScope scope(m_isolate);
    v8::Local<v8::Context> debuggerContext = v8::Debug::GetDebugContext();
    v8::Context::Scope contextScope(debuggerContext);

    v8::Local<v8::Object> info = v8::Object::New(m_isolate);
    info->Set(v8AtomicString(m_isolate, "sourceID"), v8String(debuggerContext->GetIsolate(), sourceID));
    info->Set(v8AtomicString(m_isolate, "lineNumber"), v8::Integer::New(debuggerContext->GetIsolate(), scriptBreakpoint.lineNumber));
    info->Set(v8AtomicString(m_isolate, "columnNumber"), v8::Integer::New(debuggerContext->GetIsolate(), scriptBreakpoint.columnNumber));
    info->Set(v8AtomicString(m_isolate, "interstatementLocation"), v8Boolean(interstatementLocation, debuggerContext->GetIsolate()));
    info->Set(v8AtomicString(m_isolate, "condition"), v8String(debuggerContext->GetIsolate(), scriptBreakpoint.condition));

    v8::Handle<v8::Function> setBreakpointFunction = v8::Local<v8::Function>::Cast(m_debuggerScript.newLocal(m_isolate)->Get(v8AtomicString(m_isolate, "setBreakpoint")));
    v8::Handle<v8::Value> breakpointId = v8::Debug::Call(setBreakpointFunction, info);
    if (breakpointId.IsEmpty() || !breakpointId->IsString())
        return "";
    *actualLineNumber = info->Get(v8AtomicString(m_isolate, "lineNumber"))->Int32Value();
    *actualColumnNumber = info->Get(v8AtomicString(m_isolate, "columnNumber"))->Int32Value();
    return toCoreString(breakpointId.As<v8::String>());
}

void ScriptDebugServer::removeBreakpoint(const String& breakpointId)
{
    v8::HandleScope scope(m_isolate);
    v8::Local<v8::Context> debuggerContext = v8::Debug::GetDebugContext();
    v8::Context::Scope contextScope(debuggerContext);

    v8::Local<v8::Object> info = v8::Object::New(m_isolate);
    info->Set(v8AtomicString(m_isolate, "breakpointId"), v8String(debuggerContext->GetIsolate(), breakpointId));

    v8::Handle<v8::Function> removeBreakpointFunction = v8::Local<v8::Function>::Cast(m_debuggerScript.newLocal(m_isolate)->Get(v8AtomicString(m_isolate, "removeBreakpoint")));
    v8::Debug::Call(removeBreakpointFunction, info);
}

void ScriptDebugServer::clearBreakpoints()
{
    ensureDebuggerScriptCompiled();
    v8::HandleScope scope(m_isolate);
    v8::Local<v8::Context> debuggerContext = v8::Debug::GetDebugContext();
    v8::Context::Scope contextScope(debuggerContext);

    v8::Handle<v8::Function> clearBreakpoints = v8::Local<v8::Function>::Cast(m_debuggerScript.newLocal(m_isolate)->Get(v8AtomicString(m_isolate, "clearBreakpoints")));
    v8::Debug::Call(clearBreakpoints);
}

void ScriptDebugServer::setBreakpointsActivated(bool activated)
{
    ensureDebuggerScriptCompiled();
    v8::HandleScope scope(m_isolate);
    v8::Local<v8::Context> debuggerContext = v8::Debug::GetDebugContext();
    v8::Context::Scope contextScope(debuggerContext);

    v8::Local<v8::Object> info = v8::Object::New(m_isolate);
    info->Set(v8AtomicString(m_isolate, "enabled"), v8::Boolean::New(m_isolate, activated));
    v8::Handle<v8::Function> setBreakpointsActivated = v8::Local<v8::Function>::Cast(m_debuggerScript.newLocal(m_isolate)->Get(v8AtomicString(m_isolate, "setBreakpointsActivated")));
    v8::Debug::Call(setBreakpointsActivated, info);

    m_breakpointsActivated = activated;
}

ScriptDebugServer::PauseOnExceptionsState ScriptDebugServer::pauseOnExceptionsState()
{
    ensureDebuggerScriptCompiled();
    v8::HandleScope scope(m_isolate);
    v8::Context::Scope contextScope(v8::Debug::GetDebugContext());

    v8::Handle<v8::Value> argv[] = { v8Undefined() };
    v8::Handle<v8::Value> result = callDebuggerMethod("pauseOnExceptionsState", 0, argv);
    return static_cast<ScriptDebugServer::PauseOnExceptionsState>(result->Int32Value());
}

void ScriptDebugServer::setPauseOnExceptionsState(PauseOnExceptionsState pauseOnExceptionsState)
{
    ensureDebuggerScriptCompiled();
    v8::HandleScope scope(m_isolate);
    v8::Context::Scope contextScope(v8::Debug::GetDebugContext());

    v8::Handle<v8::Value> argv[] = { v8::Int32::New(m_isolate, pauseOnExceptionsState) };
    callDebuggerMethod("setPauseOnExceptionsState", 1, argv);
}

void ScriptDebugServer::setPauseOnNextStatement(bool pause)
{
    ASSERT(!isPaused());
    if (pause)
        v8::Debug::DebugBreak(m_isolate);
    else
        v8::Debug::CancelDebugBreak(m_isolate);
}

bool ScriptDebugServer::pausingOnNextStatement()
{
    return v8::Debug::CheckDebugBreak(m_isolate);
}

bool ScriptDebugServer::canBreakProgram()
{
    if (!m_breakpointsActivated)
        return false;
    return m_isolate->InContext();
}

void ScriptDebugServer::breakProgram()
{
    if (!canBreakProgram())
        return;

    v8::HandleScope scope(m_isolate);
    if (m_breakProgramCallbackTemplate.isEmpty()) {
        v8::Handle<v8::FunctionTemplate> templ = v8::FunctionTemplate::New(m_isolate);
        templ->SetCallHandler(&ScriptDebugServer::breakProgramCallback, v8::External::New(m_isolate, this));
        m_breakProgramCallbackTemplate.set(m_isolate, templ);
    }

    v8::Handle<v8::Function> breakProgramFunction = m_breakProgramCallbackTemplate.newLocal(m_isolate)->GetFunction();
    v8::Debug::Call(breakProgramFunction);
}

void ScriptDebugServer::continueProgram()
{
    if (isPaused())
        quitMessageLoopOnPause();
    m_pausedScriptState.clear();
    m_executionState.Clear();
}

void ScriptDebugServer::stepIntoStatement()
{
    ASSERT(isPaused());
    ASSERT(!m_executionState.IsEmpty());
    v8::HandleScope handleScope(m_isolate);
    v8::Handle<v8::Value> argv[] = { m_executionState };
    callDebuggerMethod(stepIntoV8MethodName, 1, argv);
    continueProgram();
}

void ScriptDebugServer::stepOverStatement()
{
    ASSERT(isPaused());
    ASSERT(!m_executionState.IsEmpty());
    v8::HandleScope handleScope(m_isolate);
    v8::Handle<v8::Value> argv[] = { m_executionState };
    callDebuggerMethod("stepOverStatement", 1, argv);
    continueProgram();
}

void ScriptDebugServer::stepOutOfFunction()
{
    ASSERT(isPaused());
    ASSERT(!m_executionState.IsEmpty());
    v8::HandleScope handleScope(m_isolate);
    v8::Handle<v8::Value> argv[] = { m_executionState };
    callDebuggerMethod(stepOutV8MethodName, 1, argv);
    continueProgram();
}

bool ScriptDebugServer::setScriptSource(const String& sourceID, const String& newContent, bool preview, String* error, RefPtr<TypeBuilder::Debugger::SetScriptSourceError>& errorData, ScriptValue* newCallFrames, RefPtr<JSONObject>* result)
{
    class EnableLiveEditScope {
    public:
        explicit EnableLiveEditScope(v8::Isolate* isolate) : m_isolate(isolate) { v8::Debug::SetLiveEditEnabled(m_isolate, true); }
        ~EnableLiveEditScope() { v8::Debug::SetLiveEditEnabled(m_isolate, false); }
    private:
        v8::Isolate* m_isolate;
    };

    ensureDebuggerScriptCompiled();
    v8::HandleScope scope(m_isolate);

    OwnPtr<v8::Context::Scope> contextScope;
    v8::Handle<v8::Context> debuggerContext = v8::Debug::GetDebugContext();
    if (!isPaused())
        contextScope = adoptPtr(new v8::Context::Scope(debuggerContext));

    v8::Handle<v8::Value> argv[] = { v8String(m_isolate, sourceID), v8String(m_isolate, newContent), v8Boolean(preview, m_isolate) };

    v8::Local<v8::Value> v8result;
    {
        EnableLiveEditScope enableLiveEditScope(m_isolate);
        v8::TryCatch tryCatch;
        tryCatch.SetVerbose(false);
        v8result = callDebuggerMethod("liveEditScriptSource", 3, argv);
        if (tryCatch.HasCaught()) {
            v8::Local<v8::Message> message = tryCatch.Message();
            if (!message.IsEmpty())
                *error = toCoreStringWithUndefinedOrNullCheck(message->Get());
            else
                *error = "Unknown error.";
            return false;
        }
    }
    ASSERT(!v8result.IsEmpty());
    v8::Local<v8::Object> resultTuple = v8result->ToObject();
    int code = static_cast<int>(resultTuple->Get(0)->ToInteger()->Value());
    switch (code) {
    case 0:
        {
            v8::Local<v8::Value> normalResult = resultTuple->Get(1);
            RefPtr<JSONValue> jsonResult = v8ToJSONValue(m_isolate, normalResult, JSONValue::maxDepth);
            if (jsonResult)
                *result = jsonResult->asObject();
            // Call stack may have changed after if the edited function was on the stack.
            if (!preview && isPaused())
                *newCallFrames = currentCallFrames();
            return true;
        }
    // Compile error.
    case 1:
        {
            RefPtr<TypeBuilder::Debugger::SetScriptSourceError::CompileError> compileError =
                TypeBuilder::Debugger::SetScriptSourceError::CompileError::create()
                    .setMessage(toCoreStringWithUndefinedOrNullCheck(resultTuple->Get(2)))
                    .setLineNumber(resultTuple->Get(3)->ToInteger()->Value())
                    .setColumnNumber(resultTuple->Get(4)->ToInteger()->Value());

            *error = toCoreStringWithUndefinedOrNullCheck(resultTuple->Get(1));
            errorData = TypeBuilder::Debugger::SetScriptSourceError::create();
            errorData->setCompileError(compileError);
            return false;
        }
    }
    *error = "Unknown error.";
    return false;
}

int ScriptDebugServer::frameCount()
{
    ASSERT(isPaused());
    ASSERT(!m_executionState.IsEmpty());
    v8::Handle<v8::Value> argv[] = { m_executionState };
    v8::Handle<v8::Value> result = callDebuggerMethod("frameCount", WTF_ARRAY_LENGTH(argv), argv);
    if (result->IsInt32())
        return result->Int32Value();
    return 0;
}

PassRefPtr<JavaScriptCallFrame> ScriptDebugServer::toJavaScriptCallFrameUnsafe(const ScriptValue& value)
{
    if (value.isEmpty())
        return nullptr;
    ASSERT(value.isObject());
    return V8JavaScriptCallFrame::toNative(v8::Handle<v8::Object>::Cast(value.v8ValueUnsafe()));
}

PassRefPtr<JavaScriptCallFrame> ScriptDebugServer::wrapCallFrames(int maximumLimit, ScopeInfoDetails scopeDetails)
{
    const int scopeBits = 2;
    COMPILE_ASSERT(NoScopes < (1 << scopeBits), not_enough_bits_to_encode_ScopeInfoDetails);

    ASSERT(maximumLimit >= 0);
    int data = (maximumLimit << scopeBits) | scopeDetails;
    v8::Handle<v8::Value> currentCallFrameV8;
    if (m_executionState.IsEmpty()) {
        v8::Handle<v8::Function> currentCallFrameFunction = v8::Local<v8::Function>::Cast(m_debuggerScript.newLocal(m_isolate)->Get(v8AtomicString(m_isolate, "currentCallFrame")));
        currentCallFrameV8 = v8::Debug::Call(currentCallFrameFunction, v8::Integer::New(m_isolate, data));
    } else {
        v8::Handle<v8::Value> argv[] = { m_executionState, v8::Integer::New(m_isolate, data) };
        currentCallFrameV8 = callDebuggerMethod("currentCallFrame", WTF_ARRAY_LENGTH(argv), argv);
    }
    ASSERT(!currentCallFrameV8.IsEmpty());
    if (!currentCallFrameV8->IsObject())
        return nullptr;
    return JavaScriptCallFrame::create(v8::Debug::GetDebugContext(), v8::Handle<v8::Object>::Cast(currentCallFrameV8));
}

ScriptValue ScriptDebugServer::currentCallFramesInner(ScopeInfoDetails scopeDetails)
{
    if (!m_isolate->InContext())
        return ScriptValue();
    v8::HandleScope handleScope(m_isolate);

    // Filter out stack traces entirely consisting of V8's internal scripts.
    v8::Local<v8::StackTrace> stackTrace = v8::StackTrace::CurrentStackTrace(m_isolate, 1);
    if (!stackTrace->GetFrameCount())
        return ScriptValue();

    RefPtr<JavaScriptCallFrame> currentCallFrame = wrapCallFrames(0, scopeDetails);
    if (!currentCallFrame)
        return ScriptValue();

    ScriptState* scriptState = m_pausedScriptState ? m_pausedScriptState.get() : ScriptState::current(m_isolate);
    ScriptState::Scope scope(scriptState);
    return ScriptValue(scriptState, toV8(currentCallFrame.release(), scriptState->context()->Global(), m_isolate));
}

ScriptValue ScriptDebugServer::currentCallFrames()
{
    return currentCallFramesInner(AllScopes);
}

ScriptValue ScriptDebugServer::currentCallFramesForAsyncStack()
{
    return currentCallFramesInner(FastAsyncScopes);
}

PassRefPtr<JavaScriptCallFrame> ScriptDebugServer::callFrameNoScopes(int index)
{
    v8::Handle<v8::Value> currentCallFrameV8;
    if (m_executionState.IsEmpty()) {
        v8::Handle<v8::Function> currentCallFrameFunction = v8::Local<v8::Function>::Cast(m_debuggerScript.newLocal(m_isolate)->Get(v8AtomicString(m_isolate, "currentCallFrameByIndex")));
        currentCallFrameV8 = v8::Debug::Call(currentCallFrameFunction, v8::Integer::New(m_isolate, index));
    } else {
        v8::Handle<v8::Value> argv[] = { m_executionState, v8::Integer::New(m_isolate, index) };
        currentCallFrameV8 = callDebuggerMethod("currentCallFrameByIndex", WTF_ARRAY_LENGTH(argv), argv);
    }
    ASSERT(!currentCallFrameV8.IsEmpty());
    if (!currentCallFrameV8->IsObject())
        return nullptr;
    return JavaScriptCallFrame::create(v8::Debug::GetDebugContext(), v8::Handle<v8::Object>::Cast(currentCallFrameV8));
}

void ScriptDebugServer::interruptAndRun(PassOwnPtr<Task> task, v8::Isolate* isolate)
{
    v8::Debug::DebugBreakForCommand(isolate, new ClientDataImpl(task));
}

void ScriptDebugServer::runPendingTasks()
{
    v8::Debug::ProcessDebugMessages();
}

static ScriptDebugServer* toScriptDebugServer(v8::Handle<v8::Value> data)
{
    void* p = v8::Handle<v8::External>::Cast(data)->Value();
    return static_cast<ScriptDebugServer*>(p);
}

void ScriptDebugServer::breakProgramCallback(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    ASSERT(2 == info.Length());
    ScriptDebugServer* thisPtr = toScriptDebugServer(info.Data());
    ScriptState* pausedScriptState = ScriptState::current(thisPtr->m_isolate);
    v8::Handle<v8::Value> exception;
    v8::Handle<v8::Array> hitBreakpoints;
    thisPtr->handleProgramBreak(pausedScriptState, v8::Handle<v8::Object>::Cast(info[0]), exception, hitBreakpoints);
}

void ScriptDebugServer::handleProgramBreak(ScriptState* pausedScriptState, v8::Handle<v8::Object> executionState, v8::Handle<v8::Value> exception, v8::Handle<v8::Array> hitBreakpointNumbers)
{
    // Don't allow nested breaks.
    if (isPaused())
        return;

    ScriptDebugListener* listener = getDebugListenerForContext(pausedScriptState->context());
    if (!listener)
        return;

    Vector<String> breakpointIds;
    if (!hitBreakpointNumbers.IsEmpty()) {
        breakpointIds.resize(hitBreakpointNumbers->Length());
        for (size_t i = 0; i < hitBreakpointNumbers->Length(); i++) {
            v8::Handle<v8::Value> hitBreakpointNumber = hitBreakpointNumbers->Get(i);
            ASSERT(!hitBreakpointNumber.IsEmpty() && hitBreakpointNumber->IsInt32());
            breakpointIds[i] = String::number(hitBreakpointNumber->Int32Value());
        }
    }

    m_pausedScriptState = pausedScriptState;
    m_executionState = executionState;
    ScriptDebugListener::SkipPauseRequest result = listener->didPause(pausedScriptState, currentCallFrames(), ScriptValue(pausedScriptState, exception), breakpointIds);
    if (result == ScriptDebugListener::NoSkip) {
        m_runningNestedMessageLoop = true;
        runMessageLoopOnPause(pausedScriptState->context());
        m_runningNestedMessageLoop = false;
    }
    m_pausedScriptState.clear();
    m_executionState.Clear();

    if (result == ScriptDebugListener::StepInto) {
        v8::Handle<v8::Value> argv[] = { executionState };
        callDebuggerMethod(stepIntoV8MethodName, 1, argv);
    } else if (result == ScriptDebugListener::StepOut) {
        v8::Handle<v8::Value> argv[] = { executionState };
        callDebuggerMethod(stepOutV8MethodName, 1, argv);
    }
}

void ScriptDebugServer::v8DebugEventCallback(const v8::Debug::EventDetails& eventDetails)
{
    ScriptDebugServer* thisPtr = toScriptDebugServer(eventDetails.GetCallbackData());
    thisPtr->handleV8DebugEvent(eventDetails);
}

static v8::Handle<v8::Value> callInternalGetterFunction(v8::Handle<v8::Object> object, const char* functionName, v8::Isolate* isolate)
{
    v8::Handle<v8::Value> getterValue = object->Get(v8AtomicString(isolate, functionName));
    ASSERT(!getterValue.IsEmpty() && getterValue->IsFunction());
    return V8ScriptRunner::callInternalFunction(v8::Handle<v8::Function>::Cast(getterValue), object, 0, 0, isolate);
}

void ScriptDebugServer::handleV8DebugEvent(const v8::Debug::EventDetails& eventDetails)
{
    v8::DebugEvent event = eventDetails.GetEvent();

    if (event == v8::BreakForCommand) {
        ClientDataImpl* data = static_cast<ClientDataImpl*>(eventDetails.GetClientData());
        data->task()->run();
        return;
    }

    if (event != v8::AsyncTaskEvent && event != v8::Break && event != v8::Exception && event != v8::AfterCompile && event != v8::BeforeCompile && event != v8::CompileError && event != v8::PromiseEvent)
        return;

    v8::Handle<v8::Context> eventContext = eventDetails.GetEventContext();
    ASSERT(!eventContext.IsEmpty());

    ScriptDebugListener* listener = getDebugListenerForContext(eventContext);
    if (listener) {
        v8::HandleScope scope(m_isolate);
        v8::Handle<v8::Object> debuggerScript = m_debuggerScript.newLocal(m_isolate);
        if (event == v8::BeforeCompile) {
            preprocessBeforeCompile(eventDetails);
        } else if (event == v8::AfterCompile || event == v8::CompileError) {
            v8::Context::Scope contextScope(v8::Debug::GetDebugContext());
            v8::Handle<v8::Function> getAfterCompileScript = v8::Local<v8::Function>::Cast(debuggerScript->Get(v8AtomicString(m_isolate, "getAfterCompileScript")));
            v8::Handle<v8::Value> argv[] = { eventDetails.GetEventData() };
            v8::Handle<v8::Value> value = V8ScriptRunner::callInternalFunction(getAfterCompileScript, debuggerScript, WTF_ARRAY_LENGTH(argv), argv, m_isolate);
            ASSERT(value->IsObject());
            v8::Handle<v8::Object> object = v8::Handle<v8::Object>::Cast(value);
            dispatchDidParseSource(listener, object, event != v8::AfterCompile ? CompileError : CompileSuccess);
        } else if (event == v8::Exception) {
            v8::Handle<v8::Object> eventData = eventDetails.GetEventData();
            v8::Handle<v8::Value> exception = callInternalGetterFunction(eventData, "exception", m_isolate);
            handleProgramBreak(ScriptState::from(eventContext), eventDetails.GetExecutionState(), exception, v8::Handle<v8::Array>());
        } else if (event == v8::Break) {
            v8::Handle<v8::Function> getBreakpointNumbersFunction = v8::Local<v8::Function>::Cast(debuggerScript->Get(v8AtomicString(m_isolate, "getBreakpointNumbers")));
            v8::Handle<v8::Value> argv[] = { eventDetails.GetEventData() };
            v8::Handle<v8::Value> hitBreakpoints = V8ScriptRunner::callInternalFunction(getBreakpointNumbersFunction, debuggerScript, WTF_ARRAY_LENGTH(argv), argv, m_isolate);
            ASSERT(hitBreakpoints->IsArray());
            handleProgramBreak(ScriptState::from(eventContext), eventDetails.GetExecutionState(), v8::Handle<v8::Value>(), hitBreakpoints.As<v8::Array>());
        } else if (event == v8::AsyncTaskEvent) {
            handleV8AsyncTaskEvent(listener, ScriptState::from(eventContext), eventDetails.GetExecutionState(), eventDetails.GetEventData());
        } else if (event == v8::PromiseEvent) {
            handleV8PromiseEvent(listener, ScriptState::from(eventContext), eventDetails.GetExecutionState(), eventDetails.GetEventData());
        }
    }
}

void ScriptDebugServer::handleV8AsyncTaskEvent(ScriptDebugListener* listener, ScriptState* pausedScriptState, v8::Handle<v8::Object> executionState, v8::Handle<v8::Object> eventData)
{
    String type = toCoreStringWithUndefinedOrNullCheck(callInternalGetterFunction(eventData, "type", m_isolate));
    String name = toCoreStringWithUndefinedOrNullCheck(callInternalGetterFunction(eventData, "name", m_isolate));
    int id = callInternalGetterFunction(eventData, "id", m_isolate)->ToInteger()->Value();

    m_pausedScriptState = pausedScriptState;
    m_executionState = executionState;
    listener->didReceiveV8AsyncTaskEvent(pausedScriptState->executionContext(), type, name, id);
    m_pausedScriptState.clear();
    m_executionState.Clear();
}

void ScriptDebugServer::handleV8PromiseEvent(ScriptDebugListener* listener, ScriptState* pausedScriptState, v8::Handle<v8::Object> executionState, v8::Handle<v8::Object> eventData)
{
    v8::Handle<v8::Value> argv[] = { eventData };
    v8::Local<v8::Object> promiseDetails = callDebuggerMethod("getPromiseDetails", 1, argv)->ToObject();
    v8::Handle<v8::Object> promise = promiseDetails->Get(v8AtomicString(m_isolate, "promise"))->ToObject();
    int status = promiseDetails->Get(v8AtomicString(m_isolate, "status"))->ToInteger()->Value();
    v8::Handle<v8::Value> parentPromise = promiseDetails->Get(v8AtomicString(m_isolate, "parentPromise"));

    m_pausedScriptState = pausedScriptState;
    m_executionState = executionState;
    listener->didReceiveV8PromiseEvent(pausedScriptState, promise, parentPromise, status);
    m_pausedScriptState.clear();
    m_executionState.Clear();
}

void ScriptDebugServer::dispatchDidParseSource(ScriptDebugListener* listener, v8::Handle<v8::Object> object, CompileResult compileResult)
{
    v8::Handle<v8::Value> id = object->Get(v8AtomicString(m_isolate, "id"));
    ASSERT(!id.IsEmpty() && id->IsInt32());
    String sourceID = String::number(id->Int32Value());

    ScriptDebugListener::Script script;
    script.url = toCoreStringWithUndefinedOrNullCheck(object->Get(v8AtomicString(m_isolate, "name")));
    script.sourceURL = toCoreStringWithUndefinedOrNullCheck(object->Get(v8AtomicString(m_isolate, "sourceURL")));
    script.sourceMappingURL = toCoreStringWithUndefinedOrNullCheck(object->Get(v8AtomicString(m_isolate, "sourceMappingURL")));
    script.source = toCoreStringWithUndefinedOrNullCheck(object->Get(v8AtomicString(m_isolate, "source")));
    script.startLine = object->Get(v8AtomicString(m_isolate, "startLine"))->ToInteger()->Value();
    script.startColumn = object->Get(v8AtomicString(m_isolate, "startColumn"))->ToInteger()->Value();
    script.endLine = object->Get(v8AtomicString(m_isolate, "endLine"))->ToInteger()->Value();
    script.endColumn = object->Get(v8AtomicString(m_isolate, "endColumn"))->ToInteger()->Value();
    script.isContentScript = object->Get(v8AtomicString(m_isolate, "isContentScript"))->ToBoolean()->Value();

    listener->didParseSource(sourceID, script, compileResult);
}

void ScriptDebugServer::ensureDebuggerScriptCompiled()
{
    if (!m_debuggerScript.isEmpty())
        return;

    v8::HandleScope scope(m_isolate);
    v8::Context::Scope contextScope(v8::Debug::GetDebugContext());
    const blink::WebData& debuggerScriptSourceResource = blink::Platform::current()->loadResource("DebuggerScriptSource.js");
    v8::Handle<v8::String> source = v8String(m_isolate, String(debuggerScriptSourceResource.data(), debuggerScriptSourceResource.size()));
    v8::Local<v8::Value> value = V8ScriptRunner::compileAndRunInternalScript(source, m_isolate);
    ASSERT(!value.IsEmpty());
    ASSERT(value->IsObject());
    m_debuggerScript.set(m_isolate, v8::Handle<v8::Object>::Cast(value));
}

void ScriptDebugServer::discardDebuggerScript()
{
    ASSERT(!m_debuggerScript.isEmpty());
    m_debuggerScript.clear();
}

v8::Local<v8::Value> ScriptDebugServer::functionScopes(v8::Handle<v8::Function> function)
{
    ensureDebuggerScriptCompiled();

    v8::Handle<v8::Value> argv[] = { function };
    return callDebuggerMethod("getFunctionScopes", 1, argv);
}

v8::Local<v8::Value> ScriptDebugServer::collectionEntries(v8::Handle<v8::Object>& object)
{
    ensureDebuggerScriptCompiled();

    v8::Handle<v8::Value> argv[] = { object };
    return callDebuggerMethod("getCollectionEntries", 1, argv);
}

v8::Local<v8::Value> ScriptDebugServer::getInternalProperties(v8::Handle<v8::Object>& object)
{
    if (m_debuggerScript.isEmpty())
        return v8::Local<v8::Value>::New(m_isolate, v8::Undefined(m_isolate));

    v8::Handle<v8::Value> argv[] = { object };
    return callDebuggerMethod("getInternalProperties", 1, argv);
}

v8::Handle<v8::Value> ScriptDebugServer::setFunctionVariableValue(v8::Handle<v8::Value> functionValue, int scopeNumber, const String& variableName, v8::Handle<v8::Value> newValue)
{
    v8::Local<v8::Context> debuggerContext = v8::Debug::GetDebugContext();
    if (m_debuggerScript.isEmpty())
        return m_isolate->ThrowException(v8::String::NewFromUtf8(m_isolate, "Debugging is not enabled."));

    v8::Handle<v8::Value> argv[] = {
        functionValue,
        v8::Handle<v8::Value>(v8::Integer::New(debuggerContext->GetIsolate(), scopeNumber)),
        v8String(debuggerContext->GetIsolate(), variableName),
        newValue
    };
    return callDebuggerMethod("setFunctionVariableValue", 4, argv);
}

bool ScriptDebugServer::isPaused()
{
    return m_pausedScriptState;
}

void ScriptDebugServer::compileScript(ScriptState* scriptState, const String& expression, const String& sourceURL, String* scriptId, String* exceptionDetailsText, int* lineNumber, int* columnNumber, RefPtr<ScriptCallStack>* stackTrace)
{
    if (scriptState->contextIsEmpty())
        return;
    ScriptState::Scope scope(scriptState);

    v8::Handle<v8::String> source = v8String(m_isolate, expression);
    v8::TryCatch tryCatch;
    v8::Local<v8::Script> script = V8ScriptRunner::compileScript(source, sourceURL, TextPosition(), m_isolate);
    if (tryCatch.HasCaught()) {
        v8::Local<v8::Message> message = tryCatch.Message();
        if (!message.IsEmpty()) {
            *exceptionDetailsText = toCoreStringWithUndefinedOrNullCheck(message->Get());
            *lineNumber = message->GetLineNumber();
            *columnNumber = message->GetStartColumn();
            *stackTrace = createScriptCallStack(message->GetStackTrace(), message->GetStackTrace()->GetFrameCount(), m_isolate);
        }
        return;
    }
    if (script.IsEmpty())
        return;

    *scriptId = String::number(script->GetUnboundScript()->GetId());
    m_compiledScripts.set(*scriptId, adoptPtr(new ScopedPersistent<v8::Script>(m_isolate, script)));
}

void ScriptDebugServer::clearCompiledScripts()
{
    m_compiledScripts.clear();
}

void ScriptDebugServer::runScript(ScriptState* scriptState, const String& scriptId, ScriptValue* result, bool* wasThrown, String* exceptionDetailsText, int* lineNumber, int* columnNumber, RefPtr<ScriptCallStack>* stackTrace)
{
    if (!m_compiledScripts.contains(scriptId))
        return;
    v8::HandleScope handleScope(m_isolate);
    ScopedPersistent<v8::Script>* scriptHandle = m_compiledScripts.get(scriptId);
    v8::Local<v8::Script> script = scriptHandle->newLocal(m_isolate);
    m_compiledScripts.remove(scriptId);
    if (script.IsEmpty())
        return;

    if (scriptState->contextIsEmpty())
        return;
    ScriptState::Scope scope(scriptState);
    v8::TryCatch tryCatch;
    v8::Local<v8::Value> value = V8ScriptRunner::runCompiledScript(script, scriptState->executionContext(), m_isolate);
    *wasThrown = false;
    if (tryCatch.HasCaught()) {
        *wasThrown = true;
        *result = ScriptValue(scriptState, tryCatch.Exception());
        v8::Local<v8::Message> message = tryCatch.Message();
        if (!message.IsEmpty()) {
            *exceptionDetailsText = toCoreStringWithUndefinedOrNullCheck(message->Get());
            *lineNumber = message->GetLineNumber();
            *columnNumber = message->GetStartColumn();
            *stackTrace = createScriptCallStack(message->GetStackTrace(), message->GetStackTrace()->GetFrameCount(), m_isolate);
        }
    } else {
        *result = ScriptValue(scriptState, value);
    }
}

PassOwnPtr<ScriptSourceCode> ScriptDebugServer::preprocess(LocalFrame*, const ScriptSourceCode&)
{
    return PassOwnPtr<ScriptSourceCode>();
}

String ScriptDebugServer::preprocessEventListener(LocalFrame*, const String& source, const String& url, const String& functionName)
{
    return source;
}

} // namespace blink