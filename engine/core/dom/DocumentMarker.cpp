/*
 * Copyright (C) 2011 Google Inc. All rights reserved.
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
#include "core/dom/DocumentMarker.h"

namespace blink {

DocumentMarkerDetails::~DocumentMarkerDetails()
{
}

class DocumentMarkerDescription FINAL : public DocumentMarkerDetails {
public:
    static PassRefPtrWillBeRawPtr<DocumentMarkerDescription> create(const String&);

    const String& description() const { return m_description; }
    virtual bool isDescription() const OVERRIDE { return true; }

private:
    explicit DocumentMarkerDescription(const String& description)
        : m_description(description)
    {
    }

    String m_description;
};

PassRefPtrWillBeRawPtr<DocumentMarkerDescription> DocumentMarkerDescription::create(const String& description)
{
    return adoptRefWillBeNoop(new DocumentMarkerDescription(description));
}

inline DocumentMarkerDescription* toDocumentMarkerDescription(DocumentMarkerDetails* details)
{
    if (details && details->isDescription())
        return static_cast<DocumentMarkerDescription*>(details);
    return 0;
}


class DocumentMarkerTextMatch FINAL : public DocumentMarkerDetails {
public:
    static PassRefPtrWillBeRawPtr<DocumentMarkerTextMatch> instanceFor(bool);

    bool activeMatch() const { return m_match; }
    virtual bool isTextMatch() const OVERRIDE { return true; }

private:
    explicit DocumentMarkerTextMatch(bool match)
        : m_match(match)
    {
    }

    bool m_match;
};

PassRefPtrWillBeRawPtr<DocumentMarkerTextMatch> DocumentMarkerTextMatch::instanceFor(bool match)
{
    DEFINE_STATIC_REF_WILL_BE_PERSISTENT(DocumentMarkerTextMatch, trueInstance, (adoptRefWillBeNoop(new DocumentMarkerTextMatch(true))));
    DEFINE_STATIC_REF_WILL_BE_PERSISTENT(DocumentMarkerTextMatch, falseInstance, (adoptRefWillBeNoop(new DocumentMarkerTextMatch(false))));
    return match ? trueInstance : falseInstance;
}

inline DocumentMarkerTextMatch* toDocumentMarkerTextMatch(DocumentMarkerDetails* details)
{
    if (details && details->isTextMatch())
        return static_cast<DocumentMarkerTextMatch*>(details);
    return 0;
}


DocumentMarker::DocumentMarker()
    : m_type(Spelling)
    , m_startOffset(0)
    , m_endOffset(0)
    , m_hash(0)
{
}

DocumentMarker::DocumentMarker(MarkerType type, unsigned startOffset, unsigned endOffset)
    : m_type(type)
    , m_startOffset(startOffset)
    , m_endOffset(endOffset)
    , m_hash(0)
{
}

DocumentMarker::DocumentMarker(MarkerType type, unsigned startOffset, unsigned endOffset, const String& description)
    : m_type(type)
    , m_startOffset(startOffset)
    , m_endOffset(endOffset)
    , m_details(description.isEmpty() ? nullptr : DocumentMarkerDescription::create(description))
    , m_hash(0)
{
}

DocumentMarker::DocumentMarker(MarkerType type, unsigned startOffset, unsigned endOffset, const String& description, uint32_t hash)
    : m_type(type)
    , m_startOffset(startOffset)
    , m_endOffset(endOffset)
    , m_details(description.isEmpty() ? nullptr : DocumentMarkerDescription::create(description))
    , m_hash(hash)
{
}

DocumentMarker::DocumentMarker(unsigned startOffset, unsigned endOffset, bool activeMatch)
    : m_type(DocumentMarker::TextMatch)
    , m_startOffset(startOffset)
    , m_endOffset(endOffset)
    , m_details(DocumentMarkerTextMatch::instanceFor(activeMatch))
    , m_hash(0)
{
}

DocumentMarker::DocumentMarker(MarkerType type, unsigned startOffset, unsigned endOffset, PassRefPtrWillBeRawPtr<DocumentMarkerDetails> details)
    : m_type(type)
    , m_startOffset(startOffset)
    , m_endOffset(endOffset)
    , m_details(details)
    , m_hash(0)
{
}

DocumentMarker::DocumentMarker(const DocumentMarker& marker)
    : m_type(marker.type())
    , m_startOffset(marker.startOffset())
    , m_endOffset(marker.endOffset())
    , m_details(marker.details())
    , m_hash(marker.hash())
{
}

void DocumentMarker::shiftOffsets(int delta)
{
    m_startOffset += delta;
    m_endOffset +=  delta;
}

void DocumentMarker::setActiveMatch(bool active)
{
    m_details = DocumentMarkerTextMatch::instanceFor(active);
}

const String& DocumentMarker::description() const
{
    if (DocumentMarkerDescription* details = toDocumentMarkerDescription(m_details.get()))
        return details->description();
    return emptyString();
}

bool DocumentMarker::activeMatch() const
{
    if (DocumentMarkerTextMatch* details = toDocumentMarkerTextMatch(m_details.get()))
        return details->activeMatch();
    return false;
}

void DocumentMarker::trace(Visitor* visitor)
{
    visitor->trace(m_details);
}

} // namespace blink
