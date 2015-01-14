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

#include "sky/engine/config.h"
#include "sky/engine/core/dom/custom/CustomElementRegistrationContext.h"

#include "gen/sky/core/HTMLNames.h"
#include "sky/engine/bindings/core/v8/ExceptionState.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/Element.h"
#include "sky/engine/core/dom/custom/CustomElement.h"
#include "sky/engine/core/dom/custom/CustomElementDefinition.h"
#include "sky/engine/core/dom/custom/CustomElementScheduler.h"
#include "sky/engine/core/html/HTMLElement.h"
#include "sky/engine/wtf/RefPtr.h"

namespace blink {

CustomElementRegistrationContext::CustomElementRegistrationContext()
{
}

void CustomElementRegistrationContext::registerElement(Document* document, CustomElementConstructorBuilder* constructorBuilder, const AtomicString& type, CustomElement::NameSet validNames, ExceptionState& exceptionState)
{
    m_registry.registerElement(document, constructorBuilder, type, validNames, exceptionState);
}

PassRefPtr<Element> CustomElementRegistrationContext::createCustomTagElement(Document& document, const QualifiedName& tagName)
{
    ASSERT(CustomElement::isValidName(tagName.localName()));

    RefPtr<Element> element = HTMLElement::create(tagName, document);
    element->setCustomElementState(Element::WaitingForUpgrade);
    resolveOrScheduleResolution(element.get());
    return element.release();
}

void CustomElementRegistrationContext::resolveOrScheduleResolution(Element* element)
{
    CustomElementDescriptor descriptor(element->localName());
    ASSERT(element->customElementState() == Element::WaitingForUpgrade);

    CustomElementScheduler::resolveOrScheduleResolution(this, element, descriptor);
}

void CustomElementRegistrationContext::resolve(Element* element, const CustomElementDescriptor& descriptor)
{
    if (CustomElementDefinition* definition = m_registry.find(descriptor))
        CustomElement::define(element, definition);
}

} // namespace blink
