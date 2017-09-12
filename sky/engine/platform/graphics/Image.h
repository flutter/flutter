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

#ifndef SKY_ENGINE_PLATFORM_GRAPHICS_IMAGE_H_
#define SKY_ENGINE_PLATFORM_GRAPHICS_IMAGE_H_

#include "flutter/sky/engine/platform/PlatformExport.h"
#include "flutter/sky/engine/platform/geometry/IntRect.h"
#include "flutter/sky/engine/platform/graphics/Color.h"
#include "flutter/sky/engine/platform/graphics/GraphicsTypes.h"
#include "flutter/sky/engine/platform/graphics/ImageOrientation.h"
#include "flutter/sky/engine/wtf/Assertions.h"
#include "flutter/sky/engine/wtf/PassRefPtr.h"
#include "flutter/sky/engine/wtf/RefCounted.h"
#include "flutter/sky/engine/wtf/RefPtr.h"
#include "flutter/sky/engine/wtf/text/WTFString.h"

namespace blink {

class FloatPoint;
class FloatRect;
class FloatSize;
class GraphicsContext;
class Length;
class SharedBuffer;

// This class gets notified when an image creates or destroys decoded frames and
// when it advances animation frames.
class ImageObserver;

class PLATFORM_EXPORT Image : public RefCounted<Image> {
  friend class GeneratedImage;
  friend class GradientGeneratedImage;
  friend class GraphicsContext;

 public:
  virtual ~Image();

  virtual bool currentFrameKnownToBeOpaque() = 0;

  bool isNull() const { return size().isEmpty(); }

  virtual void setContainerSize(const IntSize&) {}
  virtual bool usesContainerSize() const { return false; }
  virtual bool hasRelativeWidth() const { return false; }
  virtual bool hasRelativeHeight() const { return false; }
  virtual void computeIntrinsicDimensions(Length& intrinsicWidth,
                                          Length& intrinsicHeight,
                                          FloatSize& intrinsicRatio);

  virtual IntSize size() const = 0;
  IntRect rect() const { return IntRect(IntPoint(), size()); }
  int width() const { return size().width(); }
  int height() const { return size().height(); }
  virtual bool getHotSpot(IntPoint&) const { return false; }

  bool setData(PassRefPtr<SharedBuffer> data, bool allDataReceived);
  virtual bool dataChanged(bool /*allDataReceived*/) { return false; }

  virtual String filenameExtension() const {
    return String();
  }  // null string if unknown

  virtual void destroyDecodedData(bool destroyAll) = 0;

  SharedBuffer* data() { return m_encodedImageData.get(); }

  // Animation begins whenever someone draws the image, so startAnimation() is
  // not normally called. It will automatically pause once all observers no
  // longer want to render the image anywhere.
  enum CatchUpAnimation { DoNotCatchUp, CatchUp };
  virtual void startAnimation(CatchUpAnimation = CatchUp) {}
  virtual void stopAnimation() {}
  virtual void resetAnimation() {}

  // True if this image can potentially animate.
  virtual bool maybeAnimated() { return false; }

  // Typically the ImageResource that owns us.
  ImageObserver* imageObserver() const { return m_imageObserver; }
  void setImageObserver(ImageObserver* observer) { m_imageObserver = observer; }

  enum TileRule { StretchTile, RoundTile, SpaceTile, RepeatTile };

  virtual PassRefPtr<Image> imageForDefaultFrame();

  virtual void drawPattern(GraphicsContext*,
                           const FloatRect&,
                           const FloatSize&,
                           const FloatPoint& phase,
                           CompositeOperator,
                           const FloatRect&,
                           WebBlendMode = WebBlendModeNormal,
                           const IntSize& repeatSpacing = IntSize());

#if ENABLE(ASSERT)
  virtual bool notSolidColor() { return true; }
#endif

 protected:
  Image(ImageObserver* = 0);

  static void fillWithSolidColor(GraphicsContext*,
                                 const FloatRect& dstRect,
                                 const Color&,
                                 CompositeOperator);
  static FloatRect adjustForNegativeSize(const FloatRect&);  // A helper method
                                                             // for translating
                                                             // negative width
                                                             // and height
                                                             // values.

  virtual void draw(GraphicsContext*,
                    const FloatRect& dstRect,
                    const FloatRect& srcRect,
                    CompositeOperator,
                    WebBlendMode) = 0;
  virtual void draw(GraphicsContext*,
                    const FloatRect& dstRect,
                    const FloatRect& srcRect,
                    CompositeOperator,
                    WebBlendMode,
                    RespectImageOrientationEnum);
  void drawTiled(GraphicsContext*,
                 const FloatRect& dstRect,
                 const FloatPoint& srcPoint,
                 const FloatSize& tileSize,
                 CompositeOperator,
                 WebBlendMode,
                 const IntSize& repeatSpacing);
  void drawTiled(GraphicsContext*,
                 const FloatRect& dstRect,
                 const FloatRect& srcRect,
                 const FloatSize& tileScaleFactor,
                 TileRule hRule,
                 TileRule vRule,
                 CompositeOperator);

  // Supporting tiled drawing
  virtual bool mayFillWithSolidColor() { return false; }
  virtual Color solidColor() const { return Color(); }

 private:
  RefPtr<SharedBuffer> m_encodedImageData;
  ImageObserver* m_imageObserver;
};

#define DEFINE_IMAGE_TYPE_CASTS(typeName)                          \
  DEFINE_TYPE_CASTS(typeName, Image, image, image->is##typeName(), \
                    image.is##typeName())

}  // namespace blink

#endif  // SKY_ENGINE_PLATFORM_GRAPHICS_IMAGE_H_
