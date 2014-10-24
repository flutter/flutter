/*
 * Copyright (C) 2006 Apple Computer, Inc.  All rights reserved.
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

#ifndef PNGImageDecoder_h
#define PNGImageDecoder_h

#include "platform/image-decoders/ImageDecoder.h"
#include "wtf/Noncopyable.h"
#include "wtf/OwnPtr.h"

namespace blink {

class PNGImageReader;

// This class decodes the PNG image format.
class PLATFORM_EXPORT PNGImageDecoder : public ImageDecoder {
    WTF_MAKE_NONCOPYABLE(PNGImageDecoder);
public:
    PNGImageDecoder(ImageSource::AlphaOption, ImageSource::GammaAndColorProfileOption, size_t maxDecodedBytes);
    virtual ~PNGImageDecoder();

    // ImageDecoder
    virtual String filenameExtension() const override { return "png"; }
    virtual bool isSizeAvailable() override;
    virtual bool hasColorProfile() const override { return m_hasColorProfile; }
    virtual ImageFrame* frameBufferAtIndex(size_t) override;
    // CAUTION: setFailed() deletes |m_reader|.  Be careful to avoid
    // accessing deleted memory, especially when calling this from inside
    // PNGImageReader!
    virtual bool setFailed() override;

    // Callbacks from libpng
    void headerAvailable();
    void rowAvailable(unsigned char* rowBuffer, unsigned rowIndex, int interlacePass);
    void pngComplete();

    bool isComplete() const
    {
        return !m_frameBufferCache.isEmpty() && (m_frameBufferCache.first().status() == ImageFrame::FrameComplete);
    }

private:
    // Decodes the image.  If |onlySize| is true, stops decoding after
    // calculating the image size.  If decoding fails but there is no more
    // data coming, sets the "decode failure" flag.
    void decode(bool onlySize);

    OwnPtr<PNGImageReader> m_reader;
    bool m_doNothingOnFailure;
    bool m_hasColorProfile;
};

} // namespace blink

#endif
