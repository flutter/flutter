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

#include "platform/graphics/ThreadSafeDataTransport.h"

#include "platform/SharedBuffer.h"
#include <gtest/gtest.h>

using namespace blink;

namespace {

TEST(ThreadSafeDataTransportTest, hasNewData)
{
    ThreadSafeDataTransport transport;

    const char testString[] = "123456789";
    RefPtr<SharedBuffer> buffer = SharedBuffer::create(testString, sizeof(testString));

    transport.setData(buffer.get(), false);
    EXPECT_TRUE(transport.hasNewData());

    SharedBuffer* tempBuffer = 0;
    bool allDataReceived = false;
    transport.data(&tempBuffer, &allDataReceived);
    EXPECT_FALSE(transport.hasNewData());

    transport.setData(buffer.get(), false);
    EXPECT_FALSE(transport.hasNewData());
}

TEST(ThreadSafeDataTransportTest, setData)
{
    ThreadSafeDataTransport transport;

    const char testString1[] = "123";
    RefPtr<SharedBuffer> buffer1 = SharedBuffer::create(testString1, sizeof(testString1) - 1);
    const char testString2[] = "12345";
    RefPtr<SharedBuffer> buffer2 = SharedBuffer::create(testString2, sizeof(testString2) - 1);
    const char testString3[] = "1234567890";
    RefPtr<SharedBuffer> buffer3 = SharedBuffer::create(testString3, sizeof(testString3) - 1);

    transport.setData(buffer1.get(), false);
    transport.setData(buffer2.get(), false);
    transport.setData(buffer3.get(), true);
    EXPECT_TRUE(transport.hasNewData());

    SharedBuffer* tempBuffer = 0;
    bool allDataReceived = false;
    transport.data(&tempBuffer, &allDataReceived);
    EXPECT_TRUE(allDataReceived);
    EXPECT_FALSE(memcmp(testString3, tempBuffer->data(), tempBuffer->size()));
}

} // namespace
