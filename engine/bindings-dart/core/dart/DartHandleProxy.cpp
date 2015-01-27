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
#include "config.h"
#include "bindings/core/dart/DartHandleProxy.h"

#include "bindings/core/dart/DartJsInterop.h"
#include "bindings/core/dart/DartNode.h"
#include "bindings/core/dart/DartPersistentValue.h"
#include "bindings/core/dart/DartScriptState.h"
#include "bindings/core/dart/V8Converter.h"
#include "bindings/core/v8/PageScriptDebugServer.h"
#include "bindings/core/v8/ScriptController.h"
#include "bindings/core/v8/V8Binding.h"
#include "bindings/core/v8/V8ScriptRunner.h"
#include "bindings/core/v8/V8ThrowException.h"

#include "wtf/StdLibExtras.h"

namespace blink {

struct DartHandleProxy::CallbackData {
    ScopedPersistent<v8::Object> handle;
    DartPersistentValue* value;
};

typedef HashMap<String, v8::Persistent<v8::FunctionTemplate>* > FunctionTemplateMap;

static v8::Local<v8::FunctionTemplate> objectProxyTemplate(Dart_Handle instance);
static v8::Local<v8::FunctionTemplate> functionProxyTemplate();
static v8::Local<v8::FunctionTemplate> libraryProxyTemplate(v8::Handle<v8::String> libraryNameV8);
static v8::Local<v8::FunctionTemplate> typeProxyTemplate(Dart_Handle type);
static v8::Local<v8::FunctionTemplate> frameProxyTemplate();

DartPersistentValue* DartHandleProxy::readPointerFromProxy(v8::Handle<v8::Value> proxy)
{
    void* pointer = proxy.As<v8::Object>()->GetAlignedPointerFromInternalField(0);
    return static_cast<DartPersistentValue*>(pointer);
}

bool DartHandleProxy::isDartProxy(v8::Handle<v8::Value> value)
{
    if (!value.IsEmpty() && value->IsObject()) {
        v8::Isolate* v8Isolate = v8::Isolate::GetCurrent();
        v8::Local<v8::Value> hiddenValue = value.As<v8::Object>()->GetHiddenValue(v8::String::NewFromUtf8(v8Isolate, "dartProxy"));
        return *hiddenValue && hiddenValue->IsBoolean();
    }
    return false;
}

bool isGlobalObjectProxy(v8::Handle<v8::Object> value)
{
    v8::Isolate* v8Isolate = v8::Isolate::GetCurrent();
    v8::Local<v8::Value> hiddenValue = value.As<v8::Object>()->GetHiddenValue(v8::String::NewFromUtf8(v8Isolate, "asGlobal"));
    return *hiddenValue && hiddenValue->IsBoolean();
}

DartScopes::DartScopes(v8::Local<v8::Object> v8Handle, bool disableBreak) :
    scriptValue(DartHandleProxy::readPointerFromProxy(v8Handle)),
    scope(scriptValue->isolate()),
    disableBreak(disableBreak)
{
    ASSERT(scriptValue->isIsolateAlive());
    handle = scriptValue->value();
    if (disableBreak) {
        previousPauseInfo = Dart_GetExceptionPauseInfo();
        Dart_SetExceptionPauseInfo(kNoPauseOnExceptions);
    }
}

DartScopes::~DartScopes()
{
    if (disableBreak) {
        Dart_SetExceptionPauseInfo(previousPauseInfo);
    }
}

static void weakCallback(const v8::WeakCallbackData<v8::Object, DartHandleProxy::CallbackData >& data)
{
    DartHandleProxy::CallbackData* callbackData = data.GetParameter();
    callbackData->handle.clear();
    delete callbackData->value;
    delete callbackData;
}

Dart_Handle DartHandleProxy::unwrapValue(v8::Handle<v8::Value> value)
{
    if (DartHandleProxy::isDartProxy(value))
        return readPointerFromProxy(value)->value();

    Dart_Handle exception = 0;
    Dart_Handle handle = V8Converter::toDart(value, exception);
    ASSERT(!exception);
    return handle;
}

bool libraryHasMember(Dart_Handle library, Dart_Handle name)
{
    return !Dart_IsError(Dart_GetField(library, name))
        || !Dart_IsError(Dart_GetType(library, name, 0, 0))
        || Dart_IsFunction(Dart_LookupFunction(library, name));
}

bool typeHasMember(Dart_Handle type, Dart_Handle name)
{
    return !Dart_IsError(Dart_GetField(type, name)) || Dart_IsFunction(Dart_LookupFunction(type, name));
}

Dart_Handle getEncodedMapKeyList(Dart_Handle object)
{
    return DartUtilities::invokeUtilsMethod("getEncodedMapKeyList", 1, &object);
}

Dart_Handle stripTrailingDot(Dart_Handle str)
{
    return DartUtilities::invokeUtilsMethod("stripTrailingDot", 1, &str);
}

Dart_Handle addTrailingDot(Dart_Handle str)
{
    return DartUtilities::invokeUtilsMethod("addTrailingDot", 1, &str);
}

Dart_Handle demangle(Dart_Handle str)
{
    return DartUtilities::invokeUtilsMethod("demangle", 1, &str);
}

Dart_Handle lookupValueForEncodedMapKey(Dart_Handle object, Dart_Handle key)
{
    Dart_Handle args[] = {object, key};
    return DartUtilities::invokeUtilsMethod("lookupValueForEncodedMapKey", 2, args);
}

Dart_Handle buildConstructorName(Dart_Handle typeName, Dart_Handle constructorName)
{
    Dart_Handle args[] = {typeName, constructorName};
    return DartUtilities::invokeUtilsMethod("buildConstructorName", 2, args);
}

Dart_Handle stripClassName(Dart_Handle str, Dart_Handle typeName)
{
    Dart_Handle args[] = {str, typeName};
    return DartUtilities::invokeUtilsMethod("stripClassName", 2, args);
}

bool isNoSuchMethodError(Dart_Handle type)
{
    Dart_Handle exception = 0;
    bool ret = DartUtilities::dartToBool(DartUtilities::invokeUtilsMethod("isNoSuchMethodError", 1, &type), exception);
    ASSERT(!exception);
    return ret;
}

Dart_Handle createLocalVariablesMap(Dart_Handle localVariablesList)
{
    return DartUtilities::invokeUtilsMethod("createLocalVariablesMap", 1, &localVariablesList);
}

Dart_Handle getMapKeyList(Dart_Handle localVariablesMap)
{
    return DartUtilities::invokeUtilsMethod("getMapKeyList", 1, &localVariablesMap);
}

bool mapContainsKey(Dart_Handle map, Dart_Handle key)
{
    Dart_Handle exception = 0;
    return DartUtilities::dartToBool(Dart_Invoke(map, Dart_NewStringFromCString("containsKey"), 1, &key), exception);
}

void addFunctionNames(Dart_Handle handle, v8::Local<v8::Array>& properties, intptr_t* count, bool isInstance, bool noMethods)
{
    intptr_t length = 0;
    Dart_Handle functionNames = Dart_GetFunctionNames(handle);
    ASSERT(!Dart_IsError(functionNames));
    bool isLibrary = Dart_IsLibrary(handle);
    Dart_ListLength(functionNames, &length);
    for (intptr_t i = 0; i < length; i++) {
        Dart_Handle functionName = Dart_ListGetAt(functionNames, i);
        Dart_Handle function = Dart_LookupFunction(handle, functionName);

        // FIXME: the DartVM doesn't correctly handle invoking properties with
        // private names. For now, skip private function names.
        intptr_t functionNameLength = 0;
        uint8_t* functionNameData;
        Dart_StringToUTF8(functionName, &functionNameData, &functionNameLength);
        if (functionNameLength > 0 && functionNameData[0] == '_')
            continue;

        bool isStatic = false;
        Dart_FunctionIsStatic(function, &isStatic);

        bool isConstructor = false;
        Dart_FunctionIsConstructor(function, &isConstructor);

        if (!isLibrary) {
            if (isInstance == (isStatic || isConstructor))
                continue;

            bool isSetter = false;
            Dart_FunctionIsSetter(function, &isSetter);
            bool isGetter = false;
            Dart_FunctionIsGetter(function, &isGetter);

            if (noMethods && !isSetter && !isGetter)
                continue;

            // Skip setters as any setter we care to enumerate should have a matching getter.
            // Setters without matching getters will still be callable but won't be enumerated.
            if (isSetter)
                continue;
        }

        // Strip off the leading typename from constructor name.
        if (isConstructor)
            functionName = stripClassName(functionName, Dart_TypeName(handle));

        functionName = demangle(functionName);
        properties->Set(*count, V8Converter::stringToV8(functionName));
        *count = *count + 1;
    }
}

void addClassNames(Dart_Handle library, v8::Local<v8::Array>& properties, intptr_t* count)
{
    intptr_t length = 0;
    Dart_Handle typeNames = Dart_LibraryGetClassNames(library);
    ASSERT(!Dart_IsNull(typeNames));
    ASSERT(Dart_IsList(typeNames));
    Dart_ListLength(typeNames, &length);
    for (intptr_t i = 0; i < length; i++) {
        Dart_Handle typeName = Dart_ListGetAt(typeNames, i);
        properties->Set(*count, V8Converter::stringToV8(typeName));
        *count = *count + 1;
    }
}

void addFieldNames(Dart_Handle fieldNames, v8::Local<v8::Array>& properties, intptr_t* count)
{
    ASSERT(!Dart_IsApiError(fieldNames));
    ASSERT(Dart_IsList(fieldNames));
    intptr_t length = 0;
    Dart_ListLength(fieldNames, &length);
    for (intptr_t i = 0; i < length; i += 2) {
        Dart_Handle fieldName = Dart_ListGetAt(fieldNames, i);
        properties->Set(*count, V8Converter::stringToV8(demangle(fieldName)));
        *count = *count + 1;
    }
}

template<typename CallbackInfo>
void setReturnValue(CallbackInfo info, Dart_Handle result)
{
    if (Dart_IsError(result)) {
        // FIXME: we would really prefer to call the following however it has
        // bad unintended consequences as then JS cannot catch the thrown exception.
        // DartUtilities::reportProblem(DartUtilities::scriptExecutionContext(), result);
        v8::Isolate* v8Isolate = v8::Isolate::GetCurrent();
        V8ThrowException::throwException(v8::String::NewFromUtf8(v8Isolate, Dart_GetError(result)), v8::Isolate::GetCurrent());
    } else {
        v8SetReturnValue(info, DartHandleProxy::create(result));
    }
}

void DartHandleProxy::writePointerToProxy(v8::Local<v8::Object> proxy, Dart_Handle value)
{
    ASSERT(!proxy.IsEmpty());
    DartPersistentValue* dartScriptValue = new DartPersistentValue(value);
    proxy->SetAlignedPointerInInternalField(0, dartScriptValue);
    v8::Isolate* isolate = v8::Isolate::GetCurrent();
    v8::Persistent<v8::Object> persistentHandle;
    DartHandleProxy::CallbackData* callbackData = new DartHandleProxy::CallbackData();
    callbackData->value = dartScriptValue;
    callbackData->handle.set(isolate, proxy);
    callbackData->handle.setWeak(callbackData, &weakCallback);
}

intptr_t getLibraryId(v8::Local<v8::Object> proxy)
{
    v8::Isolate* v8Isolate = v8::Isolate::GetCurrent();
    return (intptr_t)proxy.As<v8::Object>()->GetHiddenValue(v8::String::NewFromUtf8(v8Isolate, "libraryId"))->Int32Value();
}

// Returns a String of the library prefix or Dart_Null if no prefix is found.
Dart_Handle getLibraryPrefix(v8::Local<v8::Object> proxy)
{
    v8::Isolate* v8Isolate = v8::Isolate::GetCurrent();
    v8::Local<v8::Value> prefix = proxy.As<v8::Object>()->GetHiddenValue(v8::String::NewFromUtf8(v8Isolate, "prefix"));
    if (*prefix && prefix->IsString())
        return V8Converter::stringToDart(prefix);
    return Dart_Null();
}

static void functionNamedPropertyGetter(v8::Local<v8::String> name, const v8::PropertyCallbackInfo<v8::Value>& info)
{
    DartScopes scopes(info.Holder());
    Dart_Handle handle = scopes.handle;

    ASSERT(DartUtilities::isFunction(DartDOMData::current(), handle) || Dart_IsFunction(handle));
    v8::Isolate* v8Isolate = v8::Isolate::GetCurrent();
    Dart_Handle ret = Dart_Invoke(handle, V8Converter::stringToDart(v8::String::Concat(v8::String::NewFromUtf8(v8Isolate, "get:"), name)), 0, 0);
    if (Dart_IsError(ret) && name->Equals(v8::String::NewFromUtf8(v8Isolate, "__proto__")))
        return;

    setReturnValue(info, ret);
}

static void functionNamedPropertySetter(v8::Local<v8::String> property, v8::Local<v8::Value> value, const v8::PropertyCallbackInfo<v8::Value>& info)
{
    v8::Isolate* v8Isolate = v8::Isolate::GetCurrent();
    V8ThrowException::throwException(v8::String::NewFromUtf8(v8Isolate, "Dart functions do not have writeable properties"), v8::Isolate::GetCurrent());
}

static void functionInvocationCallback(const v8::FunctionCallbackInfo<v8::Value>& args)
{
    DartScopes scopes(args.Holder());
    Dart_Handle handle = scopes.handle;

    DartDOMData* domData = DartDOMData::current();
    ASSERT(DartUtilities::isFunction(domData, handle) || Dart_IsFunction(handle));
    bool isConstructor = false;
    Dart_FunctionIsConstructor(handle, &isConstructor);
    if (args.IsConstructCall() != isConstructor) {
        v8::Isolate* v8Isolate = v8::Isolate::GetCurrent();
        V8ThrowException::throwException(v8::String::NewFromUtf8(v8Isolate, isConstructor ? "Constructor called without new" : "Regular function called as constructor"), v8Isolate);
        return;
    }

    Vector<Dart_Handle> dartFunctionArgs;
    for (intptr_t i = 0; i < args.Length(); ++i)
        dartFunctionArgs.append(DartHandleProxy::unwrapValue(args[i]));

    if (DartUtilities::isFunction(domData, handle)) {
        setReturnValue(args, Dart_InvokeClosure(handle, dartFunctionArgs.size(), dartFunctionArgs.data()));
        return;
    }
    Dart_Handle type = Dart_FunctionOwner(handle);
    if (isConstructor) {
        // FIXME: this seems like an overly complex way to have to invoke a constructor.
        setReturnValue(args,
            Dart_New(type, stripClassName(Dart_FunctionName(handle), Dart_TypeName(type)),
                dartFunctionArgs.size(), dartFunctionArgs.data()));
    } else {
        // Workaround so that invoking toString on a Class object returns
        // something meaningful instead of throwing an exception.
        if (Dart_IsType(type)) {
            bool isStatic = true;
            Dart_FunctionIsStatic(handle, &isStatic);
            // Attempting to invoke a static method on a Class object will fail
            // so there is not much harm in returning a more user friendly
            // result for toString().
            v8::Isolate* v8Isolate = v8::Isolate::GetCurrent();
            if (!isStatic && V8Converter::stringToV8(Dart_FunctionName(handle))->Equals(v8::String::NewFromUtf8(v8Isolate, "toString"))) {
                setReturnValue(args, Dart_QualifiedTypeName(type));
                return;
            }
        }
        setReturnValue(args,
            Dart_Invoke(type, Dart_FunctionName(handle), dartFunctionArgs.size(), dartFunctionArgs.data()));
    }
}

static void typeProxyConstructorInvocationCallback(const v8::FunctionCallbackInfo<v8::Value>& args)
{
    DartScopes scopes(args.Holder());
    Dart_Handle handle = scopes.handle;

    ASSERT(Dart_IsType(handle));

    if (!args.IsConstructCall()) {
        v8::Isolate* v8Isolate = v8::Isolate::GetCurrent();
        V8ThrowException::throwException(v8::String::NewFromUtf8(v8Isolate, "Constructors can only be invoked with 'new'"), v8Isolate);
        return;
    }

    Vector<Dart_Handle> dartFunctionArgs;
    for (intptr_t i = 0; i < args.Length(); ++i)
        dartFunctionArgs.append(DartHandleProxy::unwrapValue(args[i]));

    setReturnValue(args, Dart_New(handle, Dart_Null(), dartFunctionArgs.size(), dartFunctionArgs.data()));
}

void getImportedLibrariesMatchingPrefix(intptr_t libraryId, Dart_Handle prefix, Vector<std::pair<Dart_Handle, intptr_t> >* libraries)
{
    Dart_Handle imports = Dart_GetLibraryImports(libraryId);
    ASSERT(!Dart_IsError(imports));
    // Unfortunately dart_debugger_api.h adds a trailing dot to import prefixes.
    if (!Dart_IsNull(prefix))
        prefix = addTrailingDot(prefix);
    intptr_t length = 0;
    Dart_ListLength(imports, &length);
    for (intptr_t i = 0; i < length; i += 2) {
        Dart_Handle importPrefix = Dart_ListGetAt(imports, i);
        ASSERT(Dart_IsNull(importPrefix) || Dart_IsString(importPrefix));
        bool equals = false;
        Dart_Handle ALLOW_UNUSED result = Dart_ObjectEquals(prefix, importPrefix, &equals);
        ASSERT(!Dart_IsError(result));
        if (equals) {
            Dart_Handle importedLibraryIdHandle = Dart_ListGetAt(imports, i + 1);
            ASSERT(Dart_IsInteger(importedLibraryIdHandle));
            int64_t importedLibraryId;
            Dart_IntegerToInt64(importedLibraryIdHandle, &importedLibraryId);
            Dart_Handle libraryURL = Dart_GetLibraryURL(importedLibraryId);
            ASSERT(!Dart_IsError(libraryURL));
            Dart_Handle library = Dart_LookupLibrary(libraryURL);
            ASSERT(Dart_IsLibrary(library));
            libraries->append(std::pair<Dart_Handle, intptr_t>(library, importedLibraryId));
        }
    }
}

static bool libraryNamedPropertyGetterHelper(Dart_Handle library, Dart_Handle dartName,
    const v8::PropertyCallbackInfo<v8::Value>* info)
{
    Dart_Handle ret;
    ret  = Dart_GetField(library, dartName);
    if (!Dart_IsApiError(ret)) {
        if (info)
            setReturnValue(*info, ret);
        return true;
    }

    ret = Dart_GetType(library, dartName, 0, 0);
    if (!Dart_IsError(ret)) {
        if (info)
            v8SetReturnValue(*info, DartHandleProxy::createTypeProxy(ret, true));
        return true;
    }

    ret = Dart_LookupFunction(library, dartName);
    if (!Dart_IsNull(ret) && !Dart_IsError(ret)) {
        if (info)
            setReturnValue(*info, ret);
        return true;
    }
    return false;
}

/**
 * Helper for getting library property values.
 * Info may be 0 in which case no V8 If info is 0, no return value is set.
 */
static bool libraryNamedPropertyGetterHelper(v8::Local<v8::String> name, v8::Local<v8::Object> holder,
    const v8::PropertyCallbackInfo<v8::Value>* info)
{
    DartScopes scopes(holder);
    Dart_Handle handle = scopes.handle;

    ASSERT(Dart_IsLibrary(handle));
    intptr_t libraryId = getLibraryId(holder);
    Dart_Handle dartName = V8Converter::stringToDart(name);
    Dart_Handle prefix = getLibraryPrefix(holder);
    bool hasLibraryPrefix = !Dart_IsNull(prefix) && Dart_IsString(prefix);

    if (hasLibraryPrefix) {
        Vector<std::pair<Dart_Handle, intptr_t> > libraries;
        getImportedLibrariesMatchingPrefix(libraryId, prefix, &libraries);
        for (size_t i = 0; i < libraries.size(); i++) {
            if (libraryNamedPropertyGetterHelper(libraries[i].first, dartName, info))
                return true;
        }
    } else {
        if (libraryNamedPropertyGetterHelper(handle, dartName, info))
            return true;

        // Check whether there is at least one library imported with the specified prefix.
        Vector<std::pair<Dart_Handle, intptr_t> > libraries;
        getImportedLibrariesMatchingPrefix(libraryId, dartName, &libraries);
        if (libraries.size() > 0) {
            if (info)
                v8SetReturnValue(*info, DartHandleProxy::createLibraryProxy(handle, libraryId, dartName, false));
            return true;
        }
    }

    v8::Isolate* v8Isolate = v8::Isolate::GetCurrent();
    if (name->Equals(v8::String::NewFromUtf8(v8Isolate, "__proto__"))) {
        if (info)
            v8SetReturnValue(*info, v8::Null(v8Isolate));
        return true;
    }
    return false;
}

static void libraryNamedPropertyGetter(v8::Local<v8::String> name, const v8::PropertyCallbackInfo<v8::Value>& info)
{
    libraryNamedPropertyGetterHelper(name, info.Holder(), &info);
}

// FIXME: we need to handle prefixes when setting library properties as well
// for completness. Postponing implementing this for now as we hope Dart_Invoke
// can just be fixed to handle libraries correctly.
static void libraryNamedPropertySetter(v8::Local<v8::String> property, v8::Local<v8::Value> value, const v8::PropertyCallbackInfo<v8::Value>& info)
{
    DartScopes scopes(info.Holder());
    Dart_Handle handle = scopes.handle;

    ASSERT(Dart_IsLibrary(handle));
    Dart_Handle dartValue = DartHandleProxy::unwrapValue(value);
    setReturnValue(info, Dart_SetField(handle, V8Converter::stringToDart(property), dartValue));
}

static void libraryQueryProperty(v8::Local<v8::String> name, const v8::PropertyCallbackInfo<v8::Integer>& info)
{
    if (libraryNamedPropertyGetterHelper(name, info.Holder(), 0))
        v8SetReturnValueInt(info, 0);
}

void libraryEnumerateHelper(Dart_Handle library, intptr_t libraryId, v8::Local<v8::Array> properties, intptr_t* count)
{
    addFunctionNames(library, properties, count, false, false);
    addClassNames(library, properties, count);
    addFieldNames(Dart_GetLibraryFields(libraryId), properties, count);
}

static void libraryPropertyEnumerator(const v8::PropertyCallbackInfo<v8::Array>& info)
{
    DartScopes scopes(info.Holder());
    Dart_Handle handle = scopes.handle;

    intptr_t libraryId = getLibraryId(info.Holder());
    ASSERT(Dart_IsLibrary(handle));
    v8::Isolate* v8Isolate = v8::Isolate::GetCurrent();
    v8::Local<v8::Array> cachedProperties = info.Holder().As<v8::Object>()->GetHiddenValue(v8::String::NewFromUtf8(v8Isolate, "cache")).As<v8::Array>();
    if (*cachedProperties) {
        v8SetReturnValue(info, cachedProperties);
        return;
    }

    Dart_Handle prefix = getLibraryPrefix(info.Holder());
    bool hasLibraryPrefix = Dart_IsString(prefix);

    v8::Local<v8::Array> properties = v8::Array::New(v8Isolate);
    intptr_t count = 0;

    if (hasLibraryPrefix) {
        Vector<std::pair<Dart_Handle, intptr_t> > libraries;
        getImportedLibrariesMatchingPrefix(libraryId, prefix, &libraries);
        for (size_t i = 0; i < libraries.size(); i++)
            libraryEnumerateHelper(libraries[i].first, libraries[i].second, properties, &count);
    } else {
        libraryEnumerateHelper(handle, libraryId, properties, &count);
        // Add all library prefixes of imports to the library.
        Dart_Handle imports = Dart_GetLibraryImports(libraryId);
        ASSERT(!Dart_IsError(imports));
        intptr_t length = 0;
        Dart_ListLength(imports, &length);
        for (intptr_t i = 0; i < length; i += 2) {
            Dart_Handle importPrefix = Dart_ListGetAt(imports, i);
            if (!Dart_IsNull(importPrefix)) {
                ASSERT(Dart_IsString(importPrefix));
                properties->Set(count, V8Converter::stringToV8(
                    demangle(stripTrailingDot(importPrefix))));
                count++;
            }
        }
    }

    info.Holder()->SetHiddenValue(v8::String::NewFromUtf8(v8Isolate, "cache"), properties);
    v8SetReturnValue(info, properties);
}

bool isShowStatics(v8::Handle<v8::Value> value)
{
    v8::Isolate* v8Isolate = v8::Isolate::GetCurrent();
    v8::Local<v8::Value> showStatics = value.As<v8::Object>()->GetHiddenValue(v8::String::NewFromUtf8(v8Isolate, "showStatics"));
    ASSERT(*showStatics && showStatics->IsBoolean());
    return showStatics->BooleanValue();
}

static void typeNamedPropertyGetter(v8::Local<v8::String> name, const v8::PropertyCallbackInfo<v8::Value>& info)
{
    DartScopes scopes(info.Holder());
    Dart_Handle handle = scopes.handle;

    Dart_Handle ret;
    ASSERT(Dart_IsType(handle));
    v8::Isolate* v8Isolate = v8::Isolate::GetCurrent();
    if (name->Equals(v8::String::NewFromUtf8(v8Isolate, "__proto__"))) {
        // Due to Dart semantics, if we are showing statics, we need to
        // not link types up to their superclasses as statics in superclasses
        // are not visible in subclasses.
        if (isShowStatics(info.Holder())) {
            v8SetReturnValue(info, v8::Null(v8Isolate));
            return;
        }

        Dart_Handle supertype = Dart_GetSupertype(handle);
        if (!Dart_IsNull(supertype))
            v8SetReturnValue(info, DartHandleProxy::createTypeProxy(supertype, false));
        else
            v8SetReturnValue(info, v8::Null(v8Isolate));
        return;
    }

    Dart_Handle dartName = V8Converter::stringToDart(name);
    ret = Dart_GetField(handle, dartName);
    if (!Dart_IsError(ret)) {
        setReturnValue(info, ret);
        return;
    }
    ret = Dart_LookupFunction(handle, dartName);
    if (!Dart_IsNull(ret) && !Dart_IsError(ret)) {
        setReturnValue(info, ret);
        return;
    }

    Dart_Handle typeName = Dart_TypeName(handle);
    ASSERT(Dart_IsString(typeName));
    Dart_Handle constructorName = buildConstructorName(typeName, V8Converter::stringToDart(name));
    ret = Dart_LookupFunction(handle, constructorName);
    if (!Dart_IsNull(ret) && !Dart_IsError(ret))
        setReturnValue(info, ret);
}

static void typeNamedPropertySetter(v8::Local<v8::String> property, v8::Local<v8::Value> value, const v8::PropertyCallbackInfo<v8::Value>& info)
{
    DartScopes scopes(info.Holder());
    Dart_Handle handle = scopes.handle;

    ASSERT(Dart_IsType(handle));
    Dart_Handle dartValue = DartHandleProxy::unwrapValue(value);
    v8::Isolate* v8Isolate = v8::Isolate::GetCurrent();
    setReturnValue(info, Dart_Invoke(handle, V8Converter::stringToDart(v8::String::Concat(v8::String::NewFromUtf8(v8Isolate, "set:"), property)), 1, &dartValue));
}

static void typeQueryProperty(v8::Local<v8::String> name, const v8::PropertyCallbackInfo<v8::Integer>& info)
{
    DartScopes scopes(info.Holder());
    Dart_Handle handle = scopes.handle;

    ASSERT(Dart_IsType(handle));
    v8::Isolate* v8Isolate = v8::Isolate::GetCurrent();
    if (name->Equals(v8::String::NewFromUtf8(v8Isolate, "__proto__"))
        || typeHasMember(handle, V8Converter::stringToDart(name)))
        return v8SetReturnValueInt(info, 0);
}

static void typePropertyEnumerator(const v8::PropertyCallbackInfo<v8::Array>& info)
{
    DartScopes scopes(info.Holder());
    Dart_Handle handle = scopes.handle;
    bool showStatics = isShowStatics(info.Holder());

    ASSERT(Dart_IsType(handle));

    v8::Isolate* v8Isolate = v8::Isolate::GetCurrent();
    v8::Local<v8::Array> properties = v8::Array::New(v8Isolate);
    intptr_t count = 0;
    addFunctionNames(handle, properties, &count, !showStatics, false);
    if (showStatics)
        addFieldNames(Dart_GetStaticFields(handle), properties, &count);

    properties->Set(count, v8::String::NewFromUtf8(v8Isolate, "__proto__"));
    count++;
    v8SetReturnValue(info, properties);
}

static void frameNamedPropertyGetter(v8::Local<v8::String> name, const v8::PropertyCallbackInfo<v8::Value>& info)
{
    DartScopes scopes(info.Holder());
    Dart_Handle handle = scopes.handle;

    if (mapContainsKey(handle, V8Converter::stringToDart(name))) {
        Dart_Handle indexedGetterOperator = Dart_NewStringFromCString("[]");
        Dart_Handle dartName = V8Converter::stringToDart(name);
        setReturnValue(info, Dart_Invoke(handle, indexedGetterOperator, 1, &dartName));
    }
    v8::Isolate* v8Isolate = v8::Isolate::GetCurrent();
    if (name->Equals(v8::String::NewFromUtf8(v8Isolate, "__proto__"))) {
        v8SetReturnValue(info, v8::Null(v8Isolate));
    }
}

static void frameNamedPropertySetter(v8::Local<v8::String> property, v8::Local<v8::Value> value, const v8::PropertyCallbackInfo<v8::Value>& info)
{
    v8::Isolate* v8Isolate = v8::Isolate::GetCurrent();
    V8ThrowException::throwException(v8::String::NewFromUtf8(v8Isolate, "Dart does not yet provide a debugger api for setting local fields"), v8Isolate);
}

static void frameQueryProperty(v8::Local<v8::String> name, const v8::PropertyCallbackInfo<v8::Integer>& info)
{
    DartScopes scopes(info.Holder());

    if (mapContainsKey(scopes.handle, V8Converter::stringToDart(name)))
        v8SetReturnValueInt(info, 0);
}

static void framePropertyEnumerator(const v8::PropertyCallbackInfo<v8::Array>& info)
{
    DartScopes scopes(info.Holder());
    Dart_Handle keyList = getMapKeyList(scopes.handle);
    ASSERT(!Dart_IsError(keyList));
    ASSERT(Dart_IsList(keyList));

    intptr_t length = 0;
    Dart_ListLength(keyList, &length);
    v8::Isolate* v8Isolate = v8::Isolate::GetCurrent();
    v8::Local<v8::Array> properties = v8::Array::New(v8Isolate, length);
    for (intptr_t i = 0; i < length; i ++)
        properties->Set(i, V8Converter::stringToV8(Dart_ListGetAt(keyList, i)));
    v8SetReturnValue(info, properties);
}

static void namedPropertyGetter(v8::Local<v8::String> name, const v8::PropertyCallbackInfo<v8::Value>& info)
{
    DartScopes scopes(info.Holder());
    Dart_Handle handle = scopes.handle;

    ASSERT(Dart_IsInstance(handle));
    v8::Isolate* v8Isolate = v8::Isolate::GetCurrent();
    if (name->Equals(v8::String::NewFromUtf8(v8Isolate, "__proto__"))) {
        v8SetReturnValue(info, DartHandleProxy::createTypeProxy(Dart_InstanceGetType(handle), false));
        return;
    }

    v8::String::Utf8Value stringName(name);
    const char* data = *stringName;
    if (data[0] == ':' || data[0] == '#') {
        // Look up a map key instead of a regular property as regular dart property names
        // cannot start with these symbols.
        setReturnValue(info,
            lookupValueForEncodedMapKey(handle, V8Converter::stringToDart(name)));
        return;
    }
    // Prefix for metadata used only by the Dart Editor debugger.
    if (data[0] == '@') {
        if (name->Equals(v8::String::NewFromUtf8(v8Isolate, "@staticFields"))) {
            v8SetReturnValue(info, DartHandleProxy::createTypeProxy(Dart_InstanceGetType(handle), true));
            return;
        }
        if (name->Equals(v8::String::NewFromUtf8(v8Isolate, "@library"))) {
            intptr_t libraryId = 0;
            intptr_t classId = 0;
            Dart_Handle ALLOW_UNUSED result = Dart_GetObjClassId(handle, &classId);
            ASSERT(!Dart_IsError(result));
            result = Dart_GetClassInfo(classId, 0, &libraryId, 0, 0);
            ASSERT(!Dart_IsError(result));
            v8SetReturnValue(info, DartHandleProxy::createLibraryProxy(Dart_GetLibraryFromId(libraryId), libraryId, Dart_Null(), false));
            return;
        }
    }

    Dart_Handle result = Dart_Invoke(handle, V8Converter::stringToDart(v8::String::Concat(v8::String::NewFromUtf8(v8Isolate, "get:"), name)), 0, 0);
    if (Dart_IsError(result)) {
        // To match JS conventions, we should just return undefined if a
        // property does not exist rather than throwing.
        if (Dart_ErrorHasException(result) && isNoSuchMethodError(Dart_ErrorGetException(result)))
            return;
        v8::Isolate* v8Isolate = v8::Isolate::GetCurrent();
        v8Isolate->ThrowException(v8::String::NewFromUtf8(v8Isolate, Dart_GetError(result)));
        return;
    }
    v8SetReturnValue(info, DartHandleProxy::create(result));
}

static void namedPropertySetter(v8::Local<v8::String> property, v8::Local<v8::Value> value, const v8::PropertyCallbackInfo<v8::Value>& info)
{
    DartScopes scopes(info.Holder());
    Dart_Handle handle = scopes.handle;

    Dart_Handle dartValue = DartHandleProxy::unwrapValue(value);
    v8::Isolate* v8Isolate = v8::Isolate::GetCurrent();
    setReturnValue(info, Dart_Invoke(handle, V8Converter::stringToDart(v8::String::Concat(v8::String::NewFromUtf8(v8Isolate, "set:"), property)), 1, &dartValue));
}

static void objectQueryProperty(v8::Local<v8::String> name, const v8::PropertyCallbackInfo<v8::Integer>& info)
{
    DartScopes scopes(info.Holder());
    Dart_Handle handle = scopes.handle;

    Dart_Handle ret;
    ASSERT(Dart_IsInstance(handle));
    v8::String::Utf8Value stringName(name);
    const char* data = *stringName;

    // Looking up a map key instead of a regular property... as regular dart property names
    // cannot start with these symbols.
    if (data[0] == ':' || data[0] == '#') {
        v8SetReturnValueInt(info, v8::ReadOnly);
        return;
    }
    if (data[0] == '@') {
        v8SetReturnValueInt(info, v8::DontEnum);
        return;
    }

    v8::Isolate* v8Isolate = v8::Isolate::GetCurrent();
    ret = Dart_Invoke(handle, V8Converter::stringToDart(v8::String::Concat(v8::String::NewFromUtf8(v8Isolate, "get:"), name)), 0, 0);
    if (Dart_IsError(ret) && !name->Equals(v8::String::NewFromUtf8(v8Isolate, "__proto__"))) {
        return;
    }
    v8SetReturnValueInt(info, 0);
}

static void objectPropertyEnumerator(const v8::PropertyCallbackInfo<v8::Array>& info)
{
    DartScopes scopes(info.Holder());
    Dart_Handle handle = scopes.handle;

    ASSERT(Dart_IsInstance(handle));

    Dart_Handle typeHandle = Dart_InstanceGetType(handle);

    v8::Isolate* v8Isolate = v8::Isolate::GetCurrent();
    v8::Local<v8::Array> properties = v8::Array::New(v8Isolate);
    intptr_t count = 0;
    Dart_Handle mapKeys = getEncodedMapKeyList(handle);
    if (Dart_IsList(mapKeys)) {
        // If the object has map keys, add them all as properties at the start
        // of the list. This aids for debugging although it risks confusing
        // users.
        intptr_t length = 0;
        Dart_ListLength(mapKeys, &length);
        for (intptr_t i = 0; i < length; i++) {
            properties->Set(count, V8Converter::stringToV8(Dart_ListGetAt(mapKeys, i)));
            count++;
        }
    }

    Dart_Handle instanceFields = Dart_GetInstanceFields(handle);
    intptr_t length = 0;
    Dart_ListLength(instanceFields, &length);
    for (intptr_t i = 0; i < length; i += 2) {
        properties->Set(count, DartHandleProxy::create(
            Dart_ListGetAt(instanceFields, i)));
        count++;
    }

    while (!Dart_IsError(typeHandle) && !Dart_IsNull(typeHandle)) {
        addFunctionNames(typeHandle, properties, &count, true, true);
        typeHandle = Dart_GetSupertype(typeHandle);
    }

    properties->Set(count, v8::String::NewFromUtf8(v8Isolate, "@staticFields"));
    count++;
    properties->Set(count, v8::String::NewFromUtf8(v8Isolate, "@library"));
    count++;
    v8SetReturnValue(info, properties);
}

static void indexedGetter(uint32_t index, const v8::PropertyCallbackInfo<v8::Value>& info)
{
    DartScopes scopes(info.Holder());
    Dart_Handle handle = scopes.handle;

    Dart_Handle ret = 0;
    if (Dart_IsList(handle))
        ret = Dart_ListGetAt(handle, index);
    else
        ret = Dart_Null();

    setReturnValue(info, ret);
}

static void indexedSetter(uint32_t index, v8::Local<v8::Value> value, const v8::PropertyCallbackInfo<v8::Value>& info)
{
    DartScopes scopes(info.Holder());
    Dart_Handle handle = scopes.handle;

    Dart_Handle ret = 0;
    if (Dart_IsList(handle))
        ret = Dart_ListSetAt(handle, index, DartHandleProxy::unwrapValue(value));
    else
        ret = Dart_Null();

    setReturnValue(info, ret);
}

static void indexedEnumerator(const v8::PropertyCallbackInfo<v8::Array>& info)
{
    DartScopes scopes(info.Holder());
    Dart_Handle handle = scopes.handle;

    intptr_t length = 0;
    if (Dart_IsList(handle))
        Dart_ListLength(handle, &length);

    v8::Isolate* v8Isolate = v8::Isolate::GetCurrent();
    v8::Local<v8::Array> indexes = v8::Array::New(v8Isolate, length);
    for (int i = 0; i < length; i++)
        indexes->Set(i, v8::Integer::New(v8Isolate, i));

    v8SetReturnValue(info, indexes);
}

static v8::Local<v8::ObjectTemplate> setupInstanceTemplate(v8::Local<v8::FunctionTemplate> proxyTemplate)
{
    v8::Local<v8::ObjectTemplate> instanceTemplate = proxyTemplate->InstanceTemplate();
    instanceTemplate->SetInternalFieldCount(1);
    return instanceTemplate;
}

static v8::Local<v8::FunctionTemplate> objectProxyTemplate(Dart_Handle instance)
{
    DEFINE_STATIC_LOCAL(FunctionTemplateMap, map, ());
    Dart_Handle dartType = Dart_InstanceGetType(instance);
    ASSERT(!Dart_IsError(dartType));
    Dart_Handle typeNameHandle = Dart_TypeName(dartType);
    ASSERT(!Dart_IsError(typeNameHandle));
    v8::Handle<v8::String> typeNameV8 = V8Converter::stringToV8(typeNameHandle);
    String typeName = toCoreString(typeNameV8);
    v8::Persistent<v8::FunctionTemplate>* proxyTemplate = map.get(typeName);
    v8::Local<v8::FunctionTemplate> proxyTemplateLocal;
    v8::Isolate* v8Isolate = v8::Isolate::GetCurrent();
    if (!proxyTemplate) {
        proxyTemplate = new v8::Persistent<v8::FunctionTemplate>(v8Isolate, v8::FunctionTemplate::New(v8Isolate));
        proxyTemplateLocal = v8::Local<v8::FunctionTemplate>::New(v8Isolate, *proxyTemplate);
        proxyTemplateLocal->SetClassName(typeNameV8);
        map.set(typeName, proxyTemplate);
        v8::Local<v8::ObjectTemplate> instanceTemplate = setupInstanceTemplate(proxyTemplateLocal);
        instanceTemplate->SetIndexedPropertyHandler(&indexedGetter, &indexedSetter, 0, 0, &indexedEnumerator);
        instanceTemplate->SetNamedPropertyHandler(&namedPropertyGetter, &namedPropertySetter, &objectQueryProperty, 0, &objectPropertyEnumerator);
    } else {
        proxyTemplateLocal = v8::Local<v8::FunctionTemplate>::New(v8Isolate, *proxyTemplate);
    }
    return proxyTemplateLocal;
}

static v8::Local<v8::FunctionTemplate> functionProxyTemplate()
{
    DEFINE_STATIC_LOCAL(v8::Persistent<v8::FunctionTemplate>, proxyTemplate, ());
    v8::Local<v8::FunctionTemplate> proxyTemplateLocal;
    v8::Isolate* v8Isolate = v8::Isolate::GetCurrent();
    if (proxyTemplate.IsEmpty()) {
        proxyTemplate.Reset(v8::Isolate::GetCurrent(), v8::FunctionTemplate::New(v8Isolate));
        proxyTemplateLocal = v8::Local<v8::FunctionTemplate>::New(v8Isolate, proxyTemplate);
        proxyTemplateLocal->SetClassName(v8::String::NewFromUtf8(v8Isolate, "[Dart Function]"));
        v8::Local<v8::ObjectTemplate> instanceTemplate = setupInstanceTemplate(proxyTemplateLocal);
        instanceTemplate->SetNamedPropertyHandler(&functionNamedPropertyGetter, &functionNamedPropertySetter);
        instanceTemplate->SetCallAsFunctionHandler(&functionInvocationCallback);
    } else {
        proxyTemplateLocal = v8::Local<v8::FunctionTemplate>::New(v8Isolate, proxyTemplate);
    }
    return proxyTemplateLocal;
}

static v8::Local<v8::FunctionTemplate> libraryProxyTemplate(v8::Handle<v8::String> libraryNameV8)
{
    DEFINE_STATIC_LOCAL(FunctionTemplateMap, map, ());
    String typeName = toCoreString(libraryNameV8);
    v8::Persistent<v8::FunctionTemplate>* proxyTemplate = map.get(typeName);
    v8::Local<v8::FunctionTemplate> proxyTemplateLocal;
    v8::Isolate* v8Isolate = v8::Isolate::GetCurrent();
    if (!proxyTemplate) {
        proxyTemplate = new v8::Persistent<v8::FunctionTemplate>(v8Isolate, v8::FunctionTemplate::New(v8Isolate));
        proxyTemplateLocal = v8::Local<v8::FunctionTemplate>::New(v8Isolate, *proxyTemplate);
        proxyTemplateLocal->SetClassName(libraryNameV8);
        map.set(typeName, proxyTemplate);
        v8::Local<v8::ObjectTemplate> instanceTemplate = setupInstanceTemplate(proxyTemplateLocal);
        instanceTemplate->SetNamedPropertyHandler(&libraryNamedPropertyGetter, &libraryNamedPropertySetter, &libraryQueryProperty, 0, &libraryPropertyEnumerator);
    } else {
        proxyTemplateLocal = v8::Local<v8::FunctionTemplate>::New(v8Isolate, *proxyTemplate);
    }
    return proxyTemplateLocal;
}

static v8::Local<v8::FunctionTemplate> typeProxyTemplate(Dart_Handle type)
{
    DEFINE_STATIC_LOCAL(FunctionTemplateMap, map, ());
    Dart_Handle typeNameHandle = Dart_TypeName(type);
    ASSERT(!Dart_IsError(typeNameHandle));
    v8::Handle<v8::String> typeNameV8 = V8Converter::stringToV8(typeNameHandle);
    String typeName = toCoreString(typeNameV8);

    v8::Persistent<v8::FunctionTemplate>* proxyTemplate = map.get(typeName);
    v8::Local<v8::FunctionTemplate> proxyTemplateLocal;
    v8::Isolate* v8Isolate = v8::Isolate::GetCurrent();
    if (!proxyTemplate) {
        proxyTemplate = new v8::Persistent<v8::FunctionTemplate>(v8Isolate, v8::FunctionTemplate::New(v8Isolate));
        proxyTemplateLocal = v8::Local<v8::FunctionTemplate>::New(v8Isolate, *proxyTemplate);
        proxyTemplateLocal->SetClassName(typeNameV8);
        v8::Local<v8::ObjectTemplate> instanceTemplate = setupInstanceTemplate(proxyTemplateLocal);
        instanceTemplate->SetNamedPropertyHandler(&typeNamedPropertyGetter, &typeNamedPropertySetter, &typeQueryProperty, 0, &typePropertyEnumerator);
        instanceTemplate->SetCallAsFunctionHandler(&typeProxyConstructorInvocationCallback);
        map.set(typeName, proxyTemplate);
    } else {
        proxyTemplateLocal = v8::Local<v8::FunctionTemplate>::New(v8Isolate, *proxyTemplate);
    }
    return proxyTemplateLocal;
}

static v8::Local<v8::FunctionTemplate> frameProxyTemplate()
{
    DEFINE_STATIC_LOCAL(v8::Persistent<v8::FunctionTemplate>, proxyTemplate, ());
    v8::Local<v8::FunctionTemplate> proxyTemplateLocal;
    v8::Isolate* v8Isolate = v8::Isolate::GetCurrent();
    if (proxyTemplate.IsEmpty()) {
        proxyTemplate.Reset(v8::Isolate::GetCurrent(), v8::FunctionTemplate::New(v8Isolate));
        proxyTemplateLocal = v8::Local<v8::FunctionTemplate>::New(v8Isolate, proxyTemplate);
        proxyTemplateLocal->SetClassName(v8::String::NewFromUtf8(v8Isolate, "[Dart Frame]"));
        v8::Local<v8::ObjectTemplate> instanceTemplate = setupInstanceTemplate(proxyTemplateLocal);
        instanceTemplate->SetNamedPropertyHandler(&frameNamedPropertyGetter, &frameNamedPropertySetter, &frameQueryProperty, 0, &framePropertyEnumerator);
    } else {
        proxyTemplateLocal = v8::Local<v8::FunctionTemplate>::New(v8Isolate, proxyTemplate);
    }
    return proxyTemplateLocal;
}

v8::Handle<v8::Value> DartHandleProxy::create(Dart_Handle value)
{
    v8::Context::Scope scope(DartUtilities::currentV8Context());
    v8::Isolate* v8Isolate = v8::Isolate::GetCurrent();

    if (Dart_IsNull(value))
        return v8::Null(v8Isolate);
    if (Dart_IsString(value))
        return V8Converter::stringToV8(value);
    if (Dart_IsBoolean(value))
        return V8Converter::booleanToV8(value);
    if (Dart_IsNumber(value))
        return V8Converter::numberToV8(value);
    v8::Local<v8::Object> proxy;
    // We could unwrap Dart DOM types to native types and then rewrap them as
    // JS DOM types but currently we choose not to instead returning JS
    // proxies for the Dart DOM types so that the Dart DOM APIs for DOM types
    // are exposed in the debugger instead of the JS APIs.
    // We attempt to get the best of both worlds by providing the method
    // getJavaScriptType to let debugger APIs treat these Dart proxies for
    // DOM types like native DOM types for cases such as visual Node
    // highlighting.

    DartDOMData* domData = DartDOMData::current();
    // FIXME: refactor code so we do not have to check for Dart_IsFunction.
    if (DartUtilities::isFunction(domData, value) || Dart_IsFunction(value)) {
        proxy = functionProxyTemplate()->InstanceTemplate()->NewInstance();
    } else {
        ASSERT(Dart_IsInstance(value));
        proxy = objectProxyTemplate(value)->InstanceTemplate()->NewInstance();
    }
    writePointerToProxy(proxy, value);
    proxy->SetHiddenValue(v8::String::NewFromUtf8(v8Isolate, "dartProxy"), v8::Boolean::New(v8Isolate, true));

    return proxy;
}

v8::Handle<v8::Value> DartHandleProxy::createTypeProxy(Dart_Handle value, bool showStatics)
{
    ASSERT(Dart_IsType(value));
    v8::Local<v8::Object> proxy = typeProxyTemplate(value)->InstanceTemplate()->NewInstance();
    writePointerToProxy(proxy, value);
    v8::Isolate* v8Isolate = v8::Isolate::GetCurrent();
    proxy->SetHiddenValue(v8::String::NewFromUtf8(v8Isolate, "dartProxy"), v8::Boolean::New(v8Isolate, true));
    proxy->SetHiddenValue(v8::String::NewFromUtf8(v8Isolate, "showStatics"), v8::Boolean::New(v8Isolate, showStatics));
    return proxy;
}

/**
 * Returns the JavaScript type name following the Chrome debugger conventions
 * for Dart objects that have natural JavaScript analogs.
 * This enables visually consistent display of Dart Lists and JavaScript arrays,
 * functions, and DOM nodes.
 */
const char* DartHandleProxy::getJavaScriptType(v8::Handle<v8::Value> value)
{
    DartPersistentValue* scriptValue = readPointerFromProxy(value);
    ASSERT(scriptValue->isIsolateAlive());
    DartIsolateScope scope(scriptValue->isolate());
    DartApiScope apiScope;
    Dart_PersistentHandle handle = scriptValue->value();

    if (Dart_IsInstance(handle)) {
        if (Dart_IsList(handle))
            return "array";

        if (DartDOMWrapper::subtypeOf(handle, DartNode::dartClassId))
            return "node";
    }

    return 0;
}

Node* DartHandleProxy::toNativeNode(v8::Handle<v8::Value> value)
{
    DartPersistentValue* scriptValue = readPointerFromProxy(value);
    ASSERT(scriptValue->isIsolateAlive());
    DartIsolateScope scope(scriptValue->isolate());
    DartApiScope apiScope;
    Dart_PersistentHandle handle = scriptValue->value();
    Dart_Handle exception = 0;
    Node* node = DartNode::toNative(handle, exception);
    ASSERT(!exception);
    return node;
}

/**
 * Creates a proxy for a Dart library.
 * If a string prefix is specified, we similuate that all requests to the library start with
 * the specified prefix.
 */
v8::Handle<v8::Value> DartHandleProxy::createLibraryProxy(Dart_Handle value, intptr_t libraryId, Dart_Handle prefix, bool asGlobal)
{
    v8::Context::Scope scope(DartUtilities::currentV8Context());
    ASSERT(Dart_IsLibrary(value));
    v8::Isolate* v8Isolate = v8::Isolate::GetCurrent();
    v8::Handle<v8::String> libraryNameV8 = Dart_IsNull(prefix) ? V8Converter::stringToV8(Dart_GetLibraryURL(libraryId)) : v8::String::NewFromUtf8(v8Isolate, "[Library Prefix]");
    v8::Local<v8::Object> proxy = libraryProxyTemplate(libraryNameV8)->InstanceTemplate()->NewInstance();
    writePointerToProxy(proxy, value);
    proxy->SetHiddenValue(v8::String::NewFromUtf8(v8Isolate, "libraryId"), v8::Number::New(v8Isolate, libraryId));
    if (Dart_IsString(prefix))
        proxy->SetHiddenValue(v8::String::NewFromUtf8(v8Isolate, "prefix"), V8Converter::stringToV8(prefix));

    if (asGlobal)
        proxy->SetHiddenValue(v8::String::NewFromUtf8(v8Isolate, "asGlobal"), v8::Boolean::New(v8Isolate, true));

    proxy->SetHiddenValue(v8::String::NewFromUtf8(v8Isolate, "dartProxy"), v8::Boolean::New(v8Isolate, true));
    return proxy;
}

v8::Handle<v8::Value> DartHandleProxy::createLocalScopeProxy(Dart_Handle localVariables)
{
    v8::Local<v8::Object> proxy = frameProxyTemplate()->InstanceTemplate()->NewInstance();
    Dart_Handle localScopeVariableMap = createLocalVariablesMap(localVariables);
    ASSERT(!Dart_IsError(localScopeVariableMap));
    writePointerToProxy(proxy, localScopeVariableMap);
    v8::Isolate* v8Isolate = v8::Isolate::GetCurrent();
    proxy->SetHiddenValue(v8::String::NewFromUtf8(v8Isolate, "dartProxy"), v8::Boolean::New(v8Isolate, true));
    return proxy;
}

v8::Handle<v8::Value> DartHandleProxy::evaluate(Dart_Handle target, Dart_Handle expression, Dart_Handle localVariables)
{
    DartDOMData* domData = DartDOMData::current();
    ASSERT(domData);
    ASSERT(Dart_IsList(localVariables) || Dart_IsNull(localVariables));
    v8::Isolate* v8Isolate = v8::Isolate::GetCurrent();
    if (V8Converter::stringToV8(expression)->Equals(v8::String::NewFromUtf8(v8Isolate, "@NamesInScope"))) {
        // Special case: return an object specifying all names that are in
        // scope for the current target. FIXME: we could handle this a lot more
        // efficiently given we don't really care what the values of the
        // variables are just that they are in scope.
        if (Dart_IsLibrary(target))
            return DartHandleProxy::createLibraryProxy(target, DartUtilities::libraryHandleToLibraryId(target), Dart_Null(), true);
        return DartHandleProxy::create(target);
    }

    Dart_Handle exception = 0;
    bool ret = DartUtilities::dartToBool(DartUtilities::invokeUtilsMethod("isJsExpression", 1, &expression), exception);
    ASSERT(!exception);
    if (ret) {
        // FIXME(dartbug.com/13468): remove this hacky fallback of invoking JS
        // code when we believe a JS code fragment generated by the chrome
        // developer tools was passed to us rather than a fragment of true
        // Dart code.
        ASSERT(!v8Isolate->GetCurrentContext().IsEmpty());
        v8::Handle<v8::Value> result = V8ScriptRunner::compileAndRunInternalScript(V8Converter::stringToV8(expression), v8::Isolate::GetCurrent());
        return result;
    }

    bool expectsConsoleApi = DartUtilities::dartToBool(DartUtilities::invokeUtilsMethod("expectsConsoleApi", 1, &expression), exception);
    ASSERT(!exception);
    if (expectsConsoleApi) {
        // Vector of local variables and injected console variables.
        Vector<Dart_Handle> locals;
        if (Dart_IsList(localVariables)) {
            DartUtilities::extractListElements(localVariables, exception, locals);
            ASSERT(!exception);
        }
        // Use JsInterop to proxy all properties and functions defined by
        // window.console._commandLineAPI
        v8::Isolate* v8Isolate = v8::Isolate::GetCurrent();
        v8::Handle<v8::Value> commandLineApiValue = v8Isolate->GetCurrentContext()->Global()->Get(v8::String::NewFromUtf8(v8Isolate, "__commandLineAPI"));
        ASSERT(commandLineApiValue->IsObject());
        if (commandLineApiValue->IsObject()) {
            v8::Handle<v8::Object> commandLineApi = commandLineApiValue.As<v8::Object>();
            v8::Local<v8::Array> propertyNames = commandLineApi->GetOwnPropertyNames();
            uint32_t length = propertyNames->Length();
            ASSERT(length > 0);
            for (uint32_t i = 0; i < length; i++) {
                v8::Handle<v8::String> propertyName = propertyNames->Get(i).As<v8::String>();
                ASSERT(!propertyNames.IsEmpty());
                v8::Handle<v8::Value> propertyValue = commandLineApi->Get(propertyName);

                Dart_Handle dartValue;
                if (propertyValue->IsFunction()) {
                    dartValue = JsInterop::toDart(propertyValue);
                    // We need to wrap the JsFunction object we get back
                    // from the vanila JsInterop library so that users can
                    // call it like a normal Dart function instead of
                    // having to use the apply method.
                    dartValue = Dart_Invoke(domData->jsLibrary(), Dart_NewStringFromCString("_wrapAsDebuggerVarArgsFunction"), 1, &dartValue);
                } else {
                    dartValue = JsInterop::toDart(propertyValue);
                }
                locals.append(V8Converter::stringToDart(propertyName));
                locals.append(dartValue);
            }
        }
        localVariables = DartUtilities::toList(locals, exception);
        ASSERT(!exception);
    }

    Dart_Handle wrapExpressionArgs[2] = { expression, localVariables };
    Dart_Handle wrappedExpressionTuple =
        DartUtilities::invokeUtilsMethod("wrapExpressionAsClosure", 2, wrapExpressionArgs);
    ASSERT(Dart_IsList(wrappedExpressionTuple));
    Dart_Handle wrappedExpression = Dart_ListGetAt(wrappedExpressionTuple, 0);
    Dart_Handle wrappedExpressionArgs = Dart_ListGetAt(wrappedExpressionTuple, 1);

    ASSERT(Dart_IsString(wrappedExpression));
    Dart_Handle closure = Dart_EvaluateExpr(target, wrappedExpression);
    // There was a parse error. FIXME: consider cleaning up the line numbers in
    // the error message.
    if (Dart_IsError(closure))
        return V8ThrowException::throwException(v8::String::NewFromUtf8(v8Isolate, Dart_GetError(closure)), v8::Isolate::GetCurrent());

    // Invoke the closure passing in the expression arguments specified by
    // wrappedExpressionTuple.
    ASSERT(DartUtilities::isFunction(domData, closure));
    intptr_t length = 0;
    Dart_ListLength(wrappedExpressionArgs, &length);
    Vector<Dart_Handle> dartFunctionArgs;
    for (intptr_t i = 0; i < length; i ++)
        dartFunctionArgs.append(Dart_ListGetAt(wrappedExpressionArgs, i));

    Dart_Handle result = Dart_InvokeClosure(closure, dartFunctionArgs.size(), dartFunctionArgs.data());
    if (Dart_IsError(result))
        return V8ThrowException::throwException(v8::String::NewFromUtf8(v8Isolate, Dart_GetError(result)), v8::Isolate::GetCurrent());
    return DartHandleProxy::create(result);
}

}
