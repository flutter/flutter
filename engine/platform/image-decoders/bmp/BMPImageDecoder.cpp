/*
 * Copyright (c) 2008, 2009, Google Inc. All rights reserved.
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

#include "platform/image-decoders/bmp/BMPImageDecoder.h"

#include "sky/engine/wtf/PassOwnPtr.h"

namespace blink {

// Number of bits in .BMP used to store the file header (doesn't match
// "sizeof(BMPImageDecoder::BitmapFileHeader)" since we omit some fields and
// don't pack).
static const size_t sizeOfFileHeader = 14;

BMPImageDecoder::BMPImageDecoder(ImageSource::AlphaOption alphaOption,
    ImageSource::GammaAndColorProfileOption gammaAndColorProfileOption,
    size_t maxDecodedBytes)
    : ImageDecoder(alphaOption, gammaAndColorProfileOption, maxDecodedBytes)
    , m_decodedOffset(0)
{
}

void BMPImageDecoder::setData(SharedBuffer* data, bool allDataReceived)
{
    if (failed())
        return;

    ImageDecoder::setData(data, allDataReceived);
    if (m_reader)
        m_reader->setData(data);
}

bool BMPImageDecoder::isSizeAvailable()
{
    if (!ImageDecoder::isSizeAvailable())
        decode(true);

    return ImageDecoder::isSizeAvailable();
}

ImageFrame* BMPImageDecoder::frameBufferAtIndex(size_t index)
{
    if (index)
        return 0;

    if (m_frameBufferCache.isEmpty()) {
        m_frameBufferCache.resize(1);
        m_frameBufferCache.first().setPremultiplyAlpha(m_premultiplyAlpha);
    }

    ImageFrame* buffer = &m_frameBufferCache.first();
    if (buffer->status() != ImageFrame::FrameComplete) {
        decode(false);
    }
    return buffer;
}

bool BMPImageDecoder::setFailed()
{
    m_reader.clear();
    return ImageDecoder::setFailed();
}

void BMPImageDecoder::decode(bool onlySize)
{
    if (failed())
        return;

    // If we couldn't decode the image but we've received all the data, decoding
    // has failed.
    if (!decodeHelper(onlySize) && isAllDataReceived())
        setFailed();
    // If we're done decoding the image, we don't need the BMPImageReader
    // anymore.  (If we failed, |m_reader| has already been cleared.)
    else if (!m_frameBufferCache.isEmpty() && (m_frameBufferCache.first().status() == ImageFrame::FrameComplete))
        m_reader.clear();
}

bool BMPImageDecoder::decodeHelper(bool onlySize)
{
    size_t imgDataOffset = 0;
    if ((m_decodedOffset < sizeOfFileHeader) && !processFileHeader(&imgDataOffset))
        return false;

    if (!m_reader) {
        m_reader = adoptPtr(new BMPImageReader(this, m_decodedOffset, imgDataOffset, false));
        m_reader->setData(m_data.get());
    }

    if (!m_frameBufferCache.isEmpty())
        m_reader->setBuffer(&m_frameBufferCache.first());

    return m_reader->decodeBMP(onlySize);
}

bool BMPImageDecoder::processFileHeader(size_t* imgDataOffset)
{
    ASSERT(imgDataOffset);

    // Read file header.
    ASSERT(!m_decodedOffset);
    if (m_data->size() < sizeOfFileHeader)
        return false;
    const uint16_t fileType = (m_data->data()[0] << 8) | static_cast<uint8_t>(m_data->data()[1]);
    *imgDataOffset = readUint32(10);
    m_decodedOffset = sizeOfFileHeader;

    // See if this is a bitmap filetype we understand.
    enum {
        BMAP = 0x424D,  // "BM"
        // The following additional OS/2 2.x header values (see
        // http://www.fileformat.info/format/os2bmp/egff.htm ) aren't widely
        // decoded, and are unlikely to be in much use.
        /*
        ICON = 0x4943,  // "IC"
        POINTER = 0x5054,  // "PT"
        COLORICON = 0x4349,  // "CI"
        COLORPOINTER = 0x4350,  // "CP"
        BITMAPARRAY = 0x4241,  // "BA"
        */
    };
    return (fileType == BMAP) || setFailed();
}

} // namespace blink
