/*
 * Copyright (C) 2006 Samuel Weinig (sam.weinig@gmail.com)
 * Copyright (C) 2004, 2005, 2006 Apple Computer, Inc.  All rights reserved.
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

#include "flutter/sky/engine/platform/graphics/Image.h"

#include "flutter/sky/engine/platform/Length.h"
#include "flutter/sky/engine/platform/SharedBuffer.h"
#include "flutter/sky/engine/platform/geometry/FloatPoint.h"
#include "flutter/sky/engine/platform/geometry/FloatRect.h"
#include "flutter/sky/engine/platform/geometry/FloatSize.h"
#include "flutter/sky/engine/platform/graphics/GraphicsContext.h"
#include "flutter/sky/engine/platform/graphics/GraphicsContextStateSaver.h"
#include "flutter/sky/engine/public/platform/Platform.h"
#include "flutter/sky/engine/wtf/MainThread.h"
#include "flutter/sky/engine/wtf/StdLibExtras.h"

#include <math.h>

namespace blink {

Image::Image(ImageObserver* observer) : m_imageObserver(observer) {}

Image::~Image() {}

bool Image::setData(PassRefPtr<SharedBuffer> data, bool allDataReceived) {
  m_encodedImageData = data;
  if (!m_encodedImageData.get())
    return true;

  int length = m_encodedImageData->size();
  if (!length)
    return true;

  return dataChanged(allDataReceived);
}

void Image::fillWithSolidColor(GraphicsContext* ctxt,
                               const FloatRect& dstRect,
                               const Color& color,
                               CompositeOperator op) {
  if (!color.alpha())
    return;

  CompositeOperator previousOperator = ctxt->compositeOperation();
  ctxt->setCompositeOperation(
      !color.hasAlpha() && op == CompositeSourceOver ? CompositeCopy : op);
  ctxt->fillRect(dstRect, color);
  ctxt->setCompositeOperation(previousOperator);
}

FloatRect Image::adjustForNegativeSize(const FloatRect& rect) {
  FloatRect norm = rect;
  if (norm.width() < 0) {
    norm.setX(norm.x() + norm.width());
    norm.setWidth(-norm.width());
  }
  if (norm.height() < 0) {
    norm.setY(norm.y() + norm.height());
    norm.setHeight(-norm.height());
  }
  return norm;
}

void Image::draw(GraphicsContext* ctx,
                 const FloatRect& dstRect,
                 const FloatRect& srcRect,
                 CompositeOperator op,
                 WebBlendMode blendMode,
                 RespectImageOrientationEnum) {}

void Image::drawTiled(GraphicsContext* ctxt,
                      const FloatRect& destRect,
                      const FloatPoint& srcPoint,
                      const FloatSize& scaledTileSize,
                      CompositeOperator op,
                      WebBlendMode blendMode,
                      const IntSize& repeatSpacing) {}

// FIXME: Merge with the other drawTiled eventually, since we need a combination
// of both for some things.
void Image::drawTiled(GraphicsContext* ctxt,
                      const FloatRect& dstRect,
                      const FloatRect& srcRect,
                      const FloatSize& providedTileScaleFactor,
                      TileRule hRule,
                      TileRule vRule,
                      CompositeOperator op) {}

void Image::drawPattern(GraphicsContext* context,
                        const FloatRect& floatSrcRect,
                        const FloatSize& scale,
                        const FloatPoint& phase,
                        CompositeOperator compositeOp,
                        const FloatRect& destRect,
                        WebBlendMode blendMode,
                        const IntSize& repeatSpacing) {}

void Image::computeIntrinsicDimensions(Length& intrinsicWidth,
                                       Length& intrinsicHeight,
                                       FloatSize& intrinsicRatio) {}

PassRefPtr<Image> Image::imageForDefaultFrame() {
  RefPtr<Image> image(this);
  return image.release();
}

}  // namespace blink
