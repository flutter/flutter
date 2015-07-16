// Copyright (c) 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <GLES2/gl2.h>

#include "gpu/command_buffer/service/shader_translator_cache.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace gpu {
namespace gles2 {

TEST(ShaderTranslatorCacheTest, InitParamComparable) {
  // Tests that ShaderTranslatorInitParams padding or padding of its
  // members does not affect the object equality or ordering.

  ShBuiltInResources a_resources;
  memset(&a_resources, 88, sizeof(a_resources));
  ShInitBuiltInResources(&a_resources);

  ShBuiltInResources b_resources;
  memset(&b_resources, 77, sizeof(b_resources));
  ShInitBuiltInResources(&b_resources);

  EXPECT_TRUE(memcmp(&a_resources, &b_resources, sizeof(a_resources)) == 0);

  ShCompileOptions driver_bug_workarounds = SH_VALIDATE;

  char a_storage[sizeof(ShaderTranslatorCache::ShaderTranslatorInitParams)];
  memset(a_storage, 55, sizeof(a_storage));
  ShaderTranslatorCache::ShaderTranslatorInitParams* a =
      new (&a_storage) ShaderTranslatorCache::ShaderTranslatorInitParams(
          GL_VERTEX_SHADER,
          SH_GLES2_SPEC,
          a_resources,
          ShaderTranslatorInterface::kGlslES,
          driver_bug_workarounds);

  ShaderTranslatorCache::ShaderTranslatorInitParams b(
      GL_VERTEX_SHADER,
      SH_GLES2_SPEC,
      b_resources,
      ShaderTranslatorInterface::kGlslES,
      driver_bug_workarounds);

  EXPECT_TRUE(*a == b);
  EXPECT_FALSE(*a < b || b < *a);

  memset(a_storage, 55, sizeof(a_storage));
  a = new (&a_storage) ShaderTranslatorCache::ShaderTranslatorInitParams(b);

  EXPECT_TRUE(*a == b);
  EXPECT_FALSE(*a < b || b < *a);
}
}  // namespace gles2
}  // namespace gpu
