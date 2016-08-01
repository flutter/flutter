/*
 * Copyright (C) 2006 Samuel Weinig (sam.weinig@gmail.com)
 * Copyright (C) 2004, 2005, 2006 Apple Computer, Inc.  All rights reserved.
 * Copyright (C) 2008-2009 Torch Mobile, Inc.
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

#ifndef SKY_ENGINE_PLATFORM_GRAPHICS_BITMAPIMAGE_H_
#define SKY_ENGINE_PLATFORM_GRAPHICS_BITMAPIMAGE_H_

#include "sky/engine/platform/geometry/IntSize.h"
#include "sky/engine/platform/graphics/Color.h"
#include "sky/engine/platform/graphics/FrameData.h"
#include "sky/engine/platform/graphics/Image.h"
#include "sky/engine/platform/graphics/ImageOrientation.h"
#include "sky/engine/platform/graphics/ImageSource.h"
#include "sky/engine/wtf/Forward.h"

namespace blink {

template <typename T> class Timer;

class PLATFORM_EXPORT BitmapImage : public Image {
    friend class GeneratedImage;
    friend class CrossfadeGeneratedImage;
    friend class GradientGeneratedImage;
    friend class GraphicsContext;
public:
    static PassRefPtr<BitmapImage> create(ImageObserver* observer = 0)
    {
        return adoptRef(new BitmapImage(observer));
    }
    virtual ~BitmapImage();

    virtual bool isBitmapImage() const override;

    virtual IntSize size() const override;
    IntSize sizeRespectingOrientation() const;
    IntSize currentFrameSize() const;
    virtual bool getHotSpot(IntPoint&) const override;

    virtual bool dataChanged(bool allDataReceived) override;
    bool isAllDataReceived() const { return m_allDataReceived; }
    bool hasColorProfile() const;
    virtual String filenameExtension() const override;

    // It may look unusual that there is no start animation call as public API.  This is because
    // we start and stop animating lazily.  Animation begins whenever someone draws the image.  It will
    // automatically pause once all observers no longer want to render the image anywhere.
    virtual void stopAnimation() override;
    virtual void resetAnimation() override;
    virtual bool maybeAnimated() override;

    virtual PassRefPtr<Image> imageForDefaultFrame() override;
    virtual bool currentFrameKnownToBeOpaque() override;

    ImageOrientation currentFrameOrientation();

#if ENABLE(ASSERT)
    virtual bool notSolidColor() override;
#endif

private:
    friend class BitmapImageTest;

    void resetDecoder();
    void updateSize() const;

protected:
    enum RepetitionCountStatus {
      Unknown,    // We haven't checked the source's repetition count.
      Uncertain,  // We have a repetition count, but it might be wrong (some GIFs have a count after the image data, and will report "loop once" until all data has been decoded).
      Certain     // The repetition count is known to be correct.
    };

    BitmapImage(ImageObserver* = 0);

    virtual void draw(GraphicsContext*, const FloatRect& dstRect, const FloatRect& srcRect, CompositeOperator, WebBlendMode) override;
    virtual void draw(GraphicsContext*, const FloatRect& dstRect, const FloatRect& srcRect, CompositeOperator, WebBlendMode, RespectImageOrientationEnum) override;

    // True if the image is animated (contains multiple frames)
    bool isAnimated();
    size_t currentFrame() const { return m_currentFrame; }
    size_t frameCount();
    bool frameIsCompleteAtIndex(size_t);
    float frameDurationAtIndex(size_t);
    bool frameHasAlphaAtIndex(size_t);
    ImageOrientation frameOrientationAtIndex(size_t);

    // Decodes and caches a frame. Never accessed except internally.
    void cacheFrame(size_t index);
    // Called before accessing m_frames[index]. Returns false on index out of bounds.
    bool ensureFrameIsCached(size_t index);

    // Called to invalidate cached data. When |destroyAll| is true, we wipe out
    // the entire frame buffer cache and tell the image source to destroy
    // everything; this is used when e.g. we want to free some room in the image
    // cache. If |destroyAll| is false, we delete frames except the current
    // frame; this is used while animating large images to keep memory footprint
    // low; the decoder should preserve the current frame and may preserve some
    // other frames to avoid redecoding the whole image on every frame.
    virtual void destroyDecodedData(bool destroyAll) override;

    // If the image is large enough, calls destroyDecodedData().
    void destroyDecodedDataIfNecessary();

    // Generally called by destroyDecodedData(), destroys whole-image metadata
    // and notifies observers that the memory footprint has (hopefully)
    // decreased by |frameBytesCleared|.
    void destroyMetadataAndNotify(size_t frameBytesCleared);

    // Whether or not size is available yet.
    bool isSizeAvailable();

    // Animation.
    int repetitionCount(bool imageKnownToBeComplete);  // |imageKnownToBeComplete| should be set if the caller knows the entire image has been decoded.
    bool shouldAnimate();
    virtual void startAnimation(CatchUpAnimation = CatchUp) override;
    void advanceAnimation(Timer<BitmapImage>*);

    // Function that does the real work of advancing the animation.  When
    // skippingFrames is true, we're in the middle of a loop trying to skip over
    // a bunch of animation frames, so we should not do things like decode each
    // one or notify our observers.
    // Returns whether the animation was advanced.
    bool internalAdvanceAnimation(bool skippingFrames);

    // Checks to see if the image is a 1x1 solid color.  We optimize these images and just do a fill rect instead.
    // This check should happen regardless whether m_checkedForSolidColor is already set, as the frame may have
    // changed.
    void checkForSolidColor();

    virtual bool mayFillWithSolidColor() override;
    virtual Color solidColor() const override;

    ImageSource m_source;
    mutable IntSize m_size; // The size to use for the overall image (will just be the size of the first image).
    mutable IntSize m_sizeRespectingOrientation;

    size_t m_currentFrame; // The index of the current frame of animation.
    Vector<FrameData, 1> m_frames; // An array of the cached frames of the animation. We have to ref frames to pin them in the cache.

    Timer<BitmapImage>* m_frameTimer;
    int m_repetitionCount; // How many total animation loops we should do.  This will be cAnimationNone if this image type is incapable of animation.
    RepetitionCountStatus m_repetitionCountStatus;
    int m_repetitionsComplete;  // How many repetitions we've finished.
    double m_desiredFrameStartTime;  // The system time at which we hope to see the next call to startAnimation().

    Color m_solidColor;  // If we're a 1x1 solid color, this is the color to use to fill.

    size_t m_frameCount;

    bool m_isSolidColor : 1; // Whether or not we are a 1x1 solid image.
    bool m_checkedForSolidColor : 1; // Whether we've checked the frame for solid color.

    bool m_animationFinished : 1; // Whether or not we've completed the entire animation.

    bool m_allDataReceived : 1; // Whether or not we've received all our data.
    mutable bool m_haveSize : 1; // Whether or not our |m_size| member variable has the final overall image size yet.
    bool m_sizeAvailable : 1; // Whether or not we can obtain the size of the first image frame yet from ImageIO.
    mutable bool m_hasUniformFrameSize : 1;
    mutable bool m_haveFrameCount : 1;
};

DEFINE_IMAGE_TYPE_CASTS(BitmapImage);

} // namespace blink

#endif  // SKY_ENGINE_PLATFORM_GRAPHICS_BITMAPIMAGE_H_
