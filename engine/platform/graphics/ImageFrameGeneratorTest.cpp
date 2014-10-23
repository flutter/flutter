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

#include "config.h"
#include "platform/graphics/ImageFrameGenerator.h"

#include "base/bind.h"
#include "base/threading/thread.h"
#include "platform/SharedBuffer.h"
#include "platform/graphics/ImageDecodingStore.h"
#include "platform/graphics/test/MockImageDecoder.h"
#include <gtest/gtest.h>

namespace blink {

namespace {

// Helper methods to generate standard sizes.
SkISize fullSize() { return SkISize::Make(100, 100); }

SkImageInfo imageInfo()
{
    return SkImageInfo::Make(100, 100, kBGRA_8888_SkColorType, kOpaque_SkAlphaType);
}

} // namespace

class ImageFrameGeneratorTest : public ::testing::Test, public MockImageDecoderClient {
public:
    virtual void SetUp() OVERRIDE
    {
        ImageDecodingStore::instance()->setCacheLimitInBytes(1024 * 1024);
        m_data = SharedBuffer::create();
        m_generator = ImageFrameGenerator::create(fullSize(), m_data, false);
        useMockImageDecoderFactory();
        m_decodersDestroyed = 0;
        m_frameBufferRequestCount = 0;
        m_status = ImageFrame::FrameEmpty;
    }

    virtual void TearDown() OVERRIDE
    {
        ImageDecodingStore::instance()->clear();
    }

    virtual void decoderBeingDestroyed() OVERRIDE
    {
        ++m_decodersDestroyed;
    }

    virtual void frameBufferRequested() OVERRIDE
    {
        ++m_frameBufferRequestCount;
    }

    virtual ImageFrame::Status status() OVERRIDE
    {
        ImageFrame::Status currentStatus = m_status;
        m_status = m_nextFrameStatus;
        return currentStatus;
    }

    virtual size_t frameCount() OVERRIDE { return 1; }
    virtual int repetitionCount() const OVERRIDE { return cAnimationNone; }
    virtual float frameDuration() const OVERRIDE { return 0; }

protected:
    void useMockImageDecoderFactory()
    {
        m_generator->setImageDecoderFactory(MockImageDecoderFactory::create(this, fullSize()));
    }

    void addNewData()
    {
        m_data->append("g", 1);
        m_generator->setData(m_data, false);
    }

    void setFrameStatus(ImageFrame::Status status)  { m_status = m_nextFrameStatus = status; }
    void setNextFrameStatus(ImageFrame::Status status)  { m_nextFrameStatus = status; }

    RefPtr<SharedBuffer> m_data;
    RefPtr<ImageFrameGenerator> m_generator;
    int m_decodersDestroyed;
    int m_frameBufferRequestCount;
    ImageFrame::Status m_status;
    ImageFrame::Status m_nextFrameStatus;
};

TEST_F(ImageFrameGeneratorTest, incompleteDecode)
{
    setFrameStatus(ImageFrame::FramePartial);

    char buffer[100 * 100 * 4];
    m_generator->decodeAndScale(imageInfo(), 0, buffer, 100 * 4);
    EXPECT_EQ(1, m_frameBufferRequestCount);

    addNewData();
    m_generator->decodeAndScale(imageInfo(), 0, buffer, 100 * 4);
    EXPECT_EQ(2, m_frameBufferRequestCount);
    EXPECT_EQ(0, m_decodersDestroyed);
}

TEST_F(ImageFrameGeneratorTest, incompleteDecodeBecomesComplete)
{
    setFrameStatus(ImageFrame::FramePartial);

    char buffer[100 * 100 * 4];
    m_generator->decodeAndScale(imageInfo(), 0, buffer, 100 * 4);
    EXPECT_EQ(1, m_frameBufferRequestCount);
    EXPECT_EQ(0, m_decodersDestroyed);

    setFrameStatus(ImageFrame::FrameComplete);
    addNewData();

    m_generator->decodeAndScale(imageInfo(), 0, buffer, 100 * 4);
    EXPECT_EQ(2, m_frameBufferRequestCount);
    EXPECT_EQ(1, m_decodersDestroyed);

    // Decoder created again.
    m_generator->decodeAndScale(imageInfo(), 0, buffer, 100 * 4);
    EXPECT_EQ(3, m_frameBufferRequestCount);
}

static void decodeThreadMain(ImageFrameGenerator* generator)
{
    char buffer[100 * 100 * 4];
    generator->decodeAndScale(imageInfo(), 0, buffer, 100 * 4);
}

TEST_F(ImageFrameGeneratorTest, incompleteDecodeBecomesCompleteMultiThreaded)
{
    setFrameStatus(ImageFrame::FramePartial);

    char buffer[100 * 100 * 4];
    m_generator->decodeAndScale(imageInfo(), 0, buffer, 100 * 4);
    EXPECT_EQ(1, m_frameBufferRequestCount);
    EXPECT_EQ(0, m_decodersDestroyed);

    // LocalFrame can now be decoded completely.
    setFrameStatus(ImageFrame::FrameComplete);
    addNewData();
    OwnPtr<base::Thread> thread = adoptPtr(new base::Thread("DecodeThread"));
    thread->Start();
    thread->message_loop()->PostTask(FROM_HERE, base::Bind(&decodeThreadMain, m_generator.get()));
    thread.clear();
    EXPECT_EQ(2, m_frameBufferRequestCount);
    EXPECT_EQ(1, m_decodersDestroyed);

    // Decoder created again.
    m_generator->decodeAndScale(imageInfo(), 0, buffer, 100 * 4);
    EXPECT_EQ(3, m_frameBufferRequestCount);
}

TEST_F(ImageFrameGeneratorTest, frameHasAlpha)
{
    setFrameStatus(ImageFrame::FramePartial);

    char buffer[100 * 100 * 4];
    m_generator->decodeAndScale(imageInfo(), 1, buffer, 100 * 4);
    EXPECT_TRUE(m_generator->hasAlpha(1));
    EXPECT_EQ(1, m_frameBufferRequestCount);

    ImageDecoder* tempDecoder = 0;
    EXPECT_TRUE(ImageDecodingStore::instance()->lockDecoder(m_generator.get(), fullSize(), &tempDecoder));
    ASSERT_TRUE(tempDecoder);
    static_cast<MockImageDecoder*>(tempDecoder)->setFrameHasAlpha(false);
    ImageDecodingStore::instance()->unlockDecoder(m_generator.get(), tempDecoder);

    setFrameStatus(ImageFrame::FrameComplete);
    m_generator->decodeAndScale(imageInfo(), 1, buffer, 100 * 4);
    EXPECT_EQ(2, m_frameBufferRequestCount);
    EXPECT_FALSE(m_generator->hasAlpha(1));
}

} // namespace blink
