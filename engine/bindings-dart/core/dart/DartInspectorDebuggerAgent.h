/*
 * Copyright (C) 2010 Apple Inc. All rights reserved.
 * Copyright (C) 2010-2014 Google Inc. All rights reserved.
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

#ifndef DartInspectorDebuggerAgent_h
#define DartInspectorDebuggerAgent_h

#include "bindings/common/ScriptState.h"
#include "bindings/core/dart/DartInjectedScript.h"
#include "bindings/core/dart/DartInjectedScriptManager.h"
#include "bindings/core/dart/DartScriptDebugListener.h"
#include "core/InspectorFrontend.h"
#include "core/frame/ConsoleTypes.h"
#include "core/inspector/ConsoleAPITypes.h"
#include "core/inspector/InspectorBaseAgent.h"
#include "core/inspector/ScriptBreakpoint.h"
#include "wtf/Forward.h"
#include "wtf/HashMap.h"
#include "wtf/PassRefPtr.h"
#include "wtf/Vector.h"
#include "wtf/text/StringHash.h"

namespace blink {

class Document;
class Event;
class EventListener;
class EventTarget;
class ExecutionContextTask;
class FormData;
class HTTPHeaderMap;
class InspectorFrontend;
class InstrumentingAgents;
class JavaScriptCallFrame;
class JSONObject;
class KURL;
class MutationObserver;
class ScriptArguments;
class ScriptAsyncCallStack;
class ScriptCallStack;
class ScriptCallFrame;
class DartScriptDebugServer;
class ScriptRegexp;
class ScriptSourceCode;
class ScriptValue;
class ThreadableLoaderClient;
class XMLHttpRequest;
class InspectorDebuggerAgent;

typedef String ErrorString;

class DartInspectorDebuggerAgent : public DartScriptDebugListener {
    WTF_MAKE_NONCOPYABLE(DartInspectorDebuggerAgent);
public:
    enum BreakpointSource {
        UserBreakpointSource,
        DebugCommandBreakpointSource,
        MonitorCommandBreakpointSource
    };
    explicit DartInspectorDebuggerAgent(DartInjectedScriptManager*, InspectorDebuggerAgent*, InspectorPageAgent*);

    static const char backtraceObjectGroup[];

    ~DartInspectorDebuggerAgent();
    virtual void canSetScriptSource(ErrorString*, bool* result) FINAL { *result = true; }

    virtual void init() FINAL;
    virtual void setFrontend(InspectorFrontend*) FINAL;
    virtual void clearFrontend() FINAL;
    virtual void restore() FINAL;

    bool isPaused();
    bool runningNestedMessageLoop();

    // Part of the protocol.
    virtual void enable(ErrorString*) FINAL;
    virtual void disable(ErrorString*) FINAL;
    virtual void setBreakpointsActive(ErrorString*, bool active) FINAL;
    virtual void setSkipAllPauses(ErrorString*, bool skipped, const bool* untilReload) FINAL;

    virtual void setBreakpointByUrl(ErrorString*, int lineNumber, const String* optionalURL, const String* optionalURLRegex, const int* optionalColumnNumber, const String* optionalCondition, const bool* isAntiBreakpoint, TypeBuilder::Debugger::BreakpointId*, RefPtr<TypeBuilder::Array<TypeBuilder::Debugger::Location> >& locations) FINAL;
    virtual void setBreakpoint(ErrorString*, const RefPtr<JSONObject>& location, const String* optionalCondition, TypeBuilder::Debugger::BreakpointId*, RefPtr<TypeBuilder::Debugger::Location>& actualLocation) FINAL;
    virtual void removeBreakpoint(ErrorString*, const String& breakpointId) FINAL;
    virtual void continueToLocation(ErrorString*, const RefPtr<JSONObject>& location, const bool* interstateLocationOpt) FINAL;
    virtual void getBacktrace(ErrorString*, RefPtr<TypeBuilder::Array<TypeBuilder::Debugger::CallFrame> >&, RefPtr<TypeBuilder::Debugger::StackTrace>&) FINAL;

    virtual void searchInContent(ErrorString*, const String& scriptId, const String& query, const bool* optionalCaseSensitive, const bool* optionalIsRegex, RefPtr<TypeBuilder::Array<TypeBuilder::Page::SearchMatch> >&) FINAL;
    virtual void getScriptSource(ErrorString*, const String& scriptId, String* scriptSource) FINAL;
    virtual void getFunctionDetails(ErrorString*, const String& functionId, RefPtr<TypeBuilder::Debugger::FunctionDetails>&) FINAL;
    virtual void pause(ErrorString*) FINAL;
    virtual void resume(ErrorString*) FINAL;
    virtual void stepOver(ErrorString*) FINAL;
    virtual void stepInto(ErrorString*) FINAL;
    virtual void stepOut(ErrorString*) FINAL;
    virtual void setPauseOnExceptions(ErrorString*, const String& pauseState) FINAL;
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
        RefPtr<TypeBuilder::Debugger::ExceptionDetails>&) FINAL;
    virtual void getCompletionsOnCallFrame(ErrorString*,
        const String& callFrameId,
        const String& expression,
        RefPtr<TypeBuilder::Array<String> >& result) FINAL;
    virtual void setOverlayMessage(ErrorString*, const String*);
    virtual void setVariableValue(ErrorString*, int in_scopeNumber, const String& in_variableName, const RefPtr<JSONObject>& in_newValue, const String* in_callFrame, const String* in_functionObjectId) FINAL;
    virtual void skipStackFrames(ErrorString*, const String* pattern) FINAL;

    void schedulePauseOnNextStatement(InspectorFrontend::Debugger::Reason::Enum breakReason, PassRefPtr<JSONObject> data);
    bool canBreakProgram();
    void breakProgram(InspectorFrontend::Debugger::Reason::Enum breakReason, PassRefPtr<JSONObject> data);
    void scriptExecutionBlockedByCSP(const String& directiveText);

    class Listener : public WillBeGarbageCollectedMixin {
    public:
        virtual ~Listener() { }
        virtual void debuggerWasEnabled() = 0;
        virtual void debuggerWasDisabled() = 0;
        virtual void stepInto() = 0;
        virtual void didPause() = 0;
    };
    void setListener(Listener* listener) { m_listener = listener; }

    bool enabled();

    virtual DartScriptDebugServer& scriptDebugServer() = 0;

    void setBreakpoint(const String& scriptId, int lineNumber, int columnNumber, BreakpointSource, const String& condition = String());
    void removeBreakpoint(const String& scriptId, int lineNumber, int columnNumber, BreakpointSource);

    PassRefPtrWillBeRawPtr<ScriptAsyncCallStack> currentAsyncStackTraceForConsole();

    bool isDartScriptId(const String& scriptId);
    bool isDartURL(const String* const optionalURL, const String* const optionalURLRegex);

protected:

    virtual void startListeningScriptDebugServer() = 0;
    virtual void stopListeningScriptDebugServer() = 0;
    virtual void muteConsole() = 0;
    virtual void unmuteConsole() = 0;
    DartInjectedScriptManager* injectedScriptManager() { return m_injectedScriptManager; }
    virtual DartInjectedScript* injectedScriptForEval(ErrorString*, const int* executionContextId) = 0;

    virtual void enable();
    virtual void disable();
    virtual SkipPauseRequest didPause(ScriptState*, Dart_StackTrace callFrames, const ScriptValue& exception, const Vector<String>& hitBreakpoints) FINAL;
    virtual void didContinue() FINAL;
    void reset();
    void pageDidCommitLoad();

protected:
    SkipPauseRequest shouldSkipExceptionPause();
    SkipPauseRequest shouldSkipStepPause();
    bool isTopCallFrameInFramework();

    void cancelPauseOnNextStatement();
    void addMessageToConsole(MessageSource, MessageType);

    PassRefPtr<TypeBuilder::Array<TypeBuilder::Debugger::CallFrame> > currentCallFrames();

    virtual void didParseSource(const String& scriptId, const Script&, CompileResult) FINAL;

    void setPauseOnExceptionsImpl(ErrorString*, int);

    PassRefPtr<TypeBuilder::Debugger::Location> resolveBreakpoint(const String& breakpointId, const String& scriptId, const ScriptBreakpoint&, BreakpointSource);
    void removeBreakpoint(const String& breakpointId);
    void clear();
    bool assertPaused(ErrorString*);
    void clearBreakDetails();

    String sourceMapURLForScript(const Script&, CompileResult);

    ScriptCallFrame topCallFrameSkipUnknownSources();

    InspectorState* state();

    typedef HashMap<String, Script> ScriptsMap;
    typedef HashMap<String, Vector<String> > BreakpointIdToDebugServerBreakpointIdsMap;
    typedef HashMap<String, std::pair<String, BreakpointSource> > DebugServerBreakpointToBreakpointIdAndSourceMap;

    DartInjectedScriptManager* m_injectedScriptManager;
    InspectorFrontend::Debugger* m_frontend;
    RefPtr<ScriptState> m_pausedScriptState;
    Dart_StackTrace m_currentCallStack;
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
    RawPtrWillBeMember<Listener> m_listener;

    int m_skippedStepInCount;
    int m_minFrameCountForSkip;
    bool m_skipAllPauses;
    OwnPtr<ScriptRegexp> m_cachedSkipStackRegExp;
    InspectorDebuggerAgent* m_inspectorDebuggerAgent;
    InspectorPageAgent* m_pageAgent;
};

} // namespace blink


#endif // !defined(DartInspectorDebuggerAgent_h)
