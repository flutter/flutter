/*
 * Copyright (C) 2010 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "core/editing/SpellCheckRequester.h"

#include "core/dom/Document.h"
#include "core/dom/DocumentMarkerController.h"
#include "core/dom/Node.h"
#include "core/editing/SpellChecker.h"
#include "core/frame/LocalFrame.h"
#include "core/frame/Settings.h"
#include "platform/text/TextCheckerClient.h"

namespace blink {

SpellCheckRequest::SpellCheckRequest(
    PassRefPtrWillBeRawPtr<Range> checkingRange,
    PassRefPtrWillBeRawPtr<Range> paragraphRange,
    const String& text,
    TextCheckingTypeMask mask,
    TextCheckingProcessType processType,
    const Vector<uint32_t>& documentMarkersInRange,
    const Vector<unsigned>& documentMarkerOffsets,
    int requestNumber)
    : m_requester(0)
    , m_checkingRange(checkingRange)
    , m_paragraphRange(paragraphRange)
    , m_rootEditableElement(m_checkingRange->startContainer()->rootEditableElement())
    , m_requestData(unrequestedTextCheckingSequence, text, mask, processType, documentMarkersInRange, documentMarkerOffsets)
    , m_requestNumber(requestNumber)
{
}

SpellCheckRequest::~SpellCheckRequest()
{
}

// static
PassRefPtr<SpellCheckRequest> SpellCheckRequest::create(TextCheckingTypeMask textCheckingOptions, TextCheckingProcessType processType, PassRefPtrWillBeRawPtr<Range> checkingRange, PassRefPtrWillBeRawPtr<Range> paragraphRange, int requestNumber)
{
    ASSERT(checkingRange);
    ASSERT(paragraphRange);

    String text = checkingRange->text();
    if (!text.length())
        return PassRefPtr<SpellCheckRequest>();

    const DocumentMarkerVector& markers = checkingRange->ownerDocument().markers().markersInRange(checkingRange.get(), DocumentMarker::SpellCheckClientMarkers());
    Vector<uint32_t> hashes(markers.size());
    Vector<unsigned> offsets(markers.size());
    for (size_t i = 0; i < markers.size(); i++) {
        hashes[i] = markers[i]->hash();
        offsets[i] = markers[i]->startOffset();
    }

    return adoptRef(new SpellCheckRequest(checkingRange, paragraphRange, text, textCheckingOptions, processType, hashes, offsets, requestNumber));
}

const TextCheckingRequestData& SpellCheckRequest::data() const
{
    return m_requestData;
}

void SpellCheckRequest::didSucceed(const Vector<TextCheckingResult>& results)
{
    if (!m_requester)
        return;
    SpellCheckRequester* requester = m_requester;
    m_requester = 0;
    requester->didCheckSucceed(m_requestData.sequence(), results);
}

void SpellCheckRequest::didCancel()
{
    if (!m_requester)
        return;
    SpellCheckRequester* requester = m_requester;
    m_requester = 0;
    requester->didCheckCancel(m_requestData.sequence());
}

void SpellCheckRequest::setCheckerAndSequence(SpellCheckRequester* requester, int sequence)
{
    ASSERT(!m_requester);
    ASSERT(m_requestData.sequence() == unrequestedTextCheckingSequence);
    m_requester = requester;
    m_requestData.m_sequence = sequence;
}

void SpellCheckRequest::requesterDestroyed()
{
    m_requester = 0;
}

SpellCheckRequester::SpellCheckRequester(LocalFrame& frame)
    : m_frame(frame)
    , m_lastRequestSequence(0)
    , m_lastProcessedSequence(0)
    , m_timerToProcessQueuedRequest(this, &SpellCheckRequester::timerFiredToProcessQueuedRequest)
{
}

SpellCheckRequester::~SpellCheckRequester()
{
    if (m_processingRequest)
        m_processingRequest->requesterDestroyed();
    for (RequestQueue::iterator i = m_requestQueue.begin(); i != m_requestQueue.end(); ++i)
        (*i)->requesterDestroyed();
}

TextCheckerClient& SpellCheckRequester::client() const
{
    return m_frame.spellChecker().textChecker();
}

void SpellCheckRequester::timerFiredToProcessQueuedRequest(Timer<SpellCheckRequester>*)
{
    ASSERT(!m_requestQueue.isEmpty());
    if (m_requestQueue.isEmpty())
        return;

    invokeRequest(m_requestQueue.takeFirst());
}

bool SpellCheckRequester::isAsynchronousEnabled() const
{
    return m_frame.settings() && m_frame.settings()->asynchronousSpellCheckingEnabled();
}

bool SpellCheckRequester::canCheckAsynchronously(Range* range) const
{
    return isCheckable(range) && isAsynchronousEnabled();
}

bool SpellCheckRequester::isCheckable(Range* range) const
{
    if (!range || !range->firstNode() || !range->firstNode()->renderer())
        return false;
    const Node* node = range->startContainer();
    if (node && node->isElementNode() && !toElement(node)->isSpellCheckingEnabled())
        return false;
    return true;
}

void SpellCheckRequester::requestCheckingFor(PassRefPtr<SpellCheckRequest> request)
{
    if (!request || !canCheckAsynchronously(request->paragraphRange().get()))
        return;

    ASSERT(request->data().sequence() == unrequestedTextCheckingSequence);
    int sequence = ++m_lastRequestSequence;
    if (sequence == unrequestedTextCheckingSequence)
        sequence = ++m_lastRequestSequence;

    request->setCheckerAndSequence(this, sequence);

    if (m_timerToProcessQueuedRequest.isActive() || m_processingRequest) {
        enqueueRequest(request);
        return;
    }

    invokeRequest(request);
}

void SpellCheckRequester::cancelCheck()
{
    if (m_processingRequest)
        m_processingRequest->didCancel();
}

void SpellCheckRequester::invokeRequest(PassRefPtr<SpellCheckRequest> request)
{
    ASSERT(!m_processingRequest);
    m_processingRequest = request;
    client().requestCheckingOfString(m_processingRequest);
}

void SpellCheckRequester::enqueueRequest(PassRefPtr<SpellCheckRequest> request)
{
    ASSERT(request);
    bool continuation = false;
    if (!m_requestQueue.isEmpty()) {
        RefPtr<SpellCheckRequest> lastRequest = m_requestQueue.last();
        // It's a continuation if the number of the last request got incremented in the new one and
        // both apply to the same editable.
        continuation = request->rootEditableElement() == lastRequest->rootEditableElement()
            && request->requestNumber() == lastRequest->requestNumber() + 1;
    }

    // Spellcheck requests for chunks of text in the same element should not overwrite each other.
    if (!continuation) {
        for (RequestQueue::iterator it = m_requestQueue.begin(); it != m_requestQueue.end(); ++it) {
            if (request->rootEditableElement() != (*it)->rootEditableElement())
                continue;

            *it = request;
            return;
        }
    }

    m_requestQueue.append(request);
}

void SpellCheckRequester::didCheck(int sequence, const Vector<TextCheckingResult>& results)
{
    ASSERT(m_processingRequest);
    ASSERT(m_processingRequest->data().sequence() == sequence);
    if (m_processingRequest->data().sequence() != sequence) {
        m_requestQueue.clear();
        return;
    }

    m_frame.spellChecker().markAndReplaceFor(m_processingRequest, results);

    if (m_lastProcessedSequence < sequence)
        m_lastProcessedSequence = sequence;

    m_processingRequest.clear();
    if (!m_requestQueue.isEmpty())
        m_timerToProcessQueuedRequest.startOneShot(0, FROM_HERE);
}

void SpellCheckRequester::didCheckSucceed(int sequence, const Vector<TextCheckingResult>& results)
{
    TextCheckingRequestData requestData = m_processingRequest->data();
    if (requestData.sequence() == sequence) {
        DocumentMarker::MarkerTypes markers = DocumentMarker::SpellCheckClientMarkers();
        if (!requestData.maskContains(TextCheckingTypeSpelling))
            markers.remove(DocumentMarker::Spelling);
        if (!requestData.maskContains(TextCheckingTypeGrammar))
            markers.remove(DocumentMarker::Grammar);
        m_frame.document()->markers().removeMarkers(m_processingRequest->checkingRange().get(), markers);
    }
    didCheck(sequence, results);
}

void SpellCheckRequester::didCheckCancel(int sequence)
{
    Vector<TextCheckingResult> results;
    didCheck(sequence, results);
}

} // namespace blink
