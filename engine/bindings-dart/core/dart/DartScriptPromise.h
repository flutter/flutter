// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef DartScriptPromise_h
#define DartScriptPromise_h

#include "bindings/common/AbstractScriptPromise.h"
#include "bindings/common/ScriptValue.h"
#include "bindings/core/v8/ScriptFunction.h"
#include "core/dom/ExceptionCode.h"
#include "platform/heap/Handle.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/PassRefPtr.h"
#include "wtf/text/WTFString.h"
#include <dart_api.h>

namespace blink {

class DOMException;
class ExceptionState;

class DartScriptPromise FINAL : public AbstractScriptPromise {
    WTF_MAKE_NONCOPYABLE(DartScriptPromise);
public:
    static PassRefPtr<DartScriptPromise> create()
    {
        return adoptRef(new DartScriptPromise());
    }

    static PassRefPtr<DartScriptPromise> create(DartScriptState* scriptState, Dart_Handle promise)
    {
        return adoptRef(new DartScriptPromise(scriptState, promise));
    }

    static void returnToDart(Dart_NativeArguments args, ScriptPromise promise, bool autoScope);

private:
    // Constructs an empty promise.
    DartScriptPromise() : m_scriptState() , m_value(0) { }

    // Constructs a ScriptPromise from |promise|.
    // If |promise| is not a Promise object, throws a v8 TypeError.
    DartScriptPromise(DartScriptState*, Dart_Handle promise);

public:
    PassRefPtr<AbstractScriptPromise> then(PassOwnPtr<ScriptFunction> onFulfilled, PassOwnPtr<ScriptFunction> onRejected = PassOwnPtr<ScriptFunction>());

    bool isDartScriptPromise() const { return true; }

    bool equals(PassRefPtr<AbstractScriptPromise> other) const
    {
        if (!other->isDartScriptPromise())
            return false;
        return *this == *static_cast<DartScriptPromise*>(other.get());
    }

    bool isObject() const
    {
        ASSERT(!isEmpty());
        return true;
    }

    bool isNull() const
    {
        ASSERT(!isEmpty());
        return Dart_IsNull(dartValue());
    }

    bool isUndefinedOrNull() const
    {
        ASSERT(!isEmpty());
        return Dart_IsNull(dartValue());
    }

    bool isEmpty() const
    {
        return !dartValue();
    }

    void clear()
    {
        m_value.clear();
    }

    bool operator==(const DartScriptPromise& value) const
    {
        return Dart_IdentityEquals(dartValue(), value.dartValue());
    }

    bool operator!=(const DartScriptPromise& value) const
    {
        return !operator==(value);
    }

    Dart_Handle dartValue() const { return m_value.value(); }

    v8::Handle<v8::Value> v8Value() const
    {
        RELEASE_ASSERT_NOT_REACHED();
        return v8::Handle<v8::Value>();
    }

    v8::Isolate* isolate() const
    {
        RELEASE_ASSERT_NOT_REACHED();
        return m_scriptState->v8ScriptState()->isolate();
    }

private:
    RefPtr<DartScriptState> m_scriptState;
    DartPersistentValue m_value;
};

} // namespace blink

#endif // DartScriptPromise_h
