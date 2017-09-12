/*
 * Copyright (C) 2012 Apple Inc. All rights reserved.
 * Copyright (C) 2014 Google Inc. All rights reserved.
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

#ifndef SKY_ENGINE_CORE_RENDERING_RENDERGEOMETRYMAPSTEP_H_
#define SKY_ENGINE_CORE_RENDERING_RENDERGEOMETRYMAPSTEP_H_

#include "flutter/sky/engine/platform/geometry/LayoutSize.h"
#include "flutter/sky/engine/platform/transforms/TransformationMatrix.h"
#include "flutter/sky/engine/wtf/OwnPtr.h"

namespace blink {

class RenderObject;

// Stores data about how to map from one renderer to its container.
struct RenderGeometryMapStep {
  RenderGeometryMapStep(const RenderGeometryMapStep& o)
      : m_renderer(o.m_renderer),
        m_offset(o.m_offset),
        m_accumulatingTransform(o.m_accumulatingTransform),
        m_isNonUniform(o.m_isNonUniform),
        m_hasTransform(o.m_hasTransform) {
    ASSERT(!o.m_transform);
  }
  RenderGeometryMapStep(const RenderObject* renderer,
                        bool accumulatingTransform,
                        bool isNonUniform,
                        bool hasTransform)
      : m_renderer(renderer),
        m_accumulatingTransform(accumulatingTransform),
        m_isNonUniform(isNonUniform),
        m_hasTransform(hasTransform) {}
  const RenderObject* m_renderer;
  LayoutSize m_offset;
  OwnPtr<TransformationMatrix> m_transform;  // Includes offset if non-null.
  bool m_accumulatingTransform;
  bool m_isNonUniform;  // Mapping depends on the input point, e.g. because of
                        // CSS columns.
  bool m_hasTransform;
};

}  // namespace blink

WTF_ALLOW_MOVE_INIT_AND_COMPARE_WITH_MEM_FUNCTIONS(
    blink::RenderGeometryMapStep);

#endif  // SKY_ENGINE_CORE_RENDERING_RENDERGEOMETRYMAPSTEP_H_
