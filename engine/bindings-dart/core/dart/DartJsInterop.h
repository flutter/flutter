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

#ifndef DartJsInterop_h
#define DartJsInterop_h

#include "bindings/core/dart/DartDOMData.h"
#include "bindings/core/dart/DartScriptValue.h"
#include "wtf/RefCounted.h"

#include <dart_api.h>
#include <dart_mirrors_api.h>
#include <v8.h>

namespace blink {

class LocalDOMWindow;
class Node;

class JsInterop {
public:
    static Dart_NativeFunction resolver(Dart_Handle nameHandle, int argumentCount, bool* autoSetupScope);
    static const uint8_t* symbolizer(Dart_NativeFunction);

    static v8::Local<v8::Value> fromDart(DartDOMData*, Dart_Handle, Dart_Handle& exception);
    static Dart_Handle toDart(v8::Local<v8::Value>);
};

class JsObject : public RefCounted<JsObject> {
    WTF_MAKE_NONCOPYABLE(JsObject);
private:
    JsObject(v8::Local<v8::Object> v8Handle);
public:
    static Dart_Handle toDart(v8::Local<v8::Object>);
    static Dart_Handle toDart(PassRefPtr<JsObject>);

    ~JsObject();

    static PassRefPtr<JsObject> create(v8::Local<v8::Object> v8Handle);

    v8::Local<v8::Object> localV8Object();

    static const int dartClassId;
    static const bool isNode = false;
    static const bool isEventTarget = false;
    static const bool isActive = false;
    static const bool isGarbageCollected = false;

    typedef JsObject NativeType;
    friend class JsFunction;
    friend class JsArray;
private:
    v8::Persistent<v8::Object> v8Object;
};

class JsFunction : public JsObject {
    WTF_MAKE_NONCOPYABLE(JsFunction);
private:
    JsFunction(v8::Local<v8::Function> v8Handle);

public:
    static Dart_Handle toDart(PassRefPtr<JsFunction> jsObject);

    static PassRefPtr<JsFunction> create(v8::Local<v8::Function> v8Handle);

    v8::Local<v8::Function> localV8Function();

    static const int dartClassId;
    static const bool isNode = false;
    static const bool isEventTarget = false;
    static const bool isActive = false;
    static const bool isGarbageCollected = false;

    typedef JsFunction NativeType;
};

class JsArray : public JsObject {
    WTF_MAKE_NONCOPYABLE(JsArray);
private:
    JsArray(v8::Local<v8::Array> v8Handle);

public:
    static Dart_Handle toDart(PassRefPtr<JsArray> jsObject);

    static PassRefPtr<JsArray> create(v8::Local<v8::Array> v8Handle);

    v8::Local<v8::Array> localV8Array();

    static const int dartClassId;
    static const bool isNode = false;
    static const bool isEventTarget = false;
    static const bool isActive = false;
    static const bool isGarbageCollected = false;

    typedef JsArray NativeType;
};

}

#endif // DartJsInterop_h
