// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_surface_manager.h"

#include <dlfcn.h>
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

TEST(AndroidSurfaceManagerTest, RealImageReaderNativeWindowTest) {
#if FML_OS_ANDROID
  void* mediandk = dlopen("libmediandk.so", RTLD_NOW);
  if (!mediandk) {
    GTEST_SKIP() << "libmediandk.so not available";
  }
  typedef struct AImageReader AImageReader;
  typedef int32_t (*AImageReader_newWithUsage_fn)(
      int32_t width, int32_t height, int32_t format, uint64_t usage,
      int32_t maxImages, AImageReader** reader);
  typedef int32_t (*AImageReader_getWindow_fn)(AImageReader* reader,
                                               ANativeWindow** window);
  typedef void (*AImageReader_delete_fn)(AImageReader* reader);

  auto newWithUsage = reinterpret_cast<AImageReader_newWithUsage_fn>(
      dlsym(mediandk, "AImageReader_newWithUsage"));
  auto getWindow = reinterpret_cast<AImageReader_getWindow_fn>(
      dlsym(mediandk, "AImageReader_getWindow"));
  auto deleteReader = reinterpret_cast<AImageReader_delete_fn>(
      dlsym(mediandk, "AImageReader_delete"));

  if (!newWithUsage || !getWindow || !deleteReader) {
    dlclose(mediandk);
    GTEST_SKIP() << "AImageReader APIs not available";
  }

  // AIMAGE_FORMAT_RGBA_8888 = 1
  // AHARDWAREBUFFER_USAGE_GPU_SAMPLED_IMAGE = 1 << 8
  // AHARDWAREBUFFER_USAGE_GPU_COLOR_OUTPUT = 1 << 9
  constexpr uint64_t kUsage = (1ULL << 8) | (1ULL << 9);
  AImageReader* reader = nullptr;
  int32_t status = newWithUsage(640, 480, 1, kUsage, 3, &reader);
  ASSERT_EQ(status, 0) << "Failed to create AImageReader: " << status;
  ASSERT_NE(reader, nullptr);

  ANativeWindow* window = nullptr;
  status = getWindow(reader, &window);
  ASSERT_EQ(status, 0);
  ASSERT_NE(window, nullptr);

  auto manager =
      AndroidSurfaceManager::Create(AndroidRenderingAPI::kImpellerOpenGLES);
  ASSERT_NE(manager, nullptr);

  bool set_result = manager->SetNativeWindow(window);
  std::cout << "SetNativeWindow result: " << set_result << std::endl;
  EXPECT_TRUE(set_result);

  EGLint visual_id = -1;
  eglGetConfigAttrib(manager->GetEGLDisplay(), manager->GetEGLConfig(),
                     EGL_NATIVE_VISUAL_ID, &visual_id);
  std::cout << "EGL_NATIVE_VISUAL_ID: " << visual_id << std::endl;

  int geo_res = ANativeWindow_setBuffersGeometry(window, 0, 0, visual_id);
  std::cout << "ANativeWindow_setBuffersGeometry(window) result: " << geo_res
            << std::endl;

  if (set_result) {
    EXPECT_TRUE(manager->MakeCurrent());
    EXPECT_TRUE(manager->Present());
    // Leave context current! Do not clear!
  }

  // Create second ImageReader
  AImageReader* reader2 = nullptr;
  status = newWithUsage(640, 480, 1, kUsage, 3, &reader2);
  ASSERT_EQ(status, 0);
  ANativeWindow* window2 = nullptr;
  status = getWindow(reader2, &window2);
  ASSERT_EQ(status, 0);

  // Now call SetNativeWindow(window2) from another thread (simulating UI
  // thread)!
  bool thread_set_result = false;
  std::thread ui_thread([&]() {
    thread_set_result = manager->SetNativeWindow(window2);
    std::cout << "Thread SetNativeWindow(window2) result: " << thread_set_result
              << std::endl;
  });
  ui_thread.join();
  EXPECT_TRUE(thread_set_result);

  manager->ClearNativeWindow();
  deleteReader(reader);
  deleteReader(reader2);
  dlclose(mediandk);
#endif
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

TEST(AndroidSurfaceManagerTest, OffscreenFBOLifecycleAndPool) {
  auto manager =
      AndroidSurfaceManager::Create(AndroidRenderingAPI::kImpellerOpenGLES);
  ASSERT_NE(manager, nullptr);

  // 100x200 dimensions for test FBO.
  constexpr size_t kWidth = 100;
  constexpr size_t kHeight = 200;

  auto fbo1 = manager->AcquireOffscreenFBO(kWidth, kHeight);
  EXPECT_NE(fbo1.fbo, 0u);
  EXPECT_EQ(fbo1.width, kWidth);
  EXPECT_EQ(fbo1.height, kHeight);

  // Acquire second FBO with different dimensions.
  constexpr size_t kOtherWidth = 300;
  constexpr size_t kOtherHeight = 400;
  auto fbo2 = manager->AcquireOffscreenFBO(kOtherWidth, kOtherHeight);
  EXPECT_NE(fbo2.fbo, 0u);
  EXPECT_NE(fbo1.fbo, fbo2.fbo);

  // Release fbo1 back to pool.
  manager->ReleaseOffscreenFBO(fbo1);

  // Re-acquire matching dimensions should reuse fbo1.
  auto fbo1_reused = manager->AcquireOffscreenFBO(kWidth, kHeight);
  EXPECT_EQ(fbo1_reused.fbo, fbo1.fbo);

  manager->ReleaseOffscreenFBO(fbo1_reused);
  manager->ReleaseOffscreenFBO(fbo2);

  // Test BlitAndSwapOverlaySurface stub on host.
  EXPECT_TRUE(
      manager->BlitAndSwapOverlaySurface(nullptr, fbo1.fbo, kWidth, kHeight));
  manager->DestroyOverlaySurfaces();
}

TEST(AndroidSurfaceManagerTest,
     BlitAndSwapOverlaySurfaceNullWindowGracefulReturn) {
  auto manager =
      AndroidSurfaceManager::Create(AndroidRenderingAPI::kImpellerOpenGLES);
  ASSERT_NE(manager, nullptr);

  EXPECT_TRUE(manager->BlitAndSwapOverlaySurface(nullptr, /*offscreen_fbo=*/1,
                                                 /*width=*/100,
                                                 /*height=*/100));
}

TEST(AndroidSurfaceManagerTest, GlProcResolverResolvesViaDlsym) {
  auto manager =
      AndroidSurfaceManager::Create(AndroidRenderingAPI::kImpellerOpenGLES);
  ASSERT_NE(manager, nullptr);
  FlutterOpenGLRendererConfig config = {};
  manager->PopulateGLRendererConfig(&config);
  ASSERT_NE(config.gl_proc_resolver, nullptr);
  void* proc = config.gl_proc_resolver(nullptr, "dlsym");
  EXPECT_NE(proc, nullptr);
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
