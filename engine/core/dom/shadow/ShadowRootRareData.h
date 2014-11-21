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

#ifndef SKY_ENGINE_CORE_DOM_SHADOW_SHADOWROOTRAREDATA_H_
#define SKY_ENGINE_CORE_DOM_SHADOW_SHADOWROOTRAREDATA_H_

#include "sky/engine/core/dom/shadow/InsertionPoint.h"
#include "sky/engine/wtf/RefPtr.h"
#include "sky/engine/wtf/Vector.h"

namespace blink {

class ShadowRootRareData {
public:
    ShadowRootRareData()
        : m_descendantContentElementCount(0)
        , m_childShadowRootCount(0)
    {
    }

    void didAddInsertionPoint(InsertionPoint*);
    void didRemoveInsertionPoint(InsertionPoint*);

    bool containsContentElements() const { return m_descendantContentElementCount; }
    bool containsShadowRoots() const { return m_childShadowRootCount; }

    void didAddChildShadowRoot() { ++m_childShadowRootCount; }
    void didRemoveChildShadowRoot() { ASSERT(m_childShadowRootCount > 0); --m_childShadowRootCount; }

    unsigned childShadowRootCount() const { return m_childShadowRootCount; }

    const Vector<RefPtr<InsertionPoint> >& descendantInsertionPoints() { return m_descendantInsertionPoints; }
    void setDescendantInsertionPoints(Vector<RefPtr<InsertionPoint> >& list) { m_descendantInsertionPoints.swap(list); }
    void clearDescendantInsertionPoints() { m_descendantInsertionPoints.clear(); }

    StyleSheetList* styleSheets() { return m_styleSheetList.get(); }
    void setStyleSheets(PassRefPtr<StyleSheetList> styleSheetList) { m_styleSheetList = styleSheetList; }


private:
    unsigned m_descendantContentElementCount;
    unsigned m_childShadowRootCount;
    Vector<RefPtr<InsertionPoint> > m_descendantInsertionPoints;
    RefPtr<StyleSheetList> m_styleSheetList;
};

inline void ShadowRootRareData::didAddInsertionPoint(InsertionPoint* point)
{
    ASSERT(point);
    if (isHTMLContentElement(*point))
        ++m_descendantContentElementCount;
    else
        ASSERT_NOT_REACHED();
}

inline void ShadowRootRareData::didRemoveInsertionPoint(InsertionPoint* point)
{
    ASSERT(point);
    if (isHTMLContentElement(*point))
        --m_descendantContentElementCount;
    else
        ASSERT_NOT_REACHED();

    ASSERT(m_descendantContentElementCount >= 0);
}

} // namespace blink

#endif  // SKY_ENGINE_CORE_DOM_SHADOW_SHADOWROOTRAREDATA_H_
