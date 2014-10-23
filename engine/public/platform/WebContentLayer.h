/*
 * Copyright (C) 2011 Google Inc. All rights reserved.
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

#ifndef WebContentLayer_h
#define WebContentLayer_h

#include "WebCommon.h"
#include "WebLayer.h"

namespace blink {

class WebContentLayer {
public:
    virtual ~WebContentLayer() { }

    // The WebContentLayer has ownership of this wrapper.
    virtual WebLayer* layer() = 0;

    // Set to true if the backside of this layer's contents should be visible when composited.
    // Defaults to false.
    virtual void setDoubleSided(bool) = 0;

    // Allow the compositor to determine the scale at which the layer should
    // be rasterized based on the layer's hierarchy and transform. This defaults
    // to false.
    virtual void setAutomaticallyComputeRasterScale(bool) { }

    // Set to draw a system-defined checkerboard if the compositor would otherwise draw a tile in this layer
    // and the actual contents are unavailable. If false, the compositor will draw the layer's background color
    // for these tiles.
    // Defaults to false.
    virtual void setDrawCheckerboardForMissingTiles(bool) = 0;
};

} // namespace blink

#endif // WebContentLayer_h
