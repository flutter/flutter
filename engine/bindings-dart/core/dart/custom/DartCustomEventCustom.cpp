// Copyright 2013, Google Inc.
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//    * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//    * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#include "config.h"
#include "bindings/core/dart/DartCustomEvent.h"

#include "bindings/core/v8/V8Binding.h"

namespace blink {

namespace DartCustomEventInternal {

void detailGetter(Dart_NativeArguments args)
{
    // FIXME: consider if we need complicated logic of v8 counterpart.
    CustomEvent* receiver = DartDOMWrapper::receiver< CustomEvent >(args);

    if (!receiver->serializedDetail()) {
        // The detail field was set in the main V8 isolate. We need to convert
        // it to a SerializedScriptValue here.
        v8::Isolate* v8Isolate = v8::Isolate::GetCurrent();
        v8::Handle<v8::Value> mainWorldDetail = V8HiddenValue::getHiddenValueFromMainWorldWrapper(v8Isolate, receiver, V8HiddenValue::detail(v8Isolate));
        if (!mainWorldDetail.IsEmpty())
            receiver->setSerializedDetail(SerializedScriptValue::createAndSwallowExceptions(mainWorldDetail, v8Isolate));
    }

    Dart_Handle returnValue = DartUtilities::serializedScriptValueToDart(receiver->serializedDetail());
    if (returnValue)
        Dart_SetReturnValue(args, returnValue);
    return;
}

void initCustomEventCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        CustomEvent* receiver = DartDOMWrapper::receiver< CustomEvent >(args);

        DartStringAdapter typeArg = DartUtilities::dartToStringWithNullCheck(args, 1, exception);
        if (exception)
            goto fail;

        bool canBubbleArg = DartUtilities::dartToBool(Dart_GetNativeArgument(args, 2), exception);
        if (exception)
            goto fail;

        bool cancelableArg = DartUtilities::dartToBool(Dart_GetNativeArgument(args, 3), exception);
        if (exception)
            goto fail;

        RefPtr<SerializedScriptValue> detailArg = DartUtilities::dartToSerializedScriptValue(Dart_GetNativeArgument(args, 4), exception);
        if (exception)
            goto fail;

        receiver->initCustomEvent(typeArg, canBubbleArg, cancelableArg, detailArg);
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

}

}
