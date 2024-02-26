// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gtest/gtest.h"
#include "impeller/base/validation.h"
#include "impeller/core/formats.h"
#include "impeller/core/texture_descriptor.h"
#include "impeller/playground/playground_test.h"
#include "impeller/renderer/command_buffer.h"

namespace impeller {
namespace testing {

using BlitPassTest = PlaygroundTest;
INSTANTIATE_PLAYGROUND_SUITE(BlitPassTest);

TEST_P(BlitPassTest, BlitAcrossDifferentPixelFormatsFails) {
  ScopedValidationDisable scope;  // avoid noise in output.
  auto context = GetContext();
  auto cmd_buffer = context->CreateCommandBuffer();
  auto blit_pass = cmd_buffer->CreateBlitPass();

  TextureDescriptor src_desc;
  src_desc.format = PixelFormat::kA8UNormInt;
  src_desc.size = {100, 100};
  src_desc.storage_mode = StorageMode::kHostVisible;
  auto src = context->GetResourceAllocator()->CreateTexture(src_desc);

  TextureDescriptor dst_format;
  dst_format.format = PixelFormat::kR8G8B8A8UNormInt;
  dst_format.size = {100, 100};
  dst_format.storage_mode = StorageMode::kHostVisible;
  auto dst = context->GetResourceAllocator()->CreateTexture(dst_format);

  EXPECT_FALSE(blit_pass->AddCopy(src, dst));
}

TEST_P(BlitPassTest, BlitAcrossDifferentSampleCountsFails) {
  ScopedValidationDisable scope;  // avoid noise in output.
  auto context = GetContext();
  auto cmd_buffer = context->CreateCommandBuffer();
  auto blit_pass = cmd_buffer->CreateBlitPass();

  TextureDescriptor src_desc;
  src_desc.format = PixelFormat::kR8G8B8A8UNormInt;
  src_desc.sample_count = SampleCount::kCount4;
  src_desc.size = {100, 100};
  auto src = context->GetResourceAllocator()->CreateTexture(src_desc);

  TextureDescriptor dst_format;
  dst_format.format = PixelFormat::kR8G8B8A8UNormInt;
  dst_format.size = {100, 100};
  auto dst = context->GetResourceAllocator()->CreateTexture(dst_format);

  EXPECT_FALSE(blit_pass->AddCopy(src, dst));
}

TEST_P(BlitPassTest, BlitPassesForMatchingFormats) {
  ScopedValidationDisable scope;  // avoid noise in output.
  auto context = GetContext();
  auto cmd_buffer = context->CreateCommandBuffer();
  auto blit_pass = cmd_buffer->CreateBlitPass();

  TextureDescriptor src_desc;
  src_desc.format = PixelFormat::kR8G8B8A8UNormInt;
  src_desc.size = {100, 100};
  auto src = context->GetResourceAllocator()->CreateTexture(src_desc);

  TextureDescriptor dst_format;
  dst_format.format = PixelFormat::kR8G8B8A8UNormInt;
  dst_format.size = {100, 100};
  auto dst = context->GetResourceAllocator()->CreateTexture(dst_format);

  EXPECT_TRUE(blit_pass->AddCopy(src, dst));
}

}  // namespace testing
}  // namespace impeller
