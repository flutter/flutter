/*
 * Copyright (C) 2006 Apple Computer, Inc.  All rights reserved.
 * Copyright (C) Research In Motion Limited 2009-2010. All rights reserved.
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

#ifndef ImageFrame_h
#define ImageFrame_h

#include "platform/PlatformExport.h"
#include "platform/geometry/IntRect.h"
#include "platform/graphics/skia/NativeImageSkia.h"
#include "wtf/Assertions.h"
#include "wtf/PassRefPtr.h"

namespace blink {

// ImageFrame represents the decoded image data.  This buffer is what all
// decoders write a single frame into.
class PLATFORM_EXPORT ImageFrame {
public:
    enum Status { FrameEmpty, FramePartial, FrameComplete };
    enum DisposalMethod {
        // If you change the numeric values of these, make sure you audit
        // all users, as some users may cast raw values to/from these
        // constants.
        DisposeNotSpecified, // Leave frame in framebuffer
        DisposeKeep, // Leave frame in framebuffer
        DisposeOverwriteBgcolor, // Clear frame to fully transparent
        DisposeOverwritePrevious // Clear frame to previous framebuffer contents
    };
    // Indicates how non-opaque pixels in the current frame rectangle
    // are blended with those in the previous frame.
    // Notes:
    // * GIF always uses 'BlendAtopPreviousFrame'.
    // * WebP also uses the 'BlendAtopBgcolor' option. This is useful for
    //   cases where one wants to transform a few opaque pixels of the
    //   previous frame into non-opaque pixels in the current frame.
    enum AlphaBlendSource {
        // Blend non-opaque pixels atop the corresponding pixels in the
        // initial buffer state (i.e. any previous frame buffer after having
        // been properly disposed).
        BlendAtopPreviousFrame,

        // Blend non-opaque pixels against fully transparent (i.e. simply
        // overwrite the corresponding pixels).
        BlendAtopBgcolor,
    };
    typedef uint32_t PixelData;

    ImageFrame();

    ImageFrame(const ImageFrame& other) { operator=(other); }

    // For backends which refcount their data, this operator doesn't need to
    // create a new copy of the image data, only increase the ref count.
    ImageFrame& operator=(const ImageFrame& other);

    // These do not touch other metadata, only the raw pixel data.
    void clearPixelData();
    void zeroFillPixelData();
    void zeroFillFrameRect(const IntRect&);

    // Makes this frame have an independent copy of the provided image's
    // pixel data, so that modifications in one frame are not reflected in
    // the other.  Returns whether the copy succeeded.
    bool copyBitmapData(const ImageFrame&);

    // Copies the pixel data at [(startX, startY), (endX, startY)) to the
    // same X-coordinates on each subsequent row up to but not including
    // endY.
    void copyRowNTimes(int startX, int endX, int startY, int endY)
    {
        ASSERT(startX < width());
        ASSERT(endX <= width());
        ASSERT(startY < height());
        ASSERT(endY <= height());
        const int rowBytes = (endX - startX) * sizeof(PixelData);
        const PixelData* const startAddr = getAddr(startX, startY);
        for (int destY = startY + 1; destY < endY; ++destY)
            memcpy(getAddr(startX, destY), startAddr, rowBytes);
    }

    // Allocates space for the pixel data.  Must be called before any pixels
    // are written.  Must only be called once.  Returns whether allocation
    // succeeded.
    bool setSize(int newWidth, int newHeight);

    // Returns a caller-owned pointer to the underlying native image data.
    // (Actual use: This pointer will be owned by BitmapImage and freed in
    // FrameData::clear()).
    PassRefPtr<NativeImageSkia> asNewNativeImage() const;

    bool hasAlpha() const;
    const IntRect& originalFrameRect() const { return m_originalFrameRect; }
    Status status() const { return m_status; }
    unsigned duration() const { return m_duration; }
    DisposalMethod disposalMethod() const { return m_disposalMethod; }
    AlphaBlendSource alphaBlendSource() const { return m_alphaBlendSource; }
    bool premultiplyAlpha() const { return m_premultiplyAlpha; }
    SkBitmap::Allocator* allocator() const { return m_allocator; }
    const SkBitmap& getSkBitmap() const { return m_bitmap; }
    // Returns true if the pixels changed, but the bitmap has not yet been notified.
    bool pixelsChanged() const { return m_pixelsChanged; }

    size_t requiredPreviousFrameIndex() const
    {
        ASSERT(m_requiredPreviousFrameIndexValid);
        return m_requiredPreviousFrameIndex;
    }
#if ENABLE(ASSERT)
    bool requiredPreviousFrameIndexValid() const { return m_requiredPreviousFrameIndexValid; }
#endif
    void setHasAlpha(bool alpha);
    void setOriginalFrameRect(const IntRect& r) { m_originalFrameRect = r; }
    void setStatus(Status);
    void setDuration(unsigned duration) { m_duration = duration; }
    void setDisposalMethod(DisposalMethod disposalMethod) { m_disposalMethod = disposalMethod; }
    void setAlphaBlendSource(AlphaBlendSource alphaBlendSource) { m_alphaBlendSource = alphaBlendSource; }
    void setPremultiplyAlpha(bool premultiplyAlpha) { m_premultiplyAlpha = premultiplyAlpha; }
    void setMemoryAllocator(SkBitmap::Allocator* allocator) { m_allocator = allocator; }
    void setSkBitmap(const SkBitmap& bitmap) { m_bitmap = bitmap; }
    // The pixelsChanged flag needs to be set when the raw pixel data was directly modified
    // (e.g. through a pointer or setRGBA). The flag is usually set after a batch of changes was made.
    void setPixelsChanged(bool pixelsChanged) { m_pixelsChanged = pixelsChanged; }

    void setRequiredPreviousFrameIndex(size_t previousFrameIndex)
    {
        m_requiredPreviousFrameIndex = previousFrameIndex;
#if ENABLE(ASSERT)
        m_requiredPreviousFrameIndexValid = true;
#endif
    }

    inline PixelData* getAddr(int x, int y)
    {
        return m_bitmap.getAddr32(x, y);
    }

    inline void setRGBA(int x, int y, unsigned r, unsigned g, unsigned b, unsigned a)
    {
        setRGBA(getAddr(x, y), r, g, b, a);
    }

    inline void setRGBA(PixelData* dest, unsigned r, unsigned g, unsigned b, unsigned a)
    {
        if (m_premultiplyAlpha)
            setRGBAPremultiply(dest, r, g, b, a);
        else
            *dest = SkPackARGB32NoCheck(a, r, g, b);
    }

    static const unsigned div255 = static_cast<unsigned>(1.0 / 255 * (1 << 24)) + 1;

    static inline void setRGBAPremultiply(PixelData* dest, unsigned r, unsigned g, unsigned b, unsigned a)
    {
        if (a < 255) {
            if (!a) {
                *dest = 0;
                return;
            }

            unsigned alpha = a * div255;
            r = (r * alpha) >> 24;
            g = (g * alpha) >> 24;
            b = (b * alpha) >> 24;
        }

        // Call the "NoCheck" version since we may deliberately pass non-premultiplied
        // values, and we don't want an assert.
        *dest = SkPackARGB32NoCheck(a, r, g, b);
    }

    static inline void setRGBARaw(PixelData* dest, unsigned r, unsigned g, unsigned b, unsigned a)
    {
        *dest = SkPackARGB32NoCheck(a, r, g, b);
    }

    // Notifies the SkBitmap if any pixels changed and resets the flag.
    inline void notifyBitmapIfPixelsChanged()
    {
        if (m_pixelsChanged)
            m_bitmap.notifyPixelsChanged();
        m_pixelsChanged = false;
    }

private:
    int width() const
    {
        return m_bitmap.width();
    }

    int height() const
    {
        return m_bitmap.height();
    }

    SkBitmap m_bitmap;
    SkBitmap::Allocator* m_allocator;
    bool m_hasAlpha;
    // This will always just be the entire buffer except for GIF or WebP
    // frames whose original rect was smaller than the overall image size.
    IntRect m_originalFrameRect;
    Status m_status;
    unsigned m_duration;
    DisposalMethod m_disposalMethod;
    AlphaBlendSource m_alphaBlendSource;
    bool m_premultiplyAlpha;
    // True if the pixels changed, but the bitmap has not yet been notified.
    bool m_pixelsChanged;

    // The frame that must be decoded before this frame can be decoded.
    // WTF::kNotFound if this frame doesn't require any previous frame.
    // This is used by ImageDecoder::clearCacheExceptFrame(), and will never
    // be read for image formats that do not have multiple frames.
    size_t m_requiredPreviousFrameIndex;
#if ENABLE(ASSERT)
    bool m_requiredPreviousFrameIndexValid;
#endif
};

} // namespace blink

#endif
