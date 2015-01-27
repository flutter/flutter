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
#include "bindings/core/dart/DartXMLHttpRequest.h"

#include "bindings/core/dart/DartBlob.h"
#include "bindings/core/dart/DartDOMWrapper.h"
#include "bindings/core/dart/DartDocument.h"
#include "bindings/core/dart/DartFormData.h"
#include "bindings/core/dart/DartStream.h"
#include "bindings/core/dart/DartUtilities.h"
#include "bindings/core/dart/V8Converter.h"
#include "core/dom/ExecutionContext.h"
#include "core/xml/XMLHttpRequest.h"

namespace blink {

namespace DartXMLHttpRequestInternal {

void constructorCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        ExecutionContext* context = DartUtilities::scriptExecutionContext();
        if (!context) {
            exception = Dart_NewStringFromCString("XMLHttpRequest constructor's associated context is not available");
            goto fail;
        }

        RefPtr<XMLHttpRequest> xmlHttpRequest = XMLHttpRequest::create(context);
        DartDOMWrapper::returnToDart<DartXMLHttpRequest>(args, xmlHttpRequest);
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

void openCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        XMLHttpRequest* receiver = DartDOMWrapper::receiver<XMLHttpRequest>(args);
        DartStringAdapter method = DartUtilities::dartToString(args, 1, exception);
        if (exception)
            goto fail;
        DartStringAdapter url = DartUtilities::dartToString(args, 2, exception);
        if (exception)
            goto fail;

        ExecutionContext* context = DartUtilities::scriptExecutionContext();
        if (!context)
            return;
        KURL fullURL = context->completeURL(url);

        DartExceptionState es;
        Dart_Handle arg3 = Dart_GetNativeArgument(args, 3);
        if (!Dart_IsNull(arg3)) {
            bool async = DartUtilities::dartToBool(arg3, exception);
            if (exception)
                goto fail;

            Dart_Handle arg4 = Dart_GetNativeArgument(args, 4);
            if (!Dart_IsNull(arg4)) {
                DartStringAdapter user = DartUtilities::dartToString(arg4, exception);
                if (exception)
                    goto fail;

                Dart_Handle arg5 = Dart_GetNativeArgument(args, 5);
                if (!Dart_IsNull(arg5)) {
                    DartStringAdapter passwd = DartUtilities::dartToString(arg5, exception);
                    if (exception)
                        goto fail;

                    receiver->open(method, fullURL, async, user, passwd, es);
                } else {
                    receiver->open(method, fullURL, async, user, es);
                }
            } else {
                receiver->open(method, fullURL, async, es);
            }
        } else {
            receiver->open(method, fullURL, es);
        }

        if (es.hadException()) {
            exception = es.toDart(args);
            goto fail;
        }
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

// FIXMEDART: we shouldn't have to implement these methods like this.
// Fix the binding script.
void sendCallback_1(Dart_NativeArguments args) { return sendCallback(args); }
void sendCallback_2(Dart_NativeArguments args) { return sendCallback(args); }
void sendCallback_3(Dart_NativeArguments args) { return sendCallback(args); }
void sendCallback_4(Dart_NativeArguments args) { return sendCallback(args); }
void sendCallback_5(Dart_NativeArguments args) { return sendCallback(args); }
void sendCallback_6(Dart_NativeArguments args) { return sendCallback(args); }
void sendCallback_7(Dart_NativeArguments args) { return sendCallback(args); }

void sendCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        XMLHttpRequest* receiver = DartDOMWrapper::receiver<XMLHttpRequest>(args);

        DartExceptionState es;
        Dart_Handle arg1 = Dart_GetNativeArgument(args, 1);
        if (Dart_IsNull(arg1)) {
            receiver->send(es);
        } else if (DartDOMWrapper::subtypeOf(arg1, DartDocument::dartClassId)) {
            Document* asDocument = DartDocument::toNative(arg1, exception);
            if (exception)
                goto fail;
            receiver->send(asDocument, es);
        } else if (DartDOMWrapper::subtypeOf(arg1, DartBlob::dartClassId)) {
            Blob* asBlob = DartBlob::toNative(arg1, exception);
            if (exception)
                goto fail;
            receiver->send(asBlob, es);
        } else if (DartDOMWrapper::subtypeOf(arg1, DartFormData::dartClassId)) {
            DOMFormData* asDOMFormData = DartFormData::toNative(arg1, exception);
            if (exception)
                goto fail;
            receiver->send(asDOMFormData, es);
        } else if (Dart_IsByteBuffer(arg1)) {
            arg1 = Dart_GetDataFromByteBuffer(arg1);
            RefPtr<ArrayBufferView> asArrayBufferView = DartUtilities::dartToArrayBufferView(arg1, exception);
            if (exception)
                goto fail;
            receiver->send(asArrayBufferView.get(), es);
        } else if (Dart_IsTypedData(arg1)) {
            RefPtr<ArrayBufferView> asArrayBufferView = DartUtilities::dartToArrayBufferView(arg1, exception);
            if (exception)
                goto fail;
            receiver->send(asArrayBufferView.get(), es);
        } else {
            DartStringAdapter asString = DartUtilities::dartToString(arg1, exception);
            if (exception)
                goto fail;
            receiver->send(asString, es);
        }

        if (es.hadException()) {
            exception = es.toDart(args);
            goto fail;
        }
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

void responseTextGetter(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        XMLHttpRequest* receiver = DartDOMWrapper::receiver<XMLHttpRequest>(args);

        DartExceptionState es;
        // FIXME: Can we push this out of the V8 heap?
        ScriptString v8String = receiver->responseText(es);

        if (es.hadException()) {
            exception = es.toDart(args);
            goto fail;
        }

        v8::Handle<v8::Value> v8Value = v8String.v8Value();

        Dart_Handle result;
        if (*v8Value) {
            // FIXME: Should we cache this?
            result = V8Converter::stringToDart(v8Value);
        } else {
            // If the V8 value is null, there was an error. Return an
            // empty string to Dart.
            // FIXME: Resolve expected error behavior:
            // https://code.google.com/p/dart/issues/detail?id=11998
            result = Dart_NewStringFromCString("");
        }
        Dart_SetReturnValue(args, result);
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

void responseGetter(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        XMLHttpRequest* receiver = DartDOMWrapper::receiver<XMLHttpRequest>(args);

        switch (receiver->responseTypeCode()) {
        case XMLHttpRequest::ResponseTypeDefault:
        case XMLHttpRequest::ResponseTypeText:
            {
                DartExceptionState es;
                ScriptString v8String = receiver->responseText(es);
                if (es.hadException()) {
                    exception = es.toDart(args);
                    goto fail;
                }

                // FIXME: Should we cache this?
                Dart_Handle result = V8Converter::stringToDart(v8String.v8Value());
                Dart_SetReturnValue(args, result);
                return;
            }

        case XMLHttpRequest::ResponseTypeJSON:
            {
                ScriptString v8String = receiver->responseJSONSource();
                if (v8String.isEmpty()) {
                    Dart_SetReturnValue(args, Dart_Null());
                    return;
                }

                // FIXME: Should we cache this?
                Dart_Handle jsonSource = V8Converter::stringToDart(v8String.v8Value());
                Dart_Handle result = DartUtilities::invokeUtilsMethod("parseJson", 1, &jsonSource);
                if (Dart_IsError(result)) {
                    exception = result;
                    goto fail;
                }
                Dart_SetReturnValue(args, result);
                return;
            }

        case XMLHttpRequest::ResponseTypeDocument:
            {
                DartExceptionState es;
                Document* document = receiver->responseXML(es);
                if (es.hadException()) {
                    exception = es.toDart(args);
                    goto fail;
                }
                DartDOMWrapper::returnToDart<DartDocument>(args, document);
                return;
            }

        case XMLHttpRequest::ResponseTypeBlob:
            {
                Blob* blob = receiver->responseBlob();
                DartDOMWrapper::returnToDart<DartBlob>(args, blob);
                return;
            }

        case XMLHttpRequest::ResponseTypeLegacyStream:
            {
                Stream* stream = receiver->responseStream();
                DartDOMWrapper::returnToDart<DartStream>(args, stream);
                return;
            }

        case XMLHttpRequest::ResponseTypeArrayBuffer:
            {
                ArrayBuffer* arrayBuffer = receiver->responseArrayBuffer();
                Dart_SetReturnValue(args, DartUtilities::arrayBufferToDart(arrayBuffer));
                return;
            }
        }
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

} // DartXMLHttpRequestInternal

} // WebCore
