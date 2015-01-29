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
#include "sky/engine/core/dom/custom/CustomElementScheduler.h"

#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/Element.h"
#include "sky/engine/core/dom/custom/CustomElementCallbackInvocation.h"
#include "sky/engine/core/dom/custom/CustomElementLifecycleCallbacks.h"
#include "sky/engine/core/dom/custom/CustomElementMicrotaskDispatcher.h"
#include "sky/engine/core/dom/custom/CustomElementMicrotaskImportStep.h"
#include "sky/engine/core/dom/custom/CustomElementMicrotaskResolutionStep.h"
#include "sky/engine/core/dom/custom/CustomElementMicrotaskRunQueue.h"
#include "sky/engine/core/dom/custom/CustomElementProcessingStack.h"
#include "sky/engine/core/dom/custom/CustomElementRegistrationContext.h"
#include "sky/engine/core/dom/custom/CustomElementSyncMicrotaskQueue.h"
#include "sky/engine/core/html/imports/HTMLImportChild.h"
#include "sky/engine/core/html/imports/HTMLImportsController.h"

namespace blink {

DEFINE_EMPTY_DESTRUCTOR_WILL_BE_REMOVED(CustomElementScheduler)

void CustomElementScheduler::scheduleCallback(PassRefPtr<CustomElementLifecycleCallbacks> callbacks, PassRefPtr<Element> element, CustomElementLifecycleCallbacks::CallbackType type)
{
    ASSERT(type != CustomElementLifecycleCallbacks::AttributeChangedCallback);

    if (!callbacks->hasCallback(type))
        return;

    CustomElementCallbackQueue& queue = instance().schedule(element);
    queue.append(CustomElementCallbackInvocation::createInvocation(callbacks, type));
}

void CustomElementScheduler::scheduleAttributeChangedCallback(PassRefPtr<CustomElementLifecycleCallbacks> callbacks, PassRefPtr<Element> element, const AtomicString& name, const AtomicString& oldValue, const AtomicString& newValue)
{
    if (!callbacks->hasCallback(CustomElementLifecycleCallbacks::AttributeChangedCallback))
        return;

    CustomElementCallbackQueue& queue = instance().schedule(element);
    queue.append(CustomElementCallbackInvocation::createAttributeChangedInvocation(callbacks, name, oldValue, newValue));
}

void CustomElementScheduler::resolveOrScheduleResolution(PassRefPtr<CustomElementRegistrationContext> context, PassRefPtr<Element> element)
{
    if (CustomElementProcessingStack::inCallbackDeliveryScope()) {
        context->resolve(element.get());
        return;
    }

    Document& document = element->document();
    OwnPtr<CustomElementMicrotaskResolutionStep> step = CustomElementMicrotaskResolutionStep::create(context, element);
    enqueueMicrotaskStep(document, step.release());
}

CustomElementMicrotaskImportStep* CustomElementScheduler::scheduleImport(HTMLImportChild* import)
{
    ASSERT(!import->isDone());
    ASSERT(import->parent());

    // Ownership of the new step is transferred to the parent
    // processing step, or the base queue.
    OwnPtr<CustomElementMicrotaskImportStep> step = CustomElementMicrotaskImportStep::create(import);
    CustomElementMicrotaskImportStep* rawStep = step.get();
    enqueueMicrotaskStep(*(import->parent()->document()), step.release(), import->isSync());
    return rawStep;
}

void CustomElementScheduler::enqueueMicrotaskStep(Document& document, PassOwnPtr<CustomElementMicrotaskStep> step, bool importIsSync)
{
    Document& master = document.importsController() ? *(document.importsController()->master()) : document;
    master.customElementMicrotaskRunQueue()->enqueue(document.importLoader(), step, importIsSync);
}

CustomElementScheduler& CustomElementScheduler::instance()
{
    DEFINE_STATIC_LOCAL(OwnPtr<CustomElementScheduler>, instance, (adoptPtr (new CustomElementScheduler())));
    return *instance;
}

CustomElementCallbackQueue& CustomElementScheduler::ensureCallbackQueue(PassRefPtr<Element> element)
{
    ElementCallbackQueueMap::ValueType* it = m_elementCallbackQueueMap.add(element.get(), nullptr).storedValue;
    if (!it->value)
        it->value = CustomElementCallbackQueue::create(element);
    return *it->value.get();
}

void CustomElementScheduler::callbackDispatcherDidFinish()
{
    if (CustomElementMicrotaskDispatcher::instance().elementQueueIsEmpty())
        instance().clearElementCallbackQueueMap();
}

void CustomElementScheduler::microtaskDispatcherDidFinish()
{
    ASSERT(!CustomElementProcessingStack::inCallbackDeliveryScope());
    instance().clearElementCallbackQueueMap();
}

void CustomElementScheduler::clearElementCallbackQueueMap()
{
    ElementCallbackQueueMap emptyMap;
    m_elementCallbackQueueMap.swap(emptyMap);
}

// Finds or creates the callback queue for element.
CustomElementCallbackQueue& CustomElementScheduler::schedule(PassRefPtr<Element> passElement)
{
    RefPtr<Element> element(passElement);

    CustomElementCallbackQueue& callbackQueue = ensureCallbackQueue(element);
    if (callbackQueue.inCreatedCallback()) {
        // Don't move it. Authors use the createdCallback like a
        // constructor. By not moving it, the createdCallback
        // completes before any other callbacks are entered for this
        // element.
        return callbackQueue;
    }

    if (CustomElementProcessingStack::inCallbackDeliveryScope()) {
        // The processing stack is active.
        CustomElementProcessingStack::instance().enqueue(&callbackQueue);
        return callbackQueue;
    }

    CustomElementMicrotaskDispatcher::instance().enqueue(&callbackQueue);
    return callbackQueue;
}

} // namespace blink
