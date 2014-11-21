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
#include "sky/engine/core/dom/custom/CustomElementMicrotaskResolutionStep.h"

#include "sky/engine/core/dom/Element.h"
#include "sky/engine/core/dom/custom/CustomElementRegistrationContext.h"

namespace blink {

PassOwnPtr<CustomElementMicrotaskResolutionStep> CustomElementMicrotaskResolutionStep::create(PassRefPtr<CustomElementRegistrationContext> context, PassRefPtr<Element> element, const CustomElementDescriptor& descriptor)
{
    return adoptPtr(new CustomElementMicrotaskResolutionStep(context, element, descriptor));
}

CustomElementMicrotaskResolutionStep::CustomElementMicrotaskResolutionStep(PassRefPtr<CustomElementRegistrationContext> context, PassRefPtr<Element> element, const CustomElementDescriptor& descriptor)
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

} // namespace blink
