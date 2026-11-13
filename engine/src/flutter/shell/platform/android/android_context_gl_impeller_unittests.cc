// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_context_gl_impeller.h"

#include <chrono>
#include <deque>
#include <memory>
#include <optional>

#include "flutter/fml/task_runner.h"
#include "flutter/fml/thread.h"
#include "flutter/impeller/entity/contents/pipelines.h"
#include "flutter/impeller/renderer/pipeline_library.h"
#include "flutter/impeller/toolkit/egl/surface.h"
#include "flutter/testing/post_task_sync.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

using ::testing::_;
using ::testing::AllOf;
using ::testing::ByMove;
using ::testing::Field;
using ::testing::Matcher;
using ::testing::Return;

using ::impeller::egl::Config;
using ::impeller::egl::ConfigDescriptor;

namespace {
class MockDisplay : public impeller::egl::Display {
 public:
  MOCK_METHOD(bool, IsValid, (), (const, override));
  MOCK_METHOD(std::unique_ptr<Config>,
              ChooseConfig,
              (ConfigDescriptor),
              (const, override));
};

bool GetEGLConfigForSurface(EGLint surface_bit, EGLConfig* result) {
  EGLint attributes[] = {
      // clang-format off
      EGL_RENDERABLE_TYPE, EGL_OPENGL_ES2_BIT,
      EGL_SURFACE_TYPE,    surface_bit,
      EGL_RED_SIZE,        8,
      EGL_GREEN_SIZE,      8,
      EGL_BLUE_SIZE,       8,
      EGL_ALPHA_SIZE,      8,
      EGL_DEPTH_SIZE,      24,
      EGL_STENCIL_SIZE,    8,
      EGL_NONE,
      // clang-format on
  };
  EGLint config_count = 0;
  return eglChooseConfig(eglGetDisplay(EGL_DEFAULT_DISPLAY), attributes, result,
                         1, &config_count);
}

/// A task runner that captures posted tasks so a test can choose when, and on
/// which thread, they run.
class CapturingTaskRunner final : public fml::BasicTaskRunner {
 public:
  void PostTask(const fml::closure& task) override { tasks_.push_back(task); }

  /// Runs tasks, including ones posted while running, until none remain.
  void RunAll() {
    while (!tasks_.empty()) {
      fml::closure task = std::move(tasks_.front());
      tasks_.pop_front();
      task();
    }
  }

 private:
  std::deque<fml::closure> tasks_;
};

bool IsReady(
    const impeller::PipelineFuture<impeller::PipelineDescriptor>& future) {
  return future.future.wait_for(std::chrono::seconds(1)) ==
         std::future_status::ready;
}

}  // namespace

class AndroidContextGLImpellerTest : public ::testing::Test {
 public:
  AndroidContextGLImpellerTest() {}

  void SetUp() override {
    EGLDisplay egl_display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
    ASSERT_TRUE(eglInitialize(egl_display, nullptr, nullptr));
  }
};

TEST_F(AndroidContextGLImpellerTest, MSAAFirstAttempt) {
  EGLConfig window_egl_config, pbuffer_egl_config;
  ASSERT_TRUE(GetEGLConfigForSurface(EGL_WINDOW_BIT, &window_egl_config));
  ASSERT_TRUE(GetEGLConfigForSurface(EGL_PBUFFER_BIT, &pbuffer_egl_config));

  auto display = std::make_unique<MockDisplay>();
  EXPECT_CALL(*display, IsValid).WillRepeatedly(Return(true));
  auto first_result =
      std::make_unique<Config>(ConfigDescriptor(), window_egl_config);
  auto second_result =
      std::make_unique<Config>(ConfigDescriptor(), pbuffer_egl_config);
  EXPECT_CALL(
      *display,
      ChooseConfig(Matcher<ConfigDescriptor>(AllOf(
          Field(&ConfigDescriptor::samples, impeller::egl::Samples::kFour),
          Field(&ConfigDescriptor::surface_type,
                impeller::egl::SurfaceType::kWindow)))))
      .WillOnce(Return(ByMove(std::move(first_result))));
  EXPECT_CALL(*display, ChooseConfig(Matcher<ConfigDescriptor>(
                            Field(&ConfigDescriptor::surface_type,
                                  impeller::egl::SurfaceType::kPBuffer))))
      .WillOnce(Return(ByMove(std::move(second_result))));
  ON_CALL(*display, ChooseConfig(_))
      .WillByDefault(Return(ByMove(std::unique_ptr<Config>())));
  auto context = std::make_unique<AndroidContextGLImpeller>(
      std::move(display), true, impeller::Flags{}, nullptr);
  ASSERT_TRUE(context);
}

TEST_F(AndroidContextGLImpellerTest, FallbackForEmulator) {
  EGLConfig window_egl_config, pbuffer_egl_config;
  ASSERT_TRUE(GetEGLConfigForSurface(EGL_WINDOW_BIT, &window_egl_config));
  ASSERT_TRUE(GetEGLConfigForSurface(EGL_PBUFFER_BIT, &pbuffer_egl_config));

  auto display = std::make_unique<MockDisplay>();
  EXPECT_CALL(*display, IsValid).WillRepeatedly(Return(true));
  std::unique_ptr<Config> first_result;
  std::unique_ptr<Config> second_result;
  auto third_result =
      std::make_unique<Config>(ConfigDescriptor(), window_egl_config);
  auto fourth_result =
      std::make_unique<Config>(ConfigDescriptor(), pbuffer_egl_config);
  EXPECT_CALL(
      *display,
      ChooseConfig(Matcher<ConfigDescriptor>(AllOf(
          Field(&ConfigDescriptor::api, impeller::egl::API::kOpenGLES3),
          Field(&ConfigDescriptor::samples, impeller::egl::Samples::kFour),
          Field(&ConfigDescriptor::surface_type,
                impeller::egl::SurfaceType::kWindow)))))
      .WillOnce(Return(ByMove(std::move(first_result))));
  EXPECT_CALL(
      *display,
      ChooseConfig(Matcher<ConfigDescriptor>(AllOf(
          Field(&ConfigDescriptor::api, impeller::egl::API::kOpenGLES2),
          Field(&ConfigDescriptor::samples, impeller::egl::Samples::kFour),
          Field(&ConfigDescriptor::surface_type,
                impeller::egl::SurfaceType::kWindow)))))
      .WillOnce(Return(ByMove(std::move(second_result))));
  EXPECT_CALL(
      *display,
      ChooseConfig(Matcher<ConfigDescriptor>(
          AllOf(Field(&ConfigDescriptor::samples, impeller::egl::Samples::kOne),
                Field(&ConfigDescriptor::surface_type,
                      impeller::egl::SurfaceType::kWindow)))))
      .WillOnce(Return(ByMove(std::move(third_result))));
  EXPECT_CALL(*display, ChooseConfig(Matcher<ConfigDescriptor>(
                            Field(&ConfigDescriptor::surface_type,
                                  impeller::egl::SurfaceType::kPBuffer))))
      .WillOnce(Return(ByMove(std::move(fourth_result))));
  ON_CALL(*display, ChooseConfig(_))
      .WillByDefault(Return(ByMove(std::unique_ptr<Config>())));
  auto context = std::make_unique<AndroidContextGLImpeller>(
      std::move(display), true, impeller::Flags{}, nullptr);
  ASSERT_TRUE(context);
}

// Regression test for https://github.com/flutter/flutter/issues/196453.
//
// At engine startup, pipelines may be requested before the IO thread has made
// its resource context current. The IO thread then can't run the compile jobs'
// reactor operations, which stay queued on it while the jobs leave the compile
// queue. They must run once the IO thread makes its resource context current,
// or the raster thread waits on the pipelines forever.
TEST_F(AndroidContextGLImpellerTest,
       CompilesPipelinesRequestedBeforeTheResourceContextIsCurrent) {
  fml::Thread io_thread("io");
  auto io_task_runner = std::make_shared<CapturingTaskRunner>();
  auto context = std::make_unique<AndroidContextGLImpeller>(
      std::make_unique<impeller::egl::Display>(),
      /*enable_gpu_tracing=*/false, impeller::Flags{}, io_task_runner);
  ASSERT_TRUE(context->IsValid());
  std::shared_ptr<impeller::Context> impeller_context =
      context->GetImpellerContext();
  ASSERT_TRUE(impeller_context);
  std::shared_ptr<impeller::PipelineLibrary> library =
      impeller_context->GetPipelineLibrary();

  // The pipelines are requested from this thread, standing in for the raster
  // thread, which has no context current.
  std::optional<impeller::PipelineDescriptor> solid_fill_desc =
      impeller::SolidFillPipeline::Builder::MakeDefaultPipelineDescriptor(
          *impeller_context);
  std::optional<impeller::PipelineDescriptor> texture_desc =
      impeller::TexturePipeline::Builder::MakeDefaultPipelineDescriptor(
          *impeller_context);
  ASSERT_TRUE(solid_fill_desc.has_value());
  ASSERT_TRUE(texture_desc.has_value());
  impeller::PipelineFuture<impeller::PipelineDescriptor> solid_fill_future =
      library->GetPipeline(solid_fill_desc, /*async=*/true);
  impeller::PipelineFuture<impeller::PipelineDescriptor> texture_future =
      library->GetPipeline(texture_desc, /*async=*/true);

  // The IO thread runs every compile job before its resource context is
  // current.
  PostTaskSync(io_thread.GetTaskRunner(),
               [&io_task_runner]() { io_task_runner->RunAll(); });
  EXPECT_FALSE(IsReady(solid_fill_future));
  EXPECT_FALSE(IsReady(texture_future));

  // The IO thread makes its resource context current, as the shell does when
  // it creates the resource context.
  std::unique_ptr<impeller::egl::Surface> offscreen_surface =
      context->CreateOffscreenSurface();
  bool made_current = false;
  PostTaskSync(io_thread.GetTaskRunner(), [&]() {
    made_current = context->ResourceContextMakeCurrent(offscreen_surface.get());
  });
  ASSERT_TRUE(made_current);

  // Waiting on pipelines that never become ready deadlocks the raster thread.
  EXPECT_TRUE(IsReady(solid_fill_future));
  EXPECT_TRUE(IsReady(texture_future));
  if (IsReady(solid_fill_future) && IsReady(texture_future)) {
    std::shared_ptr<impeller::Pipeline<impeller::PipelineDescriptor>>
        solid_fill_pipeline = solid_fill_future.Get();
    std::shared_ptr<impeller::Pipeline<impeller::PipelineDescriptor>>
        texture_pipeline = texture_future.Get();
    EXPECT_TRUE(solid_fill_pipeline && solid_fill_pipeline->IsValid());
    EXPECT_TRUE(texture_pipeline && texture_pipeline->IsValid());
  }

  PostTaskSync(io_thread.GetTaskRunner(),
               [&context]() { context->ResourceContextClearCurrent(); });
  io_thread.Join();
}

}  // namespace testing
}  // namespace flutter
