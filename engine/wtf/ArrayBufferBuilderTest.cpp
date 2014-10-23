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
#include "wtf/ArrayBufferBuilder.h"

#include "wtf/Assertions.h"
#include <gtest/gtest.h>
#include <limits.h>
#include <string.h>

namespace WTF {

TEST(ArrayBufferBuilderTest, Constructor)
{
    ArrayBufferBuilder zeroBuilder(0);
    EXPECT_EQ(0u, zeroBuilder.byteLength());
    EXPECT_EQ(0u, zeroBuilder.capacity());

    ArrayBufferBuilder smallBuilder(1024);
    EXPECT_EQ(0u, zeroBuilder.byteLength());
    EXPECT_EQ(1024u, smallBuilder.capacity());

    ArrayBufferBuilder bigBuilder(2048);
    EXPECT_EQ(0u, zeroBuilder.byteLength());
    EXPECT_EQ(2048u, bigBuilder.capacity());
}

TEST(ArrayBufferBuilderTest, Append)
{
    const char data[] = "HelloWorld";
    size_t dataSize = sizeof(data) - 1;

    ArrayBufferBuilder builder(2 * dataSize);

    EXPECT_EQ(dataSize, builder.append(data, dataSize));
    EXPECT_EQ(dataSize, builder.byteLength());
    EXPECT_EQ(dataSize * 2, builder.capacity());

    EXPECT_EQ(dataSize, builder.append(data, dataSize));
    EXPECT_EQ(dataSize * 2, builder.byteLength());
    EXPECT_EQ(dataSize * 2, builder.capacity());

    EXPECT_EQ(dataSize, builder.append(data, dataSize));
    EXPECT_EQ(dataSize * 3, builder.byteLength());
    EXPECT_GE(builder.capacity(), dataSize * 3);
}

TEST(ArrayBufferBuilderTest, AppendRepeatedly)
{
    const char data[] = "HelloWorld";
    size_t dataSize = sizeof(data) - 1;

    ArrayBufferBuilder builder(37); // Some number coprime with dataSize.

    for (size_t i = 1; i < 1000U; ++i) {
        EXPECT_EQ(dataSize, builder.append(data, dataSize));
        EXPECT_EQ(dataSize * i, builder.byteLength());
        EXPECT_GE(builder.capacity(), dataSize * i);
    }
}

TEST(ArrayBufferBuilderTest, DefaultConstructorAndAppendRepeatedly)
{
    const char data[] = "HelloWorld";
    size_t dataSize = sizeof(data) - 1;

    ArrayBufferBuilder builder;

    for (size_t i = 1; i < 4000U; ++i) {
        EXPECT_EQ(dataSize, builder.append(data, dataSize));
        EXPECT_EQ(dataSize * i, builder.byteLength());
        EXPECT_GE(builder.capacity(), dataSize * i);
    }
}

TEST(ArrayBufferBuilderTest, AppendFixedCapacity)
{
    const char data[] = "HelloWorld";
    size_t dataSize = sizeof(data) - 1;

    ArrayBufferBuilder builder(15);
    builder.setVariableCapacity(false);

    EXPECT_EQ(dataSize, builder.append(data, dataSize));
    EXPECT_EQ(dataSize, builder.byteLength());
    EXPECT_EQ(15u, builder.capacity());

    EXPECT_EQ(5u, builder.append(data, dataSize));
    EXPECT_EQ(15u, builder.byteLength());
    EXPECT_EQ(15u, builder.capacity());

    EXPECT_EQ(0u, builder.append(data, dataSize));
    EXPECT_EQ(15u, builder.byteLength());
    EXPECT_EQ(15u, builder.capacity());
}

TEST(ArrayBufferBuilderTest, ToArrayBuffer)
{
    const char data1[] = "HelloWorld";
    size_t data1Size = sizeof(data1) - 1;

    const char data2[] = "GoodbyeWorld";
    size_t data2Size = sizeof(data2) - 1;

    ArrayBufferBuilder builder(1024);
    builder.append(data1, data1Size);
    builder.append(data2, data2Size);

    const char expected[] = "HelloWorldGoodbyeWorld";
    size_t expectedSize = sizeof(expected) - 1;

    RefPtr<ArrayBuffer> result = builder.toArrayBuffer();
    ASSERT_EQ(data1Size + data2Size, result->byteLength());
    ASSERT_EQ(expectedSize, result->byteLength());
    EXPECT_EQ(0, memcmp(expected, result->data(), expectedSize));
}

TEST(ArrayBufferBuilderTest, ToArrayBufferSameAddressIfExactCapacity)
{
    const char data[] = "HelloWorld";
    size_t dataSize = sizeof(data) - 1;

    ArrayBufferBuilder builder(dataSize);
    builder.append(data, dataSize);

    RefPtr<ArrayBuffer> result1 = builder.toArrayBuffer();
    RefPtr<ArrayBuffer> result2 = builder.toArrayBuffer();
    EXPECT_EQ(result1.get(), result2.get());
}

TEST(ArrayBufferBuilderTest, ToString)
{
    const char data1[] = "HelloWorld";
    size_t data1Size = sizeof(data1) - 1;

    const char data2[] = "GoodbyeWorld";
    size_t data2Size = sizeof(data2) - 1;

    ArrayBufferBuilder builder(1024);
    builder.append(data1, data1Size);
    builder.append(data2, data2Size);

    const char expected[] = "HelloWorldGoodbyeWorld";
    size_t expectedSize = sizeof(expected) - 1;

    String result = builder.toString();
    EXPECT_EQ(expectedSize, result.length());
    for (unsigned i = 0; i < result.length(); ++i)
        EXPECT_EQ(expected[i], result[i]);
}

TEST(ArrayBufferBuilderTest, ShrinkToFitNoAppend)
{
    ArrayBufferBuilder builder(1024);
    EXPECT_EQ(1024u, builder.capacity());
    builder.shrinkToFit();
    EXPECT_EQ(0u, builder.byteLength());
    EXPECT_EQ(0u, builder.capacity());
}

TEST(ArrayBufferBuilderTest, ShrinkToFit)
{
    const char data[] = "HelloWorld";
    size_t dataSize = sizeof(data) - 1;

    ArrayBufferBuilder builder(32);

    EXPECT_EQ(dataSize, builder.append(data, dataSize));
    EXPECT_EQ(dataSize, builder.byteLength());
    EXPECT_EQ(32u, builder.capacity());

    builder.shrinkToFit();
    EXPECT_EQ(dataSize, builder.byteLength());
    EXPECT_EQ(dataSize, builder.capacity());
}

TEST(ArrayBufferBuilderTest, ShrinkToFitFullyUsed)
{
    const char data[] = "HelloWorld";
    size_t dataSize = sizeof(data) - 1;

    ArrayBufferBuilder builder(dataSize);
    const void* internalAddress = builder.data();

    EXPECT_EQ(dataSize, builder.append(data, dataSize));
    EXPECT_EQ(dataSize, builder.byteLength());
    EXPECT_EQ(dataSize, builder.capacity());

    builder.shrinkToFit();
    // Reallocation should not happen.
    EXPECT_EQ(internalAddress, builder.data());
    EXPECT_EQ(dataSize, builder.byteLength());
    EXPECT_EQ(dataSize, builder.capacity());
}

TEST(ArrayBufferBuilderTest, ShrinkToFitAfterGrowth)
{
    const char data[] = "HelloWorld";
    size_t dataSize = sizeof(data) - 1;

    ArrayBufferBuilder builder(5);

    EXPECT_EQ(dataSize, builder.append(data, dataSize));
    EXPECT_GE(builder.capacity(), dataSize);
    builder.shrinkToFit();
    EXPECT_EQ(dataSize, builder.byteLength());
    EXPECT_EQ(dataSize, builder.capacity());
}

} // namespace WTF
