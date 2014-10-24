/*
 * Copyright (c) 2013, Google Inc. All rights reserved.
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
#include "platform/graphics/BitmapImage.h"

#include "platform/SharedBuffer.h"
#include "platform/graphics/DeferredImageDecoder.h"
#include "platform/graphics/ImageObserver.h"
#include "public/platform/Platform.h"
#include "public/platform/WebUnitTestSupport.h"

#include <gtest/gtest.h>

namespace blink {

class BitmapImageTest : public ::testing::Test {
public:
    class FakeImageObserver : public ImageObserver {
    public:
        FakeImageObserver() : m_lastDecodedSizeChangedDelta(0) { }

        virtual void decodedSizeChanged(const Image*, int delta)
        {
            m_lastDecodedSizeChangedDelta = delta;
        }
        virtual void didDraw(const Image*) override { }
        virtual bool shouldPauseAnimation(const Image*) override { return false; }
        virtual void animationAdvanced(const Image*) override { }
        virtual void changedInRect(const Image*, const IntRect&) { }

        int m_lastDecodedSizeChangedDelta;
    };

    static PassRefPtr<SharedBuffer> readFile(const char* fileName)
    {
        String filePath = Platform::current()->unitTestSupport()->webKitRootDir();
        filePath.append(fileName);
        return Platform::current()->unitTestSupport()->readFromFile(filePath);
    }

    // Accessors to BitmapImage's protected methods.
    void destroyDecodedData(bool destroyAll) { m_image->destroyDecodedData(destroyAll); }
    size_t frameCount() { return m_image->frameCount(); }
    void setCurrentFrame(size_t frame) { m_image->m_currentFrame = frame; }
    size_t frameDecodedSize(size_t frame) { return m_image->m_frames[frame].m_frameBytes; }
    size_t decodedFramesCount() const { return m_image->m_frames.size(); }
    void resetDecoder() { return m_image->resetDecoder(); }

    void loadImage(const char* fileName)
    {
        RefPtr<SharedBuffer> imageData = readFile(fileName);
        ASSERT_TRUE(imageData.get());

        m_image->setData(imageData, true);
        EXPECT_EQ(0u, decodedSize());

        size_t frameCount = m_image->frameCount();
        for (size_t i = 0; i < frameCount; ++i)
            m_image->frameAtIndex(i);
    }

    size_t decodedSize()
    {
        // In the context of this test, the following loop will give the correct result, but only because the test
        // forces all frames to be decoded in loadImage() above. There is no general guarantee that frameDecodedSize()
        // is up-to-date. Because of how multi frame images (like GIF) work, requesting one frame to be decoded may
        // require other previous frames to be decoded as well. In those cases frameDecodedSize() wouldn't return the
        // correct thing for the previous frame because the decoded size wouldn't have propagated upwards to the
        // BitmapImage frame cache.
        size_t size = 0;
        for (size_t i = 0; i < decodedFramesCount(); ++i)
            size += frameDecodedSize(i);
        return size;
    }

    void advanceAnimation()
    {
        m_image->advanceAnimation(0);
    }

protected:
    virtual void SetUp() override
    {
        DeferredImageDecoder::setEnabled(false);
        m_image = BitmapImage::create(&m_imageObserver);
    }

    FakeImageObserver m_imageObserver;
    RefPtr<BitmapImage> m_image;
};

TEST_F(BitmapImageTest, destroyDecodedDataExceptCurrentFrame)
{
    loadImage("/tests/fast/images/resources/animated-10color.gif");
    size_t totalSize = decodedSize();
    size_t frame = frameCount() / 2;
    setCurrentFrame(frame);
    size_t size = frameDecodedSize(frame);
    destroyDecodedData(false);
    EXPECT_LT(m_imageObserver.m_lastDecodedSizeChangedDelta, 0);
    EXPECT_GE(m_imageObserver.m_lastDecodedSizeChangedDelta, -static_cast<int>(totalSize - size));
}

TEST_F(BitmapImageTest, destroyAllDecodedData)
{
    loadImage("/tests/fast/images/resources/animated-10color.gif");
    size_t totalSize = decodedSize();
    EXPECT_GT(totalSize, 0u);
    destroyDecodedData(true);
    EXPECT_EQ(-static_cast<int>(totalSize), m_imageObserver.m_lastDecodedSizeChangedDelta);
    EXPECT_EQ(0u, decodedSize());
}

TEST_F(BitmapImageTest, maybeAnimated)
{
    loadImage("/tests/fast/images/resources/gif-loop-count.gif");
    for (size_t i = 0; i < frameCount(); ++i) {
        EXPECT_TRUE(m_image->maybeAnimated());
        advanceAnimation();
    }
    EXPECT_FALSE(m_image->maybeAnimated());
}

TEST_F(BitmapImageTest, isAllDataReceived)
{
    RefPtr<SharedBuffer> imageData = readFile("/tests/fast/images/resources/green.jpg");
    ASSERT_TRUE(imageData.get());

    RefPtr<BitmapImage> image = BitmapImage::create();
    EXPECT_FALSE(image->isAllDataReceived());

    image->setData(imageData, false);
    EXPECT_FALSE(image->isAllDataReceived());

    image->setData(imageData, true);
    EXPECT_TRUE(image->isAllDataReceived());

    image->setData(SharedBuffer::create("data", sizeof("data")), false);
    EXPECT_FALSE(image->isAllDataReceived());

    image->setData(imageData, true);
    EXPECT_TRUE(image->isAllDataReceived());
}

#if USE(QCMSLIB)

TEST_F(BitmapImageTest, jpegHasColorProfile)
{
    loadImage("/tests/fast/images/resources/icc-v2-gbr.jpg");
    EXPECT_EQ(1u, decodedFramesCount());
    EXPECT_EQ(227700u, decodedSize());
    EXPECT_TRUE(m_image->hasColorProfile());

    resetDecoder();
    destroyDecodedData(true);

    loadImage("/tests/fast/images/resources/green.jpg");
    EXPECT_EQ(1u, decodedFramesCount());
    EXPECT_EQ(1024u, decodedSize());
    EXPECT_FALSE(m_image->hasColorProfile());
}

TEST_F(BitmapImageTest, pngHasColorProfile)
{
    loadImage("/tests/fast/images/resources/palatted-color-png-gamma-one-color-profile.png");
    EXPECT_EQ(1u, decodedFramesCount());
    EXPECT_EQ(65536u, decodedSize());
    EXPECT_TRUE(m_image->hasColorProfile());

    resetDecoder();
    destroyDecodedData(true);

    loadImage("/tests/fast/images/resources/green.jpg");
    EXPECT_EQ(1u, decodedFramesCount());
    EXPECT_EQ(1024u, decodedSize());
    EXPECT_FALSE(m_image->hasColorProfile());
}

#endif // USE(QCMSLIB)

} // namespace blink
