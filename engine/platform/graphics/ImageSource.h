/*
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

#ifndef ImageSource_h
#define ImageSource_h

#include "platform/PlatformExport.h"
#include "platform/graphics/ImageOrientation.h"
#include "wtf/Forward.h"
#include "wtf/Noncopyable.h"
#include "wtf/OwnPtr.h"

namespace blink {

class DeferredImageDecoder;
class ImageOrientation;
class IntPoint;
class IntSize;
class NativeImageSkia;
class SharedBuffer;

// GIF and WebP support animation. The explanation below is in terms of GIF,
// but the same constants are used for WebP, too.
// GIFs have an optional 16-bit unsigned loop count that describes how an
// animated GIF should be cycled.  If the loop count is absent, the animation
// cycles once; if it is 0, the animation cycles infinitely; otherwise the
// animation plays n + 1 cycles (where n is the specified loop count).  If the
// GIF decoder defaults to cAnimationLoopOnce in the absence of any loop count
// and translates an explicit "0" loop count to cAnimationLoopInfinite, then we
// get a couple of nice side effects:
//   * By making cAnimationLoopOnce be 0, we allow the animation cycling code in
//     BitmapImage.cpp to avoid special-casing it, and simply treat all
//     non-negative loop counts identically.
//   * By making the other two constants negative, we avoid conflicts with any
//     real loop count values.
const int cAnimationLoopOnce = 0;
const int cAnimationLoopInfinite = -1;
const int cAnimationNone = -2;

class PLATFORM_EXPORT ImageSource {
    WTF_MAKE_NONCOPYABLE(ImageSource);
public:
    enum AlphaOption {
        AlphaPremultiplied,
        AlphaNotPremultiplied
    };

    enum GammaAndColorProfileOption {
        GammaAndColorProfileApplied,
        GammaAndColorProfileIgnored
    };

    ImageSource(AlphaOption alphaOption = AlphaPremultiplied, GammaAndColorProfileOption gammaAndColorProfileOption = GammaAndColorProfileApplied);
    ~ImageSource();

    // Tells the ImageSource that the Image no longer cares about decoded frame
    // data except for the specified frame. Callers may pass WTF::kNotFound to
    // clear all frames.
    //
    // In response, the ImageSource should delete cached decoded data for other
    // frames where possible to keep memory use low. The expectation is that in
    // the future, the caller may call createFrameAtIndex() with an index larger
    // than the one passed to this function, and the implementation may then
    // make use of the preserved frame data here in decoding that frame.
    // By contrast, callers who call this function and then later ask for an
    // earlier frame may require more work to be done, e.g. redecoding the image
    // from the beginning.
    //
    // Implementations may elect to preserve more frames than the one requested
    // here if doing so is likely to save CPU time in the future, but will pay
    // an increased memory cost to do so.
    //
    // Returns the number of bytes of frame data actually cleared.
    size_t clearCacheExceptFrame(size_t);

    bool initialized() const;
    void resetDecoder();

    void setData(SharedBuffer& data, bool allDataReceived);
    String filenameExtension() const;

    bool isSizeAvailable();
    bool hasColorProfile() const;
    IntSize size(RespectImageOrientationEnum = DoNotRespectImageOrientation) const;
    IntSize frameSizeAtIndex(size_t, RespectImageOrientationEnum = DoNotRespectImageOrientation) const;

    bool getHotSpot(IntPoint&) const;

    // Returns one of the cAnimationXXX constants at the top of the file, or
    // a loop count. In the latter case, the actual number of times the animation
    // cycles is one more than the loop count. See comment atop the file.
    int repetitionCount();

    size_t frameCount() const;

    PassRefPtr<NativeImageSkia> createFrameAtIndex(size_t);

    float frameDurationAtIndex(size_t) const;
    bool frameHasAlphaAtIndex(size_t) const; // Whether or not the frame actually used any alpha.
    bool frameIsCompleteAtIndex(size_t) const; // Whether or not the frame is fully received.
    ImageOrientation orientationAtIndex(size_t) const; // EXIF image orientation

    // Return the number of bytes in the decoded frame. If the frame is not yet
    // decoded then return 0.
    unsigned frameBytesAtIndex(size_t) const;

private:
    OwnPtr<DeferredImageDecoder> m_decoder;

    AlphaOption m_alphaOption;
    GammaAndColorProfileOption m_gammaAndColorProfileOption;
};

} // namespace blink

#endif
