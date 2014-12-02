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

#include "sky/engine/config.h"


#include "sky/engine/v8_inspector/InjectedScriptBase.h"

#include "sky/engine/bindings/core/v8/ScriptFunctionCall.h"
#include "sky/engine/core/inspector/InspectorTraceEvents.h"
#include "sky/engine/platform/JSONValues.h"
#include "sky/engine/wtf/text/WTFString.h"

using blink::TypeBuilder::Array;
using blink::TypeBuilder::Runtime::RemoteObject;

namespace blink {

static PassRefPtr<TypeBuilder::Debugger::ExceptionDetails> toExceptionDetails(PassRefPtr<JSONObject> object)
{
    String text;
    if (!object->getString("text", &text))
        return nullptr;

    RefPtr<TypeBuilder::Debugger::ExceptionDetails> exceptionDetails = TypeBuilder::Debugger::ExceptionDetails::create().setText(text);
    String url;
    if (object->getString("url", &url))
        exceptionDetails->setUrl(url);
    int line = 0;
    if (object->getNumber("line", &line))
        exceptionDetails->setLine(line);
    int column = 0;
    if (object->getNumber("column", &column))
        exceptionDetails->setColumn(column);
    RefPtr<JSONArray> stackTrace = object->getArray("stackTrace");
    if (stackTrace && stackTrace->length() > 0) {
        RefPtr<TypeBuilder::Array<TypeBuilder::Console::CallFrame> > frames = TypeBuilder::Array<TypeBuilder::Console::CallFrame>::create();
        for (unsigned i = 0; i < stackTrace->length(); ++i) {
            RefPtr<JSONObject> stackFrame = stackTrace->get(i)->asObject();
            int lineNumber = 0;
            stackFrame->getNumber("lineNumber", &lineNumber);
            int column = 0;
            stackFrame->getNumber("column", &column);
            int scriptId = 0;
            stackFrame->getNumber("scriptId", &scriptId);
            String sourceURL;
            stackFrame->getString("scriptNameOrSourceURL", &sourceURL);
            String functionName;
            stackFrame->getString("functionName", &functionName);

            RefPtr<TypeBuilder::Console::CallFrame> callFrame = TypeBuilder::Console::CallFrame::create()
                .setFunctionName(functionName)
                .setScriptId(String::number(scriptId))
                .setUrl(sourceURL)
                .setLineNumber(lineNumber)
                .setColumnNumber(column);

            frames->addItem(callFrame.release());
        }
        exceptionDetails->setStackTrace(frames.release());
    }
    return exceptionDetails.release();
}

InjectedScriptBase::InjectedScriptBase(const String& name)
    : m_name(name)
{
}

InjectedScriptBase::InjectedScriptBase(const String& name, ScriptValue injectedScriptObject)
    : m_name(name)
    , m_injectedScriptObject(injectedScriptObject)
{
}

void InjectedScriptBase::initialize(ScriptValue injectedScriptObject)
{
    m_injectedScriptObject = injectedScriptObject;
}

const ScriptValue& InjectedScriptBase::injectedScriptObject() const
{
    return m_injectedScriptObject;
}

ScriptValue InjectedScriptBase::callFunctionWithEvalEnabled(ScriptFunctionCall& function, bool& hadException) const
{
    ASSERT(!isEmpty());
    ExecutionContext* executionContext = m_injectedScriptObject.scriptState()->executionContext();
    TRACE_EVENT1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline"), "FunctionCall", "data", InspectorFunctionCallEvent::data(executionContext, 0, name(), 1));
    TRACE_EVENT_INSTANT1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline.stack"), "CallStack", TRACE_EVENT_SCOPE_PROCESS, "stack", InspectorCallStackEvent::currentCallStack());

    ScriptState* scriptState = m_injectedScriptObject.scriptState();
    bool evalIsDisabled = false;
    if (scriptState) {
        evalIsDisabled = !scriptState->evalEnabled();
        // Temporarily enable allow evals for inspector.
        if (evalIsDisabled)
            scriptState->setEvalEnabled(true);
    }

    ScriptValue resultValue = function.call(hadException);

    if (evalIsDisabled)
        scriptState->setEvalEnabled(false);

    TRACE_EVENT_INSTANT1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline"), "UpdateCounters", TRACE_EVENT_SCOPE_PROCESS, "data", InspectorUpdateCountersEvent::data());
    return resultValue;
}

void InjectedScriptBase::makeCall(ScriptFunctionCall& function, RefPtr<JSONValue>* result)
{
    if (isEmpty()) {
        *result = JSONValue::null();
        return;
    }

    bool hadException = false;
    ScriptValue resultValue = callFunctionWithEvalEnabled(function, hadException);

    ASSERT(!hadException);
    if (!hadException) {
        *result = resultValue.toJSONValue(m_injectedScriptObject.scriptState());
        if (!*result)
            *result = JSONString::create(String::format("Object has too long reference chain(must not be longer than %d)", JSONValue::maxDepth));
    } else {
        *result = JSONString::create("Exception while making a call.");
    }
}

void InjectedScriptBase::makeEvalCall(ErrorString* errorString, ScriptFunctionCall& function, RefPtr<TypeBuilder::Runtime::RemoteObject>* objectResult, TypeBuilder::OptOutput<bool>* wasThrown, RefPtr<TypeBuilder::Debugger::ExceptionDetails>* exceptionDetails)
{
    RefPtr<JSONValue> result;
    makeCall(function, &result);
    if (!result) {
        *errorString = "Internal error: result value is empty";
        return;
    }
    if (result->type() == JSONValue::TypeString) {
        result->asString(errorString);
        ASSERT(errorString->length());
        return;
    }
    RefPtr<JSONObject> resultPair = result->asObject();
    if (!resultPair) {
        *errorString = "Internal error: result is not an Object";
        return;
    }
    RefPtr<JSONObject> resultObj = resultPair->getObject("result");
    bool wasThrownVal = false;
    if (!resultObj || !resultPair->getBoolean("wasThrown", &wasThrownVal)) {
        *errorString = "Internal error: result is not a pair of value and wasThrown flag";
        return;
    }
    if (wasThrownVal) {
        RefPtr<JSONObject> objectExceptionDetails = resultPair->getObject("exceptionDetails");
        if (objectExceptionDetails)
            *exceptionDetails = toExceptionDetails(objectExceptionDetails.release());
    }
    *objectResult = TypeBuilder::Runtime::RemoteObject::runtimeCast(resultObj);
    *wasThrown = wasThrownVal;
}

} // namespace blink

