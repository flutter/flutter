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
#include "bindings/core/dart/DartElement.h"

#include "bindings/core/dart/DartDOMWrapper.h"
#include "bindings/core/dart/DartHTMLElement.h"
#include "bindings/core/dart/DartSVGElement.h"
#include "platform/RuntimeEnabledFeatures.h"

namespace blink {

Dart_Handle DartElement::createWrapper(DartDOMData* domData, Element* element)
{
    if (!element)
        return Dart_Null();

    if (element->isHTMLElement())
        return DartHTMLElement::createWrapper(domData, static_cast<HTMLElement*>(element));
    if (element->isSVGElement())
        return DartSVGElement::createWrapper(domData, static_cast<SVGElement*>(element));
    return DartDOMWrapper::createWrapper<DartElement>(domData, element);
}

namespace DartElementInternal {


void scrollLeftSetter(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        Element* receiver = DartDOMWrapper::receiver<Element>(args);

        // FIXME: The IDL now specifies an option to pass in a dictionary
        // instead of just an integer.
        int scrollLeft = DartUtilities::dartToInt(args, 1, exception);
        if (exception)
            goto fail;

        receiver->setScrollLeft(scrollLeft);
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

void scrollTopSetter(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        Element* receiver = DartDOMWrapper::receiver<Element>(args);

        // FIXME: The IDL now specifies an option to pass in a dictionary
        // instead of just an integer.
        int scrollTop = DartUtilities::dartToInt(args, 1, exception);
        if (exception)
            goto fail;

        receiver->setScrollTop(scrollTop);
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

void animateCallback(Dart_NativeArguments)
{
    // FIXME: proper implementation.
    DART_UNIMPLEMENTED();
}

}

}
