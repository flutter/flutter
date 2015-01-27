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
#include "bindings/core/dart/DartDocument.h"

#include "bindings/core/dart/DartDOMWrapper.h"
#include "bindings/core/dart/DartElement.h"
#include "bindings/core/dart/DartHTMLDocument.h"
#include "bindings/core/dart/DartTouchList.h"
#include "core/dom/Document.h"
#include "core/dom/custom/CustomElementCallbackDispatcher.h"

namespace blink {

Dart_Handle DartDocument::createWrapper(DartDOMData* domData, Document* document)
{
    if (!document)
        return Dart_Null();

    if (document->isHTMLDocument())
        return DartHTMLDocument::createWrapper(domData, static_cast<HTMLDocument*>(document));

    return DartDOMWrapper::createWrapper<DartDocument>(domData, document);
}

namespace DartDocumentInternal {

void createTouchListCallback(Dart_NativeArguments args)
{
    RefPtr<TouchList> touchList = TouchList::create();
    ASSERT(Dart_GetNativeArgumentCount(args) == 1);
    DartTouchList::returnToDart(args, touchList.release());
}

void createElementCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        Document* receiver = DartDOMWrapper::receiver< Document >(args);

        DartStringAdapter localName = DartUtilities::dartToString(args, 1, exception);
        if (exception)
            goto fail;

        DartStringAdapter typeExtension = DartUtilities::dartToStringWithNullCheck(args, 2, exception);
        if (exception)
            goto fail;

        DartExceptionState es;
        RefPtr<Element> result;
        {
            CustomElementCallbackDispatcher::CallbackDeliveryScope deliveryScope;

            const AtomicString& typeExtensionString = typeExtension;
            if (typeExtensionString.isNull()) {
                result = receiver->createElement(localName, es);
            } else {
                result = receiver->createElement(localName, typeExtensionString, es);
            }
        }

        DartElement::returnToDart(args, result);
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

void createElementCallback_2(Dart_NativeArguments args)
{
    return createElementCallback(args);
}

void createElementNSCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        Document* receiver = DartDOMWrapper::receiver< Document >(args);

        DartStringAdapter namespaceURI = DartUtilities::dartToString(args, 1, exception);
        if (exception)
            goto fail;

        DartStringAdapter qualifiedName = DartUtilities::dartToString(args, 2, exception);
        if (exception)
            goto fail;

        DartStringAdapter typeExtension = DartUtilities::dartToStringWithNullCheck(args, 3, exception);
        if (exception)
            goto fail;

        DartExceptionState es;
        RefPtr<Element> result;
        {
            CustomElementCallbackDispatcher::CallbackDeliveryScope deliveryScope;

            const AtomicString& typeExtensionString = typeExtension;
            if (typeExtensionString.isNull()) {
                result = receiver->createElementNS(namespaceURI, qualifiedName, es);
            } else {
                result = receiver->createElementNS(namespaceURI, qualifiedName, typeExtensionString, es);
            }
        }

        DartElement::returnToDart(args, result);
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

void createElementNSCallback_2(Dart_NativeArguments args)
{
    return createElementNSCallback(args);
}

} // namespace DartDocumentInternal

} // namespace blink
