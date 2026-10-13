// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/android/android_renderer.h"

#include <android/api-level.h>

#include <memory>
#include <string>
#include <utility>

#include "flutter/display_list/geometry/dl_path_builder.h"
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

TEST_F(AndroidRendererTest, CompositorDelegateForwardsMutationsToCallbacks) {
  struct Capture {
    int32_t view_id = -1;
    size_t count = 0;
    FlutterPlatformViewMutationType first_type =
        kFlutterPlatformViewMutationTypeOpacity;
    double first_tx = 0.0;
    FlutterPathFillType fill_type = kFlutterPathFillTypeNonZero;
    size_t verbs_count = 0;
  } capture;

  FlutterNativeWindowCompositor compositor = {};
  compositor.struct_size = sizeof(FlutterNativeWindowCompositor);
  compositor.user_data = &capture;
  compositor.display_platform_view2_callback =
      [](void* user_data, int32_t view_id, int32_t /*x*/, int32_t /*y*/,
         int32_t /*w*/, int32_t /*h*/, int32_t /*vw*/, int32_t /*vh*/,
         const FlutterPlatformViewMutation* const* mutations, size_t count) {
        auto* c = static_cast<Capture*>(user_data);
        c->view_id = view_id;
        c->count = count;
        if (count >= 2) {
          c->first_type = mutations[0]->type;
          c->first_tx = mutations[0]->transformation.transX;
          if (mutations[1]->type == kFlutterPlatformViewMutationTypeClipPath &&
              mutations[1]->clip_path != nullptr) {
            c->fill_type = mutations[1]->clip_path->fill_type;
            c->verbs_count = mutations[1]->clip_path->verbs_count;
          }
        }
      };

  std::shared_ptr<AndroidExternalViewEmbedderDelegate> delegate =
      MakeNativeWindowCompositorDelegate(&compositor, nullptr);
  ASSERT_NE(delegate, nullptr);

  MutatorsStack stack;
  stack.PushTransform(DlMatrix::MakeTranslation({12.0f, 34.0f}));
  DlPathBuilder builder;
  builder.SetFillType(DlPathFillType::kOdd);
  builder.MoveTo({0.0f, 0.0f});
  builder.LineTo({10.0f, 0.0f});
  builder.LineTo({10.0f, 10.0f});
  builder.Close();
  stack.PushClipPath(builder.TakePath());

  delegate->onDisplayPlatformView2(7, 1, 2, 100, 200, 100, 200, stack);
  EXPECT_EQ(capture.view_id, 7);
  EXPECT_EQ(capture.count, 2u);
  EXPECT_EQ(capture.first_type, kFlutterPlatformViewMutationTypeTransformation);
  EXPECT_DOUBLE_EQ(capture.first_tx, 12.0);
  EXPECT_EQ(capture.fill_type, kFlutterPathFillTypeEvenOdd);
  // MoveTo + 2 LineTo + closing LineTo + Close = 5 verbs.
  EXPECT_EQ(capture.verbs_count, 5u);
}

}  // namespace testing
}  // namespace flutter
