#include <memory>
#include "flutter/shell/platform/android/android_context_gl.h"
#include "flutter/shell/platform/android/android_environment_gl.h"
#include "gtest/gtest.h"

TEST(AndroidContextGl, Create) {
  auto environment = fml::MakeRefCounted<flutter::AndroidEnvironmentGL>();
  auto context = std::make_unique<flutter::AndroidContextGL>(
      flutter::AndroidRenderingAPI::kOpenGLES, environment);
  EXPECT_NE(context.get(), nullptr);
}
