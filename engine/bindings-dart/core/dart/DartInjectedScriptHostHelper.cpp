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

#include "config.h"
#include "bindings/core/dart/DartInjectedScriptHostHelper.h"

#include "bindings/core/dart/DartController.h"
#include "bindings/core/dart/DartHandleProxy.h"
#include "bindings/core/dart/DartScriptState.h"
#include "bindings/core/dart/V8Converter.h"
#include "bindings/core/v8/V8HiddenValue.h"

namespace blink {

/**
 * Returns true if the expression passed in my args was evaluated as Dart code.
 */
v8::Handle<v8::Value> DartInjectedScriptHostHelper::evaluateIfDartContext(v8::Handle<v8::Object> v8InjectedScriptHost, v8::Handle<v8::String> expression)
{
    v8::Isolate* v8Isolate = v8::Isolate::GetCurrent();
    ASSERT(!v8Isolate->GetCurrentContext().IsEmpty());

    ScriptState* currentScriptState = 0;
    v8::Local<v8::Value> scriptStateWrapper = V8HiddenValue::getHiddenValue(v8::Isolate::GetCurrent(), v8InjectedScriptHost, V8HiddenValue::scriptState(v8Isolate));
    if (!scriptStateWrapper.IsEmpty() && scriptStateWrapper->IsExternal())
        currentScriptState = static_cast<ScriptState*>(v8::External::Cast(*scriptStateWrapper)->Value());
    else
        currentScriptState = V8ScriptState::current(v8Isolate);

    ExecutionContext* ALLOW_UNUSED scriptExecutionContext = currentScriptState->executionContext();
    ASSERT(scriptExecutionContext);

    if (!currentScriptState->isJavaScript()) {
        DartScriptState* dartScriptState = static_cast<DartScriptState*>(currentScriptState);
        DartIsolateScope scope(dartScriptState->isolate());
        DartApiScope apiScope;

        Dart_Handle target = Dart_GetLibraryFromId(dartScriptState->libraryId());
        return DartHandleProxy::evaluate(target, V8Converter::stringToDart(expression), Dart_Null());
    }
    return v8::Handle<v8::Value>();
}

} // namespace blink
