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

  fml::AutoResetWaitableEvent waiter_started;
  std::atomic<bool> waiter_returned = false;

  std::thread waiter_thread([context, &waiter_started, &waiter_returned]() {
    waiter_started.Signal();
    context->RenderingApi();
    waiter_returned.store(true);
  });

  waiter_started.Wait();
  // Give the waiter thread a moment to enter RenderingApi() and block.
  std::this_thread::sleep_for(std::chrono::milliseconds(10));

  // Verify that the waiter thread is indeed blocked and hasn't returned yet.
  EXPECT_FALSE(waiter_returned);

  // Now run setup, which should unblock the waiter.
  context->SetupImpellerContext();

  waiter_thread.join();
  EXPECT_TRUE(waiter_returned.load());
  EXPECT_NE(context->RenderingApi(), AndroidRenderingAPI::kImpellerAutoselect);
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
