/*
 * Copyright (C) 2007-2009 Google Inc. All rights reserved.
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

#ifndef ScheduledAction_h
#define ScheduledAction_h

#include "sky/engine/bindings/core/v8/ScopedPersistent.h"
#include "sky/engine/bindings/core/v8/ScriptSourceCode.h"
#include "sky/engine/bindings/core/v8/ScriptState.h"
#include "sky/engine/bindings/core/v8/V8PersistentValueVector.h"
#include "sky/engine/wtf/Forward.h"
#include "v8/include/v8.h"

namespace blink {

class LocalFrame;
class ExecutionContext;

class ScheduledAction {
    WTF_MAKE_NONCOPYABLE(ScheduledAction);
public:
    ScheduledAction(ScriptState*, v8::Handle<v8::Function>, int argc, v8::Handle<v8::Value> argv[], v8::Isolate*);
    ScheduledAction(ScriptState*, const String&, const KURL&, v8::Isolate*);
    ~ScheduledAction();

    void execute(ExecutionContext*);

private:
    void execute(LocalFrame*);
    void createLocalHandlesForArgs(Vector<v8::Handle<v8::Value> >* handles);

    ScriptStateProtectingContext m_scriptState;
    ScopedPersistent<v8::Function> m_function;
    V8PersistentValueVector<v8::Value> m_info;
    ScriptSourceCode m_code;
};

} // namespace blink

#endif // ScheduledAction
