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
#include "core/dom/custom/CustomElementMicrotaskResolutionStep.h"

#include "core/dom/Element.h"
#include "core/dom/custom/CustomElementRegistrationContext.h"

namespace blink {

PassOwnPtrWillBeRawPtr<CustomElementMicrotaskResolutionStep> CustomElementMicrotaskResolutionStep::create(PassRefPtrWillBeRawPtr<CustomElementRegistrationContext> context, PassRefPtrWillBeRawPtr<Element> element, const CustomElementDescriptor& descriptor)
{
    return adoptPtrWillBeNoop(new CustomElementMicrotaskResolutionStep(context, element, descriptor));
}

CustomElementMicrotaskResolutionStep::CustomElementMicrotaskResolutionStep(PassRefPtrWillBeRawPtr<CustomElementRegistrationContext> context, PassRefPtrWillBeRawPtr<Element> element, const CustomElementDescriptor& descriptor)
    : m_context(context)
    , m_element(element)
    , m_descriptor(descriptor)
{
}

CustomElementMicrotaskResolutionStep::~CustomElementMicrotaskResolutionStep()
{
}

CustomElementMicrotaskStep::Result CustomElementMicrotaskResolutionStep::process()
{
    m_context->resolve(m_element.get(), m_descriptor);
    return CustomElementMicrotaskStep::FinishedProcessing;
}

void CustomElementMicrotaskResolutionStep::trace(Visitor* visitor)
{
    visitor->trace(m_context);
    visitor->trace(m_element);
    CustomElementMicrotaskStep::trace(visitor);
}

#if !defined(NDEBUG)
void CustomElementMicrotaskResolutionStep::show(unsigned indent)
{
    fprintf(stderr, "%*sResolution: ", indent, "");
    m_element->outerHTML().show();
}
#endif

} // namespace blink
