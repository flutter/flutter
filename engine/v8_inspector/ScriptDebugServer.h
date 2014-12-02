/*
 * Copyright (c) 2010, Google Inc. All rights reserved.
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

#ifndef SKY_ENGINE_V8_INSPECTOR_SCRIPTDEBUGSERVER_H_
#define SKY_ENGINE_V8_INSPECTOR_SCRIPTDEBUGSERVER_H_

#include "gen/v8_inspector/InspectorBackendDispatcher.h"
#include "sky/engine/bindings/core/v8/ScopedPersistent.h"
#include "sky/engine/core/inspector/ScriptCallStack.h"
#include "sky/engine/v8_inspector/ScriptBreakpoint.h"
#include "sky/engine/v8_inspector/ScriptDebugListener.h"
#include "sky/engine/wtf/HashMap.h"
#include "sky/engine/wtf/Noncopyable.h"
#include "sky/engine/wtf/PassOwnPtr.h"
#include "sky/engine/wtf/text/StringHash.h"
#include "sky/engine/wtf/text/WTFString.h"
#include "v8/include/v8-debug.h"
#include "v8/include/v8.h"

namespace blink {

class ScriptState;
class ScriptController;
class ScriptDebugListener;
class ScriptSourceCode;
class ScriptValue;
class JavaScriptCallFrame;

class ScriptDebugServer {
    WTF_MAKE_NONCOPYABLE(ScriptDebugServer);
public:
    String setBreakpoint(const String& sourceID, const ScriptBreakpoint&, int* actualLineNumber, int* actualColumnNumber, bool interstatementLocation);
    void removeBreakpoint(const String& breakpointId);
    void clearBreakpoints();
    void setBreakpointsActivated(bool activated);

    enum PauseOnExceptionsState {
        DontPauseOnExceptions,
        PauseOnAllExceptions,
        PauseOnUncaughtExceptions
    };
    PauseOnExceptionsState pauseOnExceptionsState();
    void setPauseOnExceptionsState(PauseOnExceptionsState pauseOnExceptionsState);

    void setPauseOnNextStatement(bool pause);
    bool pausingOnNextStatement();
    bool canBreakProgram();
    void breakProgram();
    void continueProgram();
    void stepIntoStatement();
    void stepOverStatement();
    void stepOutOfFunction();

    bool setScriptSource(const String& sourceID, const String& newContent, bool preview, String* error, RefPtr<TypeBuilder::Debugger::SetScriptSourceError>&, ScriptValue* newCallFrames, RefPtr<JSONObject>* result);
    ScriptValue currentCallFrames();
    ScriptValue currentCallFramesForAsyncStack();
    PassRefPtr<JavaScriptCallFrame> callFrameNoScopes(int index);
    int frameCount();

    static PassRefPtr<JavaScriptCallFrame> toJavaScriptCallFrameUnsafe(const ScriptValue&);

    class Task {
    public:
        virtual ~Task() { }
        virtual void run() = 0;
    };
    static void interruptAndRun(PassOwnPtr<Task>, v8::Isolate*);
    void runPendingTasks();

    bool isPaused();
    bool runningNestedMessageLoop() { return m_runningNestedMessageLoop; }

    v8::Local<v8::Value> functionScopes(v8::Handle<v8::Function>);
    v8::Local<v8::Value> collectionEntries(v8::Handle<v8::Object>&);
    v8::Local<v8::Value> getInternalProperties(v8::Handle<v8::Object>&);
    v8::Handle<v8::Value> setFunctionVariableValue(v8::Handle<v8::Value> functionValue, int scopeNumber, const String& variableName, v8::Handle<v8::Value> newValue);
    v8::Local<v8::Value> callDebuggerMethod(const char* functionName, int argc, v8::Handle<v8::Value> argv[]);

    virtual void compileScript(ScriptState*, const String& expression, const String& sourceURL, String* scriptId, String* exceptionDetailsText, int* lineNumber, int* columnNumber, RefPtr<ScriptCallStack>* stackTrace);
    virtual void clearCompiledScripts();
    virtual void runScript(ScriptState*, const String& scriptId, ScriptValue* result, bool* wasThrown, String* exceptionDetailsText, int* lineNumber, int* columnNumber, RefPtr<ScriptCallStack>* stackTrace);
    virtual void setPreprocessorSource(const String&) { }
    virtual void preprocessBeforeCompile(const v8::Debug::EventDetails&) { }
    virtual PassOwnPtr<ScriptSourceCode> preprocess(LocalFrame*, const ScriptSourceCode&);
    virtual String preprocessEventListener(LocalFrame*, const String& source, const String& url, const String& functionName);
    virtual void clearPreprocessor() { }

protected:
    explicit ScriptDebugServer(v8::Isolate*);
    virtual ~ScriptDebugServer();

    virtual ScriptDebugListener* getDebugListenerForContext(v8::Handle<v8::Context>) = 0;
    virtual void runMessageLoopOnPause(v8::Handle<v8::Context>) = 0;
    virtual void quitMessageLoopOnPause() = 0;

    static void breakProgramCallback(const v8::FunctionCallbackInfo<v8::Value>&);
    void handleProgramBreak(ScriptState* pausedScriptState, v8::Handle<v8::Object> executionState, v8::Handle<v8::Value> exception, v8::Handle<v8::Array> hitBreakpoints);

    static void v8DebugEventCallback(const v8::Debug::EventDetails& eventDetails);
    void handleV8DebugEvent(const v8::Debug::EventDetails& eventDetails);

    void dispatchDidParseSource(ScriptDebugListener*, v8::Handle<v8::Object> sourceObject, CompileResult);

    void ensureDebuggerScriptCompiled();
    void discardDebuggerScript();

    PauseOnExceptionsState m_pauseOnExceptionsState;
    ScopedPersistent<v8::Object> m_debuggerScript;
    v8::Local<v8::Object> m_executionState;
    RefPtr<ScriptState> m_pausedScriptState;
    bool m_breakpointsActivated;
    ScopedPersistent<v8::FunctionTemplate> m_breakProgramCallbackTemplate;
    HashMap<String, OwnPtr<ScopedPersistent<v8::Script> > > m_compiledScripts;
    v8::Isolate* m_isolate;

private:
    enum ScopeInfoDetails {
        AllScopes,
        FastAsyncScopes,
        NoScopes // Should be the last option.
    };

    ScriptValue currentCallFramesInner(ScopeInfoDetails);

    PassRefPtr<JavaScriptCallFrame> wrapCallFrames(int maximumLimit, ScopeInfoDetails);

    void handleV8AsyncTaskEvent(ScriptDebugListener*, ScriptState* pausedScriptState, v8::Handle<v8::Object> executionState, v8::Handle<v8::Object> eventData);

    void handleV8PromiseEvent(ScriptDebugListener*, ScriptState* pausedScriptState, v8::Handle<v8::Object> executionState, v8::Handle<v8::Object> eventData);

    bool m_runningNestedMessageLoop;
};

} // namespace blink


#endif  // SKY_ENGINE_V8_INSPECTOR_SCRIPTDEBUGSERVER_H_
