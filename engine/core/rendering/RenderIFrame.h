// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef RenderIFrame_h
#define RenderIFrame_h

#include "core/rendering/RenderReplaced.h"

namespace blink {

class HTMLIFrameElement;

class RenderIFrame : public RenderReplaced {
public:
    explicit RenderIFrame(HTMLIFrameElement*);
    virtual ~RenderIFrame();

    // RenderReplaced methods:
    void invalidateWidgetBounds() override;

private:
    LayerType layerTypeRequired() const override { return NormalLayer; }
    void paintReplaced(PaintInfo& paintInfo, const LayoutPoint& paintOffset) override;
};

} // namespace blink

#endif // RenderIFrame_h
