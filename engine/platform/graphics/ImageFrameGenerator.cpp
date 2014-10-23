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

#include "config.h"

#include "platform/graphics/ImageFrameGenerator.h"

#include "platform/SharedBuffer.h"
#include "platform/TraceEvent.h"
#include "platform/graphics/ImageDecodingStore.h"
#include "platform/image-decoders/ImageDecoder.h"

#include "skia/ext/image_operations.h"
#include "third_party/skia/include/core/SkMallocPixelRef.h"

namespace blink {

// Creates a SkPixelRef such that the memory for pixels is given by an external body.
// This is used to write directly to the memory given by Skia during decoding.
class ImageFrameGenerator::ExternalMemoryAllocator : public SkBitmap::Allocator {
public:
    ExternalMemoryAllocator(const SkImageInfo& info, void* pixels, size_t rowBytes)
        : m_info(info)
        , m_pixels(pixels)
        , m_rowBytes(rowBytes)
    {
    }

    virtual bool allocPixelRef(SkBitmap* dst, SkColorTable* ctable) OVERRIDE
    {
        const SkImageInfo& info = dst->info();
        if (kUnknown_SkColorType == info.colorType())
            return false;

        if (info != m_info || m_rowBytes != dst->rowBytes())
            return false;

        if (!dst->installPixels(m_info, m_pixels, m_rowBytes))
            return false;
        dst->lockPixels();
        return true;
    }

private:
    SkImageInfo m_info;
    void* m_pixels;
    size_t m_rowBytes;
};

ImageFrameGenerator::ImageFrameGenerator(const SkISize& fullSize, PassRefPtr<SharedBuffer> data, bool allDataReceived, bool isMultiFrame)
    : m_fullSize(fullSize)
    , m_isMultiFrame(isMultiFrame)
    , m_decodeFailedAndEmpty(false)
    , m_decodeCount(0)
{
    setData(data.get(), allDataReceived);
}

ImageFrameGenerator::~ImageFrameGenerator()
{
    ImageDecodingStore::instance()->removeCacheIndexedByGenerator(this);
}

void ImageFrameGenerator::setData(PassRefPtr<SharedBuffer> data, bool allDataReceived)
{
    m_data.setData(data.get(), allDataReceived);
}

void ImageFrameGenerator::copyData(RefPtr<SharedBuffer>* data, bool* allDataReceived)
{
    SharedBuffer* buffer = 0;
    m_data.data(&buffer, allDataReceived);
    if (buffer)
        *data = buffer->copy();
}

bool ImageFrameGenerator::decodeAndScale(const SkImageInfo& info, size_t index, void* pixels, size_t rowBytes)
{
    // This method is called to populate a discardable memory owned by Skia.

    // Prevents concurrent decode or scale operations on the same image data.
    MutexLocker lock(m_decodeMutex);

    // This implementation does not support scaling so check the requested size.
    SkISize scaledSize = SkISize::Make(info.fWidth, info.fHeight);
    ASSERT(m_fullSize == scaledSize);

    if (m_decodeFailedAndEmpty)
        return false;

    TRACE_EVENT2("blink", "ImageFrameGenerator::decodeAndScale", "generator", this, "decodeCount", m_decodeCount);

    m_externalAllocator = adoptPtr(new ExternalMemoryAllocator(info, pixels, rowBytes));

    SkBitmap bitmap = tryToResumeDecode(scaledSize, index);
    if (bitmap.isNull())
        return false;

    // Don't keep the allocator because it contains a pointer to memory
    // that we do not own.
    m_externalAllocator.clear();

    ASSERT(bitmap.width() == scaledSize.width());
    ASSERT(bitmap.height() == scaledSize.height());

    bool result = true;
    // Check to see if decoder has written directly to the memory provided
    // by Skia. If not make a copy.
    if (bitmap.getPixels() != pixels)
        result = bitmap.copyPixelsTo(pixels, rowBytes * info.fHeight, rowBytes);
    return result;
}

bool ImageFrameGenerator::decodeToYUV(void* planes[3], size_t rowBytes[3])
{
    // This method is called to populate a discardable memory owned by Skia.

    // Prevents concurrent decode or scale operations on the same image data.
    MutexLocker lock(m_decodeMutex);

    if (m_decodeFailedAndEmpty)
        return false;

    TRACE_EVENT2("blink", "ImageFrameGenerator::decodeToYUV", "generator", this, "decodeCount", static_cast<int>(m_decodeCount));

    if (!planes || !planes[0] || !planes[1] || !planes[2]
        || !rowBytes || !rowBytes[0] || !rowBytes[1] || !rowBytes[2]) {
        return false;
    }

    SharedBuffer* data = 0;
    bool allDataReceived = false;
    m_data.data(&data, &allDataReceived);

    // FIXME: YUV decoding does not currently support progressive decoding.
    if (!allDataReceived)
        return false;

    OwnPtr<ImageDecoder> decoder = ImageDecoder::create(*data, ImageSource::AlphaPremultiplied, ImageSource::GammaAndColorProfileApplied);
    if (!decoder)
        return false;

    decoder->setData(data, allDataReceived);

    OwnPtr<ImagePlanes> imagePlanes = adoptPtr(new ImagePlanes(planes, rowBytes));
    decoder->setImagePlanes(imagePlanes.release());
    bool yuvDecoded = decoder->decodeToYUV();
    if (yuvDecoded)
        setHasAlpha(0, false); // YUV is always opaque
    return yuvDecoded;
}

SkBitmap ImageFrameGenerator::tryToResumeDecode(const SkISize& scaledSize, size_t index)
{
    TRACE_EVENT1("blink", "ImageFrameGenerator::tryToResumeDecodeAndScale", "index", static_cast<int>(index));

    ImageDecoder* decoder = 0;
    const bool resumeDecoding = ImageDecodingStore::instance()->lockDecoder(this, m_fullSize, &decoder);
    ASSERT(!resumeDecoding || decoder);

    SkBitmap fullSizeImage;
    bool complete = decode(index, &decoder, &fullSizeImage);

    if (!decoder)
        return SkBitmap();

    // If we are not resuming decoding that means the decoder is freshly
    // created and we have ownership. If we are resuming decoding then
    // the decoder is owned by ImageDecodingStore.
    OwnPtr<ImageDecoder> decoderContainer;
    if (!resumeDecoding)
        decoderContainer = adoptPtr(decoder);

    if (fullSizeImage.isNull()) {
        // If decode has failed and resulted an empty image we can save work
        // in the future by returning early.
        m_decodeFailedAndEmpty = !m_isMultiFrame && decoder->failed();

        if (resumeDecoding)
            ImageDecodingStore::instance()->unlockDecoder(this, decoder);
        return SkBitmap();
    }

    // If the image generated is complete then there is no need to keep
    // the decoder. The exception is multi-frame decoder which can generate
    // multiple complete frames.
    const bool removeDecoder = complete && !m_isMultiFrame;

    if (resumeDecoding) {
        if (removeDecoder)
            ImageDecodingStore::instance()->removeDecoder(this, decoder);
        else
            ImageDecodingStore::instance()->unlockDecoder(this, decoder);
    } else if (!removeDecoder) {
        ImageDecodingStore::instance()->insertDecoder(this, decoderContainer.release());
    }
    return fullSizeImage;
}

void ImageFrameGenerator::setHasAlpha(size_t index, bool hasAlpha)
{
    MutexLocker lock(m_alphaMutex);
    if (index >= m_hasAlpha.size()) {
        const size_t oldSize = m_hasAlpha.size();
        m_hasAlpha.resize(index + 1);
        for (size_t i = oldSize; i < m_hasAlpha.size(); ++i)
            m_hasAlpha[i] = true;
    }
    m_hasAlpha[index] = hasAlpha;
}

bool ImageFrameGenerator::decode(size_t index, ImageDecoder** decoder, SkBitmap* bitmap)
{
    TRACE_EVENT2("blink", "ImageFrameGenerator::decode", "width", m_fullSize.width(), "height", m_fullSize.height());

    ASSERT(decoder);
    SharedBuffer* data = 0;
    bool allDataReceived = false;
    bool newDecoder = false;
    m_data.data(&data, &allDataReceived);

    // Try to create an ImageDecoder if we are not given one.
    if (!*decoder) {
        newDecoder = true;
        if (m_imageDecoderFactory)
            *decoder = m_imageDecoderFactory->create().leakPtr();

        if (!*decoder)
            *decoder = ImageDecoder::create(*data, ImageSource::AlphaPremultiplied, ImageSource::GammaAndColorProfileApplied).leakPtr();

        if (!*decoder)
            return false;
    }

    if (!m_isMultiFrame && newDecoder && allDataReceived) {
        // If we're using an external memory allocator that means we're decoding
        // directly into the output memory and we can save one memcpy.
        ASSERT(m_externalAllocator.get());
        (*decoder)->setMemoryAllocator(m_externalAllocator.get());
    }
    (*decoder)->setData(data, allDataReceived);

    ImageFrame* frame = (*decoder)->frameBufferAtIndex(index);
    (*decoder)->setData(0, false); // Unref SharedBuffer from ImageDecoder.
    (*decoder)->clearCacheExceptFrame(index);
    (*decoder)->setMemoryAllocator(0);

    if (!frame || frame->status() == ImageFrame::FrameEmpty)
        return false;

    // A cache object is considered complete if we can decode a complete frame.
    // Or we have received all data. The image might not be fully decoded in
    // the latter case.
    const bool isDecodeComplete = frame->status() == ImageFrame::FrameComplete || allDataReceived;
    SkBitmap fullSizeBitmap = frame->getSkBitmap();
    if (!fullSizeBitmap.isNull())
    {
        ASSERT(fullSizeBitmap.width() == m_fullSize.width() && fullSizeBitmap.height() == m_fullSize.height());
        setHasAlpha(index, !fullSizeBitmap.isOpaque());
    }
    *bitmap = fullSizeBitmap;
    return isDecodeComplete;
}

bool ImageFrameGenerator::hasAlpha(size_t index)
{
    MutexLocker lock(m_alphaMutex);
    if (index < m_hasAlpha.size())
        return m_hasAlpha[index];
    return true;
}

bool ImageFrameGenerator::getYUVComponentSizes(SkISize componentSizes[3])
{
    ASSERT(componentSizes);

    TRACE_EVENT2("webkit", "ImageFrameGenerator::getYUVComponentSizes", "width", m_fullSize.width(), "height", m_fullSize.height());

    SharedBuffer* data = 0;
    bool allDataReceived = false;
    m_data.data(&data, &allDataReceived);

    // FIXME: YUV decoding does not currently support progressive decoding.
    ASSERT(allDataReceived);

    OwnPtr<ImageDecoder> decoder = ImageDecoder::create(*data, ImageSource::AlphaPremultiplied, ImageSource::GammaAndColorProfileApplied);
    if (!decoder)
        return false;

    // Setting a dummy ImagePlanes object signals to the decoder that we want to do YUV decoding.
    decoder->setData(data, allDataReceived);
    OwnPtr<ImagePlanes> dummyImagePlanes = adoptPtr(new ImagePlanes);
    decoder->setImagePlanes(dummyImagePlanes.release());

    // canDecodeToYUV() has to be called AFTER isSizeAvailable(),
    // otherwise the output color space may not be set in the decoder.
    if (!decoder->isSizeAvailable() || !decoder->canDecodeToYUV())
        return false;

    IntSize size = decoder->decodedYUVSize(0);
    componentSizes[0].set(size.width(), size.height());
    size = decoder->decodedYUVSize(1);
    componentSizes[1].set(size.width(), size.height());
    size = decoder->decodedYUVSize(2);
    componentSizes[2].set(size.width(), size.height());
    return true;
}

} // namespace blink
