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

#ifndef ResourceLoadPriorityOptimizer_h
#define ResourceLoadPriorityOptimizer_h

#include "core/fetch/ImageResource.h"
#include "core/fetch/ResourcePtr.h"
#include "platform/geometry/LayoutRect.h"

#include "wtf/HashMap.h"
#include "wtf/HashSet.h"
#include "wtf/OwnPtr.h"

namespace blink {

class ResourceLoadPriorityOptimizer {
public:
    enum VisibilityStatus {
        NotVisible,
        Visible,
    };
    void notifyImageResourceVisibility(ImageResource*, VisibilityStatus, const LayoutRect&);
    void updateAllImageResourcePriorities();
    void addRenderObject(RenderObject*);
    void removeRenderObject(RenderObject*);

    static ResourceLoadPriorityOptimizer* resourceLoadPriorityOptimizer();

private:
    ResourceLoadPriorityOptimizer();
    ~ResourceLoadPriorityOptimizer();

    void updateImageResourcesWithLoadPriority();

    struct ResourceAndVisibility {
        ResourceAndVisibility(ImageResource*, VisibilityStatus, uint32_t);
        ~ResourceAndVisibility();
        ResourcePtr<ImageResource> imageResource;
        VisibilityStatus status;
        int screenArea;
    };

    typedef HashMap<unsigned long, OwnPtr<ResourceAndVisibility>, WTF::IntHash<unsigned>, WTF::UnsignedWithZeroKeyHashTraits<unsigned> > ImageResourceMap;
    ImageResourceMap m_imageResources;

    typedef HashSet<RenderObject*> RenderObjectSet;
    RenderObjectSet m_objects;
};

}

#endif
