// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef RenderParagraph_h
#define RenderParagraph_h

#include "core/dom/ContainerNode.h"
#include "core/rendering/RenderBlockFlow.h"

namespace blink {

class ContainerNode;

class RenderParagraph final : public RenderBlockFlow {
public:
    explicit RenderParagraph(ContainerNode*);
    virtual ~RenderParagraph();

    static RenderParagraph* createAnonymous(Document&);

    bool isRenderParagraph() const override { return true; }
};

DEFINE_RENDER_OBJECT_TYPE_CASTS(RenderParagraph, isRenderParagraph());

} // namespace blink

#endif // RenderParagraph_h
