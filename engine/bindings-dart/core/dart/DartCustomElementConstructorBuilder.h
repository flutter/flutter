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

#ifndef DartCustomElementConstructorBuilder_h
#define DartCustomElementConstructorBuilder_h

#include "bindings/core/v8/CustomElementConstructorBuilder.h"

#include <dart_api.h>
#include <v8.h>

namespace blink {

class CustomElementDefinition;
class DartCustomElementLifecycleCallbacks;
class Dictionary;
class Document;
class ExceptionState;
class QualifiedName;
class ScriptState;


// Handles the scripting-specific parts of the Custom Elements element
// registration algorithm and constructor generation algorithm. It is
// used in the implementation of those algorithms in
// Document::registerElement.
class DartCustomElementConstructorBuilder : public CustomElementConstructorBuilder {
    WTF_MAKE_NONCOPYABLE(DartCustomElementConstructorBuilder);
public:
    DartCustomElementConstructorBuilder(Dart_Handle type, const AtomicString& extendsTagName, DartScriptState*, const Dictionary* options);
    virtual ~DartCustomElementConstructorBuilder() { }

    // The builder accumulates state and may run script at specific
    // points. These methods must be called in order. When one fails
    // (returns false), the calls must stop.

    virtual bool isFeatureAllowed() const;
    virtual bool validateOptions(const AtomicString& type, QualifiedName& tagName, ExceptionState&);
    virtual bool findTagName(const AtomicString& customElementType, QualifiedName& tagName);
    virtual PassRefPtr<CustomElementLifecycleCallbacks> createCallbacks();
    virtual bool createConstructor(Document*, CustomElementDefinition*, ExceptionState&);
    virtual bool didRegisterDefinition(CustomElementDefinition*) const;

    // This method collects a return value for the bindings. It is
    // safe to call this method even if the builder failed; it will
    // return an empty value.
    virtual ScriptValue bindingsReturnValue() const;

private:
    Dart_Handle m_customType;
    intptr_t m_nativeClassId;
    AtomicString m_namespaceURI;
    AtomicString m_extendsTagName;
    AtomicString m_localName;
    RefPtr<DartScriptState> m_scriptState;
    RefPtr<DartCustomElementLifecycleCallbacks> m_callbacks;
};

}

#endif // DartCustomElementConstructorBuilder_h
