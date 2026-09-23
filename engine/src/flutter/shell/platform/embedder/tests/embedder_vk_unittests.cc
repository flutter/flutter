// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include <cstring>
#include <string>
#include <utility>
#include <vector>

#include "embedder.h"
#include "embedder_engine.h"
#include "flutter/fml/synchronization/count_down_latch.h"
#include "flutter/shell/platform/embedder/tests/embedder_config_builder.h"
#include "flutter/shell/platform/embedder/tests/embedder_test.h"
#include "flutter/shell/platform/embedder/tests/embedder_test_context_vulkan.h"
#include "flutter/shell/platform/embedder/tests/embedder_unittests_util.h"
#include "flutter/testing/test_vulkan_context.h"
#include "flutter/testing/test_vulkan_image.h"
#include "flutter/testing/test_vulkan_surface.h"
#include "flutter/testing/testing.h"
#include "gmock/gmock.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkColor.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/skia/include/core/SkSurfaceProps.h"
#include "third_party/skia/include/gpu/ganesh/GrBackendSurface.h"
#include "third_party/skia/include/gpu/ganesh/GrDirectContext.h"
#include "third_party/skia/include/gpu/ganesh/SkSurfaceGanesh.h"
#include "third_party/skia/include/gpu/ganesh/vk/GrVkBackendSurface.h"
#include "third_party/skia/include/gpu/ganesh/vk/GrVkTypes.h"

// CREATE_FFI_LAMBDA is leaky by design
// NOLINTBEGIN(clang-analyzer-core.StackAddressEscape)

namespace flutter {
namespace testing {

using EmbedderTest = testing::EmbedderTest;

////////////////////////////////////////////////////////////////////////////////
// Notice: Other Vulkan unit tests exist in embedder_gl_unittests.cc.
//         See https://github.com/flutter/flutter/issues/134322
////////////////////////////////////////////////////////////////////////////////

namespace {

struct VulkanProcInfo {
  PFN_vkGetInstanceProcAddr get_instance_proc_addr = nullptr;
  PFN_vkGetDeviceProcAddr get_device_proc_addr = nullptr;
  PFN_vkQueueSubmit queue_submit_proc_addr = nullptr;
  bool did_call_queue_submit = false;
};

static_assert(std::is_trivially_destructible_v<VulkanProcInfo>);

VulkanProcInfo g_vulkan_proc_info;

VkResult QueueSubmit(VkQueue queue,
                     uint32_t submitCount,
                     const VkSubmitInfo* pSubmits,
                     VkFence fence) {
  FML_DCHECK(g_vulkan_proc_info.queue_submit_proc_addr != nullptr);
  g_vulkan_proc_info.did_call_queue_submit = true;
  return g_vulkan_proc_info.queue_submit_proc_addr(queue, submitCount, pSubmits,
                                                   fence);
}

template <size_t N>
int StrcmpFixed(const char* str1, const char (&str2)[N]) {
  return strncmp(str1, str2, N - 1);
}

PFN_vkVoidFunction GetDeviceProcAddr(VkDevice device, const char* pName) {
  FML_DCHECK(g_vulkan_proc_info.get_device_proc_addr != nullptr);
  if (StrcmpFixed(pName, "vkQueueSubmit") == 0) {
    g_vulkan_proc_info.queue_submit_proc_addr =
        reinterpret_cast<PFN_vkQueueSubmit>(
            g_vulkan_proc_info.get_device_proc_addr(device, pName));
    return reinterpret_cast<PFN_vkVoidFunction>(QueueSubmit);
  }
  return g_vulkan_proc_info.get_device_proc_addr(device, pName);
}

PFN_vkVoidFunction GetInstanceProcAddr(VkInstance instance, const char* pName) {
  FML_DCHECK(g_vulkan_proc_info.get_instance_proc_addr != nullptr);
  if (StrcmpFixed(pName, "vkGetDeviceProcAddr") == 0) {
    g_vulkan_proc_info.get_device_proc_addr =
        reinterpret_cast<PFN_vkGetDeviceProcAddr>(
            g_vulkan_proc_info.get_instance_proc_addr(instance, pName));
    return reinterpret_cast<PFN_vkVoidFunction>(GetDeviceProcAddr);
  }
  return g_vulkan_proc_info.get_instance_proc_addr(instance, pName);
}

template <typename T, typename U>
struct CheckSameSignature : std::false_type {};

template <typename Ret, typename... Args>
struct CheckSameSignature<Ret(Args...), Ret(Args...)> : std::true_type {};

static_assert(CheckSameSignature<
              decltype(GetInstanceProcAddr),
              std::remove_pointer_t<PFN_vkGetInstanceProcAddr>>::value);
static_assert(
    CheckSameSignature<decltype(GetDeviceProcAddr),
                       std::remove_pointer_t<PFN_vkGetDeviceProcAddr>>::value);
static_assert(
    CheckSameSignature<decltype(QueueSubmit),
                       std::remove_pointer_t<PFN_vkQueueSubmit>>::value);
}  // namespace

TEST_F(EmbedderTest, CanGetVulkanEmbedderContext) {
  EmbedderTestContextVulkan& context =
      GetEmbedderContext<EmbedderTestContextVulkan>();
  EmbedderConfigBuilder builder(context);
}

TEST_F(EmbedderTest, CanSwapOutVulkanCalls) {
  fml::AutoResetWaitableEvent latch;

  EmbedderTestContextVulkan& context =
      GetEmbedderContext<EmbedderTestContextVulkan>();
  context.AddIsolateCreateCallback([&latch]() { latch.Signal(); });
  context.SetVulkanInstanceProcAddressCallback(
      [](void* user_data, FlutterVulkanInstanceHandle instance,
         const char* name) -> void* {
        if (StrcmpFixed(name, "vkGetInstanceProcAddr") == 0) {
          g_vulkan_proc_info.get_instance_proc_addr =
              reinterpret_cast<PFN_vkGetInstanceProcAddr>(
                  EmbedderTestContextVulkan::InstanceProcAddr(user_data,
                                                              instance, name));
          return reinterpret_cast<void*>(GetInstanceProcAddr);
        }
        return EmbedderTestContextVulkan::InstanceProcAddr(user_data, instance,
                                                           name);
      });

  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1024, 1024));
  UniqueEngine engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());
  // Wait for the root isolate to launch.
  latch.Wait();
  engine.reset();
  EXPECT_TRUE(g_vulkan_proc_info.did_call_queue_submit);
}

namespace {
std::optional<TestVulkanImage> CreateVulkanTextureWithPixels(
    const fml::RefPtr<TestVulkanContext>& context,
    int width,
    int height,
    VkFormat format = VK_FORMAT_R8G8B8A8_UNORM) {
  std::optional<TestVulkanImage> image_result =
      context->CreateImage({width, height}, format);
  if (!image_result.has_value()) {
    FML_LOG(ERROR) << "Could not create VkImage for external texture.";
    return std::nullopt;
  }

  SkColorType color_type = kRGBA_8888_SkColorType;
  if (format == VK_FORMAT_B8G8R8A8_UNORM) {
    color_type = kBGRA_8888_SkColorType;
  }

  GrVkImageInfo image_info = {
      .fImage = image_result.value().GetImage(),
      .fImageTiling = VK_IMAGE_TILING_OPTIMAL,
      .fImageLayout = VK_IMAGE_LAYOUT_UNDEFINED,
      .fFormat = format,
      .fImageUsageFlags = VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT |
                          VK_IMAGE_USAGE_TRANSFER_SRC_BIT |
                          VK_IMAGE_USAGE_TRANSFER_DST_BIT |
                          VK_IMAGE_USAGE_SAMPLED_BIT,
      .fSampleCount = 1,
      .fLevelCount = 1,
  };
  GrBackendTexture backend_texture =
      GrBackendTextures::MakeVk(width, height, image_info);

  SkSurfaceProps surface_properties(0, kUnknown_SkPixelGeometry);
  sk_sp<SkSurface> surface = SkSurfaces::WrapBackendTexture(
      context->GetGrDirectContext().get(), backend_texture,
      kTopLeft_GrSurfaceOrigin, 1, color_type, SkColorSpace::MakeSRGB(),
      &surface_properties, nullptr, nullptr);

  if (!surface) {
    FML_LOG(ERROR) << "Could not wrap VkImage as SkSurface for drawing.";
    return std::nullopt;
  }

  SkCanvas* canvas = surface->getCanvas();
  // Top half red.
  SkPaint red_paint;
  red_paint.setColor(SK_ColorRED);
  canvas->drawRect(SkRect::MakeWH(width, height / 2), red_paint);
  // Bottom half blue.
  SkPaint blue_paint;
  blue_paint.setColor(SK_ColorBLUE);
  canvas->drawRect(SkRect::MakeXYWH(0, height / 2, width, height / 2),
                   blue_paint);

  context->GetGrDirectContext()->flushAndSubmit();

  return std::move(image_result.value());
}

std::optional<TestVulkanImage> CreateVulkanTextureNV12(
    const fml::RefPtr<TestVulkanContext>& context,
    int width,
    int height) {
  std::unique_ptr<fml::Mapping> nv12_mapping =
      testing::OpenFixtureAsMapping("texture.nv12");
  if (!nv12_mapping || nv12_mapping->GetSize() == 0) {
    FML_LOG(ERROR) << "Could not load texture.nv12 fixture.";
    return std::nullopt;
  }

  size_t y_size = static_cast<size_t>(width) * height;
  const uint8_t* y_data = nv12_mapping->GetMapping();
  const uint8_t* uv_data = y_data + y_size;

  return context->CreateNV12Image({width, height}, y_data, uv_data);
}

void DeleteTestVulkanImage(void* user_data) {
  delete static_cast<TestVulkanImage*>(user_data);
}
}  // namespace

TEST_F(EmbedderTest, RenderTextureWithImpellerVulkan) {
  constexpr int kWidth = 800;
  constexpr int kHeight = 600;
  EmbedderTestContextVulkan& context =
      GetEmbedderContext<EmbedderTestContextVulkan>();
  EmbedderConfigBuilder builder(context);
  fml::AutoResetWaitableEvent latch;
  ON_CALL(context.PresentCallbackMock(), Call()).WillByDefault([&] {
    latch.Signal();
  });
  builder.AddCommandLineArgument("--enable-impeller");
  builder.SetDartEntrypoint("render_texture_impeller_test");
  builder.SetSurface(DlISize(kWidth, kHeight));

  std::future<sk_sp<SkImage>> rendered_scene = context.GetNextSceneImage();
  context.GetRendererConfig().vulkan.external_texture_frame_callback =
      [](void* user_data, int64_t texture_id, size_t width, size_t height,
         FlutterVulkanExternalTexture* texture) -> bool {
    EmbedderTestContextVulkan* embedder_test_context =
        static_cast<EmbedderTestContextVulkan*>(user_data);
    std::optional<TestVulkanImage> texture_image =
        CreateVulkanTextureWithPixels(embedder_test_context->vulkan_context(),
                                      kWidth, kHeight);
    if (!texture_image.has_value()) {
      return false;
    }
    TestVulkanImage* img =
        new TestVulkanImage(std::move(texture_image.value()));
    texture->image = reinterpret_cast<uint64_t>(img->GetImage());
    texture->format = VK_FORMAT_R8G8B8A8_UNORM;
    texture->destruction_callback = DeleteTestVulkanImage;
    texture->user_data = img;
    texture->width = width;
    texture->height = height;
    return true;
  };

  UniqueEngine engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  flutter::EmbedderEngine* embedder_engine = ToEmbedderEngine(engine.get());

  constexpr int texture_id = 1;
  ASSERT_TRUE(embedder_engine->RegisterTexture(texture_id));

  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(event);
  event.width = kWidth;
  event.height = kHeight;
  event.pixel_ratio = 1.0;
  ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &event),
            kSuccess);
  latch.Wait();
  ASSERT_TRUE(
      ImageMatchesFixture("external_texture_impeller.png", rendered_scene));

  constexpr int kFrameCount = 5;
  for (int i = 0; i < kFrameCount; i++) {
    rendered_scene = context.GetNextSceneImage();
    ASSERT_TRUE(embedder_engine->MarkTextureFrameAvailable(texture_id));
    latch.Wait();
    ASSERT_TRUE(
        ImageMatchesFixture("external_texture_impeller.png", rendered_scene));
  }
}

TEST_F(EmbedderTest, RenderTextureWithSkiaVulkan) {
  constexpr int kWidth = 800;
  constexpr int kHeight = 600;
  EmbedderTestContextVulkan& context =
      GetEmbedderContext<EmbedderTestContextVulkan>();
  EmbedderConfigBuilder builder(context);
  fml::AutoResetWaitableEvent latch;
  ON_CALL(context.PresentCallbackMock(), Call()).WillByDefault([&] {
    latch.Signal();
  });
  builder.SetDartEntrypoint("render_texture_impeller_test");
  builder.SetSurface(DlISize(kWidth, kHeight));

  std::future<sk_sp<SkImage>> rendered_scene = context.GetNextSceneImage();
  context.GetRendererConfig().vulkan.external_texture_frame_callback =
      [](void* user_data, int64_t texture_id, size_t width, size_t height,
         FlutterVulkanExternalTexture* texture) -> bool {
    EmbedderTestContextVulkan* embedder_test_context =
        static_cast<EmbedderTestContextVulkan*>(user_data);
    std::optional<TestVulkanImage> texture_image =
        CreateVulkanTextureWithPixels(embedder_test_context->vulkan_context(),
                                      kWidth, kHeight);
    if (!texture_image.has_value()) {
      return false;
    }
    TestVulkanImage* img =
        new TestVulkanImage(std::move(texture_image.value()));
    texture->image = reinterpret_cast<uint64_t>(img->GetImage());
    texture->format = VK_FORMAT_R8G8B8A8_UNORM;
    texture->destruction_callback = DeleteTestVulkanImage;
    texture->user_data = img;
    texture->width = width;
    texture->height = height;
    return true;
  };

  UniqueEngine engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  flutter::EmbedderEngine* embedder_engine = ToEmbedderEngine(engine.get());

  constexpr int texture_id = 1;
  ASSERT_TRUE(embedder_engine->RegisterTexture(texture_id));

  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(event);
  event.width = kWidth;
  event.height = kHeight;
  event.pixel_ratio = 1.0;
  ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &event),
            kSuccess);
  latch.Wait();
  ASSERT_TRUE(
      ImageMatchesFixture("external_texture_impeller.png", rendered_scene));

  constexpr int kFrameCount = 5;
  for (int i = 0; i < kFrameCount; i++) {
    rendered_scene = context.GetNextSceneImage();
    ASSERT_TRUE(embedder_engine->MarkTextureFrameAvailable(texture_id));
    latch.Wait();
    ASSERT_TRUE(
        ImageMatchesFixture("external_texture_impeller.png", rendered_scene));
  }
}

TEST_F(EmbedderTest, RenderTextureWithImpellerVulkanDestructCallback) {
  constexpr int kWidth = 800;
  constexpr int kHeight = 600;
  EmbedderTestContextVulkan& context =
      GetEmbedderContext<EmbedderTestContextVulkan>();
  EmbedderConfigBuilder builder(context);
  fml::AutoResetWaitableEvent latch;
  ON_CALL(context.PresentCallbackMock(), Call()).WillByDefault([&] {
    latch.Signal();
  });
  builder.AddCommandLineArgument("--enable-impeller");
  builder.SetDartEntrypoint("render_texture_impeller_test");
  builder.SetSurface(DlISize(kWidth, kHeight));

  std::future<sk_sp<SkImage>> rendered_scene = context.GetNextSceneImage();

  static bool destruction_callback_called = false;
  static VoidCallback destruction_callback = [](void* user_data) {
    TestVulkanImage* img = static_cast<TestVulkanImage*>(user_data);
    delete img;
    destruction_callback_called = true;
  };

  context.GetRendererConfig().vulkan.external_texture_frame_callback =
      [](void* user_data, int64_t texture_id, size_t width, size_t height,
         FlutterVulkanExternalTexture* texture) -> bool {
    EmbedderTestContextVulkan* embedder_test_context =
        static_cast<EmbedderTestContextVulkan*>(user_data);
    std::optional<TestVulkanImage> texture_image =
        CreateVulkanTextureWithPixels(embedder_test_context->vulkan_context(),
                                      kWidth, kHeight);
    if (!texture_image.has_value()) {
      return false;
    }
    TestVulkanImage* img =
        new TestVulkanImage(std::move(texture_image.value()));
    texture->image = reinterpret_cast<uint64_t>(img->GetImage());
    texture->format = VK_FORMAT_R8G8B8A8_UNORM;
    texture->destruction_callback = destruction_callback;
    texture->user_data = img;
    texture->width = width;
    texture->height = height;
    return true;
  };

  UniqueEngine engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  flutter::EmbedderEngine* embedder_engine = ToEmbedderEngine(engine.get());

  constexpr int texture_id = 1;
  ASSERT_TRUE(embedder_engine->RegisterTexture(texture_id));

  // Send a window metrics event so frames may be scheduled.
  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(event);
  event.width = kWidth;
  event.height = kHeight;
  event.pixel_ratio = 1.0;
  ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &event),
            kSuccess);
  latch.Wait();
  ASSERT_TRUE(
      ImageMatchesFixture("external_texture_impeller.png", rendered_scene));

  // Render a second frame.
  ASSERT_TRUE(embedder_engine->MarkTextureFrameAvailable(texture_id));
  latch.Wait();

  // After the second frame completes, Impeller will have collected the handle
  // of the first frame's texture and called its destruction callback.
  ASSERT_TRUE(destruction_callback_called);
}

TEST_F(EmbedderTest, RenderTextureWithSkiaVulkanDestructCallback) {
  constexpr int kWidth = 800;
  constexpr int kHeight = 600;
  EmbedderTestContextVulkan& context =
      GetEmbedderContext<EmbedderTestContextVulkan>();
  EmbedderConfigBuilder builder(context);
  fml::AutoResetWaitableEvent latch;
  ON_CALL(context.PresentCallbackMock(), Call()).WillByDefault([&] {
    latch.Signal();
  });
  builder.SetDartEntrypoint("render_texture_impeller_test");
  builder.SetSurface(DlISize(kWidth, kHeight));

  std::future<sk_sp<SkImage>> rendered_scene = context.GetNextSceneImage();

  static bool destruction_callback_called = false;
  static VoidCallback destruction_callback = [](void* user_data) {
    TestVulkanImage* img = static_cast<TestVulkanImage*>(user_data);
    delete img;
    destruction_callback_called = true;
  };

  context.GetRendererConfig().vulkan.external_texture_frame_callback =
      [](void* user_data, int64_t texture_id, size_t width, size_t height,
         FlutterVulkanExternalTexture* texture) -> bool {
    EmbedderTestContextVulkan* embedder_test_context =
        static_cast<EmbedderTestContextVulkan*>(user_data);
    std::optional<TestVulkanImage> texture_image =
        CreateVulkanTextureWithPixels(embedder_test_context->vulkan_context(),
                                      kWidth, kHeight);
    if (!texture_image.has_value()) {
      return false;
    }
    TestVulkanImage* img =
        new TestVulkanImage(std::move(texture_image.value()));
    texture->image = reinterpret_cast<uint64_t>(img->GetImage());
    texture->format = VK_FORMAT_R8G8B8A8_UNORM;
    texture->destruction_callback = destruction_callback;
    texture->user_data = img;
    texture->width = width;
    texture->height = height;
    return true;
  };

  UniqueEngine engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  flutter::EmbedderEngine* embedder_engine = ToEmbedderEngine(engine.get());

  constexpr int texture_id = 1;
  ASSERT_TRUE(embedder_engine->RegisterTexture(texture_id));

  // Send a window metrics event so frames may be scheduled.
  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(event);
  event.width = kWidth;
  event.height = kHeight;
  event.pixel_ratio = 1.0;
  ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &event),
            kSuccess);
  latch.Wait();
  ASSERT_TRUE(
      ImageMatchesFixture("external_texture_impeller.png", rendered_scene));

  // Render a second frame.
  ASSERT_TRUE(embedder_engine->MarkTextureFrameAvailable(texture_id));
  latch.Wait();

  // After the second frame completes, Impeller will have collected the handle
  // of the first frame's texture and called its destruction callback.
  ASSERT_TRUE(destruction_callback_called);
}

// Tests that a BGRA external texture renders correctly (red/blue channels
// are not swapped) when using the Impeller backend.
TEST_F(EmbedderTest, RenderBGRATextureWithImpellerVulkan) {
  constexpr int kWidth = 800;
  constexpr int kHeight = 600;
  EmbedderTestContextVulkan& context =
      GetEmbedderContext<EmbedderTestContextVulkan>();
  EmbedderConfigBuilder builder(context);
  fml::AutoResetWaitableEvent latch;
  ON_CALL(context.PresentCallbackMock(), Call()).WillByDefault([&] {
    latch.Signal();
  });
  builder.AddCommandLineArgument("--enable-impeller");
  builder.SetDartEntrypoint("render_texture_impeller_test");
  builder.SetSurface(DlISize(kWidth, kHeight));

  std::future<sk_sp<SkImage>> rendered_scene = context.GetNextSceneImage();
  context.GetRendererConfig().vulkan.external_texture_frame_callback =
      [](void* user_data, int64_t texture_id, size_t width, size_t height,
         FlutterVulkanExternalTexture* texture) -> bool {
    EmbedderTestContextVulkan* embedder_test_context =
        static_cast<EmbedderTestContextVulkan*>(user_data);
    std::optional<TestVulkanImage> texture_image =
        CreateVulkanTextureWithPixels(embedder_test_context->vulkan_context(),
                                      kWidth, kHeight,
                                      VK_FORMAT_B8G8R8A8_UNORM);
    if (!texture_image.has_value()) {
      return false;
    }
    TestVulkanImage* img =
        new TestVulkanImage(std::move(texture_image.value()));
    texture->image = reinterpret_cast<uint64_t>(img->GetImage());
    texture->format = VK_FORMAT_B8G8R8A8_UNORM;
    texture->destruction_callback = DeleteTestVulkanImage;
    texture->user_data = img;
    texture->width = width;
    texture->height = height;
    return true;
  };

  UniqueEngine engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  flutter::EmbedderEngine* embedder_engine = ToEmbedderEngine(engine.get());

  constexpr int texture_id = 1;
  ASSERT_TRUE(embedder_engine->RegisterTexture(texture_id));

  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(event);
  event.width = kWidth;
  event.height = kHeight;
  event.pixel_ratio = 1.0;
  ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &event),
            kSuccess);
  latch.Wait();
  // The rendered scene should match the same fixture as RGBA since the
  // BGRA-to-SkColorType mapping should prevent channel swapping.
  ASSERT_TRUE(
      ImageMatchesFixture("external_texture_impeller.png", rendered_scene));
}

// Tests that a BGRA external texture renders correctly (red/blue channels
// are not swapped) when using the Skia backend.
TEST_F(EmbedderTest, RenderBGRATextureWithSkiaVulkan) {
  constexpr int kWidth = 800;
  constexpr int kHeight = 600;
  EmbedderTestContextVulkan& context =
      GetEmbedderContext<EmbedderTestContextVulkan>();
  EmbedderConfigBuilder builder(context);
  fml::AutoResetWaitableEvent latch;
  ON_CALL(context.PresentCallbackMock(), Call()).WillByDefault([&] {
    latch.Signal();
  });
  builder.SetDartEntrypoint("render_texture_impeller_test");
  builder.SetSurface(DlISize(kWidth, kHeight));

  std::future<sk_sp<SkImage>> rendered_scene = context.GetNextSceneImage();
  context.GetRendererConfig().vulkan.external_texture_frame_callback =
      [](void* user_data, int64_t texture_id, size_t width, size_t height,
         FlutterVulkanExternalTexture* texture) -> bool {
    EmbedderTestContextVulkan* embedder_test_context =
        static_cast<EmbedderTestContextVulkan*>(user_data);
    std::optional<TestVulkanImage> texture_image =
        CreateVulkanTextureWithPixels(embedder_test_context->vulkan_context(),
                                      kWidth, kHeight,
                                      VK_FORMAT_B8G8R8A8_UNORM);
    if (!texture_image.has_value()) {
      return false;
    }
    TestVulkanImage* img =
        new TestVulkanImage(std::move(texture_image.value()));
    texture->image = reinterpret_cast<uint64_t>(img->GetImage());
    texture->format = VK_FORMAT_B8G8R8A8_UNORM;
    texture->destruction_callback = DeleteTestVulkanImage;
    texture->user_data = img;
    texture->width = width;
    texture->height = height;
    return true;
  };

  UniqueEngine engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  flutter::EmbedderEngine* embedder_engine = ToEmbedderEngine(engine.get());

  constexpr int texture_id = 1;
  ASSERT_TRUE(embedder_engine->RegisterTexture(texture_id));

  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(event);
  event.width = kWidth;
  event.height = kHeight;
  event.pixel_ratio = 1.0;
  ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &event),
            kSuccess);
  latch.Wait();
  // The rendered scene should match the same fixture as RGBA since the
  // BGRA-to-SkColorType mapping should prevent channel swapping.
  ASSERT_TRUE(
      ImageMatchesFixture("external_texture_impeller.png", rendered_scene));
}

TEST_F(EmbedderTest, RenderNV12TextureWithImpellerVulkan) {
  constexpr int kWidth = 800;
  constexpr int kHeight = 600;
  EmbedderTestContextVulkan& context =
      GetEmbedderContext<EmbedderTestContextVulkan>();
  EmbedderConfigBuilder builder(context);
  fml::AutoResetWaitableEvent latch;
  ON_CALL(context.PresentCallbackMock(), Call()).WillByDefault([&] {
    latch.Signal();
  });
  builder.AddCommandLineArgument("--enable-impeller");
  builder.SetDartEntrypoint("render_texture_impeller_test");
  builder.SetSurface(DlISize(kWidth, kHeight));

  // Probe NV12 support on the test thread so that GTEST_SKIP works; the
  // texture itself is created per frame in the callback below.
  {
    std::optional<TestVulkanImage> probe_image =
        CreateVulkanTextureNV12(context.vulkan_context(), kWidth, kHeight);
    if (!probe_image.has_value()) {
      GTEST_SKIP() << "NV12 format not supported by the Vulkan device.";
    }
  }

  std::future<sk_sp<SkImage>> rendered_scene = context.GetNextSceneImage();
  context.GetRendererConfig().vulkan.external_texture_frame_callback =
      [](void* user_data, int64_t texture_id, size_t width, size_t height,
         FlutterVulkanExternalTexture* texture) -> bool {
    EmbedderTestContextVulkan* embedder_test_context =
        static_cast<EmbedderTestContextVulkan*>(user_data);
    std::optional<TestVulkanImage> texture_image = CreateVulkanTextureNV12(
        embedder_test_context->vulkan_context(), kWidth, kHeight);
    if (!texture_image.has_value()) {
      return false;
    }
    TestVulkanImage* img =
        new TestVulkanImage(std::move(texture_image.value()));
    texture->image = reinterpret_cast<uint64_t>(img->GetImage());
    texture->format = VK_FORMAT_G8_B8R8_2PLANE_420_UNORM;
    texture->destruction_callback = DeleteTestVulkanImage;
    texture->user_data = img;
    texture->width = width;
    texture->height = height;
    return true;
  };

  UniqueEngine engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  flutter::EmbedderEngine* embedder_engine = ToEmbedderEngine(engine.get());

  constexpr int texture_id = 1;
  ASSERT_TRUE(embedder_engine->RegisterTexture(texture_id));

  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(event);
  event.width = kWidth;
  event.height = kHeight;
  event.pixel_ratio = 1.0;
  ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &event),
            kSuccess);
  latch.Wait();
  ASSERT_TRUE(ImageMatchesFixture("external_texture_nv12.png", rendered_scene));
}

TEST_F(EmbedderTest, RenderNV12TextureWithSkiaVulkan) {
  constexpr int kWidth = 800;
  constexpr int kHeight = 600;
  EmbedderTestContextVulkan& context =
      GetEmbedderContext<EmbedderTestContextVulkan>();
  EmbedderConfigBuilder builder(context);
  fml::AutoResetWaitableEvent latch;
  ON_CALL(context.PresentCallbackMock(), Call()).WillByDefault([&] {
    latch.Signal();
  });
  builder.SetDartEntrypoint("render_texture_impeller_test");
  builder.SetSurface(DlISize(kWidth, kHeight));

  // Probe NV12 support on the test thread so that GTEST_SKIP works; the
  // texture itself is created per frame in the callback below.
  {
    std::optional<TestVulkanImage> probe_image =
        CreateVulkanTextureNV12(context.vulkan_context(), kWidth, kHeight);
    if (!probe_image.has_value()) {
      GTEST_SKIP() << "NV12 format not supported by the Vulkan device.";
    }
  }

  std::future<sk_sp<SkImage>> rendered_scene = context.GetNextSceneImage();
  context.GetRendererConfig().vulkan.external_texture_frame_callback =
      [](void* user_data, int64_t texture_id, size_t width, size_t height,
         FlutterVulkanExternalTexture* texture) -> bool {
    EmbedderTestContextVulkan* embedder_test_context =
        static_cast<EmbedderTestContextVulkan*>(user_data);
    std::optional<TestVulkanImage> texture_image = CreateVulkanTextureNV12(
        embedder_test_context->vulkan_context(), kWidth, kHeight);
    if (!texture_image.has_value()) {
      return false;
    }
    TestVulkanImage* img =
        new TestVulkanImage(std::move(texture_image.value()));
    texture->image = reinterpret_cast<uint64_t>(img->GetImage());
    texture->format = VK_FORMAT_G8_B8R8_2PLANE_420_UNORM;
    texture->destruction_callback = DeleteTestVulkanImage;
    texture->user_data = img;
    texture->width = width;
    texture->height = height;
    return true;
  };

  UniqueEngine engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  flutter::EmbedderEngine* embedder_engine = ToEmbedderEngine(engine.get());

  constexpr int texture_id = 1;
  ASSERT_TRUE(embedder_engine->RegisterTexture(texture_id));

  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(event);
  event.width = kWidth;
  event.height = kHeight;
  event.pixel_ratio = 1.0;
  ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &event),
            kSuccess);
  latch.Wait();
  ASSERT_TRUE(ImageMatchesFixture("external_texture_nv12.png", rendered_scene));
}

}  // namespace testing
}  // namespace flutter

// NOLINTEND(clang-analyzer-core.StackAddressEscape)
