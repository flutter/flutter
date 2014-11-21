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

#ifndef SKY_ENGINE_CORE_RENDERING_IMAGEQUALITYCONTROLLER_H_
#define SKY_ENGINE_CORE_RENDERING_IMAGEQUALITYCONTROLLER_H_

#include "sky/engine/core/rendering/RenderObject.h"
#include "sky/engine/platform/geometry/IntSize.h"
#include "sky/engine/platform/geometry/LayoutSize.h"
#include "sky/engine/platform/graphics/Image.h"
#include "sky/engine/platform/graphics/ImageOrientation.h"
#include "sky/engine/platform/graphics/ImageSource.h"
#include "sky/engine/wtf/HashMap.h"

namespace blink {

typedef HashMap<const void*, LayoutSize> LayerSizeMap;
typedef HashMap<RenderObject*, LayerSizeMap> ObjectLayerSizeMap;

class ImageQualityController final {
    WTF_MAKE_NONCOPYABLE(ImageQualityController); WTF_MAKE_FAST_ALLOCATED;
public:
    ~ImageQualityController();

    static ImageQualityController* imageQualityController();

    static void remove(RenderObject*);

    InterpolationQuality chooseInterpolationQuality(GraphicsContext*, RenderObject*, Image*, const void* layer, const LayoutSize&);

    // For testing.
    static bool has(RenderObject*);
    // This is public for testing. Do not call this from other classes.
    void set(RenderObject*, LayerSizeMap* innerMap, const void* layer, const LayoutSize&);

private:
    ImageQualityController();

    bool shouldPaintAtLowQuality(GraphicsContext*, RenderObject*, Image*, const void* layer, const LayoutSize&);
    void removeLayer(RenderObject*, LayerSizeMap* innerMap, const void* layer);
    void objectDestroyed(RenderObject*);
    bool isEmpty() { return m_objectLayerSizeMap.isEmpty(); }

    void highQualityRepaintTimerFired(Timer<ImageQualityController>*);
    void restartTimer();

    ObjectLayerSizeMap m_objectLayerSizeMap;
    Timer<ImageQualityController> m_timer;
    bool m_animatedResizeIsActive;
    bool m_liveResizeOptimizationIsActive;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_RENDERING_IMAGEQUALITYCONTROLLER_H_
