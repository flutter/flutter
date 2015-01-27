/*
 * Copyright (C) 2014 Google Inc. All rights reserved.
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
#include "bindings/core/dart/DartScriptDebugServer.h"

#include "bindings/core/dart/DartController.h"
#include "bindings/core/dart/DartScriptDebugListener.h"
#include "bindings/core/dart/DartUtilities.h"
#include "bindings/core/dart/V8Converter.h"
#include "bindings/core/v8/PageScriptDebugServer.h"
#include "bindings/core/v8/ScriptController.h"
#include "bindings/core/v8/V8Binding.h"
#include "bindings/core/v8/V8ScriptState.h"
#include "bindings/core/v8/WindowProxy.h"
#include "core/dom/Document.h"
#include "core/frame/LocalDOMWindow.h"
#include "core/inspector/InspectorController.h"
#include "core/inspector/InspectorDebuggerAgent.h"
#include "core/inspector/InspectorInstrumentation.h"
#include "core/inspector/InstrumentingAgents.h"
#include "core/inspector/JSONParser.h"
#include "core/page/Page.h"
#include "platform/JSONValues.h"
#include "platform/Logging.h"
#include "wtf/HashMap.h"
#include "wtf/MessageQueue.h"
#include "wtf/ThreadingPrimitives.h"
#include "wtf/Vector.h"

namespace blink {

void drainTaskQueue(MessageQueue<ScriptDebugServer::Task>& tasks)
{
    OwnPtr<ScriptDebugServer::Task> currentMessage;
    while ((currentMessage = tasks.tryGetMessage()))
        currentMessage->run();
}

// Wrapper to let the V8 code to handle debug messages stay unchanged for now.
class DrainQueueTask : public ScriptDebugServer::Task {
public:
    DrainQueueTask(MessageQueue<ScriptDebugServer::Task>* tasks) : m_tasks(tasks) { }
    virtual void run()
    {
        drainTaskQueue(*m_tasks);
    }
private:
    MessageQueue<ScriptDebugServer::Task>* m_tasks;
};

// Thread-safe helper class to track all current isolates.
class ThreadSafeIsolateTracker {
    WTF_MAKE_NONCOPYABLE(ThreadSafeIsolateTracker);
public:
    ThreadSafeIsolateTracker() { }

    void add(Dart_Isolate isolate)
    {
        MutexLocker locker(m_mutex);
        m_isolates.add(isolate);
    }

    void remove(Dart_Isolate isolate)
    {
        MutexLocker locker(m_mutex);
        m_isolates.remove(isolate);
    }

    Vector<Dart_Isolate> isolates()
    {
        MutexLocker locker(m_mutex);
        Vector<Dart_Isolate> result;
        copyToVector(m_isolates, result);
        return result;
    }

private:
    Mutex m_mutex;
    HashSet<Dart_Isolate> m_isolates;
};

// Thread safe method to get a list of all running isolates.
static ThreadSafeIsolateTracker& threadSafeIsolateTracker()
{
    AtomicallyInitializedStatic(ThreadSafeIsolateTracker&, tracker = *new ThreadSafeIsolateTracker);
    return tracker;
}

static MessageQueue<ScriptDebugServer::Task>& debugTaskQueue()
{
    AtomicallyInitializedStatic(MessageQueue<ScriptDebugServer::Task>&, tasks = *new MessageQueue<ScriptDebugServer::Task>);
    return tasks;
}

static Dart_ExceptionPauseInfo calculatePauseInfo(ScriptDebugServer::PauseOnExceptionsState pauseOnExceptionState)
{
    switch (pauseOnExceptionState) {
    case ScriptDebugServer::DontPauseOnExceptions:
        return kNoPauseOnExceptions;
    case ScriptDebugServer::PauseOnAllExceptions:
        return kPauseOnAllExceptions;
    case ScriptDebugServer::PauseOnUncaughtExceptions:
        return kPauseOnUnhandledExceptions;
    }
    return kNoPauseOnExceptions;
}

DartBreakpoint::DartBreakpoint(intptr_t breakpointId, Dart_Isolate isolate)
    : m_breakpointId(breakpointId)
    , m_isolate(isolate)
{
}

DartBreakpointInfo::DartBreakpointInfo(const String& scriptUrl, const ScriptBreakpoint& scriptBreakpoint)
    : m_scriptUrl(scriptUrl)
    , m_scriptBreakpoint(scriptBreakpoint)
{
}

DartPageDebug::DartPageDebug(Page* page, int pageId)
    : m_page(page)
    , m_listener(0)
    , m_pageId(pageId)
    , m_nextBreakpointId(1)
    , m_nextScriptId(1)
{
}

DartPageDebug::~DartPageDebug()
{
    for (BreakpointMap::iterator it = m_breakpoints.begin(); it != m_breakpoints.end(); ++it)
        delete it->value;
}

void DartPageDebug::registerIsolate(Dart_Isolate isolate)
{
    m_isolateMap.add(isolate);
}

intptr_t DartPageDebug::setBreakpointHelper(DartBreakpointInfo* breakpointInfo, const String& breakpointIdString, Dart_Isolate isolate, Dart_Handle& exception)
{
    Dart_Handle scriptURL = DartUtilities::convertSourceString(breakpointInfo->m_scriptUrl);
    // FIXME: use scriptBreakpoint.columnNumber and ScriptBreakpoint.condition as well.
    Dart_Handle ret = Dart_SetBreakpoint(scriptURL, breakpointInfo->m_scriptBreakpoint.lineNumber + 1);
    if (Dart_IsError(ret)) {
        exception = ret;
        return ILLEGAL_BREAKPOINT_ID;
    }
    ASSERT(Dart_IsInteger(ret));
    intptr_t breakpointId = DartUtilities::dartToInt(ret, exception);
    ASSERT(!exception);
    if (exception) {
        return ILLEGAL_BREAKPOINT_ID;
    }
    m_breakpointIdMap.set(breakpointId, breakpointIdString);
    breakpointInfo->m_breakpoints.append(DartBreakpoint(breakpointId, isolate));
    return breakpointId;
}

String DartPageDebug::setBreakpoint(const String& sourceID, const ScriptBreakpoint& scriptBreakpoint, int* actualLineNumber, int* actualColumnNumber, bool interstatementLocation)
{
    String breakpointIdString = String::format("{\"dartBreakpoint\":%d,\"page\":%d}", m_nextBreakpointId, m_pageId);
    *actualLineNumber = scriptBreakpoint.lineNumber;
    *actualColumnNumber = scriptBreakpoint.columnNumber;
    m_nextBreakpointId++;
    if (!m_idToScriptUrlMap.contains(sourceID)) {
        return "Unable to set breakpoint. Unknown sourceID";
    }
    Vector<Dart_Isolate> isolates;
    m_isolateMap.copyValues(isolates);
    for (Vector<Dart_Isolate>::iterator it = isolates.begin(); it != isolates.end(); ++it) {
        Dart_Isolate isolate = *it;
        DartIsolateScope scope(isolate);
        DartApiScope apiScope;
        Dart_Handle exception = 0;

        DartBreakpointInfo* breakpointInfo;
        BreakpointMap::iterator breakpointIt = m_breakpoints.find(breakpointIdString);
        if (breakpointIt != m_breakpoints.end()) {
            breakpointInfo = breakpointIt->value;
        } else {
            breakpointInfo = new DartBreakpointInfo(m_idToScriptUrlMap.get(sourceID), scriptBreakpoint);
            m_breakpoints.set(breakpointIdString, breakpointInfo);
        }

        intptr_t breakpointId = setBreakpointHelper(breakpointInfo, breakpointIdString, isolate, exception);
        if (exception)
            continue;

        if (breakpointId != ILLEGAL_BREAKPOINT_ID) {
            Dart_Handle breakpointLine = Dart_GetBreakpointLine(breakpointId);
            if (!Dart_IsError(breakpointLine)) {
                ASSERT(Dart_IsInteger(breakpointLine));
                *actualLineNumber = DartUtilities::dartToInt(breakpointLine, exception) - 1;
                ASSERT(!exception);
            }
        }
    }
    return breakpointIdString;
}


void DartPageDebug::removeBreakpointHelper(DartBreakpointInfo* breakpointInfo)
{
    Vector<DartBreakpoint>& breakpoints = breakpointInfo->m_breakpoints;
    for (Vector<DartBreakpoint>::iterator it = breakpoints.begin(); it != breakpoints.end(); ++it) {
        DartBreakpoint& breakpoint = *it;
        DartIsolateScope scope(breakpoint.m_isolate);
        DartApiScope apiScope;
        // perhaps this isn't needed if the isolate will be removed soon anyway.
        Dart_Handle ALLOW_UNUSED ret = Dart_RemoveBreakpoint(breakpoint.m_breakpointId);
        ASSERT(Dart_IsBoolean(ret));
        Dart_Handle ALLOW_UNUSED exception = 0;
        ASSERT(DartUtilities::dartToBool(ret, exception));
        ASSERT(!exception);
    }
    delete breakpointInfo;
}

void DartPageDebug::removeBreakpoint(const String& breakpointId)
{
    if (m_breakpoints.contains(breakpointId)) {
        removeBreakpointHelper(m_breakpoints.get(breakpointId));
        m_breakpoints.remove(breakpointId);
    }
}

void DartPageDebug::clearBreakpointsForIsolate(Dart_Isolate isolate)
{
    // Warning: this code is O(num_isolates * num_breakpoints)
    for (BreakpointMap::iterator i = m_breakpoints.begin(); i != m_breakpoints.end(); ++i) {
        Vector<DartBreakpoint>& breakpoints = i->value->m_breakpoints;
        for (size_t j = 0; j < breakpoints.size(); j++) {
            DartBreakpoint& breakpoint = breakpoints[j];
            if (breakpoint.m_isolate == isolate) {
                // No need to actually call Dart_RemoveBreakpoint as the
                // isolate is about to be shut down.
                breakpoints.remove(j);
                break;
            }
        }
    }
}

void DartPageDebug::dispatchDidParseSource(intptr_t libraryId, Dart_Handle scriptURL, Dart_Isolate isolate)
{
    ASSERT(Dart_IsString(scriptURL));
    DartScriptDebugListener::Script script;
    script.url = DartUtilities::toString(scriptURL);
    String sourceID = getScriptId(script.url);
    Dart_Handle scriptSource = Dart_ScriptGetSource(libraryId, scriptURL);
    if (Dart_IsString(scriptSource)) {
        script.source = DartUtilities::toString(scriptSource);
    } else {
        // FIXME: this is a bit ugly.
        script.source = "ERROR: unable to get source";
    }
    // FIXME: track script.sourceMappingURL for dart-dart source map support.

    Dart_Handle info = Dart_ScriptGetTokenInfo(libraryId, scriptURL);
    ASSERT(Dart_IsList(info));
    intptr_t infoLength = 0;
    Dart_Handle ALLOW_UNUSED result = Dart_ListLength(info, &infoLength);
    ASSERT(!Dart_IsError(result));
    Dart_Handle elem;
    int lastLineNumber = 0;
    int lastColumnNumber = 0;
    intptr_t lastLineStart = 0;
    for (intptr_t i = infoLength - 3; i >= 0; i--) {
        elem = Dart_ListGetAt(info, i);
        if (Dart_IsNull(elem)) {
            lastLineStart = i;
            break;
        }
    }
    Dart_Handle exception = 0;
    lastLineNumber = DartUtilities::toInteger(Dart_ListGetAt(info, lastLineStart + 1), exception);
    ASSERT(!exception);
    lastColumnNumber = DartUtilities::toInteger(Dart_ListGetAt(info, infoLength - 1), exception);
    ASSERT(!exception);

    script.startLine = 0;
    script.startColumn = 0;
    script.endLine = lastLineNumber + 1;
    script.endColumn = !lastLineNumber ? lastColumnNumber : 0;
    script.isContentScript = false;
    script.language = String("Dart");
    script.libraryId = libraryId;
    m_listener->didParseSource(sourceID, script, CompileResult::CompileSuccess);
}

String DartPageDebug::getScriptId(const String& url)
{
    HashMap<String, String>::iterator it = m_scriptUrlToIdMap.find(url);
    if (it == m_scriptUrlToIdMap.end()) {
        String id = String::format("{\"dartScript\":%d,\"page\":%d}", m_nextScriptId, m_pageId);
        m_nextScriptId++;
        m_scriptUrlToIdMap.set(url, id);
        m_idToScriptUrlMap.set(id, url);
        return id;
    }
    return it->value;
}

void DartPageDebug::clearBreakpoints()
{
    for (BreakpointMap::iterator i = m_breakpoints.begin(); i != m_breakpoints.end(); ++i)
        removeBreakpointHelper(i->value);
    m_breakpoints.clear();
    m_breakpointIdMap.clear();
}

void DartPageDebug::registerIsolateScripts(Dart_Isolate isolate)
{
    Dart_Handle libraries = Dart_GetLibraryIds();
    ASSERT(Dart_IsList(libraries));

    intptr_t librariesLength = 0;
    Dart_Handle ALLOW_UNUSED result = Dart_ListLength(libraries, &librariesLength);
    ASSERT(!Dart_IsError(result));
    for (intptr_t i = 0; i < librariesLength; ++i) {
        Dart_Handle libraryIdHandle = Dart_ListGetAt(libraries, i);
        ASSERT(!Dart_IsError(libraryIdHandle));
        Dart_Handle exception = 0;
        int64_t int64LibraryId = DartUtilities::toInteger(libraryIdHandle, exception);
        ASSERT(!exception);
        intptr_t libraryId = static_cast<intptr_t>(int64LibraryId);
        ASSERT(libraryId == int64LibraryId);

        Dart_Handle libraryURL = Dart_GetLibraryURL(libraryId);
        ASSERT(Dart_IsString(libraryURL));

        // FIXMEDART: we may be doing this more than once per library.
        Dart_SetLibraryDebuggable(libraryId, true);

        Dart_Handle scripts = Dart_GetScriptURLs(libraryURL);
        ASSERT(Dart_IsList(scripts));

        intptr_t scriptsLength = 0;
        result = Dart_ListLength(scripts, &scriptsLength);
        ASSERT(!Dart_IsError(result));
        for (intptr_t j = 0; j < scriptsLength; ++j) {
            Dart_Handle scriptURL = Dart_ListGetAt(scripts, j);
            dispatchDidParseSource(libraryId, scriptURL, isolate);
        }
    }
}

Vector<Dart_Isolate> DartPageDebug::isolates()
{
    Vector<Dart_Isolate> result;
    m_isolateMap.copyValues(result);
    return result;
}

void DartPageDebug::addListener(DartScriptDebugListener* listener)
{
    ASSERT(!m_listener);
    m_listener = listener;

    Vector<Dart_Isolate> iter = isolates();
    for (Vector<Dart_Isolate>::iterator i = iter.begin(); i != iter.end(); ++i) {
        Dart_Isolate isolate = *i;
        DartIsolateScope scope(isolate);
        DartApiScope apiScope;
        isolateLoaded();
    }
}

void DartPageDebug::removeListener()
{
    m_listener = 0;
    Vector<Dart_Isolate> iter = isolates();
    for (Vector<Dart_Isolate>::iterator i = iter.begin(); i != iter.end(); ++i) {
        Dart_Isolate isolate = *i;
        DartIsolateScope scope(isolate);
        DartApiScope apiScope;
        Dart_SetPausedEventHandler(0);
        Dart_SetExceptionThrownHandler(0);
        Dart_SetIsolateEventHandler(0);
        Dart_SetExceptionPauseInfo(kNoPauseOnExceptions);
    }
    // FIXME: Remove all breakpoints set by the agent. JavaScript does not
    // remove the breakpoints either.
}

void DartPageDebug::unregisterIsolate(Dart_Isolate isolate)
{
    clearBreakpointsForIsolate(isolate);
    m_isolateMap.removeByValue(isolate);
}

void DartPageDebug::isolateLoaded()
{
    if (!m_listener)
        return;

    Dart_Isolate isolate = Dart_CurrentIsolate();
    Dart_SetPausedEventHandler(DartScriptDebugServer::pausedEventHandler);
    Dart_SetExceptionThrownHandler(DartScriptDebugServer::exceptionHandler);
    Dart_SetIsolateEventHandler(DartScriptDebugServer::isolateEventHandler);

    Dart_ExceptionPauseInfo pauseInfo = calculatePauseInfo(
        DartScriptDebugServer::shared().pauseOnExceptionState());
    Dart_SetExceptionPauseInfo(pauseInfo);

    ASSERT(isolate);

    V8Scope v8Scope(DartDOMData::current());

    LocalFrame* frame = DartUtilities::domWindowForCurrentIsolate()->frame();
    DartController* controller = DartController::retrieve(frame);
    Vector<DartScriptState*> scriptStates;
    controller->collectScriptStatesForIsolate(isolate, DartUtilities::currentV8Context(), scriptStates);
    for (size_t i = 0; i< scriptStates.size(); i++)
        InspectorInstrumentation::didCreateIsolatedContext(frame, scriptStates[i], 0);

    registerIsolateScripts(isolate);

    for (BreakpointMap::iterator it = m_breakpoints.begin(); it != m_breakpoints.end(); ++it) {
        Dart_Handle ALLOW_UNUSED exception = 0;
        setBreakpointHelper(it->value, it->key, isolate, exception);
    }
}

String DartPageDebug::lookupBreakpointId(intptr_t dartBreakpointId)
{
    if (dartBreakpointId != ILLEGAL_BREAKPOINT_ID) {
        BreakpointIdMap::iterator it = m_breakpointIdMap.find(dartBreakpointId);
        if (it != m_breakpointIdMap.end())
            return it->value;
    }
    return "";
}

DartScriptDebugServer::DartScriptDebugServer()
    : m_pauseOnExceptionState(ScriptDebugServer::DontPauseOnExceptions)
    , m_breakpointsActivated(true)
    , m_runningNestedMessageLoop(false)
    , m_executionState(0)
    , m_pausedIsolate(0)
    , m_pausedPage(0)
    , m_clientMessageLoop(0)
    , m_nextPageId(1)
{
}

DartScriptDebugServer::~DartScriptDebugServer()
{
    for (DebugDataMap::iterator it = m_pageIdToDebugDataMap.begin(); it != m_pageIdToDebugDataMap.end(); ++it)
        delete it->value;
}

DartPageDebug* DartScriptDebugServer::lookupPageDebugForId(const String& id)
{
    RefPtr<JSONValue> json = parseJSON(id);
    ASSERT(json && json->type() == JSONValue::TypeObject);
    if (json && json->type() == JSONValue::TypeObject) {
        size_t pageId;
        bool success = json->asObject()->getNumber("page", &pageId);
        ASSERT(success);
        if (success)
            return m_pageIdToDebugDataMap.get(pageId);
    }
    return 0;
}

DartPageDebug* DartScriptDebugServer::lookupPageDebug(Page* page)
{
    ASSERT(page);
    PageToIdMap::iterator it = m_pageToIdMap.find(page);
    if (it != m_pageToIdMap.end())
        return m_pageIdToDebugDataMap.get(it->value);

    size_t pageId = m_nextPageId++;
    m_pageToIdMap.set(page, pageId);
    DartPageDebug* pageDebug = new DartPageDebug(page, pageId);
    m_pageIdToDebugDataMap.set(pageId, pageDebug);
    return pageDebug;
}

void DartScriptDebugServer::clearWindowShell(Page* page)
{
    // FIXME: find a cleaner long term solution than just ignoring
    // clearWindowShell requests where we were unable to determine the Page
    // likely because the Page is already being destroyed. One strategy would
    // be to switch all references to Page to reference LocalFrame.
    if (!page)
        return;
    PageToIdMap::iterator it = m_pageToIdMap.find(page);
    if (it != m_pageToIdMap.end()) {
        size_t pageId = it->value;
        DartPageDebug* pageDebug = m_pageIdToDebugDataMap.get(pageId);
        // Only clear the page if all isolates on the page have shutdown.
        if (pageDebug->isolates().isEmpty()) {
            pageDebug->clearBreakpoints();
        }
    }
}

String DartScriptDebugServer::getScriptId(const String& url, Dart_Isolate isolate)
{
    // FIXME: this is a ugly. It would be better to get the domData for the
    // specified isolate.
    ASSERT(isolate == Dart_CurrentIsolate());
    DartPageDebug* pageDebug = lookupPageDebug(DartUtilities::domWindowForCurrentIsolate()->document()->page());
    ASSERT(pageDebug);
    if (!pageDebug)
        return "";
    return pageDebug->getScriptId(url);
}

void DartScriptDebugServer::registerIsolate(Dart_Isolate isolate, Page* page)
{
    threadSafeIsolateTracker().add(isolate);

    DartIsolateScope scope(isolate);
    DartApiScope apiScope;

    DartPageDebug* pageDebug = lookupPageDebug(page);
    pageDebug->registerIsolate(isolate);

}

// FIXMEDART: we aren't really handling adding and removing breakpoints
// as new isolates add/remove themselves.
String DartScriptDebugServer::setBreakpoint(const String& sourceID, const ScriptBreakpoint& scriptBreakpoint, int* actualLineNumber, int* actualColumnNumber, bool interstatementLocation)
{
    DartPageDebug* pageDebug = lookupPageDebugForId(sourceID);
    ASSERT(pageDebug);
    if (!pageDebug)
        return "";
    return pageDebug->setBreakpoint(sourceID, scriptBreakpoint, actualLineNumber, actualColumnNumber, interstatementLocation);
}

void DartScriptDebugServer::removeBreakpoint(const String& breakpointId)
{
    DartPageDebug* pageDebug = lookupPageDebugForId(breakpointId);
    if (pageDebug) {
        pageDebug->removeBreakpoint(breakpointId);
    }
}

void DartScriptDebugServer::clearBreakpoints()
{
    Vector<DartPageDebug*> list = pages();
    for (Vector<DartPageDebug*>::iterator it = list.begin(); it != list.end(); ++it)
        (*it)->clearBreakpoints();
}

void DartScriptDebugServer::setBreakpointsActivated(bool activated)
{
    m_breakpointsActivated = activated;
}

ScriptDebugServer::PauseOnExceptionsState DartScriptDebugServer::pauseOnExceptionsState()
{
    return m_pauseOnExceptionState;
}

void DartScriptDebugServer::setPauseOnExceptionsState(ScriptDebugServer::PauseOnExceptionsState pauseOnExceptionState)
{
    if (m_pauseOnExceptionState == pauseOnExceptionState)
        return;
    m_pauseOnExceptionState = pauseOnExceptionState;

    Dart_ExceptionPauseInfo pauseInfo = calculatePauseInfo(pauseOnExceptionState);

    Vector<Dart_Isolate> iter = isolates();
    for (Vector<Dart_Isolate>::iterator it = iter.begin(); it != iter.end(); ++it) {
        DartIsolateScope scope(*it);
        DartApiScope apiScope;
        Dart_SetExceptionPauseInfo(pauseInfo);
    }
}

void DartScriptDebugServer::setPauseOnNextStatement(bool pause)
{
    if (isPaused())
        return;
    if (pause) {
        debugBreak();
    } else {
        cancelDebugBreak();
    }
}

bool DartScriptDebugServer::canBreakProgram()
{
    if (!m_breakpointsActivated)
        return false;

    // FIXME: what is the dart equivalent of
    // v8::HandleScope scope(m_isolate);
    // return !m_isolate->GetCurrentContext().IsEmpty();
    // ?
    return true;
}

void DartScriptDebugServer::breakProgram()
{
    if (!canBreakProgram())
        return;

    // FIXME: determine if this method needs to be implemented for Dart.
}

void DartScriptDebugServer::continueProgram()
{
    if (isPaused())
        quitMessageLoopOnPause();
    m_executionState = 0;
    m_pausedIsolate = 0;
}

void DartScriptDebugServer::stepIntoStatement()
{
    ASSERT(isPaused());
    Dart_SetStepInto();
    continueProgram();
}

void DartScriptDebugServer::stepOverStatement()
{
    ASSERT(isPaused());
    Dart_SetStepOver();
    continueProgram();
}

void DartScriptDebugServer::stepOutOfFunction()
{
    ASSERT(isPaused());
    Dart_SetStepOut();
    continueProgram();
}

bool DartScriptDebugServer::setScriptSource(const String& sourceID, const String& newContent, bool preview, String* error, RefPtr<TypeBuilder::Debugger::SetScriptSourceError>& errorData, Dart_StackTrace newCallFrames, RefPtr<JSONObject>* result)
{
    *error = "Dart does not support live editing source code yet.";
    return false;
}

bool DartScriptDebugServer::executeSkipPauseRequest(DartScriptDebugListener::SkipPauseRequest request, Dart_StackTrace stackTrace)
{
    switch (request) {
    case DartScriptDebugListener::NoSkip:
        return false;
    case DartScriptDebugListener::Continue:
        return true;
    case DartScriptDebugListener::StepInto:
    case DartScriptDebugListener::StepOut:
        break;
    }
    ASSERT(0);
    // FIXMEDART: actually do something jacobr JACOBR
    return true;
}

int DartScriptDebugServer::frameCount()
{
    ASSERT(isPaused());
    intptr_t length = 0;
    Dart_StackTraceLength(m_executionState, &length);
    return length;
}

Dart_StackTrace DartScriptDebugServer::currentCallFrames()
{
    return m_executionState;
}

ScriptCallFrame DartScriptDebugServer::callFrameNoScopes(int index)
{
    if (!isPaused())
        return ScriptCallFrame();
    DartIsolateScope scope(m_pausedIsolate);
    DartApiScope apiScope;
    return getScriptCallFrameHelper(index);
}

bool DartScriptDebugServer::isPaused()
{
    return !!m_executionState;
}

DartScriptDebugServer& DartScriptDebugServer::shared()
{
    DEFINE_STATIC_LOCAL(DartScriptDebugServer, server, ());
    return server;
}

void DartScriptDebugServer::addListener(DartScriptDebugListener* listener, Page* page)
{
    ScriptController& scriptController = page->deprecatedLocalMainFrame()->script();
    if (!scriptController.canExecuteScripts(NotAboutToExecuteScript))
        return;

    DartPageDebug* pageDebug = lookupPageDebug(page);
    pageDebug->addListener(listener);
}

Vector<DartPageDebug*> DartScriptDebugServer::pages()
{
    Vector<DartPageDebug*> result;
    copyValuesToVector(m_pageIdToDebugDataMap, result);
    return result;
}

Vector<Dart_Isolate> DartScriptDebugServer::isolates()
{
    Vector<Dart_Isolate> result;
    Vector<DartPageDebug*> allPages = pages();
    for (Vector<DartPageDebug*>::iterator it = allPages.begin(); it != allPages.end(); ++it) {
        Vector<Dart_Isolate> forPage = (*it)->isolates();
        result.appendRange(forPage.begin(), forPage.end());
    }
    return result;
}

bool DartScriptDebugServer::resolveCodeLocation(const Dart_CodeLocation& location, int* line, int* column)
{
    // FIXME: cache the results of calling Dart_ScriptGetTokenInfo to improve
    // performance.
    Dart_Handle info = Dart_ScriptGetTokenInfo(location.library_id, location.script_url);
    if (!Dart_IsList(info)) {
        // FIXME: why does this sometimes happen?
        return false;
    }
    intptr_t infoLength = 0;
    Dart_Handle ALLOW_UNUSED result = Dart_ListLength(info, &infoLength);
    ASSERT(!Dart_IsError(result));
    Dart_Handle elem;
    bool lineStart = true;
    int currentLineNumber = 0;
    for (intptr_t i = 0; i < infoLength; i++) {
        elem = Dart_ListGetAt(info, i);
        if (Dart_IsNull(elem)) {
            lineStart = true;
        } else {
            ASSERT(Dart_IsInteger(elem));
            Dart_Handle exception = 0;
            int64_t value = DartUtilities::toInteger(elem, exception);
            ASSERT(!exception);
            if (lineStart) {
                // Line number.
                currentLineNumber = value;
                lineStart = false;
            } else {
                // Token offset.
                if (value == location.token_pos) {
                    *line = currentLineNumber;
                    ASSERT(i + 1 < infoLength);
                    *column = DartUtilities::toInteger(Dart_ListGetAt(info, i + 1), exception);
                    ASSERT(!exception);
                    return true;
                }
                i++; // skip columnNumber.
            }
        }
    }
    return false;
}

void DartScriptDebugServer::removeListener(DartScriptDebugListener* listener, Page* page)
{
    if (!m_pageToIdMap.contains(page))
        return;

    if (m_pausedPage == page)
        continueProgram();

    DartPageDebug* pageDebug = lookupPageDebug(page);
    if (pageDebug)
        pageDebug->removeListener();
}

void DartScriptDebugServer::setClientMessageLoop(PageScriptDebugServer::ClientMessageLoop* clientMessageLoop)
{
    m_clientMessageLoop = clientMessageLoop;
}

void DartScriptDebugServer::runMessageLoopOnPause(Dart_Isolate isolate)
{
    LocalFrame* frame = DartUtilities::domWindowForCurrentIsolate()->frame();
    m_pausedPage = frame->page();

    // Wait for continue or step command.
    m_clientMessageLoop->run(m_pausedPage);

    DartPageDebug* pageDebug = lookupPageDebug(m_pausedPage);
    // The listener may have been removed in the nested loop.
    if (pageDebug && pageDebug->listener())
        pageDebug->listener()->didContinue();

    m_pausedPage = 0;
}

void DartScriptDebugServer::quitMessageLoopOnPause()
{
    m_clientMessageLoop->quitNow();
}

void DartScriptDebugServer::interruptAndRunAllTasks()
{
    Vector<Dart_Isolate> isolates = threadSafeIsolateTracker().isolates();
    for (Vector<Dart_Isolate>::iterator it = isolates.begin(); it != isolates.end(); ++it)
        Dart_InterruptIsolate(*it);
}

void DartScriptDebugServer::runPendingTasks()
{
    drainTaskQueue(debugTaskQueue());
}

void DartScriptDebugServer::debugBreak()
{
    Vector<Dart_Isolate> iter = isolates();
    for (Vector<Dart_Isolate>::iterator it = iter.begin(); it != iter.end(); ++it) {
        Dart_Isolate isolate = *it;
        if (!m_interruptCalled.contains(isolate)) {
            m_interruptCalled.add(isolate);
            Dart_InterruptIsolate(isolate);
        }
        m_interruptCancelled.remove(isolate);
    }
}

void DartScriptDebugServer::cancelDebugBreak()
{
    // FIXME: it would be nice if the DartVM provided an API to directly cancel
    // a debug break call like V8 does.
    for (HashSet<Dart_Isolate>::iterator it = m_interruptCalled.begin(); it != m_interruptCalled.end(); ++it) {
        m_interruptCancelled.add(*it);
    }
}

Page* DartScriptDebugServer::inferPage(Dart_Isolate isolate)
{
    for (DebugDataMap::iterator it = m_pageIdToDebugDataMap.begin(); it != m_pageIdToDebugDataMap.end(); ++it) {
        DartPageDebug* pageDebug = it->value;
        if (pageDebug->containsIsolate(isolate)) {
            return pageDebug->page();
        }
    }
    return 0;
}

void DartScriptDebugServer::unregisterIsolate(Dart_Isolate isolate, Page* page)
{
    threadSafeIsolateTracker().remove(isolate);

    m_interruptCalled.remove(isolate);
    m_interruptCancelled.remove(isolate);
    if (!page) {
        // FIXME: We should instead fix the underlying issue where the
        // reference to the page is lost before we call unregisterIsolate in
        // some cases.
        page = inferPage(isolate);
        ASSERT(page);
    }
    DartPageDebug* pageDebug = lookupPageDebug(page);
    ASSERT(pageDebug);
    if (pageDebug)
        pageDebug->unregisterIsolate(isolate);
}

void DartScriptDebugServer::isolateLoaded()
{
    Page* page = DartUtilities::domWindowForCurrentIsolate()->document()->page();
    if (!page || !instrumentationForPage(page)->inspectorDebuggerAgent())
        return;

    DartPageDebug* pageDebug = lookupPageDebug(page);
    if (!pageDebug)
        return;

    pageDebug->isolateLoaded();
}

bool DartScriptDebugServer::isAnyScriptPaused()
{
    return isPaused() || PageScriptDebugServer::shared().isPaused();
}

void DartScriptDebugServer::handleDartDebugEvent(Dart_IsolateId isolateId, intptr_t breakpointId, Dart_Handle exception, const Dart_CodeLocation& location)
{
    // Don't allow nested breaks.
    if (isAnyScriptPaused())
        return;

    if (!m_breakpointsActivated && breakpointId != ILLEGAL_BREAKPOINT_ID)
        return;

    Dart_Isolate isolate = Dart_GetIsolate(isolateId);
    ASSERT(isolate);
    Dart_StackTrace stackTrace = 0;
    Dart_Handle ALLOW_UNUSED result = Dart_GetStackTrace(&stackTrace);
    ASSERT(!Dart_IsError(result));
    result = 0;
    DartPageDebug* pageDebug = lookupPageDebugForCurrentIsolate();
    if (!pageDebug)
        return;
    DartScriptDebugListener* listener = pageDebug->listener();
    if (listener) {
        DartIsolateScope scope(isolate);
        DartApiScope apiScope;
        handleProgramBreak(isolate, stackTrace, breakpointId, exception, location);
    }
}

DartPageDebug* DartScriptDebugServer::lookupPageDebugForCurrentIsolate()
{
    Page* page = DartUtilities::domWindowForCurrentIsolate()->document()->page();
    return lookupPageDebug(page);
}

void DartScriptDebugServer::handleProgramBreak(Dart_Isolate isolate, Dart_StackTrace stackTrace, intptr_t dartBreakpointId, Dart_Handle exception, const Dart_CodeLocation& location)
{
    ASSERT(isolate == Dart_CurrentIsolate());
    // Don't allow nested breaks.
    if (isAnyScriptPaused())
        return;

    DartPageDebug* pageDebug = lookupPageDebugForCurrentIsolate();
    if (!pageDebug)
        return;
    DartScriptDebugListener* listener = pageDebug->listener();

    if (!listener)
        return;

    // Required as some Dart code executes outside of a valid V8 scope when
    // the program is paused due to interrupting a Dart isolate.
    V8Scope v8Scope(DartDOMData::current());

    Vector<String> breakpointIds;
    breakpointIds.append(pageDebug->lookupBreakpointId(dartBreakpointId));
    m_executionState = stackTrace;
    m_pausedIsolate = isolate;
    DartScriptState* scriptState = DartUtilities::currentScriptState();
    DartScriptDebugListener::SkipPauseRequest result = listener->didPause(scriptState, m_executionState, exception ? DartUtilities::dartToScriptValue(exception) : ScriptValue(), breakpointIds);

    if (result == DartScriptDebugListener::NoSkip) {
        m_runningNestedMessageLoop = true;
        runMessageLoopOnPause(isolate);
        m_runningNestedMessageLoop = false;
    }
    if (result == DartScriptDebugListener::StepInto) {
        Dart_SetStepInto();
    } else if (result == DartScriptDebugListener::StepOut) {
        Dart_SetStepOut();
    }
}

void DartScriptDebugServer::pausedEventHandler(Dart_IsolateId isolateId, intptr_t breakpointId, const Dart_CodeLocation& location)
{
    DartScriptDebugServer::shared().handleDartDebugEvent(isolateId, breakpointId, 0, location);
}

void DartScriptDebugServer::exceptionHandler(Dart_IsolateId isolateId, Dart_Handle exception, Dart_StackTrace trace)
{
    DartScriptDebugServer::shared().handleException(isolateId, exception, trace);
}

void DartScriptDebugServer::isolateEventHandler(Dart_IsolateId isolateId, Dart_IsolateEvent kind)
{
    if (kind == kInterrupted) {
        DartScriptDebugServer::shared().handleInterrupted(isolateId);
    }
}

void DartScriptDebugServer::handleInterrupted(Dart_IsolateId isolateId)
{
    V8Scope v8Scope(DartDOMData::current());
    // FIXME: this is a bit of a hack. V8 was also set to pause on the next
    // code execution. If it attempts to pause while in the middle of
    // internal V8 debugger logic it will crash so before we do anything we
    // need to cancel the pending pause sent to V8.
    // Perhaps it would be slightly less hacky to send a message to
    // ScriptDebugServer instructing it to cancel pausing V8.
    v8::Debug::CancelDebugBreak(DartUtilities::currentV8Context()->GetIsolate());

    Dart_Isolate isolate = Dart_GetIsolate(isolateId);
    ASSERT(isolate);
    DartIsolateScope scope(isolate);
    DartApiScope apiScope;

    if (!m_interruptCalled.contains(isolate)) {
        // Special case when we were interrupted to run pending tasks.
        // We need to fake that an interrupt has been called so we don't
        // issue an extra spurious interrupt.
        m_interruptCalled.add(isolate);
        m_interruptCancelled.add(isolate);
    }
    runPendingTasks();

    ASSERT(isolate == Dart_CurrentIsolate());
    if (!m_interruptCalled.contains(isolate)) {
        return;
    }

    m_interruptCalled.remove(isolate);
    if (m_interruptCancelled.contains(isolate)) {
        m_interruptCancelled.remove(isolate);
        return;
    }

    // The user really wants to be paused at the start of the first line of
    // the Dart method not at the method invocation itself. Otherwise,
    // stepping to the next call steps out of the executing Dart code
    // which is not what the user expects.
    Dart_SetStepInto();
    continueProgram();
}

void DartScriptDebugServer::handleException(Dart_IsolateId isolateId, Dart_Handle exception, Dart_StackTrace trace)
{
    Dart_Isolate isolate = Dart_GetIsolate(isolateId);
    ASSERT(isolate);
    Dart_CodeLocation location;
    Dart_Handle ALLOW_UNUSED result;
    Dart_ActivationFrame frame;
    result = Dart_GetActivationFrame(trace, 0, &frame);
    ASSERT(!Dart_IsError(result));
    result = Dart_ActivationFrameGetLocation(frame, 0, 0, &location);
    ASSERT(!Dart_IsError(result));
    handleProgramBreak(isolate, trace, ILLEGAL_BREAKPOINT_ID, exception, location);
}

void DartScriptDebugServer::runScript(ScriptState* scriptState, const String& scriptId, ScriptValue* result, bool* wasThrown, String* exceptionDetailsText, int* lineNumber, int* columnNumber, RefPtrWillBeRawPtr<ScriptCallStack>* stackTrace)
{
}

ScriptCallFrame DartScriptDebugServer::getScriptCallFrameHelper(int frameIndex)
{
    Dart_ActivationFrame frame = 0;
    Dart_Handle result = Dart_GetActivationFrame(0, frameIndex, &frame);
    ASSERT(!Dart_IsError(result));
    if (Dart_IsError(result))
        return ScriptCallFrame();
    Dart_Handle functionName = 0;
    Dart_Handle function = 0;
    Dart_CodeLocation location;
    Dart_ActivationFrameGetLocation(frame, &functionName, &function, &location);
    const String& url = DartUtilities::toString(location.script_url);
    intptr_t line = 0;
    intptr_t column = 0;
    Dart_ActivationFrameInfo(frame, 0, 0, &line, &column);

    Dart_Handle exception = 0;
    String functionString = DartUtilities::dartToString(functionName, exception);
    ASSERT(!exception);
    if (exception)
        functionString = "Unknown function";
    return ScriptCallFrame(functionString, getScriptId(url, Dart_CurrentIsolate()), url, line - 1, column - 1);
}

}
