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

#include "config.h"
#include "platform/image-decoders/bmp/BMPImageReader.h"

namespace {

// See comments on m_lookupTableAddresses in the header.
const uint8_t nBitTo8BitlookupTable[] = {
    // 1 bit
    0, 255,
    // 2 bits
    0, 85, 170, 255,
    // 3 bits
    0, 36, 73, 109, 146, 182, 219, 255,
    // 4 bits
    0, 17, 34, 51, 68, 85, 102, 119, 136, 153, 170, 187, 204, 221, 238, 255,
    // 5 bits
    0, 8, 16, 25, 33, 41, 49, 58, 66, 74, 82, 90, 99, 107, 115, 123,
    132, 140, 148, 156, 165, 173, 181, 189, 197, 206, 214, 222, 230, 239, 247, 255,
    // 6 bits
    0, 4, 8, 12, 16, 20, 24, 28, 32, 36, 40, 45, 49, 53, 57, 61,
    65, 69, 73, 77, 81, 85, 89, 93, 97, 101, 105, 109, 113, 117, 121, 125,
    130, 134, 138, 142, 146, 150, 154, 158, 162, 166, 170, 174, 178, 182, 186, 190,
    194, 198, 202, 206, 210, 215, 219, 223, 227, 231, 235, 239, 243, 247, 251, 255,
    // 7 bits
    0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30,
    32, 34, 36, 38, 40, 42, 44, 46, 48, 50, 52, 54, 56, 58, 60, 62,
    64, 66, 68, 70, 72, 74, 76, 78, 80, 82, 84, 86, 88, 90, 92, 94,
    96, 98, 100, 102, 104, 106, 108, 110, 112, 114, 116, 118, 120, 122, 124, 126,
    129, 131, 133, 135, 137, 139, 141, 143, 145, 147, 149, 151, 153, 155, 157, 159,
    161, 163, 165, 167, 169, 171, 173, 175, 177, 179, 181, 183, 185, 187, 189, 191,
    193, 195, 197, 199, 201, 203, 205, 207, 209, 211, 213, 215, 217, 219, 221, 223,
    225, 227, 229, 231, 233, 235, 237, 239, 241, 243, 245, 247, 249, 251, 253, 255,
};

}

namespace blink {

BMPImageReader::BMPImageReader(ImageDecoder* parent, size_t decodedAndHeaderOffset, size_t imgDataOffset, bool isInICO)
    : m_parent(parent)
    , m_buffer(0)
    , m_decodedOffset(decodedAndHeaderOffset)
    , m_headerOffset(decodedAndHeaderOffset)
    , m_imgDataOffset(imgDataOffset)
    , m_isOS21x(false)
    , m_isOS22x(false)
    , m_isTopDown(false)
    , m_needToProcessBitmasks(false)
    , m_needToProcessColorTable(false)
    , m_seenNonZeroAlphaPixel(false)
    , m_seenZeroAlphaPixel(false)
    , m_isInICO(isInICO)
    , m_decodingAndMask(false)
{
    // Clue-in decodeBMP() that we need to detect the correct info header size.
    memset(&m_infoHeader, 0, sizeof(m_infoHeader));
}

bool BMPImageReader::decodeBMP(bool onlySize)
{
    // Calculate size of info header.
    if (!m_infoHeader.biSize && !readInfoHeaderSize())
        return false;

    // Read and process info header.
    if ((m_decodedOffset < (m_headerOffset + m_infoHeader.biSize)) && !processInfoHeader())
        return false;

    // processInfoHeader() set the size, so if that's all we needed, we're done.
    if (onlySize)
        return true;

    // Read and process the bitmasks, if needed.
    if (m_needToProcessBitmasks && !processBitmasks())
        return false;

    // Read and process the color table, if needed.
    if (m_needToProcessColorTable && !processColorTable())
        return false;

    // Initialize the framebuffer if needed.
    ASSERT(m_buffer);  // Parent should set this before asking us to decode!
    if (m_buffer->status() == ImageFrame::FrameEmpty) {
        if (!m_buffer->setSize(m_parent->size().width(), m_parent->size().height()))
            return m_parent->setFailed(); // Unable to allocate.
        m_buffer->setStatus(ImageFrame::FramePartial);
        // setSize() calls eraseARGB(), which resets the alpha flag, so we force
        // it back to false here.  We'll set it true below in all cases where
        // these 0s could actually show through.
        m_buffer->setHasAlpha(false);

        // For BMPs, the frame always fills the entire image.
        m_buffer->setOriginalFrameRect(IntRect(IntPoint(), m_parent->size()));

        if (!m_isTopDown)
            m_coord.setY(m_parent->size().height() - 1);
    }

    // Decode the data.
    if (!m_decodingAndMask && !pastEndOfImage(0)) {
        if ((m_infoHeader.biCompression != RLE4) && (m_infoHeader.biCompression != RLE8) && (m_infoHeader.biCompression != RLE24)) {
            const ProcessingResult result = processNonRLEData(false, 0);
            if (result != Success)
                return (result == Failure) ? m_parent->setFailed() : false;
        } else if (!processRLEData())
            return false;
    }

    // If the image has an AND mask and there was no alpha data, process the
    // mask.
    if (m_isInICO && !m_decodingAndMask && !m_buffer->hasAlpha()) {
        // Reset decoding coordinates to start of image.
        m_coord.setX(0);
        m_coord.setY(m_isTopDown ? 0 : (m_parent->size().height() - 1));

        // The AND mask is stored as 1-bit data.
        m_infoHeader.biBitCount = 1;

        m_decodingAndMask = true;
    }
    if (m_decodingAndMask) {
        const ProcessingResult result = processNonRLEData(false, 0);
        if (result != Success)
            return (result == Failure) ? m_parent->setFailed() : false;
    }

    // Done!
    m_buffer->setStatus(ImageFrame::FrameComplete);
    return true;
}

bool BMPImageReader::readInfoHeaderSize()
{
    // Get size of info header.
    ASSERT(m_decodedOffset == m_headerOffset);
    if ((m_decodedOffset > m_data->size()) || ((m_data->size() - m_decodedOffset) < 4))
        return false;
    m_infoHeader.biSize = readUint32(0);
    // Don't increment m_decodedOffset here, it just makes the code in
    // processInfoHeader() more confusing.

    // Don't allow the header to overflow (which would be harmless here, but
    // problematic or at least confusing in other places), or to overrun the
    // image data.
    if (((m_headerOffset + m_infoHeader.biSize) < m_headerOffset) || (m_imgDataOffset && (m_imgDataOffset < (m_headerOffset + m_infoHeader.biSize))))
        return m_parent->setFailed();

    // See if this is a header size we understand:
    // OS/2 1.x: 12
    if (m_infoHeader.biSize == 12)
        m_isOS21x = true;
    // Windows V3: 40
    else if ((m_infoHeader.biSize == 40) || isWindowsV4Plus())
        ;
    // OS/2 2.x: any multiple of 4 between 16 and 64, inclusive, or 42 or 46
    else if ((m_infoHeader.biSize >= 16) && (m_infoHeader.biSize <= 64) && (!(m_infoHeader.biSize & 3) || (m_infoHeader.biSize == 42) || (m_infoHeader.biSize == 46)))
        m_isOS22x = true;
    else
        return m_parent->setFailed();

    return true;
}

bool BMPImageReader::processInfoHeader()
{
    // Read info header.
    ASSERT(m_decodedOffset == m_headerOffset);
    if ((m_decodedOffset > m_data->size()) || ((m_data->size() - m_decodedOffset) < m_infoHeader.biSize) || !readInfoHeader())
        return false;
    m_decodedOffset += m_infoHeader.biSize;

    // Sanity-check header values.
    if (!isInfoHeaderValid())
        return m_parent->setFailed();

    // Set our size.
    if (!m_parent->setSize(m_infoHeader.biWidth, m_infoHeader.biHeight))
        return false;

    // For paletted images, bitmaps can set biClrUsed to 0 to mean "all
    // colors", so set it to the maximum number of colors for this bit depth.
    // Also do this for bitmaps that put too large a value here.
    if (m_infoHeader.biBitCount < 16) {
      const uint32_t maxColors = static_cast<uint32_t>(1) << m_infoHeader.biBitCount;
      if (!m_infoHeader.biClrUsed || (m_infoHeader.biClrUsed > maxColors))
          m_infoHeader.biClrUsed = maxColors;
    }

    // For any bitmaps that set their BitCount to the wrong value, reset the
    // counts now that we've calculated the number of necessary colors, since
    // other code relies on this value being correct.
    if (m_infoHeader.biCompression == RLE8)
        m_infoHeader.biBitCount = 8;
    else if (m_infoHeader.biCompression == RLE4)
        m_infoHeader.biBitCount = 4;

    // Tell caller what still needs to be processed.
    if (m_infoHeader.biBitCount >= 16)
        m_needToProcessBitmasks = true;
    else if (m_infoHeader.biBitCount)
        m_needToProcessColorTable = true;

    return true;
}

bool BMPImageReader::readInfoHeader()
{
    // Pre-initialize some fields that not all headers set.
    m_infoHeader.biCompression = RGB;
    m_infoHeader.biClrUsed = 0;

    if (m_isOS21x) {
        m_infoHeader.biWidth = readUint16(4);
        m_infoHeader.biHeight = readUint16(6);
        ASSERT(!m_isInICO); // ICO is a Windows format, not OS/2!
        m_infoHeader.biBitCount = readUint16(10);
        return true;
    }

    m_infoHeader.biWidth = readUint32(4);
    m_infoHeader.biHeight = readUint32(8);
    if (m_isInICO)
        m_infoHeader.biHeight /= 2;
    m_infoHeader.biBitCount = readUint16(14);

    // Read compression type, if present.
    if (m_infoHeader.biSize >= 20) {
        uint32_t biCompression = readUint32(16);

        // Detect OS/2 2.x-specific compression types.
        if ((biCompression == 3) && (m_infoHeader.biBitCount == 1)) {
            m_infoHeader.biCompression = HUFFMAN1D;
            m_isOS22x = true;
        } else if ((biCompression == 4) && (m_infoHeader.biBitCount == 24)) {
            m_infoHeader.biCompression = RLE24;
            m_isOS22x = true;
        } else if (biCompression > 5)
            return m_parent->setFailed(); // Some type we don't understand.
        else
            m_infoHeader.biCompression = static_cast<CompressionType>(biCompression);
    }

    // Read colors used, if present.
    if (m_infoHeader.biSize >= 36)
        m_infoHeader.biClrUsed = readUint32(32);

    // Windows V4+ can safely read the four bitmasks from 40-56 bytes in, so do
    // that here. If the bit depth is less than 16, these values will be ignored
    // by the image data decoders. If the bit depth is at least 16 but the
    // compression format isn't BITFIELDS, the RGB bitmasks will be ignored and
    // overwritten in processBitmasks(). (The alpha bitmask will never be
    // overwritten: images that actually want alpha have to specify a valid
    // alpha mask. See comments in processBitmasks().)
    //
    // For non-Windows V4+, m_bitMasks[] et. al will be initialized later
    // during processBitmasks().
    if (isWindowsV4Plus()) {
        m_bitMasks[0] = readUint32(40);
        m_bitMasks[1] = readUint32(44);
        m_bitMasks[2] = readUint32(48);
        m_bitMasks[3] = readUint32(52);
    }

    // Detect top-down BMPs.
    if (m_infoHeader.biHeight < 0) {
        m_isTopDown = true;
        m_infoHeader.biHeight = -m_infoHeader.biHeight;
    }

    return true;
}

bool BMPImageReader::isInfoHeaderValid() const
{
    // Non-positive widths/heights are invalid.  (We've already flipped the
    // sign of the height for top-down bitmaps.)
    if ((m_infoHeader.biWidth <= 0) || !m_infoHeader.biHeight)
        return false;

    // Only Windows V3+ has top-down bitmaps.
    if (m_isTopDown && (m_isOS21x || m_isOS22x))
        return false;

    // Only bit depths of 1, 4, 8, or 24 are universally supported.
    if ((m_infoHeader.biBitCount != 1) && (m_infoHeader.biBitCount != 4) && (m_infoHeader.biBitCount != 8) && (m_infoHeader.biBitCount != 24)) {
        // Windows V3+ additionally supports bit depths of 0 (for embedded
        // JPEG/PNG images), 16, and 32.
        if (m_isOS21x || m_isOS22x || (m_infoHeader.biBitCount && (m_infoHeader.biBitCount != 16) && (m_infoHeader.biBitCount != 32)))
            return false;
    }

    // Each compression type is only valid with certain bit depths (except RGB,
    // which can be used with any bit depth). Also, some formats do not support
    // some compression types.
    switch (m_infoHeader.biCompression) {
    case RGB:
        if (!m_infoHeader.biBitCount)
            return false;
        break;

    case RLE8:
        // Supposedly there are undocumented formats like "BitCount = 1,
        // Compression = RLE4" (which means "4 bit, but with a 2-color table"),
        // so also allow the paletted RLE compression types to have too low a
        // bit count; we'll correct this later.
        if (!m_infoHeader.biBitCount || (m_infoHeader.biBitCount > 8))
            return false;
        break;

    case RLE4:
        // See comments in RLE8.
        if (!m_infoHeader.biBitCount || (m_infoHeader.biBitCount > 4))
            return false;
        break;

    case BITFIELDS:
        // Only valid for Windows V3+.
        if (m_isOS21x || m_isOS22x || ((m_infoHeader.biBitCount != 16) && (m_infoHeader.biBitCount != 32)))
            return false;
        break;

    case JPEG:
    case PNG:
        // Only valid for Windows V3+.
        if (m_isOS21x || m_isOS22x || m_infoHeader.biBitCount)
            return false;
        break;

    case HUFFMAN1D:
        // Only valid for OS/2 2.x.
        if (!m_isOS22x || (m_infoHeader.biBitCount != 1))
            return false;
        break;

    case RLE24:
        // Only valid for OS/2 2.x.
        if (!m_isOS22x || (m_infoHeader.biBitCount != 24))
            return false;
        break;

    default:
        // Some type we don't understand.  This should have been caught in
        // readInfoHeader().
        ASSERT_NOT_REACHED();
        return false;
    }

    // Top-down bitmaps cannot be compressed; they must be RGB or BITFIELDS.
    if (m_isTopDown && (m_infoHeader.biCompression != RGB) && (m_infoHeader.biCompression != BITFIELDS))
        return false;

    // Reject the following valid bitmap types that we don't currently bother
    // decoding.  Few other people decode these either, they're unlikely to be
    // in much use.
    // TODO(pkasting): Consider supporting these someday.
    //   * Bitmaps larger than 2^16 pixels in either dimension (Windows
    //     probably doesn't draw these well anyway, and the decoded data would
    //     take a lot of memory).
    if ((m_infoHeader.biWidth >= (1 << 16)) || (m_infoHeader.biHeight >= (1 << 16)))
        return false;
    //   * Windows V3+ JPEG-in-BMP and PNG-in-BMP bitmaps (supposedly not found
    //     in the wild, only used to send data to printers?).
    if ((m_infoHeader.biCompression == JPEG) || (m_infoHeader.biCompression == PNG))
        return false;
    //   * OS/2 2.x Huffman-encoded monochrome bitmaps (see
    //      http://www.fileformat.info/mirror/egff/ch09_05.htm , re: "G31D"
    //      algorithm).
    if (m_infoHeader.biCompression == HUFFMAN1D)
        return false;

    return true;
}

bool BMPImageReader::processBitmasks()
{
    // Create m_bitMasks[] values for R/G/B.
    if (m_infoHeader.biCompression != BITFIELDS) {
        // The format doesn't actually use bitmasks.  To simplify the decode
        // logic later, create bitmasks for the RGB data.  For Windows V4+,
        // this overwrites the masks we read from the header, which are
        // supposed to be ignored in non-BITFIELDS cases.
        // 16 bits:    MSB <-                     xRRRRRGG GGGBBBBB -> LSB
        // 24/32 bits: MSB <- [AAAAAAAA] RRRRRRRR GGGGGGGG BBBBBBBB -> LSB
        const int numBits = (m_infoHeader.biBitCount == 16) ? 5 : 8;
        for (int i = 0; i <= 2; ++i)
            m_bitMasks[i] = ((static_cast<uint32_t>(1) << (numBits * (3 - i))) - 1) ^ ((static_cast<uint32_t>(1) << (numBits * (2 - i))) - 1);
    } else if (!isWindowsV4Plus()) {
        // For Windows V4+ BITFIELDS mode bitmaps, this was already done when
        // we read the info header.

        // Fail if we don't have enough file space for the bitmasks.
        static const size_t SIZEOF_BITMASKS = 12;
        if (((m_headerOffset + m_infoHeader.biSize + SIZEOF_BITMASKS) < (m_headerOffset + m_infoHeader.biSize)) || (m_imgDataOffset && (m_imgDataOffset < (m_headerOffset + m_infoHeader.biSize + SIZEOF_BITMASKS))))
            return m_parent->setFailed();

        // Read bitmasks.
        if ((m_data->size() - m_decodedOffset) < SIZEOF_BITMASKS)
            return false;
        m_bitMasks[0] = readUint32(0);
        m_bitMasks[1] = readUint32(4);
        m_bitMasks[2] = readUint32(8);

        m_decodedOffset += SIZEOF_BITMASKS;
    }

    // Alpha is a poorly-documented and inconsistently-used feature.
    //
    // Windows V4+ has an alpha bitmask in the info header. Unlike the R/G/B
    // bitmasks, the MSDN docs don't indicate that it is only valid for the
    // BITFIELDS compression format, so we respect it at all times.
    //
    // To complicate things, Windows V3 BMPs, which lack this mask, can specify
    // 32bpp format, which to any sane reader would imply an 8-bit alpha
    // channel -- and for BMPs-in-ICOs, that's precisely what's intended to
    // happen. There also exist standalone BMPs in this format which clearly
    // expect the alpha channel to be respected. However, there are many other
    // BMPs which, for example, fill this channel with all 0s, yet clearly
    // expect to not be displayed as a fully-transparent rectangle.
    //
    // If these were the only two types of Windows V3, 32bpp BMPs in the wild,
    // we could distinguish between them by scanning the alpha channel in the
    // image, looking for nonzero values, and only enabling alpha if we found
    // some. (It turns out we have to do this anyway, because, crazily, there
    // are also Windows V4+ BMPs with an explicit, non-zero alpha mask, which
    // then zero-fill their alpha channels! See comments in
    // processNonRLEData().)
    //
    // Unfortunately there are also V3 BMPs -- indeed, probably more than the
    // number of 32bpp, V3 BMPs which intentionally use alpha -- which specify
    // 32bpp format, use nonzero (and non-255) alpha values, and yet expect to
    // be rendered fully-opaque. And other browsers do so.
    //
    // So it's impossible to display every BMP in the way its creators intended,
    // and we have to choose what to break. Given the paragraph above, we match
    // other browsers and ignore alpha in Windows V3 BMPs except inside ICO
    // files.
    if (!isWindowsV4Plus())
        m_bitMasks[3] = (m_isInICO && (m_infoHeader.biCompression != BITFIELDS) && (m_infoHeader.biBitCount == 32)) ? static_cast<uint32_t>(0xff000000) : 0;

    // We've now decoded all the non-image data we care about.  Skip anything
    // else before the actual raster data.
    if (m_imgDataOffset)
        m_decodedOffset = m_imgDataOffset;
    m_needToProcessBitmasks = false;

    // Check masks and set shift and LUT address values.
    for (int i = 0; i < 4; ++i) {
        // Trim the mask to the allowed bit depth.  Some Windows V4+ BMPs
        // specify a bogus alpha channel in bits that don't exist in the pixel
        // data (for example, bits 25-31 in a 24-bit RGB format).
        if (m_infoHeader.biBitCount < 32)
            m_bitMasks[i] &= ((static_cast<uint32_t>(1) << m_infoHeader.biBitCount) - 1);

        // For empty masks (common on the alpha channel, especially after the
        // trimming above), quickly clear the shift and LUT address and
        // continue, to avoid an infinite loop in the counting code below.
        uint32_t tempMask = m_bitMasks[i];
        if (!tempMask) {
            m_bitShiftsRight[i] = 0;
            m_lookupTableAddresses[i] = 0;
            continue;
        }

        // Make sure bitmask does not overlap any other bitmasks.
        for (int j = 0; j < i; ++j) {
            if (tempMask & m_bitMasks[j])
                return m_parent->setFailed();
        }

        // Count offset into pixel data.
        for (m_bitShiftsRight[i] = 0; !(tempMask & 1); tempMask >>= 1)
            ++m_bitShiftsRight[i];

        // Count size of mask.
        size_t numBits = 0;
        for (; tempMask & 1; tempMask >>= 1)
            ++numBits;

        // Make sure bitmask is contiguous.
        if (tempMask)
            return m_parent->setFailed();

        // Since RGBABuffer tops out at 8 bits per channel, adjust the shift
        // amounts to use the most significant 8 bits of the channel.
        if (numBits >= 8) {
            m_bitShiftsRight[i] += (numBits - 8);
            numBits = 0;
        }

        // Calculate LUT address.
        m_lookupTableAddresses[i] = numBits ? (nBitTo8BitlookupTable + (1 << numBits) - 2) : 0;
    }

    return true;
}

bool BMPImageReader::processColorTable()
{
    size_t tableSizeInBytes = m_infoHeader.biClrUsed * (m_isOS21x ? 3 : 4);

    // Fail if we don't have enough file space for the color table.
    if (((m_headerOffset + m_infoHeader.biSize + tableSizeInBytes) < (m_headerOffset + m_infoHeader.biSize)) || (m_imgDataOffset && (m_imgDataOffset < (m_headerOffset + m_infoHeader.biSize + tableSizeInBytes))))
        return m_parent->setFailed();

    // Read color table.
    if ((m_decodedOffset > m_data->size()) || ((m_data->size() - m_decodedOffset) < tableSizeInBytes))
        return false;
    m_colorTable.resize(m_infoHeader.biClrUsed);
    for (size_t i = 0; i < m_infoHeader.biClrUsed; ++i) {
        m_colorTable[i].rgbBlue = m_data->data()[m_decodedOffset++];
        m_colorTable[i].rgbGreen = m_data->data()[m_decodedOffset++];
        m_colorTable[i].rgbRed = m_data->data()[m_decodedOffset++];
        // Skip padding byte (not present on OS/2 1.x).
        if (!m_isOS21x)
            ++m_decodedOffset;
    }

    // We've now decoded all the non-image data we care about.  Skip anything
    // else before the actual raster data.
    if (m_imgDataOffset)
        m_decodedOffset = m_imgDataOffset;
    m_needToProcessColorTable = false;

    return true;
}

bool BMPImageReader::processRLEData()
{
    if (m_decodedOffset > m_data->size())
        return false;

    // RLE decoding is poorly specified.  Two main problems:
    // (1) Are EOL markers necessary?  What happens when we have too many
    //     pixels for one row?
    //     http://www.fileformat.info/format/bmp/egff.htm says extra pixels
    //     should wrap to the next line.  Real BMPs I've encountered seem to
    //     instead expect extra pixels to be ignored until the EOL marker is
    //     seen, although this has only happened in a few cases and I suspect
    //     those BMPs may be invalid.  So we only change lines on EOL (or Delta
    //     with dy > 0), and fail in most cases when pixels extend past the end
    //     of the line.
    // (2) When Delta, EOL, or EOF are seen, what happens to the "skipped"
    //     pixels?
    //     http://www.daubnet.com/formats/BMP.html says these should be filled
    //     with color 0.  However, the "do nothing" and "don't care" comments
    //     of other references suggest leaving these alone, i.e. letting them
    //     be transparent to the background behind the image.  This seems to
    //     match how MSPAINT treats BMPs, so we do that.  Note that when we
    //     actually skip pixels for a case like this, we need to note on the
    //     framebuffer that we have alpha.

    // Impossible to decode row-at-a-time, so just do things as a stream of
    // bytes.
    while (true) {
        // Every entry takes at least two bytes; bail if there isn't enough
        // data.
        if ((m_data->size() - m_decodedOffset) < 2)
            return false;

        // For every entry except EOF, we'd better not have reached the end of
        // the image.
        const uint8_t count = m_data->data()[m_decodedOffset];
        const uint8_t code = m_data->data()[m_decodedOffset + 1];
        if ((count || (code != 1)) && pastEndOfImage(0))
            return m_parent->setFailed();

        // Decode.
        if (!count) {
            switch (code) {
            case 0:  // Magic token: EOL
                // Skip any remaining pixels in this row.
                if (m_coord.x() < m_parent->size().width())
                    m_buffer->setHasAlpha(true);
                moveBufferToNextRow();

                m_decodedOffset += 2;
                break;

            case 1:  // Magic token: EOF
                // Skip any remaining pixels in the image.
                if ((m_coord.x() < m_parent->size().width()) || (m_isTopDown ? (m_coord.y() < (m_parent->size().height() - 1)) : (m_coord.y() > 0)))
                    m_buffer->setHasAlpha(true);
                return true;

            case 2: {  // Magic token: Delta
                // The next two bytes specify dx and dy.  Bail if there isn't
                // enough data.
                if ((m_data->size() - m_decodedOffset) < 4)
                    return false;

                // Fail if this takes us past the end of the desired row or
                // past the end of the image.
                const uint8_t dx = m_data->data()[m_decodedOffset + 2];
                const uint8_t dy = m_data->data()[m_decodedOffset + 3];
                if (dx || dy)
                    m_buffer->setHasAlpha(true);
                if (((m_coord.x() + dx) > m_parent->size().width()) || pastEndOfImage(dy))
                    return m_parent->setFailed();

                // Skip intervening pixels.
                m_coord.move(dx, m_isTopDown ? dy : -dy);

                m_decodedOffset += 4;
                break;
            }

            default: { // Absolute mode
                // |code| pixels specified as in BI_RGB, zero-padded at the end
                // to a multiple of 16 bits.
                // Because processNonRLEData() expects m_decodedOffset to
                // point to the beginning of the pixel data, bump it past
                // the escape bytes and then reset if decoding failed.
                m_decodedOffset += 2;
                const ProcessingResult result = processNonRLEData(true, code);
                if (result == Failure)
                    return m_parent->setFailed();
                if (result == InsufficientData) {
                    m_decodedOffset -= 2;
                    return false;
                }
                break;
            }
            }
        } else {  // Encoded mode
            // The following color data is repeated for |count| total pixels.
            // Strangely, some BMPs seem to specify excessively large counts
            // here; ignore pixels past the end of the row.
            const int endX = std::min(m_coord.x() + count, m_parent->size().width());

            if (m_infoHeader.biCompression == RLE24) {
                // Bail if there isn't enough data.
                if ((m_data->size() - m_decodedOffset) < 4)
                    return false;

                // One BGR triple that we copy |count| times.
                fillRGBA(endX, m_data->data()[m_decodedOffset + 3], m_data->data()[m_decodedOffset + 2], code, 0xff);
                m_decodedOffset += 4;
            } else {
                // RLE8 has one color index that gets repeated; RLE4 has two
                // color indexes in the upper and lower 4 bits of the byte,
                // which are alternated.
                size_t colorIndexes[2] = {code, code};
                if (m_infoHeader.biCompression == RLE4) {
                    colorIndexes[0] = (colorIndexes[0] >> 4) & 0xf;
                    colorIndexes[1] &= 0xf;
                }
                for (int which = 0; m_coord.x() < endX; ) {
                    // Some images specify color values past the end of the
                    // color table; set these pixels to black.
                    if (colorIndexes[which] < m_infoHeader.biClrUsed)
                        setI(colorIndexes[which]);
                    else
                        setRGBA(0, 0, 0, 255);
                    which = !which;
                }

                m_decodedOffset += 2;
            }
        }
    }
}

BMPImageReader::ProcessingResult BMPImageReader::processNonRLEData(bool inRLE, int numPixels)
{
    if (m_decodedOffset > m_data->size())
        return InsufficientData;

    if (!inRLE)
        numPixels = m_parent->size().width();

    // Fail if we're being asked to decode more pixels than remain in the row.
    const int endX = m_coord.x() + numPixels;
    if (endX > m_parent->size().width())
        return Failure;

    // Determine how many bytes of data the requested number of pixels
    // requires.
    const size_t pixelsPerByte = 8 / m_infoHeader.biBitCount;
    const size_t bytesPerPixel = m_infoHeader.biBitCount / 8;
    const size_t unpaddedNumBytes = (m_infoHeader.biBitCount < 16) ? ((numPixels + pixelsPerByte - 1) / pixelsPerByte) : (numPixels * bytesPerPixel);
    // RLE runs are zero-padded at the end to a multiple of 16 bits.  Non-RLE
    // data is in rows and is zero-padded to a multiple of 32 bits.
    const size_t alignBits = inRLE ? 1 : 3;
    const size_t paddedNumBytes = (unpaddedNumBytes + alignBits) & ~alignBits;

    // Decode as many rows as we can.  (For RLE, where we only want to decode
    // one row, we've already checked that this condition is true.)
    while (!pastEndOfImage(0)) {
        // Bail if we don't have enough data for the desired number of pixels.
        if ((m_data->size() - m_decodedOffset) < paddedNumBytes)
            return InsufficientData;

        if (m_infoHeader.biBitCount < 16) {
            // Paletted data.  Pixels are stored little-endian within bytes.
            // Decode pixels one byte at a time, left to right (so, starting at
            // the most significant bits in the byte).
            const uint8_t mask = (1 << m_infoHeader.biBitCount) - 1;
            for (size_t byte = 0; byte < unpaddedNumBytes; ++byte) {
                uint8_t pixelData = m_data->data()[m_decodedOffset + byte];
                for (size_t pixel = 0; (pixel < pixelsPerByte) && (m_coord.x() < endX); ++pixel) {
                    const size_t colorIndex = (pixelData >> (8 - m_infoHeader.biBitCount)) & mask;
                    if (m_decodingAndMask) {
                        // There's no way to accurately represent an AND + XOR
                        // operation as an RGBA image, so where the AND values
                        // are 1, we simply set the framebuffer pixels to fully
                        // transparent, on the assumption that most ICOs on the
                        // web will not be doing a lot of inverting.
                        if (colorIndex) {
                            setRGBA(0, 0, 0, 0);
                            m_buffer->setHasAlpha(true);
                        } else
                            m_coord.move(1, 0);
                    } else {
                        // See comments near the end of processRLEData().
                        if (colorIndex < m_infoHeader.biClrUsed)
                            setI(colorIndex);
                        else
                            setRGBA(0, 0, 0, 255);
                    }
                    pixelData <<= m_infoHeader.biBitCount;
                }
            }
        } else {
            // RGB data.  Decode pixels one at a time, left to right.
            while (m_coord.x() < endX) {
                const uint32_t pixel = readCurrentPixel(bytesPerPixel);

                // Some BMPs specify an alpha channel but don't actually use it
                // (it contains all 0s).  To avoid displaying these images as
                // fully-transparent, decode as if images are fully opaque
                // until we actually see a non-zero alpha value; at that point,
                // reset any previously-decoded pixels to fully transparent and
                // continue decoding based on the real alpha channel values.
                // As an optimization, avoid setting "hasAlpha" to true for
                // images where all alpha values are 255; opaque images are
                // faster to draw.
                int alpha = getAlpha(pixel);
                if (!m_seenNonZeroAlphaPixel && !alpha) {
                    m_seenZeroAlphaPixel = true;
                    alpha = 255;
                } else {
                    m_seenNonZeroAlphaPixel = true;
                    if (m_seenZeroAlphaPixel) {
                        m_buffer->zeroFillPixelData();
                        m_seenZeroAlphaPixel = false;
                    } else if (alpha != 255)
                        m_buffer->setHasAlpha(true);
                }

                setRGBA(getComponent(pixel, 0), getComponent(pixel, 1),
                        getComponent(pixel, 2), alpha);
            }
        }

        // Success, keep going.
        m_decodedOffset += paddedNumBytes;
        if (inRLE)
            return Success;
        moveBufferToNextRow();
    }

    // Finished decoding whole image.
    return Success;
}

void BMPImageReader::moveBufferToNextRow()
{
    m_coord.move(-m_coord.x(), m_isTopDown ? 1 : -1);
}

} // namespace blink
