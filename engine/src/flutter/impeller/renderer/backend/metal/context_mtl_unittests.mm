// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"
#include "impeller/core/device_buffer_descriptor.h"
#include "impeller/core/formats.h"
#include "impeller/core/texture_descriptor.h"
#include "impeller/playground/playground_test.h"
#include "impeller/renderer/backend/metal/allocator_mtl.h"
#include "impeller/renderer/backend/metal/context_mtl.h"
#include "impeller/renderer/backend/metal/formats_mtl.h"
#include "impeller/renderer/backend/metal/texture_mtl.h"
#include "impeller/renderer/capabilities.h"

#include <QuartzCore/CAMetalLayer.h>
#include <memory>
#include <thread>

#include "gtest/gtest.h"

namespace impeller {
namespace testing {

using ContextMTLTest = PlaygroundTest;
INSTANTIATE_METAL_PLAYGROUND_SUITE(ContextMTLTest);

TEST_P(ContextMTLTest, FlushTask) {
  auto& context_mtl = ContextMTL::Cast(*GetContext());

  int executed = 0;
  int failed = 0;
  context_mtl.StoreTaskForGPU([&]() { executed++; }, [&]() { failed++; });

  context_mtl.FlushTasksAwaitingGPU();

  EXPECT_EQ(executed, 1);
  EXPECT_EQ(failed, 0);
}

TEST_P(ContextMTLTest, FlushTaskWithGPULoss) {
  auto& context_mtl = ContextMTL::Cast(*GetContext());

  int executed = 0;
  int failed = 0;
  context_mtl.StoreTaskForGPU([&]() { executed++; }, [&]() { failed++; });

  // If tasks are flushed while the GPU is disabled, then
  // they should not be executed.
  SetGPUDisabled(/*disabled=*/true);
  context_mtl.FlushTasksAwaitingGPU();

  EXPECT_EQ(executed, 0);
  EXPECT_EQ(failed, 0);

  // Toggling availibility should flush tasks.
  SetGPUDisabled(/*disabled=*/false);

  EXPECT_EQ(executed, 1);
  EXPECT_EQ(failed, 0);
}

}  // namespace testing
}  // namespace impeller
