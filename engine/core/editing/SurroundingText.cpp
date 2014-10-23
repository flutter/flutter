/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
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
#include "core/editing/SurroundingText.h"

#include "core/dom/Document.h"
#include "core/dom/Element.h"
#include "core/dom/Position.h"
#include "core/dom/Range.h"
#include "core/editing/TextIterator.h"

namespace blink {

SurroundingText::SurroundingText(const Range& range, unsigned maxLength)
    : m_startOffsetInContent(0)
    , m_endOffsetInContent(0)
{
    initialize(range.startPosition(), range.endPosition(), maxLength);
}

SurroundingText::SurroundingText(const Position& position, unsigned maxLength)
    : m_startOffsetInContent(0)
    , m_endOffsetInContent(0)
{
    initialize(position, position, maxLength);
}

void SurroundingText::initialize(const Position& startPosition, const Position& endPosition, unsigned maxLength)
{
    ASSERT(startPosition.document() == endPosition.document());

    const unsigned halfMaxLength = maxLength / 2;

    Document* document = startPosition.document();
    // The position will have no document if it is null (as in no position).
    if (!document)
        return;

    // The forward range starts at the selection end and ends at the document's
    // end. It will then be updated to only contain the text in the text in the
    // right range around the selection.
    RefPtrWillBeRawPtr<Range> forwardRange = Range::create(*document, endPosition, lastPositionInNode(document->documentElement()).parentAnchoredEquivalent());
    CharacterIterator forwardIterator(forwardRange.get());
    // FIXME: why do we stop going trough the text if we were not able to select something on the right?
    if (!forwardIterator.atEnd())
        forwardIterator.advance(maxLength - halfMaxLength);

    forwardRange = forwardIterator.range();
    if (!forwardRange || !Range::create(*document, endPosition, forwardRange->startPosition())->text().length()) {
        ASSERT(forwardRange);
        return;
    }

    // Same as with the forward range but with the backward range. The range
    // starts at the document's start and ends at the selection start and will
    // be updated.
    RefPtrWillBeRawPtr<Range> backwardsRange = Range::create(*document, firstPositionInNode(document->documentElement()).parentAnchoredEquivalent(), startPosition);
    BackwardsCharacterIterator backwardsIterator(backwardsRange.get());
    if (!backwardsIterator.atEnd())
        backwardsIterator.advance(halfMaxLength);

    backwardsRange = backwardsIterator.range();
    if (!backwardsRange) {
        ASSERT(backwardsRange);
        return;
    }

    m_startOffsetInContent = Range::create(*document, backwardsRange->endPosition(), startPosition)->text().length();
    m_endOffsetInContent = Range::create(*document, backwardsRange->endPosition(), endPosition)->text().length();
    m_contentRange = Range::create(*document, backwardsRange->endPosition(), forwardRange->startPosition());
    ASSERT(m_contentRange);
}

PassRefPtrWillBeRawPtr<Range> SurroundingText::rangeFromContentOffsets(unsigned startOffsetInContent, unsigned endOffsetInContent)
{
    if (startOffsetInContent >= endOffsetInContent || endOffsetInContent > content().length())
        return nullptr;

    CharacterIterator iterator(m_contentRange.get());

    ASSERT(!iterator.atEnd());
    iterator.advance(startOffsetInContent);

    ASSERT(iterator.range());
    Position start = iterator.range()->startPosition();

    ASSERT(!iterator.atEnd());
    iterator.advance(endOffsetInContent - startOffsetInContent);

    ASSERT(iterator.range());
    Position end = iterator.range()->startPosition();

    ASSERT(start.document());
    return Range::create(*start.document(), start, end);
}

String SurroundingText::content() const
{
    if (m_contentRange)
        return m_contentRange->text();
    return String();
}

unsigned SurroundingText::startOffsetInContent() const
{
    return m_startOffsetInContent;
}

unsigned SurroundingText::endOffsetInContent() const
{
    return m_endOffsetInContent;
}

} // namespace blink
