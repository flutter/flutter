/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2003, 2004, 2006, 2007, 2008, 2009, 2010, 2011 Apple Inc.
 * All right reserved.
 * Copyright (C) 2010 Google Inc. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 *
 */

#ifndef BidiRunForLine_h
#define BidiRunForLine_h

#include "config.h"
#include "core/rendering/BidiRunForLine.h"

#include "core/rendering/InlineIterator.h"

namespace blink {

using namespace WTF::Unicode;

static RenderObject* firstRenderObjectForDirectionalityDetermination(
    RenderObject* root, RenderObject* current = 0)
{
    RenderObject* next = current;
    while (current) {
        if (isIsolated(current->style()->unicodeBidi())
            && (current->isRenderInline() || current->isRenderBlock())) {
            if (current != root)
                current = 0;
            else
                current = next;
            break;
        }
        current = current->parent();
    }

    if (!current)
        current = root->slowFirstChild();

    while (current) {
        next = 0;
        if (isIteratorTarget(current) && !(current->isText()
            && toRenderText(current)->isAllCollapsibleWhitespace()))
            break;

        if (!isIteratorTarget(current)
            && !isIsolated(current->style()->unicodeBidi()))
            next = current->slowFirstChild();

        if (!next) {
            while (current && current != root) {
                next = current->nextSibling();
                if (next)
                    break;
                current = current->parent();
            }
        }

        if (!next)
            break;

        current = next;
    }

    return current;
}

TextDirection determinePlaintextDirectionality(RenderObject* root,
    RenderObject* current = 0, unsigned pos = 0)
{
    InlineIterator iter(root,
        firstRenderObjectForDirectionalityDetermination(root, current), pos);
    InlineBidiResolver observer;
    observer.setStatus(BidiStatus(root->style()->direction(),
        isOverride(root->style()->unicodeBidi())));
    observer.setPositionIgnoringNestedIsolates(iter);
    return observer.determineParagraphDirectionality();
}

// FIXME: This should be a BidiStatus constructor or create method.
static inline BidiStatus statusWithDirection(TextDirection textDirection,
    bool isOverride)
{
    WTF::Unicode::Direction direction = textDirection == LTR
        ? LeftToRight
        : RightToLeft;
    RefPtr<BidiContext> context = BidiContext::create(
        textDirection == LTR ? 0 : 1, direction, isOverride, FromStyleOrDOM);

    // This copies BidiStatus and may churn the ref on BidiContext.
    // I doubt it matters.
    return BidiStatus(direction, direction, direction, context.release());
}

static inline void setupResolverToResumeInIsolate(InlineBidiResolver& resolver,
    RenderObject* root, RenderObject* startObject)
{
    if (root != startObject) {
        RenderObject* parent = startObject->parent();
        setupResolverToResumeInIsolate(resolver, root, parent);
        notifyObserverEnteredObject(&resolver, startObject);
    }
}

static void restoreIsolatedMidpointStates(InlineBidiResolver& topResolver,
    InlineBidiResolver& isolatedResolver)
{
    while (!isolatedResolver.isolatedRuns().isEmpty()) {
        BidiRun* run = isolatedResolver.isolatedRuns().last();
        isolatedResolver.isolatedRuns().removeLast();
        topResolver.setMidpointStateForIsolatedRun(run,
            isolatedResolver.midpointStateForIsolatedRun(run));
    }
}

void constructBidiRunsForLine(InlineBidiResolver& topResolver,
    BidiRunList<BidiRun>& bidiRuns, const InlineIterator& endOfLine,
    VisualDirectionOverride override, bool previousLineBrokeCleanly,
    bool isNewUBAParagraph)
{
    // FIXME: We should pass a BidiRunList into createBidiRunsForLine instead
    // of the resolver owning the runs.
    ASSERT(&topResolver.runs() == &bidiRuns);
    ASSERT(topResolver.position() != endOfLine);
    RenderObject* currentRoot = topResolver.position().root();
    topResolver.createBidiRunsForLine(endOfLine, override,
        previousLineBrokeCleanly);

    while (!topResolver.isolatedRuns().isEmpty()) {
        // It does not matter which order we resolve the runs as long as we
        // resolve them all.
        BidiRun* isolatedRun = topResolver.isolatedRuns().last();
        topResolver.isolatedRuns().removeLast();

        RenderObject* startObj = isolatedRun->object();

        // Only inlines make sense with unicode-bidi: isolate (blocks are
        // already isolated).
        // FIXME: Because enterIsolate is not passed a RenderObject, we have to
        // crawl up the tree to see which parent inline is the isolate. We could
        // change enterIsolate to take a RenderObject and do this logic there,
        // but that would be a layering violation for BidiResolver (which knows
        // nothing about RenderObject).
        RenderInline* isolatedInline = toRenderInline(
            highestContainingIsolateWithinRoot(startObj, currentRoot));
        ASSERT(isolatedInline);

        InlineBidiResolver isolatedResolver;
        LineMidpointState& isolatedLineMidpointState =
            isolatedResolver.midpointState();
        isolatedLineMidpointState = topResolver.midpointStateForIsolatedRun(
            isolatedRun);
        EUnicodeBidi unicodeBidi = isolatedInline->style()->unicodeBidi();
        TextDirection direction;
        if (unicodeBidi == Plaintext) {
            direction = determinePlaintextDirectionality(isolatedInline,
                isNewUBAParagraph ? startObj : 0);
        } else {
            ASSERT(unicodeBidi == Isolate || unicodeBidi == IsolateOverride);
            direction = isolatedInline->style()->direction();
        }
        isolatedResolver.setStatus(statusWithDirection(direction,
            isOverride(unicodeBidi)));

        setupResolverToResumeInIsolate(isolatedResolver, isolatedInline,
            startObj);

        // The starting position is the beginning of the first run within the
        // isolate that was identified during the earlier call to
        // createBidiRunsForLine. This can be but is not necessarily the first
        // run within the isolate.
        InlineIterator iter = InlineIterator(isolatedInline, startObj,
            isolatedRun->m_start);
        isolatedResolver.setPositionIgnoringNestedIsolates(iter);
        // We stop at the next end of line; we may re-enter this isolate in the
        // next call to constructBidiRuns().
        // FIXME: What should end and previousLineBrokeCleanly be?
        // rniwa says previousLineBrokeCleanly is just a WinIE hack and could
        // always be false here?
        isolatedResolver.createBidiRunsForLine(endOfLine, NoVisualOverride,
            previousLineBrokeCleanly);

        ASSERT(isolatedResolver.runs().runCount());
        if (isolatedResolver.runs().runCount())
            bidiRuns.replaceRunWithRuns(isolatedRun, isolatedResolver.runs());

        // If we encountered any nested isolate runs, just move them
        // to the top resolver's list for later processing.
        if (!isolatedResolver.isolatedRuns().isEmpty()) {
            topResolver.isolatedRuns().appendVector(
                isolatedResolver.isolatedRuns());
            currentRoot = isolatedInline;
            restoreIsolatedMidpointStates(topResolver, isolatedResolver);
        }
    }
}

} // namespace blink

#endif // BidiRunForLine_h
