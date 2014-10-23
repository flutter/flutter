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

#ifndef CustomElementScheduler_h
#define CustomElementScheduler_h

#include "core/dom/custom/CustomElementCallbackQueue.h"
#include "core/dom/custom/CustomElementLifecycleCallbacks.h"
#include "platform/heap/Handle.h"
#include "wtf/HashMap.h"
#include "wtf/OwnPtr.h"
#include "wtf/PassRefPtr.h"
#include "wtf/text/AtomicString.h"

namespace blink {

class CustomElementDescriptor;
class CustomElementMicrotaskImportStep;
class CustomElementMicrotaskStep;
class CustomElementRegistrationContext;
class Document;
class Element;
class HTMLImportChild;

class CustomElementScheduler FINAL : public NoBaseWillBeGarbageCollected<CustomElementScheduler> {
    DECLARE_EMPTY_DESTRUCTOR_WILL_BE_REMOVED(CustomElementScheduler);
public:

    static void scheduleCallback(PassRefPtr<CustomElementLifecycleCallbacks>, PassRefPtrWillBeRawPtr<Element>, CustomElementLifecycleCallbacks::CallbackType);
    static void scheduleAttributeChangedCallback(PassRefPtr<CustomElementLifecycleCallbacks>, PassRefPtrWillBeRawPtr<Element>, const AtomicString& name, const AtomicString& oldValue, const AtomicString& newValue);

    static void resolveOrScheduleResolution(PassRefPtrWillBeRawPtr<CustomElementRegistrationContext>, PassRefPtrWillBeRawPtr<Element>, const CustomElementDescriptor&);
    static CustomElementMicrotaskImportStep* scheduleImport(HTMLImportChild*);

    static void microtaskDispatcherDidFinish();
    static void callbackDispatcherDidFinish();

    void trace(Visitor*);

private:
    CustomElementScheduler() { }

    static CustomElementScheduler& instance();
    static void enqueueMicrotaskStep(Document&, PassOwnPtrWillBeRawPtr<CustomElementMicrotaskStep>, bool importIsSync = true);

    CustomElementCallbackQueue& ensureCallbackQueue(PassRefPtrWillBeRawPtr<Element>);
    CustomElementCallbackQueue& schedule(PassRefPtrWillBeRawPtr<Element>);

    // FIXME: Consider moving the element's callback queue to
    // ElementRareData. Then the scheduler can become completely
    // static.
    void clearElementCallbackQueueMap();

    // The element -> callback queue map is populated by the scheduler
    // and owns the lifetimes of the CustomElementCallbackQueues.
    typedef WillBeHeapHashMap<RawPtrWillBeMember<Element>, OwnPtrWillBeMember<CustomElementCallbackQueue> > ElementCallbackQueueMap;
    ElementCallbackQueueMap m_elementCallbackQueueMap;
};

}

#endif // CustomElementScheduler_h
