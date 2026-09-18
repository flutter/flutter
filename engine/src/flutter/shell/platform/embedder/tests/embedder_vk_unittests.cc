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
#include "flutter/display_list/dl_builder.h"
#include "flutter/display_list/skia/dl_sk_canvas.h"
#include "flutter/fml/synchronization/count_down_latch.h"
#include "flutter/shell/platform/embedder/embedder_external_texture_vk.h"
#include "flutter/shell/platform/embedder/tests/embedder_config_builder.h"
#include "flutter/shell/platform/embedder/tests/embedder_test.h"
#include "flutter/shell/platform/embedder/tests/embedder_test_context_vulkan.h"
#include "flutter/shell/platform/embedder/tests/embedder_unittests_util.h"
#include "flutter/testing/testing.h"

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
  decltype(vkGetInstanceProcAddr)* get_instance_proc_addr = nullptr;
  decltype(vkGetDeviceProcAddr)* get_device_proc_addr = nullptr;
  decltype(vkQueueSubmit)* queue_submit_proc_addr = nullptr;
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
        reinterpret_cast<decltype(vkQueueSubmit)*>(
            g_vulkan_proc_info.get_device_proc_addr(device, pName));
    return reinterpret_cast<PFN_vkVoidFunction>(QueueSubmit);
  }
  return g_vulkan_proc_info.get_device_proc_addr(device, pName);
}

PFN_vkVoidFunction GetInstanceProcAddr(VkInstance instance, const char* pName) {
  FML_DCHECK(g_vulkan_proc_info.get_instance_proc_addr != nullptr);
  if (StrcmpFixed(pName, "vkGetDeviceProcAddr") == 0) {
    g_vulkan_proc_info.get_device_proc_addr =
        reinterpret_cast<decltype(vkGetDeviceProcAddr)*>(
            g_vulkan_proc_info.get_instance_proc_addr(instance, pName));
    return reinterpret_cast<PFN_vkVoidFunction>(GetDeviceProcAddr);
  }
  return g_vulkan_proc_info.get_instance_proc_addr(instance, pName);
}

template <typename T, typename U>
struct CheckSameSignature : std::false_type {};

template <typename Ret, typename... Args>
struct CheckSameSignature<Ret(Args...), Ret(Args...)> : std::true_type {};

static_assert(CheckSameSignature<decltype(GetInstanceProcAddr),
                                 decltype(vkGetInstanceProcAddr)>::value);
static_assert(CheckSameSignature<decltype(GetDeviceProcAddr),
                                 decltype(vkGetDeviceProcAddr)>::value);
static_assert(
    CheckSameSignature<decltype(QueueSubmit), decltype(vkQueueSubmit)>::value);
}  // namespace

TEST_F(EmbedderTest, CanGetVulkanEmbedderContext) {
  auto& context = GetEmbedderContext<EmbedderTestContextVulkan>();
  EmbedderConfigBuilder builder(context);
}

TEST_F(EmbedderTest, CanSwapOutVulkanCalls) {
  fml::AutoResetWaitableEvent latch;

  auto& context = GetEmbedderContext<EmbedderTestContextVulkan>();
  context.AddIsolateCreateCallback([&latch]() { latch.Signal(); });
  context.SetVulkanInstanceProcAddressCallback(
      [](void* user_data, FlutterVulkanInstanceHandle instance,
         const char* name) -> void* {
        if (StrcmpFixed(name, "vkGetInstanceProcAddr") == 0) {
          g_vulkan_proc_info.get_instance_proc_addr =
              reinterpret_cast<decltype(vkGetInstanceProcAddr)*>(
                  EmbedderTestContextVulkan::InstanceProcAddr(user_data,
                                                              instance, name));
          return reinterpret_cast<void*>(GetInstanceProcAddr);
        }
        return EmbedderTestContextVulkan::InstanceProcAddr(user_data, instance,
                                                           name);
      });

  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(1024, 1024));
  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());
  // Wait for the root isolate to launch.
  latch.Wait();
  engine.reset();
  EXPECT_TRUE(g_vulkan_proc_info.did_call_queue_submit);
}

TEST_F(EmbedderTest, CanRenderSceneWithVulkanCompositorSkia) {
  auto& context = GetEmbedderContext<EmbedderTestContextVulkan>();

  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(800, 600));
  builder.SetCompositor();
  builder.SetRenderTargetType(
      EmbedderTestBackingStoreProducer::RenderTargetType::kVulkanImage);
  builder.SetDartEntrypoint("render_gradient");

  auto rendered_scene_future = context.GetNextSceneImage();

  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(event);
  event.width = 800;
  event.height = 600;
  event.pixel_ratio = 1.0;
  ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &event),
            kSuccess);

  auto rendered_scene = rendered_scene_future.get();
  ASSERT_NE(rendered_scene, nullptr);
  EXPECT_EQ(rendered_scene->width(), 800);
  EXPECT_EQ(rendered_scene->height(), 600);

  engine.reset();
}

TEST_F(EmbedderTest, CreateInvalidBackingstoreVulkanImage) {
  fml::AutoResetWaitableEvent latch;
  auto& context = GetEmbedderContext<EmbedderTestContextVulkan>();
  context.AddIsolateCreateCallback([&latch]() { latch.Signal(); });

  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(800, 600));
  builder.SetCompositor();
  builder.SetRenderTargetType(
      EmbedderTestBackingStoreProducer::RenderTargetType::kVulkanImage);
  builder.SetDartEntrypoint("invalid_backingstore");

  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(event);
  event.width = 800;
  event.height = 600;
  event.pixel_ratio = 1.0;
  ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &event),
            kSuccess);

  latch.Wait();
  engine.reset();
}

TEST_F(EmbedderTest, ExternalTextureVKSkiaResolveAndFrameAvailable) {
  auto& context = GetEmbedderContext<EmbedderTestContextVulkan>();
  auto test_vk_context = context.GetTestVulkanContext();
  ASSERT_TRUE(test_vk_context);

  auto image = test_vk_context->CreateImage(DlISize(100, 100));
  ASSERT_TRUE(image.has_value());

  bool resolve_called = false;
  bool destruction_called = false;

  EmbedderExternalTextureVK::ExternalTextureCallback callback(
      [&](int64_t, size_t, size_t) {
        resolve_called = true;
        auto res = std::make_unique<FlutterVulkanExternalTexture>();
        res->struct_size = sizeof(FlutterVulkanExternalTexture);
        res->width = 100;
        res->height = 100;
        res->format = VK_FORMAT_R8G8B8A8_UNORM;
        res->type = kFlutterVulkanExternalTextureTypeVkImage;
        res->vk_image =
            reinterpret_cast<FlutterVulkanImageHandle>(image->GetImage());
        res->user_data = &destruction_called;
        res->destruction_callback = [](void* user_data) {
          *reinterpret_cast<bool*>(user_data) = true;
        };
        return res;
      });

  auto surface = TestVulkanSurface::Create(*test_vk_context, DlISize(100, 100));
  ASSERT_NE(surface, nullptr);
  auto gr_context = test_vk_context->GetGrDirectContext();

  {
    DisplayListBuilder dl_builder;
    DlCanvas* canvas = &dl_builder;

    Texture::PaintContext ctx{
        .canvas = canvas,
        .gr_context = gr_context.get(),
    };

    EmbedderExternalTextureVK texture(1, callback);

    texture.Paint(ctx, DlRect::MakeXYWH(0, 0, 100, 100), false,
                  DlImageSampling::kLinear);

    EXPECT_TRUE(resolve_called);
    resolve_called = false;

    // Second paint uses cached frame, so callback shouldn't be called.
    texture.Paint(ctx, DlRect::MakeXYWH(0, 0, 100, 100), false,
                  DlImageSampling::kLinear);
    EXPECT_FALSE(resolve_called);

    // After MarkNewFrameAvailable, callback is called again.
    texture.MarkNewFrameAvailable();
    texture.Paint(ctx, DlRect::MakeXYWH(0, 0, 100, 100), false,
                  DlImageSampling::kLinear);
    EXPECT_TRUE(resolve_called);
  }

  gr_context->flushAndSubmit(GrSyncCpu::kYes);
  EXPECT_TRUE(destruction_called);
}

TEST_F(EmbedderTest, ExternalTextureVKBGRAFormat) {
  auto& context = GetEmbedderContext<EmbedderTestContextVulkan>();
  auto test_vk_context = context.GetTestVulkanContext();
  ASSERT_TRUE(test_vk_context);

  auto image = test_vk_context->CreateImage(DlISize(100, 100));
  ASSERT_TRUE(image.has_value());

  bool resolve_called = false;
  EmbedderExternalTextureVK::ExternalTextureCallback callback(
      [&](int64_t, size_t, size_t) {
        resolve_called = true;
        auto res = std::make_unique<FlutterVulkanExternalTexture>();
        res->struct_size = sizeof(FlutterVulkanExternalTexture);
        res->width = 100;
        res->height = 100;
        res->format = VK_FORMAT_B8G8R8A8_UNORM;
        res->type = kFlutterVulkanExternalTextureTypeVkImage;
        res->vk_image =
            reinterpret_cast<FlutterVulkanImageHandle>(image->GetImage());
        res->user_data = nullptr;
        res->destruction_callback = nullptr;
        return res;
      });

  EmbedderExternalTextureVK texture(1, callback);

  auto surface = TestVulkanSurface::Create(*test_vk_context, DlISize(100, 100));
  ASSERT_NE(surface, nullptr);
  auto gr_context = test_vk_context->GetGrDirectContext();

  DisplayListBuilder dl_builder;
  DlCanvas* canvas = &dl_builder;

  Texture::PaintContext ctx{
      .canvas = canvas,
      .gr_context = gr_context.get(),
  };

  texture.Paint(ctx, DlRect::MakeXYWH(0, 0, 100, 100), false,
                DlImageSampling::kLinear);

  EXPECT_TRUE(resolve_called);
}

TEST_F(EmbedderTest, ExternalTextureVKZeroDimensions) {
  bool destruction_called = false;
  EmbedderExternalTextureVK::ExternalTextureCallback callback(
      [&destruction_called](int64_t, size_t, size_t) {
        auto res = std::make_unique<FlutterVulkanExternalTexture>();
        res->struct_size = sizeof(FlutterVulkanExternalTexture);
        res->width = 0;
        res->height = 0;
        res->format = VK_FORMAT_R8G8B8A8_UNORM;
        res->type = kFlutterVulkanExternalTextureTypeVkImage;
        res->vk_image = 0;
        res->user_data = &destruction_called;
        res->destruction_callback = [](void* user_data) {
          *reinterpret_cast<bool*>(user_data) = true;
        };
        return res;
      });
  EmbedderExternalTextureVK texture(1, callback);

  auto& context = GetEmbedderContext<EmbedderTestContextVulkan>();
  auto test_vk_context = context.GetTestVulkanContext();
  auto gr_context = test_vk_context->GetGrDirectContext();

  DisplayListBuilder builder;
  Texture::PaintContext ctx{
      .canvas = &builder,
      .gr_context = gr_context.get(),
  };
  texture.Paint(ctx, DlRect::MakeXYWH(0, 0, 0, 0), false,
                DlImageSampling::kLinear);
  EXPECT_TRUE(destruction_called);
}

TEST_F(EmbedderTest, ExternalTextureVKNullContextDoesNotCrash) {
  EmbedderExternalTextureVK::ExternalTextureCallback callback(
      [](int64_t, size_t, size_t) {
        auto res = std::make_unique<FlutterVulkanExternalTexture>();
        res->struct_size = sizeof(FlutterVulkanExternalTexture);
        res->width = 100;
        res->height = 100;
        res->format = VK_FORMAT_R8G8B8A8_UNORM;
        res->type = kFlutterVulkanExternalTextureTypeVkImage;
        res->vk_image = 0;
        res->user_data = nullptr;
        res->destruction_callback = [](void*) {};
        return res;
      });
  EmbedderExternalTextureVK texture(1, callback);

  DisplayListBuilder builder;
  Texture::PaintContext ctx{
      .canvas = &builder,
      .gr_context = nullptr,
      .aiks_context = nullptr,
  };
  texture.Paint(ctx, DlRect::MakeXYWH(0, 0, 100, 100), false,
                DlImageSampling::kLinear);
}

TEST_F(EmbedderTest, ExternalTextureVKInvalidTypeOrNull) {
  bool destruction_called = false;
  EmbedderExternalTextureVK::ExternalTextureCallback callback(
      [&destruction_called](int64_t, size_t, size_t) {
        auto res = std::make_unique<FlutterVulkanExternalTexture>();
        res->struct_size = sizeof(FlutterVulkanExternalTexture);
        res->width = 100;
        res->height = 100;
        // The point of the test is to feed the engine a type outside the
        // enum, so the cast is deliberate.
        // NOLINTNEXTLINE(clang-analyzer-optin.core.EnumCastOutOfRange)
        res->type = static_cast<FlutterVulkanExternalTextureType>(99);
        res->user_data = &destruction_called;
        res->destruction_callback = [](void* user_data) {
          *reinterpret_cast<bool*>(user_data) = true;
        };
        return res;
      });
  EmbedderExternalTextureVK texture(1, callback);

  auto& context = GetEmbedderContext<EmbedderTestContextVulkan>();
  auto test_vk_context = context.GetTestVulkanContext();
  auto gr_context = test_vk_context->GetGrDirectContext();

  DisplayListBuilder builder;
  Texture::PaintContext ctx{
      .canvas = &builder,
      .gr_context = gr_context.get(),
  };
  texture.Paint(ctx, DlRect::MakeXYWH(0, 0, 100, 100), false,
                DlImageSampling::kLinear);
  EXPECT_TRUE(destruction_called);
}

TEST_F(EmbedderTest, EmbedderVulkanExternalTextureEngineRegistration) {
  fml::AutoResetWaitableEvent latch;
  auto& context = GetEmbedderContext<EmbedderTestContextVulkan>();
  context.AddIsolateCreateCallback([&latch]() { latch.Signal(); });

  bool texture_callback_called = false;
  context.SetExternalTextureCallback(
      [&texture_callback_called](int64_t texture_id, size_t width,
                                 size_t height,
                                 FlutterVulkanExternalTexture* output) -> bool {
        texture_callback_called = true;
        output->struct_size = sizeof(FlutterVulkanExternalTexture);
        output->width = width;
        output->height = height;
        output->type = kFlutterVulkanExternalTextureTypeVkImage;
        output->vk_image = 0;
        output->format = VK_FORMAT_R8G8B8A8_UNORM;
        output->user_data = nullptr;
        output->destruction_callback = nullptr;
        return true;
      });

  EmbedderConfigBuilder builder(context);
  builder.SetSurface(DlISize(800, 600));

  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  // Register external texture.
  ASSERT_EQ(FlutterEngineRegisterExternalTexture(engine.get(), 100), kSuccess);

  // Mark frame available.
  ASSERT_EQ(FlutterEngineMarkExternalTextureFrameAvailable(engine.get(), 100),
            kSuccess);

  // Unregister external texture.
  ASSERT_EQ(FlutterEngineUnregisterExternalTexture(engine.get(), 100),
            kSuccess);

  latch.Wait();
  engine.reset();
}

}  // namespace testing
}  // namespace flutter

// NOLINTEND(clang-analyzer-core.StackAddressEscape)
