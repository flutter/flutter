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

#ifndef SKY_ENGINE_CORE_DOM_CUSTOM_CUSTOMELEMENTMICROTASKRESOLUTIONSTEP_H_
#define SKY_ENGINE_CORE_DOM_CUSTOM_CUSTOMELEMENTMICROTASKRESOLUTIONSTEP_H_

#include "sky/engine/core/dom/custom/CustomElementDescriptor.h"
#include "sky/engine/core/dom/custom/CustomElementMicrotaskStep.h"
#include "sky/engine/platform/heap/Handle.h"
#include "sky/engine/wtf/PassOwnPtr.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefPtr.h"

namespace blink {

class CustomElementRegistrationContext;
class Element;

class CustomElementMicrotaskResolutionStep : public CustomElementMicrotaskStep {
    WTF_MAKE_NONCOPYABLE(CustomElementMicrotaskResolutionStep);
public:
    static PassOwnPtr<CustomElementMicrotaskResolutionStep> create(PassRefPtr<CustomElementRegistrationContext>, PassRefPtr<Element>, const CustomElementDescriptor&);

    virtual ~CustomElementMicrotaskResolutionStep();

private:
    CustomElementMicrotaskResolutionStep(PassRefPtr<CustomElementRegistrationContext>, PassRefPtr<Element>, const CustomElementDescriptor&);

    virtual Result process() override;

    RefPtr<CustomElementRegistrationContext> m_context;
    RefPtr<Element> m_element;
    CustomElementDescriptor m_descriptor;
};

}

#endif  // SKY_ENGINE_CORE_DOM_CUSTOM_CUSTOMELEMENTMICROTASKRESOLUTIONSTEP_H_
