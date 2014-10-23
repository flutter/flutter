/*
 * Copyright (c) 2008, Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef NativeImageSkia_h
#define NativeImageSkia_h

#include "SkBitmap.h"
#include "SkRect.h"
#include "SkSize.h"
#include "SkXfermode.h"
#include "platform/PlatformExport.h"
#include "platform/geometry/IntSize.h"
#include "platform/graphics/GraphicsTypes.h"
#include "wtf/Forward.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefCounted.h"

namespace blink {

class FloatPoint;
class FloatRect;
class FloatSize;
class GraphicsContext;

// This object is used as the "native image" in our port. When WebKit uses
// PassNativeImagePtr / NativeImagePtr, it is a smart pointer to this type.
// It has an SkBitmap, and also stores a cached resized image.
class PLATFORM_EXPORT NativeImageSkia : public RefCounted<NativeImageSkia> {
public:
    static PassRefPtr<NativeImageSkia> create()
    {
        return adoptRef(new NativeImageSkia());
    }

    // This factory method does a shallow copy of the passed-in SkBitmap
    // (ie., it references the same pixel data and bumps the refcount). Use
    // only when you want sharing semantics.
    static PassRefPtr<NativeImageSkia> create(const SkBitmap& bitmap)
    {
        return adoptRef(new NativeImageSkia(bitmap));
    }

    ~NativeImageSkia();

    // Returns true if the entire image has been decoded.
    bool isDataComplete() const { return bitmap().isImmutable(); }

    // Get reference to the internal SkBitmap representing this image.
    const SkBitmap& bitmap() const { return m_bitmap; }

    // We can keep a resized version of the bitmap cached on this object.
    // This function will return true if there is a cached version of the given
    // scale and subset.
    bool hasResizedBitmap(const SkISize& scaledImageSize, const SkIRect& scaledImageSubset) const;

    // This will return an existing resized image subset, or generate a new one
    // of the specified size and subset and possibly cache it.
    //
    // scaledImageSize
    // Dimensions of the scaled full image.
    //
    // scaledImageSubset
    // Rectangle of the subset in the scaled image.
    SkBitmap resizedBitmap(const SkISize& scaledImageSize, const SkIRect& scaledImageSubset) const;

    void draw(
        GraphicsContext*,
        const SkRect& srcRect,
        const SkRect& destRect,
        CompositeOperator,
        WebBlendMode) const;

    void drawPattern(
        GraphicsContext*,
        const FloatRect& srcRect,
        const FloatSize& scale,
        const FloatPoint& phase,
        CompositeOperator,
        const FloatRect& destRect,
        WebBlendMode,
        const IntSize& repeatSpacing) const;

private:
    NativeImageSkia();

    NativeImageSkia(const SkBitmap&);

    // ImageResourceInfo is used to uniquely identify cached or requested image
    // resizes.
    // Image resize is identified by the scaled image size and scaled image subset.
    struct ImageResourceInfo {
        SkISize scaledImageSize;
        SkIRect scaledImageSubset;

        ImageResourceInfo();

        bool isEqual(const SkISize& otherScaledImageSize, const SkIRect& otherScaledImageSubset) const;
        void set(const SkISize& otherScaledImageSize, const SkIRect& otherScaledImageSubset);
        SkIRect rectInSubset(const SkIRect& otherScaledImageRect);
    };

    // Returns true if the given resize operation should either resize the whole
    // image and cache it, or resize just the part it needs and throw the result
    // away.
    //
    // Calling this function may increment a request count that can change the
    // result of subsequent calls.
    //
    // On the one hand, if only a small subset is desired, then we will waste a
    // lot of time resampling the entire thing, so we only want to do exactly
    // what's required. On the other hand, resampling the entire bitmap is
    // better if we're going to be using it more than once (like a bitmap
    // scrolling on and off the screen. Since we only cache when doing the
    // entire thing, it's best to just do it up front.
    bool shouldCacheResampling(const SkISize& scaledImageSize, const SkIRect& scaledImageSubset) const;

    SkBitmap extractScaledImageFragment(const SkRect& srcRect, float scaleX, float scaleY, SkRect* scaledSrcRect) const;

    // The original image.
    SkBitmap m_bitmap;

    // The cached bitmap fragment. This is a subset of the scaled version of
    // |m_bitmap|. empty() returns true if there is no cached image.
    mutable SkBitmap m_resizedImage;

    // References how many times that the image size has been requested for
    // the last size.
    //
    // Every time we get a call to shouldCacheResampling, if it matches the
    // m_cachedImageInfo, we'll increment the counter, and if not, we'll reset
    // the counter and save the dimensions.
    //
    // This allows us to see if many requests have been made for the same
    // resized image, we know that we should probably cache it, even if all of
    // those requests individually are small and would not otherwise be cached.
    //
    // We also track scaling information and destination subset for the scaled
    // image. See comments for ImageResourceInfo.
    mutable ImageResourceInfo m_cachedImageInfo;
    mutable int m_resizeRequests;
};

} // namespace blink

#endif  // NativeImageSkia_h
