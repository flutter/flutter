// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_RENDERING_RENDERIFRAME_H_
#define SKY_ENGINE_CORE_RENDERING_RENDERIFRAME_H_

#include "sky/engine/core/rendering/RenderReplaced.h"

namespace blink {

class HTMLIFrameElement;

class RenderIFrame : public RenderReplaced {
public:
    explicit RenderIFrame(HTMLIFrameElement*);
    virtual ~RenderIFrame();

    void updateWidgetBounds();

private:
    LayerType layerTypeRequired() const override { return NormalLayer; }
    void paintReplaced(PaintInfo& paintInfo, const LayoutPoint& paintOffset) override;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_RENDERING_RENDERIFRAME_H_
