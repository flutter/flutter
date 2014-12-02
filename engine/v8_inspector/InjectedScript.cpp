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


#include "sky/engine/v8_inspector/InjectedScript.h"

#include "sky/engine/bindings/core/v8/ScriptFunctionCall.h"
#include "sky/engine/core/inspector/InjectedScriptHost.h"
#include "sky/engine/platform/JSONValues.h"
#include "sky/engine/wtf/text/WTFString.h"

using blink::TypeBuilder::Array;
using blink::TypeBuilder::Debugger::CallFrame;
using blink::TypeBuilder::Debugger::CollectionEntry;
using blink::TypeBuilder::Debugger::FunctionDetails;
using blink::TypeBuilder::Runtime::PropertyDescriptor;
using blink::TypeBuilder::Runtime::InternalPropertyDescriptor;
using blink::TypeBuilder::Runtime::RemoteObject;

namespace blink {

InjectedScript::InjectedScript()
    : InjectedScriptBase("InjectedScript")
{
}

InjectedScript::InjectedScript(ScriptValue injectedScriptObject)
    : InjectedScriptBase("InjectedScript", injectedScriptObject)
{
}

void InjectedScript::evaluate(ErrorString* errorString, const String& expression, const String& objectGroup, bool includeCommandLineAPI, bool returnByValue, bool generatePreview, RefPtr<TypeBuilder::Runtime::RemoteObject>* result, TypeBuilder::OptOutput<bool>* wasThrown, RefPtr<TypeBuilder::Debugger::ExceptionDetails>* exceptionDetails)
{
    ScriptFunctionCall function(injectedScriptObject(), "evaluate");
    function.appendArgument(expression);
    function.appendArgument(objectGroup);
    function.appendArgument(includeCommandLineAPI);
    function.appendArgument(returnByValue);
    function.appendArgument(generatePreview);
    makeEvalCall(errorString, function, result, wasThrown, exceptionDetails);
}

void InjectedScript::callFunctionOn(ErrorString* errorString, const String& objectId, const String& expression, const String& arguments, bool returnByValue, bool generatePreview, RefPtr<TypeBuilder::Runtime::RemoteObject>* result, TypeBuilder::OptOutput<bool>* wasThrown)
{
    ScriptFunctionCall function(injectedScriptObject(), "callFunctionOn");
    function.appendArgument(objectId);
    function.appendArgument(expression);
    function.appendArgument(arguments);
    function.appendArgument(returnByValue);
    function.appendArgument(generatePreview);
    makeEvalCall(errorString, function, result, wasThrown);
}

void InjectedScript::evaluateOnCallFrame(ErrorString* errorString, const ScriptValue& callFrames, const Vector<ScriptValue>& asyncCallStacks, const String& callFrameId, const String& expression, const String& objectGroup, bool includeCommandLineAPI, bool returnByValue, bool generatePreview, RefPtr<RemoteObject>* result, TypeBuilder::OptOutput<bool>* wasThrown, RefPtr<TypeBuilder::Debugger::ExceptionDetails>* exceptionDetails)
{
    ScriptFunctionCall function(injectedScriptObject(), "evaluateOnCallFrame");
    function.appendArgument(callFrames);
    function.appendArgument(asyncCallStacks);
    function.appendArgument(callFrameId);
    function.appendArgument(expression);
    function.appendArgument(objectGroup);
    function.appendArgument(includeCommandLineAPI);
    function.appendArgument(returnByValue);
    function.appendArgument(generatePreview);
    makeEvalCall(errorString, function, result, wasThrown, exceptionDetails);
}

void InjectedScript::restartFrame(ErrorString* errorString, const ScriptValue& callFrames, const String& callFrameId, RefPtr<JSONObject>* result)
{
    ScriptFunctionCall function(injectedScriptObject(), "restartFrame");
    function.appendArgument(callFrames);
    function.appendArgument(callFrameId);
    RefPtr<JSONValue> resultValue;
    makeCall(function, &resultValue);
    if (resultValue) {
        if (resultValue->type() == JSONValue::TypeString) {
            resultValue->asString(errorString);
            return;
        }
        if (resultValue->type() == JSONValue::TypeObject) {
            *result = resultValue->asObject();
            return;
        }
    }
    *errorString = "Internal error";
}

void InjectedScript::getStepInPositions(ErrorString* errorString, const ScriptValue& callFrames, const String& callFrameId, RefPtr<Array<TypeBuilder::Debugger::Location> >& positions)
{
    ScriptFunctionCall function(injectedScriptObject(), "getStepInPositions");
    function.appendArgument(callFrames);
    function.appendArgument(callFrameId);
    RefPtr<JSONValue> resultValue;
    makeCall(function, &resultValue);
    if (resultValue) {
        if (resultValue->type() == JSONValue::TypeString) {
            resultValue->asString(errorString);
            return;
        }
        if (resultValue->type() == JSONValue::TypeArray) {
            positions = Array<TypeBuilder::Debugger::Location>::runtimeCast(resultValue);
            return;
        }
    }
    *errorString = "Internal error";
}

void InjectedScript::setVariableValue(ErrorString* errorString, const ScriptValue& callFrames, const String* callFrameIdOpt, const String* functionObjectIdOpt, int scopeNumber, const String& variableName, const String& newValueStr)
{
    ScriptFunctionCall function(injectedScriptObject(), "setVariableValue");
    if (callFrameIdOpt) {
        function.appendArgument(callFrames);
        function.appendArgument(*callFrameIdOpt);
    } else {
        function.appendArgument(false);
        function.appendArgument(false);
    }
    if (functionObjectIdOpt)
        function.appendArgument(*functionObjectIdOpt);
    else
        function.appendArgument(false);
    function.appendArgument(scopeNumber);
    function.appendArgument(variableName);
    function.appendArgument(newValueStr);
    RefPtr<JSONValue> resultValue;
    makeCall(function, &resultValue);
    if (!resultValue) {
        *errorString = "Internal error";
        return;
    }
    if (resultValue->type() == JSONValue::TypeString) {
        resultValue->asString(errorString);
        return;
    }
    // Normal return.
}

void InjectedScript::getFunctionDetails(ErrorString* errorString, const String& functionId, RefPtr<FunctionDetails>* result)
{
    ScriptFunctionCall function(injectedScriptObject(), "getFunctionDetails");
    function.appendArgument(functionId);
    RefPtr<JSONValue> resultValue;
    makeCall(function, &resultValue);
    if (!resultValue || resultValue->type() != JSONValue::TypeObject) {
        if (!resultValue->asString(errorString))
            *errorString = "Internal error";
        return;
    }
    *result = FunctionDetails::runtimeCast(resultValue);
}

void InjectedScript::getCollectionEntries(ErrorString* errorString, const String& objectId, RefPtr<Array<CollectionEntry> >* result)
{
    ScriptFunctionCall function(injectedScriptObject(), "getCollectionEntries");
    function.appendArgument(objectId);
    RefPtr<JSONValue> resultValue;
    makeCall(function, &resultValue);
    if (!resultValue || resultValue->type() != JSONValue::TypeArray) {
        if (!resultValue->asString(errorString))
            *errorString = "Internal error";
        return;
    }
    *result = Array<CollectionEntry>::runtimeCast(resultValue);
}

void InjectedScript::getProperties(ErrorString* errorString, const String& objectId, bool ownProperties, bool accessorPropertiesOnly, RefPtr<Array<PropertyDescriptor> >* properties)
{
    ScriptFunctionCall function(injectedScriptObject(), "getProperties");
    function.appendArgument(objectId);
    function.appendArgument(ownProperties);
    function.appendArgument(accessorPropertiesOnly);

    RefPtr<JSONValue> result;
    makeCall(function, &result);
    if (!result || result->type() != JSONValue::TypeArray) {
        *errorString = "Internal error";
        return;
    }
    *properties = Array<PropertyDescriptor>::runtimeCast(result);
}

void InjectedScript::getInternalProperties(ErrorString* errorString, const String& objectId, RefPtr<Array<InternalPropertyDescriptor> >* properties)
{
    ScriptFunctionCall function(injectedScriptObject(), "getInternalProperties");
    function.appendArgument(objectId);

    RefPtr<JSONValue> result;
    makeCall(function, &result);
    if (!result || result->type() != JSONValue::TypeArray) {
        *errorString = "Internal error";
        return;
    }
    RefPtr<Array<InternalPropertyDescriptor> > array = Array<InternalPropertyDescriptor>::runtimeCast(result);
    if (array->length() > 0)
        *properties = array;
}

Node* InjectedScript::nodeForObjectId(const String& objectId)
{
    if (isEmpty())
        return 0;

    ScriptFunctionCall function(injectedScriptObject(), "nodeForObjectId");
    function.appendArgument(objectId);

    bool hadException = false;
    ScriptValue resultValue = callFunctionWithEvalEnabled(function, hadException);
    ASSERT(!hadException);

    return InjectedScriptHost::scriptValueAsNode(scriptState(), resultValue);
}

void InjectedScript::releaseObject(const String& objectId)
{
    ScriptFunctionCall function(injectedScriptObject(), "releaseObject");
    function.appendArgument(objectId);
    RefPtr<JSONValue> result;
    makeCall(function, &result);
}

PassRefPtr<Array<CallFrame> > InjectedScript::wrapCallFrames(const ScriptValue& callFrames, int asyncOrdinal)
{
    ASSERT(!isEmpty());
    ScriptFunctionCall function(injectedScriptObject(), "wrapCallFrames");
    function.appendArgument(callFrames);
    function.appendArgument(asyncOrdinal);
    bool hadException = false;
    ScriptValue callFramesValue = callFunctionWithEvalEnabled(function, hadException);
    ASSERT(!hadException);
    RefPtr<JSONValue> result = callFramesValue.toJSONValue(scriptState());
    if (result && result->type() == JSONValue::TypeArray)
        return Array<CallFrame>::runtimeCast(result);
    return Array<CallFrame>::create();
}

PassRefPtr<TypeBuilder::Runtime::RemoteObject> InjectedScript::wrapObject(const ScriptValue& value, const String& groupName, bool generatePreview) const
{
    ASSERT(!isEmpty());
    ScriptFunctionCall wrapFunction(injectedScriptObject(), "wrapObject");
    wrapFunction.appendArgument(value);
    wrapFunction.appendArgument(groupName);
    wrapFunction.appendArgument(true);
    wrapFunction.appendArgument(generatePreview);
    bool hadException = false;
    ScriptValue r = callFunctionWithEvalEnabled(wrapFunction, hadException);
    if (hadException)
        return nullptr;
    RefPtr<JSONObject> rawResult = r.toJSONValue(scriptState())->asObject();
    return TypeBuilder::Runtime::RemoteObject::runtimeCast(rawResult);
}

PassRefPtr<TypeBuilder::Runtime::RemoteObject> InjectedScript::wrapTable(const ScriptValue& table, const ScriptValue& columns) const
{
    ASSERT(!isEmpty());
    ScriptFunctionCall wrapFunction(injectedScriptObject(), "wrapTable");
    wrapFunction.appendArgument(true);
    wrapFunction.appendArgument(table);
    if (columns.isEmpty())
        wrapFunction.appendArgument(false);
    else
        wrapFunction.appendArgument(columns);
    bool hadException = false;
    ScriptValue r = callFunctionWithEvalEnabled(wrapFunction, hadException);
    if (hadException)
        return nullptr;
    RefPtr<JSONObject> rawResult = r.toJSONValue(scriptState())->asObject();
    return TypeBuilder::Runtime::RemoteObject::runtimeCast(rawResult);
}

PassRefPtr<TypeBuilder::Runtime::RemoteObject> InjectedScript::wrapNode(Node* node, const String& groupName)
{
    return wrapObject(nodeAsScriptValue(node), groupName);
}

ScriptValue InjectedScript::findObjectById(const String& objectId) const
{
    ASSERT(!isEmpty());
    ScriptFunctionCall function(injectedScriptObject(), "findObjectById");
    function.appendArgument(objectId);

    bool hadException = false;
    ScriptValue resultValue = callFunctionWithEvalEnabled(function, hadException);
    ASSERT(!hadException);
    return resultValue;
}

void InjectedScript::inspectNode(Node* node)
{
    ASSERT(!isEmpty());
    ScriptFunctionCall function(injectedScriptObject(), "inspectNode");
    function.appendArgument(nodeAsScriptValue(node));
    RefPtr<JSONValue> result;
    makeCall(function, &result);
}

void InjectedScript::releaseObjectGroup(const String& objectGroup)
{
    ASSERT(!isEmpty());
    ScriptFunctionCall releaseFunction(injectedScriptObject(), "releaseObjectGroup");
    releaseFunction.appendArgument(objectGroup);
    bool hadException = false;
    callFunctionWithEvalEnabled(releaseFunction, hadException);
    ASSERT(!hadException);
}

ScriptValue InjectedScript::nodeAsScriptValue(Node* node)
{
    return InjectedScriptHost::nodeAsScriptValue(scriptState(), node);
}

} // namespace blink

