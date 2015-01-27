/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
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

#ifndef DartHandleProxy_h
#define DartHandleProxy_h

#include "bindings/core/dart/DartUtilities.h"
#include "bindings/core/v8/ScriptSourceCode.h"

#include <dart_api.h>
#include <dart_debugger_api.h>
#include <dart_mirrors_api.h>
#include <v8.h>

namespace blink {

class Node;
class DartPersistentValue;

class DartHandleProxy {
public:
    static v8::Handle<v8::Value> create(Dart_Handle value);
    static v8::Handle<v8::Value> createTypeProxy(Dart_Handle value, bool showStatics);
    static v8::Handle<v8::Value> createLibraryProxy(Dart_Handle value, intptr_t libraryId, Dart_Handle prefix, bool asGlobal);
    static v8::Handle<v8::Value> createLocalScopeProxy(Dart_Handle localVariables);
    static v8::Handle<v8::Value> evaluate(Dart_Handle target, Dart_Handle expression, Dart_Handle localVariables);

    static bool isDartProxy(v8::Handle<v8::Value>);
    static const char* getJavaScriptType(v8::Handle<v8::Value>);
    static Node* toNativeNode(v8::Handle<v8::Value>);
    static Dart_Handle unwrapValue(v8::Handle<v8::Value>);

    static DartPersistentValue* readPointerFromProxy(v8::Handle<v8::Value>);
    static void writePointerToProxy(v8::Local<v8::Object> proxy, Dart_Handle);

    struct CallbackData;
};

/**
 * Helper class to manage all scopes that must be entered to safely invoke Dart
 * code.
 */
class DartScopes {
private:
    DartPersistentValue* scriptValue;
    DartIsolateScope scope;
    DartApiScope apiScope;
    Dart_ExceptionPauseInfo previousPauseInfo;
    bool disableBreak;

public:
    Dart_PersistentHandle handle;

    DartScopes(v8::Local<v8::Object> v8Handle, bool disableBreak = false);
    ~DartScopes();
};

}

#endif // DartHandleProxy_h
