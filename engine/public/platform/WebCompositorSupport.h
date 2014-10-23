/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef WebCompositorSupport_h
#define WebCompositorSupport_h

#include "WebCommon.h"
#include "WebCompositorAnimation.h"
#include "WebCompositorAnimationCurve.h"
#include "WebFloatPoint.h"
#include "WebLayerTreeView.h"
#include "WebScrollbar.h"
#include "WebScrollbarThemePainter.h"

namespace blink {

class WebCompositorAnimationCurve;
class WebCompositorOutputSurface;
class WebContentLayer;
class WebContentLayerClient;
class WebExternalTextureLayer;
class WebExternalTextureLayerClient;
class WebFilterAnimationCurve;
class WebFilterOperations;
class WebFloatAnimationCurve;
class WebGraphicsContext3D;
class WebImageLayer;
class WebNinePatchLayer;
class WebLayer;
class WebScrollbarLayer;
class WebScrollbarThemeGeometry;
class WebScrollOffsetAnimationCurve;
class WebTransformAnimationCurve;
class WebTransformOperations;

class WebCompositorSupport {
public:
    // Creates an output surface for the compositor backed by a 3d context.
    virtual WebCompositorOutputSurface* createOutputSurfaceFor3D(WebGraphicsContext3D*) { return 0; }

    // Creates an output surface for the compositor backed by a software device.
    virtual WebCompositorOutputSurface* createOutputSurfaceForSoftware() { return 0; }

    // Layers -------------------------------------------------------

    virtual WebLayer* createLayer() { return 0; }

    virtual WebContentLayer* createContentLayer(WebContentLayerClient*) { return 0; }

    virtual WebExternalTextureLayer* createExternalTextureLayer(WebExternalTextureLayerClient*) { return 0; }

    virtual WebImageLayer* createImageLayer() { return 0; }

    virtual WebNinePatchLayer* createNinePatchLayer() { return 0; }

    // The ownership of the WebScrollbarThemeGeometry pointer is passed to Chromium.
    virtual WebScrollbarLayer* createScrollbarLayer(WebScrollbar*, WebScrollbarThemePainter, WebScrollbarThemeGeometry*) { return 0; }

    virtual WebScrollbarLayer* createSolidColorScrollbarLayer(WebScrollbar::Orientation, int thumbThickness, int trackStart, bool isLeftSideVerticalScrollbar) { return 0; }

    // Animation ----------------------------------------------------

    virtual WebCompositorAnimation* createAnimation(const WebCompositorAnimationCurve&, WebCompositorAnimation::TargetProperty, int animationId = 0) { return 0; }

    virtual WebFilterAnimationCurve* createFilterAnimationCurve() { return 0; }

    virtual WebFloatAnimationCurve* createFloatAnimationCurve() { return 0; }

    virtual WebScrollOffsetAnimationCurve* createScrollOffsetAnimationCurve(WebFloatPoint targetValue, WebCompositorAnimationCurve::TimingFunctionType) { return 0; }

    virtual WebTransformAnimationCurve* createTransformAnimationCurve() { return 0; }

    virtual WebTransformOperations* createTransformOperations() { return 0; }

    virtual WebFilterOperations* createFilterOperations() { return 0; }

protected:
    virtual ~WebCompositorSupport() { }
};

}

#endif // WebCompositorSupport_h
