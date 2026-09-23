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
constexpr int kWidth = 800;
constexpr int kHeight = 600;
constexpr int kTextureId = 1;

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

using CreateTestImage = std::optional<TestVulkanImage> (*)(
    const fml::RefPtr<TestVulkanContext>& context,
    int width,
    int height);

std::optional<TestVulkanImage> CreateRGBATestImage(
    const fml::RefPtr<TestVulkanContext>& context,
    int width,
    int height) {
  return CreateVulkanTextureWithPixels(context, width, height,
                                       VK_FORMAT_R8G8B8A8_UNORM);
}

std::optional<TestVulkanImage> CreateBGRATestImage(
    const fml::RefPtr<TestVulkanContext>& context,
    int width,
    int height) {
  return CreateVulkanTextureWithPixels(context, width, height,
                                       VK_FORMAT_B8G8R8A8_UNORM);
}

struct ExternalTextureConfig {
  CreateTestImage create_image = nullptr;
  VkFormat format = VK_FORMAT_UNDEFINED;
  VoidCallback destruction_callback = nullptr;
};

static_assert(std::is_trivially_destructible_v<ExternalTextureConfig>);

ExternalTextureConfig g_external_texture_config;

bool ExternalTextureFrameCallback(void* user_data,
                                  int64_t texture_id,
                                  size_t width,
                                  size_t height,
                                  FlutterVulkanExternalTexture* texture) {
  EmbedderTestContextVulkan* embedder_test_context =
      static_cast<EmbedderTestContextVulkan*>(user_data);
  std::optional<TestVulkanImage> texture_image =
      g_external_texture_config.create_image(
          embedder_test_context->vulkan_context(), kWidth, kHeight);
  if (!texture_image.has_value()) {
    return false;
  }
  TestVulkanImage* img = new TestVulkanImage(std::move(texture_image.value()));
  texture->image = reinterpret_cast<uint64_t>(img->GetImage());
  texture->format = g_external_texture_config.format;
  texture->destruction_callback =
      g_external_texture_config.destruction_callback;
  texture->user_data = img;
  texture->width = width;
  texture->height = height;
  return true;
}

void SetExternalTexture(
    EmbedderTestContextVulkan& context,
    CreateTestImage create_image,
    VkFormat format,
    VoidCallback destruction_callback = DeleteTestVulkanImage) {
  g_external_texture_config = {create_image, format, destruction_callback};
  context.GetRendererConfig().vulkan.external_texture_frame_callback =
      ExternalTextureFrameCallback;
}

bool g_texture_destruction_callback_called = false;

void DeleteTestVulkanImageAndTrack(void* user_data) {
  delete static_cast<TestVulkanImage*>(user_data);
  g_texture_destruction_callback_called = true;
}

void ConfigureTextureTest(EmbedderTestContextVulkan& context,
                          EmbedderConfigBuilder& builder,
                          fml::AutoResetWaitableEvent& latch,
                          bool enable_impeller) {
  ON_CALL(context.PresentCallbackMock(), Call()).WillByDefault([&] {
    latch.Signal();
  });
  if (enable_impeller) {
    builder.AddCommandLineArgument("--enable-impeller");
  }
  builder.SetDartEntrypoint("render_texture_impeller_test");
  builder.SetSurface(DlISize(kWidth, kHeight));
}

UniqueEngine LaunchEngineAndScheduleFrames(EmbedderConfigBuilder& builder) {
  UniqueEngine engine = builder.LaunchEngine();
  if (!engine.is_valid()) {
    ADD_FAILURE() << "Could not launch the engine.";
    return {};
  }
  flutter::EmbedderEngine* embedder_engine = ToEmbedderEngine(engine.get());
  if (!embedder_engine->RegisterTexture(kTextureId)) {
    ADD_FAILURE() << "Could not register the external texture.";
    return {};
  }
  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(event);
  event.width = kWidth;
  event.height = kHeight;
  event.pixel_ratio = 1.0;
  if (FlutterEngineSendWindowMetricsEvent(engine.get(), &event) != kSuccess) {
    ADD_FAILURE() << "Could not send the window metrics event.";
    return {};
  }
  return engine;
}

void WaitAndVerifyFrame(fml::AutoResetWaitableEvent& latch,
                        std::future<sk_sp<SkImage>>& rendered_scene,
                        const char* fixture_name,
                        int allowable_different_pixels = 0) {
  latch.Wait();
  ASSERT_TRUE(ImageMatchesFixture(fixture_name, rendered_scene,
                                  allowable_different_pixels));
}

void RenderAndVerifyFrames(EmbedderTestContextVulkan& context,
                           const UniqueEngine& engine,
                           fml::AutoResetWaitableEvent& latch,
                           int frame_count,
                           const char* fixture_name,
                           int allowable_different_pixels = 0) {
  ASSERT_TRUE(engine.is_valid());
  flutter::EmbedderEngine* embedder_engine = ToEmbedderEngine(engine.get());
  for (int i = 0; i < frame_count; i++) {
    std::future<sk_sp<SkImage>> rendered_scene = context.GetNextSceneImage();
    ASSERT_TRUE(embedder_engine->MarkTextureFrameAvailable(kTextureId));
    latch.Wait();
    ASSERT_TRUE(ImageMatchesFixture(fixture_name, rendered_scene,
                                    allowable_different_pixels));
  }
}

void RenderFrame(const UniqueEngine& engine,
                 fml::AutoResetWaitableEvent& latch) {
  ASSERT_TRUE(engine.is_valid());
  flutter::EmbedderEngine* embedder_engine = ToEmbedderEngine(engine.get());
  ASSERT_TRUE(embedder_engine->MarkTextureFrameAvailable(kTextureId));
  latch.Wait();
}

bool CanCreateNV12Texture(EmbedderTestContextVulkan& context) {
  return CreateVulkanTextureNV12(context.vulkan_context(), kWidth, kHeight)
      .has_value();
}
}  // namespace

TEST_F(EmbedderTest, RenderTextureWithImpellerVulkan) {
  EmbedderTestContextVulkan& context =
      GetEmbedderContext<EmbedderTestContextVulkan>();
  EmbedderConfigBuilder builder(context);
  fml::AutoResetWaitableEvent latch;
  ConfigureTextureTest(context, builder, latch, /*enable_impeller=*/true);
  SetExternalTexture(context, CreateRGBATestImage, VK_FORMAT_R8G8B8A8_UNORM);

  std::future<sk_sp<SkImage>> rendered_scene = context.GetNextSceneImage();
  UniqueEngine engine = LaunchEngineAndScheduleFrames(builder);
  ASSERT_TRUE(engine.is_valid());
  WaitAndVerifyFrame(latch, rendered_scene, "external_texture_impeller.png");
  RenderAndVerifyFrames(context, engine, latch, 5,
                        "external_texture_impeller.png");
}

TEST_F(EmbedderTest, RenderTextureWithSkiaVulkan) {
  EmbedderTestContextVulkan& context =
      GetEmbedderContext<EmbedderTestContextVulkan>();
  EmbedderConfigBuilder builder(context);
  fml::AutoResetWaitableEvent latch;
  ConfigureTextureTest(context, builder, latch, /*enable_impeller=*/false);
  SetExternalTexture(context, CreateRGBATestImage, VK_FORMAT_R8G8B8A8_UNORM);

  std::future<sk_sp<SkImage>> rendered_scene = context.GetNextSceneImage();
  UniqueEngine engine = LaunchEngineAndScheduleFrames(builder);
  ASSERT_TRUE(engine.is_valid());
  WaitAndVerifyFrame(latch, rendered_scene, "external_texture_impeller.png");
  RenderAndVerifyFrames(context, engine, latch, 5,
                        "external_texture_impeller.png");
}

TEST_F(EmbedderTest, RenderTextureWithImpellerVulkanDestructCallback) {
  EmbedderTestContextVulkan& context =
      GetEmbedderContext<EmbedderTestContextVulkan>();
  EmbedderConfigBuilder builder(context);
  fml::AutoResetWaitableEvent latch;
  ConfigureTextureTest(context, builder, latch, /*enable_impeller=*/true);
  g_texture_destruction_callback_called = false;
  SetExternalTexture(context, CreateRGBATestImage, VK_FORMAT_R8G8B8A8_UNORM,
                     DeleteTestVulkanImageAndTrack);

  std::future<sk_sp<SkImage>> rendered_scene = context.GetNextSceneImage();
  UniqueEngine engine = LaunchEngineAndScheduleFrames(builder);
  ASSERT_TRUE(engine.is_valid());
  WaitAndVerifyFrame(latch, rendered_scene, "external_texture_impeller.png");

  // Render a second frame.
  RenderFrame(engine, latch);

  // After the second frame completes, the backend will have collected the
  // handle of the first frame's texture and called its destruction callback.
  EXPECT_TRUE(g_texture_destruction_callback_called);
}

TEST_F(EmbedderTest, RenderTextureWithSkiaVulkanDestructCallback) {
  EmbedderTestContextVulkan& context =
      GetEmbedderContext<EmbedderTestContextVulkan>();
  EmbedderConfigBuilder builder(context);
  fml::AutoResetWaitableEvent latch;
  ConfigureTextureTest(context, builder, latch, /*enable_impeller=*/false);
  g_texture_destruction_callback_called = false;
  SetExternalTexture(context, CreateRGBATestImage, VK_FORMAT_R8G8B8A8_UNORM,
                     DeleteTestVulkanImageAndTrack);

  std::future<sk_sp<SkImage>> rendered_scene = context.GetNextSceneImage();
  UniqueEngine engine = LaunchEngineAndScheduleFrames(builder);
  ASSERT_TRUE(engine.is_valid());
  WaitAndVerifyFrame(latch, rendered_scene, "external_texture_impeller.png");

  // Render a second frame.
  RenderFrame(engine, latch);

  // After the second frame completes, the backend will have collected the
  // handle of the first frame's texture and called its destruction callback.
  EXPECT_TRUE(g_texture_destruction_callback_called);
}

// Tests that a BGRA external texture renders correctly (red/blue channels
// are not swapped) when using the Impeller backend.
TEST_F(EmbedderTest, RenderBGRATextureWithImpellerVulkan) {
  EmbedderTestContextVulkan& context =
      GetEmbedderContext<EmbedderTestContextVulkan>();
  EmbedderConfigBuilder builder(context);
  fml::AutoResetWaitableEvent latch;
  ConfigureTextureTest(context, builder, latch, /*enable_impeller=*/true);
  SetExternalTexture(context, CreateBGRATestImage, VK_FORMAT_B8G8R8A8_UNORM);

  std::future<sk_sp<SkImage>> rendered_scene = context.GetNextSceneImage();
  UniqueEngine engine = LaunchEngineAndScheduleFrames(builder);
  ASSERT_TRUE(engine.is_valid());
  // The rendered scene should match the same fixture as RGBA since the
  // BGRA-to-SkColorType mapping should prevent channel swapping.
  WaitAndVerifyFrame(latch, rendered_scene, "external_texture_impeller.png");
}

// Tests that a BGRA external texture renders correctly (red/blue channels
// are not swapped) when using the Skia backend.
TEST_F(EmbedderTest, RenderBGRATextureWithSkiaVulkan) {
  EmbedderTestContextVulkan& context =
      GetEmbedderContext<EmbedderTestContextVulkan>();
  EmbedderConfigBuilder builder(context);
  fml::AutoResetWaitableEvent latch;
  ConfigureTextureTest(context, builder, latch, /*enable_impeller=*/false);
  SetExternalTexture(context, CreateBGRATestImage, VK_FORMAT_B8G8R8A8_UNORM);

  std::future<sk_sp<SkImage>> rendered_scene = context.GetNextSceneImage();
  UniqueEngine engine = LaunchEngineAndScheduleFrames(builder);
  ASSERT_TRUE(engine.is_valid());
  // The rendered scene should match the same fixture as RGBA since the
  // BGRA-to-SkColorType mapping should prevent channel swapping.
  WaitAndVerifyFrame(latch, rendered_scene, "external_texture_impeller.png");
}
TEST_F(EmbedderTest, RenderNV12TextureWithImpellerVulkan) {
  EmbedderTestContextVulkan& context =
      GetEmbedderContext<EmbedderTestContextVulkan>();

  // Probe NV12 support on the test thread so that GTEST_SKIP works; the
  // texture itself is created per frame in the frame callback.
  if (!CanCreateNV12Texture(context)) {
    GTEST_SKIP() << "NV12 format not supported by the Vulkan device.";
  }

  EmbedderConfigBuilder builder(context);
  fml::AutoResetWaitableEvent latch;
  ConfigureTextureTest(context, builder, latch, /*enable_impeller=*/true);
  SetExternalTexture(context, CreateVulkanTextureNV12,
                     VK_FORMAT_G8_B8R8_2PLANE_420_UNORM);

  std::future<sk_sp<SkImage>> rendered_scene = context.GetNextSceneImage();
  UniqueEngine engine = LaunchEngineAndScheduleFrames(builder);
  ASSERT_TRUE(engine.is_valid());
  WaitAndVerifyFrame(latch, rendered_scene, "external_texture_nv12.png",
                     kWidth * 2);
}

TEST_F(EmbedderTest, RenderNV12TextureWithSkiaVulkan) {
  EmbedderTestContextVulkan& context =
      GetEmbedderContext<EmbedderTestContextVulkan>();

  if (!CanCreateNV12Texture(context)) {
    GTEST_SKIP() << "NV12 format not supported by the Vulkan device.";
  }

  EmbedderConfigBuilder builder(context);
  fml::AutoResetWaitableEvent latch;
  ConfigureTextureTest(context, builder, latch, /*enable_impeller=*/false);
  SetExternalTexture(context, CreateVulkanTextureNV12,
                     VK_FORMAT_G8_B8R8_2PLANE_420_UNORM);

  std::future<sk_sp<SkImage>> rendered_scene = context.GetNextSceneImage();
  UniqueEngine engine = LaunchEngineAndScheduleFrames(builder);
  ASSERT_TRUE(engine.is_valid());
  WaitAndVerifyFrame(latch, rendered_scene, "external_texture_nv12.png",
                     kWidth * 2);
}

}  // namespace testing
}  // namespace flutter

// NOLINTEND(clang-analyzer-core.StackAddressEscape)
