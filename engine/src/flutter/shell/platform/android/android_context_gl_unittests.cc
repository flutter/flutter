#define FML_USED_ON_EMBEDDER

#include "android_environment_gl.h"

#include <memory>
#include "flutter/shell/common/thread_host.h"
#include "flutter/shell/platform/android/android_context_gl.h"
#include "flutter/shell/platform/android/android_environment_gl.h"
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

class InterceptingAndroidEnvironmentGL : public AndroidEnvironmentGL {
 public:
  InterceptingAndroidEnvironmentGL() = default;
  ~InterceptingAndroidEnvironmentGL() override = default;

  bool SetPresentationTime(EGLSurface surface,
                           fml::TimePoint time) const override {
    presentation_time_ = time;
    return AndroidEnvironmentGL::SetPresentationTime(surface, time);
  }

  mutable std::optional<fml::TimePoint> presentation_time_;

  FML_DISALLOW_COPY_AND_ASSIGN(InterceptingAndroidEnvironmentGL);
};

TEST(AndroidContextGl, Create) {
  GrMockOptions main_context_options;
  sk_sp<GrDirectContext> main_context =
      GrDirectContext::MakeMock(&main_context_options);
  auto environment = fml::MakeRefCounted<AndroidEnvironmentGL>();
  std::string thread_label =
      ::testing::UnitTest::GetInstance()->current_test_info()->name();
  ThreadHost thread_host(thread_label, ThreadHost::Type::UI |
                                           ThreadHost::Type::RASTER |
                                           ThreadHost::Type::IO);
  TaskRunners task_runners = MakeTaskRunners(thread_label, thread_host);
  auto context = std::make_unique<AndroidContextGL>(
      AndroidRenderingAPI::kOpenGLES, environment, task_runners);
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
  auto context = std::make_unique<AndroidContextGL>(
      AndroidRenderingAPI::kOpenGLES, environment, task_runners);
  context->SetMainSkiaContext(main_context);
  EXPECT_NE(context.get(), nullptr);
  context.reset();
  EXPECT_TRUE(main_context->abandoned());
}

TEST(AndroidEGLSurface, SwapBuffersNotifiesAboutPresentationTime) {
  auto environment = fml::MakeRefCounted<InterceptingAndroidEnvironmentGL>();
  std::string thread_label =
      ::testing::UnitTest::GetInstance()->current_test_info()->name();
  fml::MessageLoop::EnsureInitializedForCurrentThread();
  fml::RefPtr<fml::TaskRunner> platform_runner =
      fml::MessageLoop::GetCurrent().GetTaskRunner();
  TaskRunners task_runners =
      TaskRunners(thread_label, platform_runner, platform_runner,
                  platform_runner, platform_runner);
  auto context = std::make_unique<AndroidContextGL>(
      AndroidRenderingAPI::kOpenGLES, environment, task_runners);

  auto surface = context->CreatePbufferSurface();
  EXPECT_TRUE(surface);
  EXPECT_FALSE(environment->presentation_time_.has_value());
  auto now = fml::TimePoint::Now();
  surface->SwapBuffers(now);
  EXPECT_EQ(environment->presentation_time_, now);
}
}  // namespace android
}  // namespace testing
}  // namespace flutter
