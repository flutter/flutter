// Copyright 2011, Google Inc.
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
#include "bindings/core/dart/DartMessageEvent.h"

#include "bindings/core/dart/DartBlob.h"
#include "bindings/core/dart/DartWindow.h"
#include "bindings/core/dart/V8Converter.h"
#include "bindings/core/v8/ScriptController.h"
#include "bindings/dart/DartWebkitClassIds.h"

namespace blink {

Dart_Handle DartMessageEvent::createWrapper(DartDOMData* domData, MessageEvent* event)
{
    // The V8 custom method also appears to do some memory usage tracking.
    // FIXMEDART: implement the same sort of tracking for Dart.
    return DartDOMWrapper::createWrapper<DartMessageEvent>(
            domData, event, MessageEventClassId);
}

namespace DartMessageEventInternal {

void dataGetter(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        MessageEvent* receiver = DartDOMWrapper::receiver<MessageEvent>(args);

        Dart_Handle result = Dart_Null();
        switch (receiver->dataType()) {
        case MessageEvent::DataTypeScriptValue:
        case MessageEvent::DataTypeSerializedScriptValue: {
            v8::Isolate* v8Isolate = v8::Isolate::GetCurrent();
            v8::HandleScope handleScope(v8Isolate);
            v8::Context::Scope scope(toV8Context(DartUtilities::domWindowForCurrentIsolate()->frame(), DOMWrapperWorld::mainWorld()));
            RefPtr<SerializedScriptValue> serializedValue = receiver->dataAsSerializedScriptValue();
            if (!serializedValue)
                break;
            MessagePortArray ports = receiver->ports();
            result = V8Converter::toDart(serializedValue->deserialize(&ports), exception);
            if (exception)
                goto fail;
            break;
        }

        case MessageEvent::DataTypeString:
            DartUtilities::setDartStringReturnValue(args, receiver->dataAsString());
            return;

        case MessageEvent::DataTypeBlob:
            result = DartBlob::toDart(receiver->dataAsBlob());
            break;

        case MessageEvent::DataTypeArrayBuffer:
            result = DartUtilities::arrayBufferToDart(receiver->dataAsArrayBuffer());
            break;
        }
        // FIXME: cache the result.
        Dart_SetReturnValue(args, result);
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

void initMessageEventCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        MessageEvent* receiver = DartDOMWrapper::receiver<MessageEvent>(args);

        DartStringAdapter typeArg = DartUtilities::dartToString(args, 1, exception);
        if (exception)
            goto fail;

        bool canBubbleArg = DartUtilities::dartToBool(args, 2, exception);
        if (exception)
            goto fail;

        bool cancelableArg = DartUtilities::dartToBool(args, 3, exception);
        if (exception)
            goto fail;

        RefPtr<SerializedScriptValue> dataArg = DartUtilities::dartToSerializedScriptValue(Dart_GetNativeArgument(args, 4), exception);
        if (exception)
            goto fail;

        DartStringAdapter originArg = DartUtilities::dartToString(args, 5, exception);
        if (exception)
            goto fail;

        DartStringAdapter lastEventIdArg = DartUtilities::dartToString(args, 6, exception);
        if (exception)
            goto fail;

        LocalDOMWindow* sourceArg = DartWindow::toNativeWithNullCheck(Dart_GetNativeArgument(args, 7), exception);
        if (exception)
            goto fail;

        OwnPtr<MessagePortArray> portArray;
        if (!Dart_IsNull(Dart_GetNativeArgument(args, 8))) {
            portArray = adoptPtr(new MessagePortArray);
            ArrayBufferArray bufferArray;
            DartUtilities::toMessagePortArray(Dart_GetNativeArgument(args, 8), *portArray, bufferArray, exception);
            if (exception)
                goto fail;
            if (bufferArray.size() > 0) {
                exception = Dart_NewStringFromCString("MessagePortArray argument must contain only MessagePorts");
                goto fail;
            }
        }

        receiver->initMessageEvent(typeArg, canBubbleArg, cancelableArg, dataArg, originArg, lastEventIdArg, sourceArg, portArray.release());
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

}

}
