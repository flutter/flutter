/*
 * Copyright (C) 2012 Adobe Systems Incorporated. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer.
 * 2. Redistributions in binary form must reproduce the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer in the documentation and/or other materials
 *    provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
 * OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
 * THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#ifndef RenderLayerFilterInfo_h
#define RenderLayerFilterInfo_h

#include "core/dom/Element.h"
#include "platform/geometry/LayoutRect.h"
#include "platform/graphics/filters/FilterOperation.h"
#include "wtf/HashMap.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefPtr.h"

namespace blink {

class FilterEffectRenderer;
class FilterOperations;
class RenderLayer;
class RenderLayerFilterInfo;

typedef HashMap<const RenderLayer*, RenderLayerFilterInfo*> RenderLayerFilterInfoMap;

class RenderLayerFilterInfo {
public:
    static RenderLayerFilterInfo* filterInfoForRenderLayer(const RenderLayer*);
    static RenderLayerFilterInfo* createFilterInfoForRenderLayerIfNeeded(RenderLayer*);
    static void removeFilterInfoForRenderLayer(RenderLayer*);

    FilterEffectRenderer* renderer() const { return m_renderer.get(); }
    void setRenderer(PassRefPtr<FilterEffectRenderer>);

    void updateReferenceFilterClients(const FilterOperations&);
    void removeReferenceFilterClients();

private:
    RenderLayerFilterInfo(RenderLayer*);
    virtual ~RenderLayerFilterInfo();

    RefPtr<FilterEffectRenderer> m_renderer;

    static RenderLayerFilterInfoMap* s_filterMap;
    WillBePersistentHeapVector<RefPtrWillBeMember<Element> > m_internalSVGReferences;
};

} // namespace blink


#endif // RenderLayerFilterInfo_h
