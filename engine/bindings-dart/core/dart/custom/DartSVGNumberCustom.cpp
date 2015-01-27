// Copyright 2012, Google Inc.
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
#include "bindings/core/dart/DartSVGNumber.h"

namespace blink {

namespace DartSVGNumberInternal {

void valueGetter(Dart_NativeArguments args)
{
    SVGNumberTearOff* receiver = DartDOMWrapper::receiver<SVGNumberTearOff>(args);
    Dart_SetReturnValue(args, DartUtilities::doubleToDart(receiver->value()));
}

void valueSetter(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        SVGNumberTearOff* receiver = DartDOMWrapper::receiver<SVGNumberTearOff>(args);
        float value = DartUtilities::dartToDouble(Dart_GetNativeArgument(args, 1), exception);
        if (exception)
            goto fail;

        DartExceptionState es;
        receiver->setValue(value, es);
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

}

}
