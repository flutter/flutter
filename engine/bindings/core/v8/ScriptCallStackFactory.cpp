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

#include "sky/engine/config.h"
#include "sky/engine/bindings/core/v8/ScriptCallStackFactory.h"

#include "sky/engine/bindings/core/v8/ScriptValue.h"
#include "sky/engine/bindings/core/v8/V8Binding.h"
#include "sky/engine/core/inspector/ScriptArguments.h"
#include "sky/engine/core/inspector/ScriptCallFrame.h"
#include "sky/engine/core/inspector/ScriptCallStack.h"
#include "sky/engine/platform/JSONValues.h"
#include "sky/engine/wtf/text/StringBuilder.h"
#include "v8/include/v8-debug.h"

namespace blink {

class ExecutionContext;

static ScriptCallFrame toScriptCallFrame(v8::Handle<v8::StackFrame> frame)
{
    StringBuilder stringBuilder;
    stringBuilder.appendNumber(frame->GetScriptId());
    String scriptId = stringBuilder.toString();
    String sourceName;
    v8::Local<v8::String> sourceNameValue(frame->GetScriptNameOrSourceURL());
    if (!sourceNameValue.IsEmpty())
        sourceName = toCoreString(sourceNameValue);

    String functionName;
    v8::Local<v8::String> functionNameValue(frame->GetFunctionName());
    if (!functionNameValue.IsEmpty())
        functionName = toCoreString(functionNameValue);

    int sourceLineNumber = frame->GetLineNumber();
    int sourceColumn = frame->GetColumn();
    return ScriptCallFrame(functionName, scriptId, sourceName, sourceLineNumber, sourceColumn);
}

static void toScriptCallFramesVector(v8::Handle<v8::StackTrace> stackTrace, Vector<ScriptCallFrame>& scriptCallFrames, size_t maxStackSize, bool emptyStackIsAllowed, v8::Isolate* isolate)
{
    ASSERT(isolate->InContext());
    int frameCount = stackTrace->GetFrameCount();
    if (frameCount > static_cast<int>(maxStackSize))
        frameCount = maxStackSize;
    for (int i = 0; i < frameCount; i++) {
        v8::Local<v8::StackFrame> stackFrame = stackTrace->GetFrame(i);
        scriptCallFrames.append(toScriptCallFrame(stackFrame));
    }
    if (!frameCount && !emptyStackIsAllowed) {
        // Successfully grabbed stack trace, but there are no frames. It may happen in case
        // when a bound function is called from native code for example.
        // Fallback to setting lineNumber to 0, and source and function name to "undefined".
        scriptCallFrames.append(ScriptCallFrame());
    }
}

static PassRefPtr<ScriptCallStack> createScriptCallStack(v8::Handle<v8::StackTrace> stackTrace, size_t maxStackSize, bool emptyStackIsAllowed, v8::Isolate* isolate)
{
    ASSERT(isolate->InContext());
    v8::HandleScope scope(isolate);
    Vector<ScriptCallFrame> scriptCallFrames;
    toScriptCallFramesVector(stackTrace, scriptCallFrames, maxStackSize, emptyStackIsAllowed, isolate);
    RefPtr<ScriptCallStack> callStack = ScriptCallStack::create(scriptCallFrames);
    return callStack.release();
}

PassRefPtr<ScriptCallStack> createScriptCallStack(v8::Handle<v8::StackTrace> stackTrace, size_t maxStackSize, v8::Isolate* isolate)
{
    return createScriptCallStack(stackTrace, maxStackSize, true, isolate);
}

PassRefPtr<ScriptCallStack> createScriptCallStack(size_t maxStackSize, bool emptyStackIsAllowed)
{
    v8::Isolate* isolate = v8::Isolate::GetCurrent();
    if (!isolate->InContext())
        return nullptr;
    v8::HandleScope handleScope(isolate);
    v8::Handle<v8::StackTrace> stackTrace(v8::StackTrace::CurrentStackTrace(isolate, maxStackSize, stackTraceOptions));
    return createScriptCallStack(stackTrace, maxStackSize, emptyStackIsAllowed, isolate);
}

PassRefPtr<ScriptCallStack> createScriptCallStackForConsole(size_t maxStackSize, bool emptyStackIsAllowed)
{
    size_t stackSize = 1;
    return createScriptCallStack(stackSize, emptyStackIsAllowed);
}

PassRefPtr<ScriptArguments> createScriptArguments(ScriptState* scriptState, const v8::FunctionCallbackInfo<v8::Value>& v8arguments, unsigned skipArgumentCount)
{
    Vector<ScriptValue> arguments;
    for (int i = skipArgumentCount; i < v8arguments.Length(); ++i)
        arguments.append(ScriptValue(scriptState, v8arguments[i]));

    return ScriptArguments::create(scriptState, arguments);
}

} // namespace blink
