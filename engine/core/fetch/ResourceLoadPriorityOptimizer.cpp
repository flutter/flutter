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

#include "config.h"
#include "core/fetch/ResourceLoadPriorityOptimizer.h"
#include "core/rendering/RenderObject.h"
#include "platform/TraceEvent.h"

#include "wtf/Vector.h"

namespace blink {

ResourceLoadPriorityOptimizer* ResourceLoadPriorityOptimizer::resourceLoadPriorityOptimizer()
{
    DEFINE_STATIC_LOCAL(ResourceLoadPriorityOptimizer, s_renderLoadOptimizer, ());
    return &s_renderLoadOptimizer;
}

ResourceLoadPriorityOptimizer::ResourceAndVisibility::ResourceAndVisibility(ImageResource* image, VisibilityStatus visibilityStatus, uint32_t screenArea)
    : imageResource(image)
    , status(visibilityStatus)
    , screenArea(screenArea)
{
}

ResourceLoadPriorityOptimizer::ResourceAndVisibility::~ResourceAndVisibility()
{
}

ResourceLoadPriorityOptimizer::ResourceLoadPriorityOptimizer()
{
}

ResourceLoadPriorityOptimizer::~ResourceLoadPriorityOptimizer()
{
}

void ResourceLoadPriorityOptimizer::addRenderObject(RenderObject* renderer)
{
    m_objects.add(renderer);
    renderer->setHasPendingResourceUpdate(true);
}

void ResourceLoadPriorityOptimizer::removeRenderObject(RenderObject* renderer)
{
    if (!renderer->hasPendingResourceUpdate())
        return;
    m_objects.remove(renderer);
    renderer->setHasPendingResourceUpdate(false);
}

void ResourceLoadPriorityOptimizer::updateAllImageResourcePriorities()
{
    TRACE_EVENT0("blink", "ResourceLoadPriorityOptimizer::updateAllImageResourcePriorities");

    m_imageResources.clear();

    Vector<RenderObject*> objectsToRemove;
    for (RenderObjectSet::iterator it = m_objects.begin(); it != m_objects.end(); ++it) {
        RenderObject* obj = *it;
        if (!obj->updateImageLoadingPriorities()) {
            objectsToRemove.append(obj);
        }
    }
    m_objects.removeAll(objectsToRemove);

    updateImageResourcesWithLoadPriority();
}

void ResourceLoadPriorityOptimizer::updateImageResourcesWithLoadPriority()
{
    for (ImageResourceMap::iterator it = m_imageResources.begin(); it != m_imageResources.end(); ++it) {
        ResourceLoadPriority priority = it->value->status == Visible ?
            ResourceLoadPriorityLow : ResourceLoadPriorityVeryLow;

        if (priority != it->value->imageResource->resourceRequest().priority()) {
            it->value->imageResource->mutableResourceRequest().setPriority(priority, it->value->screenArea);
            it->value->imageResource->didChangePriority(priority, it->value->screenArea);
        }
    }
    m_imageResources.clear();
}

void ResourceLoadPriorityOptimizer::notifyImageResourceVisibility(ImageResource* img, VisibilityStatus status, const LayoutRect& screenRect)
{
    if (!img || img->isLoaded())
        return;

    int screenArea = 0;
    if (!screenRect.isEmpty() && status == Visible)
        screenArea += static_cast<uint32_t>(screenRect.width() * screenRect.height());

    ImageResourceMap::AddResult result = m_imageResources.add(img->identifier(), adoptPtr(new ResourceAndVisibility(img, status, screenArea)));
    if (!result.isNewEntry && status == Visible) {
        result.storedValue->value->status = status;
        result.storedValue->value->screenArea = status;
    }
}

}
