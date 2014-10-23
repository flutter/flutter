/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2003, 2004, 2006, 2007, 2009, 2010 Apple Inc. All right reserved.
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

#include "config.h"
#include "platform/text/BidiContext.h"

#include "wtf/StdLibExtras.h"
#include "wtf/Vector.h"

namespace blink {

using namespace WTF::Unicode;

struct SameSizeAsBidiContext : public RefCounted<SameSizeAsBidiContext> {
    uint32_t bitfields : 16;
    void* parent;
};

COMPILE_ASSERT(sizeof(BidiContext) == sizeof(SameSizeAsBidiContext), BidiContext_should_stay_small);

inline PassRefPtr<BidiContext> BidiContext::createUncached(unsigned char level, Direction direction, bool override, BidiEmbeddingSource source, BidiContext* parent)
{
    return adoptRef(new BidiContext(level, direction, override, source, parent));
}

PassRefPtr<BidiContext> BidiContext::create(unsigned char level, Direction direction, bool override, BidiEmbeddingSource source, BidiContext* parent)
{
    ASSERT(direction == (level % 2 ? RightToLeft : LeftToRight));

    if (parent)
        return createUncached(level, direction, override, source, parent);

    ASSERT(level <= 1);
    if (!level) {
        if (!override) {
            DEFINE_STATIC_REF(BidiContext, ltrContext, (createUncached(0, LeftToRight, false, FromStyleOrDOM, 0)));
            return ltrContext;
        }

        DEFINE_STATIC_REF(BidiContext, ltrOverrideContext, (createUncached(0, LeftToRight, true, FromStyleOrDOM, 0)));
        return ltrOverrideContext;
    }

    if (!override) {
        DEFINE_STATIC_REF(BidiContext, rtlContext, (createUncached(1, RightToLeft, false, FromStyleOrDOM, 0)));
        return rtlContext;
    }

    DEFINE_STATIC_REF(BidiContext, rtlOverrideContext, (createUncached(1, RightToLeft, true, FromStyleOrDOM, 0)));
    return rtlOverrideContext;
}

static inline PassRefPtr<BidiContext> copyContextAndRebaselineLevel(BidiContext* context, BidiContext* parent)
{
    ASSERT(context);
    unsigned char newLevel = parent ? parent->level() : 0;
    if (context->dir() == RightToLeft)
        newLevel = nextGreaterOddLevel(newLevel);
    else if (parent)
        newLevel = nextGreaterEvenLevel(newLevel);

    return BidiContext::create(newLevel, context->dir(), context->override(), context->source(), parent);
}

// The BidiContext stack must be immutable -- they're re-used for re-layout after
// DOM modification/editing -- so we copy all the non-unicode contexts, and
// recalculate their levels.
PassRefPtr<BidiContext> BidiContext::copyStackRemovingUnicodeEmbeddingContexts()
{
    Vector<BidiContext*, 64> contexts;
    for (BidiContext* iter = this; iter; iter = iter->parent()) {
        if (iter->source() != FromUnicode)
            contexts.append(iter);
    }
    ASSERT(contexts.size());

    RefPtr<BidiContext> topContext = copyContextAndRebaselineLevel(contexts.last(), 0);
    for (int i = contexts.size() - 1; i > 0; --i)
        topContext = copyContextAndRebaselineLevel(contexts[i - 1], topContext.get());

    return topContext.release();
}

bool operator==(const BidiContext& c1, const BidiContext& c2)
{
    if (&c1 == &c2)
        return true;
    if (c1.level() != c2.level() || c1.override() != c2.override() || c1.dir() != c2.dir() || c1.source() != c2.source())
        return false;
    if (!c1.parent())
        return !c2.parent();
    return c2.parent() && *c1.parent() == *c2.parent();
}

} // namespace blink
