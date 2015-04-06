// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_RENDERING_RENDERCUSTOMLAYOUT_H_
#define SKY_ENGINE_CORE_RENDERING_RENDERCUSTOMLAYOUT_H_

#include "sky/engine/core/rendering/RenderBlock.h"

namespace blink {

class RenderCustomLayout : public RenderBlock {
public:
    explicit RenderCustomLayout(ContainerNode* node);
    virtual void layout() override;
    const char* renderName() const;
    bool isRenderCustomLayout() const final { return true; }

protected:
    virtual ~RenderCustomLayout();
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_RENDERING_RENDERCUSTOMLAYOUT_H_
