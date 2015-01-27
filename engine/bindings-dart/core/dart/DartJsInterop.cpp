/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
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

#include "bindings/core/dart/DartJsInterop.h"

#include "bindings/core/dart/DartDOMWrapper.h"
#include "bindings/core/dart/DartHandleProxy.h"
#include "bindings/core/dart/DartJsInteropData.h"
#include "bindings/core/dart/DartPersistentValue.h"
#include "bindings/core/dart/DartUtilities.h"
#include "bindings/core/dart/V8Converter.h"
#include "bindings/core/v8/V8Binding.h"
#include "bindings/core/v8/V8RecursionScope.h"
#include "bindings/core/v8/V8ScriptRunner.h"

#include "wtf/StdLibExtras.h"

#include <dart_api.h>
#include <limits>

namespace blink {

const int JsObject::dartClassId = _JsObjectClassId;
const int JsFunction::dartClassId = _JsFunctionClassId;
const int JsArray::dartClassId = _JsArrayClassId;

static v8::Local<v8::FunctionTemplate> dartFunctionTemplate();
static v8::Local<v8::FunctionTemplate> dartObjectTemplate();

template<typename CallbackInfo>
void setJsReturnValue(DartDOMData* domData, CallbackInfo info, Dart_Handle result)
{
    if (Dart_IsError(result)) {
        v8::Isolate* v8Isolate = v8::Isolate::GetCurrent();
        V8ThrowException::throwException(v8::String::NewFromUtf8(v8Isolate, Dart_GetError(result)), v8Isolate);
    } else {
        Dart_Handle exception = 0;
        v8::Local<v8::Value> ret = JsInterop::fromDart(domData, result, exception);
        if (exception) {
            V8ThrowException::throwException(V8Converter::stringToV8(Dart_ToString(exception)), v8::Isolate::GetCurrent());
            return;
        }
        v8SetReturnValue(info, ret);
    }
}

static void functionInvocationCallback(const v8::FunctionCallbackInfo<v8::Value>& args)
{
    DartScopes scopes(args.Holder());
    Dart_Handle handle = scopes.handle;
    DartDOMData* domData = DartDOMData::current();
    ASSERT(domData);
    ASSERT(DartUtilities::isFunction(domData, handle));

    Vector<Dart_Handle> dartFunctionArgs;
    ASSERT(args.Length() == 1 || args.Length() == 2);
    // If there is 1 argument, we assume it is a v8:Array or arguments, if
    // there are 2 arguments, the first argument is "this" and the second
    // argument is an array of arguments.
    if (args.Length() > 1) {
        dartFunctionArgs.append(JsInterop::toDart(args[0]));
    }

    v8::Local<v8::Array> argsList = args[args.Length()-1].As<v8::Array>();
    uint32_t argsListLength = argsList->Length();
    for (uint32_t i = 0; i < argsListLength; i++) {
        dartFunctionArgs.append(JsInterop::toDart(argsList->Get(i)));
    }

    setJsReturnValue(domData, args, Dart_InvokeClosure(handle, dartFunctionArgs.size(), dartFunctionArgs.data()));
}

static v8::Local<v8::ObjectTemplate> setupInstanceTemplate(v8::Local<v8::FunctionTemplate> proxyTemplate)
{
    v8::Local<v8::ObjectTemplate> instanceTemplate = proxyTemplate->InstanceTemplate();
    instanceTemplate->SetInternalFieldCount(1);
    return instanceTemplate;
}

static v8::Local<v8::FunctionTemplate> dartFunctionTemplate()
{
    DEFINE_STATIC_LOCAL(v8::Persistent<v8::FunctionTemplate>, proxyTemplate, ());
    v8::Local<v8::FunctionTemplate> proxyTemplateLocal;
    v8::Isolate* v8Isolate = v8::Isolate::GetCurrent();
    if (proxyTemplate.IsEmpty()) {
        proxyTemplate.Reset(v8::Isolate::GetCurrent(), v8::FunctionTemplate::New(v8Isolate));
        proxyTemplateLocal = v8::Local<v8::FunctionTemplate>::New(v8Isolate, proxyTemplate);
        v8::Local<v8::ObjectTemplate> instanceTemplate = setupInstanceTemplate(proxyTemplateLocal);

        instanceTemplate->SetCallAsFunctionHandler(&functionInvocationCallback);
    } else {
        proxyTemplateLocal = v8::Local<v8::FunctionTemplate>::New(v8Isolate, proxyTemplate);
    }
    return proxyTemplateLocal;
}

static v8::Local<v8::FunctionTemplate> dartObjectTemplate()
{
    DEFINE_STATIC_LOCAL(v8::Persistent<v8::FunctionTemplate>, proxyTemplate, ());
    v8::Local<v8::FunctionTemplate> proxyTemplateLocal;
    v8::Isolate* v8Isolate = v8::Isolate::GetCurrent();
    if (proxyTemplate.IsEmpty()) {
        proxyTemplate.Reset(v8Isolate, v8::FunctionTemplate::New(v8Isolate));
        proxyTemplateLocal = v8::Local<v8::FunctionTemplate>::New(v8Isolate, proxyTemplate);
        proxyTemplateLocal->SetClassName(v8::String::NewFromUtf8(v8Isolate, "DartObject"));
        setupInstanceTemplate(proxyTemplateLocal);
    } else {
        proxyTemplateLocal = v8::Local<v8::FunctionTemplate>::New(v8Isolate, proxyTemplate);
    }
    return proxyTemplateLocal;
}

/**
 * Helper class to manage scopes needed for JSInterop code.
 */
class JsInteropScopes {
public:
    Dart_NativeArguments args;
    v8::Context::Scope v8Scope;
    v8::TryCatch tryCatch;

    JsInteropScopes(Dart_NativeArguments args)
        : args(args)
        , v8Scope(DartUtilities::currentV8Context())
    {
        ASSERT(v8::Isolate::GetCurrent());
    }

    ~JsInteropScopes()
    {
        // The user is expected to call handleJsException before the scope is
        // closed so that V8 exceptions are properly sent back to Dart.
        ASSERT(!tryCatch.HasCaught());
    }

    bool handleJsException(Dart_Handle* exception)
    {
        if (!tryCatch.HasCaught())
            return false;
        // FIXME: terminate v8 if tryCatch.CanContinue() is false.
        ASSERT(tryCatch.CanContinue());
        ASSERT(exception);
        v8::Handle<v8::Value> ex(tryCatch.Exception()->ToString());
        if (ex.IsEmpty()) {
            *exception = Dart_NewStringFromCString("Empty JavaScript exception");
        } else {
            *exception = V8Converter::stringToDart(ex);
        }
        tryCatch.Reset();
        return true;
    }

    void setReturnValue(Dart_Handle ret)
    {
        ASSERT(!tryCatch.HasCaught());
        Dart_SetReturnValue(args, ret);
    }

    void setReturnValue(v8::Local<v8::Value> ret)
    {
        ASSERT(!tryCatch.HasCaught());
        Dart_SetReturnValue(args, JsInterop::toDart(ret));
        ASSERT(!tryCatch.HasCaught());
    }

    void setReturnValueInteger(int64_t ret)
    {
        ASSERT(!tryCatch.HasCaught());
        Dart_SetIntegerReturnValue(args, ret);
    }
};

PassRefPtr<JsObject> JsObject::create(v8::Local<v8::Object> v8Handle)
{
    return adoptRef(new JsObject(v8Handle));
}

v8::Local<v8::Value> JsInterop::fromDart(DartDOMData* domData, Dart_Handle handle, Dart_Handle& exception)
{
    v8::Handle<v8::Value> value = V8Converter::toV8IfPrimitive(domData, handle, exception);
    if (!value.IsEmpty() || exception)
        return value;

    value = V8Converter::toV8IfBrowserNative(domData, handle, exception);
    if (!value.IsEmpty() || exception)
        return value;

    if (DartDOMWrapper::subtypeOf(handle, JsObject::dartClassId)) {
        JsObject* object = DartDOMWrapper::unwrapDartWrapper<JsObject>(domData, handle, exception);
        if (exception)
            return v8::Local<v8::Value>();
        return object->localV8Object();
    }

    if (DartUtilities::isFunction(domData, handle)) {
        v8::Local<v8::Object> functionProxy = dartFunctionTemplate()->InstanceTemplate()->NewInstance();
        DartHandleProxy::writePointerToProxy(functionProxy, handle);
        // The raw functionProxy doesn't behave enough like a true JS function
        // so we wrap it in a true JS function.
        return domData->jsInteropData()->wrapDartFunction()->Call(functionProxy, 0, 0);
    }

    v8::Local<v8::Object> proxy;
    ASSERT(Dart_IsInstance(handle));
    proxy = dartObjectTemplate()->InstanceTemplate()->NewInstance();
    DartHandleProxy::writePointerToProxy(proxy, handle);
    v8::Isolate* v8Isolate = v8::Isolate::GetCurrent();
    proxy->SetHiddenValue(v8::String::NewFromUtf8(v8Isolate, "dartProxy"), v8::Boolean::New(v8Isolate, true));

    return proxy;
}

JsObject::JsObject(v8::Local<v8::Object> v8Handle)
{
    v8::Isolate* isolate = v8::Isolate::GetCurrent();
    v8::Persistent<v8::Object> persistentHandle;
    v8Object.Reset(isolate, v8Handle);
}

v8::Local<v8::Object> JsObject::localV8Object()
{
    return v8::Local<v8::Object>::New(v8::Isolate::GetCurrent(), v8Object);
}

Dart_Handle JsInterop::toDart(v8::Local<v8::Value> v8Handle)
{
    Dart_Handle handle = V8Converter::toDartIfPrimitive(v8Handle);
    if (handle)
        return handle;

    ASSERT(v8Handle->IsObject());
    v8::Handle<v8::Object> object = v8Handle.As<v8::Object>();
    Dart_Handle exception = 0;
    handle = V8Converter::toDartIfBrowserNative(object, object->CreationContext()->GetIsolate(), exception);
    ASSERT(!exception);
    if (handle)
        return handle;

    // Unwrap objects passed from Dart to JS that are being passed back to
    // Dart. FIXME: we do not yet handle unwrapping JS functions passed
    // from Dart to JS as we have to wrap them with true JS Function objects.
    // If this use case is important we can support it at the cost of hanging
    // an extra expando off the JS function wrapping the Dart function.
    if (DartHandleProxy::isDartProxy(v8Handle)) {
        DartPersistentValue* scriptValue = DartHandleProxy::readPointerFromProxy(v8Handle);
        ASSERT(scriptValue->isIsolateAlive());
        return scriptValue->value();
    }

    return JsObject::toDart(object);
}

Dart_Handle JsObject::toDart(v8::Local<v8::Object> object)
{
    // FIXME: perform caching so that === can be used.
    if (object->IsFunction()) {
        RefPtr<JsFunction> jsFunction = JsFunction::create(object.As<v8::Function>());
        return JsFunction::toDart(jsFunction);
    }

    if (object->IsArray()) {
        RefPtr<JsArray> jsArray = JsArray::create(object.As<v8::Array>());
        return JsArray::toDart(jsArray);
    }

    RefPtr<JsObject> jsObject = JsObject::create(object);
    return JsObject::toDart(jsObject);
}

Dart_Handle JsObject::toDart(PassRefPtr<JsObject> jsObject)
{
    return DartDOMWrapper::createWrapper<JsObject>(DartDOMData::current(), jsObject.get(), JsObject::dartClassId);
}

JsObject::~JsObject()
{
    v8Object.Reset();
}

Dart_Handle JsFunction::toDart(PassRefPtr<JsFunction> jsFunction)
{
    return DartDOMWrapper::createWrapper<JsFunction>(DartDOMData::current(), jsFunction.get(), JsFunction::dartClassId);
}

JsFunction::JsFunction(v8::Local<v8::Function> v8Handle) : JsObject(v8Handle) { }

PassRefPtr<JsFunction> JsFunction::create(v8::Local<v8::Function> v8Handle)
{
    return adoptRef(new JsFunction(v8Handle));
}

v8::Local<v8::Function> JsFunction::localV8Function()
{
    return localV8Object().As<v8::Function>();
}

Dart_Handle JsArray::toDart(PassRefPtr<JsArray> jsArray)
{
    return DartDOMWrapper::createWrapper<JsArray>(DartDOMData::current(), jsArray.get(), JsArray::dartClassId);
}

JsArray::JsArray(v8::Local<v8::Array> v8Handle) : JsObject(v8Handle) { }

PassRefPtr<JsArray> JsArray::create(v8::Local<v8::Array> v8Handle)
{
    return adoptRef(new JsArray(v8Handle));
}

v8::Local<v8::Array> JsArray::localV8Array()
{
    return localV8Object().As<v8::Array>();
}

namespace JsInteropInternal {

typedef HashMap<Dart_Handle, v8::Handle<v8::Value> > DartHandleToV8Map;
v8::Handle<v8::Value> jsifyHelper(DartDOMData*, Dart_Handle value, DartHandleToV8Map&, Dart_Handle& exception);

void argsListToV8(DartDOMData* domData, Dart_Handle args, Vector<v8::Local<v8::Value> >* v8Args, Dart_Handle& exception)
{
    if (Dart_IsNull(args))
        return;

    if (!Dart_IsList(args)) {
        exception = Dart_NewStringFromCString("args not type list");
        return;
    }

    intptr_t argsLength = 0;
    Dart_ListLength(args, &argsLength);
    for (intptr_t i = 0; i < argsLength; i++) {
        v8Args->append(JsInterop::fromDart(domData, Dart_ListGetAt(args, i), exception));
        if (exception)
            return;
    }
}

void argsListToV8DebuggerOnly(DartDOMData* domData, Dart_Handle args, Vector<v8::Local<v8::Value> >* v8Args, Dart_Handle& exception)
{
    if (Dart_IsNull(args))
        return;

    if (!Dart_IsList(args)) {
        exception = Dart_NewStringFromCString("args not type list");
        return;
    }

    intptr_t argsLength = 0;
    Dart_ListLength(args, &argsLength);
    for (intptr_t i = 0; i < argsLength; i++) {
        v8Args->append(DartHandleProxy::create(Dart_ListGetAt(args, i)));
    }
}

static void jsObjectConstructorCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        JsInteropScopes scopes(args);
        DartDOMData* domData = static_cast<DartDOMData*>(Dart_GetNativeIsolateData(args));
        v8::Local<v8::Value> constructorArg = JsInterop::fromDart(domData, Dart_GetNativeArgument(args, 0), exception);
        if (exception)
            goto fail;

        if (!constructorArg->IsFunction()) {
            exception = Dart_NewStringFromCString("constructor not a function");
            goto fail;
        }

        Vector<v8::Local<v8::Value> > v8Args;
        argsListToV8(domData, Dart_GetNativeArgument(args, 1), &v8Args, exception);

        v8::Local<v8::Value> ret = constructorArg.As<v8::Function>()->CallAsConstructor(v8Args.size(), v8Args.data());
        crashIfV8IsDead();

        if (scopes.handleJsException(&exception))
            goto fail;

        // Intentionally skip auto-conversion in this case as the user expects
        // a JSObject. FIXME: evaluate if this is the right solution.
        // Alternately, we could throw an exception.
        if (ret->IsObject()) {
            scopes.setReturnValue(JsObject::toDart(ret.As<v8::Object>()));
        } else {
            // This will throw an exception in Dart checked mode.
            scopes.setReturnValue(ret);
        }
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

static void identityEqualityCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        JsInteropScopes scopes(args);
        DartDOMData* domData = static_cast<DartDOMData*>(Dart_GetNativeIsolateData(args));
        v8::Local<v8::Value> a = JsInterop::fromDart(domData, Dart_GetNativeArgument(args, 0), exception);
        if (exception)
            goto fail;
        v8::Local<v8::Value> b = JsInterop::fromDart(domData, Dart_GetNativeArgument(args, 1), exception);
        if (exception)
            goto fail;

        bool strictEquals = a->StrictEquals(b);

        if (scopes.handleJsException(&exception))
            goto fail;
        scopes.setReturnValue(DartUtilities::boolToDart(strictEquals));
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

static void getterCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        JsInteropScopes scopes(args);
        JsObject* receiver = DartDOMWrapper::receiver<JsObject>(args);
        v8::Local<v8::Object> v8Receiver = receiver->localV8Object();
        Dart_Handle index = Dart_GetNativeArgument(args, 1);
        uint64_t intIndex = 0;
        v8::Local<v8::Value> ret;

        if (Dart_IsInteger(index)) {
            bool isUint64 = false;
            Dart_IntegerFitsIntoUint64(index, &isUint64);
            if (isUint64) {
                Dart_Handle ALLOW_UNUSED result = Dart_IntegerToUint64(index, &intIndex);
                if (intIndex <= std::numeric_limits<uint32_t>::max()) {
                    ASSERT(!Dart_IsError(result));
                    ret = v8Receiver->Get((uint32_t)intIndex);
                } else {
                    ret = v8Receiver->Get(V8Converter::numberToV8(index));
                }
            } else {
                ret = v8Receiver->Get(V8Converter::numberToV8(index));
            }
        } else if (Dart_IsString(index)) {
            ret = v8Receiver->Get(V8Converter::stringToV8(index));
        } else if (Dart_IsNumber(index)) {
            ret = v8Receiver->Get(V8Converter::numberToV8(index));
        } else {
            ret = v8Receiver->Get(V8Converter::stringToV8(Dart_ToString(index)));
        }

        if (scopes.handleJsException(&exception))
            goto fail;
        scopes.setReturnValue(ret);
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

static void hasPropertyCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        JsInteropScopes scopes(args);
        JsObject* receiver = DartDOMWrapper::receiver<JsObject>(args);
        v8::Local<v8::Object> v8Receiver = receiver->localV8Object();
        Dart_Handle property = Dart_GetNativeArgument(args, 1);

        if (!Dart_IsString(property))
            property = Dart_ToString(property);

        bool hasProperty = v8Receiver->Has(V8Converter::stringToV8(property));
        if (scopes.handleJsException(&exception))
            goto fail;
        scopes.setReturnValue(DartUtilities::boolToDart(hasProperty));
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

static void deletePropertyCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        JsInteropScopes scopes(args);
        JsObject* receiver = DartDOMWrapper::receiver<JsObject>(args);
        v8::Local<v8::Object> v8Receiver = receiver->localV8Object();
        Dart_Handle property = Dart_GetNativeArgument(args, 1);
        if (!Dart_IsString(property))
            property = Dart_ToString(property);

        v8Receiver->Delete(V8Converter::stringToV8(property));
        if (scopes.handleJsException(&exception))
            goto fail;
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

static void instanceofCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        JsInteropScopes scopes(args);
        DartDOMData* domData = static_cast<DartDOMData*>(Dart_GetNativeIsolateData(args));
        JsObject* receiver = DartDOMWrapper::receiver<JsObject>(args);
        v8::Local<v8::Object> v8Receiver = receiver->localV8Object();
        v8::Local<v8::Value> type = JsInterop::fromDart(domData, Dart_GetNativeArgument(args, 1), exception);

        // FIXME: we could optimize the following lines slightly as the return
        // type is bool.
        v8::Local<v8::Value> ret = domData->jsInteropData()->instanceofFunction()->Call(v8Receiver, 1, &type);
        if (scopes.handleJsException(&exception))
            goto fail;
        scopes.setReturnValue(ret);
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

static void setterCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        JsInteropScopes scopes(args);
        DartDOMData* domData = static_cast<DartDOMData*>(Dart_GetNativeIsolateData(args));
        JsObject* receiver = DartDOMWrapper::receiver<JsObject>(args);
        v8::Local<v8::Object> v8Receiver = receiver->localV8Object();
        Dart_Handle index = Dart_GetNativeArgument(args, 1);
        v8::Local<v8::Value> value = JsInterop::fromDart(domData, Dart_GetNativeArgument(args, 2), exception);
        if (exception)
            goto fail;
        uint64_t intIndex = 0;
        bool ret = false;
        if (Dart_IsInteger(index)) {
            bool isUint64 = false;
            Dart_IntegerFitsIntoUint64(index, &isUint64);
            if (isUint64) {
                Dart_Handle ALLOW_UNUSED result = Dart_IntegerToUint64(index, &intIndex);
                if (intIndex <= std::numeric_limits<uint32_t>::max()) {
                    ASSERT(!Dart_IsError(result));
                    ret = v8Receiver->Set((uint32_t)intIndex, value);
                } else {
                    ret = v8Receiver->Set(V8Converter::numberToV8(index), value);
                }
            } else {
                ret = v8Receiver->Set(V8Converter::numberToV8(index), value);
            }
        } else if (Dart_IsString(index)) {
            ret = v8Receiver->Set(V8Converter::stringToV8(index), value);
        } else if (Dart_IsNumber(index)) {
            ret = v8Receiver->Set(V8Converter::numberToV8(index), value);
        } else {
            ret = v8Receiver->Set(V8Converter::stringToV8(Dart_ToString(index)), value);
        }

        if (scopes.handleJsException(&exception))
            goto fail;
        scopes.setReturnValue(DartUtilities::boolToDart(ret));
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

static void hashCodeCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        JsInteropScopes scopes(args);
        JsObject* receiver = DartDOMWrapper::receiver<JsObject>(args);
        int hashCode = receiver->localV8Object()->GetIdentityHash();
        // FIXME: salt the v8 hashcode so we don't leak information about v8
        // memory allocation.
        if (scopes.handleJsException(&exception))
            goto fail;
        scopes.setReturnValueInteger(hashCode);
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

static void callMethodCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        JsInteropScopes scopes(args);
        DartDOMData* domData = static_cast<DartDOMData*>(Dart_GetNativeIsolateData(args));
        JsObject* receiver = DartDOMWrapper::receiver<JsObject>(args);
        v8::Local<v8::Object> v8Receiver = receiver->localV8Object();

        Dart_Handle name = Dart_GetNativeArgument(args, 1);
        Vector<v8::Local<v8::Value> > v8Args;
        argsListToV8(domData, Dart_GetNativeArgument(args, 2), &v8Args, exception);
        if (exception)
            goto fail;
        if (!Dart_IsString(name))
            name = Dart_ToString(name);

        v8::Local<v8::Value> value = v8Receiver->Get(V8Converter::stringToV8(name));
        v8::Local<v8::Value> ret;
        if (value->IsFunction()) {
            ret = V8ScriptRunner::callFunction(value.As<v8::Function>(), DartUtilities::scriptExecutionContext(), receiver->localV8Object(), v8Args.size(), v8Args.data(), v8::Isolate::GetCurrent());
        } else if (value->IsObject()) {
            ret = V8ScriptRunner::callAsFunction(v8::Isolate::GetCurrent(), value.As<v8::Object>(), receiver->localV8Object(), v8Args.size(), v8Args.data());
        } else {
            // FIXME: we currently convert this exception to a NoSuchMethod
            // exception in the Dart code that wraps this native method.
            // Consider throwing a NoSuchMethod exception directly instead.
            exception = Dart_NewStringFromCString("property is not a function");
            goto fail;
        }

        if (scopes.handleJsException(&exception))
            goto fail;
        scopes.setReturnValue(ret);
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

static void newJsArrayCallback(Dart_NativeArguments args)
{
    JsInteropScopes scopes(args);
    scopes.setReturnValue(JsObject::toDart(v8::Array::New(v8::Isolate::GetCurrent())));
    return;
}

static void newJsArrayFromSafeListCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        JsInteropScopes scopes(args);
        DartDOMData* domData = static_cast<DartDOMData*>(Dart_GetNativeIsolateData(args));
        Dart_Handle list = Dart_GetNativeArgument(args, 0);
        // Code on the Dart side insures this arg is a native Dart list.
        ASSERT(Dart_IsList(list));

        intptr_t length = 0;
        Dart_Handle result = Dart_ListLength(list, &length);
        ASSERT(!Dart_IsError(result));
        v8::Local<v8::Array> array = v8::Array::New(v8::Isolate::GetCurrent(), length);

        for (intptr_t i = 0; i < length; ++i) {
            result = Dart_ListGetAt(list, i);
            ASSERT(!Dart_IsError(result));
            v8::Handle<v8::Value> v8value = JsInterop::fromDart(domData, result, exception);
            if (exception)
                goto fail;

            array->Set(i, v8value);
        }
        scopes.setReturnValue(array);
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}


static void jsArrayLengthCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        JsInteropScopes scopes(args);
        JsArray* receiver = DartDOMWrapper::receiver<JsArray>(args);
        uint32_t length = receiver->localV8Array()->Length();
        if (scopes.handleJsException(&exception))
            goto fail;
        scopes.setReturnValueInteger(length);
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

static void fromBrowserObjectCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        JsInteropScopes scopes(args);
        DartDOMData* domData = static_cast<DartDOMData*>(Dart_GetNativeIsolateData(args));

        v8::Local<v8::Value> ret = V8Converter::toV8IfBrowserNative(domData, Dart_GetNativeArgument(args, 0), exception);
        if (ret.IsEmpty()) {
            exception = Dart_NewStringFromCString("object must be an Node, ArrayBuffer, Blob, ImageData, or IDBKeyRange");
            goto fail;
        }
        if (exception)
            goto fail;
        ASSERT(ret->IsObject());
        if (scopes.handleJsException(&exception))
            goto fail;
        scopes.setReturnValue(JsObject::toDart(ret.As<v8::Object>()));
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

static void applyCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        JsInteropScopes scopes(args);
        DartDOMData* domData = static_cast<DartDOMData*>(Dart_GetNativeIsolateData(args));
        JsFunction* receiver = DartDOMWrapper::receiver<JsFunction>(args);

        Vector<v8::Local<v8::Value> > v8Args;
        argsListToV8(domData, Dart_GetNativeArgument(args, 1), &v8Args, exception);
        if (exception)
            goto fail;

        v8::Local<v8::Value> thisArg;
        Dart_Handle thisArgDart = Dart_GetNativeArgument(args, 2);
        if (Dart_IsNull(thisArgDart)) {
            // Use the global v8 object if no Dart thisArg was passed in.
            thisArg = DartUtilities::currentV8Context()->Global();
        } else {
            thisArg = JsInterop::fromDart(domData, thisArgDart, exception);
            if (exception)
                goto fail;
            if (!thisArg->IsObject()) {
                exception = Dart_NewStringFromCString("thisArg is not an object");
                goto fail;
            }
        }

        v8::Local<v8::Value> ret = V8ScriptRunner::callFunction(receiver->localV8Function(), DartUtilities::scriptExecutionContext(), thisArg.As<v8::Object>(), v8Args.size(), v8Args.data(), v8::Isolate::GetCurrent());
        if (scopes.handleJsException(&exception))
            goto fail;
        scopes.setReturnValue(ret);
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

static void applyDebuggerOnlyCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        JsInteropScopes scopes(args);
        DartDOMData* domData = static_cast<DartDOMData*>(Dart_GetNativeIsolateData(args));
        JsFunction* receiver = DartDOMWrapper::receiver<JsFunction>(args);

        Vector<v8::Local<v8::Value> > v8Args;
        argsListToV8DebuggerOnly(domData, Dart_GetNativeArgument(args, 1), &v8Args, exception);
        if (exception)
            goto fail;

        v8::Local<v8::Value> thisArg;
        Dart_Handle thisArgDart = Dart_GetNativeArgument(args, 2);
        if (Dart_IsNull(thisArgDart)) {
            // Use the global v8 object if no Dart thisArg was passed in.
            thisArg = DartUtilities::currentV8Context()->Global();
        } else {
            thisArg = JsInterop::fromDart(domData, thisArgDart, exception);
            if (exception)
                goto fail;
            if (!thisArg->IsObject()) {
                exception = Dart_NewStringFromCString("thisArg is not an object");
                goto fail;
            }
        }

        v8::Local<v8::Value> ret = V8ScriptRunner::callFunction(receiver->localV8Function(), DartUtilities::scriptExecutionContext(), thisArg.As<v8::Object>(), v8Args.size(), v8Args.data(), v8::Isolate::GetCurrent());
        if (scopes.handleJsException(&exception))
            goto fail;
        scopes.setReturnValue(ret);
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

static void toStringCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        JsInteropScopes scopes(args);
        JsObject* receiver = DartDOMWrapper::receiver<JsObject>(args);
        v8::Local<v8::Object> v8Object = receiver->localV8Object();
        if (scopes.handleJsException(&exception))
            goto fail;
        if (v8Object.IsEmpty()) {
            exception = Dart_NewStringFromCString("Invalid v8 handle");
            goto fail;
        }

        v8::Local<v8::String> v8String = v8Object->ToString();
        if (scopes.handleJsException(&exception))
            goto fail;
        scopes.setReturnValue(v8String);
        return;
    }
fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

static void contextCallback(Dart_NativeArguments args)
{
    v8::Local<v8::Context> v8Context = DartUtilities::currentV8Context();
    v8::Context::Scope scope(v8Context);
    Dart_SetReturnValue(args, JsObject::toDart(v8Context->Global()));
}

v8::Handle<v8::Value> mapToV8(DartDOMData* domData, Dart_Handle value, DartHandleToV8Map& map, Dart_Handle& exception)
{
    Dart_Handle asList = DartUtilities::invokeUtilsMethod("convertMapToList", 1, &value);
    if (!DartUtilities::checkResult(asList, exception))
        return v8::Handle<v8::Value>();
    ASSERT(Dart_IsList(asList));

    // Now we have a list [key, value, key, value, ....], create a v8 object and set necesary
    // properties on it.
    v8::Handle<v8::Object> object = v8::Object::New(v8::Isolate::GetCurrent());
    map.set(value, object);

    // We converted to internal Dart list, methods shouldn't throw exceptions now.
    intptr_t length = 0;
    Dart_Handle ALLOW_UNUSED result = Dart_ListLength(asList, &length);
    ASSERT(!Dart_IsError(result));
    ASSERT(!(length % 2));
    for (intptr_t i = 0; i < length; i += 2) {
        v8::Handle<v8::Value> key = jsifyHelper(domData, Dart_ListGetAt(asList, i), map, exception);
        if (exception)
            return v8::Handle<v8::Value>();
        v8::Handle<v8::Value> value = jsifyHelper(domData, Dart_ListGetAt(asList, i + 1), map, exception);
        if (exception)
            return v8::Handle<v8::Value>();

        object->Set(key, value);
    }

    return object;
}

v8::Handle<v8::Value> listToV8(DartDOMData* domData, Dart_Handle value, DartHandleToV8Map& map, Dart_Handle& exception)
{
    ASSERT(Dart_IsList(value));

    intptr_t length = 0;
    Dart_Handle result = Dart_ListLength(value, &length);
    if (!DartUtilities::checkResult(result, exception))
        return v8::Handle<v8::Value>();

    v8::Local<v8::Array> array = v8::Array::New(v8::Isolate::GetCurrent(), length);
    map.set(value, array);

    for (intptr_t i = 0; i < length; ++i) {
        result = Dart_ListGetAt(value, i);
        if (!DartUtilities::checkResult(result, exception))
            return v8::Handle<v8::Value>();
        v8::Handle<v8::Value> v8value = jsifyHelper(domData, result, map, exception);
        if (exception)
            return v8::Handle<v8::Value>();
        array->Set(i, v8value);
    }

    return array;
}

v8::Handle<v8::Value> jsifyHelper(DartDOMData* domData, Dart_Handle value, DartHandleToV8Map& map, Dart_Handle& exception)
{
    DartHandleToV8Map::iterator iter = map.find(value);
    if (iter != map.end())
        return iter->value;

    if (Dart_IsList(value))
        return listToV8(domData, value, map, exception);

    bool isMap = DartUtilities::dartToBool(DartUtilities::invokeUtilsMethod("isMap", 1, &value), exception);
    ASSERT(!exception);
    if (isMap)
        return mapToV8(domData, value, map, exception);

    Dart_Handle maybeList = DartUtilities::invokeUtilsMethod("toListIfIterable", 1, &value);
    if (Dart_IsList(maybeList))
        return listToV8(domData, maybeList, map, exception);

    v8::Handle<v8::Value> ret = JsInterop::fromDart(domData, value, exception);
    map.set(value, ret);
    return ret;
}

static void jsifyCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        JsInteropScopes scopes(args);
        Dart_Handle value = Dart_GetNativeArgument(args, 0);
        DartDOMData* domData = static_cast<DartDOMData*>(Dart_GetNativeIsolateData(args));
        DartHandleToV8Map map;
        v8::Local<v8::Value> ret = jsifyHelper(domData, value, map, exception);
        if (exception)
            goto fail;

        if (scopes.handleJsException(&exception))
            goto fail;
        // Intentionally skip auto-conversion in this case as the user expects
        // a JSObject. FIXME: evaluate if this is the right solution.
        // Alternately, we could throw an exception.
        if (ret->IsObject()) {
            scopes.setReturnValue(JsObject::toDart(ret.As<v8::Object>()));
        } else {
            // This will throw an exception in Dart checked mode.
            scopes.setReturnValue(ret);
        }
        return;
    }
fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

static void withThisCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        JsInteropScopes scopes(args);
        Dart_Handle function = Dart_GetNativeArgument(args, 0);
        DartDOMData* domData = static_cast<DartDOMData*>(Dart_GetNativeIsolateData(args));
        ASSERT(DartUtilities::isFunction(domData, function));

        v8::Local<v8::Object> proxy = dartFunctionTemplate()->InstanceTemplate()->NewInstance();
        DartHandleProxy::writePointerToProxy(proxy, function);

        v8::Local<v8::Function> ret = v8::Local<v8::Function>::Cast(domData->jsInteropData()->captureThisFunction()->Call(proxy, 0, 0));

        if (scopes.handleJsException(&exception))
            goto fail;
        scopes.setReturnValue(ret);
        return;
    }
fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

}

static DartNativeEntry nativeEntries[] = {
    { JsInteropInternal::jsObjectConstructorCallback, 2, "JsObject_constructorCallback" },
    { JsInteropInternal::contextCallback, 0, "Js_context_Callback" },
    { JsInteropInternal::jsifyCallback, 1, "JsObject_jsify" },
    { JsInteropInternal::withThisCallback, 1, "JsFunction_withThis" },
    { JsInteropInternal::getterCallback, 2, "JsObject_[]" },
    { JsInteropInternal::setterCallback, 3, "JsObject_[]=" },
    { JsInteropInternal::hashCodeCallback, 1, "JsObject_hashCode" },
    { JsInteropInternal::callMethodCallback, 3, "JsObject_callMethod" },
    { JsInteropInternal::toStringCallback, 1, "JsObject_toString" },
    { JsInteropInternal::identityEqualityCallback, 2, "JsObject_identityEquality" },
    { JsInteropInternal::hasPropertyCallback, 2, "JsObject_hasProperty" },
    { JsInteropInternal::deletePropertyCallback, 2, "JsObject_deleteProperty" },
    { JsInteropInternal::instanceofCallback, 2, "JsObject_instanceof" },
    { JsInteropInternal::applyCallback, 3, "JsFunction_apply" },
    { JsInteropInternal::applyDebuggerOnlyCallback, 3, "JsFunction_applyDebuggerOnly" },
    { JsInteropInternal::newJsArrayCallback, 0, "JsArray_newJsArray" },
    { JsInteropInternal::newJsArrayFromSafeListCallback, 1, "JsArray_newJsArrayFromSafeList" },
    { JsInteropInternal::jsArrayLengthCallback, 1, "JsArray_length" },
    { JsInteropInternal::fromBrowserObjectCallback, 1, "JsObject_fromBrowserObject" },
    { 0, 0, 0 },
};

Dart_NativeFunction JsInterop::resolver(Dart_Handle nameHandle, int argumentCount, bool* autoSetupScope)
{
    ASSERT(autoSetupScope);
    *autoSetupScope = true;
    String name = DartUtilities::toString(nameHandle);

    for (intptr_t i = 0; nativeEntries[i].nativeFunction != 0; i++) {
        if (argumentCount == nativeEntries[i].argumentCount && name == nativeEntries[i].name) {
            return nativeEntries[i].nativeFunction;
        }
    }

    return 0;
}

const uint8_t* JsInterop::symbolizer(Dart_NativeFunction nf)
{
    for (intptr_t i = 0; nativeEntries[i].nativeFunction != 0; i++) {
        if (nf == nativeEntries[i].nativeFunction) {
            return reinterpret_cast<const uint8_t*>(nativeEntries[i].name);
        }
    }
    return 0;
}

}
