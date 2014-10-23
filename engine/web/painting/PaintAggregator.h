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

#ifndef PaintAggregator_h
#define PaintAggregator_h

#include "platform/geometry/IntPoint.h"
#include "platform/geometry/IntRect.h"
#include "wtf/Vector.h"

namespace blink {

// This class is responsible for aggregating multiple invalidation and scroll
// commands to produce a scroll and repaint sequence.
class PaintAggregator {
public:
    // This structure describes an aggregation of invalidateRect and scrollRect
    // calls. If |scrollRect| is non-empty, then that rect should be scrolled
    // by the amount specified by |scrollDelta|. If |paintRects| is non-empty,
    // then those rects should be repainted. If |scrollRect| and |paintRects|
    // are non-empty, then scrolling should be performed before repainting.
    // |scrollDelta| can only specify scrolling in one direction (i.e., the x
    // and y members cannot both be non-zero).
    struct PendingUpdate {
        PendingUpdate();
        ~PendingUpdate();

        // Returns the rect damaged by scrolling within |scrollRect| by
        // |scrollDelta|. This rect must be repainted.
        blink::IntRect calculateScrollDamage() const;

        // Returns the smallest rect containing all paint rects.
        blink::IntRect calculatePaintBounds() const;

        blink::IntPoint scrollDelta;
        blink::IntRect scrollRect;
        WTF::Vector<blink::IntRect> paintRects;
    };

    // There is a PendingUpdate if invalidateRect or scrollRect were called and
    // ClearPendingUpdate was not called.
    bool hasPendingUpdate() const;
    void clearPendingUpdate();

    // Fills |update| and clears the pending update.
    void popPendingUpdate(PendingUpdate*);

    // The given rect should be repainted.
    void invalidateRect(const blink::IntRect&);

    // The given rect should be scrolled by the given amounts.
    void scrollRect(int dx, int dy, const blink::IntRect& clipRect);

private:
    blink::IntRect scrollPaintRect(const blink::IntRect& paintRect, int dx, int dy) const;
    bool shouldInvalidateScrollRect(const blink::IntRect&) const;
    void invalidateScrollRect();
    void combinePaintRects();

    PendingUpdate m_update;
};

} // namespace blink

#endif
