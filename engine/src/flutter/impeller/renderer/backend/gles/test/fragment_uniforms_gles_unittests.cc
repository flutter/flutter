// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/gles/fragment_uniforms_gles.h"

#include "gtest/gtest.h"

namespace impeller::testing {

TEST(FragmentUniformsGLES, SelectsOnlyTheObservedDriverWithEnoughUniforms) {
  constexpr auto kVersion = "OpenGL ES 3.2 v1.g24p0-00eac0.7b74681d0404c26d";
  EXPECT_TRUE(ShouldUsePlainFragmentUniforms("Mali-G52", kVersion, 4096));
  EXPECT_TRUE(ShouldUsePlainFragmentUniforms("Mali-G52", kVersion, 8192));
  for (size_t limit : {0u, 256u, 4095u}) {
    EXPECT_FALSE(ShouldUsePlainFragmentUniforms("Mali-G52", kVersion, limit));
  }
  for (auto renderer : {"Mali-G520", "Mali-G52 MC2", "Mali-G57", "Mali-G76",
                        "ANGLE (Mali-G52)", "llvmpipe", ""}) {
    EXPECT_FALSE(ShouldUsePlainFragmentUniforms(renderer, kVersion, 4096));
  }
  for (auto version :
       {"OpenGL ES 3.2 v1.g24p0-", "OpenGL ES 3.2 v1.g24p0",
        "OpenGL ES 3.2 v1.g24p01-build", "OpenGL ES 3.2 v1.g24p1-build",
        "OpenGL ES 3.2 v1.r24p0-build", "OpenGL ES 3.1 v1.g24p0-build",
        "OpenGL ES 3.2 Mesa 26.0", "3.2 v1.g24p0-build", ""}) {
    EXPECT_FALSE(ShouldUsePlainFragmentUniforms("Mali-G52", version, 4096));
  }
}

}  // namespace impeller::testing
