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

#ifndef WebDOMError_h
#define WebDOMError_h

#include "public/platform/WebCommon.h"
#include "public/platform/WebPrivatePtr.h"
#include "public/platform/WebString.h"

namespace v8 {
class Isolate;
class Object;
class Value;
template <class T> class Handle;
}

namespace blink {

class DOMError;

class WebDOMError {
public:
    ~WebDOMError() { reset(); }

    WebDOMError() { }
    WebDOMError(const WebDOMError& b) { assign(b); }
    WebDOMError& operator=(const WebDOMError& b)
    {
        assign(b);
        return *this;
    }

    BLINK_EXPORT static WebDOMError create(const WebString& name, const WebString& message);

    BLINK_EXPORT void reset();
    BLINK_EXPORT void assign(const WebDOMError&);

    BLINK_EXPORT WebString name() const;
    BLINK_EXPORT WebString message() const;

    BLINK_EXPORT v8::Handle<v8::Value> toV8Value(v8::Handle<v8::Object> creationContext, v8::Isolate*);

#if BLINK_IMPLEMENTATION
    explicit WebDOMError(const PassRefPtrWillBeRawPtr<DOMError>&);
    WebDOMError& operator=(const PassRefPtrWillBeRawPtr<DOMError>&);
#endif

protected:
    WebPrivatePtr<DOMError> m_private;
};

} // namespace blink

#endif // WebDOMError_h
