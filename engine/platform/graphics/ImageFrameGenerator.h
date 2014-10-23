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

#ifndef ImageFrameGenerator_h
#define ImageFrameGenerator_h

#include "SkBitmap.h"
#include "SkSize.h"
#include "SkTypes.h"
#include "platform/PlatformExport.h"
#include "platform/graphics/ThreadSafeDataTransport.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefCounted.h"
#include "wtf/RefPtr.h"
#include "wtf/ThreadingPrimitives.h"
#include "wtf/ThreadSafeRefCounted.h"
#include "wtf/Vector.h"

namespace blink {

class ImageDecoder;
class ImagePlanes;
class SharedBuffer;

class PLATFORM_EXPORT ImageDecoderFactory {
    WTF_MAKE_NONCOPYABLE(ImageDecoderFactory);
public:
    ImageDecoderFactory() {}
    virtual ~ImageDecoderFactory() { }
    virtual PassOwnPtr<ImageDecoder> create() = 0;
};

class PLATFORM_EXPORT ImageFrameGenerator : public ThreadSafeRefCounted<ImageFrameGenerator> {
    WTF_MAKE_NONCOPYABLE(ImageFrameGenerator);
public:
    static PassRefPtr<ImageFrameGenerator> create(const SkISize& fullSize, PassRefPtr<SharedBuffer> data, bool allDataReceived, bool isMultiFrame = false)
    {
        return adoptRef(new ImageFrameGenerator(fullSize, data, allDataReceived, isMultiFrame));
    }

    ImageFrameGenerator(const SkISize& fullSize, PassRefPtr<SharedBuffer>, bool allDataReceived, bool isMultiFrame);
    ~ImageFrameGenerator();

    // Decodes and scales the specified frame indicated by |index|. Dimensions
    // and output format are specified in |info|. Decoded pixels are written
    // into |pixels| with a stride of |rowBytes|.
    //
    // Returns true if decoding was successful.
    bool decodeAndScale(const SkImageInfo&, size_t index, void* pixels, size_t rowBytes);

    // Decodes YUV components directly into the provided memory planes.
    bool decodeToYUV(void* planes[3], size_t rowBytes[3]);

    void setData(PassRefPtr<SharedBuffer>, bool allDataReceived);

    // Creates a new SharedBuffer containing the data received so far.
    void copyData(RefPtr<SharedBuffer>*, bool* allDataReceived);

    SkISize getFullSize() const { return m_fullSize; }

    bool isMultiFrame() const { return m_isMultiFrame; }

    // FIXME: Return alpha state for each frame.
    bool hasAlpha(size_t);

    bool getYUVComponentSizes(SkISize componentSizes[3]);

private:
    class ExternalMemoryAllocator;
    friend class ImageFrameGeneratorTest;
    friend class DeferredImageDecoderTest;
    // For testing. |factory| will overwrite the default ImageDecoder creation logic if |factory->create()| returns non-zero.
    void setImageDecoderFactory(PassOwnPtr<ImageDecoderFactory> factory) { m_imageDecoderFactory = factory; }

    void setHasAlpha(size_t index, bool hasAlpha);

    // These methods are called while m_decodeMutex is locked.
    SkBitmap tryToResumeDecode(const SkISize& scaledSize, size_t index);

    // Use the given decoder to decode. If a decoder is not given then try to create one.
    // Returns true if decoding was complete.
    bool decode(size_t index, ImageDecoder**, SkBitmap*);

    SkISize m_fullSize;
    ThreadSafeDataTransport m_data;
    bool m_isMultiFrame;
    bool m_decodeFailedAndEmpty;
    Vector<bool> m_hasAlpha;
    int m_decodeCount;
    OwnPtr<ExternalMemoryAllocator> m_externalAllocator;

    OwnPtr<ImageDecoderFactory> m_imageDecoderFactory;

    // Prevents multiple decode operations on the same data.
    Mutex m_decodeMutex;

    // Protect concurrent access to m_hasAlpha.
    Mutex m_alphaMutex;
};

} // namespace blink

#endif
