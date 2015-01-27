// Copyright 2012, Google Inc.
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//    * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//    * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#include "config.h"
#include "bindings/core/dart/DartNativeUtilities.h"

#include "bindings/core/dart/DartController.h"
#include "bindings/core/dart/DartCustomElementConstructorBuilder.h"
#include "bindings/core/dart/DartCustomElementLifecycleCallbacks.h"
#include "bindings/core/dart/DartCustomElementWrapper.h"
#include "bindings/core/dart/DartDOMData.h"
#include "bindings/core/dart/DartDOMStringMap.h"
#include "bindings/core/dart/DartDOMWrapper.h"
#include "bindings/core/dart/DartDocument.h"
#include "bindings/core/dart/DartElement.h"
#include "bindings/core/dart/DartHTMLElement.h"
#include "bindings/core/dart/DartJsInterop.h"
#include "bindings/core/dart/DartUtilities.h"
#include "bindings/core/dart/DartWindow.h"
#include "bindings/core/dart/V8Converter.h"
#include "bindings/core/v8/ScriptController.h"
#include "bindings/core/v8/npruntime_impl.h"
#include "core/dom/Document.h"
#include "core/dom/custom/CustomElementCallbackDispatcher.h"
#include "core/dom/custom/CustomElementRegistrationContext.h"
#include "core/frame/LocalFrame.h"
#include "core/html/HTMLElement.h"
#include "platform/RuntimeEnabledFeatures.h"

#include "wtf/HashMap.h"
#include "wtf/StdLibExtras.h"
#include "wtf/text/CString.h"
#include "wtf/text/StringHash.h"
#include <bindings/npruntime.h>
#include <dart_api.h>

namespace blink {

namespace DartNativeUtilitiesInternal {

static void topLevelWindow(Dart_NativeArguments args)
{
    // Return full LocalDOMWindow implementation (DartDOMWrapper::createWrapper always returns a secure wrapper).
    LocalDOMWindow* window = DartUtilities::domWindowForCurrentIsolate();
    DartDOMWrapper::returnToDart<DartWindow>(args, window);
}

/**
 * Gadget for testing.
 *
 * With DART_FORWARDING_PRINT environment variable set, it invokes dartPrint
 * JavaScript function on global object to communicate to Dart test framework.
 */
static void forwardingPrint(Dart_NativeArguments args)
{
    v8::Isolate* v8Isolate = v8::Isolate::GetCurrent();
    v8::HandleScope v8Scope(v8Isolate);
    ExecutionContext* scriptExecutionContext = DartUtilities::scriptExecutionContext();
    ASSERT(scriptExecutionContext);

    DartController* dartController = DartController::retrieve(scriptExecutionContext);
    if (!dartController)
        return;
    LocalFrame* frame = dartController->frame();
    v8::Handle<v8::Context> v8Context = toV8Context(frame, DOMWrapperWorld::mainWorld());
    v8::Context::Scope scope(v8Context);
    v8::TryCatch tryCatch;

    v8::Handle<v8::Value> function = v8Context->Global()->Get(v8::String::NewFromUtf8(v8Isolate, "dartPrint"));
    if (function.IsEmpty() || !function->IsFunction())
        return;

    v8::Handle<v8::Value> message = V8Converter::stringToV8(Dart_GetNativeArgument(args, 0));
    function.As<v8::Function>()->Call(v8Context->Global(), 1, &message);
}

static void getNewIsolateId(Dart_NativeArguments args)
{
    static int isolateId = 0;
    Dart_SetReturnValue(args, DartUtilities::intToDart(isolateId++));
}

static void registerElement(Dart_NativeArguments args)
{
    DartApiScope dartApiScope;
    Dart_Handle exception = 0;
    {
        ExecutionContext* ALLOW_UNUSED scriptExecutionContext = DartUtilities::scriptExecutionContext();
        ASSERT(scriptExecutionContext);

        Document* document = DartDocument::toNative(args, 0, exception);
        if (exception)
            goto fail;

        DartStringAdapter name = DartUtilities::dartToString(args, 1, exception);
        if (exception)
            goto fail;

        Dart_Handle customType = Dart_GetNativeArgument(args, 2);
        ASSERT(Dart_IsType(customType));

        AtomicString extendsTagName;
        Dart_Handle extendsArg = Dart_GetNativeArgument(args, 3);
        if (!Dart_IsNull(extendsArg)) {
            extendsTagName = DartUtilities::dartToString(extendsArg, exception);
            if (exception) {
                goto fail;
            }
        }

        CustomElementRegistrationContext* registrationContext = document->registrationContext();
        if (!registrationContext) {
            DartExceptionState es;
            es.throwDOMException(NotSupportedError);
            exception = es.toDart(args);
            goto fail;
        }

        DartScriptState* scriptState = DartUtilities::currentScriptState();

        CustomElementCallbackDispatcher::CallbackDeliveryScope deliveryScope;

        const Dictionary dictionary;
        DartCustomElementConstructorBuilder constructorBuilder(customType, extendsTagName, scriptState, &dictionary);
        DartExceptionState es;
        registrationContext->registerElement(document, &constructorBuilder, name, CustomElement::AllNames, es);
        if (es.hadException()) {
            exception = es.toDart(args);
            goto fail;
        }
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

// Fast-path for Document.createElement, when typeExtension is not needed.
void createElement(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        Document* receiver = DartDOMWrapper::receiver< Document >(args);

        DartStringAdapter localName = DartUtilities::dartToString(args, 1, exception);
        if (exception)
            goto fail;

        DartExceptionState es;
        RefPtr<Element> result;
        {
            CustomElementCallbackDispatcher::CallbackDeliveryScope deliveryScope;

            result = receiver->createElement(localName, es);
        }
        DartElement::returnToDart(args, result);
        if (es.hadException()) {
            exception = es.toDart(args);
            goto fail;
        }
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

void initializeCustomElement(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        Dart_Handle elementWrapper = Dart_GetNativeArgument(args, 0);
        if (!DartDOMWrapper::subtypeOf(elementWrapper, DartHTMLElement::dartClassId)) {
            exception = Dart_NewStringFromCString("created called outside of custom element creation.");
            goto fail;
        }
        DartCustomElementWrapper<HTMLElement>::initializeCustomElement(elementWrapper, exception);
        if (exception) {
            goto fail;
        }
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

void spawnDomUri(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;

    {
        ExecutionContext* scriptExecutionContext = DartUtilities::scriptExecutionContext();
        ASSERT(scriptExecutionContext);
        DartController* dartController = DartController::retrieve(scriptExecutionContext);
        if (!dartController)
            return;

        DartStringAdapter uri = DartUtilities::dartToString(args, 0, exception);
        if (exception)
            goto fail;

        // TODO(vsm): Return isolate future.
        dartController->spawnDomUri(uri);
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

void changeElementWrapper(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        Dart_Handle elementWrapper = Dart_GetNativeArgument(args, 0);
        if (!DartDOMWrapper::subtypeOf(elementWrapper, DartHTMLElement::dartClassId)) {
            exception = Dart_NewStringFromCString("Invalid class: expected instance of HtmlElement");
            goto fail;
        }

        Dart_Handle wrapperType = Dart_GetNativeArgument(args, 1);
        if (!Dart_IsType(wrapperType)) {
            exception = Dart_NewStringFromCString("Expected instance of Type");
            goto fail;
        }

        Dart_Handle newWrapper = DartCustomElementWrapper<HTMLElement>::changeElementWrapper(elementWrapper, wrapperType);
        if (Dart_IsError(newWrapper)) {
            exception = newWrapper;
            goto fail;
        }
        Dart_SetReturnValue(args, newWrapper);
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

} // namespace DartNativeUtilitiesInternal

namespace DartWindowInternal {

void historyCrossFrameGetter(Dart_NativeArguments);

void locationCrossFrameGetter(Dart_NativeArguments);

}

extern Dart_NativeFunction blinkSnapshotResolver(Dart_Handle name, int argumentCount, bool* autoSetupScope);
extern Dart_NativeFunction customDartDOMStringMapResolver(Dart_Handle name, int argumentCount, bool* autoSetupScope);

static DartNativeEntry nativeEntries[] = {
    { DartNativeUtilitiesInternal::topLevelWindow, 0, "Utils_window" },
    { DartNativeUtilitiesInternal::forwardingPrint, 1, "Utils_forwardingPrint" },
    { DartNativeUtilitiesInternal::getNewIsolateId, 0, "Utils_getNewIsolateId" },
    { DartNativeUtilitiesInternal::registerElement, 4, "Utils_register" },
    { DartNativeUtilitiesInternal::createElement, 2, "Utils_createElement" },
    { DartNativeUtilitiesInternal::initializeCustomElement, 1, "Utils_initializeCustomElement" },
    { DartNativeUtilitiesInternal::changeElementWrapper, 2, "Utils_changeElementWrapper" },
    { DartNativeUtilitiesInternal::spawnDomUri, 1, "Utils_spawnDomUri" },
    { DartWindowInternal::historyCrossFrameGetter, 1, "Window_history_cross_frame_Getter" },
    { DartWindowInternal::locationCrossFrameGetter, 1, "Window_location_cross_frame_Getter" },
    { 0, 0, 0 },
};

Dart_NativeFunction domIsolateHtmlResolver(Dart_Handle name, int argumentCount, bool* autoSetupScope)
{
    // Some utility functions.
    if (Dart_NativeFunction func = blinkSnapshotResolver(name, argumentCount, autoSetupScope))
        return func;
    if (Dart_NativeFunction func = customDartDOMStringMapResolver(name, argumentCount, autoSetupScope))
        return func;
    if (Dart_NativeFunction func = JsInterop::resolver(name, argumentCount, autoSetupScope))
        return func;

    String str = DartUtilities::toString(name);
    ASSERT(autoSetupScope);
    *autoSetupScope = true;
    for (intptr_t i = 0; nativeEntries[i].nativeFunction != 0; i++) {
        if (argumentCount == nativeEntries[i].argumentCount && str == nativeEntries[i].name) {
            return nativeEntries[i].nativeFunction;
        }
    }
    return 0;
}

extern const uint8_t* blinkSnapshotSymbolizer(Dart_NativeFunction);
extern const uint8_t* customDartDOMStringMapSymbolizer(Dart_NativeFunction);

const uint8_t* domIsolateHtmlSymbolizer(Dart_NativeFunction nf)
{
    const uint8_t* r = 0;
    r = blinkSnapshotSymbolizer(nf);
    if (r) {
        return r;
    }
    r = customDartDOMStringMapSymbolizer(nf);
    if (r) {
        return r;
    }
    r = JsInterop::symbolizer(nf);
    if (r) {
        return r;
    }

    for (intptr_t i = 0; nativeEntries[i].nativeFunction != 0; i++) {
        if (nf == nativeEntries[i].nativeFunction) {
            return reinterpret_cast<const uint8_t*>(nativeEntries[i].name);
        }
    }

    return 0;
}


}
