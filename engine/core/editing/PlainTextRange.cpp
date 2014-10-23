/*
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2012 Apple Inc. All rights reserved.
 * Copyright (C) 2005 Alexey Proskuryakov.
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
#include "core/editing/PlainTextRange.h"

#include "core/dom/ContainerNode.h"
#include "core/dom/Document.h"
#include "core/dom/Range.h"
#include "core/editing/TextIterator.h"
#include "core/editing/VisiblePosition.h"

namespace blink {

PlainTextRange::PlainTextRange()
    : m_start(kNotFound)
    , m_end(kNotFound)
{
}

PlainTextRange::PlainTextRange(int location)
    : m_start(location)
    , m_end(location)
{
    ASSERT(location >= 0);
}

PlainTextRange::PlainTextRange(int start, int end)
    : m_start(start)
    , m_end(end)
{
    ASSERT(start >= 0);
    ASSERT(end >= 0);
    ASSERT(start <= end);
}

PassRefPtrWillBeRawPtr<Range> PlainTextRange::createRange(const ContainerNode& scope) const
{
    return createRangeFor(scope, ForGeneric);
}

PassRefPtrWillBeRawPtr<Range> PlainTextRange::createRangeForSelection(const ContainerNode& scope) const
{
    return createRangeFor(scope, ForSelection);
}

PassRefPtrWillBeRawPtr<Range> PlainTextRange::createRangeFor(const ContainerNode& scope, GetRangeFor getRangeFor) const
{
    ASSERT(isNotNull());

    RefPtrWillBeRawPtr<Range> resultRange = scope.document().createRange();

    size_t docTextPosition = 0;
    bool startRangeFound = false;

    RefPtrWillBeRawPtr<Range> textRunRange = nullptr;

    TextIteratorBehaviorFlags behaviorFlags = TextIteratorEmitsObjectReplacementCharacter;
    if (getRangeFor == ForSelection)
        behaviorFlags |= TextIteratorEmitsCharactersBetweenAllVisiblePositions;
    TextIterator it(rangeOfContents(const_cast<ContainerNode*>(&scope)).get(), behaviorFlags);

    // FIXME: the atEnd() check shouldn't be necessary, workaround for <http://bugs.webkit.org/show_bug.cgi?id=6289>.
    if (!start() && !length() && it.atEnd()) {
        textRunRange = it.range();

        resultRange->setStart(textRunRange->startContainer(), 0, ASSERT_NO_EXCEPTION);
        resultRange->setEnd(textRunRange->startContainer(), 0, ASSERT_NO_EXCEPTION);

        return resultRange.release();
    }

    for (; !it.atEnd(); it.advance()) {
        int len = it.length();
        textRunRange = it.range();

        bool foundStart = start() >= docTextPosition && start() <= docTextPosition + len;
        bool foundEnd = end() >= docTextPosition && end() <= docTextPosition + len;

        // Fix textRunRange->endPosition(), but only if foundStart || foundEnd, because it is only
        // in those cases that textRunRange is used.
        if (foundEnd) {
            // FIXME: This is a workaround for the fact that the end of a run
            // is often at the wrong position for emitted '\n's or if the
            // renderer of the current node is a replaced element.
            if (len == 1 && (it.characterAt(0) == '\n' || it.isInsideReplacedElement())) {
                it.advance();
                if (!it.atEnd()) {
                    RefPtrWillBeRawPtr<Range> range = it.range();
                    textRunRange->setEnd(range->startContainer(), range->startOffset(), ASSERT_NO_EXCEPTION);
                } else {
                    Position runStart = textRunRange->startPosition();
                    Position runEnd = VisiblePosition(runStart).next().deepEquivalent();
                    if (runEnd.isNotNull())
                        textRunRange->setEnd(runEnd.containerNode(), runEnd.computeOffsetInContainerNode(), ASSERT_NO_EXCEPTION);
                }
            }
        }

        if (foundStart) {
            startRangeFound = true;
            if (textRunRange->startContainer()->isTextNode()) {
                int offset = start() - docTextPosition;
                resultRange->setStart(textRunRange->startContainer(), offset + textRunRange->startOffset(), IGNORE_EXCEPTION);
            } else {
                if (start() == docTextPosition)
                    resultRange->setStart(textRunRange->startContainer(), textRunRange->startOffset(), IGNORE_EXCEPTION);
                else
                    resultRange->setStart(textRunRange->endContainer(), textRunRange->endOffset(), IGNORE_EXCEPTION);
            }
        }

        if (foundEnd) {
            if (textRunRange->startContainer()->isTextNode()) {
                int offset = end() - docTextPosition;
                resultRange->setEnd(textRunRange->startContainer(), offset + textRunRange->startOffset(), IGNORE_EXCEPTION);
            } else {
                if (end() == docTextPosition)
                    resultRange->setEnd(textRunRange->startContainer(), textRunRange->startOffset(), IGNORE_EXCEPTION);
                else
                    resultRange->setEnd(textRunRange->endContainer(), textRunRange->endOffset(), IGNORE_EXCEPTION);
            }
            docTextPosition += len;
            break;
        }
        docTextPosition += len;
    }

    if (!startRangeFound)
        return nullptr;

    if (length() && end() > docTextPosition) { // end() is out of bounds
        resultRange->setEnd(textRunRange->endContainer(), textRunRange->endOffset(), IGNORE_EXCEPTION);
    }

    return resultRange.release();
}

PlainTextRange PlainTextRange::create(const ContainerNode& scope, const Range& range)
{
    if (!range.startContainer())
        return PlainTextRange();

    // The critical assumption is that this only gets called with ranges that
    // concentrate on a given area containing the selection root. This is done
    // because of text fields and textareas. The DOM for those is not
    // directly in the document DOM, so ensure that the range does not cross a
    // boundary of one of those.
    if (range.startContainer() != &scope && !range.startContainer()->isDescendantOf(&scope))
        return PlainTextRange();
    if (range.endContainer() != scope && !range.endContainer()->isDescendantOf(&scope))
        return PlainTextRange();

    RefPtrWillBeRawPtr<Range> testRange = Range::create(scope.document(), const_cast<ContainerNode*>(&scope), 0, range.startContainer(), range.startOffset());
    ASSERT(testRange->startContainer() == &scope);
    size_t start = TextIterator::rangeLength(testRange.get());

    testRange->setEnd(range.endContainer(), range.endOffset(), IGNORE_EXCEPTION);
    ASSERT(testRange->startContainer() == &scope);
    size_t end = TextIterator::rangeLength(testRange.get());

    return PlainTextRange(start, end);
}

}
