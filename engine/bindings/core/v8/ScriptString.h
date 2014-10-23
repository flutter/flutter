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

#ifndef ScriptString_h
#define ScriptString_h

#include "bindings/core/v8/SharedPersistent.h"
#include "wtf/RefPtr.h"
#include "wtf/text/WTFString.h"
#include <v8.h>

namespace blink {

class ScriptString FINAL {
public:
    ScriptString();
    ScriptString(v8::Isolate*, v8::Handle<v8::String>);
    ScriptString& operator=(const ScriptString&);

    v8::Isolate* isolate()
    {
        if (!m_isolate)
            m_isolate = v8::Isolate::GetCurrent();
        return m_isolate;
    }
    bool isEmpty() const { return !m_string || m_string->isEmpty(); }
    void clear() { m_string = nullptr; }
    v8::Handle<v8::String> v8Value();
    ScriptString concatenateWith(const String&);
    String flattenToString();

private:
    v8::Isolate* m_isolate;
    RefPtr<SharedPersistent<v8::String> > m_string;
};

} // namespace blink

#endif // ScriptString_h
