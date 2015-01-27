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
#include "bindings/core/dart/DartNode.h"

#include "bindings/core/dart/DartAttr.h"
#include "bindings/core/dart/DartCDATASection.h"
#include "bindings/core/dart/DartComment.h"
#include "bindings/core/dart/DartDOMWrapper.h"
#include "bindings/core/dart/DartDocument.h"
#include "bindings/core/dart/DartDocumentFragment.h"
#include "bindings/core/dart/DartDocumentType.h"
#include "bindings/core/dart/DartElement.h"
#include "bindings/core/dart/DartProcessingInstruction.h"
#include "bindings/core/dart/DartShadowRoot.h"
#include "bindings/core/dart/DartText.h"
#include "core/dom/custom/CustomElementCallbackDispatcher.h"

namespace blink {

namespace DartNodeInternal {

// This function is customized to take advantage of the optional 4th argument: shouldLazyAttach.
void insertBeforeCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        Node* receiver = DartDOMWrapper::receiver<Node>(args);

        Node* newChild = DartNode::toNativeWithNullCheck(args, 1, exception);
        if (exception)
            goto fail;

        Node* refChild = DartNode::toNativeWithNullCheck(args, 2, exception);
        if (exception)
            goto fail;

        CustomElementCallbackDispatcher::CallbackDeliveryScope deliveryScope;

        DartExceptionState es;
        receiver->insertBefore(newChild, refChild, es);
        if (es.hadException()) {
            exception = es.toDart(args);
            goto fail;
        }

        DartDOMWrapper::returnToDart<DartNode>(args, newChild);
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

// This function is customized to take advantage of the optional 4th argument: shouldLazyAttach.
void replaceChildCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        Node* receiver = DartDOMWrapper::receiver<Node>(args);

        Node* newChild = DartNode::toNativeWithNullCheck(args, 1, exception);
        if (exception)
            goto fail;

        Node* oldChild = DartNode::toNativeWithNullCheck(args, 2, exception);
        if (exception)
            goto fail;

        CustomElementCallbackDispatcher::CallbackDeliveryScope deliveryScope;

        DartExceptionState es;
        receiver->replaceChild(newChild, oldChild, es);
        if (es.hadException()) {
            exception = es.toDart(args);
            goto fail;
        }

        DartDOMWrapper::returnToDart<DartNode>(args, newChild);
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

// Custom handling of the return value.
void removeChildCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        Node* receiver = DartDOMWrapper::receiver<Node>(args);

        Node* child = DartNode::toNativeWithNullCheck(args, 1, exception);
        if (exception)
            goto fail;

        CustomElementCallbackDispatcher::CallbackDeliveryScope deliveryScope;

        DartExceptionState es;
        receiver->removeChild(child, es);
        if (es.hadException()) {
            exception = es.toDart(args);
            goto fail;
        }

        DartDOMWrapper::returnToDart<DartNode>(args, child);
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

// This function is customized to enable lazy attaching - see the last argument to appendChild.
void appendChildCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        Node* receiver = DartDOMWrapper::receiver<Node>(args);

        Node* child = DartNode::toNativeWithNullCheck(args, 1, exception);
        if (exception)
            goto fail;

        CustomElementCallbackDispatcher::CallbackDeliveryScope deliveryScope;

        DartExceptionState es;
        receiver->appendChild(child, es);
        if (es.hadException()) {
            exception = es.toDart(args);
            goto fail;
        }

        DartDOMWrapper::returnToDart<DartNode>(args, child);
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

void cloneNodeCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        Node* receiver = DartDOMWrapper::receiver< Node >(args);

        bool deep = DartUtilities::dartToBool(args, 1, exception);
        if (exception)
            goto fail;

        RefPtr<Node> result;
        {
            CustomElementCallbackDispatcher::CallbackDeliveryScope deliveryScope;

            result = receiver->cloneNode(deep);
        }

        DartNode::returnToDart(args, result);
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

}

Dart_Handle DartNode::createWrapper(DartDOMData* domData, Node* node)
{
    if (!node)
        return Dart_Null();

    switch (node->nodeType()) {
    case Node::ELEMENT_NODE:
        return DartElement::createWrapper(domData, static_cast<Element*>(node));
    case Node::ATTRIBUTE_NODE:
        return DartAttr::createWrapper(domData, static_cast<Attr*>(node));
    case Node::TEXT_NODE:
        return DartText::createWrapper(domData, toText(node));
    case Node::CDATA_SECTION_NODE:
        return DartCDATASection::createWrapper(domData, static_cast<CDATASection*>(node));
    case Node::PROCESSING_INSTRUCTION_NODE:
        return DartProcessingInstruction::createWrapper(domData, static_cast<ProcessingInstruction*>(node));
    case Node::COMMENT_NODE:
        return DartComment::createWrapper(domData, static_cast<Comment*>(node));
    case Node::DOCUMENT_NODE:
        return DartDocument::createWrapper(domData, static_cast<Document*>(node));
    case Node::DOCUMENT_TYPE_NODE:
        return DartDocumentType::createWrapper(domData, static_cast<DocumentType*>(node));
    case Node::DOCUMENT_FRAGMENT_NODE:
        if (node->isShadowRoot())
            return DartShadowRoot::createWrapper(domData, static_cast<ShadowRoot*>(node));
        return DartDocumentFragment::createWrapper(domData, static_cast<DocumentFragment*>(node));
    default: break; // XPATH_NAMESPACE_NODE
    }
    return DartDOMWrapper::createWrapper<DartNode>(domData, node);
}

}
