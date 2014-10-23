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

#include "platform/graphics/ImageDecodingStore.h"

#include "platform/SharedBuffer.h"
#include "platform/graphics/ImageFrameGenerator.h"
#include "platform/graphics/test/MockImageDecoder.h"
#include <gtest/gtest.h>

using namespace blink;

namespace {

class ImageDecodingStoreTest : public ::testing::Test, public MockImageDecoderClient {
public:
    virtual void SetUp()
    {
        ImageDecodingStore::instance()->setCacheLimitInBytes(1024 * 1024);
        m_data = SharedBuffer::create();
        m_generator = ImageFrameGenerator::create(SkISize::Make(100, 100), m_data, true);
        m_decodersDestroyed = 0;
    }

    virtual void TearDown()
    {
        ImageDecodingStore::instance()->clear();
    }

    virtual void decoderBeingDestroyed()
    {
        ++m_decodersDestroyed;
    }

    virtual void frameBufferRequested()
    {
        // Decoder is never used by ImageDecodingStore.
        ASSERT_TRUE(false);
    }

    virtual ImageFrame::Status status()
    {
        return ImageFrame::FramePartial;
    }

    virtual size_t frameCount() { return 1; }
    virtual int repetitionCount() const { return cAnimationNone; }
    virtual float frameDuration() const { return 0; }

protected:
    void evictOneCache()
    {
        size_t memoryUsageInBytes = ImageDecodingStore::instance()->memoryUsageInBytes();
        if (memoryUsageInBytes)
            ImageDecodingStore::instance()->setCacheLimitInBytes(memoryUsageInBytes - 1);
        else
            ImageDecodingStore::instance()->setCacheLimitInBytes(0);
    }

    RefPtr<SharedBuffer> m_data;
    RefPtr<ImageFrameGenerator> m_generator;
    int m_decodersDestroyed;
};

TEST_F(ImageDecodingStoreTest, insertDecoder)
{
    const SkISize size = SkISize::Make(1, 1);
    OwnPtr<ImageDecoder> decoder = MockImageDecoder::create(this);
    decoder->setSize(1, 1);
    const ImageDecoder* refDecoder = decoder.get();
    ImageDecodingStore::instance()->insertDecoder(m_generator.get(), decoder.release());
    EXPECT_EQ(1, ImageDecodingStore::instance()->cacheEntries());
    EXPECT_EQ(4u, ImageDecodingStore::instance()->memoryUsageInBytes());

    ImageDecoder* testDecoder;
    EXPECT_TRUE(ImageDecodingStore::instance()->lockDecoder(m_generator.get(), size, &testDecoder));
    EXPECT_TRUE(testDecoder);
    EXPECT_EQ(refDecoder, testDecoder);
    ImageDecodingStore::instance()->unlockDecoder(m_generator.get(), testDecoder);
    EXPECT_EQ(1, ImageDecodingStore::instance()->cacheEntries());
}

TEST_F(ImageDecodingStoreTest, evictDecoder)
{
    OwnPtr<ImageDecoder> decoder1 = MockImageDecoder::create(this);
    OwnPtr<ImageDecoder> decoder2 = MockImageDecoder::create(this);
    OwnPtr<ImageDecoder> decoder3 = MockImageDecoder::create(this);
    decoder1->setSize(1, 1);
    decoder2->setSize(2, 2);
    decoder3->setSize(3, 3);
    ImageDecodingStore::instance()->insertDecoder(m_generator.get(), decoder1.release());
    ImageDecodingStore::instance()->insertDecoder(m_generator.get(), decoder2.release());
    ImageDecodingStore::instance()->insertDecoder(m_generator.get(), decoder3.release());
    EXPECT_EQ(3, ImageDecodingStore::instance()->cacheEntries());
    EXPECT_EQ(56u, ImageDecodingStore::instance()->memoryUsageInBytes());

    evictOneCache();
    EXPECT_EQ(2, ImageDecodingStore::instance()->cacheEntries());
    EXPECT_EQ(52u, ImageDecodingStore::instance()->memoryUsageInBytes());

    evictOneCache();
    EXPECT_EQ(1, ImageDecodingStore::instance()->cacheEntries());
    EXPECT_EQ(36u, ImageDecodingStore::instance()->memoryUsageInBytes());

    evictOneCache();
    EXPECT_FALSE(ImageDecodingStore::instance()->cacheEntries());
    EXPECT_FALSE(ImageDecodingStore::instance()->memoryUsageInBytes());
}

TEST_F(ImageDecodingStoreTest, decoderInUseNotEvicted)
{
    OwnPtr<ImageDecoder> decoder1 = MockImageDecoder::create(this);
    OwnPtr<ImageDecoder> decoder2 = MockImageDecoder::create(this);
    OwnPtr<ImageDecoder> decoder3 = MockImageDecoder::create(this);
    decoder1->setSize(1, 1);
    decoder2->setSize(2, 2);
    decoder3->setSize(3, 3);
    ImageDecodingStore::instance()->insertDecoder(m_generator.get(), decoder1.release());
    ImageDecodingStore::instance()->insertDecoder(m_generator.get(), decoder2.release());
    ImageDecodingStore::instance()->insertDecoder(m_generator.get(), decoder3.release());
    EXPECT_EQ(3, ImageDecodingStore::instance()->cacheEntries());

    ImageDecoder* testDecoder;
    EXPECT_TRUE(ImageDecodingStore::instance()->lockDecoder(m_generator.get(), SkISize::Make(2, 2), &testDecoder));

    evictOneCache();
    evictOneCache();
    evictOneCache();
    EXPECT_EQ(1, ImageDecodingStore::instance()->cacheEntries());
    EXPECT_EQ(16u, ImageDecodingStore::instance()->memoryUsageInBytes());

    ImageDecodingStore::instance()->unlockDecoder(m_generator.get(), testDecoder);
    evictOneCache();
    EXPECT_FALSE(ImageDecodingStore::instance()->cacheEntries());
    EXPECT_FALSE(ImageDecodingStore::instance()->memoryUsageInBytes());
}

TEST_F(ImageDecodingStoreTest, removeDecoder)
{
    const SkISize size = SkISize::Make(1, 1);
    OwnPtr<ImageDecoder> decoder = MockImageDecoder::create(this);
    decoder->setSize(1, 1);
    const ImageDecoder* refDecoder = decoder.get();
    ImageDecodingStore::instance()->insertDecoder(m_generator.get(), decoder.release());
    EXPECT_EQ(1, ImageDecodingStore::instance()->cacheEntries());
    EXPECT_EQ(4u, ImageDecodingStore::instance()->memoryUsageInBytes());

    ImageDecoder* testDecoder;
    EXPECT_TRUE(ImageDecodingStore::instance()->lockDecoder(m_generator.get(), size, &testDecoder));
    EXPECT_TRUE(testDecoder);
    EXPECT_EQ(refDecoder, testDecoder);
    ImageDecodingStore::instance()->removeDecoder(m_generator.get(), testDecoder);
    EXPECT_FALSE(ImageDecodingStore::instance()->cacheEntries());

    EXPECT_FALSE(ImageDecodingStore::instance()->lockDecoder(m_generator.get(), size, &testDecoder));
}

} // namespace
