/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef MockImageDecoder_h

#include "platform/image-decoders/ImageDecoder.h"
#include "wtf/PassOwnPtr.h"

namespace blink {

class MockImageDecoderClient {
public:
    virtual void decoderBeingDestroyed() = 0;
    virtual void frameBufferRequested() = 0;
    virtual ImageFrame::Status status() = 0;
    virtual size_t frameCount() = 0;
    virtual int repetitionCount() const = 0;
    virtual float frameDuration() const = 0;

    // Clients can control the behavior of MockImageDecoder::decodedSize() by
    // overriding this method. The default implementation causes
    // MockImageDecoder::decodedSize() to return the same thing as
    // MockImageDecoder::size(). See the precise implementation of
    // MockImageDecoder::decodedSize() below.
    virtual IntSize decodedSize() const { return IntSize(); }
};

class MockImageDecoder : public ImageDecoder {
public:
    static PassOwnPtr<MockImageDecoder> create(MockImageDecoderClient* client) { return adoptPtr(new MockImageDecoder(client)); }

    MockImageDecoder(MockImageDecoderClient* client)
        : ImageDecoder(ImageSource::AlphaPremultiplied, ImageSource::GammaAndColorProfileApplied, noDecodedImageByteLimit)
        , m_client(client)
    { }

    ~MockImageDecoder()
    {
        m_client->decoderBeingDestroyed();
    }

    virtual IntSize decodedSize() const OVERRIDE
    {
        return m_client->decodedSize().isEmpty() ? size() : m_client->decodedSize();
    }

    virtual bool setSize(unsigned width, unsigned height) OVERRIDE
    {
        ImageDecoder::setSize(width, height);
        m_frameBufferCache.resize(1);
        m_frameBufferCache[0].setSize(width, height);
        return true;
    }

    virtual String filenameExtension() const OVERRIDE
    {
        return "mock";
    }

    virtual size_t frameCount() OVERRIDE
    {
        return m_client->frameCount();
    }

    virtual int repetitionCount() const OVERRIDE
    {
        return m_client->repetitionCount();
    }

    virtual ImageFrame* frameBufferAtIndex(size_t) OVERRIDE
    {
        m_client->frameBufferRequested();

        m_frameBufferCache[0].setStatus(m_client->status());
        return &m_frameBufferCache[0];
    }

    virtual bool frameIsCompleteAtIndex(size_t) const OVERRIDE
    {
        return m_client->status() == ImageFrame::FrameComplete;
    }

    virtual float frameDurationAtIndex(size_t) const OVERRIDE
    {
        return m_client->frameDuration();
    }

    void setFrameHasAlpha(bool hasAlpha) { m_frameBufferCache[0].setHasAlpha(hasAlpha); }

private:
    MockImageDecoderClient* m_client;
};

class MockImageDecoderFactory : public ImageDecoderFactory {
public:
    static PassOwnPtr<MockImageDecoderFactory> create(MockImageDecoderClient* client, const SkISize& decodedSize)
    {
        return adoptPtr(new MockImageDecoderFactory(client, IntSize(decodedSize.width(), decodedSize.height())));
    }

    static PassOwnPtr<MockImageDecoderFactory> create(MockImageDecoderClient* client, const IntSize& decodedSize)
    {
        return adoptPtr(new MockImageDecoderFactory(client, decodedSize));
    }

    virtual PassOwnPtr<ImageDecoder> create() OVERRIDE
    {
        OwnPtr<MockImageDecoder> decoder = MockImageDecoder::create(m_client);
        decoder->setSize(m_decodedSize.width(), m_decodedSize.height());
        decoder->setFrameHasAlpha(false);
        return decoder.release();
    }

private:
    MockImageDecoderFactory(MockImageDecoderClient* client, const IntSize& decodedSize)
        : m_client(client)
        , m_decodedSize(decodedSize)
    {
    }

    MockImageDecoderClient* m_client;
    IntSize m_decodedSize;
};

} // namespace blink

#endif // MockImageDecoder_h
