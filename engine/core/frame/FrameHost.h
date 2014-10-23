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

#ifndef FrameHost_h
#define FrameHost_h

#include "core/frame/PinchViewport.h"
#include "platform/heap/Handle.h"
#include "wtf/FastAllocBase.h"
#include "wtf/Noncopyable.h"
#include "wtf/OwnPtr.h"
#include "wtf/PassOwnPtr.h"

namespace blink {

class Chrome;
class EventHandlerRegistry;
class Page;
class PinchViewport;
class Settings;
class UseCounter;
class Visitor;

// FrameHost is the set of global data shared between multiple frames
// and is provided by the embedder to each frame when created.
// FrameHost currently corresponds to the Page object in core/page
// however the concept of a Page is moving up out of Blink.
// In an out-of-process iframe world, a single Page may have
// multiple frames in different process, thus Page becomes a
// browser-level concept and Blink core/ only knows about its LocalFrame (and FrameHost).
// Separating Page from the rest of core/ through this indirection
// allows us to slowly refactor Page without breaking the rest of core.
class FrameHost FINAL : public NoBaseWillBeGarbageCollectedFinalized<FrameHost> {
    WTF_MAKE_NONCOPYABLE(FrameHost); WTF_MAKE_FAST_ALLOCATED_WILL_BE_REMOVED;
public:
    static PassOwnPtrWillBeRawPtr<FrameHost> create(Page&);
    ~FrameHost();

    // Careful: This function will eventually be removed.
    Page& page() const { return *m_page; }
    Settings& settings() const;
    Chrome& chrome() const;
    UseCounter& useCounter() const;

    // Corresponds to pixel density of the device where this Page is
    // being displayed. In multi-monitor setups this can vary between pages.
    // This value does not account for Page zoom, use LocalFrame::devicePixelRatio instead.
    float deviceScaleFactor() const;

    PinchViewport& pinchViewport() const;
    EventHandlerRegistry& eventHandlerRegistry() const;

    void trace(Visitor*);

private:
    explicit FrameHost(Page&);

    RawPtrWillBeMember<Page> m_page;
    const OwnPtr<PinchViewport> m_pinchViewport;
    const OwnPtrWillBeMember<EventHandlerRegistry> m_eventHandlerRegistry;
};

}

#endif // FrameHost_h
