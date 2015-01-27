// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef AbstractScriptPromise_h
#define AbstractScriptPromise_h

#include "bindings/core/v8/ScriptFunction.h"
#include "platform/heap/Handle.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/PassRefPtr.h"
#include <v8.h>

namespace blink {

class AbstractScriptPromise : public RefCounted<AbstractScriptPromise> {
    WTF_MAKE_NONCOPYABLE(AbstractScriptPromise);
public:
    virtual ~AbstractScriptPromise() { }

    virtual PassRefPtr<AbstractScriptPromise> then(PassOwnPtr<ScriptFunction> onFulfilled, PassOwnPtr<ScriptFunction> onRejected = PassOwnPtr<ScriptFunction>()) = 0;

    virtual bool isDartScriptPromise() const { return false; }
    virtual bool isV8ScriptPromise() const { return false; }
    virtual bool equals(PassRefPtr<AbstractScriptPromise>) const = 0;

    virtual bool isObject() const = 0;
    virtual bool isNull() const = 0;
    virtual bool isUndefinedOrNull() const = 0;
    virtual bool isEmpty() const = 0;
    virtual void clear() = 0;

    // FIXMEMULTIVM: Remove.
    virtual v8::Handle<v8::Value> v8Value() const = 0;
    virtual v8::Isolate* isolate() const = 0;

protected:
    AbstractScriptPromise() { }
};

} // namespace blink

#endif // AbstractScriptPromise_h
