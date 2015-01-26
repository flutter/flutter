/*
 * Copyright (C) 2008, 2009 Google Inc. All rights reserved.
 * Copyright (C) 2009 Apple Inc. All rights reserved.
 * Copyright (C) 2014 Opera Software ASA. All rights reserved.
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
#include "sky/engine/bindings/core/v8/ScriptController.h"

#include "bindings/core/v8/V8Event.h"
#include "bindings/core/v8/V8HTMLElement.h"
#include "bindings/core/v8/V8Window.h"
#include "sky/engine/bindings/core/v8/BindingSecurity.h"
#include "sky/engine/bindings/core/v8/ScriptCallStackFactory.h"
#include "sky/engine/bindings/core/v8/ScriptSourceCode.h"
#include "sky/engine/bindings/core/v8/ScriptValue.h"
#include "sky/engine/bindings/core/v8/V8Binding.h"
#include "sky/engine/bindings/core/v8/V8GCController.h"
#include "sky/engine/bindings/core/v8/V8PerContextData.h"
#include "sky/engine/bindings/core/v8/V8ScriptRunner.h"
#include "sky/engine/bindings/core/v8/WindowProxy.h"
#include "sky/engine/core/app/Module.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/Node.h"
#include "sky/engine/core/events/Event.h"
#include "sky/engine/core/events/EventListener.h"
#include "sky/engine/core/frame/LocalDOMWindow.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/frame/Settings.h"
#include "sky/engine/core/html/imports/HTMLImportChild.h"
#include "sky/engine/core/html/imports/HTMLImportLoader.h"
#include "sky/engine/core/html/parser/HTMLDocumentParser.h"
#include "sky/engine/core/inspector/InspectorTraceEvents.h"
#include "sky/engine/core/loader/FrameLoaderClient.h"
#include "sky/engine/platform/NotImplemented.h"
#include "sky/engine/platform/TraceEvent.h"
#include "sky/engine/platform/Widget.h"
#include "sky/engine/public/platform/Platform.h"
#include "sky/engine/core/inspector/ScriptCallStack.h"
#include "sky/engine/wtf/CurrentTime.h"
#include "sky/engine/wtf/StdLibExtras.h"
#include "sky/engine/wtf/StringExtras.h"
#include "sky/engine/wtf/text/CString.h"
#include "sky/engine/wtf/text/StringBuilder.h"
#include "sky/engine/wtf/text/TextPosition.h"

namespace blink {

bool ScriptController::canAccessFromCurrentOrigin(LocalFrame *frame)
{
    if (!frame)
        return false;
    v8::Isolate* isolate = toIsolate(frame);
    return !isolate->InContext() || BindingSecurity::shouldAllowAccessToFrame(isolate, frame);
}

ScriptController::ScriptController(LocalFrame* frame)
    : m_frame(frame)
    , m_sourceURL(0)
    , m_isolate(v8::Isolate::GetCurrent())
    , m_windowProxy(WindowProxy::create(frame, DOMWrapperWorld::mainWorld(), m_isolate))
{
}

ScriptController::~ScriptController()
{
    // WindowProxy::clearForClose() must be invoked before destruction starts.
    ASSERT(!m_windowProxy->isContextInitialized());
}

void ScriptController::clearForClose()
{
    double start = currentTime();
    m_windowProxy->clearForClose();
    for (IsolatedWorldMap::iterator iter = m_isolatedWorlds.begin(); iter != m_isolatedWorlds.end(); ++iter)
        iter->value->clearForClose();
    blink::Platform::current()->histogramCustomCounts("WebCore.ScriptController.clearForClose", (currentTime() - start) * 1000, 0, 10000, 50);
}

v8::Local<v8::Value> ScriptController::callFunction(v8::Handle<v8::Function> function, v8::Handle<v8::Value> receiver, int argc, v8::Handle<v8::Value> info[])
{
    // Keep LocalFrame (and therefore ScriptController) alive.
    RefPtr<LocalFrame> protect(m_frame);
    return ScriptController::callFunction(m_frame->document(), function, receiver, argc, info, m_isolate);
}

v8::Local<v8::Value> ScriptController::callFunction(ExecutionContext* context, v8::Handle<v8::Function> function, v8::Handle<v8::Value> receiver, int argc, v8::Handle<v8::Value> info[], v8::Isolate* isolate)
{
    TRACE_EVENT1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline"), "FunctionCall", "data", devToolsTraceEventData(context, function, isolate));
    TRACE_EVENT_INSTANT1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline.stack"), "CallStack", TRACE_EVENT_SCOPE_PROCESS, "stack", InspectorCallStackEvent::currentCallStack());

    return V8ScriptRunner::callFunction(function, context, receiver, argc, info, isolate);
}

v8::Local<v8::Value> ScriptController::executeScriptAndReturnValue(v8::Handle<v8::Context> context, const ScriptSourceCode& source)
{
    TRACE_EVENT1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline"), "EvaluateScript", "data", InspectorEvaluateScriptEvent::data(source.url().string(), source.startLine()));
    TRACE_EVENT_INSTANT1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline.stack"), "CallStack", TRACE_EVENT_SCOPE_PROCESS, "stack", InspectorCallStackEvent::currentCallStack());

    v8::Local<v8::Value> result;
    {
        V8CacheOptions v8CacheOptions(V8CacheOptionsOff);
        if (m_frame->settings())
            v8CacheOptions = m_frame->settings()->v8CacheOptions();

        // Isolate exceptions that occur when compiling and executing
        // the code. These exceptions should not interfere with
        // javascript code we might evaluate from C++ when returning
        // from here.
        v8::TryCatch tryCatch;
        tryCatch.SetVerbose(true);

        v8::Handle<v8::Script> script = V8ScriptRunner::compileScript(source, m_isolate, v8CacheOptions);

        // Keep LocalFrame (and therefore ScriptController) alive.
        RefPtr<LocalFrame> protect(m_frame);
        result = V8ScriptRunner::runCompiledScript(script, m_frame->document(), m_isolate);
        ASSERT(!tryCatch.HasCaught() || result.IsEmpty());
    }

    TRACE_EVENT_INSTANT1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline"), "UpdateCounters", TRACE_EVENT_SCOPE_PROCESS, "data", InspectorUpdateCountersEvent::data());

    return result;
}

bool ScriptController::initializeMainWorld()
{
    if (m_windowProxy->isContextInitialized())
        return false;
    return windowProxy(DOMWrapperWorld::mainWorld())->isContextInitialized();
}

WindowProxy* ScriptController::existingWindowProxy(DOMWrapperWorld& world)
{
    if (world.isMainWorld())
        return m_windowProxy->isContextInitialized() ? m_windowProxy.get() : 0;
    return 0;
}

WindowProxy* ScriptController::windowProxy(DOMWrapperWorld& world)
{
    m_windowProxy->initializeIfNeeded();
    return m_windowProxy.get();
}

V8Extensions& ScriptController::registeredExtensions()
{
    DEFINE_STATIC_LOCAL(V8Extensions, extensions, ());
    return extensions;
}

void ScriptController::registerExtensionIfNeeded(v8::Extension* extension)
{
    const V8Extensions& extensions = registeredExtensions();
    for (size_t i = 0; i < extensions.size(); ++i) {
        if (extensions[i] == extension)
            return;
    }
    v8::RegisterExtension(extension);
    registeredExtensions().append(extension);
}

void ScriptController::clearWindowProxy()
{
    double start = currentTime();
    // V8 binding expects ScriptController::clearWindowProxy only be called
    // when a frame is loading a new page. This creates a new context for the new page.

    m_windowProxy->clearForNavigation();
    for (IsolatedWorldMap::iterator iter = m_isolatedWorlds.begin(); iter != m_isolatedWorlds.end(); ++iter)
        iter->value->clearForNavigation();
    blink::Platform::current()->histogramCustomCounts("WebCore.ScriptController.clearWindowProxy", (currentTime() - start) * 1000, 0, 10000, 50);
}

void ScriptController::setCaptureCallStackForUncaughtExceptions(bool value)
{
    v8::V8::SetCaptureStackTraceForUncaughtExceptions(value, ScriptCallStack::maxCallStackSizeToCapture, stackTraceOptions);
}

void ScriptController::setWorldDebugId(int debuggerId)
{
    ASSERT(debuggerId > 0);
    if (!m_windowProxy || !m_windowProxy->isContextInitialized())
        return;
    v8::HandleScope scope(m_isolate);
    v8::Local<v8::Context> context = m_windowProxy->context();
    V8PerContextDebugData::setContextDebugData(context, "page", debuggerId);
}

void ScriptController::updateDocument()
{
    // For an uninitialized main window windowProxy, do not incur the cost of context initialization.
    if (!m_windowProxy->isGlobalInitialized())
        return;

    if (!initializeMainWorld())
        windowProxy(DOMWrapperWorld::mainWorld())->updateDocument();
}

void ScriptController::executeScriptInMainWorld(const String& script)
{
    v8::HandleScope handleScope(m_isolate);
    evaluateScriptInMainWorld(ScriptSourceCode(script));
}

void ScriptController::executeScriptInMainWorld(const ScriptSourceCode& sourceCode)
{
    v8::HandleScope handleScope(m_isolate);
    evaluateScriptInMainWorld(sourceCode);
}

v8::Local<v8::Value> ScriptController::executeScriptInMainWorldAndReturnValue(const ScriptSourceCode& sourceCode)
{
    return evaluateScriptInMainWorld(sourceCode);
}

v8::Local<v8::Value> ScriptController::evaluateScriptInMainWorld(const ScriptSourceCode& sourceCode)
{
    String sourceURL = sourceCode.url();
    const String* savedSourceURL = m_sourceURL;
    m_sourceURL = &sourceURL;

    v8::EscapableHandleScope handleScope(m_isolate);
    v8::Handle<v8::Context> context = toV8Context(m_frame, DOMWrapperWorld::mainWorld());
    if (context.IsEmpty())
        return v8::Local<v8::Value>();

    ScriptState* scriptState = ScriptState::from(context);
    ScriptState::Scope scope(scriptState);

    RefPtr<LocalFrame> protect(m_frame);

    v8::Local<v8::Value> object = executeScriptAndReturnValue(scriptState->context(), sourceCode);
    m_sourceURL = savedSourceURL;

    if (object.IsEmpty())
        return v8::Local<v8::Value>();

    return handleScope.Escape(object);
}

void ScriptController::executeModuleScript(AbstractModule& module, const String& source, const TextPosition& textPosition)
{
    v8::HandleScope handleScope(m_isolate);
    v8::Handle<v8::Context> context = toV8Context(m_frame, DOMWrapperWorld::mainWorld());
    if (context.IsEmpty())
        return;

    ScriptState* scriptState = ScriptState::from(context);
    ScriptState::Scope scope(scriptState);

    RefPtr<LocalFrame> protect(m_frame);

    v8::TryCatch tryCatch;
    tryCatch.SetVerbose(true);

    V8ScriptModule scriptModule;
    scriptModule.resourceName = module.url();
    scriptModule.textPosition = textPosition;
    scriptModule.moduleObject = toV8(&module, context->Global(), m_isolate);
    scriptModule.source = source;

    if (HTMLImport* parent = module.document()->import()) {
        for (HTMLImportChild* child = static_cast<HTMLImportChild*>(parent->firstChild());
             child; child = static_cast<HTMLImportChild*>(child->next())) {
            if (Element* link = child->link()) {
                String name = link->getAttribute(HTMLNames::asAttr);
                if (!name.isEmpty()) {
                    scriptModule.formalDependencies.append(name);
                    v8::Handle<v8::Value> actual;
                    if (Module* childModule = child->module())
                        actual = childModule->exports(scriptState).v8Value();
                    if (actual.IsEmpty())
                        actual = v8::Undefined(m_isolate);
                    scriptModule.resolvedDependencies.append(actual);
                }
            }
        }
    }

    V8ScriptRunner::runModule(m_isolate, m_frame->document(), scriptModule);
}

} // namespace blink
