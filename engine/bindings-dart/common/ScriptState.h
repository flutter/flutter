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

#ifndef ScriptState_h
#define ScriptState_h

#include "bindings/common/AbstractScriptValue.h"
#include "platform/heap/Handle.h"
#include "wtf/Assertions.h"
#include "wtf/Noncopyable.h"
#include "wtf/RefCounted.h"

namespace blink {

class AbstractScriptPromiseResolver;
class AbstractScriptStateProtectingContext;
class DOMException;
class DOMWrapperWorld;
class ExecutionContext;
class IDBAny;
class IDBKey;
class LocalDOMWindow;
class LocalFrame;
class SharedBuffer;
class ScriptPromiseResolver;
class V8ScriptState;
class WebBlobInfo;

class ScriptState : public RefCounted<ScriptState> {
    WTF_MAKE_NONCOPYABLE(ScriptState);
public:
    virtual ~ScriptState() { }

    virtual bool isV8ScriptState() const { return false; }
    virtual bool isDartScriptState() const { return false; }
    virtual V8ScriptState* v8ScriptState() = 0;

    virtual ExecutionContext* executionContext() const = 0;
    virtual LocalDOMWindow* domWindow() const = 0;
    virtual LocalDOMWindow* callingDOMWindow() const = 0;

    virtual PassRefPtr<AbstractScriptValue> createNull() = 0;
    virtual PassRefPtr<AbstractScriptValue> createUndefined() = 0;
    virtual PassRefPtr<AbstractScriptValue> createBoolean(bool value) = 0;
    virtual PassRefPtr<AbstractScriptPromise> createEmptyPromise() = 0;
    virtual PassRefPtr<AbstractScriptPromise> createRejectedPromise(PassRefPtrWillBeRawPtr<DOMException>) = 0;
    virtual PassRefPtr<AbstractScriptPromise> createPromiseRejectedWithTypeError(const String& message) = 0;

    virtual PassOwnPtr<AbstractScriptPromiseResolver> createPromiseResolver(ScriptPromiseResolver*) = 0;
    virtual AbstractScriptStateProtectingContext* createProtectingContext() = 0;
    virtual PassRefPtr<AbstractScriptValue> idbAnyToScriptValue(IDBAny*) = 0;
    virtual PassRefPtr<AbstractScriptValue> idbKeyToScriptValue(IDBKey*) = 0;

    virtual const String* name() = 0;
    virtual intptr_t libraryId() = 0;
    virtual bool isJavaScript() = 0;

#ifndef NDEBUG
    virtual void assertPrimaryKeyValidOrInjectable(PassRefPtr<SharedBuffer>, const Vector<blink::WebBlobInfo>*, IDBKey*, const IDBKeyPath&) = 0;
#endif

protected:
    ScriptState() { }
};

class AbstractScriptStateProtectingContext {
public:
    virtual ~AbstractScriptStateProtectingContext() { }
    virtual ScriptState* get() const = 0;
    virtual void clear() = 0;
protected:
    AbstractScriptStateProtectingContext() { }
};

// ScriptStateProtectingContext keeps the context (V8) or isolate (Dart) associated with the ScriptState alive.
// You need to call clear() once you no longer need the context. Otherwise, the context will leak.
class ScriptStateProtectingContext {
    WTF_MAKE_NONCOPYABLE(ScriptStateProtectingContext);
public:
    ScriptStateProtectingContext(ScriptState* scriptState)
        : m_implProtectingContext(scriptState ? scriptState->createProtectingContext() : 0) { }

    ~ScriptStateProtectingContext()
    {
        clear();
    }

    ScriptState* operator->() const
    {
        return m_implProtectingContext ? m_implProtectingContext->get() : 0;
    }
    ScriptState* get() const
    {
        return m_implProtectingContext ? m_implProtectingContext->get() : 0;
    }
    void clear()
    {
        if (m_implProtectingContext) {
            m_implProtectingContext->clear();
            delete m_implProtectingContext;
            m_implProtectingContext = 0;
        }
    }
private:
    AbstractScriptStateProtectingContext* m_implProtectingContext;
};

} // namespace blink

#endif // ScriptState_h
