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

#ifndef CustomElementBinding_h
#define CustomElementBinding_h

#include "bindings/core/v8/ScopedPersistent.h"
#include "wtf/PassOwnPtr.h"
#include <v8.h>

namespace blink {

struct WrapperTypeInfo;

class CustomElementBinding {
public:
    static PassOwnPtr<CustomElementBinding> create(v8::Isolate*, v8::Handle<v8::Object> prototype, const WrapperTypeInfo*);

    ~CustomElementBinding() { }

    v8::Handle<v8::Object> prototype() { return m_prototype.newLocal(m_isolate); }
    const WrapperTypeInfo* wrapperType() { return m_wrapperType; }

private:
    CustomElementBinding(v8::Isolate*, v8::Handle<v8::Object> prototype, const WrapperTypeInfo*);

    v8::Isolate* m_isolate;
    ScopedPersistent<v8::Object> m_prototype;
    const WrapperTypeInfo* m_wrapperType;
};

}

#endif // CustomElementBinding_h
