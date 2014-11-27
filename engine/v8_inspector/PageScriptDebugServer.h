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

#ifndef SKY_ENGINE_V8_INSPECTOR_PAGESCRIPTDEBUGSERVER_H_
#define SKY_ENGINE_V8_INSPECTOR_PAGESCRIPTDEBUGSERVER_H_

#include "sky/engine/bindings/core/v8/ScriptDebugServer.h"
#include "sky/engine/bindings/core/v8/ScriptPreprocessor.h"
#include "sky/engine/wtf/Forward.h"
#include "sky/engine/wtf/RefCounted.h"
#include "v8/include/v8.h"

// This whole file will move to namespace inspector.
namespace inspector {
class InspectorHost;
}

namespace blink {

class ScriptController;
class ScriptPreprocessor;
class ScriptSourceCode;

class PageScriptDebugServer final : public ScriptDebugServer {
    WTF_MAKE_NONCOPYABLE(PageScriptDebugServer);
public:
    static PageScriptDebugServer& shared();

    static void setMainThreadIsolate(v8::Isolate*);

    void addListener(ScriptDebugListener*, inspector::InspectorHost*);
    void removeListener(ScriptDebugListener*, inspector::InspectorHost*);

    static void interruptAndRun(PassOwnPtr<Task>);

    class ClientMessageLoop {
    public:
        virtual ~ClientMessageLoop() { }
        virtual void run(inspector::InspectorHost*) = 0;
        virtual void quitNow() = 0;
    };
    void setClientMessageLoop(PassOwnPtr<ClientMessageLoop>);

    class InspectorHostResolver {
    public:
        virtual ~InspectorHostResolver() { }
        virtual inspector::InspectorHost* inspectorHostFor(v8::Handle<v8::Context>) = 0;
    };
    void setInspectorHostResolver(PassOwnPtr<InspectorHostResolver>);

    virtual void compileScript(ScriptState*, const String& expression, const String& sourceURL, String* scriptId, String* exceptionDetailsText, int* lineNumber, int* columnNumber, RefPtr<ScriptCallStack>* stackTrace) override;
    virtual void clearCompiledScripts() override;
    virtual void runScript(ScriptState*, const String& scriptId, ScriptValue* result, bool* wasThrown, String* exceptionDetailsText, int* lineNumber, int* columnNumber, RefPtr<ScriptCallStack>* stackTrace) override;
    virtual void setPreprocessorSource(const String&) override;
    virtual void preprocessBeforeCompile(const v8::Debug::EventDetails&) override;
    virtual PassOwnPtr<ScriptSourceCode> preprocess(LocalFrame*, const ScriptSourceCode&) override;
    virtual String preprocessEventListener(LocalFrame*, const String& source, const String& url, const String& functionName) override;
    virtual void clearPreprocessor() override;

    virtual void muteWarningsAndDeprecations() override;
    virtual void unmuteWarningsAndDeprecations() override;

private:
    PageScriptDebugServer();
    virtual ~PageScriptDebugServer();

    virtual ScriptDebugListener* getDebugListenerForContext(v8::Handle<v8::Context>) override;
    virtual void runMessageLoopOnPause(v8::Handle<v8::Context>) override;
    virtual void quitMessageLoopOnPause() override;

    typedef HashMap<inspector::InspectorHost*, ScriptDebugListener*> ListenersMap;
    ListenersMap m_listenersMap;
    OwnPtr<ClientMessageLoop> m_clientMessageLoop;
    OwnPtr<InspectorHostResolver> m_inspectorHostResolver;
    inspector::InspectorHost* m_pausedHost;
    HashMap<String, String> m_compiledScriptURLs;

    OwnPtr<ScriptSourceCode> m_preprocessorSourceCode;
    OwnPtr<ScriptPreprocessor> m_scriptPreprocessor;
    bool canPreprocess(LocalFrame*);
    static v8::Isolate* s_mainThreadIsolate;
};

} // namespace blink


#endif  // SKY_ENGINE_V8_INSPECTOR_PAGESCRIPTDEBUGSERVER_H_
