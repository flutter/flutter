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

#ifndef LinkResource_h
#define LinkResource_h

#include "core/fetch/FetchRequest.h"
#include "platform/heap/Handle.h"
#include "platform/weborigin/KURL.h"
#include "wtf/text/WTFString.h"

namespace blink {

class HTMLLinkElement;

class LinkResource : public NoBaseWillBeGarbageCollectedFinalized<LinkResource>  {
    WTF_MAKE_NONCOPYABLE(LinkResource); WTF_MAKE_FAST_ALLOCATED_WILL_BE_REMOVED;
public:
    enum Type {
        Style,
        Import,
        Manifest
    };

    explicit LinkResource(HTMLLinkElement*);
    virtual ~LinkResource();

    bool shouldLoadResource() const;
    LocalFrame* loadingFrame() const;

    virtual Type type() const = 0;
    virtual void process() = 0;
    virtual void ownerRemoved() { }
    virtual void ownerInserted() { }
    virtual bool hasLoaded() const = 0;

    virtual void trace(Visitor*);

protected:
    RawPtrWillBeMember<HTMLLinkElement> m_owner;
};

class LinkRequestBuilder {
    STACK_ALLOCATED();
public:
    explicit LinkRequestBuilder(HTMLLinkElement* owner);

    bool isValid() const { return !m_url.isEmpty() && m_url.isValid(); }
    const KURL& url() const { return m_url; }
    const AtomicString& charset() const { return m_charset; }
    FetchRequest build(bool blocking) const;

private:
    RawPtrWillBeMember<HTMLLinkElement> m_owner;
    KURL m_url;
    AtomicString m_charset;
};

} // namespace blink

#endif // LinkResource_h
