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

#ifndef ImageDecoder_h
#define ImageDecoder_h

#include "SkColorPriv.h"
#include "platform/PlatformExport.h"
#include "platform/PlatformScreen.h"
#include "platform/SharedBuffer.h"
#include "platform/graphics/ImageSource.h"
#include "platform/image-decoders/ImageFrame.h"
#include "public/platform/Platform.h"
#include "wtf/Assertions.h"
#include "wtf/RefPtr.h"
#include "wtf/Vector.h"
#include "wtf/text/WTFString.h"

#if USE(QCMSLIB)
#include "qcms.h"
#if OS(MACOSX)
#include <ApplicationServices/ApplicationServices.h>
#include "wtf/RetainPtr.h"
#endif
#endif

namespace blink {

// ImagePlanes can be used to decode color components into provided buffers instead of using an ImageFrame.
class PLATFORM_EXPORT ImagePlanes {
public:
    ImagePlanes();
    ImagePlanes(void* planes[3], size_t rowBytes[3]);

    void* plane(int);
    size_t rowBytes(int) const;

private:
    void* m_planes[3];
    size_t m_rowBytes[3];
};

// ImageDecoder is a base for all format-specific decoders
// (e.g. JPEGImageDecoder). This base manages the ImageFrame cache.
//
class PLATFORM_EXPORT ImageDecoder {
    WTF_MAKE_NONCOPYABLE(ImageDecoder); WTF_MAKE_FAST_ALLOCATED;
public:
    static const size_t noDecodedImageByteLimit = blink::Platform::noDecodedImageByteLimit;

    ImageDecoder(ImageSource::AlphaOption alphaOption, ImageSource::GammaAndColorProfileOption gammaAndColorProfileOption, size_t maxDecodedBytes)
        : m_premultiplyAlpha(alphaOption == ImageSource::AlphaPremultiplied)
        , m_ignoreGammaAndColorProfile(gammaAndColorProfileOption == ImageSource::GammaAndColorProfileIgnored)
        , m_maxDecodedBytes(maxDecodedBytes)
        , m_sizeAvailable(false)
        , m_isAllDataReceived(false)
        , m_failed(false) { }

    virtual ~ImageDecoder() { }

    // Returns a caller-owned decoder of the appropriate type.  Returns 0 if
    // we can't sniff a supported type from the provided data (possibly
    // because there isn't enough data yet).
    // Sets m_maxDecodedBytes to Platform::maxImageDecodedBytes().
    static PassOwnPtr<ImageDecoder> create(const SharedBuffer& data, ImageSource::AlphaOption, ImageSource::GammaAndColorProfileOption);

    // Returns a decoder with custom maxDecodedSize.
    static PassOwnPtr<ImageDecoder> create(const SharedBuffer& data, ImageSource::AlphaOption, ImageSource::GammaAndColorProfileOption, size_t maxDecodedSize);

    virtual String filenameExtension() const = 0;

    bool isAllDataReceived() const { return m_isAllDataReceived; }

    virtual void setData(SharedBuffer* data, bool allDataReceived)
    {
        if (m_failed)
            return;
        m_data = data;
        m_isAllDataReceived = allDataReceived;
    }

    virtual bool isSizeAvailable()
    {
        return !m_failed && m_sizeAvailable;
    }

    bool isSizeAvailable() const
    {
        return !m_failed && m_sizeAvailable;
    }

    virtual IntSize size() const { return m_size; }

    // Decoders which downsample images should override this method to
    // return the actual decoded size.
    virtual IntSize decodedSize() const { return size(); }

    // Decoders which support YUV decoding can override this to
    // give potentially different sizes per component.
    virtual IntSize decodedYUVSize(int component) const { return decodedSize(); }

    // This will only differ from size() for ICO (where each frame is a
    // different icon) or other formats where different frames are different
    // sizes. This does NOT differ from size() for GIF or WebP, since
    // decoding GIF or WebP composites any smaller frames against previous
    // frames to create full-size frames.
    virtual IntSize frameSizeAtIndex(size_t) const
    {
        return size();
    }

    // Returns whether the size is legal (i.e. not going to result in
    // overflow elsewhere).  If not, marks decoding as failed.
    virtual bool setSize(unsigned width, unsigned height)
    {
        if (sizeCalculationMayOverflow(width, height))
            return setFailed();
        m_size = IntSize(width, height);
        m_sizeAvailable = true;
        return true;
    }

    // Lazily-decodes enough of the image to get the frame count (if
    // possible), without decoding the individual frames.
    // FIXME: Right now that has to be done by each subclass; factor the
    // decode call out and use it here.
    virtual size_t frameCount() { return 1; }

    virtual int repetitionCount() const { return cAnimationNone; }

    // Decodes as much of the requested frame as possible, and returns an
    // ImageDecoder-owned pointer.
    virtual ImageFrame* frameBufferAtIndex(size_t) = 0;

    // Make the best effort guess to check if the requested frame has alpha channel.
    virtual bool frameHasAlphaAtIndex(size_t) const;

    // Whether or not the frame is fully received.
    virtual bool frameIsCompleteAtIndex(size_t) const;

    // Duration for displaying a frame in seconds. This method is used by animated images only.
    virtual float frameDurationAtIndex(size_t) const { return 0; }

    // Number of bytes in the decoded frame requested. Return 0 if not yet decoded.
    virtual unsigned frameBytesAtIndex(size_t) const;

    ImageOrientation orientation() const { return m_orientation; }

    static bool deferredImageDecodingEnabled();

    void setIgnoreGammaAndColorProfile(bool flag) { m_ignoreGammaAndColorProfile = flag; }
    bool ignoresGammaAndColorProfile() const { return m_ignoreGammaAndColorProfile; }

    virtual bool hasColorProfile() const { return false; }

#if USE(QCMSLIB)
    enum { iccColorProfileHeaderLength = 128 };

    static bool rgbColorProfile(const char* profileData, unsigned profileLength)
    {
        ASSERT_UNUSED(profileLength, profileLength >= iccColorProfileHeaderLength);

        return !memcmp(&profileData[16], "RGB ", 4);
    }

    static bool inputDeviceColorProfile(const char* profileData, unsigned profileLength)
    {
        ASSERT_UNUSED(profileLength, profileLength >= iccColorProfileHeaderLength);

        return !memcmp(&profileData[12], "mntr", 4) || !memcmp(&profileData[12], "scnr", 4);
    }

    class OutputDeviceProfile {
    public:
        OutputDeviceProfile()
            : m_outputDeviceProfile(0)
        {
            // FIXME: Add optional ICCv4 support.
#if OS(MACOSX)
            RetainPtr<CGColorSpaceRef> monitorColorSpace(AdoptCF, CGDisplayCopyColorSpace(CGMainDisplayID()));
            CFDataRef iccProfile(CGColorSpaceCopyICCProfile(monitorColorSpace.get()));
            if (iccProfile) {
                size_t length = CFDataGetLength(iccProfile);
                const unsigned char* systemProfile = CFDataGetBytePtr(iccProfile);
                m_outputDeviceProfile = qcms_profile_from_memory(systemProfile, length);
                CFRelease(iccProfile);
            }
#else
            // FIXME: add support for multiple monitors.
            ColorProfile profile;
            screenColorProfile(profile);
            if (!profile.isEmpty())
                m_outputDeviceProfile = qcms_profile_from_memory(profile.data(), profile.size());
#endif
            if (m_outputDeviceProfile && qcms_profile_is_bogus(m_outputDeviceProfile)) {
                qcms_profile_release(m_outputDeviceProfile);
                m_outputDeviceProfile = 0;
            }
            if (!m_outputDeviceProfile)
                m_outputDeviceProfile = qcms_profile_sRGB();
            if (m_outputDeviceProfile)
                qcms_profile_precache_output_transform(m_outputDeviceProfile);
        }

        qcms_profile* profile() const { return m_outputDeviceProfile; }

    private:
        qcms_profile* m_outputDeviceProfile;
    };

    static qcms_profile* qcmsOutputDeviceProfile()
    {
        AtomicallyInitializedStatic(OutputDeviceProfile*, outputDeviceProfile = new OutputDeviceProfile());

        return outputDeviceProfile->profile();
    }
#endif

    // Sets the "decode failure" flag.  For caller convenience (since so
    // many callers want to return false after calling this), returns false
    // to enable easy tailcalling.  Subclasses may override this to also
    // clean up any local data.
    virtual bool setFailed()
    {
        m_failed = true;
        return false;
    }

    bool failed() const { return m_failed; }

    // Clears decoded pixel data from all frames except the provided frame.
    // Callers may pass WTF::kNotFound to clear all frames.
    // Note: If |m_frameBufferCache| contains only one frame, it won't be cleared.
    // Returns the number of bytes of frame data actually cleared.
    virtual size_t clearCacheExceptFrame(size_t);

    // If the image has a cursor hot-spot, stores it in the argument
    // and returns true. Otherwise returns false.
    virtual bool hotSpot(IntPoint&) const { return false; }

    virtual void setMemoryAllocator(SkBitmap::Allocator* allocator)
    {
        // FIXME: this doesn't work for images with multiple frames.
        if (m_frameBufferCache.isEmpty()) {
            m_frameBufferCache.resize(1);
            m_frameBufferCache[0].setRequiredPreviousFrameIndex(
                findRequiredPreviousFrame(0, false));
        }
        m_frameBufferCache[0].setMemoryAllocator(allocator);
    }

    virtual bool canDecodeToYUV() const { return false; }
    virtual bool decodeToYUV() { return false; }
    virtual void setImagePlanes(PassOwnPtr<ImagePlanes>) { }

protected:
    // Calculates the most recent frame whose image data may be needed in
    // order to decode frame |frameIndex|, based on frame disposal methods
    // and |frameRectIsOpaque|, where |frameRectIsOpaque| signifies whether
    // the rectangle of frame at |frameIndex| is known to be opaque.
    // If no previous frame's data is required, returns WTF::kNotFound.
    //
    // This function requires that the previous frame's
    // |m_requiredPreviousFrameIndex| member has been set correctly. The
    // easiest way to ensure this is for subclasses to call this method and
    // store the result on the frame via setRequiredPreviousFrameIndex()
    // as soon as the frame has been created and parsed sufficiently to
    // determine the disposal method; assuming this happens for all frames
    // in order, the required invariant will hold.
    //
    // Image formats which do not use more than one frame do not need to
    // worry about this; see comments on
    // ImageFrame::m_requiredPreviousFrameIndex.
    size_t findRequiredPreviousFrame(size_t frameIndex, bool frameRectIsOpaque);

    virtual void clearFrameBuffer(size_t frameIndex);

    RefPtr<SharedBuffer> m_data; // The encoded data.
    Vector<ImageFrame, 1> m_frameBufferCache;
    bool m_premultiplyAlpha;
    bool m_ignoreGammaAndColorProfile;
    ImageOrientation m_orientation;

    // The maximum amount of memory a decoded image should require. Ideally,
    // image decoders should downsample large images to fit under this limit
    // (and then return the downsampled size from decodedSize()). Ignoring
    // this limit can cause excessive memory use or even crashes on low-
    // memory devices.
    size_t m_maxDecodedBytes;

private:
    // Some code paths compute the size of the image as "width * height * 4"
    // and return it as a (signed) int.  Avoid overflow.
    static bool sizeCalculationMayOverflow(unsigned width, unsigned height)
    {
        unsigned long long total_size = static_cast<unsigned long long>(width)
                                      * static_cast<unsigned long long>(height);
        return total_size > ((1 << 29) - 1);
    }

    IntSize m_size;
    bool m_sizeAvailable;
    bool m_isAllDataReceived;
    bool m_failed;
};

} // namespace blink

#endif
