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

#ifndef BMPImageReader_h
#define BMPImageReader_h

#include <stdint.h>
#include "platform/image-decoders/ImageDecoder.h"
#include "wtf/CPU.h"

namespace blink {

// This class decodes a BMP image.  It is used in the BMP and ICO decoders,
// which wrap it in the appropriate code to read file headers, etc.
class PLATFORM_EXPORT BMPImageReader {
    WTF_MAKE_FAST_ALLOCATED;
public:
    // Read a value from |data[offset]|, converting from little to native
    // endianness.
    static inline uint16_t readUint16(SharedBuffer* data, int offset)
    {
        uint16_t result;
        memcpy(&result, &data->data()[offset], 2);
    #if CPU(BIG_ENDIAN)
        result = ((result & 0xff) << 8) | ((result & 0xff00) >> 8);
    #endif
        return result;
    }

    static inline uint32_t readUint32(SharedBuffer* data, int offset)
    {
        uint32_t result;
        memcpy(&result, &data->data()[offset], 4);
    #if CPU(BIG_ENDIAN)
        result = ((result & 0xff) << 24) | ((result & 0xff00) << 8) | ((result & 0xff0000) >> 8) | ((result & 0xff000000) >> 24);
    #endif
        return result;
    }

    // |parent| is the decoder that owns us.
    // |startOffset| points to the start of the BMP within the file.
    // |buffer| points at an empty ImageFrame that we'll initialize and
    // fill with decoded data.
    BMPImageReader(ImageDecoder* parent, size_t decodedAndHeaderOffset, size_t imgDataOffset, bool isInICO);

    void setBuffer(ImageFrame* buffer) { m_buffer = buffer; }
    void setData(SharedBuffer* data) { m_data = data; }

    // Does the actual decoding.  If |onlySize| is true, decoding only
    // progresses as far as necessary to get the image size.  Returns
    // whether decoding succeeded.
    bool decodeBMP(bool onlySize);

private:
    // The various BMP compression types.  We don't currently decode all
    // these.
    enum CompressionType {
        // Universal types
        RGB = 0,
        RLE8 = 1,
        RLE4 = 2,
        // Windows V3+ only
        BITFIELDS = 3,
        JPEG = 4,
        PNG = 5,
        // OS/2 2.x-only
        HUFFMAN1D,  // Stored in file as 3
        RLE24,      // Stored in file as 4
    };
    enum ProcessingResult {
        Success,
        Failure,
        InsufficientData,
    };

    // These are based on the Windows BITMAPINFOHEADER and RGBTRIPLE
    // structs, but with unnecessary entries removed.
    struct BitmapInfoHeader {
        uint32_t biSize;
        int32_t biWidth;
        int32_t biHeight;
        uint16_t biBitCount;
        CompressionType biCompression;
        uint32_t biClrUsed;
    };
    struct RGBTriple {
        uint8_t rgbBlue;
        uint8_t rgbGreen;
        uint8_t rgbRed;
    };

    inline uint16_t readUint16(int offset) const
    {
        return readUint16(m_data.get(), m_decodedOffset + offset);
    }

    inline uint32_t readUint32(int offset) const
    {
        return readUint32(m_data.get(), m_decodedOffset + offset);
    }

    // Determines the size of the BMP info header.  Returns true if the size
    // is valid.
    bool readInfoHeaderSize();

    // Processes the BMP info header.  Returns true if the info header could
    // be decoded.
    bool processInfoHeader();

    // Helper function for processInfoHeader() which does the actual reading
    // of header values from the byte stream.  Returns false on error.
    bool readInfoHeader();

    // Returns true if this is a Windows V4+ BMP.
    inline bool isWindowsV4Plus() const
    {
        // Windows V4 info header is 108 bytes.  V5 is 124 bytes.
        return (m_infoHeader.biSize == 108) || (m_infoHeader.biSize == 124);
    }

    // Returns false if consistency errors are found in the info header.
    bool isInfoHeaderValid() const;

    // For BI_BITFIELDS images, initializes the m_bitMasks[] and
    // m_bitOffsets[] arrays.  processInfoHeader() will initialize these for
    // other compression types where needed.
    bool processBitmasks();

    // For paletted images, allocates and initializes the m_colorTable[]
    // array.
    bool processColorTable();

    // Processes an RLE-encoded image.  Returns true if the entire image was
    // decoded.
    bool processRLEData();

    // Processes a set of non-RLE-compressed pixels.  Two cases:
    //   * inRLE = true: the data is inside an RLE-encoded bitmap.  Tries to
    //     process |numPixels| pixels on the current row.
    //   * inRLE = false: the data is inside a non-RLE-encoded bitmap.
    //     |numPixels| is ignored.  Expects |m_coord| to point at the
    //     beginning of the next row to be decoded.  Tries to process as
    //     many complete rows as possible.  Returns InsufficientData if
    //     there wasn't enough data to decode the whole image.
    //
    // This function returns a ProcessingResult instead of a bool so that it
    // can avoid calling m_parent->setFailed(), which could lead to memory
    // corruption since that will delete |this| but some callers still want
    // to access member variables after this returns.
    ProcessingResult processNonRLEData(bool inRLE, int numPixels);

    // Returns true if the current y-coordinate plus |numRows| would be past
    // the end of the image.  Here "plus" means "toward the end of the
    // image", so downwards for m_isTopDown images and upwards otherwise.
    inline bool pastEndOfImage(int numRows)
    {
        return m_isTopDown ? ((m_coord.y() + numRows) >= m_parent->size().height()) : ((m_coord.y() - numRows) < 0);
    }

    // Returns the pixel data for the current X coordinate in a uint32_t.
    // Assumes m_decodedOffset has been set to the beginning of the current
    // row.
    // NOTE: Only as many bytes of the return value as are needed to hold
    // the pixel data will actually be set.
    inline uint32_t readCurrentPixel(int bytesPerPixel) const
    {
        const int offset = m_coord.x() * bytesPerPixel;
        switch (bytesPerPixel) {
        case 2:
            return readUint16(offset);

        case 3: {
            // It doesn't matter that we never set the most significant byte
            // of the return value here in little-endian mode, the caller
            // won't read it.
            uint32_t pixel;
            memcpy(&pixel, &m_data->data()[m_decodedOffset + offset], 3);
    #if CPU(BIG_ENDIAN)
            pixel = ((pixel & 0xff00) << 8) | ((pixel & 0xff0000) >> 8) | ((pixel & 0xff000000) >> 24);
    #endif
            return pixel;
        }

        case 4:
            return readUint32(offset);

        default:
            ASSERT_NOT_REACHED();
            return 0;
        }
    }

    // Returns the value of the desired component (0, 1, 2, 3 == R, G, B, A)
    // in the given pixel data.
    inline unsigned getComponent(uint32_t pixel, int component) const
    {
        uint8_t value = (pixel & m_bitMasks[component]) >> m_bitShiftsRight[component];
        return m_lookupTableAddresses[component] ? m_lookupTableAddresses[component][value] : value;
    }

    inline unsigned getAlpha(uint32_t pixel) const
    {
        // For images without alpha, return alpha of 0xff.
        return m_bitMasks[3] ? getComponent(pixel, 3) : 0xff;
    }

    // Sets the current pixel to the color given by |colorIndex|.  This also
    // increments the relevant local variables to move the current pixel
    // right by one.
    inline void setI(size_t colorIndex)
    {
        setRGBA(m_colorTable[colorIndex].rgbRed, m_colorTable[colorIndex].rgbGreen, m_colorTable[colorIndex].rgbBlue, 0xff);
    }

    // Like setI(), but with the individual component values specified.
    inline void setRGBA(unsigned red,
                        unsigned green,
                        unsigned blue,
                        unsigned alpha)
    {
        m_buffer->setRGBA(m_coord.x(), m_coord.y(), red, green, blue, alpha);
        m_coord.move(1, 0);
    }

    // Fills pixels from the current X-coordinate up to, but not including,
    // |endCoord| with the color given by the individual components.  This
    // also increments the relevant local variables to move the current
    // pixel right to |endCoord|.
    inline void fillRGBA(int endCoord,
                         unsigned red,
                         unsigned green,
                         unsigned blue,
                         unsigned alpha)
    {
        while (m_coord.x() < endCoord)
            setRGBA(red, green, blue, alpha);
    }

    // Resets the relevant local variables to start drawing at the left edge
    // of the "next" row, where "next" is above or below the current row
    // depending on the value of |m_isTopDown|.
    void moveBufferToNextRow();

    // The decoder that owns us.
    ImageDecoder* m_parent;

    // The destination for the pixel data.
    ImageFrame* m_buffer;

    // The file to decode.
    RefPtr<SharedBuffer> m_data;

    // An index into |m_data| representing how much we've already decoded.
    size_t m_decodedOffset;

    // The file offset at which the BMP info header starts.
    size_t m_headerOffset;

    // The file offset at which the actual image bits start.  When decoding
    // ICO files, this is set to 0, since it's not stored anywhere in a
    // header; the reader functions expect the image data to start
    // immediately after the header and (if necessary) color table.
    size_t m_imgDataOffset;

    // The BMP info header.
    BitmapInfoHeader m_infoHeader;

    // True if this is an OS/2 1.x (aka Windows 2.x) BMP.  The struct
    // layouts for this type of BMP are slightly different from the later,
    // more common formats.
    bool m_isOS21x;

    // True if this is an OS/2 2.x BMP.  The meanings of compression types 3
    // and 4 for this type of BMP differ from Windows V3+ BMPs.
    //
    // This will be falsely negative in some cases, but only ones where the
    // way we misinterpret the data is irrelevant.
    bool m_isOS22x;

    // True if the BMP is not vertically flipped, that is, the first line of
    // raster data in the file is the top line of the image.
    bool m_isTopDown;

    // These flags get set to false as we finish each processing stage.
    bool m_needToProcessBitmasks;
    bool m_needToProcessColorTable;

    // Masks/offsets for the color values for non-palette formats. These are
    // bitwise, with array entries 0, 1, 2, 3 corresponding to R, G, B, A.
    uint32_t m_bitMasks[4];

    // Right shift values, meant to be applied after the masks. We need to shift
    // the bitfield values down from their offsets into the 32 bits of pixel
    // data, as well as truncate the least significant bits of > 8-bit fields.
    int m_bitShiftsRight[4];

    // We use a lookup table to convert < 8-bit values into 8-bit values. The
    // values in the table are "round(val * 255.0 / ((1 << n) - 1))" for an
    // n-bit source value. These elements are set to 0 for 8-bit sources.
    const uint8_t* m_lookupTableAddresses[4];

    // The color palette, for paletted formats.
    Vector<RGBTriple> m_colorTable;

    // The coordinate to which we've decoded the image.
    IntPoint m_coord;

    // Variables that track whether we've seen pixels with alpha values != 0
    // and == 0, respectively.  See comments in processNonRLEData() on how
    // these are used.
    bool m_seenNonZeroAlphaPixel;
    bool m_seenZeroAlphaPixel;

    // BMPs-in-ICOs have a few differences from standalone BMPs, so we need to
    // know if we're in an ICO container.
    bool m_isInICO;

    // ICOs store a 1bpp "mask" immediately after the main bitmap image data
    // (and, confusingly, add its height to the biHeight value in the info
    // header, thus doubling it). If |m_isInICO| is true, this variable tracks
    // whether we've begun decoding this mask yet.
    bool m_decodingAndMask;
};

} // namespace blink

#endif
