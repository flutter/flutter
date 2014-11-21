// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef ClipRectsCache_h
#define ClipRectsCache_h

#include "sky/engine/core/rendering/ClipRects.h"

namespace blink {

enum ClipRectsCacheSlot {
    // Relative to the ancestor treated as the root (e.g. transformed layer). Used for hit testing.
    RootRelativeClipRects,

    // Relative to the RenderView's layer. Used for compositing overlap testing.
    AbsoluteClipRects,

    // Relative to painting ancestor. Used for painting.
    PaintingClipRects,
    PaintingClipRectsIgnoringOverflowClip,

    NumberOfClipRectsCacheSlots,
    UncachedClipRects,
};

class ClipRectsCache {
    WTF_MAKE_FAST_ALLOCATED;
public:
    struct Entry {
        Entry()
            : root(0)
        {
        }

        const RenderLayer* root;
        RefPtr<ClipRects> clipRects;
    };

    Entry& get(ClipRectsCacheSlot slot)
    {
        ASSERT(slot < NumberOfClipRectsCacheSlots);
        return m_entries[slot];
    }

    void clear(ClipRectsCacheSlot slot)
    {
        ASSERT(slot < NumberOfClipRectsCacheSlots);
        m_entries[slot] = Entry();
    }

private:
    Entry m_entries[NumberOfClipRectsCacheSlots];
};

} // namespace blink

#endif // ClipRectsCache_h
