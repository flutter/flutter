/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
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
#include "sky/engine/core/dom/custom/CustomElementRegistry.h"

#include "sky/engine/bindings/core/v8/CustomElementConstructorBuilder.h"
#include "sky/engine/core/dom/DocumentLifecycleObserver.h"
#include "sky/engine/core/dom/custom/CustomElementException.h"
#include "sky/engine/core/dom/custom/CustomElementRegistrationContext.h"

namespace blink {

class RegistrationContextObserver : public DocumentLifecycleObserver {
public:
    explicit RegistrationContextObserver(Document* document)
        : DocumentLifecycleObserver(document)
        , m_wentAway(!document)
    {
    }

    bool registrationContextWentAway() { return m_wentAway; }

private:
#if ENABLE(OILPAN)
    // In oilpan we don't have the disposed phase for context lifecycle observer.
    virtual void documentWasDetached() override { m_wentAway = true; }
#else
    virtual void documentWasDisposed() override { m_wentAway = true; }
#endif

    bool m_wentAway;
};

CustomElementDefinition* CustomElementRegistry::registerElement(Document* document, CustomElementConstructorBuilder* constructorBuilder, const AtomicString& userSuppliedName, CustomElement::NameSet validNames, ExceptionState& exceptionState)
{
    // FIXME: In every instance except one it is the
    // CustomElementConstructorBuilder that observes document
    // destruction during registration. This responsibility should be
    // consolidated in one place.
    RegistrationContextObserver observer(document);

    AtomicString type = userSuppliedName.lower();

    if (!CustomElement::isValidName(type, validNames)) {
        CustomElementException::throwException(CustomElementException::InvalidName, type, exceptionState);
        return 0;
    }

    if (m_definitions.contains(type)) {
        CustomElementException::throwException(CustomElementException::TypeAlreadyRegistered, type, exceptionState);
        return 0;
    }

    QualifiedName tagName = nullName;
    if (!constructorBuilder->validateOptions(type, tagName, exceptionState))
        return 0;

    ASSERT(!observer.registrationContextWentAway());

    RefPtr<CustomElementLifecycleCallbacks> lifecycleCallbacks = constructorBuilder->createCallbacks();

    // Consulting the constructor builder could execute script and
    // kill the document.
    if (observer.registrationContextWentAway()) {
        CustomElementException::throwException(CustomElementException::ContextDestroyedCreatingCallbacks, type, exceptionState);
        return 0;
    }

    const CustomElementDescriptor descriptor(tagName.localName());
    RefPtr<CustomElementDefinition> definition = CustomElementDefinition::create(descriptor, lifecycleCallbacks);

    if (!constructorBuilder->createConstructor(document, definition.get(), exceptionState))
        return 0;

    m_definitions.add(descriptor, definition);

    if (!constructorBuilder->didRegisterDefinition(definition.get())) {
        CustomElementException::throwException(CustomElementException::ContextDestroyedRegisteringDefinition, type, exceptionState);
        return 0;
    }

    return definition.get();
}

CustomElementDefinition* CustomElementRegistry::find(const CustomElementDescriptor& descriptor) const
{
    return m_definitions.get(descriptor);
}

} // namespace blink
