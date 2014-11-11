// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef RenderRemote_h
#define RenderRemote_h

#include "core/rendering/RenderReplaced.h"

namespace blink {

class HTMLIFrameElement;

class RenderRemote : public RenderReplaced {
public:
    explicit RenderRemote(HTMLIFrameElement*);
    virtual ~RenderRemote();

protected:
    void layout() override;

private:
    LayerType layerTypeRequired() const override { return NormalLayer; }
    void paintReplaced(PaintInfo& paintInfo, const LayoutPoint& paintOffset) override;
};

} // namespace blink

#endif // RenderRemote_h
