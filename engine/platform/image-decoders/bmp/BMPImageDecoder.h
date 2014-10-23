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

#ifndef BMPImageDecoder_h
#define BMPImageDecoder_h

#include "platform/image-decoders/bmp/BMPImageReader.h"
#include "wtf/OwnPtr.h"

namespace blink {

// This class decodes the BMP image format.
class PLATFORM_EXPORT BMPImageDecoder : public ImageDecoder {
public:
    BMPImageDecoder(ImageSource::AlphaOption, ImageSource::GammaAndColorProfileOption, size_t maxDecodedBytes);

    // ImageDecoder
    virtual String filenameExtension() const OVERRIDE { return "bmp"; }
    virtual void setData(SharedBuffer*, bool allDataReceived) OVERRIDE;
    virtual bool isSizeAvailable() OVERRIDE;
    virtual ImageFrame* frameBufferAtIndex(size_t) OVERRIDE;
    // CAUTION: setFailed() deletes |m_reader|.  Be careful to avoid
    // accessing deleted memory, especially when calling this from inside
    // BMPImageReader!
    virtual bool setFailed() OVERRIDE;

private:
    inline uint32_t readUint32(int offset) const
    {
        return BMPImageReader::readUint32(m_data.get(), m_decodedOffset + offset);
    }

    // Decodes the image.  If |onlySize| is true, stops decoding after
    // calculating the image size.  If decoding fails but there is no more
    // data coming, sets the "decode failure" flag.
    void decode(bool onlySize);

    // Decodes the image.  If |onlySize| is true, stops decoding after
    // calculating the image size.  Returns whether decoding succeeded.
    bool decodeHelper(bool onlySize);

    // Processes the file header at the beginning of the data.  Sets
    // |*imgDataOffset| based on the header contents.  Returns true if the
    // file header could be decoded.
    bool processFileHeader(size_t* imgDataOffset);

    // An index into |m_data| representing how much we've already decoded.
    // Note that this only tracks data _this_ class decodes; once the
    // BMPImageReader takes over this will not be updated further.
    size_t m_decodedOffset;

    // The reader used to do most of the BMP decoding.
    OwnPtr<BMPImageReader> m_reader;
};

} // namespace blink

#endif
