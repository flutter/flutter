/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
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

#ifndef ScriptFunction_h
#define ScriptFunction_h

#include "bindings/core/v8/ScriptValue.h"
#include "platform/heap/Handle.h"
#include <v8.h>

namespace blink {

// A common way of using ScriptFunction is as follows:
//
// class DerivedFunction : public ScriptFunction {
//     // This returns a V8 function which the DerivedFunction is bound to.
//     // The DerivedFunction is destructed when the V8 function is
//     // garbage-collected.
//     static v8::Handle<v8::Function> createFunction(ScriptState* scriptState)
//     {
//         DerivedFunction* self = new DerivedFunction(scriptState);
//         return self->bindToV8Function();
//     }
// };
class ScriptFunction : public GarbageCollectedFinalized<ScriptFunction> {
public:
    virtual ~ScriptFunction() { }
    ScriptState* scriptState() const { return m_scriptState.get(); }
    virtual void trace(Visitor*) { }

protected:
    explicit ScriptFunction(ScriptState* scriptState)
        : m_scriptState(scriptState)
    {
    }

    v8::Handle<v8::Function> bindToV8Function();

private:
    virtual ScriptValue call(ScriptValue) = 0;
    static void callCallback(const v8::FunctionCallbackInfo<v8::Value>&);

    RefPtr<ScriptState> m_scriptState;
};

} // namespace blink

#endif
