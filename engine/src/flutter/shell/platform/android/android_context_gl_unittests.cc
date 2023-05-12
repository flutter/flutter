#define FML_USED_ON_EMBEDDER

#include <memory>
#include "flutter/shell/common/thread_host.h"
#include "flutter/shell/platform/android/android_context_gl_skia.h"
#include "flutter/shell/platform/android/android_egl_surface.h"
#include "flutter/shell/platform/android/android_environment_gl.h"
#include "flutter/shell/platform/android/android_surface_gl_skia.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {
namespace android {
namespace {

TaskRunners MakeTaskRunners(const std::string& thread_label,
                            const ThreadHost& thread_host) {
  fml::MessageLoop::EnsureInitializedForCurrentThread();
  fml::RefPtr<fml::TaskRunner> platform_runner =
      fml::MessageLoop::GetCurrent().GetTaskRunner();

  return TaskRunners(thread_label, platform_runner,
                     thread_host.raster_thread->GetTaskRunner(),
                     thread_host.ui_thread->GetTaskRunner(),
                     thread_host.io_thread->GetTaskRunner());
}
}  // namespace

TEST(AndroidContextGl, Create) {
  GrMockOptions main_context_options;
  sk_sp<GrDirectContext> main_context =
      GrDirectContext::MakeMock(&main_context_options);
  auto environment = fml::MakeRefCounted<AndroidEnvironmentGL>();
  std::string thread_label =
      ::testing::UnitTest::GetInstance()->current_test_info()->name();

  ThreadHost thread_host(ThreadHost::ThreadHostConfig(
      thread_label,
      ThreadHost::Type::UI | ThreadHost::Type::RASTER | ThreadHost::Type::IO));
  TaskRunners task_runners = MakeTaskRunners(thread_label, thread_host);
  auto context = std::make_unique<AndroidContextGLSkia>(
      AndroidRenderingAPI::kOpenGLES, environment, task_runners, 0);
  context->SetMainSkiaContext(main_context);
  EXPECT_NE(context.get(), nullptr);
  context.reset();
  EXPECT_TRUE(main_context->abandoned());
}

TEST(AndroidContextGl, CreateSingleThread) {
  GrMockOptions main_context_options;
  sk_sp<GrDirectContext> main_context =
      GrDirectContext::MakeMock(&main_context_options);
  auto environment = fml::MakeRefCounted<AndroidEnvironmentGL>();
  std::string thread_label =
      ::testing::UnitTest::GetInstance()->current_test_info()->name();
  fml::MessageLoop::EnsureInitializedForCurrentThread();
  fml::RefPtr<fml::TaskRunner> platform_runner =
      fml::MessageLoop::GetCurrent().GetTaskRunner();
  TaskRunners task_runners =
      TaskRunners(thread_label, platform_runner, platform_runner,
                  platform_runner, platform_runner);
  auto context = std::make_unique<AndroidContextGLSkia>(
      AndroidRenderingAPI::kOpenGLES, environment, task_runners, 0);
  context->SetMainSkiaContext(main_context);
  EXPECT_NE(context.get(), nullptr);
  context.reset();
  EXPECT_TRUE(main_context->abandoned());
}

TEST(AndroidSurfaceGL, CreateSnapshopSurfaceWhenOnscreenSurfaceIsNotNull) {
  GrMockOptions main_context_options;
  sk_sp<GrDirectContext> main_context =
      GrDirectContext::MakeMock(&main_context_options);
  auto environment = fml::MakeRefCounted<AndroidEnvironmentGL>();
  std::string thread_label =
      ::testing::UnitTest::GetInstance()->current_test_info()->name();
  ThreadHost thread_host(ThreadHost::ThreadHostConfig(
      thread_label,
      ThreadHost::Type::UI | ThreadHost::Type::RASTER | ThreadHost::Type::IO));
  TaskRunners task_runners = MakeTaskRunners(thread_label, thread_host);
  auto android_context = std::make_shared<AndroidContextGLSkia>(
      AndroidRenderingAPI::kOpenGLES, environment, task_runners, 0);
  auto android_surface =
      std::make_unique<AndroidSurfaceGLSkia>(android_context);
  auto window = fml::MakeRefCounted<AndroidNativeWindow>(
      nullptr, /*is_fake_window=*/true);
  android_surface->SetNativeWindow(window);
  auto onscreen_surface = android_surface->GetOnscreenSurface();
  EXPECT_NE(onscreen_surface, nullptr);
  android_surface->CreateSnapshotSurface();
  EXPECT_EQ(onscreen_surface, android_surface->GetOnscreenSurface());
}

TEST(AndroidSurfaceGL, CreateSnapshopSurfaceWhenOnscreenSurfaceIsNull) {
  GrMockOptions main_context_options;
  sk_sp<GrDirectContext> main_context =
      GrDirectContext::MakeMock(&main_context_options);
  auto environment = fml::MakeRefCounted<AndroidEnvironmentGL>();
  std::string thread_label =
      ::testing::UnitTest::GetInstance()->current_test_info()->name();

  auto mask =
      ThreadHost::Type::UI | ThreadHost::Type::RASTER | ThreadHost::Type::IO;
  flutter::ThreadHost::ThreadHostConfig host_config(mask);

  ThreadHost thread_host(host_config);
  TaskRunners task_runners = MakeTaskRunners(thread_label, thread_host);
  auto android_context = std::make_shared<AndroidContextGLSkia>(
      AndroidRenderingAPI::kOpenGLES, environment, task_runners, 0);
  auto android_surface =
      std::make_unique<AndroidSurfaceGLSkia>(android_context);
  EXPECT_EQ(android_surface->GetOnscreenSurface(), nullptr);
  android_surface->CreateSnapshotSurface();
  EXPECT_NE(android_surface->GetOnscreenSurface(), nullptr);
}

// TODO(https://github.com/flutter/flutter/issues/104463): Flaky test.
TEST(AndroidContextGl, DISABLED_MSAAx4) {
  GrMockOptions main_context_options;
  sk_sp<GrDirectContext> main_context =
      GrDirectContext::MakeMock(&main_context_options);
  auto environment = fml::MakeRefCounted<AndroidEnvironmentGL>();
  std::string thread_label =
      ::testing::UnitTest::GetInstance()->current_test_info()->name();

  ThreadHost thread_host(ThreadHost::ThreadHostConfig(
      thread_label,
      ThreadHost::Type::UI | ThreadHost::Type::RASTER | ThreadHost::Type::IO));
  TaskRunners task_runners = MakeTaskRunners(thread_label, thread_host);
  auto context = std::make_unique<AndroidContextGLSkia>(
      AndroidRenderingAPI::kOpenGLES, environment, task_runners, 4);
  context->SetMainSkiaContext(main_context);

  EGLint sample_count;
  eglGetConfigAttrib(environment->Display(), context->Config(), EGL_SAMPLES,
                     &sample_count);
  EXPECT_EQ(sample_count, 4);
}

TEST(AndroidContextGl, EnsureMakeCurrentChecksCurrentContextStatus) {
  GrMockOptions main_context_options;
  sk_sp<GrDirectContext> main_context =
      GrDirectContext::MakeMock(&main_context_options);
  auto environment = fml::MakeRefCounted<AndroidEnvironmentGL>();
  std::string thread_label =
      ::testing::UnitTest::GetInstance()->current_test_info()->name();

  ThreadHost thread_host(ThreadHost::ThreadHostConfig(
      thread_label,
      ThreadHost::Type::UI | ThreadHost::Type::RASTER | ThreadHost::Type::IO));
  TaskRunners task_runners = MakeTaskRunners(thread_label, thread_host);
  auto context = std::make_unique<AndroidContextGLSkia>(
      AndroidRenderingAPI::kOpenGLES, environment, task_runners, 0);

  auto pbuffer_surface = context->CreatePbufferSurface();
  auto status = pbuffer_surface->MakeCurrent();
  EXPECT_EQ(AndroidEGLSurfaceMakeCurrentStatus::kSuccessMadeCurrent, status);

  // context already current, so status must reflect that.
  status = pbuffer_surface->MakeCurrent();
  EXPECT_EQ(AndroidEGLSurfaceMakeCurrentStatus::kSuccessAlreadyCurrent, status);
}
}  // namespace android
}  // namespace testing
}  // namespace flutter
