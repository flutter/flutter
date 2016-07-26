/*
 * Copyright (C) Research In Motion Limited 2009-2010. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 *
 */

#include "platform/image-decoders/ImageDecoder.h"

#include "platform/image-decoders/bmp/BMPImageDecoder.h"
#include "platform/image-decoders/gif/GIFImageDecoder.h"
#include "platform/image-decoders/ico/ICOImageDecoder.h"
#include "platform/image-decoders/jpeg/JPEGImageDecoder.h"
#include "platform/image-decoders/png/PNGImageDecoder.h"
#include "sky/engine/platform/graphics/DeferredImageDecoder.h"
#include "sky/engine/wtf/PassOwnPtr.h"

namespace blink {

static unsigned copyFromSharedBuffer(char* buffer, unsigned bufferLength, const SharedBuffer& sharedBuffer, unsigned offset)
{
    unsigned bytesExtracted = 0;
    const char* moreData;
    while (unsigned moreDataLength = sharedBuffer.getSomeData(moreData, offset)) {
        unsigned bytesToCopy = std::min(bufferLength - bytesExtracted, moreDataLength);
        memcpy(buffer + bytesExtracted, moreData, bytesToCopy);
        bytesExtracted += bytesToCopy;
        if (bytesExtracted == bufferLength)
            break;
        offset += bytesToCopy;
    }
    return bytesExtracted;
}

inline bool matchesGIFSignature(char* contents)
{
    return !memcmp(contents, "GIF87a", 6) || !memcmp(contents, "GIF89a", 6);
}

inline bool matchesPNGSignature(char* contents)
{
    return !memcmp(contents, "\x89\x50\x4E\x47\x0D\x0A\x1A\x0A", 8);
}

inline bool matchesJPEGSignature(char* contents)
{
    return !memcmp(contents, "\xFF\xD8\xFF", 3);
}

inline bool matchesBMPSignature(char* contents)
{
    return !memcmp(contents, "BM", 2);
}

inline bool matchesICOSignature(char* contents)
{
    return !memcmp(contents, "\x00\x00\x01\x00", 4);
}

inline bool matchesCURSignature(char* contents)
{
    return !memcmp(contents, "\x00\x00\x02\x00", 4);
}

PassOwnPtr<ImageDecoder> ImageDecoder::create(const SharedBuffer& data, ImageSource::AlphaOption alphaOption, ImageSource::GammaAndColorProfileOption gammaAndColorProfileOption)
{
    static const unsigned longestSignatureLength = sizeof("RIFF????WEBPVP") - 1;
    ASSERT(longestSignatureLength == 14);

    size_t maxDecodedBytes = blink::Platform::current()->maxDecodedImageBytes();

    char contents[longestSignatureLength];
    if (copyFromSharedBuffer(contents, longestSignatureLength, data, 0) < longestSignatureLength)
        return nullptr;

    if (matchesJPEGSignature(contents))
        return adoptPtr(new JPEGImageDecoder(alphaOption, gammaAndColorProfileOption, maxDecodedBytes));

    if (matchesPNGSignature(contents))
        return adoptPtr(new PNGImageDecoder(alphaOption, gammaAndColorProfileOption, maxDecodedBytes));

    if (matchesGIFSignature(contents))
        return adoptPtr(new GIFImageDecoder(alphaOption, gammaAndColorProfileOption, maxDecodedBytes));

    if (matchesICOSignature(contents) || matchesCURSignature(contents))
        return adoptPtr(new ICOImageDecoder(alphaOption, gammaAndColorProfileOption, maxDecodedBytes));

    if (matchesBMPSignature(contents))
        return adoptPtr(new BMPImageDecoder(alphaOption, gammaAndColorProfileOption, maxDecodedBytes));

    return nullptr;
}

bool ImageDecoder::frameHasAlphaAtIndex(size_t index) const
{
    return !frameIsCompleteAtIndex(index) || m_frameBufferCache[index].hasAlpha();
}

bool ImageDecoder::frameIsCompleteAtIndex(size_t index) const
{
    return (index < m_frameBufferCache.size()) &&
        (m_frameBufferCache[index].status() == ImageFrame::FrameComplete);
}

unsigned ImageDecoder::frameBytesAtIndex(size_t index) const
{
    if (m_frameBufferCache.size() <= index || m_frameBufferCache[index].status() == ImageFrame::FrameEmpty)
        return 0;
    // FIXME: Use the dimension of the requested frame.
    return m_size.area() * sizeof(ImageFrame::PixelData);
}

bool ImageDecoder::deferredImageDecodingEnabled()
{
    return DeferredImageDecoder::enabled();
}

size_t ImageDecoder::clearCacheExceptFrame(size_t clearExceptFrame)
{
    // Don't clear if there are no frames or only one frame.
    if (m_frameBufferCache.size() <= 1)
        return 0;

    size_t frameBytesCleared = 0;
    for (size_t i = 0; i < m_frameBufferCache.size(); ++i) {
        if (i != clearExceptFrame) {
            frameBytesCleared += frameBytesAtIndex(i);
            clearFrameBuffer(i);
        }
    }
    return frameBytesCleared;
}

void ImageDecoder::clearFrameBuffer(size_t frameIndex)
{
    m_frameBufferCache[frameIndex].clearPixelData();
}

size_t ImageDecoder::findRequiredPreviousFrame(size_t frameIndex, bool frameRectIsOpaque)
{
    ASSERT(frameIndex <= m_frameBufferCache.size());
    if (!frameIndex) {
        // The first frame doesn't rely on any previous data.
        return kNotFound;
    }

    const ImageFrame* currBuffer = &m_frameBufferCache[frameIndex];
    if ((frameRectIsOpaque || currBuffer->alphaBlendSource() == ImageFrame::BlendAtopBgcolor)
        && currBuffer->originalFrameRect().contains(IntRect(IntPoint(), size())))
        return kNotFound;

    // The starting state for this frame depends on the previous frame's
    // disposal method.
    size_t prevFrame = frameIndex - 1;
    const ImageFrame* prevBuffer = &m_frameBufferCache[prevFrame];
    ASSERT(prevBuffer->requiredPreviousFrameIndexValid());

    switch (prevBuffer->disposalMethod()) {
    case ImageFrame::DisposeNotSpecified:
    case ImageFrame::DisposeKeep:
        // prevFrame will be used as the starting state for this frame.
        // FIXME: Be even smarter by checking the frame sizes and/or alpha-containing regions.
        return prevFrame;
    case ImageFrame::DisposeOverwritePrevious:
        // Frames that use the DisposeOverwritePrevious method are effectively
        // no-ops in terms of changing the starting state of a frame compared to
        // the starting state of the previous frame, so skip over them and
        // return the required previous frame of it.
        return prevBuffer->requiredPreviousFrameIndex();
    case ImageFrame::DisposeOverwriteBgcolor:
        // If the previous frame fills the whole image, then the current frame
        // can be decoded alone. Likewise, if the previous frame could be
        // decoded without reference to any prior frame, the starting state for
        // this frame is a blank frame, so it can again be decoded alone.
        // Otherwise, the previous frame contributes to this frame.
        return (prevBuffer->originalFrameRect().contains(IntRect(IntPoint(), size()))
            || (prevBuffer->requiredPreviousFrameIndex() == kNotFound)) ? kNotFound : prevFrame;
    default:
        ASSERT_NOT_REACHED();
        return kNotFound;
    }
}

ImagePlanes::ImagePlanes()
{
    for (int i = 0; i < 3; ++i) {
        m_planes[i] = 0;
        m_rowBytes[i] = 0;
    }
}

ImagePlanes::ImagePlanes(void* planes[3], size_t rowBytes[3])
{
    for (int i = 0; i < 3; ++i) {
        m_planes[i] = planes[i];
        m_rowBytes[i] = rowBytes[i];
    }
}

void* ImagePlanes::plane(int i)
{
    ASSERT((i >= 0) && i < 3);
    return m_planes[i];
}

size_t ImagePlanes::rowBytes(int i) const
{
    ASSERT((i >= 0) && i < 3);
    return m_rowBytes[i];
}

} // namespace blink
