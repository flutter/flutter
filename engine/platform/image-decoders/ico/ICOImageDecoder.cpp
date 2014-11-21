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

#include "sky/engine/config.h"
#include "platform/image-decoders/ico/ICOImageDecoder.h"

#include <algorithm>

#include "platform/image-decoders/png/PNGImageDecoder.h"
#include "sky/engine/wtf/PassOwnPtr.h"

namespace blink {

// Number of bits in .ICO/.CUR used to store the directory and its entries,
// respectively (doesn't match sizeof values for member structs since we omit
// some fields).
static const size_t sizeOfDirectory = 6;
static const size_t sizeOfDirEntry = 16;

ICOImageDecoder::ICOImageDecoder(ImageSource::AlphaOption alphaOption,
    ImageSource::GammaAndColorProfileOption gammaAndColorProfileOption,
    size_t maxDecodedBytes)
    : ImageDecoder(alphaOption, gammaAndColorProfileOption, maxDecodedBytes)
    , m_decodedOffset(0)
{
}

ICOImageDecoder::~ICOImageDecoder()
{
}

void ICOImageDecoder::setData(SharedBuffer* data, bool allDataReceived)
{
    if (failed())
        return;

    ImageDecoder::setData(data, allDataReceived);

    for (BMPReaders::iterator i(m_bmpReaders.begin()); i != m_bmpReaders.end(); ++i) {
        if (*i)
            (*i)->setData(data);
    }
    for (size_t i = 0; i < m_pngDecoders.size(); ++i)
        setDataForPNGDecoderAtIndex(i);
}

bool ICOImageDecoder::isSizeAvailable()
{
    if (!ImageDecoder::isSizeAvailable())
        decode(0, true);

    return ImageDecoder::isSizeAvailable();
}

IntSize ICOImageDecoder::size() const
{
    return m_frameSize.isEmpty() ? ImageDecoder::size() : m_frameSize;
}

IntSize ICOImageDecoder::frameSizeAtIndex(size_t index) const
{
    return (index && (index < m_dirEntries.size())) ? m_dirEntries[index].m_size : size();
}

bool ICOImageDecoder::setSize(unsigned width, unsigned height)
{
    // The size calculated inside the BMPImageReader had better match the one in
    // the icon directory.
    return m_frameSize.isEmpty() ? ImageDecoder::setSize(width, height) : ((IntSize(width, height) == m_frameSize) || setFailed());
}

size_t ICOImageDecoder::frameCount()
{
    decode(0, true);
    if (m_frameBufferCache.isEmpty()) {
        m_frameBufferCache.resize(m_dirEntries.size());
        for (size_t i = 0; i < m_dirEntries.size(); ++i) {
            m_frameBufferCache[i].setPremultiplyAlpha(m_premultiplyAlpha);
            m_frameBufferCache[i].setRequiredPreviousFrameIndex(kNotFound);
        }
    }
    // CAUTION: We must not resize m_frameBufferCache again after this, as
    // decodeAtIndex() may give a BMPImageReader a pointer to one of the
    // entries.
    return m_frameBufferCache.size();
}

ImageFrame* ICOImageDecoder::frameBufferAtIndex(size_t index)
{
    // Ensure |index| is valid.
    if (index >= frameCount())
        return 0;

    ImageFrame* buffer = &m_frameBufferCache[index];
    if (buffer->status() != ImageFrame::FrameComplete) {
        decode(index, false);
    }
    return buffer;
}

bool ICOImageDecoder::setFailed()
{
    m_bmpReaders.clear();
    m_pngDecoders.clear();
    return ImageDecoder::setFailed();
}

bool ICOImageDecoder::hotSpot(IntPoint& hotSpot) const
{
    // When unspecified, the default frame is always frame 0. This is consistent with
    // BitmapImage where currentFrame() starts at 0 and only increases when animation is
    // requested.
    return hotSpotAtIndex(0, hotSpot);
}

bool ICOImageDecoder::hotSpotAtIndex(size_t index, IntPoint& hotSpot) const
{
    if (index >= m_dirEntries.size() || m_fileType != CURSOR)
        return false;

    hotSpot = m_dirEntries[index].m_hotSpot;
    return true;
}


// static
bool ICOImageDecoder::compareEntries(const IconDirectoryEntry& a, const IconDirectoryEntry& b)
{
    // Larger icons are better.  After that, higher bit-depth icons are better.
    const int aEntryArea = a.m_size.width() * a.m_size.height();
    const int bEntryArea = b.m_size.width() * b.m_size.height();
    return (aEntryArea == bEntryArea) ? (a.m_bitCount > b.m_bitCount) : (aEntryArea > bEntryArea);
}

void ICOImageDecoder::setDataForPNGDecoderAtIndex(size_t index)
{
    if (!m_pngDecoders[index])
        return;

    const IconDirectoryEntry& dirEntry = m_dirEntries[index];
    // Copy out PNG data to a separate vector and send to the PNG decoder.
    // FIXME: Save this copy by making the PNG decoder able to take an
    // optional offset.
    RefPtr<SharedBuffer> pngData(SharedBuffer::create(&m_data->data()[dirEntry.m_imageOffset], m_data->size() - dirEntry.m_imageOffset));
    m_pngDecoders[index]->setData(pngData.get(), isAllDataReceived());
}

void ICOImageDecoder::decode(size_t index, bool onlySize)
{
    if (failed())
        return;

    // If we couldn't decode the image but we've received all the data, decoding
    // has failed.
    if ((!decodeDirectory() || (!onlySize && !decodeAtIndex(index))) && isAllDataReceived())
        setFailed();
    // If we're done decoding this frame, we don't need the BMPImageReader or
    // PNGImageDecoder anymore.  (If we failed, these have already been
    // cleared.)
    else if ((m_frameBufferCache.size() > index) && (m_frameBufferCache[index].status() == ImageFrame::FrameComplete)) {
        m_bmpReaders[index].clear();
        m_pngDecoders[index].clear();
    }
}

bool ICOImageDecoder::decodeDirectory()
{
    // Read and process directory.
    if ((m_decodedOffset < sizeOfDirectory) && !processDirectory())
        return false;

    // Read and process directory entries.
    return (m_decodedOffset >= (sizeOfDirectory + (m_dirEntries.size() * sizeOfDirEntry))) || processDirectoryEntries();
}

bool ICOImageDecoder::decodeAtIndex(size_t index)
{
    ASSERT_WITH_SECURITY_IMPLICATION(index < m_dirEntries.size());
    const IconDirectoryEntry& dirEntry = m_dirEntries[index];
    const ImageType imageType = imageTypeAtIndex(index);
    if (imageType == Unknown)
        return false; // Not enough data to determine image type yet.

    if (imageType == BMP) {
        if (!m_bmpReaders[index]) {
            // We need to have already sized m_frameBufferCache before this, and
            // we must not resize it again later (see caution in frameCount()).
            ASSERT(m_frameBufferCache.size() == m_dirEntries.size());
            m_bmpReaders[index] = adoptPtr(new BMPImageReader(this, dirEntry.m_imageOffset, 0, true));
            m_bmpReaders[index]->setData(m_data.get());
            m_bmpReaders[index]->setBuffer(&m_frameBufferCache[index]);
        }
        m_frameSize = dirEntry.m_size;
        bool result = m_bmpReaders[index]->decodeBMP(false);
        m_frameSize = IntSize();
        return result;
    }

    if (!m_pngDecoders[index]) {
        m_pngDecoders[index] = adoptPtr(
            new PNGImageDecoder(m_premultiplyAlpha ? ImageSource::AlphaPremultiplied : ImageSource::AlphaNotPremultiplied,
                m_ignoreGammaAndColorProfile ? ImageSource::GammaAndColorProfileIgnored : ImageSource::GammaAndColorProfileApplied, m_maxDecodedBytes));
        setDataForPNGDecoderAtIndex(index);
    }
    // Fail if the size the PNGImageDecoder calculated does not match the size
    // in the directory.
    if (m_pngDecoders[index]->isSizeAvailable() && (m_pngDecoders[index]->size() != dirEntry.m_size))
        return setFailed();
    m_frameBufferCache[index] = *m_pngDecoders[index]->frameBufferAtIndex(0);
    m_frameBufferCache[index].setPremultiplyAlpha(m_premultiplyAlpha);
    m_frameBufferCache[index].setRequiredPreviousFrameIndex(kNotFound);
    return !m_pngDecoders[index]->failed() || setFailed();
}

bool ICOImageDecoder::processDirectory()
{
    // Read directory.
    ASSERT(!m_decodedOffset);
    if (m_data->size() < sizeOfDirectory)
        return false;
    const uint16_t fileType = readUint16(2);
    const uint16_t idCount = readUint16(4);
    m_decodedOffset = sizeOfDirectory;

    // See if this is an icon filetype we understand, and make sure we have at
    // least one entry in the directory.
    if (((fileType != ICON) && (fileType != CURSOR)) || (!idCount))
        return setFailed();

    m_fileType = static_cast<FileType>(fileType);

    // Enlarge member vectors to hold all the entries.
    m_dirEntries.resize(idCount);
    m_bmpReaders.resize(idCount);
    m_pngDecoders.resize(idCount);
    return true;
}

bool ICOImageDecoder::processDirectoryEntries()
{
    // Read directory entries.
    ASSERT(m_decodedOffset == sizeOfDirectory);
    if ((m_decodedOffset > m_data->size()) || ((m_data->size() - m_decodedOffset) < (m_dirEntries.size() * sizeOfDirEntry)))
        return false;
    for (IconDirectoryEntries::iterator i(m_dirEntries.begin()); i != m_dirEntries.end(); ++i)
        *i = readDirectoryEntry();  // Updates m_decodedOffset.

    // Make sure the specified image offsets are past the end of the directory
    // entries.
    for (IconDirectoryEntries::iterator i(m_dirEntries.begin()); i != m_dirEntries.end(); ++i) {
        if (i->m_imageOffset < m_decodedOffset)
            return setFailed();
    }

    // Arrange frames in decreasing quality order.
    std::sort(m_dirEntries.begin(), m_dirEntries.end(), compareEntries);

    // The image size is the size of the largest entry.
    const IconDirectoryEntry& dirEntry = m_dirEntries.first();
    // Technically, this next call shouldn't be able to fail, since the width
    // and height here are each <= 256, and |m_frameSize| is empty.
    return setSize(dirEntry.m_size.width(), dirEntry.m_size.height());
}

ICOImageDecoder::IconDirectoryEntry ICOImageDecoder::readDirectoryEntry()
{
    // Read icon data.
    // The casts to uint8_t in the next few lines are because that's the on-disk
    // type of the width and height values.  Storing them in ints (instead of
    // matching uint8_ts) is so we can record dimensions of size 256 (which is
    // what a zero byte really means).
    int width = static_cast<uint8_t>(m_data->data()[m_decodedOffset]);
    if (!width)
        width = 256;
    int height = static_cast<uint8_t>(m_data->data()[m_decodedOffset + 1]);
    if (!height)
        height = 256;
    IconDirectoryEntry entry;
    entry.m_size = IntSize(width, height);
    if (m_fileType == CURSOR) {
        entry.m_bitCount = 0;
        entry.m_hotSpot = IntPoint(readUint16(4), readUint16(6));
    } else {
        entry.m_bitCount = readUint16(6);
        entry.m_hotSpot = IntPoint();
    }
    entry.m_imageOffset = readUint32(12);

    // Some icons don't have a bit depth, only a color count.  Convert the
    // color count to the minimum necessary bit depth.  It doesn't matter if
    // this isn't quite what the bitmap info header says later, as we only use
    // this value to determine which icon entry is best.
    if (!entry.m_bitCount) {
        int colorCount = static_cast<uint8_t>(m_data->data()[m_decodedOffset + 2]);
        if (!colorCount)
            colorCount = 256;  // Vague in the spec, needed by real-world icons.
        for (--colorCount; colorCount; colorCount >>= 1)
            ++entry.m_bitCount;
    }

    m_decodedOffset += sizeOfDirEntry;
    return entry;
}

ICOImageDecoder::ImageType ICOImageDecoder::imageTypeAtIndex(size_t index)
{
    // Check if this entry is a BMP or a PNG; we need 4 bytes to check the magic
    // number.
    ASSERT_WITH_SECURITY_IMPLICATION(index < m_dirEntries.size());
    const uint32_t imageOffset = m_dirEntries[index].m_imageOffset;
    if ((imageOffset > m_data->size()) || ((m_data->size() - imageOffset) < 4))
        return Unknown;
    return strncmp(&m_data->data()[imageOffset], "\x89PNG", 4) ? BMP : PNG;
}

}
