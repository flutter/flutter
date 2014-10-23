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

#ifndef CustomElementRegistrationContext_h
#define CustomElementRegistrationContext_h

#include "core/dom/QualifiedName.h"
#include "core/dom/custom/CustomElementDescriptor.h"
#include "core/dom/custom/CustomElementRegistry.h"
#include "core/dom/custom/CustomElementUpgradeCandidateMap.h"
#include "platform/heap/Handle.h"
#include "wtf/HashMap.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/PassRefPtr.h"
#include "wtf/text/AtomicString.h"

namespace blink {

class CustomElementConstructorBuilder;
class Document;
class Element;
class ExceptionState;

class CustomElementRegistrationContext FINAL : public RefCountedWillBeGarbageCollectedFinalized<CustomElementRegistrationContext> {
public:
    static PassRefPtrWillBeRawPtr<CustomElementRegistrationContext> create()
    {
        return adoptRefWillBeNoop(new CustomElementRegistrationContext());
    }

    ~CustomElementRegistrationContext() { }

    // Definitions
    void registerElement(Document*, CustomElementConstructorBuilder*, const AtomicString& type, CustomElement::NameSet validNames, ExceptionState&);

    PassRefPtrWillBeRawPtr<Element> createCustomTagElement(Document&, const QualifiedName&);
    static void setIsAttributeAndTypeExtension(Element*, const AtomicString& type);
    static void setTypeExtension(Element*, const AtomicString& type);

    void resolve(Element*, const CustomElementDescriptor&);

    void trace(Visitor*);

protected:
    CustomElementRegistrationContext();

    // Instance creation
    void didGiveTypeExtension(Element*, const AtomicString& type);

private:
    void resolveOrScheduleResolution(Element*, const AtomicString& typeExtension);

    CustomElementRegistry m_registry;

    // Element creation
    OwnPtrWillBeMember<CustomElementUpgradeCandidateMap> m_candidates;
};

}

#endif // CustomElementRegistrationContext_h

