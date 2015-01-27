/*
 * Copyright (C) 2010 Apple Inc. All rights reserved.
 * Copyright (C) 2014 Google Inc. All rights reserved.
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
#include "bindings/core/dart/DartInspectorDebuggerAgent.h"

#include "bindings/common/ScriptValue.h"
#include "bindings/core/dart/DartInjectedScriptManager.h"
#include "bindings/core/dart/DartScriptDebugServer.h"
#include "bindings/core/v8/ScriptDebugServer.h"
#include "bindings/core/v8/ScriptRegexp.h"
#include "bindings/core/v8/ScriptSourceCode.h"
#include "core/dom/Document.h"
#include "core/dom/ExecutionContextTask.h"
#include "core/fetch/Resource.h"
#include "core/inspector/ContentSearchUtils.h"
#include "core/inspector/InspectorDebuggerAgent.h"
#include "core/inspector/InspectorPageAgent.h"
#include "core/inspector/InspectorState.h"
#include "core/inspector/InstrumentingAgents.h"
#include "core/inspector/JavaScriptCallFrame.h"
#include "core/inspector/ScriptArguments.h"
#include "core/inspector/ScriptCallFrame.h"
#include "core/inspector/ScriptCallStack.h"
#include "platform/JSONValues.h"
#include "wtf/text/StringBuilder.h"
#include "wtf/text/WTFString.h"

using blink::TypeBuilder::Array;
using blink::TypeBuilder::Debugger::BreakpointId;
using blink::TypeBuilder::Debugger::CallFrame;
using blink::TypeBuilder::Debugger::ExceptionDetails;
using blink::TypeBuilder::Debugger::FunctionDetails;
using blink::TypeBuilder::Debugger::ScriptId;
using blink::TypeBuilder::Debugger::StackTrace;
using blink::TypeBuilder::Runtime::RemoteObject;


namespace blink {

namespace DartDebuggerAgentState {
static const char debuggerEnabled[] = "debuggerEnabledDart";
static const char dartBreakpoints[] = "dartBreakpoints";
static const char pauseOnExceptionsState[] = "dartPauseOnExceptionsState";
static const char asyncCallStackDepth[] = "dartAsyncCallStackDepth";

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

static const int maxSkipStepInCountDart = 20;

const char DartInspectorDebuggerAgent::backtraceObjectGroup[] = "backtrace";

static String breakpointIdSuffixDart(DartInspectorDebuggerAgent::BreakpointSource source)
{
    switch (source) {
    case DartInspectorDebuggerAgent::UserBreakpointSource:
        break;
    case DartInspectorDebuggerAgent::DebugCommandBreakpointSource:
        return ":debug";
    case DartInspectorDebuggerAgent::MonitorCommandBreakpointSource:
        return ":monitor";
    }
    return String();
}

static String generateBreakpointIdDart(const String& scriptId, int lineNumber, int columnNumber, DartInspectorDebuggerAgent::BreakpointSource source)
{
    return scriptId + ':' + String::number(lineNumber) + ':' + String::number(columnNumber) + breakpointIdSuffixDart(source);
}

DartInspectorDebuggerAgent::DartInspectorDebuggerAgent(DartInjectedScriptManager* injectedScriptManager, InspectorDebuggerAgent* inspectorDebuggerAgent, InspectorPageAgent* pageAgent)
    : m_injectedScriptManager(injectedScriptManager)
    , m_frontend(0)
    , m_pausedScriptState(nullptr)
    , m_currentCallStack(0)
    , m_javaScriptPauseScheduled(false)
    , m_debuggerStepScheduled(false)
    , m_steppingFromFramework(false)
    , m_pausingOnNativeEvent(false)
    , m_listener(nullptr)
    , m_skippedStepInCount(0)
    , m_skipAllPauses(false)
    , m_inspectorDebuggerAgent(inspectorDebuggerAgent)
    , m_pageAgent(pageAgent)
{
}

DartInspectorDebuggerAgent::~DartInspectorDebuggerAgent()
{
}

InspectorState* DartInspectorDebuggerAgent::state()
{
    return m_inspectorDebuggerAgent->m_state.get();
}

void DartInspectorDebuggerAgent::init()
{
    // FIXME: make breakReason optional so that there was no need to init it with "other".
    clearBreakDetails();
    state()->setLong(DartDebuggerAgentState::pauseOnExceptionsState, ScriptDebugServer::DontPauseOnExceptions);
}

void DartInspectorDebuggerAgent::enable()
{
    startListeningScriptDebugServer();
    // FIXME(WK44513): breakpoints activated flag should be synchronized between all front-ends
    scriptDebugServer().setBreakpointsActivated(true);

    if (m_listener)
        m_listener->debuggerWasEnabled();
}

void DartInspectorDebuggerAgent::disable()
{
    state()->setObject(DartDebuggerAgentState::dartBreakpoints, JSONObject::create());
    state()->setLong(DartDebuggerAgentState::pauseOnExceptionsState, ScriptDebugServer::DontPauseOnExceptions);
    state()->setString(DartDebuggerAgentState::skipStackPattern, "");
    state()->setLong(DartDebuggerAgentState::asyncCallStackDepth, 0);

    scriptDebugServer().clearBreakpoints();
    stopListeningScriptDebugServer();
    clear();

    if (m_listener)
        m_listener->debuggerWasDisabled();

    m_skipAllPauses = false;
}

bool DartInspectorDebuggerAgent::enabled()
{
    return state()->getBoolean(DartDebuggerAgentState::debuggerEnabled);
}

void DartInspectorDebuggerAgent::enable(ErrorString*)
{
    if (enabled())
        return;

    enable();
    state()->setBoolean(DartDebuggerAgentState::debuggerEnabled, true);

    ASSERT(m_frontend);
}

void DartInspectorDebuggerAgent::disable(ErrorString*)
{
    if (!enabled())
        return;

    disable();
    state()->setBoolean(DartDebuggerAgentState::debuggerEnabled, false);
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

void DartInspectorDebuggerAgent::restore()
{
    if (enabled()) {
        m_frontend->globalObjectCleared();
        enable();
        long pauseState = state()->getLong(DartDebuggerAgentState::pauseOnExceptionsState);
        String error;
        setPauseOnExceptionsImpl(&error, pauseState);
        m_cachedSkipStackRegExp = compileSkipCallFramePattern(state()->getString(DartDebuggerAgentState::skipStackPattern));
        m_skipAllPauses = state()->getBoolean(DartDebuggerAgentState::skipAllPauses);
        if (m_skipAllPauses && state()->getBoolean(DartDebuggerAgentState::skipAllPausesExpiresOnReload)) {
            m_skipAllPauses = false;
            state()->setBoolean(DartDebuggerAgentState::skipAllPauses, false);
        }
    }
}

void DartInspectorDebuggerAgent::setFrontend(InspectorFrontend* frontend)
{
    m_frontend = frontend->debugger();
}

void DartInspectorDebuggerAgent::clearFrontend()
{
    m_frontend = 0;

    if (!enabled())
        return;

    disable();

    // FIXME: due to state()->mute() hack in InspectorController, debuggerEnabled is actually set to false only
    // in InspectorState, but not in cookie. That's why after navigation debuggerEnabled will be true,
    // but after front-end re-open it will still be false.
    state()->setBoolean(DartDebuggerAgentState::debuggerEnabled, false);
}

void DartInspectorDebuggerAgent::setBreakpointsActive(ErrorString*, bool active)
{
    scriptDebugServer().setBreakpointsActivated(active);
}

void DartInspectorDebuggerAgent::setSkipAllPauses(ErrorString*, bool skipped, const bool* untilReload)
{
    m_skipAllPauses = skipped;
    state()->setBoolean(DartDebuggerAgentState::skipAllPauses, m_skipAllPauses);
    state()->setBoolean(DartDebuggerAgentState::skipAllPausesExpiresOnReload, asBool(untilReload));
}

void DartInspectorDebuggerAgent::pageDidCommitLoad()
{
    if (state()->getBoolean(DartDebuggerAgentState::skipAllPausesExpiresOnReload)) {
        m_skipAllPauses = false;
        state()->setBoolean(DartDebuggerAgentState::skipAllPauses, m_skipAllPauses);
    }
}

bool DartInspectorDebuggerAgent::isPaused()
{
    return scriptDebugServer().isPaused();
}

bool DartInspectorDebuggerAgent::runningNestedMessageLoop()
{
    return scriptDebugServer().runningNestedMessageLoop();
}

static PassRefPtr<JSONObject> buildObjectForBreakpointCookie(const String& url, int lineNumber, int columnNumber, const String& condition, bool isRegex, bool isAnti)
{
    RefPtr<JSONObject> breakpointObject = JSONObject::create();
    breakpointObject->setString(DartDebuggerAgentState::url, url);
    breakpointObject->setNumber(DartDebuggerAgentState::lineNumber, lineNumber);
    breakpointObject->setNumber(DartDebuggerAgentState::columnNumber, columnNumber);
    breakpointObject->setString(DartDebuggerAgentState::condition, condition);
    breakpointObject->setBoolean(DartDebuggerAgentState::isRegex, isRegex);
    breakpointObject->setBoolean(DartDebuggerAgentState::isAnti, isAnti);
    return breakpointObject;
}

static String scriptSourceURL(const DartScriptDebugListener::Script& script)
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

void DartInspectorDebuggerAgent::setBreakpointByUrl(ErrorString* errorString, int lineNumber, const String* const optionalURL, const String* const optionalURLRegex, const int* const optionalColumnNumber, const String* const optionalCondition, const bool* isAntiBreakpoint, BreakpointId* outBreakpointId, RefPtr<Array<TypeBuilder::Debugger::Location> >& locations)
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
    RefPtr<JSONObject> breakpointsCookie = state()->getObject(DartDebuggerAgentState::dartBreakpoints);
    if (breakpointsCookie->find(breakpointId) != breakpointsCookie->end()) {
        *errorString = "Breakpoint at specified location already exists.";
        return;
    }

    breakpointsCookie->setObject(breakpointId, buildObjectForBreakpointCookie(url, lineNumber, columnNumber, condition, isRegex, isAntiBreakpointValue));
    state()->setObject(DartDebuggerAgentState::dartBreakpoints, breakpointsCookie);

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

void DartInspectorDebuggerAgent::setBreakpoint(ErrorString* errorString, const RefPtr<JSONObject>& location, const String* const optionalCondition, BreakpointId* outBreakpointId, RefPtr<TypeBuilder::Debugger::Location>& actualLocation)
{
    String scriptId;
    int lineNumber;
    int columnNumber;

    if (!parseLocation(errorString, location, &scriptId, &lineNumber, &columnNumber))
        return;

    String condition = optionalCondition ? *optionalCondition : emptyString();

    String breakpointId = generateBreakpointIdDart(scriptId, lineNumber, columnNumber, UserBreakpointSource);
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

void DartInspectorDebuggerAgent::removeBreakpoint(ErrorString*, const String& breakpointId)
{
    RefPtr<JSONObject> breakpointsCookie = state()->getObject(DartDebuggerAgentState::dartBreakpoints);
    JSONObject::iterator it = breakpointsCookie->find(breakpointId);
    bool isAntibreakpoint = false;
    if (it != breakpointsCookie->end()) {
        RefPtr<JSONObject> breakpointObject = it->value->asObject();
        breakpointObject->getBoolean(DartDebuggerAgentState::isAnti, &isAntibreakpoint);
        breakpointsCookie->remove(breakpointId);
        state()->setObject(DartDebuggerAgentState::dartBreakpoints, breakpointsCookie);
    }

    if (!isAntibreakpoint)
        removeBreakpoint(breakpointId);
}

void DartInspectorDebuggerAgent::removeBreakpoint(const String& breakpointId)
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

void DartInspectorDebuggerAgent::continueToLocation(ErrorString* errorString, const RefPtr<JSONObject>& location, const bool* interstateLocationOpt)
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

void DartInspectorDebuggerAgent::getBacktrace(ErrorString* errorString, RefPtr<Array<CallFrame> >& callFrames, WTF::RefPtr<blink::TypeBuilder::Debugger::StackTrace>& asyncStackTrace)
{
    if (!assertPaused(errorString))
        return;
    m_currentCallStack = scriptDebugServer().currentCallFrames();
    callFrames = currentCallFrames();
}

ScriptCallFrame DartInspectorDebuggerAgent::topCallFrameSkipUnknownSources()
{
    for (int index = 0; ; ++index) {
        ScriptCallFrame frame = scriptDebugServer().callFrameNoScopes(index);
        if (frame.isEmpty())
            return ScriptCallFrame();
        // FIXMEDART: is this the correct scriptId?
        if (m_scripts.contains(frame.scriptId()))
            return frame;
    }
}

DartScriptDebugListener::SkipPauseRequest DartInspectorDebuggerAgent::shouldSkipExceptionPause()
{
    if (m_steppingFromFramework)
        return DartScriptDebugListener::NoSkip;

    // FIXME: Fast return: if (!m_cachedSkipStackRegExp && !has_any_anti_breakpoint) return DartScriptDebugListener::NoSkip;

    const ScriptCallFrame& topFrame = topCallFrameSkipUnknownSources();
    if (topFrame.isEmpty())
        return DartScriptDebugListener::NoSkip;

    String topFrameScriptUrl = topFrame.sourceURL();
    if (m_cachedSkipStackRegExp && !topFrameScriptUrl.isEmpty() && m_cachedSkipStackRegExp->match(topFrameScriptUrl) != -1)
        return DartScriptDebugListener::Continue;

    // Match against breakpoints.
    if (topFrameScriptUrl.isEmpty())
        return DartScriptDebugListener::NoSkip;

    // Prepare top frame parameters.
    int topFrameLineNumber = topFrame.lineNumber();
    int topFrameColumnNumber = topFrame.columnNumber();

    RefPtr<JSONObject> breakpointsCookie = state()->getObject(DartDebuggerAgentState::dartBreakpoints);
    for (JSONObject::iterator it = breakpointsCookie->begin(); it != breakpointsCookie->end(); ++it) {
        RefPtr<JSONObject> breakpointObject = it->value->asObject();
        bool isAntibreakpoint;
        breakpointObject->getBoolean(DartDebuggerAgentState::isAnti, &isAntibreakpoint);
        if (!isAntibreakpoint)
            continue;

        int breakLineNumber;
        breakpointObject->getNumber(DartDebuggerAgentState::lineNumber, &breakLineNumber);
        int breakColumnNumber;
        breakpointObject->getNumber(DartDebuggerAgentState::columnNumber, &breakColumnNumber);

        if (breakLineNumber != topFrameLineNumber)
            continue;

        if (breakColumnNumber != -1 && breakColumnNumber != topFrameColumnNumber)
            continue;

        bool isRegex;
        breakpointObject->getBoolean(DartDebuggerAgentState::isRegex, &isRegex);
        String url;
        breakpointObject->getString(DartDebuggerAgentState::url, &url);
        if (!matches(topFrameScriptUrl, url, isRegex))
            continue;

        return DartScriptDebugListener::Continue;
    }

    return DartScriptDebugListener::NoSkip;
}

DartScriptDebugListener::SkipPauseRequest DartInspectorDebuggerAgent::shouldSkipStepPause()
{
    if (!m_cachedSkipStackRegExp || m_steppingFromFramework)
        return DartScriptDebugListener::NoSkip;

    ScriptCallFrame topFrame = topCallFrameSkipUnknownSources();
    String scriptUrl = topFrame.sourceURL();
    if (scriptUrl.isEmpty() || m_cachedSkipStackRegExp->match(scriptUrl) == -1)
        return DartScriptDebugListener::NoSkip;

    if (m_skippedStepInCount == 0) {
        m_minFrameCountForSkip = scriptDebugServer().frameCount();
        m_skippedStepInCount = 1;
        return DartScriptDebugListener::StepInto;
    }

    if (m_skippedStepInCount < maxSkipStepInCountDart && scriptDebugServer().frameCount() <= m_minFrameCountForSkip)
        m_skippedStepInCount = maxSkipStepInCountDart;

    if (m_skippedStepInCount >= maxSkipStepInCountDart) {
        if (m_pausingOnNativeEvent) {
            m_pausingOnNativeEvent = false;
            m_skippedStepInCount = 0;
            return DartScriptDebugListener::Continue;
        }
        return DartScriptDebugListener::StepOut;
    }

    ++m_skippedStepInCount;
    return DartScriptDebugListener::StepInto;
}

bool DartInspectorDebuggerAgent::isTopCallFrameInFramework()
{
    if (!m_cachedSkipStackRegExp)
        return false;

    ScriptCallFrame topFrame = topCallFrameSkipUnknownSources();
    if (topFrame.isEmpty())
        return false;

    String scriptUrl = topFrame.sourceURL();
    return !scriptUrl.isEmpty() && m_cachedSkipStackRegExp->match(scriptUrl) != -1;
}

bool DartInspectorDebuggerAgent::isDartScriptId(const String& scriptId)
{
    ScriptsMap::iterator scriptIterator = m_scripts.find(scriptId);
    return scriptIterator != m_scripts.end();
}

bool DartInspectorDebuggerAgent::isDartURL(const String* const optionalURL, const String* const optionalURLRegex)
{
    return (optionalURL && (optionalURL->endsWith(".dart", false) || optionalURL->startsWith("dart:"))) || (optionalURLRegex && (optionalURLRegex->endsWith(".dart", false) || optionalURLRegex->startsWith("dart:")));
}

PassRefPtr<TypeBuilder::Debugger::Location> DartInspectorDebuggerAgent::resolveBreakpoint(const String& breakpointId, const String& scriptId, const ScriptBreakpoint& breakpoint, BreakpointSource source)
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

void DartInspectorDebuggerAgent::searchInContent(ErrorString* error, const String& scriptId, const String& query, const bool* const optionalCaseSensitive, const bool* const optionalIsRegex, RefPtr<Array<blink::TypeBuilder::Page::SearchMatch> >& results)
{
    ScriptsMap::iterator it = m_scripts.find(scriptId);
    if (it != m_scripts.end())
        results = ContentSearchUtils::searchInTextByLines(it->value.source, query, asBool(optionalCaseSensitive), asBool(optionalIsRegex));
    else
        *error = "No script for id: " + scriptId;
}

void DartInspectorDebuggerAgent::getScriptSource(ErrorString* error, const String& scriptId, String* scriptSource)
{
    ScriptsMap::iterator it = m_scripts.find(scriptId);
    if (it == m_scripts.end()) {
        *error = "No script for id: " + scriptId;
        return;
    }

    String url = it->value.url;
    if (!url.isEmpty()) {
        if (m_pageAgent) {
            bool success = m_pageAgent->getEditedResourceContent(url, scriptSource);
            if (success)
                return;
        }
    }
    *scriptSource = it->value.source;
}

void DartInspectorDebuggerAgent::getFunctionDetails(ErrorString* errorString, const String& functionId, RefPtr<FunctionDetails>& details)
{
    DartInjectedScript* injectedScript = m_injectedScriptManager->injectedScriptForObjectId(functionId);
    if (!injectedScript) {
        *errorString = "Function object id is obsolete";
        return;
    }
    injectedScript->getFunctionDetails(errorString, functionId, &details);
}

void DartInspectorDebuggerAgent::schedulePauseOnNextStatement(InspectorFrontend::Debugger::Reason::Enum breakReason, PassRefPtr<JSONObject> data)
{
    if (m_javaScriptPauseScheduled || isPaused())
        return;
    m_breakReason = breakReason;
    m_breakAuxData = data;
    m_pausingOnNativeEvent = true;
    scriptDebugServer().setPauseOnNextStatement(true);
}

void DartInspectorDebuggerAgent::cancelPauseOnNextStatement()
{
    if (m_javaScriptPauseScheduled || isPaused())
        return;
    clearBreakDetails();
    m_pausingOnNativeEvent = false;
    scriptDebugServer().setPauseOnNextStatement(false);
}

void DartInspectorDebuggerAgent::pause(ErrorString*)
{
    if (m_javaScriptPauseScheduled || isPaused())
        return;
    clearBreakDetails();
    m_javaScriptPauseScheduled = true;
    scriptDebugServer().setPauseOnNextStatement(true);
}

void DartInspectorDebuggerAgent::resume(ErrorString* errorString)
{
    if (!assertPaused(errorString))
        return;
    m_debuggerStepScheduled = false;
    m_steppingFromFramework = false;
    m_injectedScriptManager->releaseObjectGroup(DartInspectorDebuggerAgent::backtraceObjectGroup);
    scriptDebugServer().continueProgram();
}

void DartInspectorDebuggerAgent::stepOver(ErrorString* errorString)
{
    if (!assertPaused(errorString))
        return;
    m_debuggerStepScheduled = true;
    m_steppingFromFramework = isTopCallFrameInFramework();
    m_injectedScriptManager->releaseObjectGroup(DartInspectorDebuggerAgent::backtraceObjectGroup);
    scriptDebugServer().stepOverStatement();
}

void DartInspectorDebuggerAgent::stepInto(ErrorString* errorString)
{
    if (!assertPaused(errorString))
        return;
    m_debuggerStepScheduled = true;
    m_steppingFromFramework = isTopCallFrameInFramework();
    m_injectedScriptManager->releaseObjectGroup(DartInspectorDebuggerAgent::backtraceObjectGroup);
    scriptDebugServer().stepIntoStatement();
    if (m_listener)
        m_listener->stepInto();
}

void DartInspectorDebuggerAgent::stepOut(ErrorString* errorString)
{
    if (!assertPaused(errorString))
        return;
    m_debuggerStepScheduled = true;
    m_steppingFromFramework = isTopCallFrameInFramework();
    m_injectedScriptManager->releaseObjectGroup(DartInspectorDebuggerAgent::backtraceObjectGroup);
    scriptDebugServer().stepOutOfFunction();
}

void DartInspectorDebuggerAgent::setPauseOnExceptions(ErrorString* errorString, const String& stringPauseState)
{
    ScriptDebugServer::PauseOnExceptionsState pauseState;
    if (stringPauseState == "none") {
        pauseState = ScriptDebugServer::DontPauseOnExceptions;
    } else if (stringPauseState == "all") {
        pauseState = ScriptDebugServer::PauseOnAllExceptions;
    } else if (stringPauseState == "uncaught") {
        pauseState = ScriptDebugServer::PauseOnUncaughtExceptions;
    } else {
        *errorString = "Unknown pause on exceptions mode: " + stringPauseState;
        return;
    }
    setPauseOnExceptionsImpl(errorString, pauseState);
}

void DartInspectorDebuggerAgent::setPauseOnExceptionsImpl(ErrorString* errorString, int pauseState)
{
    scriptDebugServer().setPauseOnExceptionsState(static_cast<ScriptDebugServer::PauseOnExceptionsState>(pauseState));
    if (scriptDebugServer().pauseOnExceptionsState() != pauseState)
        *errorString = "Internal error. Could not change pause on exceptions state";
    else
        state()->setLong(DartDebuggerAgentState::pauseOnExceptionsState, pauseState);
}

void DartInspectorDebuggerAgent::evaluateOnCallFrame(ErrorString* errorString, const String& callFrameId, const String& expression, const String* const objectGroup, const bool* const includeCommandLineAPI, const bool* const doNotPauseOnExceptionsAndMuteConsole, const bool* const returnByValue, const bool* generatePreview, RefPtr<RemoteObject>& result, TypeBuilder::OptOutput<bool>* wasThrown, RefPtr<TypeBuilder::Debugger::ExceptionDetails>& exceptionDetails)
{
    if (!isPaused() || !m_currentCallStack) {
        *errorString = "Attempt to access callframe when debugger is not on pause";
        return;
    }
    DartInjectedScript* injectedScript = m_injectedScriptManager->injectedScriptForObjectId(callFrameId);
    if (!injectedScript) {
        *errorString = "Inspected frame has gone";
        return;
    }

    ScriptDebugServer::PauseOnExceptionsState previousPauseOnExceptionsState = scriptDebugServer().pauseOnExceptionsState();
    if (asBool(doNotPauseOnExceptionsAndMuteConsole)) {
        if (previousPauseOnExceptionsState != ScriptDebugServer::DontPauseOnExceptions)
            scriptDebugServer().setPauseOnExceptionsState(ScriptDebugServer::DontPauseOnExceptions);
        muteConsole();
    }

    injectedScript->evaluateOnCallFrame(errorString, m_currentCallStack, callFrameId, expression, objectGroup ? *objectGroup : "", asBool(includeCommandLineAPI), asBool(returnByValue), asBool(generatePreview), &result, wasThrown, &exceptionDetails);
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

void DartInspectorDebuggerAgent::getCompletionsOnCallFrame(ErrorString* errorString, const String& callFrameId, const String& expression, RefPtr<TypeBuilder::Array<String> >& result)
{
    if (!isPaused() || !m_currentCallStack) {
        *errorString = "Attempt to access callframe when debugger is not on pause";
        return;
    }
    DartInjectedScript* injectedScript = m_injectedScriptManager->injectedScriptForObjectId(callFrameId);
    if (!injectedScript) {
        *errorString = "Inspected frame has gone";
        return;
    }

    ScriptDebugServer::PauseOnExceptionsState previousPauseOnExceptionsState = scriptDebugServer().pauseOnExceptionsState();
    if (previousPauseOnExceptionsState != ScriptDebugServer::DontPauseOnExceptions)
        scriptDebugServer().setPauseOnExceptionsState(ScriptDebugServer::DontPauseOnExceptions);
    muteConsole();

    injectedScript->getCompletionsOnCallFrame(errorString, m_currentCallStack, callFrameId, expression, &result);

    unmuteConsole();
    if (scriptDebugServer().pauseOnExceptionsState() != previousPauseOnExceptionsState)
        scriptDebugServer().setPauseOnExceptionsState(previousPauseOnExceptionsState);
}

void DartInspectorDebuggerAgent::setOverlayMessage(ErrorString*, const String*)
{
}

void DartInspectorDebuggerAgent::setVariableValue(ErrorString* errorString, int scopeNumber, const String& variableName, const RefPtr<JSONObject>& newValue, const String* callFrameId, const String* functionObjectId)
{
    DartInjectedScript* injectedScript = 0;
    if (callFrameId) {
        if (!isPaused() || !m_currentCallStack) {
            *errorString = "Attempt to access callframe when debugger is not on pause";
            return;
        }
        injectedScript = m_injectedScriptManager->injectedScriptForObjectId(*callFrameId);
        if (injectedScript->isEmpty()) {
            *errorString = "Inspected frame has gone";
            return;
        }
    } else if (functionObjectId) {
        injectedScript = m_injectedScriptManager->injectedScriptForObjectId(*functionObjectId);
        if (injectedScript->isEmpty()) {
            *errorString = "Function object id cannot be resolved";
            return;
        }
    } else {
        *errorString = "Either call frame or function object must be specified";
        return;
    }
    String newValueString = newValue->toJSONString();
    ASSERT(injectedScript);
    injectedScript->setVariableValue(errorString, m_currentCallStack, callFrameId, functionObjectId, scopeNumber, variableName, newValueString);
}

void DartInspectorDebuggerAgent::skipStackFrames(ErrorString* errorString, const String* pattern)
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
    state()->setString(DartDebuggerAgentState::skipStackPattern, patternValue);
    m_cachedSkipStackRegExp = compiled.release();
}

void DartInspectorDebuggerAgent::scriptExecutionBlockedByCSP(const String& directiveText)
{
    if (scriptDebugServer().pauseOnExceptionsState() != ScriptDebugServer::DontPauseOnExceptions) {
        RefPtr<JSONObject> directive = JSONObject::create();
        directive->setString("directiveText", directiveText);
        breakProgram(InspectorFrontend::Debugger::Reason::CSPViolation, directive.release());
    }
}

PassRefPtr<Array<CallFrame> > DartInspectorDebuggerAgent::currentCallFrames()
{
    if (!m_pausedScriptState || !m_currentCallStack)
        return Array<TypeBuilder::Debugger::CallFrame>::create();
    DartInjectedScript* injectedScript = m_injectedScriptManager->injectedScriptFor(m_pausedScriptState.get());
    if (!injectedScript) {
        ASSERT_NOT_REACHED();
        return Array<CallFrame>::create();
    }
    return injectedScript->wrapCallFrames(m_currentCallStack, 0);
}

String DartInspectorDebuggerAgent::sourceMapURLForScript(const Script& script, CompileResult compileResult)
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

    if (script.url.isEmpty())
        return String();

    if (!m_pageAgent)
        return String();
    return m_pageAgent->resourceSourceMapURL(script.url);
}

// DartScriptDebugListener functions

void DartInspectorDebuggerAgent::didParseSource(const String& scriptId, const Script& parsedScript, CompileResult compileResult)
{
    Script script = parsedScript;
    const bool* isContentScript = script.isContentScript ? &script.isContentScript : 0;

    const String* languageParam = script.language.isNull() ? 0 : &(script.language);
    const int* libraryIdParam = script.libraryId < 0 ? 0 : &(script.libraryId);
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
        m_frontend->scriptParsed(scriptId, scriptURL, script.startLine, script.startColumn, script.endLine, script.endColumn, isContentScript, sourceMapURLParam, hasSourceURLParam, languageParam, libraryIdParam);
    else
        m_frontend->scriptFailedToParse(scriptId, scriptURL, script.startLine, script.startColumn, script.endLine, script.endColumn, isContentScript, sourceMapURLParam, hasSourceURLParam, languageParam, libraryIdParam);

    m_scripts.set(scriptId, script);

    if (scriptURL.isEmpty() || hasSyntaxError)
        return;

    RefPtr<JSONObject> breakpointsCookie = state()->getObject(DartDebuggerAgentState::dartBreakpoints);
    for (JSONObject::iterator it = breakpointsCookie->begin(); it != breakpointsCookie->end(); ++it) {
        RefPtr<JSONObject> breakpointObject = it->value->asObject();
        bool isAntibreakpoint;
        breakpointObject->getBoolean(DartDebuggerAgentState::isAnti, &isAntibreakpoint);
        if (isAntibreakpoint)
            continue;
        bool isRegex;
        breakpointObject->getBoolean(DartDebuggerAgentState::isRegex, &isRegex);
        String url;
        breakpointObject->getString(DartDebuggerAgentState::url, &url);
        if (!matches(scriptURL, url, isRegex))
            continue;
        ScriptBreakpoint breakpoint;
        breakpointObject->getNumber(DartDebuggerAgentState::lineNumber, &breakpoint.lineNumber);
        breakpointObject->getNumber(DartDebuggerAgentState::columnNumber, &breakpoint.columnNumber);
        breakpointObject->getString(DartDebuggerAgentState::condition, &breakpoint.condition);
        RefPtr<TypeBuilder::Debugger::Location> location = resolveBreakpoint(it->key, scriptId, breakpoint, UserBreakpointSource);
        if (location)
            m_frontend->breakpointResolved(it->key, location);
    }
}

DartScriptDebugListener::SkipPauseRequest DartInspectorDebuggerAgent::didPause(ScriptState* scriptState, Dart_StackTrace callFrames, const ScriptValue& exception, const Vector<String>& hitBreakpoints)
{
    DartScriptDebugListener::SkipPauseRequest result;
    if (!callFrames)
        result = DartScriptDebugListener::Continue; // Skip pauses inside V8 internal scripts and on syntax errors.
    else if (m_javaScriptPauseScheduled)
        result = DartScriptDebugListener::NoSkip; // Don't skip explicit pause requests from front-end.
    else if (m_skipAllPauses)
        result = DartScriptDebugListener::Continue;
    else if (!hitBreakpoints.isEmpty())
        result = DartScriptDebugListener::NoSkip; // Don't skip explicit breakpoints even if set in frameworks.
    else if (!exception.isEmpty())
        result = shouldSkipExceptionPause();
    else if (m_debuggerStepScheduled || m_pausingOnNativeEvent)
        result = shouldSkipStepPause();
    else
        result = DartScriptDebugListener::NoSkip;

    if (result != DartScriptDebugListener::NoSkip)
        return result;

    ASSERT(scriptState && !m_pausedScriptState);
    m_pausedScriptState = scriptState;
    m_currentCallStack = callFrames;

    if (!exception.isEmpty()) {
        DartInjectedScript* injectedScript = m_injectedScriptManager->injectedScriptFor(scriptState);
        if (injectedScript) {
            m_breakReason = InspectorFrontend::Debugger::Reason::Exception;
            m_breakAuxData = injectedScript->wrapObject(exception, DartInspectorDebuggerAgent::backtraceObjectGroup)->openAccessors();
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

    m_frontend->paused(currentCallFrames(), m_breakReason, m_breakAuxData, hitBreakpointIds, nullptr);
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

void DartInspectorDebuggerAgent::didContinue()
{
    m_pausedScriptState = nullptr;
    m_currentCallStack = 0;
    clearBreakDetails();
    // Already called by InspectorDebuggerAgent?
    m_frontend->resumed();
}

bool DartInspectorDebuggerAgent::canBreakProgram()
{
    return scriptDebugServer().canBreakProgram();
}

void DartInspectorDebuggerAgent::breakProgram(InspectorFrontend::Debugger::Reason::Enum breakReason, PassRefPtr<JSONObject> data)
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

void DartInspectorDebuggerAgent::clear()
{
    m_pausedScriptState = nullptr;
    m_currentCallStack = 0;
    m_scripts.clear();
    m_breakpointIdToDebugServerBreakpointIds.clear();
    m_continueToLocationBreakpointId = String();
    clearBreakDetails();
    m_javaScriptPauseScheduled = false;
    m_debuggerStepScheduled = false;
    m_steppingFromFramework = false;
    m_pausingOnNativeEvent = false;
    ErrorString error;
    setOverlayMessage(&error, 0);
}

bool DartInspectorDebuggerAgent::assertPaused(ErrorString* errorString)
{
    if (!m_pausedScriptState) {
        *errorString = "Can only perform operation while paused.";
        return false;
    }
    return true;
}

void DartInspectorDebuggerAgent::clearBreakDetails()
{
    m_breakReason = InspectorFrontend::Debugger::Reason::Other;
    m_breakAuxData = nullptr;
}

void DartInspectorDebuggerAgent::setBreakpoint(const String& scriptId, int lineNumber, int columnNumber, BreakpointSource source, const String& condition)
{
    String breakpointId = generateBreakpointIdDart(scriptId, lineNumber, columnNumber, source);
    ScriptBreakpoint breakpoint(lineNumber, columnNumber, condition);
    resolveBreakpoint(breakpointId, scriptId, breakpoint, source);
}

void DartInspectorDebuggerAgent::removeBreakpoint(const String& scriptId, int lineNumber, int columnNumber, BreakpointSource source)
{
    removeBreakpoint(generateBreakpointIdDart(scriptId, lineNumber, columnNumber, source));
}

void DartInspectorDebuggerAgent::reset()
{
    m_scripts.clear();
    m_breakpointIdToDebugServerBreakpointIds.clear();
}

DartScriptDebugServer& DartInspectorDebuggerAgent::scriptDebugServer()
{
    return DartScriptDebugServer::shared();
}

} // namespace blink

