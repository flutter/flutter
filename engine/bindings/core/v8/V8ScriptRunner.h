/*
 * Copyright (C) 2009 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef V8ScriptRunner_h
#define V8ScriptRunner_h

#include "sky/engine/bindings/core/v8/V8CacheOptions.h"
#include "sky/engine/wtf/PassOwnPtr.h"
#include "sky/engine/wtf/text/TextPosition.h"
#include "sky/engine/wtf/text/WTFString.h"
#include "v8/include/v8.h"

namespace blink {

class ScriptSourceCode;
class ExecutionContext;

struct V8ScriptModule {
    String resourceName;
    TextPosition textPosition;
    v8::Handle<v8::Value> moduleObject;
    String source;
    Vector<String> formalDependencies;
    Vector<v8::Handle<v8::Value> > resolvedDependencies;
};

class V8ScriptRunner {
public:
    // For the following methods, the caller sites have to hold
    // a HandleScope and a ContextScope.
    static v8::Local<v8::Script> compileScript(const ScriptSourceCode&, v8::Isolate*, V8CacheOptions = V8CacheOptionsOff);
    static v8::Local<v8::Script> compileScript(v8::Handle<v8::String>, const String& fileName, const TextPosition&, v8::Isolate*, V8CacheOptions = V8CacheOptionsOff);
    static v8::Local<v8::Value> runCompiledScript(v8::Handle<v8::Script>, ExecutionContext*, v8::Isolate*);
    static v8::Local<v8::Value> compileAndRunInternalScript(v8::Handle<v8::String>, v8::Isolate*, const String& = String(), const TextPosition& = TextPosition());
    static v8::Local<v8::Value> runCompiledInternalScript(v8::Handle<v8::Script>, v8::Isolate*);
    static v8::Local<v8::Value> callInternalFunction(v8::Handle<v8::Function>, v8::Handle<v8::Value> receiver, int argc, v8::Handle<v8::Value> info[], v8::Isolate*);
    static v8::Local<v8::Value> callFunction(v8::Handle<v8::Function>, ExecutionContext*, v8::Handle<v8::Value> receiver, int argc, v8::Handle<v8::Value> info[], v8::Isolate*);
    static v8::Local<v8::Value> callAsFunction(v8::Isolate*, v8::Handle<v8::Object>, v8::Handle<v8::Value> receiver, int argc, v8::Handle<v8::Value> info[]);
    static v8::Local<v8::Object> instantiateObject(v8::Isolate*, v8::Handle<v8::ObjectTemplate>);
    static v8::Local<v8::Object> instantiateObject(v8::Isolate*, v8::Handle<v8::Function>, int argc = 0, v8::Handle<v8::Value> argv[] = 0);
    static v8::Local<v8::Object> instantiateObjectInDocument(v8::Isolate*, v8::Handle<v8::Function>, ExecutionContext*, int argc = 0, v8::Handle<v8::Value> argv[] = 0);

    static void runModule(v8::Isolate*, ExecutionContext*, V8ScriptModule&);
};

} // namespace blink

#endif // V8ScriptRunner_h
