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

#include "config.h"
#include "bindings/core/dart/DartCustomElementWrapper.h"

#include "bindings/core/dart/DartCustomElementLifecycleCallbacks.h"
#include "bindings/core/dart/DartHTMLElement.h"
#include "bindings/core/dart/DartSVGElement.h"
#include "core/DartHTMLElementWrapperFactory.h"
#include "core/DartSVGElementWrapperFactory.h"
#include "core/dom/custom/CustomElement.h"
#include "core/html/HTMLElement.h"
#include "core/html/HTMLUnknownElement.h"
#include "core/svg/SVGElement.h"

namespace blink {

template<typename ElementType>
Dart_Handle createDartDirectWrapper(DartDOMData*, ElementType*);

template<>
Dart_Handle createDartDirectWrapper<HTMLElement>(DartDOMData* domData, HTMLElement* element)
{
    return DartDOMWrapper::createWrapper<DartHTMLElement>(domData, element);
}

template<>
Dart_Handle createDartDirectWrapper<SVGElement>(DartDOMData* domData, SVGElement* element)
{
    return DartDOMWrapper::createWrapper<DartSVGElement>(domData, element);
}

template<typename ElementType>
Dart_Handle createDartFallbackWrapper(DartDOMData*, ElementType*);

template<>
Dart_Handle createDartFallbackWrapper<HTMLElement>(DartDOMData* domData, HTMLElement* element)
{
    return createDartHTMLFallbackWrapper(domData, toHTMLUnknownElement(element));
}

template<>
Dart_Handle createDartFallbackWrapper<SVGElement>(DartDOMData* domData, SVGElement* element)
{
    return createDartSVGFallbackWrapper(domData, element);
}

template<typename ElementType>
Dart_Handle createUpgradeCandidateWrapper(ElementType* element, Dart_Handle (*createSpecificWrapper)(DartDOMData*, ElementType* element))
{
    DartDOMData* domData = DartDOMData::current();
    if (CustomElement::isValidName(element->localName()))
        return createDartDirectWrapper(domData, element);
    if (createSpecificWrapper)
        return createSpecificWrapper(domData, element);
    return createDartFallbackWrapper(domData, element);
}

template<typename ElementType>
Dart_Handle DartCustomElementWrapper<ElementType>::wrap(PassRefPtr<ElementType> element, Dart_Handle (*createSpecificWrapper)(DartDOMData* domData, ElementType*))
{
    if (!element->isUpgradedCustomElement())
        return createUpgradeCandidateWrapper(element.get(), createSpecificWrapper);

    return upgradeDartWrapper(element.get(), createSpecificWrapper);
}

template<>
Dart_Handle DartCustomElementWrapper<HTMLElement>::swapElementWrapper(DartDOMData* domData, HTMLElement* element, Dart_Handle wrapperType, intptr_t nativeClassId)
{
    Dart_WeakPersistentHandle oldInstance = DartDOMWrapper::lookupWrapper<DartHTMLElement>(
        domData, reinterpret_cast<HTMLElement*>(element));
    Dart_Handle oldWrapper = 0;
    if (oldInstance) {
        oldWrapper = Dart_HandleFromWeakPersistent(oldInstance);
        DartDOMWrapper::disassociateWrapper<DartHTMLElement>(
            domData,
            reinterpret_cast<HTMLElement*>(element),
            oldWrapper);
    }

    Dart_Handle newWrapper = Dart_Allocate(wrapperType);
    ASSERT(!Dart_IsError(newWrapper));
    DartDOMWrapper::writeNativePointer(newWrapper, element, nativeClassId);

    Dart_Handle result = Dart_InvokeConstructor(newWrapper, Dart_NewStringFromCString("created"), 0, 0);

    if (Dart_IsError(result)) {
        DartUtilities::reportProblem(domData->scriptExecutionContext(), result);

        // Fall back to the old wrapper if possible.
        if (oldWrapper) {
            DartDOMWrapper::associateWrapper<DartHTMLElement>(domData, element, oldWrapper);
            return oldWrapper;
        }
        return result;
    }
    return newWrapper;
}

template<>
Dart_Handle DartCustomElementWrapper<SVGElement>::swapElementWrapper(DartDOMData* domData, SVGElement* element, Dart_Handle wrapperType, intptr_t nativeClassId)
{
    // TODO: support SVG elements.
    ASSERT(FALSE);
    return Dart_Handle();
}

template<>
Dart_Handle DartCustomElementWrapper<HTMLElement>::upgradeDartWrapper(HTMLElement* element, Dart_Handle (*createSpecificWrapper)(DartDOMData*, HTMLElement*))
{
    DartDOMData* domData = DartDOMData::current();
    DartCustomElementBinding* binding = domData->customElementBinding(element->customElementDefinition());
    if (!binding)
        return createUpgradeCandidateWrapper(element, createSpecificWrapper);

    Dart_PersistentHandle customType = binding->customType();
    ASSERT(!Dart_IsError(customType));

    Dart_Handle newWrapper = swapElementWrapper(domData, element, customType, binding->nativeClassId());
    if (Dart_IsError(newWrapper)) {
        // When the upgrade fails the failed wrapper may have been associated,
        // so we need to create a new one and re-associate it.
        Dart_Handle fallbackWrapper = createUpgradeCandidateWrapper(element, createSpecificWrapper);
        if (Dart_IsError(fallbackWrapper)) {
            // FIXME: We can reach here on a stack overflow. We should cascade the exception from here, but that will
            // require additional plumbing. We already reported the problem in swapElementWrapper so just return null
            // here.
            return Dart_Null();
        }

        DartDOMWrapper::associateWrapper<DartHTMLElement>(domData, element, fallbackWrapper);
        DartDOMWrapper::writeNativePointer(fallbackWrapper, element, binding->nativeClassId());
        return fallbackWrapper;
    }
    return newWrapper;
}

template<>
Dart_Handle DartCustomElementWrapper<HTMLElement>::changeElementWrapper(Dart_Handle element, Dart_Handle wrapperType)
{
    DartDOMData* domData = DartDOMData::current();

    intptr_t nativeClassId = reinterpret_cast<intptr_t>(DartDOMWrapper::readNativePointer(element, DartDOMWrapper::NativeTypeIndex));
    Dart_Handle exception = 0;
    HTMLElement* nativeElement = DartDOMWrapper::unwrapDartWrapper<DartHTMLElement>(domData, element, exception);
    if (exception) {
        return exception;
    }
    return swapElementWrapper(domData, nativeElement, wrapperType, nativeClassId);
}

template<>
Dart_Handle DartCustomElementWrapper<SVGElement>::changeElementWrapper(Dart_Handle element, Dart_Handle wrapperType)
{
    // TODO: support SVG elements.
    ASSERT(FALSE);
    return Dart_Handle();
}

template<>
Dart_Handle DartCustomElementWrapper<SVGElement>::upgradeDartWrapper(SVGElement* element, Dart_Handle (*createSpecificWrapper)(DartDOMData*, SVGElement*))
{
    // TODO: support SVG elements.
    ASSERT(FALSE);
    return Dart_Handle();
}

template<>
void DartCustomElementWrapper<HTMLElement>::initializeCustomElement(Dart_Handle wrapper, Dart_Handle& exception)
{
    DartDOMData* domData = DartDOMData::current();
    HTMLElement* element = DartDOMWrapper::unwrapDartWrapper<DartHTMLElement>(domData, wrapper, exception);
    if (exception) {
        return;
    }
    if (!element) {
        exception = Dart_NewStringFromCString("created called outside of custom element creation.");
        return;
    }

    DartDOMWrapper::associateWrapper<DartHTMLElement>(domData, element, wrapper);
}

template<>
void DartCustomElementWrapper<SVGElement>::initializeCustomElement(Dart_Handle wrapper, Dart_Handle& exception)
{
    // TODO: support SVG elements.
    ASSERT(FALSE);
}

template
class DartCustomElementWrapper<HTMLElement>;

template
class DartCustomElementWrapper<SVGElement>;

} // namespace blink
