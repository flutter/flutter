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
#include "core/rendering/ImageQualityController.h"

#include "core/frame/FrameView.h"
#include "core/frame/LocalFrame.h"
#include "platform/graphics/GraphicsContext.h"

namespace blink {

static const double cLowQualityTimeThreshold = 0.500; // 500 ms

static ImageQualityController* gImageQualityController = 0;

ImageQualityController* ImageQualityController::imageQualityController()
{
    if (!gImageQualityController)
        gImageQualityController = new ImageQualityController;

    return gImageQualityController;
}

void ImageQualityController::remove(RenderObject* renderer)
{
    if (gImageQualityController) {
        gImageQualityController->objectDestroyed(renderer);
        if (gImageQualityController->isEmpty()) {
            delete gImageQualityController;
            gImageQualityController = 0;
        }
    }
}

bool ImageQualityController::has(RenderObject* renderer)
{
    return gImageQualityController && gImageQualityController->m_objectLayerSizeMap.contains(renderer);
}

InterpolationQuality ImageQualityController::chooseInterpolationQuality(GraphicsContext* context, RenderObject* object, Image* image, const void* layer, const LayoutSize& layoutSize)
{
    if (object->style()->imageRendering() == ImageRenderingPixelated
        && image
        && (layoutSize.width() > image->width() || layoutSize.height() > image->height() || layoutSize == image->size())) {
        return InterpolationNone;
    }

    if (InterpolationDefault == InterpolationLow)
        return InterpolationLow;

    if (shouldPaintAtLowQuality(context, object, image, layer, layoutSize))
        return InterpolationLow;

    // For images that are potentially animated we paint them at medium quality.
    if (image && image->maybeAnimated())
        return InterpolationMedium;

    return InterpolationDefault;
}

ImageQualityController::~ImageQualityController()
{
    // This will catch users of ImageQualityController that forget to call cleanUp.
    ASSERT(!gImageQualityController || gImageQualityController->isEmpty());
}

ImageQualityController::ImageQualityController()
    : m_timer(this, &ImageQualityController::highQualityRepaintTimerFired)
    , m_animatedResizeIsActive(false)
    , m_liveResizeOptimizationIsActive(false)
{
}

void ImageQualityController::removeLayer(RenderObject* object, LayerSizeMap* innerMap, const void* layer)
{
    if (innerMap) {
        innerMap->remove(layer);
        if (innerMap->isEmpty())
            objectDestroyed(object);
    }
}

void ImageQualityController::set(RenderObject* object, LayerSizeMap* innerMap, const void* layer, const LayoutSize& size)
{
    if (innerMap)
        innerMap->set(layer, size);
    else {
        LayerSizeMap newInnerMap;
        newInnerMap.set(layer, size);
        m_objectLayerSizeMap.set(object, newInnerMap);
    }
}

void ImageQualityController::objectDestroyed(RenderObject* object)
{
    m_objectLayerSizeMap.remove(object);
    if (m_objectLayerSizeMap.isEmpty()) {
        m_animatedResizeIsActive = false;
        m_timer.stop();
    }
}

void ImageQualityController::highQualityRepaintTimerFired(Timer<ImageQualityController>*)
{
    if (!m_animatedResizeIsActive && !m_liveResizeOptimizationIsActive)
        return;
    m_animatedResizeIsActive = false;

    for (ObjectLayerSizeMap::iterator it = m_objectLayerSizeMap.begin(); it != m_objectLayerSizeMap.end(); ++it) {
        if (LocalFrame* frame = it->key->document().frame()) {
            // If this renderer's containing FrameView is in live resize, punt the timer and hold back for now.
            if (frame->view() && frame->view()->inLiveResize()) {
                restartTimer();
                return;
            }
        }
        it->key->setShouldDoFullPaintInvalidation(true);
    }

    m_liveResizeOptimizationIsActive = false;
}

void ImageQualityController::restartTimer()
{
    m_timer.startOneShot(cLowQualityTimeThreshold, FROM_HERE);
}

bool ImageQualityController::shouldPaintAtLowQuality(GraphicsContext* context, RenderObject* object, Image* image, const void *layer, const LayoutSize& layoutSize)
{
    // If the image is not a bitmap image, then none of this is relevant and we just paint at high
    // quality.
    if (!image || !image->isBitmapImage())
        return false;

    if (object->style()->imageRendering() == ImageRenderingOptimizeContrast)
        return true;

    // Look ourselves up in the hashtables.
    ObjectLayerSizeMap::iterator i = m_objectLayerSizeMap.find(object);
    LayerSizeMap* innerMap = i != m_objectLayerSizeMap.end() ? &i->value : 0;
    LayoutSize oldSize;
    bool isFirstResize = true;
    if (innerMap) {
        LayerSizeMap::iterator j = innerMap->find(layer);
        if (j != innerMap->end()) {
            isFirstResize = false;
            oldSize = j->value;
        }
    }

    const AffineTransform& currentTransform = context->getCTM();
    bool contextIsScaled = !currentTransform.isIdentityOrTranslationOrFlipped();

    // Make sure to use the unzoomed image size, since if a full page zoom is in effect, the image
    // is actually being scaled.
    LayoutSize scaledImageSize = currentTransform.mapSize(image->size());
    LayoutSize scaledLayoutSize = currentTransform.mapSize(roundedIntSize(layoutSize));

    // If the containing FrameView is being resized, paint at low quality until resizing is finished.
    if (LocalFrame* frame = object->document().frame()) {
        bool frameViewIsCurrentlyInLiveResize = frame->view() && frame->view()->inLiveResize();
        if (frameViewIsCurrentlyInLiveResize) {
            set(object, innerMap, layer, scaledLayoutSize);
            restartTimer();
            m_liveResizeOptimizationIsActive = true;
            return true;
        }
        if (m_liveResizeOptimizationIsActive) {
            // Live resize has ended, paint in HQ and remove this object from the list.
            removeLayer(object, innerMap, layer);
            return false;
        }
    }

    // See crbug.com/382491. This test is insufficient to ensure that there is no scale
    // applied in the compositor, but it is probably adequate here. In the worst case we
    // draw at high quality when we need not.
    if (!contextIsScaled && scaledLayoutSize == scaledImageSize) {
        // There is no scale in effect. If we had a scale in effect before, we can just remove this object from the list.
        removeLayer(object, innerMap, layer);
        return false;
    }

    // If an animated resize is active, paint in low quality and kick the timer ahead.
    if (m_animatedResizeIsActive) {
        set(object, innerMap, layer, scaledLayoutSize);
        restartTimer();
        return true;
    }
    // If this is the first time resizing this image, or its size is the
    // same as the last resize, draw at high res, but record the paint
    // size and set the timer.
    if (isFirstResize || oldSize == scaledLayoutSize) {
        restartTimer();
        set(object, innerMap, layer, scaledLayoutSize);
        return false;
    }
    // If the timer is no longer active, draw at high quality and don't
    // set the timer.
    if (!m_timer.isActive()) {
        removeLayer(object, innerMap, layer);
        return false;
    }
    // This object has been resized to two different sizes while the timer
    // is active, so draw at low quality, set the flag for animated resizes and
    // the object to the list for high quality redraw.
    set(object, innerMap, layer, scaledLayoutSize);
    m_animatedResizeIsActive = true;
    restartTimer();
    return true;
}

} // namespace blink
