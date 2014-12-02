/*
 * Copyright (C) 2010 Apple Inc. All rights reserved.
 * Copyright (C) 2010-2011 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 * 3.  Neither the name of Apple Computer, Inc. ("Apple") nor the names of
 *     its contributors may be used to endorse or promote products derived
 *     from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef SKY_ENGINE_V8_INSPECTOR_INSPECTORDEBUGGERAGENT_H_
#define SKY_ENGINE_V8_INSPECTOR_INSPECTORDEBUGGERAGENT_H_

#include "gen/v8_inspector/InspectorFrontend.h"
#include "sky/engine/bindings/core/v8/ScriptState.h"
#include "sky/engine/core/frame/ConsoleTypes.h"
#include "sky/engine/core/inspector/ConsoleAPITypes.h"
#include "sky/engine/v8_inspector/AsyncCallStackTracker.h"
#include "sky/engine/v8_inspector/InjectedScript.h"
#include "sky/engine/v8_inspector/InspectorBaseAgent.h"
#include "sky/engine/v8_inspector/PromiseTracker.h"
#include "sky/engine/v8_inspector/ScriptBreakpoint.h"
#include "sky/engine/v8_inspector/ScriptDebugListener.h"
#include "sky/engine/wtf/Forward.h"
#include "sky/engine/wtf/HashMap.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/Vector.h"
#include "sky/engine/wtf/text/StringHash.h"

namespace blink {

class ConsoleMessage;
class Document;
class Event;
class EventListener;
class EventTarget;
class FormData;
class HTTPHeaderMap;
class InjectedScriptManager;
class InspectorFrontend;
class InstrumentingAgents;
class JavaScriptCallFrame;
class JSONObject;
class KURL;
class MutationObserver;
class ScriptArguments;
class ScriptAsyncCallStack;
class ScriptCallStack;
class ScriptDebugServer;
class ScriptRegexp;
class ScriptSourceCode;
class ScriptValue;
class ThreadableLoaderClient;
class XMLHttpRequest;

typedef String ErrorString;

class InspectorDebuggerAgent : public InspectorBaseAgent<InspectorDebuggerAgent>, public ScriptDebugListener, public InspectorBackendDispatcher::DebuggerCommandHandler {
    WTF_MAKE_NONCOPYABLE(InspectorDebuggerAgent);
    WTF_MAKE_FAST_ALLOCATED;
public:
    enum BreakpointSource {
        UserBreakpointSource,
        DebugCommandBreakpointSource,
        MonitorCommandBreakpointSource
    };

    static const char backtraceObjectGroup[];

    virtual ~InspectorDebuggerAgent();

    virtual void canSetScriptSource(ErrorString*, bool* result) override final { *result = true; }

    virtual void virtualInit() override final;
    virtual void setFrontend(InspectorFrontend*) override final;
    virtual void clearFrontend() override final;
    virtual void restore() override final;

    bool isPaused();
    bool runningNestedMessageLoop();
    void addMessageToConsole(ConsoleMessage*);

    String preprocessEventListener(LocalFrame*, const String& source, const String& url, const String& functionName);
    PassOwnPtr<ScriptSourceCode> preprocess(LocalFrame*, const ScriptSourceCode&);

    // Part of the protocol.
    virtual void enable(ErrorString*) override final;
    virtual void disable(ErrorString*) override final;
    virtual void setBreakpointsActive(ErrorString*, bool active) override final;
    virtual void setSkipAllPauses(ErrorString*, bool skipped, const bool* untilReload) override final;

    virtual void setBreakpointByUrl(ErrorString*, int lineNumber, const String* optionalURL, const String* optionalURLRegex, const int* optionalColumnNumber, const String* optionalCondition, const bool* isAntiBreakpoint, TypeBuilder::Debugger::BreakpointId*, RefPtr<TypeBuilder::Array<TypeBuilder::Debugger::Location> >& locations) override final;
    virtual void setBreakpoint(ErrorString*, const RefPtr<JSONObject>& location, const String* optionalCondition, TypeBuilder::Debugger::BreakpointId*, RefPtr<TypeBuilder::Debugger::Location>& actualLocation) override final;
    virtual void removeBreakpoint(ErrorString*, const String& breakpointId) override final;
    virtual void continueToLocation(ErrorString*, const RefPtr<JSONObject>& location, const bool* interstateLocationOpt) override final;
    virtual void getStepInPositions(ErrorString*, const String& callFrameId, RefPtr<TypeBuilder::Array<TypeBuilder::Debugger::Location> >& positions) override final;
    virtual void getBacktrace(ErrorString*, RefPtr<TypeBuilder::Array<TypeBuilder::Debugger::CallFrame> >&, RefPtr<TypeBuilder::Debugger::StackTrace>&) override final;

    virtual void searchInContent(ErrorString*, const String& scriptId, const String& query, const bool* optionalCaseSensitive, const bool* optionalIsRegex, RefPtr<TypeBuilder::Array<TypeBuilder::Page::SearchMatch> >&) override final;
    virtual void setScriptSource(ErrorString*, RefPtr<TypeBuilder::Debugger::SetScriptSourceError>&, const String& scriptId, const String& newContent, const bool* preview, RefPtr<TypeBuilder::Array<TypeBuilder::Debugger::CallFrame> >& newCallFrames, RefPtr<JSONObject>& result, RefPtr<TypeBuilder::Debugger::StackTrace>& asyncStackTrace) override final;
    virtual void restartFrame(ErrorString*, const String& callFrameId, RefPtr<TypeBuilder::Array<TypeBuilder::Debugger::CallFrame> >& newCallFrames, RefPtr<JSONObject>& result, RefPtr<TypeBuilder::Debugger::StackTrace>& asyncStackTrace) override final;
    virtual void getScriptSource(ErrorString*, const String& scriptId, String* scriptSource) override final;
    virtual void getFunctionDetails(ErrorString*, const String& functionId, RefPtr<TypeBuilder::Debugger::FunctionDetails>&) override final;
    virtual void getCollectionEntries(ErrorString*, const String& objectId, RefPtr<TypeBuilder::Array<TypeBuilder::Debugger::CollectionEntry> >&) override final;
    virtual void pause(ErrorString*) override final;
    virtual void resume(ErrorString*) override final;
    virtual void stepOver(ErrorString*) override final;
    virtual void stepInto(ErrorString*) override final;
    virtual void stepOut(ErrorString*) override final;
    virtual void setPauseOnExceptions(ErrorString*, const String& pauseState) override final;
    virtual void evaluateOnCallFrame(ErrorString*,
        const String& callFrameId,
        const String& expression,
        const String* objectGroup,
        const bool* includeCommandLineAPI,
        const bool* doNotPauseOnExceptionsAndMuteConsole,
        const bool* returnByValue,
        const bool* generatePreview,
        RefPtr<TypeBuilder::Runtime::RemoteObject>& result,
        TypeBuilder::OptOutput<bool>* wasThrown,
        RefPtr<TypeBuilder::Debugger::ExceptionDetails>&) override final;
    virtual void compileScript(ErrorString*, const String& expression, const String& sourceURL, const int* executionContextId, TypeBuilder::OptOutput<TypeBuilder::Debugger::ScriptId>*, RefPtr<TypeBuilder::Debugger::ExceptionDetails>&) override;
    virtual void runScript(ErrorString*, const TypeBuilder::Debugger::ScriptId&, const int* executionContextId, const String* objectGroup, const bool* doNotPauseOnExceptionsAndMuteConsole, RefPtr<TypeBuilder::Runtime::RemoteObject>& result, RefPtr<TypeBuilder::Debugger::ExceptionDetails>&) override;
    virtual void setOverlayMessage(ErrorString*, const String*) override;
    virtual void setVariableValue(ErrorString*, int in_scopeNumber, const String& in_variableName, const RefPtr<JSONObject>& in_newValue, const String* in_callFrame, const String* in_functionObjectId) override final;
    virtual void skipStackFrames(ErrorString*, const String* pattern) override final;
    virtual void setAsyncCallStackDepth(ErrorString*, int depth) override final;

    void schedulePauseOnNextStatement(InspectorFrontend::Debugger::Reason::Enum breakReason, PassRefPtr<JSONObject> data);
    void didInstallTimer(ExecutionContext*, int timerId, int timeout, bool singleShot);
    void didRemoveTimer(ExecutionContext*, int timerId);
    bool willFireTimer(ExecutionContext*, int timerId);
    void didFireTimer();
    void didRequestAnimationFrame(Document*, int callbackId);
    void didCancelAnimationFrame(Document*, int callbackId);
    bool willFireAnimationFrame(Document*, int callbackId);
    void didFireAnimationFrame();
    void didEnqueueEvent(EventTarget*, Event*);
    void didRemoveEvent(EventTarget*, Event*);
    void willHandleEvent(EventTarget*, Event*, EventListener*, bool useCapture);
    void didHandleEvent();
    void didEnqueueMutationRecord(ExecutionContext*, MutationObserver*);
    void didClearAllMutationRecords(ExecutionContext*, MutationObserver*);
    void willDeliverMutationRecords(ExecutionContext*, MutationObserver*);
    void didDeliverMutationRecords();
    // void didPostExecutionContextTask(ExecutionContext*, ExecutionContextTask*);
    // void didKillAllExecutionContextTasks(ExecutionContext*);
    // void willPerformExecutionContextTask(ExecutionContext*, ExecutionContextTask*);
    // void didPerformExecutionContextTask();
    int traceAsyncOperationStarting(ExecutionContext*, const String& operationName, int prevOperationId = 0);
    void traceAsyncOperationCompleted(ExecutionContext*, int operationId);
    void traceAsyncOperationCompletedCallbackStarting(ExecutionContext*, int operationId);
    void traceAsyncCallbackStarting(ExecutionContext*, int operationId);
    void traceAsyncCallbackCompleted();
    bool canBreakProgram();
    void breakProgram(InspectorFrontend::Debugger::Reason::Enum breakReason, PassRefPtr<JSONObject> data);
    void scriptExecutionBlockedByCSP(const String& directiveText);

    class Listener {
    public:
        virtual ~Listener() { }
        virtual void debuggerWasEnabled() = 0;
        virtual void debuggerWasDisabled() = 0;
        virtual void stepInto() = 0;
        virtual void didPause() = 0;
    };
    void setListener(Listener* listener) { m_listener = listener; }

    bool enabled();

    virtual ScriptDebugServer& scriptDebugServer() = 0;

    void setBreakpoint(const String& scriptId, int lineNumber, int columnNumber, BreakpointSource, const String& condition = String());
    void removeBreakpoint(const String& scriptId, int lineNumber, int columnNumber, BreakpointSource);

protected:
    explicit InspectorDebuggerAgent(InjectedScriptManager*);

    virtual void startListeningScriptDebugServer() = 0;
    virtual void stopListeningScriptDebugServer() = 0;
    virtual void muteConsole() = 0;
    virtual void unmuteConsole() = 0;
    InjectedScriptManager* injectedScriptManager() { return m_injectedScriptManager; }
    virtual InjectedScript injectedScriptForEval(ErrorString*, const int* executionContextId) = 0;

    virtual void enable();
    virtual void disable();
    virtual SkipPauseRequest didPause(ScriptState*, const ScriptValue& callFrames, const ScriptValue& exception, const Vector<String>& hitBreakpoints) override final;
    virtual void didContinue() override final;
    void reset();
    void pageDidCommitLoad();

private:
    bool shouldSkipInspectorInternals();
    SkipPauseRequest shouldSkipExceptionPause();
    SkipPauseRequest shouldSkipStepPause();
    bool isTopCallFrameInFramework();

    void cancelPauseOnNextStatement();
    void addMessageToConsole(MessageSource, MessageType);

    PassRefPtr<TypeBuilder::Array<TypeBuilder::Debugger::CallFrame> > currentCallFrames();
    PassRefPtr<TypeBuilder::Debugger::StackTrace> currentAsyncStackTrace();

    virtual void didParseSource(const String& scriptId, const Script&, CompileResult) override final;
    virtual void didReceiveV8AsyncTaskEvent(ExecutionContext*, const String& eventType, const String& eventName, int id) override final;
    virtual void didReceiveV8PromiseEvent(ScriptState*, v8::Handle<v8::Object> promise, v8::Handle<v8::Value> parentPromise, int status) override final;

    void setPauseOnExceptionsImpl(ErrorString*, int);

    PassRefPtr<TypeBuilder::Debugger::Location> resolveBreakpoint(const String& breakpointId, const String& scriptId, const ScriptBreakpoint&, BreakpointSource);
    void removeBreakpoint(const String& breakpointId);
    void clear();
    bool assertPaused(ErrorString*);
    void clearBreakDetails();

    String sourceMapURLForScript(const Script&, CompileResult);

    PassRefPtr<JavaScriptCallFrame> topCallFrameSkipUnknownSources();
    String scriptURL(JavaScriptCallFrame*);
    AsyncCallStackTracker& asyncCallStackTracker() { return *m_asyncCallStackTracker; };

    typedef HashMap<String, Script> ScriptsMap;
    typedef HashMap<String, Vector<String> > BreakpointIdToDebugServerBreakpointIdsMap;
    typedef HashMap<String, std::pair<String, BreakpointSource> > DebugServerBreakpointToBreakpointIdAndSourceMap;

    RawPtr<InjectedScriptManager> m_injectedScriptManager;
    InspectorFrontend::Debugger* m_frontend;
    RefPtr<ScriptState> m_pausedScriptState;
    ScriptValue m_currentCallStack;
    ScriptsMap m_scripts;
    BreakpointIdToDebugServerBreakpointIdsMap m_breakpointIdToDebugServerBreakpointIds;
    DebugServerBreakpointToBreakpointIdAndSourceMap m_serverBreakpoints;
    String m_continueToLocationBreakpointId;
    InspectorFrontend::Debugger::Reason::Enum m_breakReason;
    RefPtr<JSONObject> m_breakAuxData;
    bool m_javaScriptPauseScheduled;
    bool m_debuggerStepScheduled;
    bool m_steppingFromFramework;
    bool m_pausingOnNativeEvent;
    RawPtr<Listener> m_listener;

    int m_skippedStepInCount;
    int m_minFrameCountForSkip;
    bool m_skipAllPauses;
    OwnPtr<ScriptRegexp> m_cachedSkipStackRegExp;
    OwnPtr<AsyncCallStackTracker> m_asyncCallStackTracker;
    PromiseTracker m_promiseTracker;
};

} // namespace blink


#endif  // SKY_ENGINE_V8_INSPECTOR_INSPECTORDEBUGGERAGENT_H_
