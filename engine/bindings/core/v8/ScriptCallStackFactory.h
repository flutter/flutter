/*
 * Copyright (c) 2010 Google Inc. All rights reserved.
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

#ifndef ScriptCallStackFactory_h
#define ScriptCallStackFactory_h

#include "core/inspector/ScriptCallStack.h"
#include "wtf/Forward.h"
#include <v8.h>

namespace blink {

class ScriptArguments;
class ScriptCallStack;
class ScriptState;

const v8::StackTrace::StackTraceOptions stackTraceOptions = static_cast<v8::StackTrace::StackTraceOptions>(
      v8::StackTrace::kLineNumber
    | v8::StackTrace::kColumnOffset
    | v8::StackTrace::kScriptId
    | v8::StackTrace::kScriptNameOrSourceURL
    | v8::StackTrace::kFunctionName);

PassRefPtrWillBeRawPtr<ScriptCallStack> createScriptCallStack(v8::Handle<v8::StackTrace>, size_t maxStackSize, v8::Isolate*);
PassRefPtrWillBeRawPtr<ScriptCallStack> createScriptCallStack(size_t maxStackSize, bool emptyStackIsAllowed = false);
PassRefPtrWillBeRawPtr<ScriptCallStack> createScriptCallStackForConsole(size_t maxStackSize = ScriptCallStack::maxCallStackSizeToCapture, bool emptyStackIsAllowed = false);
PassRefPtrWillBeRawPtr<ScriptArguments> createScriptArguments(ScriptState*, const v8::FunctionCallbackInfo<v8::Value>& v8arguments, unsigned skipArgumentCount);

} // namespace blink

#endif // ScriptCallStackFactory_h
