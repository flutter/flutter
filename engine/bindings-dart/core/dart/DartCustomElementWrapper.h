/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
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

#ifndef DartCustomElementWrapper_h
#define DartCustomElementWrapper_h

#include "bindings/core/dart/DartDOMData.h"
#include "wtf/PassRefPtr.h"
#include <dart_api.h>

namespace blink {

class HTMLElement;
class SVGElement;

template<typename ElementType>
class DartCustomElementWrapper {
public:
    static Dart_Handle upgradeDartWrapper(ElementType*, Dart_Handle (*createSpecificWrapper)(DartDOMData*, ElementType*));

    static Dart_Handle changeElementWrapper(Dart_Handle element, Dart_Handle wrapperType);

    static void initializeCustomElement(Dart_Handle wrapper, Dart_Handle& exception);

private:
    DartCustomElementWrapper();

    friend Dart_Handle createDartHTMLWrapper(DartDOMData*, HTMLElement*);
    friend Dart_Handle createDartSVGWrapper(DartDOMData*, SVGElement*);

    static Dart_Handle swapElementWrapper(DartDOMData*, ElementType*, Dart_Handle wrapperType, intptr_t nativeClassId);

    static Dart_Handle wrap(PassRefPtr<ElementType>, Dart_Handle (*createSpecificWrapper)(DartDOMData*, ElementType*));
};

} // namespace blink

#endif // CustomElementWrapper_h
