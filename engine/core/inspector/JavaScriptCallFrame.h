/*
 * Copyright (c) 2010, Google Inc. All rights reserved.
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

#ifndef SKY_ENGINE_CORE_INSPECTOR_JAVASCRIPTCALLFRAME_H_
#define SKY_ENGINE_CORE_INSPECTOR_JAVASCRIPTCALLFRAME_H_

#include "sky/engine/bindings/core/v8/ScopedPersistent.h"
#include "sky/engine/bindings/core/v8/ScriptState.h"
#include "sky/engine/bindings/core/v8/ScriptWrappable.h"
#include "sky/engine/wtf/RefCounted.h"
#include "sky/engine/wtf/text/WTFString.h"
#include "v8/include/v8.h"

namespace blink {

class ScriptValue;

class JavaScriptCallFrame : public RefCounted<JavaScriptCallFrame>, public ScriptWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtr<JavaScriptCallFrame> create(v8::Handle<v8::Context> debuggerContext, v8::Handle<v8::Object> callFrame)
    {
        return adoptRef(new JavaScriptCallFrame(debuggerContext, callFrame));
    }
    ~JavaScriptCallFrame();

    JavaScriptCallFrame* caller();

    int sourceID() const;
    int line() const;
    int column() const;
    String scriptName() const;
    String functionName() const;

    v8::Handle<v8::Value> scopeChain() const;
    int scopeType(int scopeIndex) const;
    v8::Handle<v8::Value> thisObject() const;
    String stepInPositions() const;
    bool isAtReturn() const;
    v8::Handle<v8::Value> returnValue() const;

    v8::Handle<v8::Value> evaluateWithExceptionDetails(const String& expression);
    v8::Handle<v8::Value> restart();
    ScriptValue setVariableValue(ScriptState*, int scopeNumber, const String& variableName, const ScriptValue& newValue);

    static v8::Handle<v8::Object> createExceptionDetails(v8::Handle<v8::Message>, v8::Isolate*);

private:
    JavaScriptCallFrame(v8::Handle<v8::Context> debuggerContext, v8::Handle<v8::Object> callFrame);

    int callV8FunctionReturnInt(const char* name) const;
    String callV8FunctionReturnString(const char* name) const;

    v8::Isolate* m_isolate;
    RefPtr<JavaScriptCallFrame> m_caller;
    ScopedPersistent<v8::Context> m_debuggerContext;
    ScopedPersistent<v8::Object> m_callFrame;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_INSPECTOR_JAVASCRIPTCALLFRAME_H_
