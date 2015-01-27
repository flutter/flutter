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

#ifndef DartScriptDebugServer_h
#define DartScriptDebugServer_h

#include "bindings/core/dart/DartScriptDebugListener.h"
#include "bindings/core/v8/PageScriptDebugServer.h"
#include "core/inspector/ScriptBreakpoint.h"

#include "wtf/Forward.h"
#include "wtf/HashSet.h"
#include "wtf/RefCounted.h"
#include <dart_api.h>
#include <dart_debugger_api.h>
#include <v8.h>

namespace blink {

class DartInjectedScriptManager;
class Page;
template<typename T>
class HandleMap {
public:
    HandleMap() : m_lastHandle(0)
    {
    }

    int add(T value)
    {
        ASSERT(!m_valueToHandleMap.contains(value));
        int handle = ++m_lastHandle;
        m_handleToValueMap.set(handle, value);
        m_valueToHandleMap.set(value, handle);
        return handle;
    }

    T get(int handle)
    {
        return m_handleToValueMap.get(handle);
    }

    bool containsValue(T value)
    {
        return m_valueToHandleMap.contains(value);
    }

    int getByValue(T value)
    {
        ASSERT(m_valueToHandleMap.contains(value));
        return m_valueToHandleMap.get(value);
    }

    T remove(int handle)
    {
        T value = m_handleToValueMap.take(handle);
        m_valueToHandleMap.remove(value);
        return value;
    }

    int removeByValue(T value)
    {
        int handle = m_valueToHandleMap.take(value);
        m_handleToValueMap.remove(handle);
        return handle;
    }

    void copyValues(Vector<T>& values)
    {
        copyKeysToVector(m_valueToHandleMap, values);
    }

private:
    int m_lastHandle;
    HashMap<int, T> m_handleToValueMap;
    HashMap<T, int> m_valueToHandleMap;
};

struct DartBreakpoint {
    DartBreakpoint(intptr_t breakpointId, Dart_Isolate);

    intptr_t m_breakpointId;
    Dart_Isolate m_isolate;
};


struct DartBreakpointInfo {
    DartBreakpointInfo(const String& scriptUrl, const ScriptBreakpoint&);
    String m_scriptUrl;
    ScriptBreakpoint m_scriptBreakpoint;
    Vector<DartBreakpoint> m_breakpoints;
};

class DartPageDebug {
public:
    DartPageDebug(Page*, int pageId);
    ~DartPageDebug();

    String setBreakpoint(const String& sourceID, const ScriptBreakpoint&, int* actualLineNumber, int* actualColumnNumber, bool interstatementLocation);

    void registerIsolate(Dart_Isolate);
    void unregisterIsolate(Dart_Isolate);

    intptr_t setBreakpointHelper(DartBreakpointInfo*, const String& breakpointIdString, Dart_Isolate, Dart_Handle& exception);

    void removeBreakpoint(const String& breakpointId);
    void removeBreakpointHelper(DartBreakpointInfo*);
    void clearBreakpointsForIsolate(Dart_Isolate);
    void clearBreakpoints();
    void isolateLoaded();
    void addListener(DartScriptDebugListener*);
    void removeListener();
    DartScriptDebugListener* listener() { return m_listener; }
    String getScriptId(const String& url);
    String lookupBreakpointId(intptr_t dartBreakpointId);

    Vector<Dart_Isolate> isolates();
    bool containsIsolate(Dart_Isolate isolate) { return m_isolateMap.containsValue(isolate); }
    Page* page() { return m_page; }
private:
    void registerIsolateScripts(Dart_Isolate);
    void dispatchDidParseSource(intptr_t libraryId, Dart_Handle scriptURL, Dart_Isolate);

    HandleMap<Dart_Isolate> m_isolateMap;

    Page* m_page;
    DartScriptDebugListener* m_listener;
    int m_pageId;
    HashMap<String, String> m_idToScriptUrlMap;
    HashMap<String, String> m_scriptUrlToIdMap;

    typedef HashMap<String, DartBreakpointInfo* > BreakpointMap;
    BreakpointMap m_breakpoints;
    typedef HashMap<intptr_t, String> BreakpointIdMap;
    BreakpointIdMap m_breakpointIdMap;
    int m_nextBreakpointId;
    int m_nextScriptId;
};

class DartScriptDebugServer  {
    WTF_MAKE_NONCOPYABLE(DartScriptDebugServer);
public:
    static DartScriptDebugServer& shared();

    void addListener(DartScriptDebugListener*, Page*);
    void removeListener(DartScriptDebugListener*, Page*);

    void setClientMessageLoop(PageScriptDebugServer::ClientMessageLoop*);

    String setBreakpoint(const String& sourceID, const ScriptBreakpoint&, int* actualLineNumber, int* actualColumnNumber, bool interstatementLocation);
    void removeBreakpoint(const String& breakpointId);
    void clearBreakpoints();
    void setBreakpointsActivated(bool);

    ScriptDebugServer::PauseOnExceptionsState pauseOnExceptionsState();
    void setPauseOnExceptionsState(ScriptDebugServer::PauseOnExceptionsState);

    void setPauseOnNextStatement(bool);
    bool canBreakProgram();
    void breakProgram();
    void continueProgram();
    void stepIntoStatement();
    void stepOverStatement();
    void stepOutOfFunction();

    bool setScriptSource(const String& sourceID, const String& newContent, bool preview, String* error, RefPtr<TypeBuilder::Debugger::SetScriptSourceError>&, Dart_StackTrace newCallFrames, RefPtr<JSONObject>* result);
    ScriptCallFrame callFrameNoScopes(int index);

    int frameCount();
    Dart_StackTrace currentCallFrames();

    bool isPaused();
    bool runningNestedMessageLoop() { return m_runningNestedMessageLoop; }

    void runScript(ScriptState*, const String& scriptId, ScriptValue* result, bool* wasThrown, String* exceptionDetailsText, int* lineNumber, int* columnNumber, RefPtrWillBeRawPtr<ScriptCallStack>* stackTrace);

    static void pausedEventHandler(Dart_IsolateId, intptr_t breakpointId, const Dart_CodeLocation&);
    static void exceptionHandler(Dart_IsolateId, Dart_Handle, Dart_StackTrace);
    void handleException(Dart_IsolateId, Dart_Handle, Dart_StackTrace);

    static void isolateEventHandler(Dart_IsolateId, Dart_IsolateEvent kind);
    void handleInterrupted(Dart_IsolateId);
    static void interruptAndRunAllTasks();
    void runPendingTasks();

    void registerIsolate(Dart_Isolate, Page*);
    void unregisterIsolate(Dart_Isolate, Page*);
    void isolateLoaded();

    bool resolveCodeLocation(const Dart_CodeLocation&, int* line, int* column);

    String getScriptId(const String& url, Dart_Isolate);
    void clearWindowShell(Page*);

    ScriptDebugServer::PauseOnExceptionsState pauseOnExceptionState() { return m_pauseOnExceptionState; }

    void setInjectedScriptManager(DartInjectedScriptManager* manager) { m_injectedScriptManager = manager; }
    DartInjectedScriptManager* injectedScriptManager() { return m_injectedScriptManager; }
protected:
    explicit DartScriptDebugServer();
    ~DartScriptDebugServer();

    bool isAnyScriptPaused();

    DartPageDebug* lookupPageDebugForId(const String& id);
    DartPageDebug* lookupPageDebug(Page*);
    DartPageDebug* lookupPageDebugForCurrentIsolate();
    void runMessageLoopOnPause(Dart_Isolate);
    void quitMessageLoopOnPause();
    bool executeSkipPauseRequest(DartScriptDebugListener::SkipPauseRequest, Dart_StackTrace);
    void handleProgramBreak(Dart_Isolate, Dart_StackTrace, intptr_t dartBreakpointId, Dart_Handle exception, const Dart_CodeLocation&);
    void handleDartDebugEvent(Dart_IsolateId, intptr_t breakpointId, Dart_Handle exception, const Dart_CodeLocation&);

    ScriptCallFrame getScriptCallFrameHelper(int frameIndex);

    void debugBreak();
    void cancelDebugBreak();
    Page* inferPage(Dart_Isolate);

    Vector<Dart_Isolate> isolates();
    Vector<DartPageDebug*> pages();

    ScriptDebugServer::PauseOnExceptionsState m_pauseOnExceptionState;
    bool m_breakpointsActivated;
    bool m_runningNestedMessageLoop;
    Dart_StackTrace m_executionState;
    Dart_Isolate m_pausedIsolate;
    Page* m_pausedPage;
    HashSet<Dart_Isolate> m_interruptCalled;
    HashSet<Dart_Isolate> m_interruptCancelled;

    typedef HashMap<int, DartPageDebug*> DebugDataMap;
    DebugDataMap m_pageIdToDebugDataMap;
    typedef HashMap<Page*, int> PageToIdMap;
    PageToIdMap m_pageToIdMap;

    PageScriptDebugServer::ClientMessageLoop* m_clientMessageLoop;

    DartInjectedScriptManager* m_injectedScriptManager;

    int m_nextPageId;
};

}

#endif // DartScriptDebugServer_h
