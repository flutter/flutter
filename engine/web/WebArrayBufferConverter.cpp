/*
 * Copyright (C) 2014 Google Inc. All rights reserved.
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

#include "config.h"
#include "public/web/WebArrayBufferConverter.h"

#include "bindings/core/v8/custom/V8ArrayBufferCustom.h"
#include "wtf/ArrayBuffer.h"
#include "wtf/PassOwnPtr.h"

namespace blink {

v8::Handle<v8::Value> WebArrayBufferConverter::toV8Value(WebArrayBuffer* buffer, v8::Handle<v8::Object> creationContext, v8::Isolate* isolate)
{
    if (!buffer)
        return v8::Handle<v8::Value>();
    return toV8(*buffer, creationContext, isolate);
}

WebArrayBuffer* WebArrayBufferConverter::createFromV8Value(v8::Handle<v8::Value> value, v8::Isolate* isolate)
{
    if (!V8ArrayBuffer::hasInstance(value, isolate))
        return 0;
    ArrayBuffer* buffer = V8ArrayBuffer::toNative(value->ToObject());
    return new WebArrayBuffer(buffer);
}

} // namespace blink

