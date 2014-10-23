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

#ifndef ShadowList_h
#define ShadowList_h

#include "core/rendering/style/ShadowData.h"
#include "platform/geometry/LayoutRect.h"
#include "platform/graphics/DrawLooperBuilder.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/RefCounted.h"
#include "wtf/Vector.h"

namespace blink {

class FloatRect;
class LayoutRect;

typedef Vector<ShadowData, 1> ShadowDataVector;

// These are used to store shadows in specified order, but we usually want to
// iterate over them backwards as the first-specified shadow is painted on top.
class ShadowList : public RefCounted<ShadowList> {
public:
    // This consumes passed in vector.
    static PassRefPtr<ShadowList> adopt(ShadowDataVector& shadows)
    {
        return adoptRef(new ShadowList(shadows));
    }
    const ShadowDataVector& shadows() const { return m_shadows; }
    bool operator==(const ShadowList& o) const { return m_shadows == o.m_shadows; }
    bool operator!=(const ShadowList& o) const { return !(*this == o); }

    static PassRefPtr<ShadowList> blend(const ShadowList* from, const ShadowList* to, double progress);

    void adjustRectForShadow(LayoutRect&) const;
    void adjustRectForShadow(FloatRect&) const;

    PassOwnPtr<DrawLooperBuilder> createDrawLooper(DrawLooperBuilder::ShadowAlphaMode, bool isHorizontal = true) const;

private:
    ShadowList(ShadowDataVector& shadows)
    {
        // If we have no shadows, we use a null ShadowList
        ASSERT(!shadows.isEmpty());
        m_shadows.swap(shadows);
        m_shadows.shrinkToFit();
    }
    ShadowDataVector m_shadows;
};

} // namespace blink

#endif // ShadowList_h
