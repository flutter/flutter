/*
 * Copyright (C) 2007-2011 Google Inc. All rights reserved.
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
#include "bindings/core/v8/V8InjectedScriptHost.h"

#include "bindings/core/v8/V8DOMTokenList.h"
#include "bindings/core/v8/V8EventTarget.h"
#include "bindings/core/v8/V8Node.h"
#include "bindings/core/v8/V8NodeList.h"
#include "sky/engine/bindings/core/v8/BindingSecurity.h"
#include "sky/engine/bindings/core/v8/ExceptionState.h"
#include "sky/engine/bindings/core/v8/ScriptValue.h"
#include "sky/engine/bindings/core/v8/V8AbstractEventListener.h"
#include "sky/engine/bindings/core/v8/V8Binding.h"
#include "sky/engine/bindings/core/v8/V8ScriptRunner.h"
#include "sky/engine/bindings/core/v8/custom/V8Float32ArrayCustom.h"
#include "sky/engine/bindings/core/v8/custom/V8Float64ArrayCustom.h"
#include "sky/engine/bindings/core/v8/custom/V8Int16ArrayCustom.h"
#include "sky/engine/bindings/core/v8/custom/V8Int32ArrayCustom.h"
#include "sky/engine/bindings/core/v8/custom/V8Int8ArrayCustom.h"
#include "sky/engine/bindings/core/v8/custom/V8Uint16ArrayCustom.h"
#include "sky/engine/bindings/core/v8/custom/V8Uint32ArrayCustom.h"
#include "sky/engine/bindings/core/v8/custom/V8Uint8ArrayCustom.h"
#include "sky/engine/bindings/core/v8/custom/V8Uint8ClampedArrayCustom.h"
#include "sky/engine/core/events/EventTarget.h"
#include "sky/engine/core/frame/LocalDOMWindow.h"
#include "sky/engine/core/inspector/InjectedScriptHost.h"
#include "sky/engine/core/inspector/JavaScriptCallFrame.h"
#include "sky/engine/platform/JSONValues.h"
#include "sky/engine/v8_inspector/InjectedScript.h"
#include "sky/engine/v8_inspector/ScriptDebugServer.h"

namespace blink {

Node* InjectedScriptHost::scriptValueAsNode(ScriptState* scriptState, ScriptValue value)
{
    ScriptState::Scope scope(scriptState);
    if (!value.isObject() || value.isNull())
        return 0;
    return V8Node::toNative(v8::Handle<v8::Object>::Cast(value.v8Value()));
}

ScriptValue InjectedScriptHost::nodeAsScriptValue(ScriptState* scriptState, Node* node)
{
    ScriptState::Scope scope(scriptState);
    v8::Isolate* isolate = scriptState->isolate();
    ExceptionState exceptionState(ExceptionState::ExecutionContext, "nodeAsScriptValue", "InjectedScriptHost", scriptState->context()->Global(), isolate);
    return ScriptValue(scriptState, toV8(node, scriptState->context()->Global(), isolate));
}

void V8InjectedScriptHost::inspectedObjectMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    if (info.Length() < 1)
        return;

    if (!info[0]->IsInt32()) {
        V8ThrowException::throwTypeError("argument has to be an integer", info.GetIsolate());
        return;
    }

    InjectedScriptHost* host = V8InjectedScriptHost::toNative(info.Holder());
    InjectedScriptHost::InspectableObject* object = host->inspectedObject(info[0]->ToInt32()->Value());
    v8SetReturnValue(info, object->get(ScriptState::current(info.GetIsolate())).v8Value());
}

static v8::Handle<v8::String> functionDisplayName(v8::Handle<v8::Function> function)
{
    v8::Handle<v8::Value> value = function->GetDisplayName();
    if (value->IsString() && v8::Handle<v8::String>::Cast(value)->Length())
        return v8::Handle<v8::String>::Cast(value);

    value = function->GetName();
    if (value->IsString() && v8::Handle<v8::String>::Cast(value)->Length())
        return v8::Handle<v8::String>::Cast(value);

    value = function->GetInferredName();
    if (value->IsString() && v8::Handle<v8::String>::Cast(value)->Length())
        return v8::Handle<v8::String>::Cast(value);

    return v8::Handle<v8::String>();
}

void V8InjectedScriptHost::internalConstructorNameMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    if (info.Length() < 1 || !info[0]->IsObject())
        return;

    v8::Local<v8::Object> object = info[0]->ToObject();
    v8::Local<v8::String> result = object->GetConstructorName();

    if (!result.IsEmpty() && toCoreStringWithUndefinedOrNullCheck(result) == "Object") {
        v8::Local<v8::String> constructorSymbol = v8AtomicString(info.GetIsolate(), "constructor");
        if (object->HasRealNamedProperty(constructorSymbol) && !object->HasRealNamedCallbackProperty(constructorSymbol)) {
            v8::TryCatch tryCatch;
            v8::Local<v8::Value> constructor = object->GetRealNamedProperty(constructorSymbol);
            if (!constructor.IsEmpty() && constructor->IsFunction()) {
                v8::Local<v8::String> constructorName = functionDisplayName(v8::Handle<v8::Function>::Cast(constructor));
                if (!constructorName.IsEmpty() && !tryCatch.HasCaught())
                    result = constructorName;
            }
        }
    }

    v8SetReturnValue(info, result);
}

void V8InjectedScriptHost::isHTMLAllCollectionMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    // FIXME(sky): remove
    v8SetReturnValue(info, false);
}

void V8InjectedScriptHost::subtypeMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    if (info.Length() < 1)
        return;
    v8::Isolate* isolate = info.GetIsolate();

    v8::Handle<v8::Value> value = info[0];
    if (value->IsArray() || value->IsTypedArray() || value->IsArgumentsObject()) {
        v8SetReturnValue(info, v8AtomicString(isolate, "array"));
        return;
    }
    if (value->IsDate()) {
        v8SetReturnValue(info, v8AtomicString(isolate, "date"));
        return;
    }
    if (value->IsRegExp()) {
        v8SetReturnValue(info, v8AtomicString(isolate, "regexp"));
        return;
    }
    if (value->IsMap() || value->IsWeakMap()) {
        v8SetReturnValue(info, v8AtomicString(isolate, "map"));
        return;
    }
    if (value->IsSet() || value->IsWeakSet()) {
        v8SetReturnValue(info, v8AtomicString(isolate, "set"));
        return;
    }
    if (V8Node::hasInstance(value, isolate)) {
        v8SetReturnValue(info, v8AtomicString(isolate, "node"));
        return;
    }
    if (V8NodeList::hasInstance(value, isolate)
        || V8DOMTokenList::hasInstance(value, isolate)) {
        v8SetReturnValue(info, v8AtomicString(isolate, "array"));
        return;
    }
}

void V8InjectedScriptHost::functionDetailsMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    if (info.Length() < 1 || !info[0]->IsFunction())
        return;

    v8::Handle<v8::Function> function = v8::Handle<v8::Function>::Cast(info[0]);
    int lineNumber = function->GetScriptLineNumber();
    int columnNumber = function->GetScriptColumnNumber();

    v8::Isolate* isolate = info.GetIsolate();
    v8::Local<v8::Object> location = v8::Object::New(isolate);
    location->Set(v8AtomicString(isolate, "lineNumber"), v8::Integer::New(isolate, lineNumber));
    location->Set(v8AtomicString(isolate, "columnNumber"), v8::Integer::New(isolate, columnNumber));
    location->Set(v8AtomicString(isolate, "scriptId"), v8::Integer::New(isolate, function->ScriptId())->ToString());

    v8::Local<v8::Object> result = v8::Object::New(isolate);
    result->Set(v8AtomicString(isolate, "location"), location);

    v8::Handle<v8::String> name = functionDisplayName(function);
    result->Set(v8AtomicString(isolate, "functionName"), name.IsEmpty() ? v8AtomicString(isolate, "") : name);

    InjectedScriptHost* host = V8InjectedScriptHost::toNative(info.Holder());
    ScriptDebugServer& debugServer = host->scriptDebugServer();
    v8::Handle<v8::Value> scopes = debugServer.functionScopes(function);
    if (!scopes.IsEmpty() && scopes->IsArray())
        result->Set(v8AtomicString(isolate, "rawScopes"), scopes);

    v8SetReturnValue(info, result);
}

void V8InjectedScriptHost::collectionEntriesMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    if (info.Length() < 1 || !info[0]->IsObject())
        return;

    v8::Handle<v8::Object> object = v8::Handle<v8::Object>::Cast(info[0]);

    InjectedScriptHost* host = V8InjectedScriptHost::toNative(info.Holder());
    ScriptDebugServer& debugServer = host->scriptDebugServer();
    v8SetReturnValue(info, debugServer.collectionEntries(object));
}

void V8InjectedScriptHost::getInternalPropertiesMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    if (info.Length() < 1 || !info[0]->IsObject())
        return;

    v8::Handle<v8::Object> object = v8::Handle<v8::Object>::Cast(info[0]);

    InjectedScriptHost* host = V8InjectedScriptHost::toNative(info.Holder());
    ScriptDebugServer& debugServer = host->scriptDebugServer();
    v8SetReturnValue(info, debugServer.getInternalProperties(object));
}

void V8InjectedScriptHost::getEventListenersMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    // FIXME(sky): remove
}

void V8InjectedScriptHost::inspectMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    if (info.Length() < 2)
        return;

    InjectedScriptHost* host = V8InjectedScriptHost::toNative(info.Holder());
    ScriptState* scriptState = ScriptState::current(info.GetIsolate());
    ScriptValue object(scriptState, info[0]);
    ScriptValue hints(scriptState, info[1]);
    host->inspectImpl(object.toJSONValue(scriptState), hints.toJSONValue(scriptState));
}

void V8InjectedScriptHost::evalMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    v8::Isolate* isolate = info.GetIsolate();
    if (info.Length() < 1) {
        isolate->ThrowException(v8::Exception::Error(v8::String::NewFromUtf8(isolate, "One argument expected.")));
        return;
    }

    v8::Handle<v8::String> expression = info[0]->ToString();
    if (expression.IsEmpty()) {
        isolate->ThrowException(v8::Exception::Error(v8::String::NewFromUtf8(isolate, "The argument must be a string.")));
        return;
    }

    ASSERT(isolate->InContext());
    v8::TryCatch tryCatch;
    v8::Handle<v8::Value> result = V8ScriptRunner::compileAndRunInternalScript(expression, info.GetIsolate());
    if (tryCatch.HasCaught()) {
        v8SetReturnValue(info, tryCatch.ReThrow());
        return;
    }
    v8SetReturnValue(info, result);
}

void V8InjectedScriptHost::evaluateWithExceptionDetailsMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    v8::Isolate* isolate = info.GetIsolate();
    if (info.Length() < 1) {
        isolate->ThrowException(v8::Exception::Error(v8::String::NewFromUtf8(isolate, "One argument expected.")));
        return;
    }

    v8::Handle<v8::String> expression = info[0]->ToString();
    if (expression.IsEmpty()) {
        isolate->ThrowException(v8::Exception::Error(v8::String::NewFromUtf8(isolate, "The argument must be a string.")));
        return;
    }

    ASSERT(isolate->InContext());
    v8::TryCatch tryCatch;
    v8::Handle<v8::Value> result = V8ScriptRunner::compileAndRunInternalScript(expression, info.GetIsolate());

    v8::Local<v8::Object> wrappedResult = v8::Object::New(isolate);
    if (tryCatch.HasCaught()) {
        wrappedResult->Set(v8::String::NewFromUtf8(isolate, "result"), tryCatch.Exception());
        wrappedResult->Set(v8::String::NewFromUtf8(isolate, "exceptionDetails"), JavaScriptCallFrame::createExceptionDetails(tryCatch.Message(), isolate));
    } else {
        wrappedResult->Set(v8::String::NewFromUtf8(isolate, "result"), result);
        wrappedResult->Set(v8::String::NewFromUtf8(isolate, "exceptionDetails"), v8::Undefined(isolate));
    }
    v8SetReturnValue(info, wrappedResult);
}

void V8InjectedScriptHost::setFunctionVariableValueMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    v8::Handle<v8::Value> functionValue = info[0];
    int scopeIndex = info[1]->Int32Value();
    String variableName = toCoreStringWithUndefinedOrNullCheck(info[2]);
    v8::Handle<v8::Value> newValue = info[3];

    InjectedScriptHost* host = V8InjectedScriptHost::toNative(info.Holder());
    ScriptDebugServer& debugServer = host->scriptDebugServer();
    v8SetReturnValue(info, debugServer.setFunctionVariableValue(functionValue, scopeIndex, variableName, newValue));
}

static bool getFunctionLocation(const v8::FunctionCallbackInfo<v8::Value>& info, String* scriptId, int* lineNumber, int* columnNumber)
{
    if (info.Length() < 1)
        return false;
    v8::Handle<v8::Value> fn = info[0];
    if (!fn->IsFunction())
        return false;
    v8::Handle<v8::Function> function = v8::Handle<v8::Function>::Cast(fn);
    *lineNumber = function->GetScriptLineNumber();
    *columnNumber = function->GetScriptColumnNumber();
    if (*lineNumber == v8::Function::kLineOffsetNotFound || *columnNumber == v8::Function::kLineOffsetNotFound)
        return false;
    *scriptId = String::number(function->ScriptId());
    return true;
}

void V8InjectedScriptHost::debugFunctionMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    String scriptId;
    int lineNumber;
    int columnNumber;
    if (!getFunctionLocation(info, &scriptId, &lineNumber, &columnNumber))
        return;

    InjectedScriptHost* host = V8InjectedScriptHost::toNative(info.Holder());
    host->debugFunction(scriptId, lineNumber, columnNumber);
}

void V8InjectedScriptHost::undebugFunctionMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    String scriptId;
    int lineNumber;
    int columnNumber;
    if (!getFunctionLocation(info, &scriptId, &lineNumber, &columnNumber))
        return;

    InjectedScriptHost* host = V8InjectedScriptHost::toNative(info.Holder());
    host->undebugFunction(scriptId, lineNumber, columnNumber);
}

void V8InjectedScriptHost::monitorFunctionMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    String scriptId;
    int lineNumber;
    int columnNumber;
    if (!getFunctionLocation(info, &scriptId, &lineNumber, &columnNumber))
        return;

    v8::Handle<v8::Value> name;
    if (info.Length() > 0 && info[0]->IsFunction()) {
        v8::Handle<v8::Function> function = v8::Handle<v8::Function>::Cast(info[0]);
        name = function->GetName();
        if (!name->IsString() || !v8::Handle<v8::String>::Cast(name)->Length())
            name = function->GetInferredName();
    }

    InjectedScriptHost* host = V8InjectedScriptHost::toNative(info.Holder());
    host->monitorFunction(scriptId, lineNumber, columnNumber, toCoreStringWithUndefinedOrNullCheck(name));
}

void V8InjectedScriptHost::unmonitorFunctionMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    String scriptId;
    int lineNumber;
    int columnNumber;
    if (!getFunctionLocation(info, &scriptId, &lineNumber, &columnNumber))
        return;

    InjectedScriptHost* host = V8InjectedScriptHost::toNative(info.Holder());
    host->unmonitorFunction(scriptId, lineNumber, columnNumber);
}

void V8InjectedScriptHost::callFunctionMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    if (info.Length() < 2 || info.Length() > 3 || !info[0]->IsFunction()) {
        ASSERT_NOT_REACHED();
        return;
    }

    v8::Handle<v8::Function> function = v8::Handle<v8::Function>::Cast(info[0]);
    v8::Handle<v8::Value> receiver = info[1];

    if (info.Length() < 3 || info[2]->IsUndefined()) {
        v8::Local<v8::Value> result = function->Call(receiver, 0, 0);
        v8SetReturnValue(info, result);
        return;
    }

    if (!info[2]->IsArray()) {
        ASSERT_NOT_REACHED();
        return;
    }

    v8::Handle<v8::Array> arguments = v8::Handle<v8::Array>::Cast(info[2]);
    size_t argc = arguments->Length();
    OwnPtr<v8::Handle<v8::Value>[]> argv = adoptArrayPtr(new v8::Handle<v8::Value>[argc]);
    for (size_t i = 0; i < argc; ++i)
        argv[i] = arguments->Get(i);

    v8::Local<v8::Value> result = function->Call(receiver, argc, argv.get());
    v8SetReturnValue(info, result);
}

void V8InjectedScriptHost::suppressWarningsAndCallFunctionMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    InjectedScriptHost* host = V8InjectedScriptHost::toNative(info.Holder());
    ScriptDebugServer& debugServer = host->scriptDebugServer();
    debugServer.muteWarningsAndDeprecations();

    callFunctionMethodCustom(info);

    debugServer.unmuteWarningsAndDeprecations();
}

} // namespace blink
