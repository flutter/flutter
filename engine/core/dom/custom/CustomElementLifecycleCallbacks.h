/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
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

#ifndef CustomElementLifecycleCallbacks_h
#define CustomElementLifecycleCallbacks_h

#include "wtf/RefCounted.h"
#include "wtf/text/AtomicString.h"

namespace blink {

class Element;

class CustomElementLifecycleCallbacks : public RefCounted<CustomElementLifecycleCallbacks> {
public:
    virtual ~CustomElementLifecycleCallbacks() { }

    enum CallbackType {
        None                     = 0,
        CreatedCallback          = 1 << 0,
        AttachedCallback         = 1 << 1,
        DetachedCallback         = 1 << 2,
        AttributeChangedCallback = 1 << 3
    };

    bool hasCallback(CallbackType type) const { return m_which & type; }

    virtual void created(Element*) = 0;
    virtual void attached(Element*) = 0;
    virtual void detached(Element*) = 0;
    virtual void attributeChanged(Element*, const AtomicString& name, const AtomicString& oldValue, const AtomicString& newValue) = 0;

protected:
    CustomElementLifecycleCallbacks(CallbackType which) : m_which(which) { }

private:
    CallbackType m_which;
};

}

#endif // CustomElementLifecycleCallbacks_h
