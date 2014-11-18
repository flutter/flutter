/*
 * Copyright (C) 2010 Apple Inc. All rights reserved.
 * Copyright (C) 2013 Google Inc. All rights reserved.
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

#include "config.h"
#include "core/inspector/InspectorDebuggerAgent.h"

#include "bindings/core/v8/ScriptDebugServer.h"
#include "bindings/core/v8/ScriptRegexp.h"
#include "bindings/core/v8/ScriptSourceCode.h"
#include "bindings/core/v8/ScriptValue.h"
#include "core/dom/Document.h"
#include "core/fetch/Resource.h"
#include "core/inspector/ConsoleMessage.h"
#include "core/inspector/ContentSearchUtils.h"
#include "core/inspector/InjectedScriptManager.h"
#include "core/inspector/InspectorState.h"
#include "core/inspector/JavaScriptCallFrame.h"
#include "core/inspector/ScriptArguments.h"
#include "core/inspector/ScriptAsyncCallStack.h"
#include "core/inspector/ScriptCallFrame.h"
#include "core/inspector/ScriptCallStack.h"
#include "platform/JSONValues.h"
#include "wtf/text/StringBuilder.h"
#include "wtf/text/WTFString.h"

using blink::TypeBuilder::Array;
using blink::TypeBuilder::Debugger::BreakpointId;
using blink::TypeBuilder::Debugger::CallFrame;
using blink::TypeBuilder::Debugger::CollectionEntry;
using blink::TypeBuilder::Debugger::ExceptionDetails;
using blink::TypeBuilder::Debugger::FunctionDetails;
using blink::TypeBuilder::Debugger::ScriptId;
using blink::TypeBuilder::Debugger::StackTrace;
using blink::TypeBuilder::Runtime::RemoteObject;

namespace {

static const char v8AsyncTaskEventEnqueue[] = "enqueue";
static const char v8AsyncTaskEventWillHandle[] = "willHandle";
static const char v8AsyncTaskEventDidHandle[] = "didHandle";

}

namespace blink {

namespace DebuggerAgentState {
static const char debuggerEnabled[] = "debuggerEnabled";
static const char javaScriptBreakpoints[] = "javaScriptBreakopints";
static const char pauseOnExceptionsState[] = "pauseOnExceptionsState";
static const char asyncCallStackDepth[] = "asyncCallStackDepth";

// Breakpoint properties.
static const char url[] = "url";
static const char isRegex[] = "isRegex";
static const char lineNumber[] = "lineNumber";
static const char columnNumber[] = "columnNumber";
static const char condition[] = "condition";
static const char isAnti[] = "isAnti";
static const char skipStackPattern[] = "skipStackPattern";
static const char skipAllPauses[] = "skipAllPauses";
static const char skipAllPausesExpiresOnReload[] = "skipAllPausesExpiresOnReload";

};

static const int maxSkipStepInCount = 20;

const char InspectorDebuggerAgent::backtraceObjectGroup[] = "backtrace";

static String breakpointIdSuffix(InspectorDebuggerAgent::BreakpointSource source)
{
    switch (source) {
    case InspectorDebuggerAgent::UserBreakpointSource:
        break;
    case InspectorDebuggerAgent::DebugCommandBreakpointSource:
        return ":debug";
    case InspectorDebuggerAgent::MonitorCommandBreakpointSource:
        return ":monitor";
    }
    return String();
}

static String generateBreakpointId(const String& scriptId, int lineNumber, int columnNumber, InspectorDebuggerAgent::BreakpointSource source)
{
    return scriptId + ':' + String::number(lineNumber) + ':' + String::number(columnNumber) + breakpointIdSuffix(source);
}

InspectorDebuggerAgent::InspectorDebuggerAgent(InjectedScriptManager* injectedScriptManager)
    : InspectorBaseAgent<InspectorDebuggerAgent>("Debugger")
    , m_injectedScriptManager(injectedScriptManager)
    , m_frontend(0)
    , m_pausedScriptState(nullptr)
    , m_javaScriptPauseScheduled(false)
    , m_debuggerStepScheduled(false)
    , m_steppingFromFramework(false)
    , m_pausingOnNativeEvent(false)
    , m_listener(nullptr)
    , m_skippedStepInCount(0)
    , m_skipAllPauses(false)
    , m_asyncCallStackTracker(adoptPtr(new AsyncCallStackTracker()))
{
}

InspectorDebuggerAgent::~InspectorDebuggerAgent()
{
}

void InspectorDebuggerAgent::virtualInit()
{
    // FIXME: make breakReason optional so that there was no need to init it with "other".
    clearBreakDetails();
    m_state->setLong(DebuggerAgentState::pauseOnExceptionsState, ScriptDebugServer::DontPauseOnExceptions);
}

void InspectorDebuggerAgent::enable()
{
    startListeningScriptDebugServer();
    // FIXME(WK44513): breakpoints activated flag should be synchronized between all front-ends
    scriptDebugServer().setBreakpointsActivated(true);

    if (m_listener)
        m_listener->debuggerWasEnabled();
}

void InspectorDebuggerAgent::disable()
{
    m_state->setObject(DebuggerAgentState::javaScriptBreakpoints, JSONObject::create());
    m_state->setLong(DebuggerAgentState::pauseOnExceptionsState, ScriptDebugServer::DontPauseOnExceptions);
    m_state->setString(DebuggerAgentState::skipStackPattern, "");
    m_state->setLong(DebuggerAgentState::asyncCallStackDepth, 0);

    scriptDebugServer().clearBreakpoints();
    scriptDebugServer().clearCompiledScripts();
    scriptDebugServer().clearPreprocessor();
    stopListeningScriptDebugServer();
    clear();

    if (m_listener)
        m_listener->debuggerWasDisabled();

    m_skipAllPauses = false;
}

bool InspectorDebuggerAgent::enabled()
{
    return m_state->getBoolean(DebuggerAgentState::debuggerEnabled);
}

void InspectorDebuggerAgent::enable(ErrorString*)
{
    if (enabled())
        return;

    enable();
    m_state->setBoolean(DebuggerAgentState::debuggerEnabled, true);

    ASSERT(m_frontend);
}

void InspectorDebuggerAgent::disable(ErrorString*)
{
    if (!enabled())
        return;

    disable();
    m_state->setBoolean(DebuggerAgentState::debuggerEnabled, false);
}

static PassOwnPtr<ScriptRegexp> compileSkipCallFramePattern(String patternText)
{
    if (patternText.isEmpty())
        return nullptr;
    OwnPtr<ScriptRegexp> result = adoptPtr(new ScriptRegexp(patternText, TextCaseSensitive));
    if (!result->isValid())
        result.clear();
    return result.release();
}

void InspectorDebuggerAgent::restore()
{
    if (enabled()) {
        m_frontend->globalObjectCleared();
        enable();
        long pauseState = m_state->getLong(DebuggerAgentState::pauseOnExceptionsState);
        String error;
        setPauseOnExceptionsImpl(&error, pauseState);
        m_cachedSkipStackRegExp = compileSkipCallFramePattern(m_state->getString(DebuggerAgentState::skipStackPattern));
        m_skipAllPauses = m_state->getBoolean(DebuggerAgentState::skipAllPauses);
        if (m_skipAllPauses && m_state->getBoolean(DebuggerAgentState::skipAllPausesExpiresOnReload)) {
            m_skipAllPauses = false;
            m_state->setBoolean(DebuggerAgentState::skipAllPauses, false);
        }
        asyncCallStackTracker().setAsyncCallStackDepth(m_state->getLong(DebuggerAgentState::asyncCallStackDepth));
    }
}

void InspectorDebuggerAgent::setFrontend(InspectorFrontend* frontend)
{
    m_frontend = frontend->debugger();
}

void InspectorDebuggerAgent::clearFrontend()
{
    m_frontend = 0;

    if (!enabled())
        return;

    disable();

    // FIXME: due to m_state->mute() hack in InspectorController, debuggerEnabled is actually set to false only
    // in InspectorState, but not in cookie. That's why after navigation debuggerEnabled will be true,
    // but after front-end re-open it will still be false.
    m_state->setBoolean(DebuggerAgentState::debuggerEnabled, false);
}

void InspectorDebuggerAgent::setBreakpointsActive(ErrorString*, bool active)
{
    scriptDebugServer().setBreakpointsActivated(active);
}

void InspectorDebuggerAgent::setSkipAllPauses(ErrorString*, bool skipped, const bool* untilReload)
{
    m_skipAllPauses = skipped;
    m_state->setBoolean(DebuggerAgentState::skipAllPauses, m_skipAllPauses);
    m_state->setBoolean(DebuggerAgentState::skipAllPausesExpiresOnReload, asBool(untilReload));
}

void InspectorDebuggerAgent::pageDidCommitLoad()
{
    if (m_state->getBoolean(DebuggerAgentState::skipAllPausesExpiresOnReload)) {
        m_skipAllPauses = false;
        m_state->setBoolean(DebuggerAgentState::skipAllPauses, m_skipAllPauses);
    }
}

bool InspectorDebuggerAgent::isPaused()
{
    return scriptDebugServer().isPaused();
}

bool InspectorDebuggerAgent::runningNestedMessageLoop()
{
    return scriptDebugServer().runningNestedMessageLoop();
}

void InspectorDebuggerAgent::addMessageToConsole(ConsoleMessage* consoleMessage)
{
    if (consoleMessage->type() == AssertMessageType && scriptDebugServer().pauseOnExceptionsState() != ScriptDebugServer::DontPauseOnExceptions)
        breakProgram(InspectorFrontend::Debugger::Reason::Assert, nullptr);
}

String InspectorDebuggerAgent::preprocessEventListener(LocalFrame* frame, const String& source, const String& url, const String& functionName)
{
    return scriptDebugServer().preprocessEventListener(frame, source, url, functionName);
}

PassOwnPtr<ScriptSourceCode> InspectorDebuggerAgent::preprocess(LocalFrame* frame, const ScriptSourceCode& sourceCode)
{
    return scriptDebugServer().preprocess(frame, sourceCode);
}

static PassRefPtr<JSONObject> buildObjectForBreakpointCookie(const String& url, int lineNumber, int columnNumber, const String& condition, bool isRegex, bool isAnti)
{
    RefPtr<JSONObject> breakpointObject = JSONObject::create();
    breakpointObject->setString(DebuggerAgentState::url, url);
    breakpointObject->setNumber(DebuggerAgentState::lineNumber, lineNumber);
    breakpointObject->setNumber(DebuggerAgentState::columnNumber, columnNumber);
    breakpointObject->setString(DebuggerAgentState::condition, condition);
    breakpointObject->setBoolean(DebuggerAgentState::isRegex, isRegex);
    breakpointObject->setBoolean(DebuggerAgentState::isAnti, isAnti);
    return breakpointObject;
}

static String scriptSourceURL(const ScriptDebugListener::Script& script)
{
    bool hasSourceURL = !script.sourceURL.isEmpty();
    return hasSourceURL ? script.sourceURL : script.url;
}

static bool matches(const String& url, const String& pattern, bool isRegex)
{
    if (isRegex) {
        ScriptRegexp regex(pattern, TextCaseSensitive);
        return regex.match(url) != -1;
    }
    return url == pattern;
}

void InspectorDebuggerAgent::setBreakpointByUrl(ErrorString* errorString, int lineNumber, const String* const optionalURL, const String* const optionalURLRegex, const int* const optionalColumnNumber, const String* const optionalCondition, const bool* isAntiBreakpoint, BreakpointId* outBreakpointId, RefPtr<Array<TypeBuilder::Debugger::Location> >& locations)
{
    locations = Array<TypeBuilder::Debugger::Location>::create();
    if (!optionalURL == !optionalURLRegex) {
        *errorString = "Either url or urlRegex must be specified.";
        return;
    }

    bool isAntiBreakpointValue = asBool(isAntiBreakpoint);

    String url = optionalURL ? *optionalURL : *optionalURLRegex;
    int columnNumber;
    if (optionalColumnNumber) {
        columnNumber = *optionalColumnNumber;
        if (columnNumber < 0) {
            *errorString = "Incorrect column number";
            return;
        }
    } else {
        columnNumber = isAntiBreakpointValue ? -1 : 0;
    }
    String condition = optionalCondition ? *optionalCondition : "";
    bool isRegex = optionalURLRegex;

    String breakpointId = (isRegex ? "/" + url + "/" : url) + ':' + String::number(lineNumber) + ':' + String::number(columnNumber);
    RefPtr<JSONObject> breakpointsCookie = m_state->getObject(DebuggerAgentState::javaScriptBreakpoints);
    if (breakpointsCookie->find(breakpointId) != breakpointsCookie->end()) {
        *errorString = "Breakpoint at specified location already exists.";
        return;
    }

    breakpointsCookie->setObject(breakpointId, buildObjectForBreakpointCookie(url, lineNumber, columnNumber, condition, isRegex, isAntiBreakpointValue));
    m_state->setObject(DebuggerAgentState::javaScriptBreakpoints, breakpointsCookie);

    if (!isAntiBreakpointValue) {
        ScriptBreakpoint breakpoint(lineNumber, columnNumber, condition);
        for (ScriptsMap::iterator it = m_scripts.begin(); it != m_scripts.end(); ++it) {
            if (!matches(scriptSourceURL(it->value), url, isRegex))
                continue;
            RefPtr<TypeBuilder::Debugger::Location> location = resolveBreakpoint(breakpointId, it->key, breakpoint, UserBreakpointSource);
            if (location)
                locations->addItem(location);
        }
    }
    *outBreakpointId = breakpointId;
}

static bool parseLocation(ErrorString* errorString, PassRefPtr<JSONObject> location, String* scriptId, int* lineNumber, int* columnNumber)
{
    if (!location->getString("scriptId", scriptId) || !location->getNumber("lineNumber", lineNumber)) {
        // FIXME: replace with input validation.
        *errorString = "scriptId and lineNumber are required.";
        return false;
    }
    *columnNumber = 0;
    location->getNumber("columnNumber", columnNumber);
    return true;
}

void InspectorDebuggerAgent::setBreakpoint(ErrorString* errorString, const RefPtr<JSONObject>& location, const String* const optionalCondition, BreakpointId* outBreakpointId, RefPtr<TypeBuilder::Debugger::Location>& actualLocation)
{
    String scriptId;
    int lineNumber;
    int columnNumber;

    if (!parseLocation(errorString, location, &scriptId, &lineNumber, &columnNumber))
        return;

    String condition = optionalCondition ? *optionalCondition : emptyString();

    String breakpointId = generateBreakpointId(scriptId, lineNumber, columnNumber, UserBreakpointSource);
    if (m_breakpointIdToDebugServerBreakpointIds.find(breakpointId) != m_breakpointIdToDebugServerBreakpointIds.end()) {
        *errorString = "Breakpoint at specified location already exists.";
        return;
    }
    ScriptBreakpoint breakpoint(lineNumber, columnNumber, condition);
    actualLocation = resolveBreakpoint(breakpointId, scriptId, breakpoint, UserBreakpointSource);
    if (actualLocation)
        *outBreakpointId = breakpointId;
    else
        *errorString = "Could not resolve breakpoint";
}

void InspectorDebuggerAgent::removeBreakpoint(ErrorString*, const String& breakpointId)
{
    RefPtr<JSONObject> breakpointsCookie = m_state->getObject(DebuggerAgentState::javaScriptBreakpoints);
    JSONObject::iterator it = breakpointsCookie->find(breakpointId);
    bool isAntibreakpoint = false;
    if (it != breakpointsCookie->end()) {
        RefPtr<JSONObject> breakpointObject = it->value->asObject();
        breakpointObject->getBoolean(DebuggerAgentState::isAnti, &isAntibreakpoint);
        breakpointsCookie->remove(breakpointId);
        m_state->setObject(DebuggerAgentState::javaScriptBreakpoints, breakpointsCookie);
    }

    if (!isAntibreakpoint)
        removeBreakpoint(breakpointId);
}

void InspectorDebuggerAgent::removeBreakpoint(const String& breakpointId)
{
    BreakpointIdToDebugServerBreakpointIdsMap::iterator debugServerBreakpointIdsIterator = m_breakpointIdToDebugServerBreakpointIds.find(breakpointId);
    if (debugServerBreakpointIdsIterator == m_breakpointIdToDebugServerBreakpointIds.end())
        return;
    for (size_t i = 0; i < debugServerBreakpointIdsIterator->value.size(); ++i) {
        const String& debugServerBreakpointId = debugServerBreakpointIdsIterator->value[i];
        scriptDebugServer().removeBreakpoint(debugServerBreakpointId);
        m_serverBreakpoints.remove(debugServerBreakpointId);
    }
    m_breakpointIdToDebugServerBreakpointIds.remove(debugServerBreakpointIdsIterator);
}

void InspectorDebuggerAgent::continueToLocation(ErrorString* errorString, const RefPtr<JSONObject>& location, const bool* interstateLocationOpt)
{
    if (!m_continueToLocationBreakpointId.isEmpty()) {
        scriptDebugServer().removeBreakpoint(m_continueToLocationBreakpointId);
        m_continueToLocationBreakpointId = "";
    }

    String scriptId;
    int lineNumber;
    int columnNumber;

    if (!parseLocation(errorString, location, &scriptId, &lineNumber, &columnNumber))
        return;

    ScriptBreakpoint breakpoint(lineNumber, columnNumber, "");
    m_continueToLocationBreakpointId = scriptDebugServer().setBreakpoint(scriptId, breakpoint, &lineNumber, &columnNumber, asBool(interstateLocationOpt));
    resume(errorString);
}

void InspectorDebuggerAgent::getStepInPositions(ErrorString* errorString, const String& callFrameId, RefPtr<Array<TypeBuilder::Debugger::Location> >& positions)
{
    if (!isPaused() || m_currentCallStack.isEmpty()) {
        *errorString = "Attempt to access callframe when debugger is not on pause";
        return;
    }
    InjectedScript injectedScript = m_injectedScriptManager->injectedScriptForObjectId(callFrameId);
    if (injectedScript.isEmpty()) {
        *errorString = "Inspected frame has gone";
        return;
    }

    injectedScript.getStepInPositions(errorString, m_currentCallStack, callFrameId, positions);
}

void InspectorDebuggerAgent::getBacktrace(ErrorString* errorString, RefPtr<Array<CallFrame> >& callFrames, RefPtr<StackTrace>& asyncStackTrace)
{
    if (!assertPaused(errorString))
        return;
    m_currentCallStack = scriptDebugServer().currentCallFrames();
    callFrames = currentCallFrames();
    asyncStackTrace = currentAsyncStackTrace();
}

PassRefPtr<JavaScriptCallFrame> InspectorDebuggerAgent::topCallFrameSkipUnknownSources()
{
    for (int index = 0; ; ++index) {
        RefPtr<JavaScriptCallFrame> frame = scriptDebugServer().callFrameNoScopes(index);
        if (!frame)
            return nullptr;
        String scriptIdString = String::number(frame->sourceID());
        if (m_scripts.contains(scriptIdString))
            return frame.release();
    }
}

String InspectorDebuggerAgent::scriptURL(JavaScriptCallFrame* frame)
{
    String scriptIdString = String::number(frame->sourceID());
    ScriptsMap::iterator it = m_scripts.find(scriptIdString);
    if (it == m_scripts.end())
        return String();
    return scriptSourceURL(it->value);
}

ScriptDebugListener::SkipPauseRequest InspectorDebuggerAgent::shouldSkipExceptionPause()
{
    if (m_steppingFromFramework)
        return ScriptDebugListener::NoSkip;

    // FIXME: Fast return: if (!m_cachedSkipStackRegExp && !has_any_anti_breakpoint) return ScriptDebugListener::NoSkip;

    RefPtr<JavaScriptCallFrame> topFrame = topCallFrameSkipUnknownSources();
    if (!topFrame)
        return ScriptDebugListener::NoSkip;

    String topFrameScriptUrl = scriptURL(topFrame.get());
    if (m_cachedSkipStackRegExp && !topFrameScriptUrl.isEmpty() && m_cachedSkipStackRegExp->match(topFrameScriptUrl) != -1)
        return ScriptDebugListener::Continue;

    // Match against breakpoints.
    if (topFrameScriptUrl.isEmpty())
        return ScriptDebugListener::NoSkip;

    // Prepare top frame parameters.
    int topFrameLineNumber = topFrame->line();
    int topFrameColumnNumber = topFrame->column();

    RefPtr<JSONObject> breakpointsCookie = m_state->getObject(DebuggerAgentState::javaScriptBreakpoints);
    for (JSONObject::iterator it = breakpointsCookie->begin(); it != breakpointsCookie->end(); ++it) {
        RefPtr<JSONObject> breakpointObject = it->value->asObject();
        bool isAntibreakpoint;
        breakpointObject->getBoolean(DebuggerAgentState::isAnti, &isAntibreakpoint);
        if (!isAntibreakpoint)
            continue;

        int breakLineNumber;
        breakpointObject->getNumber(DebuggerAgentState::lineNumber, &breakLineNumber);
        int breakColumnNumber;
        breakpointObject->getNumber(DebuggerAgentState::columnNumber, &breakColumnNumber);

        if (breakLineNumber != topFrameLineNumber)
            continue;

        if (breakColumnNumber != -1 && breakColumnNumber != topFrameColumnNumber)
            continue;

        bool isRegex;
        breakpointObject->getBoolean(DebuggerAgentState::isRegex, &isRegex);
        String url;
        breakpointObject->getString(DebuggerAgentState::url, &url);
        if (!matches(topFrameScriptUrl, url, isRegex))
            continue;

        return ScriptDebugListener::Continue;
    }

    return ScriptDebugListener::NoSkip;
}

ScriptDebugListener::SkipPauseRequest InspectorDebuggerAgent::shouldSkipStepPause()
{
    if (!m_cachedSkipStackRegExp || m_steppingFromFramework)
        return ScriptDebugListener::NoSkip;

    RefPtr<JavaScriptCallFrame> topFrame = topCallFrameSkipUnknownSources();
    String scriptUrl = scriptURL(topFrame.get());
    if (scriptUrl.isEmpty() || m_cachedSkipStackRegExp->match(scriptUrl) == -1)
        return ScriptDebugListener::NoSkip;

    if (m_skippedStepInCount == 0) {
        m_minFrameCountForSkip = scriptDebugServer().frameCount();
        m_skippedStepInCount = 1;
        return ScriptDebugListener::StepInto;
    }

    if (m_skippedStepInCount < maxSkipStepInCount && topFrame->isAtReturn() && scriptDebugServer().frameCount() <= m_minFrameCountForSkip)
        m_skippedStepInCount = maxSkipStepInCount;

    if (m_skippedStepInCount >= maxSkipStepInCount) {
        if (m_pausingOnNativeEvent) {
            m_pausingOnNativeEvent = false;
            m_skippedStepInCount = 0;
            return ScriptDebugListener::Continue;
        }
        return ScriptDebugListener::StepOut;
    }

    ++m_skippedStepInCount;
    return ScriptDebugListener::StepInto;
}

bool InspectorDebuggerAgent::isTopCallFrameInFramework()
{
    if (!m_cachedSkipStackRegExp)
        return false;

    RefPtr<JavaScriptCallFrame> topFrame = topCallFrameSkipUnknownSources();
    if (!topFrame)
        return false;

    String scriptUrl = scriptURL(topFrame.get());
    return !scriptUrl.isEmpty() && m_cachedSkipStackRegExp->match(scriptUrl) != -1;
}

PassRefPtr<TypeBuilder::Debugger::Location> InspectorDebuggerAgent::resolveBreakpoint(const String& breakpointId, const String& scriptId, const ScriptBreakpoint& breakpoint, BreakpointSource source)
{
    ScriptsMap::iterator scriptIterator = m_scripts.find(scriptId);
    if (scriptIterator == m_scripts.end())
        return nullptr;
    Script& script = scriptIterator->value;
    if (breakpoint.lineNumber < script.startLine || script.endLine < breakpoint.lineNumber)
        return nullptr;

    int actualLineNumber;
    int actualColumnNumber;
    String debugServerBreakpointId = scriptDebugServer().setBreakpoint(scriptId, breakpoint, &actualLineNumber, &actualColumnNumber, false);
    if (debugServerBreakpointId.isEmpty())
        return nullptr;

    m_serverBreakpoints.set(debugServerBreakpointId, std::make_pair(breakpointId, source));

    BreakpointIdToDebugServerBreakpointIdsMap::iterator debugServerBreakpointIdsIterator = m_breakpointIdToDebugServerBreakpointIds.find(breakpointId);
    if (debugServerBreakpointIdsIterator == m_breakpointIdToDebugServerBreakpointIds.end())
        m_breakpointIdToDebugServerBreakpointIds.set(breakpointId, Vector<String>()).storedValue->value.append(debugServerBreakpointId);
    else
        debugServerBreakpointIdsIterator->value.append(debugServerBreakpointId);

    RefPtr<TypeBuilder::Debugger::Location> location = TypeBuilder::Debugger::Location::create()
        .setScriptId(scriptId)
        .setLineNumber(actualLineNumber);
    location->setColumnNumber(actualColumnNumber);
    return location;
}

void InspectorDebuggerAgent::searchInContent(ErrorString* error, const String& scriptId, const String& query, const bool* const optionalCaseSensitive, const bool* const optionalIsRegex, RefPtr<Array<blink::TypeBuilder::Page::SearchMatch> >& results)
{
    ScriptsMap::iterator it = m_scripts.find(scriptId);
    if (it != m_scripts.end())
        results = ContentSearchUtils::searchInTextByLines(it->value.source, query, asBool(optionalCaseSensitive), asBool(optionalIsRegex));
    else
        *error = "No script for id: " + scriptId;
}

void InspectorDebuggerAgent::setScriptSource(ErrorString* error, RefPtr<TypeBuilder::Debugger::SetScriptSourceError>& errorData, const String& scriptId, const String& newContent, const bool* const preview, RefPtr<Array<CallFrame> >& newCallFrames, RefPtr<JSONObject>& result, RefPtr<StackTrace>& asyncStackTrace)
{
    if (!scriptDebugServer().setScriptSource(scriptId, newContent, asBool(preview), error, errorData, &m_currentCallStack, &result))
        return;

    newCallFrames = currentCallFrames();
    asyncStackTrace = currentAsyncStackTrace();
    // FIXME(sky): Used to tell the page agent.
}

void InspectorDebuggerAgent::restartFrame(ErrorString* errorString, const String& callFrameId, RefPtr<Array<CallFrame> >& newCallFrames, RefPtr<JSONObject>& result, RefPtr<StackTrace>& asyncStackTrace)
{
    if (!isPaused() || m_currentCallStack.isEmpty()) {
        *errorString = "Attempt to access callframe when debugger is not on pause";
        return;
    }
    InjectedScript injectedScript = m_injectedScriptManager->injectedScriptForObjectId(callFrameId);
    if (injectedScript.isEmpty()) {
        *errorString = "Inspected frame has gone";
        return;
    }

    injectedScript.restartFrame(errorString, m_currentCallStack, callFrameId, &result);
    m_currentCallStack = scriptDebugServer().currentCallFrames();
    newCallFrames = currentCallFrames();
    asyncStackTrace = currentAsyncStackTrace();
}

void InspectorDebuggerAgent::getScriptSource(ErrorString* error, const String& scriptId, String* scriptSource)
{
    ScriptsMap::iterator it = m_scripts.find(scriptId);
    if (it == m_scripts.end()) {
        *error = "No script for id: " + scriptId;
        return;
    }

    String url = it->value.url;
    // FIXME(sky): Fetch the script from the page agent?
    *scriptSource = it->value.source;
}

void InspectorDebuggerAgent::getFunctionDetails(ErrorString* errorString, const String& functionId, RefPtr<FunctionDetails>& details)
{
    InjectedScript injectedScript = m_injectedScriptManager->injectedScriptForObjectId(functionId);
    if (injectedScript.isEmpty()) {
        *errorString = "Function object id is obsolete";
        return;
    }
    injectedScript.getFunctionDetails(errorString, functionId, &details);
}

void InspectorDebuggerAgent::getCollectionEntries(ErrorString* errorString, const String& objectId, RefPtr<TypeBuilder::Array<CollectionEntry> >& entries)
{
    InjectedScript injectedScript = m_injectedScriptManager->injectedScriptForObjectId(objectId);
    if (injectedScript.isEmpty()) {
        *errorString = "Inspected frame has gone";
        return;
    }
    injectedScript.getCollectionEntries(errorString, objectId, &entries);
}

void InspectorDebuggerAgent::schedulePauseOnNextStatement(InspectorFrontend::Debugger::Reason::Enum breakReason, PassRefPtr<JSONObject> data)
{
    if (m_javaScriptPauseScheduled || isPaused())
        return;
    m_breakReason = breakReason;
    m_breakAuxData = data;
    m_pausingOnNativeEvent = true;
    scriptDebugServer().setPauseOnNextStatement(true);
}

void InspectorDebuggerAgent::cancelPauseOnNextStatement()
{
    if (m_javaScriptPauseScheduled || isPaused())
        return;
    clearBreakDetails();
    m_pausingOnNativeEvent = false;
    scriptDebugServer().setPauseOnNextStatement(false);
}

void InspectorDebuggerAgent::didInstallTimer(ExecutionContext* context, int timerId, int timeout, bool singleShot)
{
    if (asyncCallStackTracker().isEnabled())
        asyncCallStackTracker().didInstallTimer(context, timerId, singleShot, scriptDebugServer().currentCallFramesForAsyncStack());
}

void InspectorDebuggerAgent::didRemoveTimer(ExecutionContext* context, int timerId)
{
    if (asyncCallStackTracker().isEnabled())
        asyncCallStackTracker().didRemoveTimer(context, timerId);
}

bool InspectorDebuggerAgent::willFireTimer(ExecutionContext* context, int timerId)
{
    if (asyncCallStackTracker().isEnabled())
        asyncCallStackTracker().willFireTimer(context, timerId);
    return true;
}

void InspectorDebuggerAgent::didFireTimer()
{
    if (asyncCallStackTracker().isEnabled())
        asyncCallStackTracker().didFireAsyncCall();
    cancelPauseOnNextStatement();
}

void InspectorDebuggerAgent::didRequestAnimationFrame(Document* document, int callbackId)
{
    if (asyncCallStackTracker().isEnabled())
        asyncCallStackTracker().didRequestAnimationFrame(document, callbackId, scriptDebugServer().currentCallFramesForAsyncStack());
}

void InspectorDebuggerAgent::didCancelAnimationFrame(Document* document, int callbackId)
{
    if (asyncCallStackTracker().isEnabled())
        asyncCallStackTracker().didCancelAnimationFrame(document, callbackId);
}

bool InspectorDebuggerAgent::willFireAnimationFrame(Document* document, int callbackId)
{
    if (asyncCallStackTracker().isEnabled())
        asyncCallStackTracker().willFireAnimationFrame(document, callbackId);
    return true;
}

void InspectorDebuggerAgent::didFireAnimationFrame()
{
    if (asyncCallStackTracker().isEnabled())
        asyncCallStackTracker().didFireAsyncCall();
}

void InspectorDebuggerAgent::didEnqueueEvent(EventTarget* eventTarget, Event* event)
{
    if (asyncCallStackTracker().isEnabled())
        asyncCallStackTracker().didEnqueueEvent(eventTarget, event, scriptDebugServer().currentCallFramesForAsyncStack());
}

void InspectorDebuggerAgent::didRemoveEvent(EventTarget* eventTarget, Event* event)
{
    if (asyncCallStackTracker().isEnabled())
        asyncCallStackTracker().didRemoveEvent(eventTarget, event);
}

void InspectorDebuggerAgent::willHandleEvent(EventTarget* eventTarget, Event* event, EventListener* listener, bool useCapture)
{
    if (asyncCallStackTracker().isEnabled())
        asyncCallStackTracker().willHandleEvent(eventTarget, event, listener, useCapture);
}

void InspectorDebuggerAgent::didHandleEvent()
{
    if (asyncCallStackTracker().isEnabled())
        asyncCallStackTracker().didFireAsyncCall();
    cancelPauseOnNextStatement();
}

void InspectorDebuggerAgent::didEnqueueMutationRecord(ExecutionContext* context, MutationObserver* observer)
{
    if (asyncCallStackTracker().isEnabled() && !asyncCallStackTracker().hasEnqueuedMutationRecord(context, observer))
        asyncCallStackTracker().didEnqueueMutationRecord(context, observer, scriptDebugServer().currentCallFramesForAsyncStack());
}

void InspectorDebuggerAgent::didClearAllMutationRecords(ExecutionContext* context, MutationObserver* observer)
{
    if (asyncCallStackTracker().isEnabled())
        asyncCallStackTracker().didClearAllMutationRecords(context, observer);
}

void InspectorDebuggerAgent::willDeliverMutationRecords(ExecutionContext* context, MutationObserver* observer)
{
    if (asyncCallStackTracker().isEnabled())
        asyncCallStackTracker().willDeliverMutationRecords(context, observer);
}

void InspectorDebuggerAgent::didDeliverMutationRecords()
{
    if (asyncCallStackTracker().isEnabled())
        asyncCallStackTracker().didFireAsyncCall();
}

// void InspectorDebuggerAgent::didPostExecutionContextTask(ExecutionContext* context, ExecutionContextTask* task)
// {
//     if (asyncCallStackTracker().isEnabled() && !task->taskNameForInstrumentation().isEmpty())
//         asyncCallStackTracker().didPostExecutionContextTask(context, task, scriptDebugServer().currentCallFramesForAsyncStack());
// }

// void InspectorDebuggerAgent::didKillAllExecutionContextTasks(ExecutionContext* context)
// {
//     if (asyncCallStackTracker().isEnabled())
//         asyncCallStackTracker().didKillAllExecutionContextTasks(context);
// }

// void InspectorDebuggerAgent::willPerformExecutionContextTask(ExecutionContext* context, ExecutionContextTask* task)
// {
//     if (asyncCallStackTracker().isEnabled())
//         asyncCallStackTracker().willPerformExecutionContextTask(context, task);
// }

// void InspectorDebuggerAgent::didPerformExecutionContextTask()
// {
//     if (asyncCallStackTracker().isEnabled())
//         asyncCallStackTracker().didFireAsyncCall();
// }

int InspectorDebuggerAgent::traceAsyncOperationStarting(ExecutionContext* context, const String& operationName, int prevOperationId)
{
    if (!asyncCallStackTracker().isEnabled())
        return 0;
    if (prevOperationId)
        asyncCallStackTracker().traceAsyncOperationCompleted(context, prevOperationId);
    return asyncCallStackTracker().traceAsyncOperationStarting(context, operationName, scriptDebugServer().currentCallFramesForAsyncStack());
}

void InspectorDebuggerAgent::traceAsyncOperationCompleted(ExecutionContext* context, int operationId)
{
    if (asyncCallStackTracker().isEnabled())
        asyncCallStackTracker().traceAsyncOperationCompleted(context, operationId);
}

void InspectorDebuggerAgent::traceAsyncOperationCompletedCallbackStarting(ExecutionContext* context, int operationId)
{
    if (!asyncCallStackTracker().isEnabled())
        return;
    asyncCallStackTracker().traceAsyncCallbackStarting(context, operationId);
    asyncCallStackTracker().traceAsyncOperationCompleted(context, operationId);
}

void InspectorDebuggerAgent::traceAsyncCallbackStarting(ExecutionContext* context, int operationId)
{
    if (asyncCallStackTracker().isEnabled())
        asyncCallStackTracker().traceAsyncCallbackStarting(context, operationId);
}

void InspectorDebuggerAgent::traceAsyncCallbackCompleted()
{
    if (asyncCallStackTracker().isEnabled())
        asyncCallStackTracker().didFireAsyncCall();
}

void InspectorDebuggerAgent::didReceiveV8AsyncTaskEvent(ExecutionContext* context, const String& eventType, const String& eventName, int id)
{
    if (!asyncCallStackTracker().isEnabled())
        return;
    if (eventType == v8AsyncTaskEventEnqueue)
        asyncCallStackTracker().didEnqueueV8AsyncTask(context, eventName, id, scriptDebugServer().currentCallFramesForAsyncStack());
    else if (eventType == v8AsyncTaskEventWillHandle)
        asyncCallStackTracker().willHandleV8AsyncTask(context, eventName, id);
    else if (eventType == v8AsyncTaskEventDidHandle)
        asyncCallStackTracker().didFireAsyncCall();
    else
        ASSERT_NOT_REACHED();
}

void InspectorDebuggerAgent::didReceiveV8PromiseEvent(ScriptState* scriptState, v8::Handle<v8::Object> promise, v8::Handle<v8::Value> parentPromise, int status)
{
    if (!m_promiseTracker.isEnabled())
        return;
    m_promiseTracker.didReceiveV8PromiseEvent(scriptState, promise, parentPromise, status);
}

void InspectorDebuggerAgent::pause(ErrorString*)
{
    if (m_javaScriptPauseScheduled || isPaused())
        return;
    clearBreakDetails();
    m_javaScriptPauseScheduled = true;
    scriptDebugServer().setPauseOnNextStatement(true);
}

void InspectorDebuggerAgent::resume(ErrorString* errorString)
{
    if (!assertPaused(errorString))
        return;
    m_debuggerStepScheduled = false;
    m_steppingFromFramework = false;
    m_injectedScriptManager->releaseObjectGroup(InspectorDebuggerAgent::backtraceObjectGroup);
    scriptDebugServer().continueProgram();
}

void InspectorDebuggerAgent::stepOver(ErrorString* errorString)
{
    if (!assertPaused(errorString))
        return;
    m_debuggerStepScheduled = true;
    m_steppingFromFramework = isTopCallFrameInFramework();
    m_injectedScriptManager->releaseObjectGroup(InspectorDebuggerAgent::backtraceObjectGroup);
    scriptDebugServer().stepOverStatement();
}

void InspectorDebuggerAgent::stepInto(ErrorString* errorString)
{
    if (!assertPaused(errorString))
        return;
    m_debuggerStepScheduled = true;
    m_steppingFromFramework = isTopCallFrameInFramework();
    m_injectedScriptManager->releaseObjectGroup(InspectorDebuggerAgent::backtraceObjectGroup);
    scriptDebugServer().stepIntoStatement();
    if (m_listener)
        m_listener->stepInto();
}

void InspectorDebuggerAgent::stepOut(ErrorString* errorString)
{
    if (!assertPaused(errorString))
        return;
    m_debuggerStepScheduled = true;
    m_steppingFromFramework = isTopCallFrameInFramework();
    m_injectedScriptManager->releaseObjectGroup(InspectorDebuggerAgent::backtraceObjectGroup);
    scriptDebugServer().stepOutOfFunction();
}

void InspectorDebuggerAgent::setPauseOnExceptions(ErrorString* errorString, const String& stringPauseState)
{
    ScriptDebugServer::PauseOnExceptionsState pauseState;
    if (stringPauseState == "none")
        pauseState = ScriptDebugServer::DontPauseOnExceptions;
    else if (stringPauseState == "all")
        pauseState = ScriptDebugServer::PauseOnAllExceptions;
    else if (stringPauseState == "uncaught")
        pauseState = ScriptDebugServer::PauseOnUncaughtExceptions;
    else {
        *errorString = "Unknown pause on exceptions mode: " + stringPauseState;
        return;
    }
    setPauseOnExceptionsImpl(errorString, pauseState);
}

void InspectorDebuggerAgent::setPauseOnExceptionsImpl(ErrorString* errorString, int pauseState)
{
    scriptDebugServer().setPauseOnExceptionsState(static_cast<ScriptDebugServer::PauseOnExceptionsState>(pauseState));
    if (scriptDebugServer().pauseOnExceptionsState() != pauseState)
        *errorString = "Internal error. Could not change pause on exceptions state";
    else
        m_state->setLong(DebuggerAgentState::pauseOnExceptionsState, pauseState);
}

void InspectorDebuggerAgent::evaluateOnCallFrame(ErrorString* errorString, const String& callFrameId, const String& expression, const String* const objectGroup, const bool* const includeCommandLineAPI, const bool* const doNotPauseOnExceptionsAndMuteConsole, const bool* const returnByValue, const bool* generatePreview, RefPtr<RemoteObject>& result, TypeBuilder::OptOutput<bool>* wasThrown, RefPtr<TypeBuilder::Debugger::ExceptionDetails>& exceptionDetails)
{
    if (!isPaused() || m_currentCallStack.isEmpty()) {
        *errorString = "Attempt to access callframe when debugger is not on pause";
        return;
    }
    InjectedScript injectedScript = m_injectedScriptManager->injectedScriptForObjectId(callFrameId);
    if (injectedScript.isEmpty()) {
        *errorString = "Inspected frame has gone";
        return;
    }

    ScriptDebugServer::PauseOnExceptionsState previousPauseOnExceptionsState = scriptDebugServer().pauseOnExceptionsState();
    if (asBool(doNotPauseOnExceptionsAndMuteConsole)) {
        if (previousPauseOnExceptionsState != ScriptDebugServer::DontPauseOnExceptions)
            scriptDebugServer().setPauseOnExceptionsState(ScriptDebugServer::DontPauseOnExceptions);
        muteConsole();
    }

    Vector<ScriptValue> asyncCallStacks;
    const AsyncCallStackTracker::AsyncCallChain* asyncChain = asyncCallStackTracker().isEnabled() ? asyncCallStackTracker().currentAsyncCallChain() : 0;
    if (asyncChain) {
        const AsyncCallStackTracker::AsyncCallStackVector& callStacks = asyncChain->callStacks();
        asyncCallStacks.resize(callStacks.size());
        AsyncCallStackTracker::AsyncCallStackVector::const_iterator it = callStacks.begin();
        for (size_t i = 0; it != callStacks.end(); ++it, ++i)
            asyncCallStacks[i] = (*it)->callFrames();
    }

    injectedScript.evaluateOnCallFrame(errorString, m_currentCallStack, asyncCallStacks, callFrameId, expression, objectGroup ? *objectGroup : "", asBool(includeCommandLineAPI), asBool(returnByValue), asBool(generatePreview), &result, wasThrown, &exceptionDetails);
    // V8 doesn't generate afterCompile event when it's in debugger therefore there is no content of evaluated scripts on frontend
    // therefore contents of the stack does not provide necessary information
    if (exceptionDetails)
        exceptionDetails->setStackTrace(TypeBuilder::Array<TypeBuilder::Console::CallFrame>::create());
    if (asBool(doNotPauseOnExceptionsAndMuteConsole)) {
        unmuteConsole();
        if (scriptDebugServer().pauseOnExceptionsState() != previousPauseOnExceptionsState)
            scriptDebugServer().setPauseOnExceptionsState(previousPauseOnExceptionsState);
    }
}

void InspectorDebuggerAgent::compileScript(ErrorString* errorString, const String& expression, const String& sourceURL, const int* executionContextId, TypeBuilder::OptOutput<ScriptId>* scriptId, RefPtr<ExceptionDetails>& exceptionDetails)
{
    InjectedScript injectedScript = injectedScriptForEval(errorString, executionContextId);
    if (injectedScript.isEmpty()) {
        *errorString = "Inspected frame has gone";
        return;
    }

    String scriptIdValue;
    String exceptionDetailsText;
    int lineNumberValue = 0;
    int columnNumberValue = 0;
    RefPtr<ScriptCallStack> stackTraceValue;
    scriptDebugServer().compileScript(injectedScript.scriptState(), expression, sourceURL, &scriptIdValue, &exceptionDetailsText, &lineNumberValue, &columnNumberValue, &stackTraceValue);
    if (!scriptIdValue && !exceptionDetailsText) {
        *errorString = "Script compilation failed";
        return;
    }
    *scriptId = scriptIdValue;
    if (!scriptIdValue.isEmpty())
        return;

    exceptionDetails = ExceptionDetails::create().setText(exceptionDetailsText);
    exceptionDetails->setLine(lineNumberValue);
    exceptionDetails->setColumn(columnNumberValue);
    if (stackTraceValue && stackTraceValue->size() > 0)
        exceptionDetails->setStackTrace(stackTraceValue->buildInspectorArray());
}

void InspectorDebuggerAgent::runScript(ErrorString* errorString, const ScriptId& scriptId, const int* executionContextId, const String* const objectGroup, const bool* const doNotPauseOnExceptionsAndMuteConsole, RefPtr<RemoteObject>& result, RefPtr<ExceptionDetails>& exceptionDetails)
{
    InjectedScript injectedScript = injectedScriptForEval(errorString, executionContextId);
    if (injectedScript.isEmpty()) {
        *errorString = "Inspected frame has gone";
        return;
    }

    ScriptDebugServer::PauseOnExceptionsState previousPauseOnExceptionsState = scriptDebugServer().pauseOnExceptionsState();
    if (asBool(doNotPauseOnExceptionsAndMuteConsole)) {
        if (previousPauseOnExceptionsState != ScriptDebugServer::DontPauseOnExceptions)
            scriptDebugServer().setPauseOnExceptionsState(ScriptDebugServer::DontPauseOnExceptions);
        muteConsole();
    }

    ScriptValue value;
    bool wasThrownValue;
    String exceptionDetailsText;
    int lineNumberValue = 0;
    int columnNumberValue = 0;
    RefPtr<ScriptCallStack> stackTraceValue;
    scriptDebugServer().runScript(injectedScript.scriptState(), scriptId, &value, &wasThrownValue, &exceptionDetailsText, &lineNumberValue, &columnNumberValue, &stackTraceValue);
    if (value.isEmpty()) {
        *errorString = "Script execution failed";
        return;
    }
    result = injectedScript.wrapObject(value, objectGroup ? *objectGroup : "");
    if (wasThrownValue) {
        exceptionDetails = ExceptionDetails::create().setText(exceptionDetailsText);
        exceptionDetails->setLine(lineNumberValue);
        exceptionDetails->setColumn(columnNumberValue);
        if (stackTraceValue && stackTraceValue->size() > 0)
            exceptionDetails->setStackTrace(stackTraceValue->buildInspectorArray());
    }

    if (asBool(doNotPauseOnExceptionsAndMuteConsole)) {
        unmuteConsole();
        if (scriptDebugServer().pauseOnExceptionsState() != previousPauseOnExceptionsState)
            scriptDebugServer().setPauseOnExceptionsState(previousPauseOnExceptionsState);
    }
}

void InspectorDebuggerAgent::setOverlayMessage(ErrorString*, const String*)
{
}

void InspectorDebuggerAgent::setVariableValue(ErrorString* errorString, int scopeNumber, const String& variableName, const RefPtr<JSONObject>& newValue, const String* callFrameId, const String* functionObjectId)
{
    InjectedScript injectedScript;
    if (callFrameId) {
        if (!isPaused() || m_currentCallStack.isEmpty()) {
            *errorString = "Attempt to access callframe when debugger is not on pause";
            return;
        }
        injectedScript = m_injectedScriptManager->injectedScriptForObjectId(*callFrameId);
        if (injectedScript.isEmpty()) {
            *errorString = "Inspected frame has gone";
            return;
        }
    } else if (functionObjectId) {
        injectedScript = m_injectedScriptManager->injectedScriptForObjectId(*functionObjectId);
        if (injectedScript.isEmpty()) {
            *errorString = "Function object id cannot be resolved";
            return;
        }
    } else {
        *errorString = "Either call frame or function object must be specified";
        return;
    }
    String newValueString = newValue->toJSONString();

    injectedScript.setVariableValue(errorString, m_currentCallStack, callFrameId, functionObjectId, scopeNumber, variableName, newValueString);
}

void InspectorDebuggerAgent::skipStackFrames(ErrorString* errorString, const String* pattern)
{
    OwnPtr<ScriptRegexp> compiled;
    String patternValue = pattern ? *pattern : "";
    if (!patternValue.isEmpty()) {
        compiled = compileSkipCallFramePattern(patternValue);
        if (!compiled) {
            *errorString = "Invalid regular expression";
            return;
        }
    }
    m_state->setString(DebuggerAgentState::skipStackPattern, patternValue);
    m_cachedSkipStackRegExp = compiled.release();
}

void InspectorDebuggerAgent::setAsyncCallStackDepth(ErrorString*, int depth)
{
    m_state->setLong(DebuggerAgentState::asyncCallStackDepth, depth);
    asyncCallStackTracker().setAsyncCallStackDepth(depth);
}

void InspectorDebuggerAgent::scriptExecutionBlockedByCSP(const String& directiveText)
{
    if (scriptDebugServer().pauseOnExceptionsState() != ScriptDebugServer::DontPauseOnExceptions) {
        RefPtr<JSONObject> directive = JSONObject::create();
        directive->setString("directiveText", directiveText);
        breakProgram(InspectorFrontend::Debugger::Reason::CSPViolation, directive.release());
    }
}

PassRefPtr<Array<CallFrame> > InspectorDebuggerAgent::currentCallFrames()
{
    if (!m_pausedScriptState || m_currentCallStack.isEmpty())
        return Array<CallFrame>::create();
    InjectedScript injectedScript = m_injectedScriptManager->injectedScriptFor(m_pausedScriptState.get());
    if (injectedScript.isEmpty()) {
        ASSERT_NOT_REACHED();
        return Array<CallFrame>::create();
    }
    return injectedScript.wrapCallFrames(m_currentCallStack, 0);
}

PassRefPtr<StackTrace> InspectorDebuggerAgent::currentAsyncStackTrace()
{
    if (!m_pausedScriptState || !asyncCallStackTracker().isEnabled())
        return nullptr;
    const AsyncCallStackTracker::AsyncCallChain* chain = asyncCallStackTracker().currentAsyncCallChain();
    if (!chain)
        return nullptr;
    const AsyncCallStackTracker::AsyncCallStackVector& callStacks = chain->callStacks();
    if (callStacks.isEmpty())
        return nullptr;
    RefPtr<StackTrace> result;
    int asyncOrdinal = callStacks.size();
    for (AsyncCallStackTracker::AsyncCallStackVector::const_reverse_iterator it = callStacks.rbegin(); it != callStacks.rend(); ++it, --asyncOrdinal) {
        ScriptValue callFrames = (*it)->callFrames();
        ScriptState* scriptState = callFrames.scriptState();
        InjectedScript injectedScript = scriptState ? m_injectedScriptManager->injectedScriptFor(scriptState) : InjectedScript();
        if (injectedScript.isEmpty()) {
            result.clear();
            continue;
        }
        RefPtr<StackTrace> next = StackTrace::create()
            .setCallFrames(injectedScript.wrapCallFrames(callFrames, asyncOrdinal))
            .release();
        next->setDescription((*it)->description());
        if (result)
            next->setAsyncStackTrace(result.release());
        result.swap(next);
    }
    return result.release();
}

static PassRefPtr<ScriptCallStack> toScriptCallStack(JavaScriptCallFrame* callFrame)
{
    Vector<ScriptCallFrame> frames;
    for (; callFrame; callFrame = callFrame->caller()) {
        StringBuilder stringBuilder;
        stringBuilder.appendNumber(callFrame->sourceID());
        String scriptId = stringBuilder.toString();
        // FIXME(WK62725): Debugger line/column are 0-based, while console ones are 1-based.
        int line = callFrame->line() + 1;
        int column = callFrame->column() + 1;
        frames.append(ScriptCallFrame(callFrame->functionName(), scriptId, callFrame->scriptName(), line, column));
    }
    return ScriptCallStack::create(frames);
}

PassRefPtr<ScriptAsyncCallStack> InspectorDebuggerAgent::currentAsyncStackTraceForConsole()
{
    if (!asyncCallStackTracker().isEnabled())
        return nullptr;
    const AsyncCallStackTracker::AsyncCallChain* chain = asyncCallStackTracker().currentAsyncCallChain();
    if (!chain)
        return nullptr;
    const AsyncCallStackTracker::AsyncCallStackVector& callStacks = chain->callStacks();
    if (callStacks.isEmpty())
        return nullptr;
    RefPtr<ScriptAsyncCallStack> result = nullptr;
    for (AsyncCallStackTracker::AsyncCallStackVector::const_reverse_iterator it = callStacks.rbegin(); it != callStacks.rend(); ++it) {
        RefPtr<JavaScriptCallFrame> callFrame = ScriptDebugServer::toJavaScriptCallFrameUnsafe((*it)->callFrames());
        if (!callFrame)
            break;
        result = ScriptAsyncCallStack::create((*it)->description(), toScriptCallStack(callFrame.get()), result.release());
    }
    return result.release();
}

String InspectorDebuggerAgent::sourceMapURLForScript(const Script& script, CompileResult compileResult)
{
    bool hasSyntaxError = compileResult != CompileSuccess;
    if (hasSyntaxError) {
        bool deprecated;
        String sourceMapURL = ContentSearchUtils::findSourceMapURL(script.source, ContentSearchUtils::JavaScriptMagicComment, &deprecated);
        if (!sourceMapURL.isEmpty())
            return sourceMapURL;
    }

    if (!script.sourceMappingURL.isEmpty())
        return script.sourceMappingURL;

    return String();
    // FIXME(sky): Fetch from page agent.
}

// ScriptDebugListener functions

void InspectorDebuggerAgent::didParseSource(const String& scriptId, const Script& parsedScript, CompileResult compileResult)
{
    Script script = parsedScript;
    const bool* isContentScript = script.isContentScript ? &script.isContentScript : 0;

    bool hasSyntaxError = compileResult != CompileSuccess;
    if (!script.startLine && !script.startColumn) {
        if (hasSyntaxError) {
            bool deprecated;
            script.sourceURL = ContentSearchUtils::findSourceURL(script.source, ContentSearchUtils::JavaScriptMagicComment, &deprecated);
        }
    } else {
        script.sourceURL = String();
    }

    bool hasSourceURL = !script.sourceURL.isEmpty();
    String scriptURL = hasSourceURL ? script.sourceURL : script.url;

    String sourceMapURL = sourceMapURLForScript(script, compileResult);
    String* sourceMapURLParam = sourceMapURL.isNull() ? 0 : &sourceMapURL;

    bool* hasSourceURLParam = hasSourceURL ? &hasSourceURL : 0;
    if (!hasSyntaxError)
        m_frontend->scriptParsed(scriptId, scriptURL, script.startLine, script.startColumn, script.endLine, script.endColumn, isContentScript, sourceMapURLParam, hasSourceURLParam);
    else
        m_frontend->scriptFailedToParse(scriptId, scriptURL, script.startLine, script.startColumn, script.endLine, script.endColumn, isContentScript, sourceMapURLParam, hasSourceURLParam);

    m_scripts.set(scriptId, script);

    if (scriptURL.isEmpty() || hasSyntaxError)
        return;

    RefPtr<JSONObject> breakpointsCookie = m_state->getObject(DebuggerAgentState::javaScriptBreakpoints);
    for (JSONObject::iterator it = breakpointsCookie->begin(); it != breakpointsCookie->end(); ++it) {
        RefPtr<JSONObject> breakpointObject = it->value->asObject();
        bool isAntibreakpoint;
        breakpointObject->getBoolean(DebuggerAgentState::isAnti, &isAntibreakpoint);
        if (isAntibreakpoint)
            continue;
        bool isRegex;
        breakpointObject->getBoolean(DebuggerAgentState::isRegex, &isRegex);
        String url;
        breakpointObject->getString(DebuggerAgentState::url, &url);
        if (!matches(scriptURL, url, isRegex))
            continue;
        ScriptBreakpoint breakpoint;
        breakpointObject->getNumber(DebuggerAgentState::lineNumber, &breakpoint.lineNumber);
        breakpointObject->getNumber(DebuggerAgentState::columnNumber, &breakpoint.columnNumber);
        breakpointObject->getString(DebuggerAgentState::condition, &breakpoint.condition);
        RefPtr<TypeBuilder::Debugger::Location> location = resolveBreakpoint(it->key, scriptId, breakpoint, UserBreakpointSource);
        if (location)
            m_frontend->breakpointResolved(it->key, location);
    }
}

// FIXME(sky): This is a hack to make the debugger not break in the js inspector
// so it works even while v8 is paused. crbug.com/434510
bool InspectorDebuggerAgent::shouldSkipInspectorInternals()
{
    RefPtr<JavaScriptCallFrame> topFrame = topCallFrameSkipUnknownSources();
    if (!topFrame)
        return false;

    KURL url = KURL(ParsedURLString, scriptURL(topFrame.get()));
    return url.path().startsWith("/sky/framework")
        || url.path().startsWith("/sky/services")
        || url.path().startsWith("/mojo");
}

ScriptDebugListener::SkipPauseRequest InspectorDebuggerAgent::didPause(ScriptState* scriptState, const ScriptValue& callFrames, const ScriptValue& exception, const Vector<String>& hitBreakpoints)
{
    ScriptDebugListener::SkipPauseRequest result;
    if (callFrames.isEmpty() || shouldSkipInspectorInternals())
        result = ScriptDebugListener::Continue; // Skip pauses inside V8 internal scripts and on syntax errors.
    else if (m_javaScriptPauseScheduled)
        result = ScriptDebugListener::NoSkip; // Don't skip explicit pause requests from front-end.
    else if (m_skipAllPauses)
        result = ScriptDebugListener::Continue;
    else if (!hitBreakpoints.isEmpty())
        result = ScriptDebugListener::NoSkip; // Don't skip explicit breakpoints even if set in frameworks.
    else if (!exception.isEmpty())
        result = shouldSkipExceptionPause();
    else if (m_debuggerStepScheduled || m_pausingOnNativeEvent)
        result = shouldSkipStepPause();
    else
        result = ScriptDebugListener::NoSkip;

    if (result != ScriptDebugListener::NoSkip)
        return result;

    ASSERT(scriptState && !m_pausedScriptState);
    m_pausedScriptState = scriptState;
    m_currentCallStack = callFrames;

    if (!exception.isEmpty()) {
        InjectedScript injectedScript = m_injectedScriptManager->injectedScriptFor(scriptState);
        if (!injectedScript.isEmpty()) {
            m_breakReason = InspectorFrontend::Debugger::Reason::Exception;
            m_breakAuxData = injectedScript.wrapObject(exception, InspectorDebuggerAgent::backtraceObjectGroup)->openAccessors();
            // m_breakAuxData might be null after this.
        }
    }

    RefPtr<Array<String> > hitBreakpointIds = Array<String>::create();

    for (Vector<String>::const_iterator i = hitBreakpoints.begin(); i != hitBreakpoints.end(); ++i) {
        DebugServerBreakpointToBreakpointIdAndSourceMap::iterator breakpointIterator = m_serverBreakpoints.find(*i);
        if (breakpointIterator != m_serverBreakpoints.end()) {
            const String& localId = breakpointIterator->value.first;
            hitBreakpointIds->addItem(localId);

            BreakpointSource source = breakpointIterator->value.second;
            if (m_breakReason == InspectorFrontend::Debugger::Reason::Other && source == DebugCommandBreakpointSource)
                m_breakReason = InspectorFrontend::Debugger::Reason::DebugCommand;
        }
    }

    m_frontend->paused(currentCallFrames(), m_breakReason, m_breakAuxData, hitBreakpointIds, currentAsyncStackTrace());
    m_javaScriptPauseScheduled = false;
    m_debuggerStepScheduled = false;
    m_steppingFromFramework = false;
    m_pausingOnNativeEvent = false;
    m_skippedStepInCount = 0;

    if (!m_continueToLocationBreakpointId.isEmpty()) {
        scriptDebugServer().removeBreakpoint(m_continueToLocationBreakpointId);
        m_continueToLocationBreakpointId = "";
    }
    if (m_listener)
        m_listener->didPause();
    return result;
}

void InspectorDebuggerAgent::didContinue()
{
    m_pausedScriptState = nullptr;
    m_currentCallStack = ScriptValue();
    clearBreakDetails();
    m_frontend->resumed();
}

bool InspectorDebuggerAgent::canBreakProgram()
{
    return scriptDebugServer().canBreakProgram();
}

void InspectorDebuggerAgent::breakProgram(InspectorFrontend::Debugger::Reason::Enum breakReason, PassRefPtr<JSONObject> data)
{
    if (m_skipAllPauses)
        return;
    m_breakReason = breakReason;
    m_breakAuxData = data;
    m_debuggerStepScheduled = false;
    m_steppingFromFramework = false;
    m_pausingOnNativeEvent = false;
    scriptDebugServer().breakProgram();
}

void InspectorDebuggerAgent::clear()
{
    m_pausedScriptState = nullptr;
    m_currentCallStack = ScriptValue();
    m_scripts.clear();
    m_breakpointIdToDebugServerBreakpointIds.clear();
    asyncCallStackTracker().clear();
    m_promiseTracker.clear();
    m_continueToLocationBreakpointId = String();
    clearBreakDetails();
    m_javaScriptPauseScheduled = false;
    m_debuggerStepScheduled = false;
    m_steppingFromFramework = false;
    m_pausingOnNativeEvent = false;
    ErrorString error;
    setOverlayMessage(&error, 0);
}

bool InspectorDebuggerAgent::assertPaused(ErrorString* errorString)
{
    if (!m_pausedScriptState) {
        *errorString = "Can only perform operation while paused.";
        return false;
    }
    return true;
}

void InspectorDebuggerAgent::clearBreakDetails()
{
    m_breakReason = InspectorFrontend::Debugger::Reason::Other;
    m_breakAuxData = nullptr;
}

void InspectorDebuggerAgent::setBreakpoint(const String& scriptId, int lineNumber, int columnNumber, BreakpointSource source, const String& condition)
{
    String breakpointId = generateBreakpointId(scriptId, lineNumber, columnNumber, source);
    ScriptBreakpoint breakpoint(lineNumber, columnNumber, condition);
    resolveBreakpoint(breakpointId, scriptId, breakpoint, source);
}

void InspectorDebuggerAgent::removeBreakpoint(const String& scriptId, int lineNumber, int columnNumber, BreakpointSource source)
{
    removeBreakpoint(generateBreakpointId(scriptId, lineNumber, columnNumber, source));
}

void InspectorDebuggerAgent::reset()
{
    m_scripts.clear();
    m_breakpointIdToDebugServerBreakpointIds.clear();
    asyncCallStackTracker().clear();
    m_promiseTracker.clear();
    if (m_frontend)
        m_frontend->globalObjectCleared();
}

} // namespace blink

