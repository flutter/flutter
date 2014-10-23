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
#include "core/dom/custom/CustomElementObserver.h"

#include "core/dom/Element.h"

namespace blink {

// Maps elements to the observer watching them. At most one per
// element at a time.
typedef WillBeHeapHashMap<RawPtrWillBeWeakMember<Element>, RawPtrWillBeMember<CustomElementObserver> > ElementObserverMap;

static ElementObserverMap& elementObservers()
{
    DEFINE_STATIC_LOCAL(OwnPtrWillBePersistent<ElementObserverMap>, map, (adoptPtrWillBeNoop(new ElementObserverMap())));
    return *map;
}

void CustomElementObserver::notifyElementDidFinishParsingChildren(Element* element)
{
    ElementObserverMap::iterator it = elementObservers().find(element);
    if (it == elementObservers().end())
        return;
    it->value->elementDidFinishParsingChildren(element);
}

void CustomElementObserver::notifyElementWasDestroyed(Element* element)
{
    ElementObserverMap::iterator it = elementObservers().find(element);
    if (it == elementObservers().end())
        return;
    it->value->elementWasDestroyed(element);
}

void CustomElementObserver::observe(Element* element)
{
    ElementObserverMap::AddResult result = elementObservers().add(element, this);
    ASSERT_UNUSED(result, result.isNewEntry);
}

void CustomElementObserver::unobserve(Element* element)
{
    CustomElementObserver* observer = elementObservers().take(element);
    ASSERT_UNUSED(observer, observer == this);
}

} // namespace blink
