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
#include "core/dom/custom/CustomElement.h"

#include "core/dom/Document.h"
#include "core/dom/Element.h"
#include "core/dom/custom/CustomElementMicrotaskRunQueue.h"
#include "core/dom/custom/CustomElementObserver.h"
#include "core/dom/custom/CustomElementScheduler.h"

namespace blink {

CustomElementMicrotaskImportStep* CustomElement::didCreateImport(HTMLImportChild* import)
{
    return CustomElementScheduler::scheduleImport(import);
}

void CustomElement::didFinishLoadingImport(Document& master)
{
    master.customElementMicrotaskRunQueue()->requestDispatchIfNeeded();
}

Vector<AtomicString>& CustomElement::embedderCustomElementNames()
{
    DEFINE_STATIC_LOCAL(Vector<AtomicString>, names, ());
    return names;
}

void CustomElement::addEmbedderCustomElementName(const AtomicString& name)
{
    AtomicString lower = name.lower();
    if (isValidName(lower, EmbedderNames))
        return;
    embedderCustomElementNames().append(lower);
}

bool CustomElement::isValidName(const AtomicString& name, NameSet validNames)
{
    if ((validNames & EmbedderNames) && kNotFound != embedderCustomElementNames().find(name))
        return Document::isValidName(name);

    if ((validNames & StandardNames) && kNotFound != name.find('-'))
        return Document::isValidName(name.string());

    return false;
}

void CustomElement::define(Element* element, PassRefPtr<CustomElementDefinition> passDefinition)
{
    RefPtr<CustomElementDefinition> definition(passDefinition);

    switch (element->customElementState()) {
    case Element::NotCustomElement:
    case Element::Upgraded:
        ASSERT_NOT_REACHED();
        break;

    case Element::WaitingForUpgrade:
        element->setCustomElementDefinition(definition);
        CustomElementScheduler::scheduleCallback(definition->callbacks(), element, CustomElementLifecycleCallbacks::CreatedCallback);
        break;
    }
}

void CustomElement::attributeDidChange(Element* element, const AtomicString& name, const AtomicString& oldValue, const AtomicString& newValue)
{
    ASSERT(element->customElementState() == Element::Upgraded);
    CustomElementScheduler::scheduleAttributeChangedCallback(element->customElementDefinition()->callbacks(), element, name, oldValue, newValue);
}

void CustomElement::didAttach(Element* element, const Document& document)
{
    ASSERT(element->customElementState() == Element::Upgraded);
    if (!document.domWindow())
        return;
    CustomElementScheduler::scheduleCallback(element->customElementDefinition()->callbacks(), element, CustomElementLifecycleCallbacks::AttachedCallback);
}

void CustomElement::didDetach(Element* element, const Document& document)
{
    ASSERT(element->customElementState() == Element::Upgraded);
    if (!document.domWindow())
        return;
    CustomElementScheduler::scheduleCallback(element->customElementDefinition()->callbacks(), element, CustomElementLifecycleCallbacks::DetachedCallback);
}

void CustomElement::wasDestroyed(Element* element)
{
    switch (element->customElementState()) {
    case Element::NotCustomElement:
        ASSERT_NOT_REACHED();
        break;

    case Element::WaitingForUpgrade:
    case Element::Upgraded:
        CustomElementObserver::notifyElementWasDestroyed(element);
        break;
    }
}

} // namespace blink
