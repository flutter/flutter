/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
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
#include "bindings/core/dart/DartCustomElementConstructorBuilder.h"

#include "core/HTMLNames.h"
#include "core/SVGNames.h"
#include "bindings/core/dart/DartCustomElementBinding.h"
#include "bindings/core/dart/DartCustomElementLifecycleCallbacks.h"
#include "bindings/core/dart/DartDOMData.h"
#include "bindings/core/dart/DartDOMWrapper.h"
#include "bindings/core/dart/DartHTMLElement.h"
#include "bindings/core/dart/DartUtilities.h"
#include "bindings/core/v8/V8Binding.h"
#include "bindings/dart/DartWebkitClassIds.h"
#include "core/dom/Document.h"
#include "core/dom/custom/CustomElementException.h"

namespace blink {

DartCustomElementConstructorBuilder::DartCustomElementConstructorBuilder(Dart_Handle customType, const AtomicString& extendsTagName, DartScriptState* state, const Dictionary* options)
    : CustomElementConstructorBuilder(state, options)
    , m_customType(customType)
    , m_nativeClassId(_InvalidClassId)
    , m_extendsTagName(extendsTagName)
    , m_scriptState(state)
{
}

bool DartCustomElementConstructorBuilder::isFeatureAllowed() const
{
    // Check that we are in the main world
    return DartDOMData::current()->isDOMEnabled();
}

bool DartCustomElementConstructorBuilder::validateOptions(const AtomicString& type, QualifiedName& tagName, ExceptionState& es)
{
    AtomicString namespaceURI;
    DartDOMData* domData = DartDOMData::current();

    if (DartUtilities::isTypeSubclassOf(m_customType, domData->htmlLibrary(), "HtmlElement")) {
        namespaceURI = HTMLNames::xhtmlNamespaceURI;
    } else if (DartUtilities::isTypeSubclassOf(m_customType, domData->svgLibrary(), "SvgElement")) {
        //namespaceURI = SVGNames::svgNamespaceURI;
        // TODO(blois): Support SVG custom elements.
        CustomElementException::throwException(CustomElementException::ExtendsIsInvalidName, type, es);
        return false;
    } else {
        CustomElementException::throwException(CustomElementException::ExtendsIsInvalidName, type, es);
        return false;
    }

    AtomicString localName;
    if (!m_extendsTagName.isNull() && !m_extendsTagName.isEmpty()) {
        localName = m_extendsTagName.lower();

        Dart_Handle nativeElement = DartUtilities::getAndValidateNativeType(m_customType, m_extendsTagName);
        if (!nativeElement || Dart_IsNull(nativeElement)) {
            CustomElementException::throwException(CustomElementException::ExtendsIsInvalidName, type, es);
            return false;
        }

        m_nativeClassId = reinterpret_cast<intptr_t>(DartDOMWrapper::readNativePointer(nativeElement, DartDOMWrapper::NativeTypeIndex));

        if (!Document::isValidName(localName)) {
            CustomElementException::throwException(CustomElementException::ExtendsIsInvalidName, type, es);
            return false;
        }
        if (CustomElement::isValidName(localName)) {
            CustomElementException::throwException(CustomElementException::ExtendsIsCustomElementName, type, es);
            return false;
        }
    } else {
        localName = type;
        m_nativeClassId = DartHTMLElement::dartClassId;
    }

    m_localName = localName;
    m_namespaceURI = namespaceURI;
    findTagName(type, tagName);
    return true;
}

bool DartCustomElementConstructorBuilder::findTagName(const AtomicString& customElementType, QualifiedName& tagName)
{
    if (!m_extendsTagName.isNull() && !m_extendsTagName.isEmpty()) {
        tagName = QualifiedName(nullAtom, m_extendsTagName, m_namespaceURI);
    } else {
        tagName = QualifiedName(nullAtom, m_localName, m_namespaceURI);
    }
    return true;
}

PassRefPtr<CustomElementLifecycleCallbacks> DartCustomElementConstructorBuilder::createCallbacks()
{
    m_callbacks = DartCustomElementLifecycleCallbacks::create(m_scriptState.get());
    return m_callbacks.get();
}

bool DartCustomElementConstructorBuilder::createConstructor(Document* document, CustomElementDefinition* definition, ExceptionState& es)
{
    return true;
}

bool DartCustomElementConstructorBuilder::didRegisterDefinition(CustomElementDefinition* definition) const
{
    return m_callbacks->setBinding(definition, DartCustomElementBinding::create(m_customType, m_nativeClassId));
}

ScriptValue DartCustomElementConstructorBuilder::bindingsReturnValue() const
{
    // Dart does not return a constructor.
    return ScriptValue();
}
} // namespace blink
