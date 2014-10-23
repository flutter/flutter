/*
 * Copyright (C) 2009 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "bindings/core/v8/V8Initializer.h"

#include "bindings/core/v8/DOMWrapperWorld.h"
#include "bindings/core/v8/ScriptCallStackFactory.h"
#include "bindings/core/v8/ScriptController.h"
#include "bindings/core/v8/ScriptProfiler.h"
#include "bindings/core/v8/V8Binding.h"
#include "bindings/core/v8/V8DOMException.h"
#include "bindings/core/v8/V8ErrorEvent.h"
#include "bindings/core/v8/V8ErrorHandler.h"
#include "bindings/core/v8/V8GCController.h"
#include "bindings/core/v8/V8History.h"
#include "bindings/core/v8/V8Location.h"
#include "bindings/core/v8/V8PerContextData.h"
#include "bindings/core/v8/V8Window.h"
#include "core/dom/Document.h"
#include "core/dom/ExceptionCode.h"
#include "core/frame/ConsoleTypes.h"
#include "core/frame/LocalDOMWindow.h"
#include "core/frame/LocalFrame.h"
#include "core/inspector/ScriptCallStack.h"
#include "platform/EventDispatchForbiddenScope.h"
#include "platform/TraceEvent.h"
#include "public/platform/Platform.h"
#include "wtf/RefPtr.h"
#include "wtf/text/WTFString.h"
#include <v8-debug.h>

namespace blink {

static LocalFrame* findFrame(v8::Local<v8::Object> host, v8::Local<v8::Value> data, v8::Isolate* isolate)
{
    const WrapperTypeInfo* type = WrapperTypeInfo::unwrap(data);

    if (V8Window::wrapperTypeInfo.equals(type)) {
        v8::Handle<v8::Object> windowWrapper = V8Window::findInstanceInPrototypeChain(host, isolate);
        if (windowWrapper.IsEmpty())
            return 0;
        return V8Window::toNative(windowWrapper)->frame();
    }

    if (V8History::wrapperTypeInfo.equals(type))
        return V8History::toNative(host)->frame();

    if (V8Location::wrapperTypeInfo.equals(type))
        return V8Location::toNative(host)->frame();

    // This function can handle only those types listed above.
    ASSERT_NOT_REACHED();
    return 0;
}

static void reportFatalErrorInMainThread(const char* location, const char* message)
{
    int memoryUsageMB = blink::Platform::current()->actualMemoryUsageMB();
    printf("V8 error: %s (%s).  Current memory usage: %d MB\n", message, location, memoryUsageMB);
    CRASH();
}

static void messageHandlerInMainThread(v8::Handle<v8::Message> message, v8::Handle<v8::Value> data)
{
    ASSERT(isMainThread());
    // It's possible that messageHandlerInMainThread() is invoked while we're initializing a window.
    // In that half-baked situation, we don't have a valid context nor a valid world,
    // so just return immediately.
    if (DOMWrapperWorld::windowIsBeingInitialized())
        return;

    v8::Isolate* isolate = v8::Isolate::GetCurrent();
    // If called during context initialization, there will be no entered window.
    LocalDOMWindow* enteredWindow = enteredDOMWindow(isolate);
    if (!enteredWindow)
        return;

    String errorMessage = toCoreString(message->Get());

    v8::Handle<v8::StackTrace> stackTrace = message->GetStackTrace();
    RefPtrWillBeRawPtr<ScriptCallStack> callStack = nullptr;
    int scriptId = message->GetScriptOrigin().ScriptID()->Value();
    // Currently stack trace is only collected when inspector is open.
    if (!stackTrace.IsEmpty() && stackTrace->GetFrameCount() > 0) {
        callStack = createScriptCallStack(stackTrace, ScriptCallStack::maxCallStackSizeToCapture, isolate);
        bool success = false;
        int topScriptId = callStack->at(0).scriptId().toInt(&success);
        if (success && topScriptId == scriptId)
            scriptId = 0;
    } else {
        Vector<ScriptCallFrame> callFrames;
        callStack = ScriptCallStack::create(callFrames);
    }

    v8::Handle<v8::Value> resourceName = message->GetScriptOrigin().ResourceName();
    bool shouldUseDocumentURL = resourceName.IsEmpty() || !resourceName->IsString();
    String resource = shouldUseDocumentURL ? enteredWindow->document()->url() : toCoreString(resourceName.As<v8::String>());

    ScriptState* scriptState = ScriptState::current(isolate);
    RefPtrWillBeRawPtr<ErrorEvent> event = ErrorEvent::create(errorMessage, resource, message->GetLineNumber(), message->GetStartColumn() + 1, &scriptState->world());
    if (V8DOMWrapper::isDOMWrapper(data)) {
        v8::Handle<v8::Object> obj = v8::Handle<v8::Object>::Cast(data);
        const WrapperTypeInfo* type = toWrapperTypeInfo(obj);
        if (V8DOMException::wrapperTypeInfo.isSubclass(type)) {
            DOMException* exception = V8DOMException::toNative(obj);
            if (exception && !exception->messageForConsole().isEmpty())
                event->setUnsanitizedMessage("Uncaught " + exception->toStringForConsole());
        }
    }

    // This method might be called while we're creating a new context. In this case, we
    // avoid storing the exception object, as we can't create a wrapper during context creation.
    // FIXME: Can we even get here during initialization now that we bail out when GetEntered returns an empty handle?
    LocalFrame* frame = enteredWindow->document()->frame();
    if (frame && frame->script().existingWindowProxy(scriptState->world())) {
        V8ErrorHandler::storeExceptionOnErrorEventWrapper(event.get(), data, scriptState->context()->Global(), isolate);
    }

    enteredWindow->document()->reportException(event.release(), scriptId, callStack);
}

static void failedAccessCheckCallbackInMainThread(v8::Local<v8::Object> host, v8::AccessType type, v8::Local<v8::Value> data)
{
    v8::Isolate* isolate = v8::Isolate::GetCurrent();
    LocalFrame* target = findFrame(host, data, isolate);
    if (!target)
        return;

    // FIXME: We should modify V8 to pass in more contextual information (context, property, and object).
    ExceptionState exceptionState(ExceptionState::UnknownContext, 0, 0, isolate->GetCurrentContext()->Global(), isolate);
    exceptionState.throwSecurityError("failedAccessCheckCallbackInMainThread", "failedAccessCheckCallbackInMainThread");
    exceptionState.throwIfNeeded();
}

static void timerTraceProfilerInMainThread(const char* name, int status)
{
    if (!status) {
        TRACE_EVENT_BEGIN0("v8", name);
    } else {
        TRACE_EVENT_END0("v8", name);
    }
}

static void initializeV8Common(v8::Isolate* isolate)
{
    v8::V8::AddGCPrologueCallback(V8GCController::gcPrologue);
    v8::V8::AddGCEpilogueCallback(V8GCController::gcEpilogue);

    v8::Debug::SetLiveEditEnabled(isolate, false);

    isolate->SetAutorunMicrotasks(false);
}

void V8Initializer::initializeMainThreadIfNeeded()
{
    ASSERT(isMainThread());

    static bool initialized = false;
    if (initialized)
        return;
    initialized = true;

    gin::IsolateHolder::Initialize(gin::IsolateHolder::kStrictMode, v8ArrayBufferAllocator());

    v8::Isolate* isolate = V8PerIsolateData::initialize();

    initializeV8Common(isolate);

    v8::V8::SetFatalErrorHandler(reportFatalErrorInMainThread);
    v8::V8::AddMessageListener(messageHandlerInMainThread);
    v8::V8::SetFailedAccessCheckCallbackFunction(failedAccessCheckCallbackInMainThread);

    isolate->SetEventLogger(timerTraceProfilerInMainThread);

    ScriptProfiler::initialize();
}

} // namespace blink
