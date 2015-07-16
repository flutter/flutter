/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
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

#ifndef SKY_ENGINE_PLATFORM_GRAPHICS_FILTERS_SKIAIMAGEFILTERBUILDER_H_
#define SKY_ENGINE_PLATFORM_GRAPHICS_FILTERS_SKIAIMAGEFILTERBUILDER_H_

#include "sky/engine/platform/PlatformExport.h"
#include "sky/engine/platform/geometry/FloatSize.h"
#include "sky/engine/platform/graphics/ColorSpace.h"

class SkImageFilter;

namespace blink {
class AffineTransform;
class FilterEffect;
class FilterOperations;
class GraphicsContext;
class SourceGraphic;

class PLATFORM_EXPORT SkiaImageFilterBuilder {
public:
    SkiaImageFilterBuilder();
    explicit SkiaImageFilterBuilder(GraphicsContext*);
    ~SkiaImageFilterBuilder();

    PassRefPtr<SkImageFilter> build(FilterEffect*, ColorSpace, bool requiresPMColorValidation = true);
    PassRefPtr<SkImageFilter> buildTransform(const AffineTransform&, SkImageFilter* input);

    PassRefPtr<SkImageFilter> transformColorSpace(
        SkImageFilter* input, ColorSpace srcColorSpace, ColorSpace dstColorSpace);

    void setCropOffset(const FloatSize& cropOffset) { m_cropOffset = cropOffset; };
    FloatSize cropOffset() { return m_cropOffset; }

    void setSourceGraphic(SourceGraphic* sourceGraphic) { m_sourceGraphic = sourceGraphic; }
    SourceGraphic* sourceGraphic() { return m_sourceGraphic; }

    GraphicsContext* context() { return m_context; }

private:
    FloatSize m_cropOffset;
    GraphicsContext* m_context;
    SourceGraphic* m_sourceGraphic;
};

} // namespace blink

#endif  // SKY_ENGINE_PLATFORM_GRAPHICS_FILTERS_SKIAIMAGEFILTERBUILDER_H_
