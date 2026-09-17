// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_context_dynamic_impeller.h"

#include <atomic>
#include <chrono>
#include <thread>

#include "flutter/shell/platform/android/android_rendering_selector.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

namespace {
constexpr auto kSetupDelay = std::chrono::milliseconds(50);
// Allow for timer granularity so the assertion does not flake.
constexpr auto kMinObservedWait = std::chrono::milliseconds(40);
}  // namespace

TEST(AndroidContextDynamicImpellerTest, ContextsAreNullBeforeSetup) {
  auto context = std::make_shared<AndroidContextDynamicImpeller>(
      AndroidContext::ContextSettings{}, /*io_task_runner=*/nullptr);

  EXPECT_TRUE(context->IsDynamicSelection());
  // These accessors never block, so they are safe to read before setup has
  // run. They simply report that no backend exists yet.
  EXPECT_EQ(context->GetImpellerContext(), nullptr);
  EXPECT_EQ(context->GetGLContext(), nullptr);
  EXPECT_EQ(context->GetVKContext(), nullptr);
}

TEST(AndroidContextDynamicImpellerTest, RenderingApiBlocksUntilBackendChosen) {
  auto context = std::make_shared<AndroidContextDynamicImpeller>(
      AndroidContext::ContextSettings{}, /*io_task_runner=*/nullptr);

  // Setup happens on the raster thread in production, and can take 100+ ms
  // while probing for Vulkan.
  std::thread raster_thread([&context]() {
    std::this_thread::sleep_for(kSetupDelay);
    context->SetupImpellerContext();
  });

  const auto start = std::chrono::steady_clock::now();
  const AndroidRenderingAPI api = context->RenderingApi();
  const auto elapsed = std::chrono::steady_clock::now() - start;

  // Without the wait this would return kImpellerAutoselect immediately, which
  // is what made early RegisterImageTexture calls crash.
  EXPECT_NE(api, AndroidRenderingAPI::kImpellerAutoselect);
  EXPECT_GE(elapsed, kMinObservedWait);

  raster_thread.join();
}

TEST(AndroidContextDynamicImpellerTest, RenderingApiDoesNotBlockAfterSetup) {
  auto context = std::make_shared<AndroidContextDynamicImpeller>(
      AndroidContext::ContextSettings{}, /*io_task_runner=*/nullptr);

  context->SetupImpellerContext();

  // The latch stays signalled, so repeated reads do not block and stay stable.
  const AndroidRenderingAPI first = context->RenderingApi();
  const AndroidRenderingAPI second = context->RenderingApi();
  EXPECT_NE(first, AndroidRenderingAPI::kImpellerAutoselect);
  EXPECT_EQ(first, second);
  EXPECT_NE(context->GetImpellerContext(), nullptr);
}

TEST(AndroidContextDynamicImpellerTest, SetupIsIdempotent) {
  auto context = std::make_shared<AndroidContextDynamicImpeller>(
      AndroidContext::ContextSettings{}, /*io_task_runner=*/nullptr);

  context->SetupImpellerContext();
  const AndroidRenderingAPI first = context->RenderingApi();

  // A second call is a no-op and must not reset the backend selection.
  context->SetupImpellerContext();
  EXPECT_EQ(context->RenderingApi(), first);
}

TEST(AndroidContextDynamicImpellerTest, SetupThreadCanReadBackendAfterSetup) {
  auto context = std::make_shared<AndroidContextDynamicImpeller>(
      AndroidContext::ContextSettings{}, /*io_task_runner=*/nullptr);

  // Mirrors the raster thread running setup and then reading the backend later
  // in a frame, as AndroidExternalViewEmbedderWrapper::EnsureInitialized does.
  // The debug assert guarding against a deadlocking self-wait must not fire
  // here, because the wait completes immediately once setup is done.
  std::thread raster_thread([context]() {
    context->SetupImpellerContext();
    EXPECT_NE(context->RenderingApi(),
              AndroidRenderingAPI::kImpellerAutoselect);
    EXPECT_NE(context->GetImpellerContext(), nullptr);
  });
  raster_thread.join();
}

}  // namespace testing
}  // namespace flutter
