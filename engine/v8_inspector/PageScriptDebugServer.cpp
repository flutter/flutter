/*
 * Copyright (c) 2011 Google Inc. All rights reserved.
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
#include "sky/engine/v8_inspector/PageScriptDebugServer.h"

#include "gen/sky/bindings/core/v8/V8Window.h"
#include "sky/engine/bindings/core/v8/DOMWrapperWorld.h"
#include "sky/engine/bindings/core/v8/ScriptController.h"
#include "sky/engine/bindings/core/v8/ScriptSourceCode.h"
#include "sky/engine/bindings/core/v8/V8Binding.h"
#include "sky/engine/bindings/core/v8/V8ScriptRunner.h"
#include "sky/engine/bindings/core/v8/WindowProxy.h"
#include "sky/engine/core/dom/ExecutionContext.h"
#include "sky/engine/core/frame/FrameConsole.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/frame/UseCounter.h"
#include "sky/engine/core/inspector/InspectorTraceEvents.h"
#include "sky/engine/core/inspector/ScriptDebugListener.h"
#include "sky/engine/core/page/Page.h"
#include "sky/engine/v8_inspector/inspector_host.h"
#include "sky/engine/wtf/OwnPtr.h"
#include "sky/engine/wtf/PassOwnPtr.h"
#include "sky/engine/wtf/StdLibExtras.h"
#include "sky/engine/wtf/TemporaryChange.h"
#include "sky/engine/wtf/text/StringBuilder.h"

namespace blink {

static LocalFrame* retrieveFrameWithGlobalObjectCheck(v8::Handle<v8::Context> context)
{
    if (context.IsEmpty())
        return 0;

    // FIXME: This is a temporary hack for crbug.com/345014.
    // Currently it's possible that V8 can trigger Debugger::ProcessDebugEvent for a context
    // that is being initialized (i.e., inside Context::New() of the context).
    // We should fix the V8 side so that it won't trigger the event for a half-baked context
    // because there is no way in the embedder side to check if the context is half-baked or not.
    if (isMainThread() && DOMWrapperWorld::windowIsBeingInitialized())
        return 0;

    v8::Handle<v8::Value> global = V8Window::findInstanceInPrototypeChain(context->Global(), context->GetIsolate());
    if (global.IsEmpty())
        return 0;

    return toFrameIfNotDetached(context);
}

void PageScriptDebugServer::setPreprocessorSource(const String& preprocessorSource)
{
    if (preprocessorSource.isEmpty())
        m_preprocessorSourceCode.clear();
    else
        m_preprocessorSourceCode = adoptPtr(new ScriptSourceCode(preprocessorSource));
    m_scriptPreprocessor.clear();
}

PageScriptDebugServer& PageScriptDebugServer::shared()
{
    DEFINE_STATIC_LOCAL(PageScriptDebugServer, server, ());
    return server;
}

v8::Isolate* PageScriptDebugServer::s_mainThreadIsolate = 0;

void PageScriptDebugServer::setMainThreadIsolate(v8::Isolate* isolate)
{
    s_mainThreadIsolate = isolate;
}

PageScriptDebugServer::PageScriptDebugServer()
    : ScriptDebugServer(s_mainThreadIsolate)
    , m_pausedHost(0)
{
}

PageScriptDebugServer::~PageScriptDebugServer()
{
}

void PageScriptDebugServer::addListener(ScriptDebugListener* listener, inspector::InspectorHost* host)
{
    v8::HandleScope scope(m_isolate);

    if (!m_listenersMap.size()) {
        v8::Debug::SetDebugEventListener(&PageScriptDebugServer::v8DebugEventCallback, v8::External::New(m_isolate, this));
        ensureDebuggerScriptCompiled();
    }

    v8::Local<v8::Context> debuggerContext = v8::Debug::GetDebugContext();
    v8::Context::Scope contextScope(debuggerContext);

    v8::Local<v8::Object> debuggerScript = m_debuggerScript.newLocal(m_isolate);
    ASSERT(!debuggerScript->IsUndefined());
    m_listenersMap.set(host, listener);

    v8::Local<v8::Context> context = host->GetContext();
    v8::Handle<v8::Function> getScriptsFunction = v8::Local<v8::Function>::Cast(debuggerScript->Get(v8AtomicString(m_isolate, "getScripts")));
    v8::Handle<v8::Value> argv[] = { context->GetEmbedderData(0) };
    v8::Handle<v8::Value> value = V8ScriptRunner::callInternalFunction(getScriptsFunction, debuggerScript, WTF_ARRAY_LENGTH(argv), argv, m_isolate);
    if (value.IsEmpty())
        return;
    ASSERT(!value->IsUndefined() && value->IsArray());
    v8::Handle<v8::Array> scriptsArray = v8::Handle<v8::Array>::Cast(value);
    for (unsigned i = 0; i < scriptsArray->Length(); ++i)
        dispatchDidParseSource(listener, v8::Handle<v8::Object>::Cast(scriptsArray->Get(v8::Integer::New(m_isolate, i))), CompileSuccess);
}

void PageScriptDebugServer::removeListener(ScriptDebugListener* listener, inspector::InspectorHost* host)
{
    if (!m_listenersMap.contains(host))
        return;

    if (m_pausedHost == host)
        continueProgram();

    m_listenersMap.remove(host);

    if (m_listenersMap.isEmpty()) {
        discardDebuggerScript();
        v8::Debug::SetDebugEventListener(0);
        // FIXME: Remove all breakpoints set by the agent.
    }
}

void PageScriptDebugServer::interruptAndRun(PassOwnPtr<Task> task)
{
    ScriptDebugServer::interruptAndRun(task, s_mainThreadIsolate);
}

void PageScriptDebugServer::setClientMessageLoop(PassOwnPtr<ClientMessageLoop> clientMessageLoop)
{
    m_clientMessageLoop = clientMessageLoop;
}

void PageScriptDebugServer::setInspectorHostResolver(PassOwnPtr<InspectorHostResolver> resolver)
{
    m_inspectorHostResolver = resolver;
}

void PageScriptDebugServer::compileScript(ScriptState* scriptState, const String& expression, const String& sourceURL, String* scriptId, String* exceptionDetailsText, int* lineNumber, int* columnNumber, RefPtr<ScriptCallStack>* stackTrace)
{
    ExecutionContext* executionContext = scriptState->executionContext();
    RefPtr<LocalFrame> protect = executionContext->executingWindow()->frame();
    ScriptDebugServer::compileScript(scriptState, expression, sourceURL, scriptId, exceptionDetailsText, lineNumber, columnNumber, stackTrace);
    if (!scriptId->isNull())
        m_compiledScriptURLs.set(*scriptId, sourceURL);
}

void PageScriptDebugServer::clearCompiledScripts()
{
    ScriptDebugServer::clearCompiledScripts();
    m_compiledScriptURLs.clear();
}

void PageScriptDebugServer::runScript(ScriptState* scriptState, const String& scriptId, ScriptValue* result, bool* wasThrown, String* exceptionDetailsText, int* lineNumber, int* columnNumber, RefPtr<ScriptCallStack>* stackTrace)
{
    String sourceURL = m_compiledScriptURLs.take(scriptId);

    ExecutionContext* executionContext = scriptState->executionContext();
    LocalFrame* frame = executionContext->executingWindow()->frame();
    TRACE_EVENT1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline"), "EvaluateScript", "data", InspectorEvaluateScriptEvent::data(frame, sourceURL, TextPosition::minimumPosition().m_line.oneBasedInt()));
    TRACE_EVENT_INSTANT1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline.stack"), "CallStack", TRACE_EVENT_SCOPE_PROCESS, "stack", InspectorCallStackEvent::currentCallStack());

    RefPtr<LocalFrame> protect = frame;
    ScriptDebugServer::runScript(scriptState, scriptId, result, wasThrown, exceptionDetailsText, lineNumber, columnNumber, stackTrace);

    TRACE_EVENT_INSTANT1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline"), "UpdateCounters", TRACE_EVENT_SCOPE_PROCESS, "data", InspectorUpdateCountersEvent::data());
}

ScriptDebugListener* PageScriptDebugServer::getDebugListenerForContext(v8::Handle<v8::Context> context)
{
    inspector::InspectorHost* inspectorHost = m_inspectorHostResolver->inspectorHostFor(context);
    if (!inspectorHost)
        return 0;
    return m_listenersMap.get(inspectorHost);
}

void PageScriptDebugServer::runMessageLoopOnPause(v8::Handle<v8::Context> context)
{
    m_pausedHost = m_inspectorHostResolver->inspectorHostFor(context);
    ASSERT(m_pausedHost);

    // Wait for continue or step command.
    m_clientMessageLoop->run(m_pausedHost);

    // The listener may have been removed in the nested loop.
    if (ScriptDebugListener* listener = m_listenersMap.get(m_pausedHost))
        listener->didContinue();

    m_pausedHost = 0;
}

void PageScriptDebugServer::quitMessageLoopOnPause()
{
    m_clientMessageLoop->quitNow();
}

void PageScriptDebugServer::preprocessBeforeCompile(const v8::Debug::EventDetails& eventDetails)
{
    v8::Handle<v8::Context> eventContext = eventDetails.GetEventContext();
    LocalFrame* frame = retrieveFrameWithGlobalObjectCheck(eventContext);
    if (!frame)
        return;

    if (!canPreprocess(frame))
        return;

    v8::Handle<v8::Object> eventData = eventDetails.GetEventData();
    v8::Local<v8::Context> debugContext = v8::Debug::GetDebugContext();
    v8::Context::Scope contextScope(debugContext);
    v8::TryCatch tryCatch;
    // <script> tag source and attribute value source are preprocessed before we enter V8.
    // Avoid preprocessing any internal scripts by processing only eval source in this V8 event handler.
    v8::Handle<v8::Value> argvEventData[] = { eventData };
    v8::Handle<v8::Value> v8Value = callDebuggerMethod("isEvalCompilation", WTF_ARRAY_LENGTH(argvEventData), argvEventData);
    if (v8Value.IsEmpty() || !v8Value->ToBoolean()->Value())
        return;

    // The name and source are in the JS event data.
    String scriptName = toCoreStringWithUndefinedOrNullCheck(callDebuggerMethod("getScriptName", WTF_ARRAY_LENGTH(argvEventData), argvEventData));
    String script = toCoreStringWithUndefinedOrNullCheck(callDebuggerMethod("getScriptSource", WTF_ARRAY_LENGTH(argvEventData), argvEventData));

    String preprocessedSource  = m_scriptPreprocessor->preprocessSourceCode(script, scriptName);

    v8::Handle<v8::Value> argvPreprocessedScript[] = { eventData, v8String(debugContext->GetIsolate(), preprocessedSource) };
    callDebuggerMethod("setScriptSource", WTF_ARRAY_LENGTH(argvPreprocessedScript), argvPreprocessedScript);
}

static bool isCreatingPreprocessor = false;

bool PageScriptDebugServer::canPreprocess(LocalFrame* frame)
{
    ASSERT(frame);

    if (!m_preprocessorSourceCode || !frame->page() || isCreatingPreprocessor)
        return false;

    // We delay the creation of the preprocessor until just before the first JS from the
    // Web page to ensure that the debugger's console initialization code has completed.
    if (!m_scriptPreprocessor) {
        TemporaryChange<bool> isPreprocessing(isCreatingPreprocessor, true);
        m_scriptPreprocessor = adoptPtr(new ScriptPreprocessor(*m_preprocessorSourceCode.get(), frame));
    }

    if (m_scriptPreprocessor->isValid())
        return true;

    m_scriptPreprocessor.clear();
    // Don't retry the compile if we fail one time.
    m_preprocessorSourceCode.clear();
    return false;
}

// Source to Source processing iff debugger enabled and it has loaded a preprocessor.
PassOwnPtr<ScriptSourceCode> PageScriptDebugServer::preprocess(LocalFrame* frame, const ScriptSourceCode& sourceCode)
{
    if (!canPreprocess(frame))
        return PassOwnPtr<ScriptSourceCode>();

    String preprocessedSource = m_scriptPreprocessor->preprocessSourceCode(sourceCode.source(), sourceCode.url());
    return adoptPtr(new ScriptSourceCode(preprocessedSource, sourceCode.url()));
}

String PageScriptDebugServer::preprocessEventListener(LocalFrame* frame, const String& source, const String& url, const String& functionName)
{
    if (!canPreprocess(frame))
        return source;

    return m_scriptPreprocessor->preprocessSourceCode(source, url, functionName);
}

void PageScriptDebugServer::clearPreprocessor()
{
    m_scriptPreprocessor.clear();
}

void PageScriptDebugServer::muteWarningsAndDeprecations()
{
    FrameConsole::mute();
    UseCounter::muteForInspector();
}

void PageScriptDebugServer::unmuteWarningsAndDeprecations()
{
    FrameConsole::unmute();
    UseCounter::unmuteForInspector();
}

} // namespace blink
