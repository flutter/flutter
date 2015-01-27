// Copyright 2013, Google Inc.
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

#ifndef DartScriptState_h
#define DartScriptState_h

#include "bindings/core/v8/V8ScriptState.h"

#include <dart_api.h>
#include <v8.h>

namespace blink {

class DartScriptState : public ScriptState {
    WTF_MAKE_NONCOPYABLE(DartScriptState);
public:
    static PassRefPtr<DartScriptState> create(Dart_Isolate isolate, intptr_t libraryId, V8ScriptState* v8ScriptState)
    {
        return adoptRef(new DartScriptState(isolate, libraryId, v8ScriptState));
    }

    // Long term we want to be creating DartScriptStates without V8ScriptStates.
    static PassRefPtr<DartScriptState> create(Dart_Isolate isolate, intptr_t libraryId)
    {
        return adoptRef(new DartScriptState(isolate, libraryId, 0));
    }

    bool isDartScriptState() const { return true; }
    V8ScriptState* v8ScriptState()
    {
        ASSERT(m_v8ScriptState);
        return m_v8ScriptState.get();
    }

    LocalDOMWindow* domWindow() const { return m_v8ScriptState->domWindow(); }
    LocalDOMWindow* callingDOMWindow() const
    {
        // In Dart, the calling Window is always the same as the window of the
        // script as Dart does not expose bindings for cross frame DOM manipulation.
        // FIXMEDART: If/when cross-frame bindings are made available this needs to
        // be changed. Note that we cannot rely on asking the V8 script state for
        // the calling window (it can differ or be invalid during a navigation).
        return domWindow();
    }

    ExecutionContext* executionContext() const { return m_v8ScriptState->executionContext(); }
    bool evalEnabled() const { return m_v8ScriptState->evalEnabled(); }
    void setEvalEnabled(bool flag) { m_v8ScriptState->setEvalEnabled(flag); }
    bool contextIsEmpty() const;
    PassRefPtr<AbstractScriptValue> createNull();
    PassRefPtr<AbstractScriptValue> createUndefined();
    PassRefPtr<AbstractScriptValue> createBoolean(bool);
    PassRefPtr<AbstractScriptPromise> createEmptyPromise();
    PassRefPtr<AbstractScriptPromise> createRejectedPromise(PassRefPtrWillBeRawPtr<DOMException>);
    PassRefPtr<AbstractScriptPromise> createPromiseRejectedWithTypeError(const String& message);
    virtual PassOwnPtr<AbstractScriptPromiseResolver> createPromiseResolver(ScriptPromiseResolver*);
    AbstractScriptStateProtectingContext* createProtectingContext();
    PassRefPtr<AbstractScriptValue> idbAnyToScriptValue(IDBAny*);
    PassRefPtr<AbstractScriptValue> idbKeyToScriptValue(IDBKey*);

    Dart_Isolate isolate() { return m_isolate; }
    virtual intptr_t libraryId() { return m_libraryId; }

    virtual const String* name() { return &m_libraryUrl; }
    virtual bool isJavaScript() { return false; }

#ifndef NDEBUG
    void assertPrimaryKeyValidOrInjectable(PassRefPtr<SharedBuffer>, const Vector<blink::WebBlobInfo>*, IDBKey*, const IDBKeyPath&);
#endif

private:
    explicit DartScriptState(Dart_Isolate, intptr_t libraryId, V8ScriptState*);
    ~DartScriptState() { }

    Dart_Isolate m_isolate;
    intptr_t m_libraryId;
    String m_libraryUrl;
    RefPtr<V8ScriptState> m_v8ScriptState;
};

}

#endif // DartScriptState_h
