/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
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

#include "platform/image-decoders/ImageDecoder.h"

#include "platform/image-decoders/ImageFrame.h"
#include "wtf/OwnPtr.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/Vector.h"
#include <gtest/gtest.h>

using namespace blink;

class TestImageDecoder : public ImageDecoder {
public:
    TestImageDecoder()
        : ImageDecoder(ImageSource::AlphaNotPremultiplied, ImageSource::GammaAndColorProfileApplied, noDecodedImageByteLimit)
    {
    }

    virtual String filenameExtension() const override { return ""; }
    virtual ImageFrame* frameBufferAtIndex(size_t) override { return 0; }

    Vector<ImageFrame, 1>& frameBufferCache()
    {
        return m_frameBufferCache;
    }

    void resetRequiredPreviousFrames(bool knownOpaque = false)
    {
        for (size_t i = 0; i < m_frameBufferCache.size(); ++i)
            m_frameBufferCache[i].setRequiredPreviousFrameIndex(findRequiredPreviousFrame(i, knownOpaque));
    }

    void initFrames(size_t numFrames, unsigned width = 100, unsigned height = 100)
    {
        setSize(width, height);
        m_frameBufferCache.resize(numFrames);
        for (size_t i = 0; i < numFrames; ++i)
            m_frameBufferCache[i].setOriginalFrameRect(IntRect(0, 0, width, height));
    }
};

TEST(ImageDecoderTest, sizeCalculationMayOverflow)
{
    OwnPtr<TestImageDecoder> decoder(adoptPtr(new TestImageDecoder()));
    EXPECT_FALSE(decoder->setSize(1 << 29, 1));
    EXPECT_FALSE(decoder->setSize(1, 1 << 29));
    EXPECT_FALSE(decoder->setSize(1 << 15, 1 << 15));
    EXPECT_TRUE(decoder->setSize(1 << 28, 1));
    EXPECT_TRUE(decoder->setSize(1, 1 << 28));
    EXPECT_TRUE(decoder->setSize(1 << 14, 1 << 14));
}

TEST(ImageDecoderTest, requiredPreviousFrameIndex)
{
    OwnPtr<TestImageDecoder> decoder(adoptPtr(new TestImageDecoder()));
    decoder->initFrames(6);
    Vector<ImageFrame, 1>& frameBuffers = decoder->frameBufferCache();

    frameBuffers[1].setDisposalMethod(ImageFrame::DisposeKeep);
    frameBuffers[2].setDisposalMethod(ImageFrame::DisposeOverwritePrevious);
    frameBuffers[3].setDisposalMethod(ImageFrame::DisposeOverwritePrevious);
    frameBuffers[4].setDisposalMethod(ImageFrame::DisposeKeep);

    decoder->resetRequiredPreviousFrames();

    // The first frame doesn't require any previous frame.
    EXPECT_EQ(kNotFound, frameBuffers[0].requiredPreviousFrameIndex());
    // The previous DisposeNotSpecified frame is required.
    EXPECT_EQ(0u, frameBuffers[1].requiredPreviousFrameIndex());
    // DisposeKeep is treated as DisposeNotSpecified.
    EXPECT_EQ(1u, frameBuffers[2].requiredPreviousFrameIndex());
    // Previous DisposeOverwritePrevious frames are skipped.
    EXPECT_EQ(1u, frameBuffers[3].requiredPreviousFrameIndex());
    EXPECT_EQ(1u, frameBuffers[4].requiredPreviousFrameIndex());
    EXPECT_EQ(4u, frameBuffers[5].requiredPreviousFrameIndex());
}

TEST(ImageDecoderTest, requiredPreviousFrameIndexDisposeOverwriteBgcolor)
{
    OwnPtr<TestImageDecoder> decoder(adoptPtr(new TestImageDecoder()));
    decoder->initFrames(3);
    Vector<ImageFrame, 1>& frameBuffers = decoder->frameBufferCache();

    // Fully covering DisposeOverwriteBgcolor previous frame resets the starting state.
    frameBuffers[1].setDisposalMethod(ImageFrame::DisposeOverwriteBgcolor);
    decoder->resetRequiredPreviousFrames();
    EXPECT_EQ(kNotFound, frameBuffers[2].requiredPreviousFrameIndex());

    // Partially covering DisposeOverwriteBgcolor previous frame is required by this frame.
    frameBuffers[1].setOriginalFrameRect(IntRect(50, 50, 50, 50));
    decoder->resetRequiredPreviousFrames();
    EXPECT_EQ(1u, frameBuffers[2].requiredPreviousFrameIndex());
}

TEST(ImageDecoderTest, requiredPreviousFrameIndexForFrame1)
{
    OwnPtr<TestImageDecoder> decoder(adoptPtr(new TestImageDecoder()));
    decoder->initFrames(2);
    Vector<ImageFrame, 1>& frameBuffers = decoder->frameBufferCache();

    decoder->resetRequiredPreviousFrames();
    EXPECT_EQ(0u, frameBuffers[1].requiredPreviousFrameIndex());

    // The first frame with DisposeOverwritePrevious or DisposeOverwriteBgcolor
    // resets the starting state.
    frameBuffers[0].setDisposalMethod(ImageFrame::DisposeOverwritePrevious);
    decoder->resetRequiredPreviousFrames();
    EXPECT_EQ(kNotFound, frameBuffers[1].requiredPreviousFrameIndex());
    frameBuffers[0].setDisposalMethod(ImageFrame::DisposeOverwriteBgcolor);
    decoder->resetRequiredPreviousFrames();
    EXPECT_EQ(kNotFound, frameBuffers[1].requiredPreviousFrameIndex());

    // ... even if it partially covers.
    frameBuffers[0].setOriginalFrameRect(IntRect(50, 50, 50, 50));

    frameBuffers[0].setDisposalMethod(ImageFrame::DisposeOverwritePrevious);
    decoder->resetRequiredPreviousFrames();
    EXPECT_EQ(kNotFound, frameBuffers[1].requiredPreviousFrameIndex());
    frameBuffers[0].setDisposalMethod(ImageFrame::DisposeOverwriteBgcolor);
    decoder->resetRequiredPreviousFrames();
    EXPECT_EQ(kNotFound, frameBuffers[1].requiredPreviousFrameIndex());
}

TEST(ImageDecoderTest, requiredPreviousFrameIndexBlendAtopBgcolor)
{
    OwnPtr<TestImageDecoder> decoder(adoptPtr(new TestImageDecoder()));
    decoder->initFrames(3);
    Vector<ImageFrame, 1>& frameBuffers = decoder->frameBufferCache();

    frameBuffers[1].setOriginalFrameRect(IntRect(25, 25, 50, 50));
    frameBuffers[2].setAlphaBlendSource(ImageFrame::BlendAtopBgcolor);

    // A full frame with 'blending method == BlendAtopBgcolor' doesn't depend on any prior frames.
    for (int disposeMethod = ImageFrame::DisposeNotSpecified; disposeMethod <= ImageFrame::DisposeOverwritePrevious; ++disposeMethod) {
        frameBuffers[1].setDisposalMethod(static_cast<ImageFrame::DisposalMethod>(disposeMethod));
        decoder->resetRequiredPreviousFrames();
        EXPECT_EQ(kNotFound, frameBuffers[2].requiredPreviousFrameIndex());
    }

    // A non-full frame with 'blending method == BlendAtopBgcolor' does depend on a prior frame.
    frameBuffers[2].setOriginalFrameRect(IntRect(50, 50, 50, 50));
    for (int disposeMethod = ImageFrame::DisposeNotSpecified; disposeMethod <= ImageFrame::DisposeOverwritePrevious; ++disposeMethod) {
        frameBuffers[1].setDisposalMethod(static_cast<ImageFrame::DisposalMethod>(disposeMethod));
        decoder->resetRequiredPreviousFrames();
        EXPECT_NE(kNotFound, frameBuffers[2].requiredPreviousFrameIndex());
    }
}

TEST(ImageDecoderTest, requiredPreviousFrameIndexKnownOpaque)
{
    OwnPtr<TestImageDecoder> decoder(adoptPtr(new TestImageDecoder()));
    decoder->initFrames(3);
    Vector<ImageFrame, 1>& frameBuffers = decoder->frameBufferCache();

    frameBuffers[1].setOriginalFrameRect(IntRect(25, 25, 50, 50));

    // A full frame that is known to be opaque doesn't depend on any prior frames.
    for (int disposeMethod = ImageFrame::DisposeNotSpecified; disposeMethod <= ImageFrame::DisposeOverwritePrevious; ++disposeMethod) {
        frameBuffers[1].setDisposalMethod(static_cast<ImageFrame::DisposalMethod>(disposeMethod));
        decoder->resetRequiredPreviousFrames(true);
        EXPECT_EQ(kNotFound, frameBuffers[2].requiredPreviousFrameIndex());
    }

    // A non-full frame that is known to be opaque does depend on a prior frame.
    frameBuffers[2].setOriginalFrameRect(IntRect(50, 50, 50, 50));
    for (int disposeMethod = ImageFrame::DisposeNotSpecified; disposeMethod <= ImageFrame::DisposeOverwritePrevious; ++disposeMethod) {
        frameBuffers[1].setDisposalMethod(static_cast<ImageFrame::DisposalMethod>(disposeMethod));
        decoder->resetRequiredPreviousFrames(true);
        EXPECT_NE(kNotFound, frameBuffers[2].requiredPreviousFrameIndex());
    }
}

TEST(ImageDecoderTest, clearCacheExceptFrameDoNothing)
{
    OwnPtr<TestImageDecoder> decoder(adoptPtr(new TestImageDecoder()));
    decoder->clearCacheExceptFrame(0);

    // This should not crash.
    decoder->initFrames(20);
    decoder->clearCacheExceptFrame(kNotFound);
}

TEST(ImageDecoderTest, clearCacheExceptFrameAll)
{
    const size_t numFrames = 10;
    OwnPtr<TestImageDecoder> decoder(adoptPtr(new TestImageDecoder()));
    decoder->initFrames(numFrames);
    Vector<ImageFrame, 1>& frameBuffers = decoder->frameBufferCache();
    for (size_t i = 0; i < numFrames; ++i)
        frameBuffers[i].setStatus(i % 2 ? ImageFrame::FramePartial : ImageFrame::FrameComplete);

    decoder->clearCacheExceptFrame(kNotFound);

    for (size_t i = 0; i < numFrames; ++i) {
        SCOPED_TRACE(testing::Message() << i);
        EXPECT_EQ(ImageFrame::FrameEmpty, frameBuffers[i].status());
    }
}

TEST(ImageDecoderTest, clearCacheExceptFramePreverveClearExceptFrame)
{
    const size_t numFrames = 10;
    OwnPtr<TestImageDecoder> decoder(adoptPtr(new TestImageDecoder()));
    decoder->initFrames(numFrames);
    Vector<ImageFrame, 1>& frameBuffers = decoder->frameBufferCache();
    for (size_t i = 0; i < numFrames; ++i)
        frameBuffers[i].setStatus(ImageFrame::FrameComplete);

    decoder->resetRequiredPreviousFrames();
    decoder->clearCacheExceptFrame(5);
    for (size_t i = 0; i < numFrames; ++i) {
        SCOPED_TRACE(testing::Message() << i);
        if (i == 5)
            EXPECT_EQ(ImageFrame::FrameComplete, frameBuffers[i].status());
        else
            EXPECT_EQ(ImageFrame::FrameEmpty, frameBuffers[i].status());
    }
}
