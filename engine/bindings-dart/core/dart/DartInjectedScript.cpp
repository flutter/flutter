/*
 * Copyright (C) 2014 Google Inc. All rights reserved.
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

#include "bindings/core/dart/DartInjectedScript.h"

#include "bindings/core/dart/DartHandleProxy.h"
#include "bindings/core/dart/DartInjectedScriptHost.h"
#include "bindings/core/dart/DartJsInterop.h"
#include "bindings/core/dart/DartNode.h"
#include "bindings/core/dart/DartScriptDebugServer.h"
#include "bindings/core/dart/DartScriptState.h"
#include "bindings/core/dart/DartUtilities.h"
#include "bindings/core/dart/V8Converter.h"
#include "bindings/core/v8/ScriptFunctionCall.h"
#include "core/inspector/InjectedScriptHost.h"
#include "core/inspector/JSONParser.h"
#include "platform/JSONValues.h"

using blink::TypeBuilder::Array;
using blink::TypeBuilder::Debugger::CallFrame;
using blink::TypeBuilder::Debugger::Location;
using blink::TypeBuilder::Debugger::Scope;
using blink::TypeBuilder::Runtime::PropertyDescriptor;
using blink::TypeBuilder::Runtime::InternalPropertyDescriptor;
using blink::TypeBuilder::Debugger::FunctionDetails;
using blink::TypeBuilder::Runtime::RemoteObject;
using blink::TypeBuilder::Runtime::PropertyPreview;

namespace blink {

Dart_Handle getLibraryUrl(Dart_Handle handle)
{
    intptr_t libraryId = 0;
    Dart_Handle ALLOW_UNUSED result = Dart_LibraryId(handle, &libraryId);
    ASSERT(!Dart_IsError(result));
    Dart_Handle libraryUrl = Dart_GetLibraryURL(libraryId);
    ASSERT(Dart_IsString(libraryUrl));
    return libraryUrl;
}

Dart_Handle getObjectCompletions(Dart_Handle object, Dart_Handle library)
{
    Dart_Handle args[2] = {object, getLibraryUrl(library)};
    return DartUtilities::invokeUtilsMethod("getObjectCompletions", 2, args);
}

Dart_Handle getLibraryCompletions(Dart_Handle library)
{
    Dart_Handle libraryUrl = getLibraryUrl(library);
    return DartUtilities::invokeUtilsMethod("getLibraryCompletions", 1, &libraryUrl);
}

Dart_Handle getLibraryCompletionsIncludingImports(Dart_Handle library)
{
    Dart_Handle libraryUrl = getLibraryUrl(library);
    return DartUtilities::invokeUtilsMethod("getLibraryCompletionsIncludingImports", 1, &libraryUrl);
}

Dart_Handle getObjectProperties(Dart_Handle object, bool ownProperties, bool accessorPropertiesOnly)
{
    Dart_Handle args[3] = {object, DartUtilities::boolToDart(ownProperties), DartUtilities::boolToDart(accessorPropertiesOnly)};
    return DartUtilities::invokeUtilsMethod("getObjectProperties", 3, args);
}

Dart_Handle getObjectPropertySafe(Dart_Handle object, const String& propertyName)
{
    Dart_Handle args[2] = {object, DartUtilities::stringToDartString(propertyName)};
    return DartUtilities::invokeUtilsMethod("getObjectPropertySafe", 2, args);
}

Dart_Handle getObjectClassProperties(Dart_Handle object, bool ownProperties, bool accessorPropertiesOnly)
{
    Dart_Handle args[3] = {object, DartUtilities::boolToDart(ownProperties), DartUtilities::boolToDart(accessorPropertiesOnly)};
    return DartUtilities::invokeUtilsMethod("getObjectClassProperties", 3, args);
}

Dart_Handle getClassProperties(Dart_Handle kind, bool ownProperties, bool accessorPropertiesOnly)
{
    Dart_Handle args[3] = {kind, DartUtilities::boolToDart(ownProperties), DartUtilities::boolToDart(accessorPropertiesOnly)};
    return DartUtilities::invokeUtilsMethod("getClassProperties", 3, args);
}

Dart_Handle getLibraryProperties(Dart_Handle library, bool ownProperties, bool accessorPropertiesOnly)
{
    Dart_Handle args[3] = {getLibraryUrl(library), DartUtilities::boolToDart(ownProperties), DartUtilities::boolToDart(accessorPropertiesOnly)};
    return DartUtilities::invokeUtilsMethod("getLibraryProperties", 3, args);
}

Dart_Handle describeFunction(Dart_Handle function)
{
    return DartUtilities::invokeUtilsMethod("describeFunction", 1, &function);
}

Dart_Handle getInvocationTrampolineDetails(Dart_Handle function)
{
    return DartUtilities::invokeUtilsMethod("getInvocationTrampolineDetails", 1, &function);
}

Dart_Handle findReceiver(Dart_Handle locals)
{
    intptr_t length = 0;
    Dart_Handle ALLOW_UNUSED result = Dart_ListLength(locals, &length);
    ASSERT(!Dart_IsError(result));
    ASSERT(length % 2 == 0);
    String thisStr("this");
    for (intptr_t i = 0; i < length; i+= 2) {
        Dart_Handle name = Dart_ListGetAt(locals, i);
        if (DartUtilities::toString(name) == thisStr) {
            Dart_Handle ret = Dart_ListGetAt(locals, i + 1);
            return Dart_IsNull(ret) ? 0 : ret;
        }
    }
    return 0;
}

Dart_Handle lookupEnclosingType(Dart_Handle functionOwner)
{
    // Walk up the chain of function owners until we reach a type or library
    // handle.
    while (Dart_IsFunction(functionOwner))
        functionOwner = Dart_FunctionOwner(functionOwner);
    return functionOwner;
}

String stripVariableName(const String& name)
{
    size_t index = name.find('@');
    return index == kNotFound ? name : name.left(index);
}

String stripFunctionDescription(const String& description)
{
    size_t index = description.find('{');
    if (index != kNotFound)
        return description.left(index);
    index = description.find(';');
    if (index != kNotFound)
        return description.left(index);
    return description;
}

DartDebuggerObject::DartDebuggerObject(Dart_PersistentHandle h, const String& objectGroup, Kind kind)
    : m_handle(h)
    , m_group(objectGroup)
    , m_kind(kind)
{
}

DartDebuggerObject::~DartDebuggerObject()
{
    Dart_DeletePersistentHandle(m_handle);
}

DartInjectedScript::DartInjectedScript()
    : m_name("DartInjectedScript")
    , m_inspectedStateAccessCheck(0)
    , m_scriptState(0)
    , m_nextObjectId(1)
    , m_host(0)
    , m_consoleApi(0)
{
}

DartInjectedScript::DartInjectedScript(DartScriptState* scriptState, InjectedScriptManager::InspectedStateAccessCheck accessCheck, int injectedScriptId, InjectedScriptHost* host, InjectedScriptManager* injectedScriptManager)
    : m_name("DartInjectedScript")
    , m_inspectedStateAccessCheck(accessCheck)
    , m_scriptState(scriptState)
    , m_nextObjectId(1)
    , m_injectedScriptId(injectedScriptId)
    , m_host(host)
    , m_injectedScriptManager(injectedScriptManager)
    , m_consoleApi(0)
{
}

bool DartInjectedScript::canAccessInspectedWindow() const
{
    return m_inspectedStateAccessCheck(scriptState());
}

bool DartInjectedScript::validateObjectId(const String& objectId)
{
    RefPtr<JSONValue> parsedObjectId = parseJSON(objectId);
    if (parsedObjectId && parsedObjectId->type() == JSONValue::TypeObject) {
        long injectedScriptId = 0;
        bool success = parsedObjectId->asObject()->getNumber("injectedScriptId", &injectedScriptId);
        return success && injectedScriptId == m_injectedScriptId;
    }
    return false;
}

void DartInjectedScript::packageResult(Dart_Handle dartHandle, DartDebuggerObject::Kind kind, const String& objectGroup, ErrorString* errorString, bool returnByValue, bool generatePreview, RefPtr<TypeBuilder::Runtime::RemoteObject>* result, TypeBuilder::OptOutput<bool>* wasThrown)
{
    switch (kind) {
    case DartDebuggerObject::Object:
        packageObjectResult(dartHandle, objectGroup, errorString, returnByValue, generatePreview, result, wasThrown);
        return;
    case DartDebuggerObject::ObjectClass:
        packageObjectClassResult(dartHandle, objectGroup, errorString, returnByValue, generatePreview, result, wasThrown);
        return;
    case DartDebuggerObject::Function:
        packageFunctionResult(dartHandle, objectGroup, errorString, returnByValue, generatePreview, result, wasThrown);
        return;
    case DartDebuggerObject::Method:
        packageMethodResult(dartHandle, objectGroup, errorString, returnByValue, generatePreview, result, wasThrown);
        return;
    case DartDebuggerObject::Class:
    case DartDebuggerObject::StaticClass:
        packageClassResult(dartHandle, kind, objectGroup, errorString, returnByValue, generatePreview, result, wasThrown);
        return;
    case DartDebuggerObject::Library:
    case DartDebuggerObject::CurrentLibrary:
        packageLibraryResult(dartHandle, kind, objectGroup, errorString, returnByValue, generatePreview, result, wasThrown);
        return;
    case DartDebuggerObject::Isolate:
        packageIsolateResult(dartHandle, objectGroup, errorString, returnByValue, generatePreview, result, wasThrown);
        return;
    case DartDebuggerObject::LocalVariables:
        packageLocalVariablesResult(dartHandle, objectGroup, errorString, returnByValue, generatePreview, result, wasThrown);
        return;
    case DartDebuggerObject::Error:
        packageErrorResult(dartHandle, objectGroup, errorString, returnByValue, generatePreview, result, wasThrown);
        return;
    default:
        ASSERT_NOT_REACHED();
    }
}

DartInjectedScript::~DartInjectedScript()
{
    DartIsolateScope scope(m_scriptState->isolate());
    DartApiScope apiScope;

    for (DebuggerObjectMap::iterator it = m_objects.begin(); it != m_objects.end(); ++it) {
        delete it->value;
    }

    if (m_consoleApi)
        Dart_DeletePersistentHandle(m_consoleApi);
}

Dart_Handle DartInjectedScript::consoleApi()
{
    if (!m_consoleApi) {
        Dart_Handle host = DartInjectedScriptHost::toDart(m_host);
        Dart_SetPeer(host, this);
        Dart_Handle consoleApi = DartUtilities::invokeUtilsMethod("consoleApi", 1, &host);
        ASSERT(!Dart_IsError(consoleApi));
        m_consoleApi = Dart_NewPersistentHandle(consoleApi);
    }
    return m_consoleApi;
}

Dart_Handle DartInjectedScript::evaluateHelper(Dart_Handle target, const String& rawExpression, Dart_Handle localVariables, bool includeCommandLineAPI, Dart_Handle& exception)
{
    DartDOMData* ALLOW_UNUSED domData = DartDOMData::current();
    ASSERT(domData);
    ASSERT(Dart_IsList(localVariables) || Dart_IsNull(localVariables));

    Dart_Handle expression = DartUtilities::stringToDart(rawExpression);

    if (includeCommandLineAPI) {
        ASSERT(m_host);
        // Vector of local variables and injected console variables.
        Vector<Dart_Handle> locals;
        if (Dart_IsList(localVariables)) {
            DartUtilities::extractListElements(localVariables, exception, locals);
            ASSERT(!exception);
        }

        ScriptState* v8ScriptState = DartUtilities::v8ScriptStateForCurrentIsolate();
        for (unsigned i = 0; i < 6; i++) {
            ScriptValue value =  m_host->inspectedObject(i)->get(v8ScriptState);
            v8::TryCatch tryCatch;
            v8::Handle<v8::Value> v8Value = value.v8Value();
            if (v8Value.IsEmpty())
                break;
            Dart_Handle dartValue = DartHandleProxy::unwrapValue(v8Value);
            ASSERT(!Dart_IsError(dartValue));
            if (Dart_IsNull(dartValue))
                continue;
            locals.append(DartUtilities::stringToDartString(String::format("$%d", i)));
            locals.append(dartValue);
        }

        Dart_Handle list = consoleApi();
        intptr_t length = 0;
        ASSERT(Dart_IsList(list));
        Dart_Handle ALLOW_UNUSED ret = Dart_ListLength(list, &length);
        ASSERT(!(length % 2));
        ASSERT(!Dart_IsError(ret));
        for (intptr_t i = 0; i < length; i += 2) {
            Dart_Handle name = Dart_ListGetAt(list, i);
            ASSERT(Dart_IsString(name));
            locals.append(name);
            Dart_Handle value = Dart_ListGetAt(list, i+1);
            ASSERT(!Dart_IsError(value));
            locals.append(value);
        }
        localVariables = DartUtilities::toList(locals, exception);
        ASSERT(!exception);
    }

    Dart_Handle wrapExpressionArgs[3] = { expression, localVariables, DartUtilities::boolToDart(includeCommandLineAPI) };
    Dart_Handle wrappedExpressionTuple =
        DartUtilities::invokeUtilsMethod("wrapExpressionAsClosure", 3, wrapExpressionArgs);
    ASSERT(Dart_IsList(wrappedExpressionTuple));
    Dart_Handle wrappedExpression = Dart_ListGetAt(wrappedExpressionTuple, 0);
    Dart_Handle wrappedExpressionArgs = Dart_ListGetAt(wrappedExpressionTuple, 1);
    // TODO(jacobr): replace most of this logic with Dart_ActivationFrameEvaluate.

    ASSERT(Dart_IsString(wrappedExpression));
    Dart_Handle closure = Dart_EvaluateExpr(target, wrappedExpression);
    // There was a parse error. FIXME: consider cleaning up the line numbers in
    // the error message.
    if (Dart_IsError(closure)) {
        exception = closure;
        return 0;
    }

    // Invoke the closure passing in the expression arguments specified by
    // wrappedExpressionTuple.
    ASSERT(DartUtilities::isFunction(domData, closure));
    intptr_t length = 0;
    Dart_ListLength(wrappedExpressionArgs, &length);
    Vector<Dart_Handle> dartFunctionArgs;
    for (intptr_t i = 0; i < length; i ++)
        dartFunctionArgs.append(Dart_ListGetAt(wrappedExpressionArgs, i));

    Dart_Handle result = Dart_InvokeClosure(closure, dartFunctionArgs.size(), dartFunctionArgs.data());
    if (Dart_IsError(result)) {
        exception = result;
        return Dart_Null();
    }
    return result;
}

void DartInjectedScript::evaluateAndPackageResult(Dart_Handle target, const String& rawExpression, Dart_Handle localVariables, bool includeCommandLineAPI, const String& objectGroup, ErrorString* errorString, bool returnByValue, bool generatePreview, RefPtr<TypeBuilder::Runtime::RemoteObject>* result, TypeBuilder::OptOutput<bool>* wasThrown, RefPtr<TypeBuilder::Debugger::ExceptionDetails>* exceptionDetails)
{
    Dart_Handle exception = 0;
    {
        Dart_Handle evalResult = evaluateHelper(target, rawExpression, localVariables, includeCommandLineAPI, exception);
        if (exception)
            goto fail;
        packageResult(evalResult, inferKind(evalResult), objectGroup, errorString, returnByValue, generatePreview, result, wasThrown);
        return;
    }
fail:
    ASSERT(exception);
    packageResult(exception, DartDebuggerObject::Error, objectGroup, errorString, returnByValue, generatePreview, result, wasThrown);
    ASSERT(Dart_IsError(exception));
    if (exceptionDetails) {
        *exceptionDetails = TypeBuilder::Debugger::ExceptionDetails::create().setText(Dart_GetError(exception)).release();
        Dart_StackTrace trace;
        Dart_Handle ALLOW_UNUSED ret = Dart_GetStackTraceFromError(exception, &trace);
        if (Dart_IsInstance(ret)) {
            // Only unhandled exception error handles have stacktraces.
            (*exceptionDetails)->setStackTrace(consoleCallFrames(trace));
        }
    }
}

PassRefPtr<Array<TypeBuilder::Console::CallFrame> > DartInjectedScript::consoleCallFrames(Dart_StackTrace trace)
{
    intptr_t length = 0;
    Dart_Handle ALLOW_UNUSED result;
    RefPtr<Array<TypeBuilder::Console::CallFrame> > ret = Array<TypeBuilder::Console::CallFrame>::create();
    result = Dart_StackTraceLength(trace, &length);
    ASSERT(!Dart_IsError(result));
    DartScriptDebugServer& debugServer = DartScriptDebugServer::shared();
    for (intptr_t i = 0; i < length; i++) {
        Dart_ActivationFrame frame = 0;
        result = Dart_GetActivationFrame(trace, i, &frame);
        ASSERT(!Dart_IsError(result));
        Dart_Handle functionName = 0;
        Dart_CodeLocation location;
        Dart_ActivationFrameGetLocation(frame, &functionName, 0, &location);
        const String& url = DartUtilities::toString(location.script_url);
        intptr_t line = 0;
        intptr_t column = 0;
        Dart_ActivationFrameInfo(frame, 0, 0, &line, &column);

        ret->addItem(TypeBuilder::Console::CallFrame::create()
            .setFunctionName(DartUtilities::toString(functionName))
            .setScriptId(debugServer.getScriptId(url, Dart_CurrentIsolate()))
            .setUrl(url)
            .setLineNumber(line-1)
            .setColumnNumber(column)
            .release());
    }
    return ret;
}

void DartInjectedScript::packageObjectResult(Dart_Handle dartHandle, const String& objectGroup, ErrorString* errorString, bool returnByValue, bool generatePreview, RefPtr<TypeBuilder::Runtime::RemoteObject>* result, TypeBuilder::OptOutput<bool>* wasThrown)
{
    ASSERT(Dart_IsInstance(dartHandle) || Dart_IsNull(dartHandle));

    // FIXMEDART: support returnByValue for Dart types that are expressible as JSON.
    bool wasThrownVal = false;
    Dart_Handle exception = 0;
    if (Dart_IsError(dartHandle)) {
        wasThrownVal = true;
        Dart_Handle exception = Dart_ErrorGetException(dartHandle);
        ASSERT(Dart_IsInstance(exception));
        if (!Dart_IsInstance(exception)) {
            *errorString = Dart_GetError(dartHandle);
            return;
        }
        dartHandle = exception;
    }

    // Primitive value
    RefPtr<JSONValue> value = nullptr;
    TypeBuilder::Runtime::RemoteObject::Type::Enum remoteObjectType = TypeBuilder::Runtime::RemoteObject::Type::Object;
    ASSERT(Dart_IsInstance(dartHandle) || Dart_IsNull(dartHandle));

    if (Dart_IsNull(dartHandle)) {
        value = JSONValue::null();
    } else {
        if (Dart_IsString(dartHandle)) {
            remoteObjectType = TypeBuilder::Runtime::RemoteObject::Type::String;
            value = JSONString::create(DartUtilities::toString(dartHandle));
        } else if (Dart_IsDouble(dartHandle)) {
            // FIXMEDART: add an extra entry for int?
            remoteObjectType = TypeBuilder::Runtime::RemoteObject::Type::Number;
            value = JSONBasicValue::create(DartUtilities::dartToDouble(dartHandle, exception));
            ASSERT(!exception);
        } else if (Dart_IsNumber(dartHandle)) {
            // FIXMEDART: handle ints that are larger than 50 bits.
            remoteObjectType = TypeBuilder::Runtime::RemoteObject::Type::Number;
            value = JSONBasicValue::create(DartUtilities::dartToDouble(dartHandle, exception));
            ASSERT(!exception);
        } else if (Dart_IsBoolean(dartHandle)) {
            remoteObjectType = TypeBuilder::Runtime::RemoteObject::Type::Boolean;
            value = JSONBasicValue::create(DartUtilities::dartToBool(dartHandle, exception));
            ASSERT(!exception);
        }
    }

    String typeName;
    String description;
    bool isNode = false;
    if (Dart_IsNull(dartHandle)) {
        typeName = "null";
        description = "null";
    } else {
        Dart_Handle dartType = Dart_InstanceGetType(dartHandle);
        Dart_Handle typeNameHandle = Dart_TypeName(dartType);
        ASSERT(!Dart_IsError(typeNameHandle));
        typeName = DartUtilities::dartToString(typeNameHandle, exception);
        description = DartUtilities::dartToString(Dart_ToString(dartHandle), exception);
        if (exception) {
            description = String::format("Instance of '%s'", typeName.utf8().data());
            exception = 0;
        }
        ASSERT(!exception);
        if (DartDOMWrapper::subtypeOf(dartHandle, DartNode::dartClassId))
            isNode = true;
    }

    RefPtr<RemoteObject> remoteObject = TypeBuilder::Runtime::RemoteObject::create().setType(remoteObjectType).release();
    remoteObject->setLanguage("Dart");
    remoteObject->setClassName(typeName);
    remoteObject->setDescription(description);
    if (value)
        remoteObject->setValue(value);

    if (isNode)
        remoteObject->setSubtype(RemoteObject::Subtype::Node);

    // FIXMEDART: generate preview if generatePreview is true.
    String objectId = cacheObject(dartHandle, objectGroup, DartDebuggerObject::Object);
    remoteObject->setObjectId(objectId);
    *result = remoteObject;
    if (wasThrown) {
        *wasThrown = exception || wasThrownVal;
    }
}

void DartInjectedScript::packageObjectClassResult(Dart_Handle dartHandle, const String& objectGroup, ErrorString* errorString, bool returnByValue, bool generatePreview, RefPtr<TypeBuilder::Runtime::RemoteObject>* result, TypeBuilder::OptOutput<bool>* wasThrown)
{
    ASSERT(Dart_IsInstance(dartHandle) || Dart_IsNull(dartHandle));
    bool wasThrownVal = false;
    Dart_Handle exception = 0;

    RefPtr<RemoteObject> remoteObject = TypeBuilder::Runtime::RemoteObject::create().setType(TypeBuilder::Runtime::RemoteObject::Type::Object).release();
    remoteObject->setLanguage("Dart");

    Dart_Handle typeHandle = Dart_InstanceGetType(dartHandle);
    String typeName = DartUtilities::toString(Dart_TypeName(typeHandle));

    remoteObject->setClassName(typeName);
    remoteObject->setDescription(typeName);

    // Don't generate a preview for types.
    String objectId = cacheObject(dartHandle, objectGroup, DartDebuggerObject::ObjectClass);
    remoteObject->setObjectId(objectId);
    *result = remoteObject;
    if (wasThrown)
        *wasThrown = exception || wasThrownVal;
}

void DartInjectedScript::packageClassResult(Dart_Handle dartHandle, DartDebuggerObject::Kind kind, const String& objectGroup, ErrorString* errorString, bool returnByValue, bool generatePreview, RefPtr<TypeBuilder::Runtime::RemoteObject>* result, TypeBuilder::OptOutput<bool>* wasThrown)
{
    bool wasThrownVal = false;
    Dart_Handle exception = 0;

    RefPtr<RemoteObject> remoteObject = TypeBuilder::Runtime::RemoteObject::create().setType(TypeBuilder::Runtime::RemoteObject::Type::Object).release();
    remoteObject->setLanguage("Dart");
    String typeName = DartUtilities::toString(Dart_TypeName(dartHandle));
    String typeDescription("class ");
    typeDescription.append(typeName);

    remoteObject->setClassName(typeName);
    remoteObject->setDescription(typeDescription);

    // Don't generate a preview for types.
    String objectId = cacheObject(dartHandle, objectGroup, kind);
    remoteObject->setObjectId(objectId);
    *result = remoteObject;
    if (wasThrown)
        *wasThrown = exception || wasThrownVal;
}

void DartInjectedScript::packageFunctionResult(Dart_Handle dartHandle, const String& objectGroup, ErrorString* errorString, bool returnByValue, bool generatePreview, RefPtr<TypeBuilder::Runtime::RemoteObject>* result, TypeBuilder::OptOutput<bool>* wasThrown)
{
    ASSERT(DartUtilities::isFunction(DartDOMData::current(), dartHandle));
    bool wasThrownVal = false;
    Dart_Handle exception = 0;

    RefPtr<RemoteObject> remoteObject = TypeBuilder::Runtime::RemoteObject::create().setType(TypeBuilder::Runtime::RemoteObject::Type::Function).release();
    remoteObject->setLanguage("Dart");
    remoteObject->setClassName("<Dart Function>");
    remoteObject->setDescription(stripFunctionDescription(DartUtilities::toString(describeFunction(dartHandle))));

    String objectId = cacheObject(dartHandle, objectGroup, DartDebuggerObject::Function);
    remoteObject->setObjectId(objectId);
    *result = remoteObject;
    if (wasThrown) {
        *wasThrown = exception || wasThrownVal;
    }
}

void DartInjectedScript::packageMethodResult(Dart_Handle dartHandle, const String& objectGroup, ErrorString* errorString, bool returnByValue, bool generatePreview, RefPtr<TypeBuilder::Runtime::RemoteObject>* result, TypeBuilder::OptOutput<bool>* wasThrown)
{
    ASSERT(DartUtilities::isFunction(DartDOMData::current(), dartHandle));
    bool wasThrownVal = false;
    Dart_Handle exception = 0;

    RefPtr<RemoteObject> remoteObject = TypeBuilder::Runtime::RemoteObject::create().setType(TypeBuilder::Runtime::RemoteObject::Type::Function).release();
    remoteObject->setLanguage("Dart");
    remoteObject->setClassName("<Dart Method>");
    remoteObject->setDescription(stripFunctionDescription(DartUtilities::toString(describeFunction(dartHandle))));

    String objectId = cacheObject(dartHandle, objectGroup, DartDebuggerObject::Method);
    remoteObject->setObjectId(objectId);
    *result = remoteObject;
    if (wasThrown)
        *wasThrown = exception || wasThrownVal;
}

void DartInjectedScript::packageLocalVariablesResult(Dart_Handle dartHandle, const String& objectGroup, ErrorString* errorString, bool returnByValue, bool generatePreview, RefPtr<TypeBuilder::Runtime::RemoteObject>* result, TypeBuilder::OptOutput<bool>* wasThrown)
{
    bool wasThrownVal = false;
    Dart_Handle exception = 0;

    RefPtr<RemoteObject> remoteObject = TypeBuilder::Runtime::RemoteObject::create().setType(TypeBuilder::Runtime::RemoteObject::Type::Object).release();
    remoteObject->setLanguage("Dart");
    remoteObject->setClassName("Object");
    remoteObject->setDescription("Local Variables");

    String objectId = cacheObject(dartHandle, objectGroup, DartDebuggerObject::LocalVariables);
    remoteObject->setObjectId(objectId);
    *result = remoteObject;
    if (wasThrown)
        *wasThrown = exception || wasThrownVal;
}

void DartInjectedScript::packageErrorResult(Dart_Handle dartHandle, const String& objectGroup, ErrorString* errorString, bool returnByValue, bool generatePreview, RefPtr<TypeBuilder::Runtime::RemoteObject>* result, TypeBuilder::OptOutput<bool>* wasThrown)
{
    ASSERT(Dart_IsError(dartHandle));
    RefPtr<RemoteObject> remoteObject = TypeBuilder::Runtime::RemoteObject::create().setType(TypeBuilder::Runtime::RemoteObject::Type::Object).release();
    remoteObject->setLanguage("Dart");
    remoteObject->setClassName("Error");
    remoteObject->setDescription(Dart_GetError(dartHandle));

    Dart_Handle exception = Dart_ErrorGetException(dartHandle);
    String objectId = cacheObject(exception, objectGroup, DartDebuggerObject::Error);
    remoteObject->setObjectId(objectId);
    *result = remoteObject;
    if (wasThrown)
        *wasThrown = true;
}

void DartInjectedScript::packageLibraryResult(Dart_Handle dartHandle, DartDebuggerObject::Kind kind, const String& objectGroup, ErrorString* errorString, bool returnByValue, bool generatePreview, RefPtr<TypeBuilder::Runtime::RemoteObject>* result, TypeBuilder::OptOutput<bool>* wasThrown)
{
    ASSERT(Dart_IsLibrary(dartHandle));
    bool wasThrownVal = false;
    intptr_t libraryId = 0;
    Dart_Handle exception = 0;
    Dart_Handle ALLOW_UNUSED ret;
    ret = Dart_LibraryId(dartHandle, &libraryId);
    ASSERT(!Dart_IsError(ret));

    // FIXMEDART: Demangle library name.
    String libraryName = DartUtilities::toString(Dart_LibraryName(dartHandle));
    String libraryUri = DartUtilities::toString(Dart_GetLibraryURL(libraryId));
    if (libraryName == "")
        libraryName = libraryUri;

    RefPtr<RemoteObject> remoteObject = TypeBuilder::Runtime::RemoteObject::create().setType(TypeBuilder::Runtime::RemoteObject::Type::Object).release();
    remoteObject->setLanguage("Dart");
    remoteObject->setClassName(libraryUri);
    remoteObject->setDescription(libraryName);
    String objectId = cacheObject(dartHandle, objectGroup, kind);
    remoteObject->setObjectId(objectId);
    *result = remoteObject;
    if (wasThrown)
        *wasThrown = exception || wasThrownVal;
}

void DartInjectedScript::packageIsolateResult(Dart_Handle dartHandle, const String& objectGroup, ErrorString* errorString, bool returnByValue, bool generatePreview, RefPtr<TypeBuilder::Runtime::RemoteObject>* result, TypeBuilder::OptOutput<bool>* wasThrown)
{
    RefPtr<RemoteObject> remoteObject = TypeBuilder::Runtime::RemoteObject::create().setType(TypeBuilder::Runtime::RemoteObject::Type::Object).release();

    String isolateName = DartUtilities::toString(Dart_DebugName());

    remoteObject->setLanguage("Dart");
    remoteObject->setClassName("Dart Isolate");
    remoteObject->setDescription(isolateName);
    String objectId = cacheObject(dartHandle, objectGroup, DartDebuggerObject::Isolate);
    remoteObject->setObjectId(objectId);
    *result = remoteObject;
}

Dart_Handle DartInjectedScript::library()
{
    ASSERT(m_scriptState);
    return Dart_GetLibraryFromId(m_scriptState->libraryId());
}

void DartInjectedScript::evaluate(ErrorString* errorString, const String& expression, const String& objectGroup, bool includeCommandLineAPI, bool returnByValue, bool generatePreview, RefPtr<TypeBuilder::Runtime::RemoteObject>* result, TypeBuilder::OptOutput<bool>* wasThrown, RefPtr<TypeBuilder::Debugger::ExceptionDetails>* exceptionDetails)
{
    if (!m_scriptState) {
        *errorString = "Invalid DartInjectedScript";
        return;
    }
    DartIsolateScope scope(m_scriptState->isolate());
    DartApiScope apiScope;
    V8Scope v8scope(DartDOMData::current());
    evaluateAndPackageResult(library(), expression, Dart_Null(), includeCommandLineAPI, objectGroup, errorString, returnByValue, generatePreview, result, wasThrown, exceptionDetails);
}

void DartInjectedScript::callFunctionOn(ErrorString* errorString, const String& objectId, const String& expression, const String& arguments, bool returnByValue, bool generatePreview, RefPtr<TypeBuilder::Runtime::RemoteObject>* result, TypeBuilder::OptOutput<bool>* wasThrown)
{
    Dart_Handle exception = 0;
    String objectGroup;
    if (!m_scriptState) {
        *errorString = "Invalid DartInjectedScript";
        return;
    }
    DartIsolateScope scope(m_scriptState->isolate());
    DartApiScope apiScope;
    {
        DartDebuggerObject* object = lookupObject(objectId);
        if (!object) {
            *errorString = "Object has been deleted";
            return;
        }
        objectGroup = object->group();
        Vector<Dart_Handle> dartFunctionArgs;
        if (arguments.length()) {
            RefPtr<JSONValue> parsedArguments = parseJSON(arguments);
            if (!parsedArguments.get()) {
                *errorString = "Unable to parse arguments json";
                return;
            }
            if (!parsedArguments->isNull()) {
                if (parsedArguments->type() != JSONValue::TypeArray) {
                    *errorString = "Invalid arguments";
                    return;
                }
                RefPtr<JSONArray> argumentsArray = parsedArguments->asArray();
                for (JSONArray::iterator it = argumentsArray->begin(); it != argumentsArray->end(); ++it) {
                    RefPtr<JSONObject> arg;
                    if (!(*it)->asObject(&arg)) {
                        *errorString = "Invalid argument passed to callFunctionOn";
                        return;
                    }
                    String argObjectId;

                    if (!arg->getString("objectId", &argObjectId)) {
                        // FIXME: support primitive values passed as arguments as well.
                        *errorString = "Unspecified object id";
                    }

                    DartDebuggerObject* argObject = lookupObject(argObjectId);
                    if (!argObject) {
                        *errorString = "Argument has been deleted";
                        return;
                    }
                    dartFunctionArgs.append(argObject->handle());
                }
            }
        }

        Dart_Handle dartClosure = evaluateHelper(object->handle(), expression, Dart_Null(), false, exception);
        if (exception)
            goto fail;

        if (Dart_IsError(dartClosure)) {
            *errorString = Dart_GetError(dartClosure);
            return;
        }
        if (!Dart_IsClosure(dartClosure)) {
            *errorString = "Given expression does not evaluate to a closure";
            return;
        }
        Dart_Handle evalResult = Dart_InvokeClosure(dartClosure, dartFunctionArgs.size(), dartFunctionArgs.data());
        packageResult(evalResult, inferKind(evalResult), objectGroup, errorString, returnByValue, generatePreview, result, wasThrown);
        return;
    }
fail:
    ASSERT(exception);
    packageResult(exception, DartDebuggerObject::Error, objectGroup, errorString, returnByValue, generatePreview, result, wasThrown);


}

void DartInjectedScript::evaluateOnCallFrame(ErrorString* errorString, const Dart_StackTrace callFrames, const String& callFrameId, const String& expression, const String& objectGroup, bool includeCommandLineAPI, bool returnByValue, bool generatePreview, RefPtr<RemoteObject>* result, TypeBuilder::OptOutput<bool>* wasThrown, RefPtr<TypeBuilder::Debugger::ExceptionDetails>* exceptionDetails)
{
    DartIsolateScope scope(m_scriptState->isolate());
    DartApiScope apiScope;
    // FIXMEDART: add v8Scope calls elsewhere.
    V8Scope v8scope(DartDOMData::current());

    Dart_ActivationFrame frame = callFrameForId(callFrames, callFrameId);
    ASSERT(frame);
    if (!frame) {
        *errorString = "Call frame not found";
        return;
    }

    Dart_Handle function = 0;
    Dart_ActivationFrameGetLocation(frame, 0, &function, 0);
    ASSERT(function);
    Dart_Handle localVariables = Dart_GetLocalVariables(frame);
    Dart_Handle thisHandle = findReceiver(localVariables);
    Dart_Handle context = thisHandle ? thisHandle : lookupEnclosingType(function);
    evaluateAndPackageResult(context, expression, localVariables, includeCommandLineAPI, objectGroup, errorString, returnByValue, generatePreview, result, wasThrown, exceptionDetails);
}

void DartInjectedScript::restartFrame(ErrorString* errorString, const Dart_StackTrace callFrames, const String& callFrameId, RefPtr<JSONObject>* result)
{
    *errorString = "Dart does not yet support restarting call frames";
    return;
}

void DartInjectedScript::setVariableValue(ErrorString* errorString, const Dart_StackTrace callFrames, const String* callFrameIdOpt, const String* functionObjectIdOpt, int scopeNumber, const String& variableName, const String& newValueStr)
{
    if (!m_scriptState) {
        *errorString = "Invalid DartInjectedScript";
        return;
    }
    DartIsolateScope scope(m_scriptState->isolate());
    DartApiScope apiScope;
    *errorString = "Not supported by Dart.";
    return;
}

void DartInjectedScript::getFunctionDetails(ErrorString* errorString, const String& functionId, RefPtr<FunctionDetails>* result)
{
    if (!m_scriptState) {
        *errorString = "Invalid DartInjectedScript";
        return;
    }
    DartIsolateScope scope(m_scriptState->isolate());
    DartApiScope apiScope;
    DartDebuggerObject* object = lookupObject(functionId);
    if (!object) {
        *errorString = "Object has been deleted";
        return;
    }

    int line = 0;
    int column = 0;
    DartScriptDebugServer& debugServer = DartScriptDebugServer::shared();
    Dart_Handle url;
    Dart_Handle name = 0;
    Dart_Handle exception = 0;

    switch (object->kind()) {
    case DartDebuggerObject::Function: {
        Dart_CodeLocation location;
        Dart_Handle ret = Dart_GetClosureInfo(object->handle(), &name, 0, &location);
        if (Dart_IsError(ret) || !debugServer.resolveCodeLocation(location, &line, &column)) {
            // Avoid returning an error for this case which can legitimately
            // occur if the function was the result of calling Dart_EvaluateExpr.
            RefPtr<Location> locationJson = Location::create()
                .setScriptId("INVALID_SCRIPT_ID")
                .setLineNumber(0);
            *result = FunctionDetails::create().setLocation(locationJson).setFunctionName("DartClosure").release();
            return;
        }
        url = location.script_url;
        break;
    }
    case DartDebuggerObject::Method:
        {
            Dart_Handle ret = getInvocationTrampolineDetails(object->handle());

            if (Dart_IsError(ret)) {
                *errorString = Dart_GetError(ret);
                return;
            }
            ASSERT(Dart_IsList(ret));
            line = DartUtilities::toInteger(Dart_ListGetAt(ret, 0), exception);
            column = DartUtilities::toInteger(Dart_ListGetAt(ret, 1), exception);
            url = Dart_ListGetAt(ret, 2);
            name = Dart_ListGetAt(ret, 3);
            break;
        }
    default:
        *errorString = "Object is not a function.";
        return;
    }

    ASSERT(!exception);

    RefPtr<Location> locationJson = Location::create()
        .setScriptId(debugServer.getScriptId(DartUtilities::toString(url), Dart_CurrentIsolate()))
        .setLineNumber(line - 1);
    locationJson->setColumnNumber(column);

    *result = FunctionDetails::create().setLocation(locationJson).setFunctionName(DartUtilities::toString(name)).release();
}

void addCompletions(Dart_Handle completions, RefPtr<TypeBuilder::Array<String> >* result)
{
    ASSERT(Dart_IsList(completions));
    intptr_t length = 0;
    Dart_ListLength(completions, &length);
    for (intptr_t i = 0; i < length; ++i)
        (*result)->addItem(DartUtilities::toString(Dart_ListGetAt(completions, i)));
}

void DartInjectedScript::getCompletionsOnCallFrame(ErrorString* errorString, const Dart_StackTrace callFrames, const String& callFrameId, const String& expression, RefPtr<TypeBuilder::Array<String> >* result)
{
    *result = TypeBuilder::Array<String>::create();
    if (!m_scriptState) {
        *errorString = "Invalid DartInjectedScript";
        return;
    }
    DartIsolateScope scope(m_scriptState->isolate());
    DartApiScope apiScope;
    V8Scope v8scope(DartDOMData::current());

    Dart_ActivationFrame frame = callFrameForId(callFrames, callFrameId);
    ASSERT(frame);
    if (!frame) {
        *errorString = "Call frame not found";
        return;
    }

    Dart_Handle function = 0;
    Dart_ActivationFrameGetLocation(frame, 0, &function, 0);
    ASSERT(function);
    Dart_Handle localVariables = Dart_GetLocalVariables(frame);
    Dart_Handle thisHandle = findReceiver(localVariables);
    Dart_Handle enclosingType = lookupEnclosingType(function);
    Dart_Handle context = thisHandle ? thisHandle : enclosingType;

    if (expression.isEmpty()) {
        addCompletions(getLibraryCompletionsIncludingImports(library()), result);
        if (!Dart_IsLibrary(context)) {
            addCompletions(getObjectCompletions(context, library()), result);
        }
        if (context != enclosingType) {
            addCompletions(getObjectCompletions(enclosingType, library()), result);
        }
        intptr_t length = 0;
        Dart_ListLength(localVariables, &length);
        for (intptr_t i = 0; i < length; i += 2)
            (*result)->addItem(stripVariableName(DartUtilities::toString(Dart_ListGetAt(localVariables, i))));
    } else {
        // FIXME: we can do better than evaluating the expression and getting
        // all completions for that object if an exception is not thrown. For
        // example run the Dart Analyzer to get completions of complex
        // expressions without triggering side effects or failing for
        // expressions that do not evaluate to a first class object. For
        // example, the html library is imported with prefix html and the
        // expression html is used.
        Dart_Handle exception = 0;
        Dart_Handle handle = evaluateHelper(context, expression, localVariables, true, exception);

        // No completions if the expression cannot be evaluated.
        if (exception)
            return;
        addCompletions(getObjectCompletions(handle, library()), result);
    }
}

void DartInjectedScript::getCompletions(ErrorString* errorString, const String& expression, RefPtr<TypeBuilder::Array<String> >* result)
{
    *result = TypeBuilder::Array<String>::create();

    if (!m_scriptState) {
        *errorString = "Invalid DartInjectedScript";
        return;
    }
    DartIsolateScope scope(m_scriptState->isolate());
    DartApiScope apiScope;
    V8Scope v8scope(DartDOMData::current());

    Dart_Handle completions;
    if (expression.isEmpty()) {
        completions = getLibraryCompletionsIncludingImports(library());
    } else {
        // FIXME: we can do better than evaluating the expression and getting
        // all completions for that object if an exception is not thrown. For
        // example run the Dart Analyzer to get completions of complex
        // expressions without triggering side effects or failing for
        // expressions that do not evaluate to a first class object. For
        // example, the html library is imported with prefix html and the
        // expression html is used.
        Dart_Handle exception = 0;
        Dart_Handle handle = evaluateHelper(library(), expression, Dart_Null(), true, exception);
        // No completions if the expression cannot be evaluated.
        if (exception)
            return;
        completions = getObjectCompletions(handle, library());
    }

    addCompletions(completions, result);
}

void DartInjectedScript::getProperties(ErrorString* errorString, const String& objectId, bool ownProperties, bool accessorPropertiesOnly, RefPtr<Array<PropertyDescriptor> >* properties)
{
    Dart_Handle exception = 0;
    if (!m_scriptState) {
        *errorString = "Invalid DartInjectedScript";
        return;
    }
    DartIsolateScope scope(m_scriptState->isolate());
    DartApiScope apiScope;

    DartDebuggerObject* object = lookupObject(objectId);
    if (!object) {
        *errorString = "Unknown objectId";
        return;
    }
    Dart_Handle handle = object->handle();
    String objectGroup = object->group();

    *properties = Array<PropertyDescriptor>::create();
    Dart_Handle propertiesList;
    switch (object->kind()) {
    case DartDebuggerObject::Object:
    case DartDebuggerObject::Function:
    case DartDebuggerObject::Error:
        propertiesList = getObjectProperties(handle, ownProperties, accessorPropertiesOnly);
        break;
    case DartDebuggerObject::ObjectClass:
        propertiesList = getObjectClassProperties(handle, ownProperties, accessorPropertiesOnly);
        break;
    case DartDebuggerObject::Method:
        // There aren't any meaningful properties to display for a Dart method.
        return;
    case DartDebuggerObject::Class:
    case DartDebuggerObject::StaticClass:
        propertiesList = getClassProperties(handle, ownProperties, accessorPropertiesOnly);
        break;
    case DartDebuggerObject::Library:
    case DartDebuggerObject::CurrentLibrary:
        propertiesList = getLibraryProperties(handle, ownProperties, accessorPropertiesOnly);
        break;
    case DartDebuggerObject::LocalVariables:
        {
            if (accessorPropertiesOnly)
                return;
            ASSERT(Dart_IsList(handle));
            intptr_t length = 0;
            Dart_Handle ALLOW_UNUSED ret = Dart_ListLength(handle, &length);
            ASSERT(!Dart_IsError(ret));
            for (intptr_t i = 0; i < length; i += 2) {
                const String& name = stripVariableName(DartUtilities::toString(Dart_ListGetAt(handle, i)));
                Dart_Handle value = Dart_ListGetAt(handle, i + 1);
                RefPtr<PropertyDescriptor> descriptor = PropertyDescriptor::create().setName(name).setConfigurable(false).setEnumerable(true).release();
                descriptor->setValue(wrapDartHandle(value, inferKind(value), objectGroup, false));
                descriptor->setWritable(false);
                descriptor->setWasThrown(false);
                descriptor->setIsOwn(true);
                (*properties)->addItem(descriptor);
            }
            return;
        }
    case DartDebuggerObject::Isolate:
        {
            if (accessorPropertiesOnly)
                return;

            Dart_Handle libraries = handle;
            ASSERT(Dart_IsList(libraries));

            intptr_t librariesLength = 0;
            Dart_Handle ALLOW_UNUSED result = Dart_ListLength(libraries, &librariesLength);
            ASSERT(!Dart_IsError(result));
            for (intptr_t i = 0; i < librariesLength; ++i) {
                Dart_Handle libraryIdHandle = Dart_ListGetAt(libraries, i);
                ASSERT(!Dart_IsError(libraryIdHandle));
                Dart_Handle exception = 0;
                int64_t libraryId = DartUtilities::toInteger(libraryIdHandle, exception);
                const String& name = DartUtilities::toString(Dart_GetLibraryURL(libraryId));
                RefPtr<PropertyDescriptor> descriptor = PropertyDescriptor::create().setName(name).setConfigurable(false).setEnumerable(true).release();
                descriptor->setValue(wrapDartHandle(Dart_GetLibraryFromId(libraryId), DartDebuggerObject::Library, objectGroup, false));
                descriptor->setWritable(false);
                descriptor->setWasThrown(false);
                descriptor->setIsOwn(true);
                (*properties)->addItem(descriptor);
                ASSERT(!exception);
            }
            return;
        }
    default:
        ASSERT_NOT_REACHED();
        *errorString = "Internal error";
        return;
    }

    if (Dart_IsError(propertiesList)) {
        *errorString = Dart_GetError(propertiesList);
        return;
    }

    ASSERT(Dart_IsList(propertiesList));
    intptr_t length = 0;
    Dart_Handle ALLOW_UNUSED ret = Dart_ListLength(propertiesList, &length);
    ASSERT(!Dart_IsError(ret));
    ASSERT(!(length % 9));
    for (intptr_t i = 0; i < length; i += 9) {
        String name = DartUtilities::toString(Dart_ListGetAt(propertiesList, i));
        Dart_Handle setter = Dart_ListGetAt(propertiesList, i + 1);
        Dart_Handle getter = Dart_ListGetAt(propertiesList, i + 2);
        Dart_Handle value = Dart_ListGetAt(propertiesList, i + 3);
        bool hasValue = DartUtilities::dartToBool(Dart_ListGetAt(propertiesList, i + 4), exception);
        ASSERT(!exception);
        bool writable = DartUtilities::dartToBool(Dart_ListGetAt(propertiesList, i + 5), exception);
        ASSERT(!exception);
        bool isMethod = DartUtilities::dartToBool(Dart_ListGetAt(propertiesList, i + 6), exception);
        ASSERT(!exception);
        bool isOwn = DartUtilities::dartToBool(Dart_ListGetAt(propertiesList, i + 7), exception);
        ASSERT(!exception);
        bool wasThrown = DartUtilities::dartToBool(Dart_ListGetAt(propertiesList, i + 8), exception);
        ASSERT(!exception);
        RefPtr<PropertyDescriptor> descriptor = PropertyDescriptor::create().setName(name).setConfigurable(false).setEnumerable(true).release();
        if (isMethod) {
            ASSERT(hasValue);
            descriptor->setValue(wrapDartHandle(value, DartDebuggerObject::Method, objectGroup, false));
        } else {
            if (hasValue)
                descriptor->setValue(wrapDartHandle(value, inferKind(value), objectGroup, false));
            if (!Dart_IsNull(setter))
                descriptor->setSet(wrapDartHandle(setter, DartDebuggerObject::Method, objectGroup, false));
            if (!Dart_IsNull(getter))
                descriptor->setGet(wrapDartHandle(getter, DartDebuggerObject::Method, objectGroup, false));
        }
        descriptor->setWritable(writable);
        descriptor->setWasThrown(wasThrown);
        descriptor->setIsOwn(isOwn);

        (*properties)->addItem(descriptor);
    }

    if (object->kind() == DartDebuggerObject::Object && !accessorPropertiesOnly && !Dart_IsNull(handle)) {
        RefPtr<PropertyDescriptor> descriptor = PropertyDescriptor::create().setName("[[class]]").setConfigurable(false).setEnumerable(true).release();
        descriptor->setValue(wrapDartHandle(handle, DartDebuggerObject::ObjectClass, objectGroup, false));
        descriptor->setWritable(false);
        descriptor->setWasThrown(false);
        descriptor->setIsOwn(true);
        (*properties)->addItem(descriptor);

        if (DartDOMWrapper::subtypeOf(handle, JsObject::dartClassId)) {
            DartDOMData* domData = DartDOMData::current();
            JsObject* object = DartDOMWrapper::unwrapDartWrapper<JsObject>(domData, handle, exception);
            if (!exception) {
                descriptor = PropertyDescriptor::create().setName("[[JavaScript View]]").setConfigurable(false).setEnumerable(true).release();

                V8ScriptState* v8ScriptState = DartUtilities::v8ScriptStateForCurrentIsolate();
                InjectedScript v8InjectedScript = m_injectedScriptManager->injectedScriptFor(v8ScriptState);
                ScriptValue v8ScriptValue(v8ScriptState, object->localV8Object());
                descriptor->setValue(v8InjectedScript.wrapObject(v8ScriptValue, objectGroup, false));
                descriptor->setWritable(false);
                descriptor->setWasThrown(false);
                descriptor->setIsOwn(true);
                (*properties)->addItem(descriptor);
            }
        }
    }
}

void DartInjectedScript::getInternalProperties(ErrorString* errorString, const String& objectId, RefPtr<Array<InternalPropertyDescriptor> >* properties)
{
    if (!m_scriptState) {
        *errorString = "Invalid DartInjectedScript";
        return;
    }
    // FIXME: add internal properties such as [[PrimitiveValue], [[BoundThis]], etc.
    *properties = Array<InternalPropertyDescriptor>::create();
}

void DartInjectedScript::getProperty(ErrorString* errorString, const String& objectId, const RefPtr<JSONArray>& propertyPath, RefPtr<TypeBuilder::Runtime::RemoteObject>* result, TypeBuilder::OptOutput<bool>* wasThrown)
{
    if (!m_scriptState) {
        *errorString = "Invalid DartInjectedScript";
        return;
    }
    DartIsolateScope scope(m_scriptState->isolate());
    DartApiScope apiScope;

    DartDebuggerObject* object = lookupObject(objectId);
    if (!object) {
        *errorString = "Unknown objectId";
        return;
    }
    Dart_Handle handle = object->handle();
    const String& objectGroup = object->group();


    for (unsigned i = 0; i < propertyPath->length(); i++) {
        RefPtr<JSONValue> value = propertyPath->get(i);
        String propertyName;
        if (!value->asString(&propertyName)) {
            *errorString = "Invalid property name";
            return;
        }

        handle = getObjectPropertySafe(handle, propertyName);
        ASSERT(!Dart_IsError(handle));
    }
    *result = wrapDartHandle(handle, inferKind(handle), objectGroup, false);
}

Node* DartInjectedScript::nodeForObjectId(const String& objectId)
{
    DartIsolateScope scope(m_scriptState->isolate());
    DartApiScope apiScope;

    DartDebuggerObject* object = lookupObject(objectId);
    if (!object || object->kind() != DartDebuggerObject::Object)
        return 0;

    Dart_Handle handle = object->handle();
    if (DartDOMWrapper::subtypeOf(handle, DartNode::dartClassId)) {
        Dart_Handle exception = 0;
        Node* node = DartNode::toNative(handle, exception);
        ASSERT(!exception);
        return node;
    }
    return 0;
}

String DartInjectedScript::cacheObject(Dart_Handle handle, const String& objectGroup, DartDebuggerObject::Kind kind)
{
    Dart_PersistentHandle persistentHandle = Dart_NewPersistentHandle(handle);
    String objectId = String::format("{\"injectedScriptId\":%d,\"id\":%ld,\"isDart\":true}", m_injectedScriptId, m_nextObjectId);
    m_nextObjectId++;

    if (!objectGroup.isNull()) {
        ObjectGroupMap::AddResult addResult = m_objectGroups.add(objectGroup, Vector<String>());
        Vector<String>& groupMembers = addResult.storedValue->value;
        groupMembers.append(objectId);
    }

    m_objects.set(objectId, new DartDebuggerObject(persistentHandle, objectGroup, kind));
    return objectId;
}

void DartInjectedScript::releaseObject(const String& objectId)
{
    DartIsolateScope scope(m_scriptState->isolate());
    DartApiScope apiScope;
    ASSERT(validateObjectId(objectId));
    DebuggerObjectMap::iterator it = m_objects.find(objectId);
    if (it != m_objects.end()) {
        delete it->value;
        m_objects.remove(objectId);
    }
}

String DartInjectedScript::getCallFrameId(int ordinal, int asyncOrdinal)
{
    // FIXME: what if the stack trace contains frames from multiple
    // injectedScripts?
    return String::format("{\"ordinal\":%d,\"injectedScriptId\":%d,\"asyncOrdinal\":%d,\"isDart\":true}", ordinal, m_injectedScriptId, asyncOrdinal);
}

Dart_ActivationFrame DartInjectedScript::callFrameForId(const Dart_StackTrace trace, const String& callFrameId)
{
    Dart_ActivationFrame frame = 0;
    int ordinal = 0;
    int asyncOrdinal = 0;
    RefPtr<JSONValue> json = parseJSON(callFrameId);
    if (json && json->type() == JSONValue::TypeObject) {
        bool ALLOW_UNUSED success = json->asObject()->getNumber("ordinal", &ordinal);
        ASSERT(success);
        success = json->asObject()->getNumber("asyncOrdinal", &asyncOrdinal);
        ASSERT(success);
    } else {
        ASSERT(json && json->type() == JSONValue::TypeObject);
        return 0;
    }
    Dart_Handle ALLOW_UNUSED result;
    if (asyncOrdinal > 0) { // 1-based index
        // FIXMEDART: we never really supported async stacks for dart anyway.
        return 0;
    }
    result = Dart_GetActivationFrame(trace, ordinal, &frame);
    ASSERT(result);
    return frame;
}

PassRefPtr<Array<CallFrame> > DartInjectedScript::wrapCallFrames(const Dart_StackTrace trace, int asyncOrdinal)
{
    intptr_t length = 0;
    Dart_Handle ALLOW_UNUSED result;
    RefPtr<Array<CallFrame> > ret = Array<CallFrame>::create();
    result = Dart_StackTraceLength(trace, &length);
    ASSERT(!Dart_IsError(result));
    DartScriptDebugServer& debugServer = DartScriptDebugServer::shared();
    Dart_Handle libraries = Dart_GetLibraryIds();
    for (intptr_t i = 0; i < length; i++) {
        Dart_ActivationFrame frame = 0;
        result = Dart_GetActivationFrame(trace, i, &frame);
        ASSERT(!Dart_IsError(result));
        Dart_Handle functionName = 0;
        Dart_Handle function = 0;
        Dart_CodeLocation location;
        Dart_ActivationFrameGetLocation(frame, &functionName, &function, &location);
        const String& url = DartUtilities::toString(location.script_url);
        intptr_t line = 0;
        intptr_t column = 0;
        Dart_ActivationFrameInfo(frame, 0, 0, &line, &column);
        RefPtr<Location> locationJson = Location::create()
            .setScriptId(debugServer.getScriptId(url, Dart_CurrentIsolate()))
            .setLineNumber(line - 1);
        locationJson->setColumnNumber(column);
        Dart_Handle localVariables = Dart_GetLocalVariables(frame);
        Dart_Handle thisHandle = findReceiver(localVariables);
        Dart_Handle enclosingType = lookupEnclosingType(function);
        RefPtr<TypeBuilder::Array<Scope> > scopeChain = TypeBuilder::Array<Scope>::create();
        RefPtr<TypeBuilder::Runtime::RemoteObject> thisObject =
            wrapDartHandle(thisHandle ? thisHandle : Dart_Null(), DartDebuggerObject::Object, "backtrace", false);

        intptr_t localVariablesLength = 0;
        result = Dart_ListLength(localVariables, &localVariablesLength);
        ASSERT(!Dart_IsError(result));
        if (localVariablesLength > 0) {
            scopeChain->addItem(Scope::create()
                .setType(Scope::Type::Local)
                .setObject(wrapDartHandle(localVariables, DartDebuggerObject::LocalVariables, "backtrace", false))
                .release());
        }

        if (thisHandle) {
            scopeChain->addItem(Scope::create()
                .setType(Scope::Type::Instance)
                .setObject(thisObject)
                .release());
        }

        if (Dart_IsType(enclosingType)) {
            scopeChain->addItem(Scope::create()
                .setType(Scope::Type::Class)
                .setObject(wrapDartHandle(enclosingType, DartDebuggerObject::StaticClass, "backtrace", false))
                .release());
        }

        Dart_Handle library = Dart_GetLibraryFromId(location.library_id);
        ASSERT(Dart_IsLibrary(library));
        ASSERT(!Dart_IsNull(library));
        if (Dart_IsLibrary(library)) {
            scopeChain->addItem(Scope::create()
                .setType(Scope::Type::Library)
                .setObject(wrapDartHandle(library, DartDebuggerObject::CurrentLibrary, "backtrace", false))
                .release());
        }

        scopeChain->addItem(Scope::create()
            .setType(Scope::Type::Isolate)
            .setObject(wrapDartHandle(libraries, DartDebuggerObject::Isolate, "backtrace", false))
            .release());

        ret->addItem(CallFrame::create()
            .setCallFrameId(getCallFrameId(i, asyncOrdinal))
            .setFunctionName(DartUtilities::toString(functionName))
            .setLocation(locationJson)
            .setScopeChain(scopeChain)
            .setThis(thisObject)
            .release());
    }
    return ret;
}

DartDebuggerObject::Kind DartInjectedScript::inferKind(Dart_Handle handle)
{
    DartDOMData* domData = DartDOMData::current();
    ASSERT(domData);
    if (Dart_IsType(handle))
        return DartDebuggerObject::Class;
    if (Dart_IsError(handle))
        return DartDebuggerObject::Error;
    if (Dart_IsNull(handle))
        return DartDebuggerObject::Object;
    if (DartUtilities::isFunction(domData, handle))
        return DartDebuggerObject::Function;
    if (Dart_IsInstance(handle))
        return DartDebuggerObject::Object;
    ASSERT(Dart_IsLibrary(handle));
    return DartDebuggerObject::Library;
}

PassRefPtr<TypeBuilder::Runtime::RemoteObject> DartInjectedScript::wrapDartObject(Dart_Handle dartHandle, const String& groupName, bool generatePreview)
{
    return wrapDartHandle(dartHandle, inferKind(dartHandle), groupName, generatePreview);
}

PassRefPtr<TypeBuilder::Runtime::RemoteObject> DartInjectedScript::wrapDartHandle(Dart_Handle dartHandle, DartDebuggerObject::Kind kind, const String& groupName, bool generatePreview)
{
    RefPtr<TypeBuilder::Runtime::RemoteObject> remoteObject;
    packageResult(dartHandle, kind, groupName, 0, false, generatePreview, &remoteObject, 0);
    return remoteObject;
}

PassRefPtr<TypeBuilder::Runtime::RemoteObject> DartInjectedScript::wrapObject(const ScriptValue& value, const String& groupName, bool generatePreview)
{
    if (!m_scriptState)
        return nullptr;

    AbstractScriptValue* scriptValue = value.scriptValue();
    if (scriptValue->isEmpty())
        return wrapDartObject(Dart_Null(), groupName, generatePreview);

    DartIsolateScope scope(m_scriptState->isolate());
    DartApiScope apiScope;
    ASSERT(!scriptValue->isV8());
    if (scriptValue->isV8()) {
        return wrapDartObject(Dart_NewStringFromCString("JavaScript value when Dart value expected"), groupName, generatePreview);
    }
    return wrapDartObject(static_cast<DartScriptValue*>(scriptValue)->dartValue(), groupName, generatePreview);
}

PassRefPtr<TypeBuilder::Runtime::RemoteObject> DartInjectedScript::wrapTable(const ScriptValue& table, const ScriptValue& columns)
{
    if (!m_scriptState)
        return nullptr;
    DartIsolateScope scope(m_scriptState->isolate());
    DartApiScope apiScope;
    // FIXME: implement this rarely used method or call out to the JS version.
    ASSERT_NOT_REACHED();
    return nullptr;
}

ScriptValue DartInjectedScript::findObjectById(const String& objectId) const
{
    // FIXMEDART: Implement this.
    RELEASE_ASSERT(0);
    return ScriptValue();
}

void DartInjectedScript::inspectNode(Node* node)
{
    // FIXMEDART: Implement this.
    RELEASE_ASSERT(0);
}

void DartInjectedScript::releaseObjectGroup(const String& objectGroup)
{
    if (!m_scriptState)
        return;
    DartIsolateScope scope(m_scriptState->isolate());
    DartApiScope apiScope;
    ObjectGroupMap::iterator it = m_objectGroups.find(objectGroup);
    if (it != m_objectGroups.end()) {
        Vector<String>& ids = it->value;
        for (Vector<String>::iterator it = ids.begin(); it != ids.end(); ++it) {
            const String& id = *it;
            DebuggerObjectMap::iterator objectIt = m_objects.find(id);
            if (objectIt != m_objects.end()) {
                delete objectIt->value;
                m_objects.remove(id);
            }
        }
        m_objectGroups.remove(objectGroup);
    }
}

DartScriptState* DartInjectedScript::scriptState() const
{
    return m_scriptState;
}

DartDebuggerObject* DartInjectedScript::lookupObject(const String& objectId)
{
    ASSERT(validateObjectId(objectId));
    DebuggerObjectMap::iterator it = m_objects.find(objectId);
    return it != m_objects.end() ? it->value : 0;
}

bool DartInjectedScript::isDartObjectId(const String& objectId)
{
    RefPtr<JSONValue> parsedObjectId = parseJSON(objectId);
    if (parsedObjectId && parsedObjectId->type() == JSONValue::TypeObject) {
        bool isDart = false;
        bool success = parsedObjectId->asObject()-> getBoolean("isDart", &isDart);
        return success && isDart;
    }
    return false;
}

} // namespace blink
