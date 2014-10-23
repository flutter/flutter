// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef CompositingInputsUpdater_h
#define CompositingInputsUpdater_h

#include "core/rendering/RenderGeometryMap.h"

namespace blink {

class RenderLayer;

class CompositingInputsUpdater {
public:
    explicit CompositingInputsUpdater(RenderLayer* rootRenderLayer);
    ~CompositingInputsUpdater();

    void update();

#if ENABLE(ASSERT)
    static void assertNeedsCompositingInputsUpdateBitsCleared(RenderLayer*);
#endif

private:
    enum UpdateType {
        DoNotForceUpdate,
        ForceUpdate,
    };

    struct AncestorInfo {
        AncestorInfo()
            : ancestorStackingContext(0)
            , enclosingCompositedLayer(0)
            , lastScrollingAncestor(0)
            , hasAncestorWithClipOrOverflowClip(false)
            , hasAncestorWithClipPath(false)
        {
        }

        RenderLayer* ancestorStackingContext;
        RenderLayer* enclosingCompositedLayer;
        // Notice that lastScrollingAncestor isn't the same thing as
        // ancestorScrollingLayer. The former is just the nearest scrolling
        // along the RenderLayer::parent() chain. The latter is the layer that
        // actually controls the scrolling of this layer, which we find on the
        // containing block chain.
        RenderLayer* lastScrollingAncestor;
        bool hasAncestorWithClipOrOverflowClip;
        bool hasAncestorWithClipPath;
    };

    void updateRecursive(RenderLayer*, UpdateType, AncestorInfo);

    RenderGeometryMap m_geometryMap;
    RenderLayer* m_rootRenderLayer;
};

} // namespace blink

#endif // CompositingInputsUpdater_h
