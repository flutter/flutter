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

class AndroidSurfaceManagerTest : public ::testing::Test {
 public:
  static void SetMockHandles(AndroidSurfaceManager* manager,
                             ANativeWindow* window,
                             VkInstance instance,
                             VkDevice device) {
    manager->native_window_ = window;
    manager->is_fake_window_ = false;
    manager->vk_instance_ = instance;
    manager->vk_device_ = device;
  }

  static void PopulateDummyVulkanProcs(AndroidSurfaceManager* manager) {
    void* dummy = reinterpret_cast<void*>(0x1);
    manager->vk_create_android_surface_khr_fn_ =
        reinterpret_cast<PFN_vkCreateAndroidSurfaceKHR>(dummy);
    manager->vk_get_physical_device_surface_support_khr_fn_ =
        reinterpret_cast<PFN_vkGetPhysicalDeviceSurfaceSupportKHR>(dummy);
    manager->vk_get_physical_device_surface_capabilities_khr_fn_ =
        reinterpret_cast<PFN_vkGetPhysicalDeviceSurfaceCapabilitiesKHR>(dummy);
    manager->vk_get_physical_device_surface_formats_khr_fn_ =
        reinterpret_cast<PFN_vkGetPhysicalDeviceSurfaceFormatsKHR>(dummy);
    manager->vk_create_swapchain_khr_fn_ =
        reinterpret_cast<PFN_vkCreateSwapchainKHR>(dummy);
    manager->vk_get_swapchain_images_khr_fn_ =
        reinterpret_cast<PFN_vkGetSwapchainImagesKHR>(dummy);
    manager->vk_create_command_pool_fn_ =
        reinterpret_cast<PFN_vkCreateCommandPool>(dummy);
    manager->vk_allocate_command_buffers_fn_ =
        reinterpret_cast<PFN_vkAllocateCommandBuffers>(dummy);
    manager->vk_create_fence_fn_ = reinterpret_cast<PFN_vkCreateFence>(dummy);
  }

  static void ClearVulkanCapabilitiesProc(AndroidSurfaceManager* manager) {
    manager->vk_get_physical_device_surface_capabilities_khr_fn_ = nullptr;
  }

  static void ClearVulkanSwapchainProc(AndroidSurfaceManager* manager) {
    manager->vk_create_swapchain_khr_fn_ = nullptr;
  }

  static bool CallCreateOrUpdateVulkanSurfaceLocked(
      AndroidSurfaceManager* manager) {
    std::lock_guard<std::mutex> lock(manager->window_mutex_);
    return manager->CreateOrUpdateVulkanSurfaceLocked();
  }

  static bool CallCreateOrUpdateOverlayVulkanSurfaceLocked(
      AndroidSurfaceManager* manager,
      ANativeWindow* window) {
    std::lock_guard<std::mutex> lock(manager->window_mutex_);
    AndroidSurfaceManager::VulkanOverlaySurface entry;
    return manager->CreateOrUpdateOverlayVulkanSurfaceLocked(window, entry);
  }

  static void ResetMockHandles(AndroidSurfaceManager* manager) {
    manager->native_window_ = nullptr;
    manager->vk_instance_ = VK_NULL_HANDLE;
    manager->vk_device_ = VK_NULL_HANDLE;
  }
};

TEST_F(AndroidSurfaceManagerTest, LifecycleAndInitialState) {
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

TEST_F(AndroidSurfaceManagerTest, SetAndClearNativeWindowFake) {
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

TEST_F(AndroidSurfaceManagerTest, RealImageReaderNativeWindowTest) {
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

TEST_F(AndroidSurfaceManagerTest, SoftwarePresentValidation) {
  auto manager = AndroidSurfaceManager::Create(AndroidRenderingAPI::kSoftware);
  ASSERT_NE(manager, nullptr);

  // Without window, software present fails
  uint8_t dummy_pixels[64] = {0};
  EXPECT_FALSE(manager->PresentSoftware(dummy_pixels, 16, 4));

  // With fake window, software present succeeds
  EXPECT_TRUE(manager->SetNativeWindow(nullptr, /*is_fake_window=*/true));
  EXPECT_TRUE(manager->PresentSoftware(dummy_pixels, 16, 4));
}

TEST_F(AndroidSurfaceManagerTest, PopulateGLRendererConfig) {
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

TEST_F(AndroidSurfaceManagerTest, PopulateSoftwareRendererConfig) {
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

TEST_F(AndroidSurfaceManagerTest, ConcurrentThreadSafety) {
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

TEST_F(AndroidSurfaceManagerTest, OffscreenFBOLifecycleAndPool) {
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

TEST_F(AndroidSurfaceManagerTest,
       BlitAndSwapOverlaySurfaceNullWindowGracefulReturn) {
  auto manager =
      AndroidSurfaceManager::Create(AndroidRenderingAPI::kImpellerOpenGLES);
  ASSERT_NE(manager, nullptr);

  EXPECT_TRUE(manager->BlitAndSwapOverlaySurface(nullptr, /*offscreen_fbo=*/1,
                                                 /*width=*/100,
                                                 /*height=*/100));
}

TEST_F(AndroidSurfaceManagerTest, GlProcResolverResolvesViaDlsym) {
  auto manager =
      AndroidSurfaceManager::Create(AndroidRenderingAPI::kImpellerOpenGLES);
  ASSERT_NE(manager, nullptr);
  FlutterOpenGLRendererConfig config = {};
  manager->PopulateGLRendererConfig(&config);
  ASSERT_NE(config.gl_proc_resolver, nullptr);
  void* proc = config.gl_proc_resolver(nullptr, "dlsym");
  EXPECT_NE(proc, nullptr);
}

TEST_F(AndroidSurfaceManagerTest, PresentImageValidatesSwapchainImages) {
  auto manager =
      AndroidSurfaceManager::Create(AndroidRenderingAPI::kImpellerVulkan);
  ASSERT_NE(manager, nullptr);

  // PresentImage with nullptr image should return false safely without
  // crashing.
  EXPECT_FALSE(manager->PresentImage(nullptr));

  // Without a valid swapchain, PresentImage with a stale image should return
  // false.
  FlutterVulkanImage stale_image = {};
  stale_image.struct_size = sizeof(FlutterVulkanImage);
  stale_image.image = 0xdeadbeef;
  // 37 is VK_FORMAT_R8G8B8A8_UNORM
  stale_image.format = 37;
  EXPECT_FALSE(manager->PresentImage(&stale_image));

  // With a fake window, PresentImage returns true for testing stubs.
  EXPECT_TRUE(manager->SetNativeWindow(nullptr, /*is_fake_window=*/true));
  EXPECT_TRUE(manager->PresentImage(&stale_image));
  manager->ClearNativeWindow();
}

TEST_F(AndroidSurfaceManagerTest, VulkanOverlaySurfaceLifecycle) {
  auto manager =
      AndroidSurfaceManager::Create(AndroidRenderingAPI::kImpellerVulkan);
  ASSERT_NE(manager, nullptr);

  // Without a window or fake window, GetNextOverlayImage returns empty image.
  FlutterVulkanImage img = manager->GetNextOverlayImage(nullptr);
  EXPECT_EQ(img.image, 0u);

  // PresentOverlayImage with nullptr returns false safely.
  EXPECT_FALSE(manager->PresentOverlayImage(nullptr, nullptr));

  // With a fake window, GetNextOverlayImage returns mock image (0x2000)
  // and PresentOverlayImage returns true.
  EXPECT_TRUE(manager->SetNativeWindow(nullptr, /*is_fake_window=*/true));
  FlutterVulkanImage overlay_img = manager->GetNextOverlayImage(nullptr);
  // 0x2000 is mock overlay image handle for unit tests without Vulkan hardware
  EXPECT_EQ(overlay_img.image, 0x2000u);
  // 37 is VK_FORMAT_R8G8B8A8_UNORM
  EXPECT_EQ(overlay_img.format, 37u);

  EXPECT_TRUE(manager->PresentOverlayImage(nullptr, &overlay_img));

  // DestroyOverlaySurfaces cleans up overlay resources safely.
  manager->DestroyOverlaySurfaces();
  manager->ClearNativeWindow();
}

TEST_F(AndroidSurfaceManagerTest, ClearAndPresentOnscreenSurfaceFakeWindow) {
  auto manager =
      AndroidSurfaceManager::Create(AndroidRenderingAPI::kImpellerVulkan);
  ASSERT_NE(manager, nullptr);
  EXPECT_TRUE(manager->SetNativeWindow(nullptr, /*is_fake_window=*/true));
  EXPECT_TRUE(manager->ClearAndPresentOnscreenSurface());
  manager->ClearNativeWindow();
}

TEST_F(AndroidSurfaceManagerTest, VulkanSwapchainUsageInitialAndReset) {
  auto manager =
      AndroidSurfaceManager::Create(AndroidRenderingAPI::kImpellerVulkan);
  ASSERT_NE(manager, nullptr);
  // Default swapchain usage flags are uninitialized (0) before surface
  // creation.
  EXPECT_EQ(manager->GetVulkanSwapchainUsage(),
            static_cast<VkImageUsageFlags>(0));

  EXPECT_TRUE(manager->SetNativeWindow(nullptr, /*is_fake_window=*/true));
  // In fake window mode without a native window, no real swapchain is created,
  // so usage remains 0.
  EXPECT_EQ(manager->GetVulkanSwapchainUsage(),
            static_cast<VkImageUsageFlags>(0));

  manager->ClearNativeWindow();
  // ClearNativeWindow calls DestroyVulkanSurfaceLocked, ensuring usage resets
  // to 0.
  EXPECT_EQ(manager->GetVulkanSwapchainUsage(),
            static_cast<VkImageUsageFlags>(0));

#if FML_OS_ANDROID
  void* mediandk = dlopen("libmediandk.so", RTLD_NOW);
  if (mediandk) {
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

    if (newWithUsage && getWindow && deleteReader) {
      // (1ULL << 8) is AHARDWAREBUFFER_USAGE_GPU_SAMPLED_IMAGE
      // (1ULL << 9) is AHARDWAREBUFFER_USAGE_GPU_COLOR_OUTPUT
      constexpr uint64_t kUsage = (1ULL << 8) | (1ULL << 9);
      AImageReader* reader = nullptr;
      // 640 and 480 are test buffer dimensions.
      // 1 is AIMAGE_FORMAT_RGBA_8888.
      // 3 is maxImages buffer queue depth.
      constexpr int32_t kWidth = 640;
      constexpr int32_t kHeight = 480;
      constexpr int32_t kFormatRgba8888 = 1;
      constexpr int32_t kMaxImages = 3;
      int32_t status = newWithUsage(kWidth, kHeight, kFormatRgba8888, kUsage,
                                    kMaxImages, &reader);
      if (status == 0 && reader != nullptr) {
        ANativeWindow* window = nullptr;
        if (getWindow(reader, &window) == 0 && window != nullptr) {
          if (manager->IsVulkanInitialized() &&
              manager->SetNativeWindow(window, /*is_fake_window=*/false)) {
            // When a real Vulkan swapchain is established, COLOR_ATTACHMENT
            // must be set.
            EXPECT_NE(manager->GetVulkanSwapchainUsage() &
                          VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT,
                      0u);
          }
          manager->ClearNativeWindow();
          EXPECT_EQ(manager->GetVulkanSwapchainUsage(),
                    static_cast<VkImageUsageFlags>(0));
        }
        deleteReader(reader);
      }
    }
    dlclose(mediandk);
  }
#endif
}

TEST_F(AndroidSurfaceManagerTest, VulkanNullFunctionPointersHandledSafely) {
  auto manager =
      AndroidSurfaceManager::Create(AndroidRenderingAPI::kImpellerVulkan);
  ASSERT_NE(manager, nullptr);

  auto dummy_window = reinterpret_cast<ANativeWindow*>(0x1);
  auto dummy_instance = reinterpret_cast<VkInstance>(0x1);
  auto dummy_device = reinterpret_cast<VkDevice>(0x1);

  // Configure non-null mock state so handle and window checks succeed.
  SetMockHandles(manager.get(), dummy_window, dummy_instance, dummy_device);
  PopulateDummyVulkanProcs(manager.get());

  // 1. Verify that when capabilities fn is null, surface creation fails
  // safely.
  ClearVulkanCapabilitiesProc(manager.get());
  EXPECT_FALSE(CallCreateOrUpdateVulkanSurfaceLocked(manager.get()));
  EXPECT_FALSE(CallCreateOrUpdateOverlayVulkanSurfaceLocked(manager.get(),
                                                            dummy_window));

  // 2. Restore capabilities fn and clear swapchain fn; verify safe failure.
  PopulateDummyVulkanProcs(manager.get());
  ClearVulkanSwapchainProc(manager.get());
  EXPECT_FALSE(CallCreateOrUpdateVulkanSurfaceLocked(manager.get()));
  EXPECT_FALSE(CallCreateOrUpdateOverlayVulkanSurfaceLocked(manager.get(),
                                                            dummy_window));

  // Reset handles before manager destruction to avoid attempting real
  // teardown on dummy handles.
  ResetMockHandles(manager.get());
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
