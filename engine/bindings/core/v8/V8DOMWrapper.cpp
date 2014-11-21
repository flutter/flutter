/*
 * Copyright (C) 2009 Google Inc. All rights reserved.
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

#include "sky/engine/config.h"
#include "sky/engine/bindings/core/v8/V8DOMWrapper.h"

#include "bindings/core/v8/V8HTMLDocument.h"
#include "bindings/core/v8/V8Window.h"
#include "sky/engine/bindings/core/v8/V8Binding.h"
#include "sky/engine/bindings/core/v8/V8ObjectConstructor.h"
#include "sky/engine/bindings/core/v8/V8PerContextData.h"
#include "sky/engine/bindings/core/v8/V8ScriptRunner.h"

namespace blink {

v8::Local<v8::Object> V8DOMWrapper::createWrapper(v8::Handle<v8::Object> creationContext, const WrapperTypeInfo* type, ScriptWrappableBase* internalPointer, v8::Isolate* isolate)
{
    V8WrapperInstantiationScope scope(creationContext, isolate);

    V8PerContextData* data = V8PerContextData::from(scope.context());
    if (data)
        return data->createWrapperFromCache(type);
    return V8ObjectConstructor::newInstance(isolate, type->domTemplate(isolate)->GetFunction());
}

bool V8DOMWrapper::isDOMWrapper(v8::Handle<v8::Value> value)
{
    if (value.IsEmpty() || !value->IsObject())
        return false;

    if (v8::Handle<v8::Object>::Cast(value)->InternalFieldCount() < v8DefaultWrapperInternalFieldCount)
        return false;

    v8::Handle<v8::Object> wrapper = v8::Handle<v8::Object>::Cast(value);
    ASSERT(wrapper->GetAlignedPointerFromInternalField(v8DOMWrapperObjectIndex));
    ASSERT(wrapper->GetAlignedPointerFromInternalField(v8DOMWrapperTypeIndex));

    const WrapperTypeInfo* typeInfo = static_cast<const WrapperTypeInfo*>(wrapper->GetAlignedPointerFromInternalField(v8DOMWrapperTypeIndex));
    // FIXME: We should add a more strict way to check if the typeInfo is a typeInfo of some DOM wrapper.
    // Even if it's a typeInfo of Blink, it's not guaranteed that it's a typeInfo of a DOM wrapper.
    return typeInfo->ginEmbedder == gin::kEmbedderBlink;
}

} // namespace blink
