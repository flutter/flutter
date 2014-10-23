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

#include "config.h"
#include "bindings/core/v8/V8History.h"

#include "bindings/core/v8/ExceptionState.h"
#include "bindings/core/v8/SerializedScriptValue.h"
#include "bindings/core/v8/V8Binding.h"
#include "bindings/core/v8/V8HiddenValue.h"
#include "bindings/core/v8/V8Window.h"
#include "core/dom/ExceptionCode.h"
#include "core/frame/History.h"

namespace blink {

void V8History::stateAttributeGetterCustom(const v8::PropertyCallbackInfo<v8::Value>& info)
{
    History* history = V8History::toNative(info.Holder());

    v8::Handle<v8::Value> value = V8HiddenValue::getHiddenValue(info.GetIsolate(), info.Holder(), V8HiddenValue::state(info.GetIsolate()));

    if (!value.IsEmpty() && !history->stateChanged()) {
        v8SetReturnValue(info, value);
        return;
    }

    RefPtr<SerializedScriptValue> serialized = history->state();
    value = serialized ? serialized->deserialize(info.GetIsolate()) : v8::Handle<v8::Value>(v8::Null(info.GetIsolate()));
    V8HiddenValue::setHiddenValue(info.GetIsolate(), info.Holder(), V8HiddenValue::state(info.GetIsolate()), value);

    v8SetReturnValue(info, value);
}

void V8History::pushStateMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    ExceptionState exceptionState(ExceptionState::ExecutionContext, "pushState", "History", info.Holder(), info.GetIsolate());
    RefPtr<SerializedScriptValue> historyState = SerializedScriptValue::create(info[0], 0, exceptionState, info.GetIsolate());
    if (exceptionState.throwIfNeeded())
        return;

    TOSTRING_VOID(V8StringResource<TreatNullAndUndefinedAsNullString>, title, info[1]);
    TOSTRING_VOID(V8StringResource<TreatNullAndUndefinedAsNullString>, url, info[2]);

    History* history = V8History::toNative(info.Holder());
    history->stateObjectAdded(historyState.release(), title, url, FrameLoadTypeStandard, exceptionState);
    V8HiddenValue::deleteHiddenValue(info.GetIsolate(), info.Holder(), V8HiddenValue::state(info.GetIsolate()));
    exceptionState.throwIfNeeded();
}

void V8History::replaceStateMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    // FIXME(sky): re-implement.
}

} // namespace blink
