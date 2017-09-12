/*
 * Copyright (C) 2008 Apple Computer, Inc.  All rights reserved.
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

#ifndef SKY_ENGINE_PLATFORM_GRAPHICS_GENERATEDIMAGE_H_
#define SKY_ENGINE_PLATFORM_GRAPHICS_GENERATEDIMAGE_H_

#include "flutter/sky/engine/platform/geometry/IntSize.h"
#include "flutter/sky/engine/platform/graphics/Image.h"
#include "flutter/sky/engine/wtf/RefPtr.h"

namespace blink {

class PLATFORM_EXPORT GeneratedImage : public Image {
 public:
  virtual void setContainerSize(const IntSize& size) override { m_size = size; }
  virtual bool usesContainerSize() const override { return true; }
  virtual bool hasRelativeWidth() const override { return true; }
  virtual bool hasRelativeHeight() const override { return true; }
  virtual void computeIntrinsicDimensions(Length& intrinsicWidth,
                                          Length& intrinsicHeight,
                                          FloatSize& intrinsicRatio) override;

  virtual IntSize size() const override { return m_size; }

  // Assume that generated content has no decoded data we need to worry about
  virtual void destroyDecodedData(bool) override {}

 protected:
  virtual void drawPattern(GraphicsContext*,
                           const FloatRect&,
                           const FloatSize&,
                           const FloatPoint&,
                           CompositeOperator,
                           const FloatRect&,
                           WebBlendMode,
                           const IntSize& repeatSpacing) override = 0;

  // FIXME: Implement this to be less conservative.
  virtual bool currentFrameKnownToBeOpaque() override { return false; }

  GeneratedImage() {}

  IntSize m_size;
};

}  // namespace blink

#endif  // SKY_ENGINE_PLATFORM_GRAPHICS_GENERATEDIMAGE_H_
