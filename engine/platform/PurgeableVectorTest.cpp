/*
 * Copyright (C) 2014 Google Inc. All rights reserved.
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
#include "platform/PurgeableVector.h"

#include "platform/TestingPlatformSupport.h"
#include "public/platform/WebDiscardableMemory.h"
#include "wtf/Vector.h"

#include <algorithm>
#include <cstdlib>

#include <gtest/gtest.h>

using namespace blink;

namespace {

const size_t kTestSize = 32 * 1024;

enum DiscardableMemorySupport {
    DontSupportDiscardableMemory,
    SupportDiscardableMemory,
};

class PurgeableVectorTestWithPlatformSupport : public testing::TestWithParam<DiscardableMemorySupport> {
public:
    PurgeableVectorTestWithPlatformSupport() : m_testingPlatformSupport(makeTestingPlatformSupportConfig()) { }

protected:
    bool isDiscardableMemorySupported() const { return GetParam() == SupportDiscardableMemory; }

    TestingPlatformSupport::Config makeTestingPlatformSupportConfig() const
    {
        TestingPlatformSupport::Config config;
        config.hasDiscardableMemorySupport = isDiscardableMemorySupported();
        return config;
    }

    PurgeableVector::PurgeableOption makePurgeableOption() const
    {
        return isDiscardableMemorySupported() ? PurgeableVector::Purgeable : PurgeableVector::NotPurgeable;
    }

private:
    TestingPlatformSupport m_testingPlatformSupport;
};

TEST_P(PurgeableVectorTestWithPlatformSupport, grow)
{
    PurgeableVector purgeableVector(makePurgeableOption());
    purgeableVector.grow(kTestSize);
    ASSERT_EQ(kTestSize, purgeableVector.size());
    // Make sure the underlying buffer was actually (re)allocated.
    memset(purgeableVector.data(), 0, purgeableVector.size());
}

TEST_P(PurgeableVectorTestWithPlatformSupport, clear)
{
    Vector<char> testData(kTestSize);
    std::generate(testData.begin(), testData.end(), &std::rand);

    PurgeableVector purgeableVector(makePurgeableOption());
    purgeableVector.append(testData.data(), testData.size());
    EXPECT_EQ(testData.size(), purgeableVector.size());

    purgeableVector.clear();
    EXPECT_EQ(0U, purgeableVector.size());
    EXPECT_EQ(0, purgeableVector.data());
}

TEST_P(PurgeableVectorTestWithPlatformSupport, clearDoesNotResetLockCounter)
{
    PurgeableVector purgeableVector(makePurgeableOption());
    purgeableVector.clear();
    EXPECT_TRUE(purgeableVector.isLocked());
    purgeableVector.unlock();
    EXPECT_FALSE(purgeableVector.isLocked());
}

TEST_P(PurgeableVectorTestWithPlatformSupport, reserveCapacityDoesNotChangeSize)
{
    PurgeableVector purgeableVector(makePurgeableOption());
    EXPECT_EQ(0U, purgeableVector.size());
    purgeableVector.reserveCapacity(kTestSize);
    EXPECT_EQ(0U, purgeableVector.size());
}

TEST_P(PurgeableVectorTestWithPlatformSupport, multipleAppends)
{
    Vector<char> testData(kTestSize);
    std::generate(testData.begin(), testData.end(), &std::rand);

    PurgeableVector purgeableVector(makePurgeableOption());
    // Force an allocation.
    const char kSmallString[] = "hello";
    purgeableVector.append(kSmallString, sizeof(kSmallString));
    const char* const data = purgeableVector.data();

    // Append all the testing data in 4 iterations. The |data| pointer should
    // have been changed at the end of the unit test due to reallocations.
    const size_t kIterationCount = 4;
    ASSERT_EQ(0U, testData.size() % kIterationCount);
    for (size_t i = 0; i < kIterationCount; ++i) {
        const char* const testDataStart = testData.data() + i * (testData.size() / kIterationCount);
        purgeableVector.append(testDataStart, testData.size() / kIterationCount);
        ASSERT_EQ((i + 1) * testData.size() / kIterationCount, purgeableVector.size() - sizeof(kSmallString));
    }

    ASSERT_EQ(sizeof(kSmallString) + testData.size(), purgeableVector.size());
    EXPECT_NE(data, purgeableVector.data());
    EXPECT_EQ(0, memcmp(purgeableVector.data() + sizeof(kSmallString), testData.data(), testData.size()));
}

TEST_P(PurgeableVectorTestWithPlatformSupport, multipleAppendsAfterReserveCapacity)
{
    Vector<char> testData(kTestSize);
    std::generate(testData.begin(), testData.end(), &std::rand);

    PurgeableVector purgeableVector(makePurgeableOption());
    purgeableVector.reserveCapacity(testData.size());
    const char* const data = purgeableVector.data();

    // The |data| pointer should be unchanged at the end of the unit test
    // meaning that there should not have been any reallocation.
    const size_t kIterationCount = 4;
    ASSERT_EQ(0U, testData.size() % kIterationCount);
    for (size_t i = 0; i < kIterationCount; ++i) {
        const char* const testDataStart = testData.data() + i * (testData.size() / kIterationCount);
        purgeableVector.append(testDataStart, testData.size() / kIterationCount);
        ASSERT_EQ((i + 1) * testData.size() / kIterationCount, purgeableVector.size());
    }

    ASSERT_EQ(testData.size(), purgeableVector.size());
    EXPECT_EQ(data, purgeableVector.data());
    EXPECT_EQ(0, memcmp(purgeableVector.data(), testData.data(), testData.size()));
}

TEST_P(PurgeableVectorTestWithPlatformSupport, reserveCapacityUsesExactCapacityWhenVectorIsEmpty)
{
    Vector<char> testData(kTestSize);
    std::generate(testData.begin(), testData.end(), &std::rand);

    PurgeableVector purgeableVector(makePurgeableOption());
    purgeableVector.reserveCapacity(kTestSize);
    const char* const data = purgeableVector.data();

    purgeableVector.append(testData.data(), testData.size());
    EXPECT_EQ(data, purgeableVector.data());
    EXPECT_EQ(0, memcmp(purgeableVector.data(), testData.data(), testData.size()));

    // This test is not reliable if the PurgeableVector uses a plain WTF::Vector
    // for storage, as it does if discardable memory is not supported; the vectors
    // capacity will always be expanded to fill the PartitionAlloc bucket.
    if (isDiscardableMemorySupported()) {
        // Appending one extra byte should cause a reallocation since the first
        // allocation happened while the purgeable vector was empty. This behavior
        // helps us guarantee that there is no memory waste on very small vectors
        // (which SharedBuffer requires).
        purgeableVector.append(testData.data(), 1);
        EXPECT_NE(data, purgeableVector.data());
    }
}

TEST_P(PurgeableVectorTestWithPlatformSupport, appendReservesCapacityIfNeeded)
{
    Vector<char> testData(kTestSize);
    std::generate(testData.begin(), testData.end(), &std::rand);

    PurgeableVector purgeableVector(makePurgeableOption());
    // No reserveCapacity().
    ASSERT_FALSE(purgeableVector.data());

    purgeableVector.append(testData.data(), testData.size());
    ASSERT_EQ(testData.size(), purgeableVector.size());
    ASSERT_EQ(0, memcmp(purgeableVector.data(), testData.data(), testData.size()));
}

TEST_P(PurgeableVectorTestWithPlatformSupport, adopt)
{
    Vector<char> testData(kTestSize);
    std::generate(testData.begin(), testData.end(), &std::rand);
    const Vector<char> testDataCopy(testData);
    const char* const testDataPtr = testData.data();

    PurgeableVector purgeableVector(makePurgeableOption());
    purgeableVector.adopt(testData);
    EXPECT_TRUE(testData.isEmpty());
    EXPECT_EQ(kTestSize, purgeableVector.size());
    ASSERT_EQ(0, memcmp(purgeableVector.data(), testDataCopy.data(), testDataCopy.size()));

    if (isDiscardableMemorySupported()) {
        // An extra discardable memory allocation + memcpy() should have happened.
        EXPECT_NE(testDataPtr, purgeableVector.data());
    } else {
        // Vector::swap() should have been used.
        EXPECT_EQ(testDataPtr, purgeableVector.data());
    }
}

TEST_P(PurgeableVectorTestWithPlatformSupport, adoptEmptyVector)
{
    Vector<char> testData;
    PurgeableVector purgeableVector(makePurgeableOption());
    purgeableVector.adopt(testData);
}

TEST(PurgeableVectorTestWithPlatformSupport, adoptDiscardsPreviousData)
{
    Vector<char> testData;
    std::generate(testData.begin(), testData.end(), &std::rand);

    PurgeableVector purgeableVector(PurgeableVector::NotPurgeable);
    static const char smallString[] = "hello";
    purgeableVector.append(smallString, sizeof(smallString));
    ASSERT_EQ(0, memcmp(purgeableVector.data(), smallString, sizeof(smallString)));

    purgeableVector.adopt(testData);
    EXPECT_EQ(testData.size(), purgeableVector.size());
    ASSERT_EQ(0, memcmp(purgeableVector.data(), testData.data(), testData.size()));
}

TEST_P(PurgeableVectorTestWithPlatformSupport, unlockWithoutHintAtConstruction)
{
    Vector<char> testData(30000);
    std::generate(testData.begin(), testData.end(), &std::rand);

    unsigned length = testData.size();
    PurgeableVector purgeableVector(PurgeableVector::NotPurgeable);
    purgeableVector.append(testData.data(), length);
    ASSERT_EQ(length, purgeableVector.size());
    const char* data = purgeableVector.data();

    purgeableVector.unlock();

    // Note that the purgeable vector must be locked before calling data().
    const bool wasPurged = !purgeableVector.lock();
    if (isDiscardableMemorySupported()) {
        // The implementation of purgeable memory used for testing always purges data upon unlock().
        EXPECT_TRUE(wasPurged);
    }

    if (isDiscardableMemorySupported()) {
        // The data should have been moved from the heap-allocated vector to a purgeable buffer.
        ASSERT_NE(data, purgeableVector.data());
    } else {
        ASSERT_EQ(data, purgeableVector.data());
    }

    if (!wasPurged)
        ASSERT_EQ(0, memcmp(purgeableVector.data(), testData.data(), length));
}

TEST(PurgeableVectorTest, unlockOnEmptyPurgeableVector)
{
    PurgeableVector purgeableVector;
    ASSERT_EQ(0U, purgeableVector.size());
    purgeableVector.unlock();
    ASSERT_FALSE(purgeableVector.isLocked());
}

TEST_P(PurgeableVectorTestWithPlatformSupport, unlockOnPurgeableVectorWithPurgeableHint)
{
    Vector<char> testData(kTestSize);
    std::generate(testData.begin(), testData.end(), &std::rand);

    PurgeableVector purgeableVector;
    purgeableVector.append(testData.data(), kTestSize);
    const char* const data = purgeableVector.data();

    // unlock() should happen in place, i.e. without causing any reallocation.
    // Note that the instance must be locked when data() is called.
    purgeableVector.unlock();
    EXPECT_FALSE(purgeableVector.isLocked());
    purgeableVector.lock();
    EXPECT_TRUE(purgeableVector.isLocked());
    EXPECT_EQ(data, purgeableVector.data());
}

TEST_P(PurgeableVectorTestWithPlatformSupport, lockingUsesACounter)
{
    Vector<char> testData(kTestSize);
    std::generate(testData.begin(), testData.end(), &std::rand);

    PurgeableVector purgeableVector(PurgeableVector::NotPurgeable);
    purgeableVector.append(testData.data(), testData.size());
    ASSERT_EQ(testData.size(), purgeableVector.size());

    ASSERT_TRUE(purgeableVector.isLocked()); // SharedBuffer is locked at creation.
    ASSERT_TRUE(purgeableVector.lock()); // Add an extra lock.
    ASSERT_TRUE(purgeableVector.isLocked());

    purgeableVector.unlock();
    ASSERT_TRUE(purgeableVector.isLocked());

    purgeableVector.unlock();
    ASSERT_FALSE(purgeableVector.isLocked());

    if (purgeableVector.lock())
        ASSERT_EQ(0, memcmp(purgeableVector.data(), testData.data(), testData.size()));
}

// Instantiates all the unit tests using the SharedBufferTestWithPlatformSupport fixture both with
// and without discardable memory support.
INSTANTIATE_TEST_CASE_P(testsWithPlatformSetUp, PurgeableVectorTestWithPlatformSupport,
    ::testing::Values(DontSupportDiscardableMemory, SupportDiscardableMemory));

} // namespace

