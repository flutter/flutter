// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_surface_manager.h"

#include <thread>
#include <vector>

#include "gtest/gtest.h"

namespace flutter {
namespace testing {

TEST(AndroidSurfaceManagerTest, LifecycleAndInitialState) {
  auto manager_software =
      AndroidSurfaceManager::Create(AndroidRenderingAPI::kSoftware);
  ASSERT_NE(manager_software, nullptr);
  EXPECT_TRUE(manager_software->IsValid());
  EXPECT_EQ(manager_software->GetRenderingAPI(),
            AndroidRenderingAPI::kSoftware);
  EXPECT_EQ(manager_software->GetNativeWindow(), nullptr);
  EXPECT_FALSE(manager_software->IsFakeWindow());

  auto manager_gl =
      AndroidSurfaceManager::Create(AndroidRenderingAPI::kSkiaOpenGLES);
  ASSERT_NE(manager_gl, nullptr);
  EXPECT_TRUE(manager_gl->IsValid());
  EXPECT_EQ(manager_gl->GetRenderingAPI(), AndroidRenderingAPI::kSkiaOpenGLES);

  auto manager_vulkan =
      AndroidSurfaceManager::Create(AndroidRenderingAPI::kImpellerVulkan);
  ASSERT_NE(manager_vulkan, nullptr);
  EXPECT_TRUE(manager_vulkan->IsValid());
  EXPECT_EQ(manager_vulkan->GetRenderingAPI(),
            AndroidRenderingAPI::kImpellerVulkan);
}

TEST(AndroidSurfaceManagerTest, SetAndClearNativeWindowFake) {
  auto manager =
      AndroidSurfaceManager::Create(AndroidRenderingAPI::kSkiaOpenGLES);
  ASSERT_NE(manager, nullptr);

  EXPECT_TRUE(manager->SetNativeWindow(nullptr, /*is_fake_window=*/true));
  EXPECT_TRUE(manager->IsFakeWindow());
  EXPECT_TRUE(manager->MakeCurrent());
  EXPECT_TRUE(manager->ClearCurrent());
  EXPECT_TRUE(manager->MakeResourceCurrent());
  EXPECT_TRUE(manager->Present());
  EXPECT_EQ(manager->GetFBO(), 0u);

  manager->ClearNativeWindow();
  EXPECT_FALSE(manager->IsFakeWindow());
  EXPECT_EQ(manager->GetNativeWindow(), nullptr);
}

TEST(AndroidSurfaceManagerTest, SoftwarePresentValidation) {
  auto manager = AndroidSurfaceManager::Create(AndroidRenderingAPI::kSoftware);
  ASSERT_NE(manager, nullptr);

  // Without window, software present fails
  uint8_t dummy_pixels[64] = {0};
  EXPECT_FALSE(manager->PresentSoftware(dummy_pixels, 16, 4));

  // With fake window, software present succeeds
  EXPECT_TRUE(manager->SetNativeWindow(nullptr, /*is_fake_window=*/true));
  EXPECT_TRUE(manager->PresentSoftware(dummy_pixels, 16, 4));
}

TEST(AndroidSurfaceManagerTest, PopulateGLRendererConfig) {
  auto manager =
      AndroidSurfaceManager::Create(AndroidRenderingAPI::kSkiaOpenGLES);
  ASSERT_NE(manager, nullptr);
  EXPECT_TRUE(manager->SetNativeWindow(nullptr, /*is_fake_window=*/true));

  FlutterOpenGLRendererConfig config = {};
  manager->PopulateGLRendererConfig(&config);

  EXPECT_EQ(config.struct_size, sizeof(FlutterOpenGLRendererConfig));
  ASSERT_NE(config.make_current, nullptr);
  ASSERT_NE(config.clear_current, nullptr);
  ASSERT_NE(config.present, nullptr);
  ASSERT_NE(config.fbo_callback, nullptr);
  ASSERT_NE(config.make_resource_current, nullptr);

  EXPECT_TRUE(config.make_current(manager.get()));
  EXPECT_EQ(config.fbo_callback(manager.get()), 0u);
  EXPECT_TRUE(config.present(manager.get()));
  EXPECT_TRUE(config.clear_current(manager.get()));
  EXPECT_TRUE(config.make_resource_current(manager.get()));

  // Null safety
  manager->PopulateGLRendererConfig(nullptr);
}

TEST(AndroidSurfaceManagerTest, PopulateSoftwareRendererConfig) {
  auto manager = AndroidSurfaceManager::Create(AndroidRenderingAPI::kSoftware);
  ASSERT_NE(manager, nullptr);
  EXPECT_TRUE(manager->SetNativeWindow(nullptr, /*is_fake_window=*/true));

  FlutterSoftwareRendererConfig config = {};
  manager->PopulateSoftwareRendererConfig(&config);

  EXPECT_EQ(config.struct_size, sizeof(FlutterSoftwareRendererConfig));
  ASSERT_NE(config.surface_present_callback, nullptr);

  uint8_t dummy_pixels[16] = {0};
  EXPECT_TRUE(
      config.surface_present_callback(manager.get(), dummy_pixels, 4, 4));

  // Null safety
  manager->PopulateSoftwareRendererConfig(nullptr);
}

TEST(AndroidSurfaceManagerTest, ConcurrentThreadSafety) {
  auto manager =
      AndroidSurfaceManager::Create(AndroidRenderingAPI::kSkiaOpenGLES);
  ASSERT_NE(manager, nullptr);

  constexpr size_t kThreadCount = 4;
  constexpr size_t kIterations = 100;
  std::vector<std::thread> threads;
  threads.reserve(kThreadCount);

  for (size_t t = 0; t < kThreadCount; ++t) {
    threads.emplace_back([&manager]() {
      for (size_t i = 0; i < kIterations; ++i) {
        if (i % 2 == 0) {
          manager->SetNativeWindow(nullptr, /*is_fake_window=*/true);
          manager->MakeCurrent();
          manager->Present();
          manager->ClearCurrent();
        } else {
          manager->ClearNativeWindow();
          manager->GetNativeWindow();
          manager->GetNativeWindowSize();
        }
      }
    });
  }

  for (auto& thread : threads) {
    thread.join();
  }

  // After all concurrent operations finish, verify manager is in a valid
  // consistent state
  EXPECT_TRUE(manager->SetNativeWindow(nullptr, /*is_fake_window=*/true));
  EXPECT_TRUE(manager->MakeCurrent());
  EXPECT_TRUE(manager->Present());
  EXPECT_TRUE(manager->ClearCurrent());
}

class AndroidSurfaceManagerMultiBackendMatrixTest
    : public ::testing::TestWithParam<AndroidRenderingAPI> {
 protected:
  void SetUp() override { rendering_api_ = GetParam(); }

  AndroidRenderingAPI rendering_api_ = AndroidRenderingAPI::kImpellerOpenGLES;
};

static std::string SurfaceMatrixTestName(
    const ::testing::TestParamInfo<AndroidRenderingAPI>& info) {
  switch (info.param) {
    case AndroidRenderingAPI::kSoftware:
      return "Software";
    case AndroidRenderingAPI::kSkiaOpenGLES:
      return "SkiaOpenGLES";
    case AndroidRenderingAPI::kImpellerOpenGLES:
      return "ImpellerOpenGLES";
    case AndroidRenderingAPI::kImpellerVulkan:
      return "ImpellerVulkan";
    case AndroidRenderingAPI::kImpellerAutoselect:
      return "ImpellerAutoselect";
  }
}

TEST_P(AndroidSurfaceManagerMultiBackendMatrixTest,
       LifecycleAndWindowAttachment) {
  auto manager = AndroidSurfaceManager::Create(rendering_api_);
  ASSERT_NE(manager, nullptr);
  EXPECT_TRUE(manager->IsValid());
  EXPECT_EQ(manager->GetRenderingAPI(), rendering_api_);
  EXPECT_EQ(manager->GetNativeWindow(), nullptr);
  EXPECT_FALSE(manager->IsFakeWindow());

  EXPECT_TRUE(manager->SetNativeWindow(nullptr, /*is_fake_window=*/true));
  EXPECT_TRUE(manager->IsFakeWindow());
  EXPECT_TRUE(manager->MakeCurrent());
  EXPECT_TRUE(manager->Present());
  EXPECT_TRUE(manager->ClearCurrent());

  manager->ClearNativeWindow();
  EXPECT_FALSE(manager->IsFakeWindow());
  EXPECT_EQ(manager->GetNativeWindow(), nullptr);
}

TEST_P(AndroidSurfaceManagerMultiBackendMatrixTest, RendererConfigPopulation) {
  auto manager = AndroidSurfaceManager::Create(rendering_api_);
  ASSERT_NE(manager, nullptr);
  EXPECT_TRUE(manager->SetNativeWindow(nullptr, /*is_fake_window=*/true));

  if (rendering_api_ == AndroidRenderingAPI::kSoftware) {
    FlutterSoftwareRendererConfig config = {};
    manager->PopulateSoftwareRendererConfig(&config);
    EXPECT_EQ(config.struct_size, sizeof(FlutterSoftwareRendererConfig));
    ASSERT_NE(config.surface_present_callback, nullptr);
  } else if (rendering_api_ == AndroidRenderingAPI::kImpellerVulkan) {
    // Vulkan uses embedder compositor backing stores rather than
    // OpenGL/Software configs.
    EXPECT_TRUE(manager->IsValid());
  } else {
    FlutterOpenGLRendererConfig config = {};
    manager->PopulateGLRendererConfig(&config);
    EXPECT_EQ(config.struct_size, sizeof(FlutterOpenGLRendererConfig));
    ASSERT_NE(config.make_current, nullptr);
    ASSERT_NE(config.clear_current, nullptr);
    ASSERT_NE(config.present, nullptr);
  }
}

TEST_P(AndroidSurfaceManagerMultiBackendMatrixTest, ConcurrentOperations) {
  auto manager = AndroidSurfaceManager::Create(rendering_api_);
  ASSERT_NE(manager, nullptr);

  constexpr size_t kThreadCount = 4;
  constexpr size_t kIterations = 50;
  std::vector<std::thread> threads;
  threads.reserve(kThreadCount);

  for (size_t t = 0; t < kThreadCount; ++t) {
    threads.emplace_back([&manager]() {
      for (size_t i = 0; i < kIterations; ++i) {
        if (i % 2 == 0) {
          manager->SetNativeWindow(nullptr, /*is_fake_window=*/true);
          manager->MakeCurrent();
          manager->Present();
          manager->ClearCurrent();
        } else {
          manager->ClearNativeWindow();
          manager->GetNativeWindow();
          manager->GetNativeWindowSize();
        }
      }
    });
  }

  for (auto& thread : threads) {
    thread.join();
  }

  EXPECT_TRUE(manager->SetNativeWindow(nullptr, /*is_fake_window=*/true));
  EXPECT_TRUE(manager->MakeCurrent());
  EXPECT_TRUE(manager->Present());
  EXPECT_TRUE(manager->ClearCurrent());
}

INSTANTIATE_TEST_SUITE_P(
    Matrix,
    AndroidSurfaceManagerMultiBackendMatrixTest,
    ::testing::Values(AndroidRenderingAPI::kSoftware,
                      AndroidRenderingAPI::kSkiaOpenGLES,
                      AndroidRenderingAPI::kImpellerOpenGLES,
                      AndroidRenderingAPI::kImpellerVulkan,
                      AndroidRenderingAPI::kImpellerAutoselect),
    SurfaceMatrixTestName);

}  // namespace testing
}  // namespace flutter
