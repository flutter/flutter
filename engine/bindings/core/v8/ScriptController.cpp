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

#include "config.h"
#include "bindings/core/v8/ScriptController.h"

#include "bindings/core/v8/BindingSecurity.h"
#include "bindings/core/v8/ScriptCallStackFactory.h"
#include "bindings/core/v8/ScriptSourceCode.h"
#include "bindings/core/v8/ScriptValue.h"
#include "bindings/core/v8/V8Binding.h"
#include "bindings/core/v8/V8Event.h"
#include "bindings/core/v8/V8GCController.h"
#include "bindings/core/v8/V8HTMLElement.h"
#include "bindings/core/v8/V8PerContextData.h"
#include "bindings/core/v8/V8ScriptRunner.h"
#include "bindings/core/v8/V8Window.h"
#include "bindings/core/v8/WindowProxy.h"
#include "core/dom/Document.h"
#include "core/dom/Node.h"
#include "core/events/Event.h"
#include "core/events/EventListener.h"
#include "core/frame/LocalDOMWindow.h"
#include "core/frame/LocalFrame.h"
#include "core/frame/Settings.h"
#include "core/frame/UseCounter.h"
#include "core/html/HTMLLinkElement.h"
#include "core/html/imports/HTMLImportChild.h"
#include "core/html/imports/HTMLImportLoader.h"
#include "core/html/parser/HTMLDocumentParser.h"
#include "core/inspector/InspectorTraceEvents.h"
#include "core/inspector/ScriptCallStack.h"
#include "core/loader/FrameLoaderClient.h"
#include "platform/NotImplemented.h"
#include "platform/TraceEvent.h"
#include "platform/UserGestureIndicator.h"
#include "platform/Widget.h"
#include "public/platform/Platform.h"
#include "wtf/CurrentTime.h"
#include "wtf/StdLibExtras.h"
#include "wtf/StringExtras.h"
#include "wtf/text/CString.h"
#include "wtf/text/StringBuilder.h"
#include "wtf/text/TextPosition.h"

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
    TRACE_EVENT_INSTANT1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline.stack"), "CallStack", "stack", InspectorCallStackEvent::currentCallStack());

    return V8ScriptRunner::callFunction(function, context, receiver, argc, info, isolate);
}

v8::Local<v8::Value> ScriptController::executeScriptAndReturnValue(v8::Handle<v8::Context> context, const ScriptSourceCode& source)
{
    TRACE_EVENT1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline"), "EvaluateScript", "data", InspectorEvaluateScriptEvent::data(m_frame, source.url().string(), source.startLine()));
    TRACE_EVENT_INSTANT1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline.stack"), "CallStack", "stack", InspectorCallStackEvent::currentCallStack());

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

    TRACE_EVENT_INSTANT1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline"), "UpdateCounters", "data", InspectorUpdateCountersEvent::data());

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

    IsolatedWorldMap::iterator iter = m_isolatedWorlds.find(world.worldId());
    if (iter == m_isolatedWorlds.end())
        return 0;
    return iter->value->isContextInitialized() ? iter->value.get() : 0;
}

WindowProxy* ScriptController::windowProxy(DOMWrapperWorld& world)
{
    WindowProxy* windowProxy = 0;
    if (world.isMainWorld()) {
        windowProxy = m_windowProxy.get();
    } else {
        IsolatedWorldMap::iterator iter = m_isolatedWorlds.find(world.worldId());
        if (iter != m_isolatedWorlds.end()) {
            windowProxy = iter->value.get();
        } else {
            OwnPtr<WindowProxy> isolatedWorldWindowProxy = WindowProxy::create(m_frame, world, m_isolate);
            windowProxy = isolatedWorldWindowProxy.get();
            m_isolatedWorlds.set(world.worldId(), isolatedWorldWindowProxy.release());
        }
    }
    windowProxy->initializeIfNeeded();
    return windowProxy;
}

TextPosition ScriptController::eventHandlerPosition() const
{
    HTMLDocumentParser* parser = m_frame->document()->scriptableDocumentParser();
    if (parser)
        return parser->textPosition();
    return TextPosition::minimumPosition();
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

void ScriptController::setWorldDebugId(int worldId, int debuggerId)
{
    ASSERT(debuggerId > 0);
    bool isMainWorld = worldId == MainWorldId;
    WindowProxy* windowProxy = 0;
    if (isMainWorld) {
        windowProxy = m_windowProxy.get();
    } else {
        IsolatedWorldMap::iterator iter = m_isolatedWorlds.find(worldId);
        if (iter != m_isolatedWorlds.end())
            windowProxy = iter->value.get();
    }
    if (!windowProxy || !windowProxy->isContextInitialized())
        return;
    v8::HandleScope scope(m_isolate);
    v8::Local<v8::Context> context = windowProxy->context();
    const char* worldName = isMainWorld ? "page" : "injected";
    V8PerContextDebugData::setContextDebugData(context, worldName, debuggerId);
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

void ScriptController::executeScriptInIsolatedWorld(int worldID, const Vector<ScriptSourceCode>& sources, int extensionGroup, Vector<v8::Local<v8::Value> >* results)
{
    ASSERT(worldID > 0);

    RefPtr<DOMWrapperWorld> world = DOMWrapperWorld::ensureIsolatedWorld(worldID, extensionGroup);
    WindowProxy* isolatedWorldWindowProxy = windowProxy(*world);
    if (!isolatedWorldWindowProxy->isContextInitialized())
        return;

    ScriptState* scriptState = isolatedWorldWindowProxy->scriptState();
    v8::EscapableHandleScope handleScope(scriptState->isolate());
    ScriptState::Scope scope(scriptState);
    v8::Local<v8::Array> resultArray = v8::Array::New(m_isolate, sources.size());

    for (size_t i = 0; i < sources.size(); ++i) {
        v8::Local<v8::Value> evaluationResult = executeScriptAndReturnValue(scriptState->context(), sources[i]);
        if (evaluationResult.IsEmpty())
            evaluationResult = v8::Local<v8::Value>::New(m_isolate, v8::Undefined(m_isolate));
        resultArray->Set(i, evaluationResult);
    }

    if (results) {
        for (size_t i = 0; i < resultArray->Length(); ++i)
            results->append(handleScope.Escape(resultArray->Get(i)));
    }
}

void ScriptController::executeModuleScript(Document& document, const String& source)
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

    V8ScriptModule module;
    module.receiver = toV8(&document, context->Global(), m_isolate);

    if (HTMLImport* parent = document.import()) {
        for (HTMLImport* child = parent->firstChild(); child; child = child->next()) {
            if (HTMLLinkElement* link = static_cast<HTMLImportChild*>(child)->link()) {
                String name = link->as();
                if (!name.isEmpty()) {
                    module.formalDependenciesAndSource.append(v8String(m_isolate, name));
                    module.resolvedDependencies.append(child->document() ? child->document()->exports().v8Value() : v8Undefined());
                }
            }
        }
    }

    module.formalDependenciesAndSource.append(v8String(m_isolate, source));
    V8ScriptRunner::runModule(m_isolate, m_frame->document(), module);
}

} // namespace blink
