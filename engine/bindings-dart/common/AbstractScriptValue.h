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

#ifndef AbstractScriptValue_h
#define AbstractScriptValue_h

#include "platform/heap/Handle.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefPtr.h"
#include "wtf/text/WTFString.h"

namespace blink {

class AbstractScriptPromise;
class IDBKey;
class IDBKeyPath;
class IDBKeyRange;
class JSONValue;
class ScriptState;

class AbstractScriptValue : public RefCounted<AbstractScriptValue> {
    WTF_MAKE_NONCOPYABLE(AbstractScriptValue);
public:
    AbstractScriptValue() { }
    virtual ~AbstractScriptValue() { }

    virtual bool isV8() const { return false; };
    virtual bool isDart() const { return false; };
    virtual bool equals(AbstractScriptValue* other) const = 0;

    virtual ScriptState* scriptState() const = 0;
    virtual void clear() = 0;
    virtual bool isObject() const = 0;
    virtual bool isUndefined() const = 0;
    virtual bool isFunction() const = 0;
    virtual bool isNull() const = 0;
    virtual bool isEmpty() const = 0;

    virtual bool toString(String& result) const = 0;
    virtual PassRefPtr<JSONValue> toJSONValue(ScriptState* state) const = 0;

    virtual PassRefPtr<AbstractScriptPromise> toPromise() const = 0;
    virtual PassRefPtr<AbstractScriptPromise> toRejectedPromise() const = 0;

    virtual IDBKey* createIDBKeyFromKeyPath(const IDBKeyPath&) = 0;
    virtual bool canInjectIDBKey(const IDBKeyPath&) = 0;
    virtual IDBKey* toIDBKey() = 0;
    virtual IDBKeyRange* toIDBKeyRange() = 0;
};

} // namespace blink

#endif // AbstractScriptValue_h
