// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/android/android_renderer.h"

#include <android/api-level.h>

#include <memory>
#include <string>
#include <utility>

#include "flutter/fml/task_runner.h"
#include "flutter/shell/common/thread_host.h"
#include "flutter/shell/platform/embedder/android/external_view_embedder/external_view_embedder_delegate_mock.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

namespace {

// The API level from which PlatformViewAndroid allows HCPP.
constexpr int kMinAPILevelHCPP = 34;

// Hands the renderer's OpenGL ES context a plain task runner for uploads.
class IOTaskRunner final : public fml::BasicTaskRunner {
 public:
  explicit IOTaskRunner(fml::RefPtr<fml::TaskRunner> runner)
      : runner_(std::move(runner)) {}

  void PostTask(const fml::closure& task) override { runner_->PostTask(task); }

 private:
  fml::RefPtr<fml::TaskRunner> runner_;
};

class AndroidRendererTest : public ::testing::Test {
 protected:
  AndroidRendererTest()
      : thread_host_(ThreadHost::ThreadHostConfig(
            ::testing::UnitTest::GetInstance()->current_test_info()->name(),
            ThreadHost::Type::kPlatform | ThreadHost::Type::kUi |
                ThreadHost::Type::kRaster | ThreadHost::Type::kIo)),
        task_runners_(
            ::testing::UnitTest::GetInstance()->current_test_info()->name(),
            thread_host_.platform_thread->GetTaskRunner(),
            thread_host_.raster_thread->GetTaskRunner(),
            thread_host_.ui_thread->GetTaskRunner(),
            thread_host_.io_thread->GetTaskRunner()),
        io_task_runner_(
            std::make_shared<IOTaskRunner>(task_runners_.GetIOTaskRunner())) {}

  std::unique_ptr<AndroidRenderer> MakeImpellerGLESRenderer(
      const Settings& settings) {
    return std::make_unique<AndroidRenderer>(
        task_runners_, settings, AndroidRenderingAPI::kImpellerOpenGLES,
        io_task_runner_, /*create_transaction=*/nullptr);
  }

  ThreadHost thread_host_;
  TaskRunners task_runners_;
  std::shared_ptr<fml::BasicTaskRunner> io_task_runner_;
};

Settings ImpellerSettings() {
  Settings settings;
  settings.enable_impeller = true;
  return settings;
}

}  // namespace

TEST_F(AndroidRendererTest, SpawnedRendererSharesTheContext) {
  const Settings settings = ImpellerSettings();
  std::unique_ptr<AndroidRenderer> parent = MakeImpellerGLESRenderer(settings);
  ASSERT_NE(parent->GetAndroidContext(), nullptr);

  AndroidRenderer spawned(task_runners_, settings, parent->GetAndroidContext(),
                          /*create_transaction=*/nullptr);

  EXPECT_EQ(spawned.GetAndroidContext(), parent->GetAndroidContext());
  // Each renderer makes its own surfaces from the shared context.
  EXPECT_NE(spawned.GetSurfaceFactory(), parent->GetSurfaceFactory());
}

TEST_F(AndroidRendererTest, SurfaceControlNeedsTheVulkanBackend) {
  Settings settings = ImpellerSettings();
  settings.enable_surface_control = true;

  std::unique_ptr<AndroidRenderer> renderer =
      MakeImpellerGLESRenderer(settings);

  EXPECT_EQ(renderer->MeetsHCPPCriteria(),
            android_get_device_api_level() >= kMinAPILevelHCPP);
  EXPECT_FALSE(renderer->IsSurfaceControlEnabled());
}

TEST_F(AndroidRendererTest, HCPPNeedsSurfaceControlAndImpeller) {
  Settings without_surface_control = ImpellerSettings();
  without_surface_control.enable_surface_control = false;

  EXPECT_FALSE(
      MakeImpellerGLESRenderer(without_surface_control)->MeetsHCPPCriteria());
}

TEST_F(AndroidRendererTest, CreatesExternalViewEmbedderWhenDelegateIsSet) {
  std::unique_ptr<AndroidRenderer> renderer =
      MakeImpellerGLESRenderer(ImpellerSettings());
  EXPECT_EQ(renderer->CreateExternalViewEmbedder(), nullptr);

  auto delegate = std::make_shared<ExternalViewEmbedderDelegateMock>();
  renderer->SetExternalViewEmbedderDelegate(delegate);
  EXPECT_NE(renderer->CreateExternalViewEmbedder(), nullptr);
}

}  // namespace testing
}  // namespace flutter
