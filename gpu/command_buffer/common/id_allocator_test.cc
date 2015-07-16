// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file has the unit tests for the IdAllocator class.

#include "gpu/command_buffer/common/id_allocator.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace gpu {

class IdAllocatorTest : public testing::Test {
 protected:
  void SetUp() override {}
  void TearDown() override {}

  IdAllocator* id_allocator() { return &id_allocator_; }

 private:
  IdAllocator id_allocator_;
};

// Checks basic functionality: AllocateID, FreeID, InUse.
TEST_F(IdAllocatorTest, TestBasic) {
  IdAllocator *allocator = id_allocator();
  // Check that resource 1 is not in use
  EXPECT_FALSE(allocator->InUse(1));

  // Allocate an ID, check that it's in use.
  ResourceId id1 = allocator->AllocateID();
  EXPECT_TRUE(allocator->InUse(id1));

  // Allocate another ID, check that it's in use, and different from the first
  // one.
  ResourceId id2 = allocator->AllocateID();
  EXPECT_TRUE(allocator->InUse(id2));
  EXPECT_NE(id1, id2);

  // Free one of the IDs, check that it's not in use any more.
  allocator->FreeID(id1);
  EXPECT_FALSE(allocator->InUse(id1));

  // Frees the other ID, check that it's not in use any more.
  allocator->FreeID(id2);
  EXPECT_FALSE(allocator->InUse(id2));
}

// Checks that the resource IDs are re-used after being freed.
TEST_F(IdAllocatorTest, TestAdvanced) {
  IdAllocator *allocator = id_allocator();

  // Allocate the highest possible ID, to make life awkward.
  allocator->AllocateIDAtOrAbove(~static_cast<ResourceId>(0));

  // Allocate a significant number of resources.
  const unsigned int kNumResources = 100;
  ResourceId ids[kNumResources];
  for (unsigned int i = 0; i < kNumResources; ++i) {
    ids[i] = allocator->AllocateID();
    EXPECT_TRUE(allocator->InUse(ids[i]));
  }

  // Check that a new allocation re-uses the resource we just freed.
  ResourceId id1 = ids[kNumResources / 2];
  allocator->FreeID(id1);
  EXPECT_FALSE(allocator->InUse(id1));
  ResourceId id2 = allocator->AllocateID();
  EXPECT_TRUE(allocator->InUse(id2));
  EXPECT_EQ(id1, id2);
}

// Checks that we can choose our own ids and they won't be reused.
TEST_F(IdAllocatorTest, MarkAsUsed) {
  IdAllocator* allocator = id_allocator();
  ResourceId id = allocator->AllocateID();
  allocator->FreeID(id);
  EXPECT_FALSE(allocator->InUse(id));
  EXPECT_TRUE(allocator->MarkAsUsed(id));
  EXPECT_TRUE(allocator->InUse(id));
  ResourceId id2 = allocator->AllocateID();
  EXPECT_NE(id, id2);
  EXPECT_TRUE(allocator->MarkAsUsed(id2 + 1));
  ResourceId id3 = allocator->AllocateID();
  // Checks our algorithm. If the algorithm changes this check should be
  // changed.
  EXPECT_EQ(id3, id2 + 2);
}

// Checks AllocateIdAtOrAbove.
TEST_F(IdAllocatorTest, AllocateIdAtOrAbove) {
  const ResourceId kOffset = 123456;
  IdAllocator* allocator = id_allocator();
  ResourceId id1 = allocator->AllocateIDAtOrAbove(kOffset);
  EXPECT_EQ(kOffset, id1);
  ResourceId id2 = allocator->AllocateIDAtOrAbove(kOffset);
  EXPECT_GT(id2, kOffset);
  ResourceId id3 = allocator->AllocateIDAtOrAbove(kOffset);
  EXPECT_GT(id3, kOffset);
}

// Checks that AllocateIdAtOrAbove wraps around at the maximum value.
TEST_F(IdAllocatorTest, AllocateIdAtOrAboveWrapsAround) {
  const ResourceId kMaxPossibleOffset = ~static_cast<ResourceId>(0);
  IdAllocator* allocator = id_allocator();
  ResourceId id1 = allocator->AllocateIDAtOrAbove(kMaxPossibleOffset);
  EXPECT_EQ(kMaxPossibleOffset, id1);
  ResourceId id2 = allocator->AllocateIDAtOrAbove(kMaxPossibleOffset);
  EXPECT_EQ(1u, id2);
  ResourceId id3 = allocator->AllocateIDAtOrAbove(kMaxPossibleOffset);
  EXPECT_EQ(2u, id3);
}

TEST_F(IdAllocatorTest, RedundantFreeIsIgnored) {
  IdAllocator* allocator = id_allocator();
  ResourceId id1 = allocator->AllocateID();
  allocator->FreeID(0);
  allocator->FreeID(id1);
  allocator->FreeID(id1);
  allocator->FreeID(id1 + 1);

  ResourceId id2 = allocator->AllocateID();
  ResourceId id3 = allocator->AllocateID();
  EXPECT_NE(id2, id3);
  EXPECT_NE(kInvalidResource, id2);
  EXPECT_NE(kInvalidResource, id3);
}

TEST_F(IdAllocatorTest, AllocateIDRange) {
  const ResourceId kMaxPossibleOffset = std::numeric_limits<ResourceId>::max();

  IdAllocator* allocator = id_allocator();

  ResourceId id1 = allocator->AllocateIDRange(1);
  EXPECT_EQ(1u, id1);
  ResourceId id2 = allocator->AllocateIDRange(2);
  EXPECT_EQ(2u, id2);
  ResourceId id3 = allocator->AllocateIDRange(3);
  EXPECT_EQ(4u, id3);
  ResourceId id4 = allocator->AllocateID();
  EXPECT_EQ(7u, id4);
  allocator->FreeID(3);
  ResourceId id5 = allocator->AllocateIDRange(1);
  EXPECT_EQ(3u, id5);
  allocator->FreeID(5);
  allocator->FreeID(2);
  allocator->FreeID(4);
  ResourceId id6 = allocator->AllocateIDRange(2);
  EXPECT_EQ(4u, id6);
  ResourceId id7 = allocator->AllocateIDAtOrAbove(kMaxPossibleOffset);
  EXPECT_EQ(kMaxPossibleOffset, id7);
  ResourceId id8 = allocator->AllocateIDAtOrAbove(kMaxPossibleOffset);
  EXPECT_EQ(2u, id8);
  ResourceId id9 = allocator->AllocateIDRange(50);
  EXPECT_EQ(8u, id9);
  ResourceId id10 = allocator->AllocateIDRange(50);
  EXPECT_EQ(58u, id10);
  // Remove all the low-numbered ids.
  allocator->FreeID(1);
  allocator->FreeID(15);
  allocator->FreeIDRange(2, 107);
  ResourceId id11 = allocator->AllocateIDRange(100);
  EXPECT_EQ(1u, id11);
  allocator->FreeID(kMaxPossibleOffset);
  ResourceId id12 = allocator->AllocateIDRange(100);
  EXPECT_EQ(101u, id12);

  ResourceId id13 = allocator->AllocateIDAtOrAbove(kMaxPossibleOffset - 2u);
  EXPECT_EQ(kMaxPossibleOffset - 2u, id13);
  ResourceId id14 = allocator->AllocateIDRange(3);
  EXPECT_EQ(201u, id14);
}

TEST_F(IdAllocatorTest, AllocateIDRangeEndNoEffect) {
  const ResourceId kMaxPossibleOffset = std::numeric_limits<ResourceId>::max();

  IdAllocator* allocator = id_allocator();
  ResourceId id1 = allocator->AllocateIDAtOrAbove(kMaxPossibleOffset - 2u);
  EXPECT_EQ(kMaxPossibleOffset - 2u, id1);
  ResourceId id3 = allocator->AllocateIDRange(3);
  EXPECT_EQ(1u, id3);
  ResourceId id2 = allocator->AllocateIDRange(2);
  EXPECT_EQ(4u, id2);
}

TEST_F(IdAllocatorTest, AllocateFullIDRange) {
  const uint32_t kMaxPossibleRange = std::numeric_limits<uint32_t>::max();
  const ResourceId kFreedId = 555u;
  IdAllocator* allocator = id_allocator();

  ResourceId id1 = allocator->AllocateIDRange(kMaxPossibleRange);
  EXPECT_EQ(1u, id1);
  ResourceId id2 = allocator->AllocateID();
  EXPECT_EQ(0u, id2);
  allocator->FreeID(kFreedId);
  ResourceId id3 = allocator->AllocateID();
  EXPECT_EQ(kFreedId, id3);
  ResourceId id4 = allocator->AllocateID();
  EXPECT_EQ(0u, id4);
  allocator->FreeID(kFreedId + 1u);
  allocator->FreeID(kFreedId + 4u);
  allocator->FreeID(kFreedId + 3u);
  allocator->FreeID(kFreedId + 5u);
  allocator->FreeID(kFreedId + 2u);
  ResourceId id5 = allocator->AllocateIDRange(5);
  EXPECT_EQ(kFreedId + 1u, id5);
}

TEST_F(IdAllocatorTest, AllocateIDRangeNoWrapInRange) {
  const uint32_t kMaxPossibleRange = std::numeric_limits<uint32_t>::max();
  const ResourceId kAllocId = 10u;
  IdAllocator* allocator = id_allocator();

  ResourceId id1 = allocator->AllocateIDAtOrAbove(kAllocId);
  EXPECT_EQ(kAllocId, id1);
  ResourceId id2 = allocator->AllocateIDRange(kMaxPossibleRange - 5u);
  EXPECT_EQ(0u, id2);
  ResourceId id3 = allocator->AllocateIDRange(kMaxPossibleRange - kAllocId);
  EXPECT_EQ(kAllocId + 1u, id3);
}

TEST_F(IdAllocatorTest, AllocateIdMax) {
  const uint32_t kMaxPossibleRange = std::numeric_limits<uint32_t>::max();

  IdAllocator* allocator = id_allocator();
  ResourceId id = allocator->AllocateIDRange(kMaxPossibleRange);
  EXPECT_EQ(1u, id);
  allocator->FreeIDRange(id, kMaxPossibleRange - 1u);
  ResourceId id2 = allocator->AllocateIDRange(kMaxPossibleRange);
  EXPECT_EQ(0u, id2);
  allocator->FreeIDRange(id, kMaxPossibleRange);
  ResourceId id3 = allocator->AllocateIDRange(kMaxPossibleRange);
  EXPECT_EQ(1u, id3);
}

TEST_F(IdAllocatorTest, ZeroIdCases) {
  IdAllocator* allocator = id_allocator();
  EXPECT_FALSE(allocator->InUse(0));
  ResourceId id1 = allocator->AllocateIDAtOrAbove(0);
  EXPECT_NE(0u, id1);
  EXPECT_FALSE(allocator->InUse(0));
  allocator->FreeID(0);
  EXPECT_FALSE(allocator->InUse(0));
  EXPECT_TRUE(allocator->InUse(id1));
  allocator->FreeID(id1);
  EXPECT_FALSE(allocator->InUse(id1));
}
}  // namespace gpu
