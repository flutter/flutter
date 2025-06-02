// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"  // IWYU pragma: keep
#include "gtest/gtest.h"
#include "impeller/renderer/backend/gles/test/mock_gles.h"

namespace impeller {
namespace testing {

TEST(DescriptionGLES, DeterminesOpenGLVersion) {
  auto mock_gles = MockGLES::Init(std::nullopt, "OpenGL 4.0");
  auto description = mock_gles->GetProcTable().GetDescription();
  auto version = description->GetGlVersion();

  EXPECT_FALSE(description->IsES());
  EXPECT_EQ(version.major_version, size_t{4});
  EXPECT_EQ(version.minor_version, size_t{0});
  EXPECT_EQ(version.patch_version, size_t{0});
}

TEST(DescriptionGLES, DeterminesANGLEVersion) {
  auto mock_gles = MockGLES::Init(
      std::nullopt, "OpenGL ES 3.1.0 (ANGLE 1.2.3 git hash: abcdef)");
  auto description = mock_gles->GetProcTable().GetDescription();
  auto version = description->GetGlVersion();

  EXPECT_TRUE(description->IsANGLE());
  EXPECT_TRUE(description->IsES());
  EXPECT_EQ(version.major_version, size_t{3});
  EXPECT_EQ(version.minor_version, size_t{1});
  EXPECT_EQ(version.patch_version, size_t{0});
}

TEST(DescriptionGLES, DeterminesUnprefixedVersion) {
  auto mock_gles = MockGLES::Init(std::nullopt, "3.0.0");
  auto description = mock_gles->GetProcTable().GetDescription();
  auto version = description->GetGlVersion();

  EXPECT_FALSE(description->IsANGLE());
  EXPECT_FALSE(description->IsES());
  EXPECT_EQ(version.major_version, size_t{3});
  EXPECT_EQ(version.minor_version, size_t{0});
  EXPECT_EQ(version.patch_version, size_t{0});
}

TEST(DescriptionGLES, DeterminesWeirdVersion) {
  auto mock_gles = MockGLES::Init(std::nullopt, "Hi, I am version 1.2.3");
  auto description = mock_gles->GetProcTable().GetDescription();
  auto version = description->GetGlVersion();

  EXPECT_FALSE(description->IsANGLE());
  EXPECT_FALSE(description->IsES());
  EXPECT_EQ(version.major_version, size_t{1});
  EXPECT_EQ(version.minor_version, size_t{2});
  EXPECT_EQ(version.patch_version, size_t{3});
}

}  // namespace testing
}  // namespace impeller
