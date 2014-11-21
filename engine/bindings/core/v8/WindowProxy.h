/*
 * Copyright (C) 2009 Google Inc. All rights reserved.
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

#ifndef WindowProxy_h
#define WindowProxy_h

#include "sky/engine/bindings/core/v8/DOMWrapperWorld.h"
#include "sky/engine/bindings/core/v8/ScopedPersistent.h"
#include "sky/engine/bindings/core/v8/ScriptState.h"
#include "sky/engine/bindings/core/v8/WrapperTypeInfo.h"
#include "sky/engine/wtf/Forward.h"
#include "sky/engine/wtf/HashMap.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefCounted.h"
#include "sky/engine/wtf/RefPtr.h"
#include "sky/engine/wtf/text/AtomicString.h"
#include "v8/include/v8.h"

namespace blink {

class LocalDOMWindow;
class LocalFrame;
class HTMLDocument;

// WindowProxy represents all the per-global object state for a LocalFrame that
// persist between navigations.
class WindowProxy {
public:
    static PassOwnPtr<WindowProxy> create(LocalFrame*, DOMWrapperWorld&, v8::Isolate*);

    v8::Local<v8::Context> context() const { return m_scriptState ? m_scriptState->context() : v8::Local<v8::Context>(); }
    ScriptState* scriptState() const { return m_scriptState.get(); }

    // Update document object of the frame.
    void updateDocument();

    bool isContextInitialized() { return m_scriptState && !!m_scriptState->perContextData(); }
    bool isGlobalInitialized() { return !m_global.isEmpty(); }

    bool initializeIfNeeded();
    void updateDocumentWrapper(v8::Handle<v8::Object> wrapper);

    void clearForNavigation();
    void clearForClose();

    DOMWrapperWorld& world() { return *m_world; }

private:
    WindowProxy(LocalFrame*, PassRefPtr<DOMWrapperWorld>, v8::Isolate*);
    bool initialize();

    enum GlobalDetachmentBehavior {
        DoNotDetachGlobal,
        DetachGlobal
    };
    void disposeContext(GlobalDetachmentBehavior);

    // The JavaScript wrapper for the document object is cached on the global
    // object for fast access. UpdateDocumentProperty sets the wrapper
    // for the current document on the global object. ClearDocumentProperty
    // deletes the document wrapper from the global object.
    void updateDocumentProperty();
    void clearDocumentProperty();

    void createContext();
    bool installDOMWindow();

    static WindowProxy* enteredIsolatedWorldContext();

    LocalFrame* m_frame;
    v8::Isolate* m_isolate;
    RefPtr<ScriptState> m_scriptState;
    RefPtr<DOMWrapperWorld> m_world;
    ScopedPersistent<v8::Object> m_global;
    ScopedPersistent<v8::Object> m_document;
};

} // namespace blink

#endif // WindowProxy_h
