// Copyright 2011, Google Inc.
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//    * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//    * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#ifndef DartController_h
#define DartController_h

#include "bindings/core/v8/ScriptSourceCode.h"
#include "wtf/Deque.h"
#include "wtf/HashMap.h"
#include "wtf/Vector.h"
#include "wtf/text/WTFString.h"

#include <dart_api.h>
#include <v8.h>

struct NPObject;

namespace blink {

class DartApplicationLoader;
class DartDOMData;
class DartScriptInfo;
class DartScriptState;
class Document;
class ExecutionContext;
class LocalDOMWindow;
class LocalFrame;
class ScriptLoader;
class ScriptState;
class V8ScriptState;

typedef HashMap<intptr_t, RefPtr<DartScriptState> > LibraryIdMap;
typedef HashMap<Dart_Isolate, LibraryIdMap*> ScriptStatesMap;

// This class provides the linkage between a LocalFrame and its attached
// Dart isolates. It is similar to ScriptController for JavaScript.
// The DartController is owned by its LocalFrame.
class DartController {
public:
    DartController(LocalFrame*);
    virtual ~DartController();

    void evaluate(const ScriptSourceCode&, ScriptLoader* = 0);

    // Exposes NPObject instance to Dart environment.
    void bindToWindowObject(LocalFrame*, const String& key, NPObject*);
    NPObject* npObject(const String& key);

    void clearWindowShell();
    void clearScriptObjects();

    Dart_Handle callFunction(Dart_Handle function, int argc, Dart_Handle* argv);

    LocalFrame* frame() const { return m_frame; }
    void collectScriptStates(V8ScriptState*, Vector<DartScriptState*>& result);
    void collectScriptStatesForIsolate(Dart_Isolate, v8::Handle<v8::Context> v8Context, Vector<DartScriptState*>& result);
    DartScriptState* lookupScriptState(Dart_Isolate, v8::Handle<v8::Context> v8Context, intptr_t libraryId);

    static DartController* retrieve(LocalFrame*);
    static DartController* retrieve(ExecutionContext*);

    bool isActive() { return !m_isolates.isEmpty(); }

    void spawnDomUri(const String& uri);

private:
    static void initVMIfNeeded();

    static Dart_Isolate createIsolate(const char* scriptURL, const char* entryPoint, Document*, bool isDOMEnabled, bool isDebuggerEnabled, char** errorMessage);
    void shutdownIsolate(Dart_Isolate);

    Dart_Isolate createDOMEnabledIsolate(const String& scriptURL, const String& entryPoint, Document*);
    void scheduleScriptExecution(const String&, Dart_Isolate, PassRefPtr<DartScriptInfo>);
    void loadAndRunScript(const String&, Dart_Isolate, PassRefPtr<DartScriptInfo>);
    static void shutdownIsolateCallback(void* data);
    static Dart_Isolate createServiceIsolateCallback(void* callbackData, char** error);
    static Dart_Isolate createPureIsolateCallback(const char* prefix, const char* main, const char* packageRoot, void* callbackData, char** errorMsg);

    static void weakCallback(void* isolateCallbackData, Dart_WeakPersistentHandle, void* peer);

    HashSet<Document*> m_documentsWithDart;

    LibraryIdMap* libraryIdMapForIsolate(Dart_Isolate);
    DartScriptState* lookupScriptStateFromLibraryIdMap(Dart_Isolate, v8::Handle<v8::Context>, LibraryIdMap*, intptr_t libraryId);

    // The frame that owns this controller.
    LocalFrame* m_frame;

    // Isolate associated with scripts in this document.
    Vector<Dart_Isolate> m_isolates;
    RefPtr<DartApplicationLoader> m_loader;

    ScriptStatesMap m_scriptStates;

    typedef HashMap<String, NPObject*> NPObjectMap;
    NPObjectMap m_npObjectMap;

    friend class DartDomLoadCallback;
    friend class DartScriptRunner;
    friend class DartService;
};

}

#endif // DartController_h
