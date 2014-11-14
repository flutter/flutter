/*
 * Copyright (C) 2014 Google Inc. All rights reserved.
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

#include "config.h"

#include "public/web/WebLeakDetector.h"

#include "bindings/core/v8/V8Binding.h"
#include "bindings/core/v8/V8GCController.h"
#include "core/dom/Document.h"
#include "core/fetch/MemoryCache.h"
#include "core/fetch/ResourceFetcher.h"
#include "core/inspector/InspectorCounters.h"
#include "core/rendering/RenderObject.h"
#include "platform/Timer.h"
#include "public/web/WebDocument.h"
#include "public/web/WebLocalFrame.h"

#include <v8.h>

namespace blink {

namespace {

// FIXME: Oilpan: It may take multiple GC to collect on-heap objects referenced from off-heap objects.
// Please see comment in Heap::collectAllGarbage()
static const int kNumberOfGCsToClaimChains = 5;

class WebLeakDetectorImpl final : public WebLeakDetector {
WTF_MAKE_NONCOPYABLE(WebLeakDetectorImpl);
public:
    explicit WebLeakDetectorImpl(WebLeakDetectorClient* client)
        : m_client(client)
        , m_delayedGCAndReportTimer(this, &WebLeakDetectorImpl::delayedGCAndReport)
        , m_delayedReportTimer(this, &WebLeakDetectorImpl::delayedReport)
        , m_numberOfGCNeeded(0)
    {
        ASSERT(m_client);
    }

    virtual ~WebLeakDetectorImpl() { }

    virtual void collectGarbageAndGetDOMCounts(WebLocalFrame*) override;

private:
    void delayedGCAndReport(Timer<WebLeakDetectorImpl>*);
    void delayedReport(Timer<WebLeakDetectorImpl>*);

    WebLeakDetectorClient* m_client;
    Timer<WebLeakDetectorImpl> m_delayedGCAndReportTimer;
    Timer<WebLeakDetectorImpl> m_delayedReportTimer;
    int m_numberOfGCNeeded;
};

void WebLeakDetectorImpl::collectGarbageAndGetDOMCounts(WebLocalFrame* frame)
{
    memoryCache()->evictResources();

    {
        RefPtr<Document> document = PassRefPtr<Document>(frame->document());
        if (ResourceFetcher* fetcher = document->fetcher())
            fetcher->garbageCollectDocumentResources();
    }

    // FIXME: HTML5 Notification should be closed because notification affects the result of number of DOM objects.

    for (int i = 0; i < kNumberOfGCsToClaimChains; ++i)
        V8GCController::collectGarbage(v8::Isolate::GetCurrent());
    // Note: Oilpan precise GC is scheduled at the end of the event loop.

    // Task queue may contain delayed object destruction tasks.
    // This method is called from navigation hook inside FrameLoader,
    // so previous document is still held by the loader until the next event loop.
    // Complete all pending tasks before proceeding to gc.
    m_numberOfGCNeeded = 2;
    m_delayedGCAndReportTimer.startOneShot(0, FROM_HERE);
}

void WebLeakDetectorImpl::delayedGCAndReport(Timer<WebLeakDetectorImpl>*)
{
    // We do a second and third GC here to address flakiness
    // The second GC is necessary as Resource GC may have postponed clean-up tasks to next event loop.
    // The third GC is necessary for cleaning up Document after worker object died.

    for (int i = 0; i < kNumberOfGCsToClaimChains; ++i)
        V8GCController::collectGarbage(V8PerIsolateData::mainThreadIsolate());
    // Note: Oilpan precise GC is scheduled at the end of the event loop.

    // Inspect counters on the next event loop.
    if (--m_numberOfGCNeeded)
        m_delayedGCAndReportTimer.startOneShot(0, FROM_HERE);
    else
        m_delayedReportTimer.startOneShot(0, FROM_HERE);
}

void WebLeakDetectorImpl::delayedReport(Timer<WebLeakDetectorImpl>*)
{
    ASSERT(m_client);

    WebLeakDetectorClient::Result result;
    result.numberOfLiveDocuments = InspectorCounters::counterValue(InspectorCounters::DocumentCounter);
    result.numberOfLiveNodes = InspectorCounters::counterValue(InspectorCounters::NodeCounter);
    result.numberOfLiveRenderObjects = RenderObject::instanceCount();
    result.numberOfLiveResources = Resource::instanceCount();

    m_client->onLeakDetectionComplete(result);

#ifndef NDEBUG
    showLiveDocumentInstances();
#endif
}

} // namespace

WebLeakDetector* WebLeakDetector::create(WebLeakDetectorClient* client)
{
    return new WebLeakDetectorImpl(client);
}

} // namespace blink
