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

#include "platform/image-decoders/jpeg/JPEGImageDecoder.h"

#include "platform/SharedBuffer.h"
#include "public/platform/Platform.h"
#include "public/platform/WebData.h"
#include "public/platform/WebSize.h"
#include "public/platform/WebUnitTestSupport.h"
#include "wtf/OwnPtr.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/StringHasher.h"

#include <gtest/gtest.h>

using namespace blink;

static const size_t LargeEnoughSize = 1000 * 1000;

namespace {

PassRefPtr<SharedBuffer> readFile(const char* fileName)
{
    String filePath = Platform::current()->unitTestSupport()->webKitRootDir();
    filePath.append(fileName);

    return Platform::current()->unitTestSupport()->readFromFile(filePath);
}

PassOwnPtr<JPEGImageDecoder> createDecoder(size_t maxDecodedBytes)
{
    return adoptPtr(new JPEGImageDecoder(ImageSource::AlphaNotPremultiplied, ImageSource::GammaAndColorProfileApplied, maxDecodedBytes));
}

} // namespace

void downsample(size_t maxDecodedBytes, unsigned* outputWidth, unsigned* outputHeight, const char* imageFilePath)
{
    RefPtr<SharedBuffer> data = readFile(imageFilePath);
    ASSERT_TRUE(data.get());

    OwnPtr<JPEGImageDecoder> decoder = createDecoder(maxDecodedBytes);
    decoder->setData(data.get(), true);

    ImageFrame* frame = decoder->frameBufferAtIndex(0);
    ASSERT_TRUE(frame);
    *outputWidth = frame->getSkBitmap().width();
    *outputHeight = frame->getSkBitmap().height();
    EXPECT_EQ(IntSize(*outputWidth, *outputHeight), decoder->decodedSize());
}

void readYUV(size_t maxDecodedBytes, unsigned* outputYWidth, unsigned* outputYHeight, unsigned* outputUVWidth, unsigned* outputUVHeight, const char* imageFilePath)
{
    RefPtr<SharedBuffer> data = readFile(imageFilePath);
    ASSERT_TRUE(data.get());

    OwnPtr<JPEGImageDecoder> decoder = createDecoder(maxDecodedBytes);
    decoder->setData(data.get(), true);

    OwnPtr<ImagePlanes> imagePlanes = adoptPtr(new ImagePlanes());
    decoder->setImagePlanes(imagePlanes.release());
    bool sizeIsAvailable = decoder->isSizeAvailable();
    ASSERT_TRUE(sizeIsAvailable);

    IntSize size = decoder->decodedSize();
    IntSize ySize = decoder->decodedYUVSize(0);
    IntSize uSize = decoder->decodedYUVSize(1);
    IntSize vSize = decoder->decodedYUVSize(2);

    ASSERT_TRUE(size.width() == ySize.width());
    ASSERT_TRUE(size.height() == ySize.height());
    ASSERT_TRUE(uSize.width() == vSize.width());
    ASSERT_TRUE(uSize.height() == vSize.height());

    *outputYWidth = ySize.width();
    *outputYHeight = ySize.height();
    *outputUVWidth = uSize.width();
    *outputUVHeight = uSize.height();
}

// Tests failure on a too big image.
TEST(JPEGImageDecoderTest, tooBig)
{
    OwnPtr<JPEGImageDecoder> decoder = createDecoder(100);
    EXPECT_FALSE(decoder->setSize(10000, 10000));
    EXPECT_TRUE(decoder->failed());
}

// Tests that JPEG decoder can downsample image whose width and height are multiple of 8,
// to ensure we compute the correct decodedSize and pass correct parameters to libjpeg to
// output image with the expected size.
TEST(JPEGImageDecoderTest, downsampleImageSizeMultipleOf8)
{
    const char* jpegFile = "/tests/fast/images/resources/lenna.jpg"; // 256x256
    unsigned outputWidth, outputHeight;

    // 1/8 downsample.
    downsample(40 * 40 * 4, &outputWidth, &outputHeight, jpegFile);
    EXPECT_EQ(32u, outputWidth);
    EXPECT_EQ(32u, outputHeight);

    // 2/8 downsample.
    downsample(70 * 70 * 4, &outputWidth, &outputHeight, jpegFile);
    EXPECT_EQ(64u, outputWidth);
    EXPECT_EQ(64u, outputHeight);

    // 3/8 downsample.
    downsample(100 * 100 * 4, &outputWidth, &outputHeight, jpegFile);
    EXPECT_EQ(96u, outputWidth);
    EXPECT_EQ(96u, outputHeight);

    // 4/8 downsample.
    downsample(130 * 130 * 4, &outputWidth, &outputHeight, jpegFile);
    EXPECT_EQ(128u, outputWidth);
    EXPECT_EQ(128u, outputHeight);

    // 5/8 downsample.
    downsample(170 * 170 * 4, &outputWidth, &outputHeight, jpegFile);
    EXPECT_EQ(160u, outputWidth);
    EXPECT_EQ(160u, outputHeight);

    // 6/8 downsample.
    downsample(200 * 200 * 4, &outputWidth, &outputHeight, jpegFile);
    EXPECT_EQ(192u, outputWidth);
    EXPECT_EQ(192u, outputHeight);

    // 7/8 downsample.
    downsample(230 * 230 * 4, &outputWidth, &outputHeight, jpegFile);
    EXPECT_EQ(224u, outputWidth);
    EXPECT_EQ(224u, outputHeight);
}

// Tests that JPEG decoder can downsample image whose width and height are not multiple of 8.
// Ensures that we round decodedSize and scale_num using the same algorithm as that of libjpeg.
TEST(JPEGImageDecoderTest, downsampleImageSizeNotMultipleOf8)
{
    const char* jpegFile = "/tests/fast/images/resources/icc-v2-gbr.jpg"; // 275x207
    unsigned outputWidth, outputHeight;

    // 1/8 downsample.
    downsample(40 * 40 * 4, &outputWidth, &outputHeight, jpegFile);
    EXPECT_EQ(35u, outputWidth);
    EXPECT_EQ(26u, outputHeight);

    // 2/8 downsample.
    downsample(70 * 70 * 4, &outputWidth, &outputHeight, jpegFile);
    EXPECT_EQ(69u, outputWidth);
    EXPECT_EQ(52u, outputHeight);

    // 3/8 downsample.
    downsample(100 * 100 * 4, &outputWidth, &outputHeight, jpegFile);
    EXPECT_EQ(104u, outputWidth);
    EXPECT_EQ(78u, outputHeight);

    // 4/8 downsample.
    downsample(130 * 130 * 4, &outputWidth, &outputHeight, jpegFile);
    EXPECT_EQ(138u, outputWidth);
    EXPECT_EQ(104u, outputHeight);

    // 5/8 downsample.
    downsample(170 * 170 * 4, &outputWidth, &outputHeight, jpegFile);
    EXPECT_EQ(172u, outputWidth);
    EXPECT_EQ(130u, outputHeight);

    // 6/8 downsample.
    downsample(200 * 200 * 4, &outputWidth, &outputHeight, jpegFile);
    EXPECT_EQ(207u, outputWidth);
    EXPECT_EQ(156u, outputHeight);

    // 7/8 downsample.
    downsample(230 * 230 * 4, &outputWidth, &outputHeight, jpegFile);
    EXPECT_EQ(241u, outputWidth);
    EXPECT_EQ(182u, outputHeight);
}

// Tests that upsampling is not allowed.
TEST(JPEGImageDecoderTest, upsample)
{
    const char* jpegFile = "/tests/fast/images/resources/lenna.jpg"; // 256x256
    unsigned outputWidth, outputHeight;
    downsample(LargeEnoughSize, &outputWidth, &outputHeight, jpegFile);
    EXPECT_EQ(256u, outputWidth);
    EXPECT_EQ(256u, outputHeight);
}

TEST(JPEGImageDecoderTest, yuv)
{
    const char* jpegFile = "/tests/fast/images/resources/lenna.jpg"; // 256x256, YUV 4:2:0
    unsigned outputYWidth, outputYHeight, outputUVWidth, outputUVHeight;
    readYUV(LargeEnoughSize, &outputYWidth, &outputYHeight, &outputUVWidth, &outputUVHeight, jpegFile);
    EXPECT_EQ(256u, outputYWidth);
    EXPECT_EQ(256u, outputYHeight);
    EXPECT_EQ(128u, outputUVWidth);
    EXPECT_EQ(128u, outputUVHeight);
}
