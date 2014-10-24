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

#ifndef ICOImageDecoder_h
#define ICOImageDecoder_h

#include "platform/image-decoders/bmp/BMPImageReader.h"

namespace blink {

class PNGImageDecoder;

// This class decodes the ICO and CUR image formats.
class PLATFORM_EXPORT ICOImageDecoder : public ImageDecoder {
public:
    ICOImageDecoder(ImageSource::AlphaOption, ImageSource::GammaAndColorProfileOption, size_t maxDecodedBytes);
    virtual ~ICOImageDecoder();

    // ImageDecoder
    virtual String filenameExtension() const override { return "ico"; }
    virtual void setData(SharedBuffer*, bool allDataReceived) override;
    virtual bool isSizeAvailable() override;
    virtual IntSize size() const override;
    virtual IntSize frameSizeAtIndex(size_t) const override;
    virtual bool setSize(unsigned width, unsigned height) override;
    virtual size_t frameCount() override;
    virtual ImageFrame* frameBufferAtIndex(size_t) override;
    // CAUTION: setFailed() deletes all readers and decoders.  Be careful to
    // avoid accessing deleted memory, especially when calling this from
    // inside BMPImageReader!
    virtual bool setFailed() override;
    virtual bool hotSpot(IntPoint&) const override;

private:
    enum ImageType {
        Unknown,
        BMP,
        PNG,
    };

    enum FileType {
        ICON = 1,
        CURSOR = 2,
    };

    struct IconDirectoryEntry {
        IntSize m_size;
        uint16_t m_bitCount;
        IntPoint m_hotSpot;
        uint32_t m_imageOffset;
    };

    // Returns true if |a| is a preferable icon entry to |b|.
    // Larger sizes, or greater bitdepths at the same size, are preferable.
    static bool compareEntries(const IconDirectoryEntry& a, const IconDirectoryEntry& b);

    inline uint16_t readUint16(int offset) const
    {
        return BMPImageReader::readUint16(m_data.get(), m_decodedOffset + offset);
    }

    inline uint32_t readUint32(int offset) const
    {
        return BMPImageReader::readUint32(m_data.get(), m_decodedOffset + offset);
    }

    // If the desired PNGImageDecoder exists, gives it the appropriate data.
    void setDataForPNGDecoderAtIndex(size_t);

    // Decodes the entry at |index|.  If |onlySize| is true, stops decoding
    // after calculating the image size.  If decoding fails but there is no
    // more data coming, sets the "decode failure" flag.
    void decode(size_t index, bool onlySize);

    // Decodes the directory and directory entries at the beginning of the
    // data, and initializes members.  Returns true if all decoding
    // succeeded.  Once this returns true, all entries' sizes are known.
    bool decodeDirectory();

    // Decodes the specified entry.
    bool decodeAtIndex(size_t);

    // Processes the ICONDIR at the beginning of the data.  Returns true if
    // the directory could be decoded.
    bool processDirectory();

    // Processes the ICONDIRENTRY records after the directory.  Keeps the
    // "best" entry as the one we'll decode.  Returns true if the entries
    // could be decoded.
    bool processDirectoryEntries();

    // Stores the hot-spot for |index| in |hotSpot| and returns true,
    // or returns false if there is none.
    bool hotSpotAtIndex(size_t index, IntPoint& hotSpot) const;

    // Reads and returns a directory entry from the current offset into
    // |data|.
    IconDirectoryEntry readDirectoryEntry();

    // Determines whether the desired entry is a BMP or PNG.  Returns true
    // if the type could be determined.
    ImageType imageTypeAtIndex(size_t);

    // An index into |m_data| representing how much we've already decoded.
    // Note that this only tracks data _this_ class decodes; once the
    // BMPImageReader takes over this will not be updated further.
    size_t m_decodedOffset;

    // Which type of file (ICO/CUR) this is.
    FileType m_fileType;

    // The headers for the ICO.
    typedef Vector<IconDirectoryEntry> IconDirectoryEntries;
    IconDirectoryEntries m_dirEntries;

    // The image decoders for the various frames.
    typedef Vector<OwnPtr<BMPImageReader> > BMPReaders;
    BMPReaders m_bmpReaders;
    typedef Vector<OwnPtr<PNGImageDecoder> > PNGDecoders;
    PNGDecoders m_pngDecoders;

    // Valid only while a BMPImageReader is decoding, this holds the size
    // for the particular entry being decoded.
    IntSize m_frameSize;
};

} // namespace blink

#endif
