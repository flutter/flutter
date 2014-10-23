/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "bindings/core/v8/V8ObjectConstructor.h"

#include "bindings/core/v8/V8Binding.h"
#include "bindings/core/v8/V8ScriptRunner.h"
#include "core/dom/Document.h"
#include "core/frame/LocalFrame.h"
#include "platform/TraceEvent.h"


namespace blink {

v8::Local<v8::Object> V8ObjectConstructor::newInstance(v8::Isolate* isolate, v8::Handle<v8::Function> function)
{
    if (function.IsEmpty())
        return v8::Local<v8::Object>();
    ConstructorMode constructorMode(isolate);
    return V8ScriptRunner::instantiateObject(isolate, function);
}

v8::Local<v8::Object> V8ObjectConstructor::newInstance(v8::Isolate* isolate, v8::Handle<v8::Function> function, int argc, v8::Handle<v8::Value> argv[])
{
    if (function.IsEmpty())
        return v8::Local<v8::Object>();
    ConstructorMode constructorMode(isolate);
    return V8ScriptRunner::instantiateObject(isolate, function, argc, argv);
}

v8::Local<v8::Object> V8ObjectConstructor::newInstanceInDocument(v8::Isolate* isolate, v8::Handle<v8::Function> function, int argc, v8::Handle<v8::Value> argv[], Document* document)
{
    if (function.IsEmpty())
        return v8::Local<v8::Object>();
    return V8ScriptRunner::instantiateObjectInDocument(isolate, function, document, argc, argv);
}

void V8ObjectConstructor::isValidConstructorMode(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    if (ConstructorMode::current(info.GetIsolate()) == ConstructorMode::CreateNewObject) {
        V8ThrowException::throwTypeError("Illegal constructor", info.GetIsolate());
        return;
    }
    v8SetReturnValue(info, info.This());
}

} // namespace blink
