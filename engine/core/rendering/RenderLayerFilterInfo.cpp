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

#include "sky/engine/config.h"

#include "sky/engine/core/rendering/RenderLayerFilterInfo.h"

#include "sky/engine/core/rendering/FilterEffectRenderer.h"
#include "sky/engine/core/rendering/RenderLayer.h"

namespace blink {

RenderLayerFilterInfoMap* RenderLayerFilterInfo::s_filterMap = 0;

RenderLayerFilterInfo* RenderLayerFilterInfo::filterInfoForRenderLayer(const RenderLayer* layer)
{
    if (!s_filterMap)
        return 0;
    RenderLayerFilterInfoMap::iterator iter = s_filterMap->find(layer);
    return (iter != s_filterMap->end()) ? iter->value : 0;
}

RenderLayerFilterInfo* RenderLayerFilterInfo::createFilterInfoForRenderLayerIfNeeded(RenderLayer* layer)
{
    if (!s_filterMap)
        s_filterMap = new RenderLayerFilterInfoMap();

    RenderLayerFilterInfoMap::iterator iter = s_filterMap->find(layer);
    if (iter != s_filterMap->end()) {
        ASSERT(layer->hasFilterInfo());
        return iter->value;
    }

    RenderLayerFilterInfo* filter = new RenderLayerFilterInfo(layer);
    s_filterMap->set(layer, filter);
    layer->setHasFilterInfo(true);
    return filter;
}

void RenderLayerFilterInfo::removeFilterInfoForRenderLayer(RenderLayer* layer)
{
    if (!s_filterMap)
        return;
    RenderLayerFilterInfo* filter = s_filterMap->take(layer);
    if (s_filterMap->isEmpty()) {
        delete s_filterMap;
        s_filterMap = 0;
    }
    if (!filter) {
        ASSERT(!layer->hasFilterInfo());
        return;
    }
    layer->setHasFilterInfo(false);
    delete filter;
}

RenderLayerFilterInfo::RenderLayerFilterInfo(RenderLayer* layer)
{
}

RenderLayerFilterInfo::~RenderLayerFilterInfo()
{
}

void RenderLayerFilterInfo::setRenderer(PassRefPtr<FilterEffectRenderer> renderer)
{
    m_renderer = renderer;
}

void RenderLayerFilterInfo::updateReferenceFilterClients(const FilterOperations& operations)
{
}

void RenderLayerFilterInfo::removeReferenceFilterClients()
{
}

} // namespace blink

