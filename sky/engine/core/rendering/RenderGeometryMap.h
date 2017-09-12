/*
 * Copyright (C) 2012 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef SKY_ENGINE_CORE_RENDERING_RENDERGEOMETRYMAP_H_
#define SKY_ENGINE_CORE_RENDERING_RENDERGEOMETRYMAP_H_

#include "flutter/sky/engine/core/rendering/RenderGeometryMapStep.h"
#include "flutter/sky/engine/core/rendering/RenderObject.h"
#include "flutter/sky/engine/platform/geometry/FloatPoint.h"
#include "flutter/sky/engine/platform/geometry/FloatQuad.h"
#include "flutter/sky/engine/platform/geometry/IntSize.h"
#include "flutter/sky/engine/platform/geometry/LayoutSize.h"
#include "flutter/sky/engine/wtf/OwnPtr.h"

namespace blink {

class RenderLayer;
class RenderBox;
class TransformationMatrix;
class TransformState;

// Can be used while walking the Renderer tree to cache data about offsets and
// transforms.
class RenderGeometryMap {
  WTF_MAKE_NONCOPYABLE(RenderGeometryMap);

 public:
  RenderGeometryMap(MapCoordinatesFlags = UseTransforms);
  ~RenderGeometryMap();

  MapCoordinatesFlags mapCoordinatesFlags() const {
    return m_mapCoordinatesFlags;
  }

  FloatRect absoluteRect(const FloatRect& rect) const {
    return mapToContainer(rect, 0).boundingBox();
  }

  // Map to a container. Will assert that the container has been pushed onto
  // this map. A null container maps through the RenderView (including its scale
  // transform, if any). If the container is the RenderView, the scroll offset
  // is applied, but not the scale.
  FloatPoint mapToContainer(const FloatPoint&, const RenderBox*) const;
  FloatQuad mapToContainer(const FloatRect&, const RenderBox*) const;

  // Called by code walking the renderer or layer trees.
  void pushMappingsToAncestor(const RenderLayer*,
                              const RenderLayer* ancestorLayer);
  void popMappingsToAncestor(const RenderLayer*);
  void pushMappingsToAncestor(const RenderObject*,
                              const RenderBox* ancestorRenderer);
  void popMappingsToAncestor(const RenderBox*);

  // The following methods should only be called by renderers inside a call to
  // pushMappingsToAncestor().

  // Push geometry info between this renderer and some ancestor. The ancestor
  // must be its container() or some stacking context between the renderer and
  // its container.
  void push(const RenderObject*,
            const LayoutSize&,
            bool accumulatingTransform = false,
            bool isNonUniform = false,
            bool hasTransform = false);
  void push(const RenderObject*,
            const TransformationMatrix&,
            bool accumulatingTransform = false,
            bool isNonUniform = false,
            bool hasTransform = false);

 private:
  void mapToContainer(TransformState&, const RenderBox* container = 0) const;

  void stepInserted(const RenderGeometryMapStep&);
  void stepRemoved(const RenderGeometryMapStep&);

  bool hasNonUniformStep() const { return m_nonUniformStepsCount; }
  bool hasTransformStep() const { return m_transformedStepsCount; }

#ifndef NDEBUG
  void dumpSteps() const;
#endif

#if ENABLE(ASSERT)
  bool isTopmostRenderView(const RenderObject* renderer) const;
#endif

  typedef Vector<RenderGeometryMapStep, 32> RenderGeometryMapSteps;

  size_t m_insertionPosition;
  int m_nonUniformStepsCount;
  int m_transformedStepsCount;
  RenderGeometryMapSteps m_mapping;
  LayoutSize m_accumulatedOffset;
  MapCoordinatesFlags m_mapCoordinatesFlags;
};

}  // namespace blink

#endif  // SKY_ENGINE_CORE_RENDERING_RENDERGEOMETRYMAP_H_
