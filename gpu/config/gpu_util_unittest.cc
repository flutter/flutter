// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/config/gpu_util.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace gpu {

TEST(GpuUtilTest, MergeFeatureSets) {
  {
    // Merge two empty sets.
    std::set<int> src;
    std::set<int> dst;
    EXPECT_TRUE(dst.empty());
    MergeFeatureSets(&dst, src);
    EXPECT_TRUE(dst.empty());
  }
  {
    // Merge an empty set into a set with elements.
    std::set<int> src;
    std::set<int> dst;
    dst.insert(1);
    EXPECT_EQ(1u, dst.size());
    MergeFeatureSets(&dst, src);
    EXPECT_EQ(1u, dst.size());
  }
  {
    // Merge two sets where the source elements are already in the target set.
    std::set<int> src;
    std::set<int> dst;
    src.insert(1);
    dst.insert(1);
    EXPECT_EQ(1u, dst.size());
    MergeFeatureSets(&dst, src);
    EXPECT_EQ(1u, dst.size());
  }
  {
    // Merge two sets with different elements.
    std::set<int> src;
    std::set<int> dst;
    src.insert(1);
    dst.insert(2);
    EXPECT_EQ(1u, dst.size());
    MergeFeatureSets(&dst, src);
    EXPECT_EQ(2u, dst.size());
  }
}

TEST(GpuUtilTest, StringToFeatureSet) {
  {
    // zero feature.
    std::set<int> features;
    StringToFeatureSet("", &features);
    EXPECT_EQ(0u, features.size());
  }
  {
    // One features.
    std::set<int> features;
    StringToFeatureSet("4", &features);
    EXPECT_EQ(1u, features.size());
  }
  {
    // Multiple features.
    std::set<int> features;
    StringToFeatureSet("1,9", &features);
    EXPECT_EQ(2u, features.size());
  }
}

}  // namespace gpu
