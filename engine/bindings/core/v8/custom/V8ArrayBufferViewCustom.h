/*
 * Copyright (C) 2009, 2011 Google Inc. All rights reserved.
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

#ifndef SKY_ENGINE_BINDINGS_CORE_V8_CUSTOM_V8ARRAYBUFFERVIEWCUSTOM_H_
#define SKY_ENGINE_BINDINGS_CORE_V8_CUSTOM_V8ARRAYBUFFERVIEWCUSTOM_H_

#include "sky/engine/bindings/core/v8/V8Binding.h"
#include "sky/engine/bindings/core/v8/V8ObjectConstructor.h"
#include "sky/engine/bindings/core/v8/custom/V8ArrayBufferCustom.h"
#include "sky/engine/core/dom/ExceptionCode.h"
#include "sky/engine/wtf/ArrayBuffer.h"
#include "sky/engine/wtf/ArrayBufferView.h"

namespace blink {


class V8ArrayBufferView {
public:
    static bool hasInstance(v8::Handle<v8::Value> value, v8::Isolate*)
    {
        return value->IsArrayBufferView();
    }
    static ArrayBufferView* toNative(v8::Handle<v8::Object>);
    static ArrayBufferView* toNativeWithTypeCheck(v8::Isolate*, v8::Handle<v8::Value>);

    static inline void* toScriptWrappableBase(ArrayBufferView* impl)
    {
        return impl;
    }
};


} // namespace blink
#endif  // SKY_ENGINE_BINDINGS_CORE_V8_CUSTOM_V8ARRAYBUFFERVIEWCUSTOM_H_
