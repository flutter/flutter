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
#include "bindings/core/dart/DartCanvasRenderingContext2D.h"

#include "bindings/core/dart/DartCanvasGradient.h"
#include "bindings/core/dart/DartCanvasPattern.h"
#include "bindings/core/dart/DartDOMWrapper.h"
#include "core/html/canvas/CanvasRenderingContext2D.h"
#include "core/html/canvas/CanvasStyle.h"

namespace blink {

namespace DartCanvasRenderingContext2DInternal {

static void canvasStyleReturnToDartValue(Dart_NativeArguments args, CanvasStyle* style)
{
    if (style->canvasGradient()) {
        DartCanvasGradient::returnToDart(args, style->canvasGradient());
        return;
    }

    if (style->canvasPattern()) {
        DartCanvasPattern::returnToDart(args, style->canvasPattern());
        return;
    }

    DartUtilities::setDartStringReturnValue(args, style->color());
}

static PassRefPtr<CanvasStyle> toCanvasStyle(Dart_Handle value)
{
    Dart_Handle exception = 0;
    if (DartDOMWrapper::subtypeOf(value, DartCanvasGradient::dartClassId))
        return CanvasStyle::createFromGradient(DartCanvasGradient::toNativeWithNullCheck(value, exception));

    if (DartDOMWrapper::subtypeOf(value, DartCanvasPattern::dartClassId))
        return CanvasStyle::createFromPattern(DartCanvasPattern::toNativeWithNullCheck(value, exception));

    return nullptr;
}

void strokeStyleGetter(Dart_NativeArguments args )
{
    {
        CanvasRenderingContext2D* receiver = DartDOMWrapper::receiver<CanvasRenderingContext2D>(args);

        canvasStyleReturnToDartValue(args, receiver->strokeStyle());
        return;
    }
}

void strokeStyleSetter(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        CanvasRenderingContext2D* receiver = DartDOMWrapper::receiver<CanvasRenderingContext2D>(args);

        Dart_Handle arg = Dart_GetNativeArgument(args, 1);
        if (Dart_IsString(arg)) {
            DartStringAdapter color = DartUtilities::dartToString(args, 1, exception);
            if (exception)
                goto fail;

            receiver->setStrokeColor(color);
            return;
        }

        receiver->setStrokeStyle(toCanvasStyle(arg));
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

void fillStyleGetter(Dart_NativeArguments args)
{
    {
        CanvasRenderingContext2D* receiver = DartDOMWrapper::receiver<CanvasRenderingContext2D>(args);

        canvasStyleReturnToDartValue(args, receiver->fillStyle());
        return;
    }
}

void fillStyleSetter(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        CanvasRenderingContext2D* receiver = DartDOMWrapper::receiver<CanvasRenderingContext2D>(args);

        Dart_Handle arg = Dart_GetNativeArgument(args, 1);
        if (Dart_IsString(arg)) {
            DartStringAdapter color = DartUtilities::dartToString(arg, exception);
            if (exception)
                goto fail;

            receiver->setFillColor(color);
            return;
        }

        receiver->setFillStyle(toCanvasStyle(arg));
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

} // namespace DartCanvasRenderingContext2DInternal

} // namespace blink
