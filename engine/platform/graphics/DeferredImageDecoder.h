/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
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

#ifndef DeferredImageDecoder_h
#define DeferredImageDecoder_h

#include "SkBitmap.h"
#include "SkPixelRef.h"
#include "platform/PlatformExport.h"
#include "platform/geometry/IntSize.h"
#include "platform/graphics/ImageFrameGenerator.h"
#include "platform/graphics/ImageSource.h"
#include "platform/image-decoders/ImageDecoder.h"
#include "wtf/Forward.h"
#include "wtf/OwnPtr.h"
#include "wtf/Vector.h"

namespace blink {

class ImageFrameGenerator;
class SharedBuffer;

class PLATFORM_EXPORT DeferredImageDecoder {
    WTF_MAKE_NONCOPYABLE(DeferredImageDecoder);
public:
    ~DeferredImageDecoder();
    static PassOwnPtr<DeferredImageDecoder> create(const SharedBuffer& data, ImageSource::AlphaOption, ImageSource::GammaAndColorProfileOption);

    static PassOwnPtr<DeferredImageDecoder> createForTesting(PassOwnPtr<ImageDecoder>);

    static bool isLazyDecoded(const SkBitmap&);

    static void setEnabled(bool);
    static bool enabled();

    String filenameExtension() const;

    ImageFrame* frameBufferAtIndex(size_t index);

    void setData(SharedBuffer& data, bool allDataReceived);

    bool isSizeAvailable();
    bool hasColorProfile() const;
    IntSize size() const;
    IntSize frameSizeAtIndex(size_t index) const;
    size_t frameCount();
    int repetitionCount() const;
    size_t clearCacheExceptFrame(size_t);
    bool frameHasAlphaAtIndex(size_t index) const;
    bool frameIsCompleteAtIndex(size_t) const;
    float frameDurationAtIndex(size_t) const;
    unsigned frameBytesAtIndex(size_t index) const;
    ImageOrientation orientation() const;
    bool hotSpot(IntPoint&) const;

    // For testing.
    ImageFrameGenerator* frameGenerator() { return m_frameGenerator.get(); }

private:
    explicit DeferredImageDecoder(PassOwnPtr<ImageDecoder> actualDecoder);
    void prepareLazyDecodedFrames();
    SkBitmap createBitmap(size_t index);
    void activateLazyDecoding();

    RefPtr<SharedBuffer> m_data;
    bool m_allDataReceived;
    unsigned m_lastDataSize;
    bool m_dataChanged;
    OwnPtr<ImageDecoder> m_actualDecoder;

    String m_filenameExtension;
    IntSize m_size;
    ImageOrientation m_orientation;
    int m_repetitionCount;
    bool m_hasColorProfile;

    Vector<OwnPtr<ImageFrame> > m_lazyDecodedFrames;
    RefPtr<ImageFrameGenerator> m_frameGenerator;

    static bool s_enabled;
};

} // namespace blink

#endif
