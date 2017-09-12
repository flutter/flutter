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

#include "flutter/sky/engine/core/rendering/RenderGeometryMap.h"

#include "flutter/sky/engine/core/rendering/RenderLayer.h"
#include "flutter/sky/engine/core/rendering/RenderView.h"
#include "flutter/sky/engine/platform/geometry/TransformState.h"
#include "flutter/sky/engine/wtf/TemporaryChange.h"

namespace blink {

RenderGeometryMap::RenderGeometryMap(MapCoordinatesFlags flags)
    : m_insertionPosition(kNotFound),
      m_nonUniformStepsCount(0),
      m_transformedStepsCount(0),
      m_mapCoordinatesFlags(flags) {}

RenderGeometryMap::~RenderGeometryMap() {}

void RenderGeometryMap::mapToContainer(TransformState& transformState,
                                       const RenderBox* container) const {
  // If the mapping includes something like columns, we have to go via
  // renderers.
  if (hasNonUniformStep()) {
    m_mapping.last().m_renderer->mapLocalToContainer(
        container, transformState, ApplyContainerFlip | m_mapCoordinatesFlags);
    transformState.flatten();
    return;
  }

#if ENABLE(ASSERT)
  bool foundContainer =
      !container || (m_mapping.size() && m_mapping[0].m_renderer == container);
#endif

  for (int i = m_mapping.size() - 1; i >= 0; --i) {
    const RenderGeometryMapStep& currentStep = m_mapping[i];

    // If container is the root RenderView (step 0) we want to apply its fixed
    // position offset.
    if (i > 0 && currentStep.m_renderer == container) {
#if ENABLE(ASSERT)
      foundContainer = true;
#endif
      break;
    }

    ASSERT(!i == isTopmostRenderView(currentStep.m_renderer));

    if (!i) {
      // A null container indicates mapping through the root RenderView, so
      // including its transform (the page scale).
      if (!container && currentStep.m_transform)
        transformState.applyTransform(*currentStep.m_transform.get());
    } else {
      TransformState::TransformAccumulation accumulate =
          currentStep.m_accumulatingTransform
              ? TransformState::AccumulateTransform
              : TransformState::FlattenTransform;
      if (currentStep.m_transform)
        transformState.applyTransform(*currentStep.m_transform.get(),
                                      accumulate);
      else
        transformState.move(currentStep.m_offset.width(),
                            currentStep.m_offset.height(), accumulate);
    }
  }

  ASSERT(foundContainer);
  transformState.flatten();
}

FloatPoint RenderGeometryMap::mapToContainer(const FloatPoint& p,
                                             const RenderBox* container) const {
  FloatPoint result;

  if (!hasTransformStep() && !hasNonUniformStep() &&
      (!container ||
       (m_mapping.size() && container == m_mapping[0].m_renderer)))
    result = p + m_accumulatedOffset;
  else {
    TransformState transformState(TransformState::ApplyTransformDirection, p);
    mapToContainer(transformState, container);
    result = transformState.lastPlanarPoint();
  }

#if ENABLE(ASSERT)
  if (m_mapping.size() > 0) {
    const RenderObject* lastRenderer = m_mapping.last().m_renderer;
    const RenderLayer* layer = lastRenderer->enclosingLayer();

    // Bounds for invisible layers are intentionally not calculated, and are
    // therefore not necessarily expected to be correct here. This is ok,
    // because they will be recomputed if the layer becomes visible.
    if (!layer) {
      FloatPoint rendererMappedResult = lastRenderer->localToContainerPoint(
          p, container, m_mapCoordinatesFlags);

      ASSERT(roundedIntPoint(rendererMappedResult) == roundedIntPoint(result));
    }
  }
#endif

  return result;
}

#ifndef NDEBUG
// Handy function to call from gdb while debugging mismatched point/rect errors.
void RenderGeometryMap::dumpSteps() const {
  fprintf(stderr, "RenderGeometryMap::dumpSteps accumulatedOffset=%d,%d\n",
          m_accumulatedOffset.width().toInt(),
          m_accumulatedOffset.height().toInt());
  for (int i = m_mapping.size() - 1; i >= 0; --i) {
    fprintf(stderr, " [%d] %s: offset=%d,%d", i,
            m_mapping[i].m_renderer->debugName().ascii().data(),
            m_mapping[i].m_offset.width().toInt(),
            m_mapping[i].m_offset.height().toInt());
    if (m_mapping[i].m_hasTransform)
      fprintf(stderr, " hasTransform");
    fprintf(stderr, "\n");
  }
}
#endif

FloatQuad RenderGeometryMap::mapToContainer(const FloatRect& rect,
                                            const RenderBox* container) const {
  FloatRect result;

  if (!hasTransformStep() && !hasNonUniformStep() &&
      (!container ||
       (m_mapping.size() && container == m_mapping[0].m_renderer))) {
    result = rect;
    result.move(m_accumulatedOffset);
  } else {
    TransformState transformState(TransformState::ApplyTransformDirection,
                                  rect.center(), rect);
    mapToContainer(transformState, container);
    result = transformState.lastPlanarQuad().boundingBox();
  }

#if ENABLE(ASSERT)
  if (m_mapping.size() > 0) {
    const RenderObject* lastRenderer = m_mapping.last().m_renderer;

    // Bounds for invisible layers are intentionally not calculated, and are
    // therefore not necessarily expected to be correct here. This is ok,
    // because they will be recomputed if the layer becomes visible.
    FloatRect rendererMappedResult =
        lastRenderer
            ->localToContainerQuad(rect, container, m_mapCoordinatesFlags)
            .boundingBox();

    // Inspector creates renderers with negative width
    // <https://bugs.webkit.org/show_bug.cgi?id=87194>. Taking FloatQuad bounds
    // avoids spurious assertions because of that.
    ASSERT(enclosingIntRect(rendererMappedResult) ==
           enclosingIntRect(FloatQuad(result).boundingBox()));
  }
#endif

  return result;
}

void RenderGeometryMap::pushMappingsToAncestor(
    const RenderObject* renderer,
    const RenderBox* ancestorRenderer) {
  // We need to push mappings in reverse order here, so do insertions rather
  // than appends.
  TemporaryChange<size_t> positionChange(m_insertionPosition, m_mapping.size());
  do {
    renderer = renderer->pushMappingToContainer(ancestorRenderer, *this);
  } while (renderer && renderer != ancestorRenderer);

  ASSERT(m_mapping.isEmpty() || isTopmostRenderView(m_mapping[0].m_renderer));
}

static bool canMapBetweenRenderers(const RenderObject* renderer,
                                   const RenderObject* ancestor) {
  for (const RenderObject* current = renderer;; current = current->parent()) {
    if (current->hasTransform())
      return false;

    if (current == ancestor)
      break;
  }

  return true;
}

void RenderGeometryMap::pushMappingsToAncestor(
    const RenderLayer* layer,
    const RenderLayer* ancestorLayer) {
  const RenderObject* renderer = layer->renderer();

  bool crossDocument = false;
  ASSERT(!crossDocument || m_mapCoordinatesFlags & TraverseDocumentBoundaries);

  // We have to visit all the renderers to detect flipped blocks. This might
  // defeat the gains from mapping via layers.
  bool canConvertInLayerTree =
      (ancestorLayer && !crossDocument)
          ? canMapBetweenRenderers(layer->renderer(), ancestorLayer->renderer())
          : false;

  //    fprintf(stderr, "RenderGeometryMap::pushMappingsToAncestor from layer %p
  //    to layer %p, canConvertInLayerTree=%d\n", layer, ancestorLayer,
  //    canConvertInLayerTree);

  if (canConvertInLayerTree) {
    LayoutPoint layerOffset;
    layer->convertToLayerCoords(ancestorLayer, layerOffset);

    // The RenderView must be pushed first.
    if (!m_mapping.size()) {
      ASSERT(ancestorLayer->renderer()->isRenderView());
      pushMappingsToAncestor(ancestorLayer->renderer(), 0);
    }

    TemporaryChange<size_t> positionChange(m_insertionPosition,
                                           m_mapping.size());
    bool accumulatingTransform =
        layer->renderer()->style()->preserves3D() ||
        ancestorLayer->renderer()->style()->preserves3D();
    push(renderer, toLayoutSize(layerOffset), accumulatingTransform,
         /*isNonUniform*/ false, /*hasTransform*/ false);
    return;
  }
  const RenderBox* ancestorRenderer =
      ancestorLayer ? ancestorLayer->renderer() : 0;
  pushMappingsToAncestor(renderer, ancestorRenderer);
}

void RenderGeometryMap::push(const RenderObject* renderer,
                             const LayoutSize& offsetFromContainer,
                             bool accumulatingTransform,
                             bool isNonUniform,
                             bool hasTransform) {
  //    fprintf(stderr, "RenderGeometryMap::push %p %d,%d isNonUniform=%d\n",
  //    renderer, offsetFromContainer.width().toInt(),
  //    offsetFromContainer.height().toInt(), isNonUniform);

  ASSERT(m_insertionPosition != kNotFound);
  ASSERT(!renderer->isRenderView() || !m_insertionPosition ||
         m_mapCoordinatesFlags & TraverseDocumentBoundaries);

  m_mapping.insert(m_insertionPosition,
                   RenderGeometryMapStep(renderer, accumulatingTransform,
                                         isNonUniform, hasTransform));

  RenderGeometryMapStep& step = m_mapping[m_insertionPosition];
  step.m_offset = offsetFromContainer;

  stepInserted(step);
}

void RenderGeometryMap::push(const RenderObject* renderer,
                             const TransformationMatrix& t,
                             bool accumulatingTransform,
                             bool isNonUniform,
                             bool hasTransform) {
  ASSERT(m_insertionPosition != kNotFound);
  ASSERT(!renderer->isRenderView() || !m_insertionPosition ||
         m_mapCoordinatesFlags & TraverseDocumentBoundaries);

  m_mapping.insert(m_insertionPosition,
                   RenderGeometryMapStep(renderer, accumulatingTransform,
                                         isNonUniform, hasTransform));

  RenderGeometryMapStep& step = m_mapping[m_insertionPosition];

  if (!t.isIntegerTranslation())
    step.m_transform = adoptPtr(new TransformationMatrix(t));
  else
    step.m_offset = LayoutSize(t.e(), t.f());

  stepInserted(step);
}

void RenderGeometryMap::popMappingsToAncestor(
    const RenderBox* ancestorRenderer) {
  ASSERT(m_mapping.size());

  while (m_mapping.size() && m_mapping.last().m_renderer != ancestorRenderer) {
    stepRemoved(m_mapping.last());
    m_mapping.removeLast();
  }
}

void RenderGeometryMap::popMappingsToAncestor(
    const RenderLayer* ancestorLayer) {
  const RenderBox* ancestorRenderer =
      ancestorLayer ? ancestorLayer->renderer() : 0;
  popMappingsToAncestor(ancestorRenderer);
}

void RenderGeometryMap::stepInserted(const RenderGeometryMapStep& step) {
  m_accumulatedOffset += step.m_offset;

  if (step.m_isNonUniform)
    ++m_nonUniformStepsCount;

  if (step.m_transform)
    ++m_transformedStepsCount;
}

void RenderGeometryMap::stepRemoved(const RenderGeometryMapStep& step) {
  m_accumulatedOffset -= step.m_offset;

  if (step.m_isNonUniform) {
    ASSERT(m_nonUniformStepsCount);
    --m_nonUniformStepsCount;
  }

  if (step.m_transform) {
    ASSERT(m_transformedStepsCount);
    --m_transformedStepsCount;
  }
}

#if ENABLE(ASSERT)
bool RenderGeometryMap::isTopmostRenderView(
    const RenderObject* renderer) const {
  if (!renderer->isRenderView())
    return false;

  // If we're not working with multiple RenderViews, then any view is considered
  // "topmost" (to preserve original behavior).
  return !(m_mapCoordinatesFlags & TraverseDocumentBoundaries);
}
#endif

}  // namespace blink
