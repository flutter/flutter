/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer
 *    in the documentation and/or other materials provided with the
 *    distribution.
 * 3. Neither the name of Google Inc. nor the names of its contributors
 *    may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
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
#include "core/dom/custom/CustomElementRegistrationContext.h"

#include "bindings/core/v8/ExceptionState.h"
#include "gen/sky/core/HTMLNames.h"
#include "core/dom/Document.h"
#include "core/dom/Element.h"
#include "core/dom/custom/CustomElement.h"
#include "core/dom/custom/CustomElementDefinition.h"
#include "core/dom/custom/CustomElementScheduler.h"
#include "core/html/HTMLElement.h"
#include "wtf/RefPtr.h"

namespace blink {

CustomElementRegistrationContext::CustomElementRegistrationContext()
    : m_candidates(CustomElementUpgradeCandidateMap::create())
{
}

void CustomElementRegistrationContext::registerElement(Document* document, CustomElementConstructorBuilder* constructorBuilder, const AtomicString& type, CustomElement::NameSet validNames, ExceptionState& exceptionState)
{
    CustomElementDefinition* definition = m_registry.registerElement(document, constructorBuilder, type, validNames, exceptionState);

    if (!definition)
        return;

    // Upgrade elements that were waiting for this definition.
    OwnPtr<CustomElementUpgradeCandidateMap::ElementSet> upgradeCandidates = m_candidates->takeUpgradeCandidatesFor(definition->descriptor());

    if (!upgradeCandidates)
        return;

    for (CustomElementUpgradeCandidateMap::ElementSet::const_iterator it = upgradeCandidates->begin(); it != upgradeCandidates->end(); ++it)
        CustomElement::define(*it, definition);
}

PassRefPtr<Element> CustomElementRegistrationContext::createCustomTagElement(Document& document, const QualifiedName& tagName)
{
    ASSERT(CustomElement::isValidName(tagName.localName()));

    RefPtr<Element> element = HTMLElement::create(tagName, document);
    element->setCustomElementState(Element::WaitingForUpgrade);
    resolveOrScheduleResolution(element.get(), nullAtom);
    return element.release();
}

void CustomElementRegistrationContext::didGiveTypeExtension(Element* element, const AtomicString& type)
{
    resolveOrScheduleResolution(element, type);
}

void CustomElementRegistrationContext::resolveOrScheduleResolution(Element* element, const AtomicString& typeExtension)
{
    // If an element has a custom tag name it takes precedence over
    // the "is" attribute (if any).
    const AtomicString& type = CustomElement::isValidName(element->localName())
        ? element->localName()
        : typeExtension;
    ASSERT(!type.isNull());

    CustomElementDescriptor descriptor(type, element->localName());
    ASSERT(element->customElementState() == Element::WaitingForUpgrade);

    CustomElementScheduler::resolveOrScheduleResolution(this, element, descriptor);
}

void CustomElementRegistrationContext::resolve(Element* element, const CustomElementDescriptor& descriptor)
{
    CustomElementDefinition* definition = m_registry.find(descriptor);
    if (definition) {
        CustomElement::define(element, definition);
    } else {
        ASSERT(element->customElementState() == Element::WaitingForUpgrade);
        m_candidates->add(descriptor, element);
    }
}

void CustomElementRegistrationContext::setIsAttributeAndTypeExtension(Element* element, const AtomicString& type)
{
    ASSERT(element);
    ASSERT(!type.isEmpty());
    element->setAttribute(HTMLNames::isAttr, type);
    setTypeExtension(element, type);
}

void CustomElementRegistrationContext::setTypeExtension(Element* element, const AtomicString& type)
{
    if (!element->isHTMLElement())
        return;

    CustomElementRegistrationContext* context = element->document().registrationContext();
    if (!context)
        return;

    if (element->isCustomElement()) {
        // This can happen if:
        // 1. The element has a custom tag, which takes precedence over
        //    type extensions.
        // 2. Undoing a command (eg ReplaceNodeWithSpan) recycles an
        //    element but tries to overwrite its attribute list.
        return;
    }

    // Custom tags take precedence over type extensions
    ASSERT(!CustomElement::isValidName(element->localName()));

    if (!CustomElement::isValidName(type))
        return;

    element->setCustomElementState(Element::WaitingForUpgrade);
    // FIXME(sky) this used to call Document::convertLocalName(type) which
    // would lowercase if Document was HTML, that made no sense.
    context->didGiveTypeExtension(element, type);
}

} // namespace blink
