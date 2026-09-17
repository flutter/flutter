// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <unordered_set>

#include "flutter/testing/testing.h"
#include "impeller/renderer/pipeline_descriptor.h"

namespace impeller {
namespace testing {

TEST(PipelineDescriptorTest, PrimitiveTypeHashEquality) {
  PipelineDescriptor descA;
  PipelineDescriptor descB;

  ASSERT_TRUE(descA.IsEqual(descB));
  ASSERT_EQ(descA.GetHash(), descB.GetHash());

  descA.SetPrimitiveType(PrimitiveType::kTriangleStrip);

  ASSERT_FALSE(descA.IsEqual(descB));
  ASSERT_NE(descA.GetHash(), descB.GetHash());
}

TEST(PipelineDescriptorTest, HighPriorityDoesNotAffectHashEquality) {
  PipelineDescriptor descA;
  PipelineDescriptor descB;

  ASSERT_TRUE(descA.IsEqual(descB));
  ASSERT_EQ(descA.GetHash(), descB.GetHash());

  descA.SetHighPriority(true);

  // Priority is a scheduling hint, not part of a pipeline's identity. If it
  // participated in hashing or equality, the same pipeline requested at two
  // different priorities would be compiled and cached twice.
  EXPECT_TRUE(descA.IsHighPriority());
  EXPECT_FALSE(descB.IsHighPriority());
  EXPECT_TRUE(descA.IsEqual(descB));
  EXPECT_EQ(descA.GetHash(), descB.GetHash());

  // And the descriptors must collapse to a single entry in a hash container.
  std::unordered_set<PipelineDescriptor, ComparableHash<PipelineDescriptor>,
                     ComparableEqual<PipelineDescriptor>>
      set;
  set.insert(descA);
  set.insert(descB);
  EXPECT_EQ(set.size(), 1u);
}

}  // namespace  testing
}  // namespace impeller
