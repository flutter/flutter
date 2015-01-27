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
#include "bindings/core/dart/DartHTMLCanvasElement.h"

#include "bindings/core/dart/DartCanvasRenderingContext2D.h"
#include "bindings/core/dart/DartDOMWrapper.h"
#include "bindings/core/dart/DartUtilities.h"
#include "bindings/core/dart/DartWebGLRenderingContext.h"
#include "core/html/canvas/CanvasContextAttributes.h"
#include "core/html/canvas/CanvasRenderingContext2D.h"
#include "core/html/canvas/CanvasRenderingContext.h"
#include "core/html/canvas/WebGLContextAttributes.h"
#include "core/html/canvas/WebGLRenderingContext.h"
#include "core/html/HTMLCanvasElement.h"

namespace blink {

namespace DartHTMLCanvasElementInternal {

void toDataURLCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        HTMLCanvasElement* receiver = DartDOMWrapper::receiver<HTMLCanvasElement>(args);

        DartStringAdapter type = DartUtilities::dartToString(args, 1, exception);
        if (exception)
            goto fail;

        double quality;
        double* qualityPtr = 0;
        Dart_Handle secondArgument = Dart_GetNativeArgument(args, 2);
        if (!Dart_IsNull(secondArgument)) {
            quality = DartUtilities::dartToDouble(secondArgument, exception);
            if (exception)
                goto fail;
            qualityPtr = &quality;
        }

        DartExceptionState es;
        String result = receiver->toDataURL(type, qualityPtr, es);
        if (es.hadException()) {
            exception = es.toDart(args);
            goto fail;
        }

        Dart_SetReturnValue(args, DartUtilities::stringToDartWithNullCheck(result));
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

void getContextCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        HTMLCanvasElement* receiver = DartDOMWrapper::receiver<HTMLCanvasElement>(args);

        DartStringAdapter contextId = DartUtilities::dartToString(args, 1, exception);
        if (exception)
            goto fail;

        RefPtr<CanvasContextAttributes> attrs;
        const String& contextIdStr = contextId;
        if (contextIdStr == "webgl" || contextIdStr == "experimental-webgl" || contextIdStr == "webkit-3d") {
            attrs = WebGLContextAttributes::create();
            WebGLContextAttributes* webGLAttrs = static_cast<WebGLContextAttributes*>(attrs.get());
            Dart_Handle attrsAsMapHandle = Dart_GetNativeArgument(args, 2);
            if (!Dart_IsNull(attrsAsMapHandle)) {
                Dart_Handle attrsAsIntHandle = DartUtilities::invokeUtilsMethod("convertCanvasElementGetContextMap", 1, &attrsAsMapHandle);
                if (!DartUtilities::checkResult(attrsAsIntHandle, exception))
                    goto fail;
                int attrsAsInt = DartUtilities::toInteger(attrsAsIntHandle, exception);
                if (exception)
                    goto fail;

                webGLAttrs->setAlpha(attrsAsInt & 0x01);
                webGLAttrs->setDepth(attrsAsInt & 0x02);
                webGLAttrs->setStencil(attrsAsInt & 0x04);
                webGLAttrs->setAntialias(attrsAsInt & 0x08);
                webGLAttrs->setPremultipliedAlpha(attrsAsInt & 0x10);
                webGLAttrs->setPreserveDrawingBuffer(attrsAsInt & 0x20);
            }
        }

        CanvasRenderingContext* result = receiver->getContext(contextId, attrs.get());
        if (!result)
            return;
        if (result->is2d())
            DartDOMWrapper::returnToDart<DartCanvasRenderingContext2D>(args, static_cast<CanvasRenderingContext2D*>(result));
        else if (result->is3d())
            DartDOMWrapper::returnToDart<DartWebGLRenderingContext>(args, static_cast<WebGLRenderingContext*>(result));
        else
            ASSERT_NOT_REACHED();
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

void getContextCallback_1(Dart_NativeArguments args)
{
    return getContextCallback(args);
}

void getContextCallback_2(Dart_NativeArguments args)
{
    return getContextCallback(args);
}

} // namespace DartHTMLCanvasElementInternal

} // namespace blink
