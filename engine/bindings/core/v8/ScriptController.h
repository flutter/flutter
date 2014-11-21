/*
 * Copyright (C) 2008, 2009 Google Inc. All rights reserved.
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

#ifndef ScriptController_h
#define ScriptController_h

#include "sky/engine/bindings/core/v8/ScriptValue.h"
#include "sky/engine/bindings/core/v8/SharedPersistent.h"
#include "sky/engine/wtf/Forward.h"
#include "sky/engine/wtf/HashMap.h"
#include "sky/engine/wtf/RefCounted.h"
#include "sky/engine/wtf/Vector.h"
#include "sky/engine/wtf/text/TextPosition.h"
#include "v8/include/v8.h"

namespace blink {

class DOMWrapperWorld;
class ExecutionContext;
class Event;
class HTMLDocument;
class KURL;
class LocalFrame;
class AbstractModule;
class ScriptState;
class ScriptSourceCode;
class WindowProxy;
class Widget;

typedef WTF::Vector<v8::Extension*> V8Extensions;

class ScriptController {
public:
    ScriptController(LocalFrame*);
    ~ScriptController();

    bool initializeMainWorld();
    WindowProxy* windowProxy(DOMWrapperWorld&);
    WindowProxy* existingWindowProxy(DOMWrapperWorld&);

    // Evaluate JavaScript in the main world.
    void executeScriptInMainWorld(const String&);
    void executeScriptInMainWorld(const ScriptSourceCode&);
    v8::Local<v8::Value> executeScriptInMainWorldAndReturnValue(const ScriptSourceCode&);
    v8::Local<v8::Value> executeScriptAndReturnValue(v8::Handle<v8::Context>, const ScriptSourceCode&);

    void executeModuleScript(AbstractModule&, const String& source, const TextPosition& textPosition);

    // Executes JavaScript in an isolated world. The script gets its own global scope,
    // its own prototypes for intrinsic JavaScript objects (String, Array, and so-on),
    // and its own wrappers for all DOM nodes and DOM constructors.
    //
    // If an isolated world with the specified ID already exists, it is reused.
    // Otherwise, a new world is created.
    //
    // FIXME: Get rid of extensionGroup here.
    void executeScriptInIsolatedWorld(int worldID, const Vector<ScriptSourceCode>& sources, int extensionGroup, Vector<v8::Local<v8::Value> >* results);

    v8::Local<v8::Value> callFunction(v8::Handle<v8::Function>, v8::Handle<v8::Value>, int argc, v8::Handle<v8::Value> argv[]);
    static v8::Local<v8::Value> callFunction(ExecutionContext*, v8::Handle<v8::Function>, v8::Handle<v8::Value> receiver, int argc, v8::Handle<v8::Value> info[], v8::Isolate*);

    static bool canAccessFromCurrentOrigin(LocalFrame*);

    static void setCaptureCallStackForUncaughtExceptions(bool);

    void clearWindowProxy();
    void updateDocument();

    void clearForClose();

    // Registers a v8 extension to be available on webpages. Will only
    // affect v8 contexts initialized after this call. Takes ownership of
    // the v8::Extension object passed.
    static void registerExtensionIfNeeded(v8::Extension*);
    static V8Extensions& registeredExtensions();

    void setWorldDebugId(int worldId, int debuggerId);

    v8::Isolate* isolate() const { return m_isolate; }

private:
    typedef HashMap<int, OwnPtr<WindowProxy> > IsolatedWorldMap;

    v8::Local<v8::Value> evaluateScriptInMainWorld(const ScriptSourceCode&);

    LocalFrame* m_frame;
    const String* m_sourceURL;
    v8::Isolate* m_isolate;

    OwnPtr<WindowProxy> m_windowProxy;
    IsolatedWorldMap m_isolatedWorlds;
};

} // namespace blink

#endif // ScriptController_h
