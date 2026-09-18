// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include <atomic>
#include <cstring>
#include <string>
#include <utility>
#include <vector>

#include "embedder.h"
#include "embedder_engine.h"
#include "flutter/fml/closure.h"
#include "flutter/fml/synchronization/count_down_latch.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/shell/platform/embedder/tests/embedder_config_builder.h"
#include "flutter/shell/platform/embedder/tests/embedder_test.h"
#include "flutter/shell/platform/embedder/tests/embedder_test_backingstore_producer.h"
#include "flutter/shell/platform/embedder/tests/embedder_test_compositor.h"
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

PFN_vkVoidFunction GetDeviceProcAddr(VkDevice device, const char* pName) {
  FML_DCHECK(g_vulkan_proc_info.get_device_proc_addr != nullptr);
  if (std::strcmp(pName, "vkQueueSubmit") == 0) {
    g_vulkan_proc_info.queue_submit_proc_addr =
        reinterpret_cast<PFN_vkQueueSubmit>(
            g_vulkan_proc_info.get_device_proc_addr(device, pName));
    return reinterpret_cast<PFN_vkVoidFunction>(QueueSubmit);
  }
  return g_vulkan_proc_info.get_device_proc_addr(device, pName);
}

// Skia resolves device functions through vkGetDeviceProcAddr, so it is caught
// in GetDeviceProcAddr. Impeller initializes its dispatcher with the instance
// alone and resolves device functions here, by name, so vkQueueSubmit has to be
// caught on this route too.
PFN_vkVoidFunction GetInstanceProcAddr(VkInstance instance, const char* pName) {
  FML_DCHECK(g_vulkan_proc_info.get_instance_proc_addr != nullptr);
  if (std::strcmp(pName, "vkQueueSubmit") == 0) {
    g_vulkan_proc_info.queue_submit_proc_addr =
        reinterpret_cast<PFN_vkQueueSubmit>(
            g_vulkan_proc_info.get_instance_proc_addr(instance, pName));
    return reinterpret_cast<PFN_vkVoidFunction>(QueueSubmit);
  }
  if (std::strcmp(pName, "vkGetDeviceProcAddr") == 0) {
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

#if IMPELLER_SUPPORTS_RENDERING

/// Verifies that Impeller can render into an embedder-provided Vulkan backing
/// store, present it to the compositor, and match the expected golden output.
TEST_F(EmbedderTest, CanRenderWithImpellerVulkan) {
  auto& context = GetEmbedderContext<EmbedderTestContextVulkan>();
  EmbedderConfigBuilder builder(context);

  builder.AddCommandLineArgument("--enable-impeller");
  builder.SetDartEntrypoint("render_impeller_test");
  builder.SetSurface(DlISize(800, 600));
  builder.SetCompositor();
  builder.SetRenderTargetType(
      EmbedderTestBackingStoreProducer::RenderTargetType::kVulkanImage);

  fml::AutoResetWaitableEvent latch;
  bool layer_was_a_vulkan_backing_store = false;
  context.GetCompositor().SetNextPresentCallback(
      [&](FlutterViewId view_id, const FlutterLayer** layers,
          size_t layers_count) {
        if (layers_count == 1u &&
            layers[0]->type == kFlutterLayerContentTypeBackingStore &&
            layers[0]->backing_store->type == kFlutterBackingStoreTypeVulkan) {
          layer_was_a_vulkan_backing_store = true;
        }
        latch.Signal();
      });

  auto rendered_scene = context.GetNextSceneImage();

  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(event);
  event.width = 800;
  event.height = 600;
  event.pixel_ratio = 1.0;
  ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &event),
            kSuccess);

  // Bound the wait so a dropped frame fails instead of hanging.
  ASSERT_FALSE(latch.WaitWithTimeout(fml::TimeDelta::FromSeconds(30)))
      << "no frame reached the compositor";
  EXPECT_TRUE(layer_was_a_vulkan_backing_store);

  ASSERT_TRUE(ImageMatchesFixture("impeller_test.png", rendered_scene));
}

namespace {

struct VulkanDestructionTracker {
  struct WrappedUserData {
    VulkanDestructionTracker* tracker = nullptr;
    VoidCallback original_callback = nullptr;
    void* original_user_data = nullptr;
  };

  std::atomic<int> created_count{0};
  std::atomic<int> destroyed_count{0};

  void Reset() {
    created_count.store(0);
    destroyed_count.store(0);
  }

  void WrapBackingStore(FlutterBackingStore* backing_store_out) {
    created_count++;
    auto* wrapped = new WrappedUserData{
        .tracker = this,
        .original_callback = backing_store_out->vulkan.destruction_callback,
        .original_user_data = backing_store_out->vulkan.user_data,
    };
    backing_store_out->vulkan.user_data = wrapped;
    backing_store_out->vulkan.destruction_callback = [](void* data) {
      auto* w = reinterpret_cast<WrappedUserData*>(data);
      w->tracker->destroyed_count++;
      if (w->original_callback) {
        w->original_callback(w->original_user_data);
      }
      delete w;
    };
  }
};

void RunImpellerVulkanFailureCleanupTest(EmbedderTestContextVulkan& context,
                                         bool use_null_image) {
  EmbedderConfigBuilder builder(context);

  builder.AddCommandLineArgument("--enable-impeller");
  builder.SetDartEntrypoint("render_impeller_test");
  builder.SetSurface(DlISize(800, 600));
  builder.SetCompositor();
  builder.SetRenderTargetType(
      EmbedderTestBackingStoreProducer::RenderTargetType::kVulkanImage);

  static std::atomic<int> created_count{0};
  static std::atomic<int> destroyed_count{0};
  static std::atomic<int> collected_count{0};
  static fml::AutoResetWaitableEvent* cleanup_latch = nullptr;
  static bool return_null_image = false;

  created_count.store(0);
  destroyed_count.store(0);
  collected_count.store(0);
  fml::AutoResetWaitableEvent latch;
  cleanup_latch = &latch;
  return_null_image = use_null_image;

  builder.GetCompositor().create_backing_store_callback =
      [](const FlutterBackingStoreConfig* config,
         FlutterBackingStore* backing_store_out, void* user_data) -> bool {
    created_count++;
    backing_store_out->type = kFlutterBackingStoreTypeVulkan;
    if (return_null_image) {
      backing_store_out->vulkan.image = nullptr;
    } else {
      static FlutterVulkanImage invalid_format_image = {
          .struct_size = sizeof(FlutterVulkanImage),
          .image = 1,
          .format = VK_FORMAT_B8G8R8A8_SRGB,
      };
      backing_store_out->vulkan.image = &invalid_format_image;
    }
    backing_store_out->vulkan.user_data = nullptr;
    backing_store_out->vulkan.destruction_callback = [](void*) {
      destroyed_count++;
    };
    return true;
  };

  builder.GetCompositor().collect_backing_store_callback =
      [](const FlutterBackingStore* backing_store, void* user_data) -> bool {
    collected_count++;
    if (cleanup_latch) {
      cleanup_latch->Signal();
    }
    return true;
  };

  {
    auto engine = builder.LaunchEngine();
    ASSERT_TRUE(engine.is_valid());

    FlutterWindowMetricsEvent event = {};
    event.struct_size = sizeof(event);
    event.width = 800;
    event.height = 600;
    event.pixel_ratio = 1.0;
    ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &event),
              kSuccess);

    ASSERT_FALSE(latch.WaitWithTimeout(fml::TimeDelta::FromSeconds(30)))
        << "cleanup callbacks were not invoked on failure";
  }

  EXPECT_GT(created_count.load(), 0);
  EXPECT_EQ(destroyed_count.load(), created_count.load());
  EXPECT_EQ(collected_count.load(), created_count.load());
  cleanup_latch = nullptr;
}

}  // namespace

/// Verifies that `FlutterVulkanBackingStore.destruction_callback` is invoked
/// when Impeller releases a Vulkan backing store.
TEST_F(EmbedderTest, ImpellerVulkanBackingStoreCallsDestructionCallback) {
  auto& context = GetEmbedderContext<EmbedderTestContextVulkan>();
  EmbedderConfigBuilder builder(context);

  builder.AddCommandLineArgument("--enable-impeller");
  builder.SetDartEntrypoint("render_impeller_test");
  builder.SetSurface(DlISize(800, 600));
  builder.SetCompositor();
  builder.SetRenderTargetType(
      EmbedderTestBackingStoreProducer::RenderTargetType::kVulkanImage);

  static VulkanDestructionTracker tracker;
  tracker.Reset();

  builder.GetCompositor().create_backing_store_callback =
      [](const FlutterBackingStoreConfig* config,
         FlutterBackingStore* backing_store_out, void* user_data) -> bool {
    auto* compositor = reinterpret_cast<EmbedderTestCompositor*>(user_data);
    if (!compositor->CreateBackingStore(config, backing_store_out)) {
      return false;
    }
    tracker.WrapBackingStore(backing_store_out);
    return true;
  };

  fml::AutoResetWaitableEvent latch;
  context.GetCompositor().SetNextPresentCallback(
      [&](FlutterViewId view_id, const FlutterLayer** layers,
          size_t layers_count) { latch.Signal(); });

  {
    auto engine = builder.LaunchEngine();
    ASSERT_TRUE(engine.is_valid());

    FlutterWindowMetricsEvent event = {};
    event.struct_size = sizeof(event);
    event.width = 800;
    event.height = 600;
    event.pixel_ratio = 1.0;
    ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &event),
              kSuccess);

    ASSERT_FALSE(latch.WaitWithTimeout(fml::TimeDelta::FromSeconds(30)))
        << "no frame reached the compositor";
  }

  EXPECT_GT(tracker.created_count.load(), 0);
  EXPECT_EQ(tracker.destroyed_count.load(), tracker.created_count.load());
}

/// Verifies that `FlutterVulkanBackingStore.destruction_callback` is invoked
/// for every backing store when `avoid_backing_store_cache` is true across
/// multiple frames and a resize.
TEST_F(EmbedderTest, ImpellerVulkanBackingStoreAvoidCacheDestructionCallback) {
  auto& context = GetEmbedderContext<EmbedderTestContextVulkan>();
  EmbedderConfigBuilder builder(context);

  builder.AddCommandLineArgument("--enable-impeller");
  builder.SetDartEntrypoint("render_impeller_test");
  builder.SetSurface(DlISize(800, 600));
  builder.SetCompositor(/*avoid_backing_store_cache=*/true);
  builder.SetRenderTargetType(
      EmbedderTestBackingStoreProducer::RenderTargetType::kVulkanImage);

  static VulkanDestructionTracker tracker;
  tracker.Reset();

  builder.GetCompositor().create_backing_store_callback =
      [](const FlutterBackingStoreConfig* config,
         FlutterBackingStore* backing_store_out, void* user_data) -> bool {
    auto* compositor = reinterpret_cast<EmbedderTestCompositor*>(user_data);
    if (!compositor->CreateBackingStore(config, backing_store_out)) {
      return false;
    }
    tracker.WrapBackingStore(backing_store_out);
    return true;
  };

  fml::AutoResetWaitableEvent latch;
  context.GetCompositor().SetPresentCallback(
      [&](FlutterViewId view_id, const FlutterLayer** layers,
          size_t layers_count) { latch.Signal(); },
      /*one_shot=*/false);

  {
    auto engine = builder.LaunchEngine();
    ASSERT_TRUE(engine.is_valid());

    FlutterWindowMetricsEvent event = {};
    event.struct_size = sizeof(event);
    event.width = 800;
    event.height = 600;
    event.pixel_ratio = 1.0;
    ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &event),
              kSuccess);
    ASSERT_FALSE(latch.WaitWithTimeout(fml::TimeDelta::FromSeconds(30)))
        << "first frame did not reach the compositor";

    event.width = 400;
    event.height = 300;
    ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &event),
              kSuccess);
    ASSERT_FALSE(latch.WaitWithTimeout(fml::TimeDelta::FromSeconds(30)))
        << "resized frame did not reach the compositor";
  }

  EXPECT_GE(tracker.created_count.load(), 2);
  EXPECT_EQ(tracker.destroyed_count.load(), tracker.created_count.load());
}

/// Verifies that both `collect_backing_store_callback` and
/// `FlutterVulkanBackingStore.destruction_callback` are invoked when render
/// target creation fails due to an unsupported pixel format.
TEST_F(EmbedderTest,
       ImpellerVulkanBackingStoreUnsupportedFormatInvokesCleanup) {
  RunImpellerVulkanFailureCleanupTest(
      GetEmbedderContext<EmbedderTestContextVulkan>(),
      /*use_null_image=*/false);
}

/// Verifies that both `collect_backing_store_callback` and
/// `FlutterVulkanBackingStore.destruction_callback` are invoked when render
/// target creation fails due to a null Vulkan image.
TEST_F(EmbedderTest, ImpellerVulkanBackingStoreNullImageInvokesCleanup) {
  RunImpellerVulkanFailureCleanupTest(
      GetEmbedderContext<EmbedderTestContextVulkan>(),
      /*use_null_image=*/true);
}

#endif  // IMPELLER_SUPPORTS_RENDERING

// Hands the engine GetInstanceProcAddr above in place of the real
// vkGetInstanceProcAddr, so that its vkQueueSubmit lands in QueueSubmit.
static void* SwapInInstanceProcAddr(void* user_data,
                                    FlutterVulkanInstanceHandle instance,
                                    const char* name) {
  if (std::strcmp(name, "vkGetInstanceProcAddr") == 0) {
    g_vulkan_proc_info.get_instance_proc_addr =
        reinterpret_cast<PFN_vkGetInstanceProcAddr>(
            EmbedderTestContextVulkan::InstanceProcAddr(user_data, instance,
                                                        name));
    return reinterpret_cast<void*>(GetInstanceProcAddr);
  }
  return EmbedderTestContextVulkan::InstanceProcAddr(user_data, instance, name);
}

TEST_F(EmbedderTest, CanSwapOutVulkanCalls) {
  // The capture is global. Declared before the engine so that the engine has
  // shut down by the time it is cleared.
  fml::ScopedCleanupClosure reset_proc_info([] { g_vulkan_proc_info = {}; });
  fml::AutoResetWaitableEvent latch;

  EmbedderTestContextVulkan& context =
      GetEmbedderContext<EmbedderTestContextVulkan>();
  context.AddIsolateCreateCallback([&latch]() { latch.Signal(); });
  context.SetVulkanInstanceProcAddressCallback(SwapInInstanceProcAddr);

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

void* g_last_texture_user_data = nullptr;

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
  g_last_texture_user_data = img;
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

void* g_destroyed_texture_user_data = nullptr;

void DeleteTestVulkanImageAndTrack(void* user_data) {
  g_destroyed_texture_user_data = user_data;
  delete static_cast<TestVulkanImage*>(user_data);
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
  g_destroyed_texture_user_data = nullptr;
  SetExternalTexture(context, CreateRGBATestImage, VK_FORMAT_R8G8B8A8_UNORM,
                     DeleteTestVulkanImageAndTrack);

  std::future<sk_sp<SkImage>> rendered_scene = context.GetNextSceneImage();
  UniqueEngine engine = LaunchEngineAndScheduleFrames(builder);
  ASSERT_TRUE(engine.is_valid());
  WaitAndVerifyFrame(latch, rendered_scene, "external_texture_impeller.png");
  void* first_frame_user_data = g_last_texture_user_data;
  ASSERT_NE(first_frame_user_data, nullptr);

  RenderFrame(engine, latch);

  EXPECT_EQ(g_destroyed_texture_user_data, first_frame_user_data);
}

TEST_F(EmbedderTest, RenderTextureWithSkiaVulkanDestructCallback) {
  EmbedderTestContextVulkan& context =
      GetEmbedderContext<EmbedderTestContextVulkan>();
  EmbedderConfigBuilder builder(context);
  fml::AutoResetWaitableEvent latch;
  ConfigureTextureTest(context, builder, latch, /*enable_impeller=*/false);
  g_destroyed_texture_user_data = nullptr;
  SetExternalTexture(context, CreateRGBATestImage, VK_FORMAT_R8G8B8A8_UNORM,
                     DeleteTestVulkanImageAndTrack);

  std::future<sk_sp<SkImage>> rendered_scene = context.GetNextSceneImage();
  UniqueEngine engine = LaunchEngineAndScheduleFrames(builder);
  ASSERT_TRUE(engine.is_valid());
  WaitAndVerifyFrame(latch, rendered_scene, "external_texture_impeller.png");
  void* first_frame_user_data = g_last_texture_user_data;
  ASSERT_NE(first_frame_user_data, nullptr);

  RenderFrame(engine, latch);

  EXPECT_EQ(g_destroyed_texture_user_data, first_frame_user_data);
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

#if IMPELLER_SUPPORTS_RENDERING

/// Verifies Vulkan proc interception under Impeller. Because Impeller does not
/// submit command buffers during context setup, this test renders a frame to
/// trigger `vkQueueSubmit`.
TEST_F(EmbedderTest, CanSwapOutVulkanCallsWithImpeller) {
  // Declared before the engine so that the engine has shut down by the time
  // the capture is cleared.
  fml::ScopedCleanupClosure reset_proc_info([] { g_vulkan_proc_info = {}; });

  auto& context =
      static_cast<EmbedderTestContextVulkan&>(GetVulkanImpellerContext());
  context.SetVulkanInstanceProcAddressCallback(SwapInInstanceProcAddr);

  EmbedderConfigBuilder builder(context);
  builder.SetDartEntrypoint("render_impeller_test");
  builder.SetSurface(DlISize(800, 600));
  builder.SetCompositor();
  builder.SetRenderTargetType(
      EmbedderTestBackingStoreProducer::RenderTargetType::kVulkanImage);

  fml::AutoResetWaitableEvent latch;
  context.GetCompositor().SetNextPresentCallback(
      [&](FlutterViewId view_id, const FlutterLayer** layers,
          size_t layers_count) { latch.Signal(); });

  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(event);
  event.width = 800;
  event.height = 600;
  event.pixel_ratio = 1.0;
  ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &event),
            kSuccess);

  // WaitWithTimeout returns true when it timed out.
  ASSERT_FALSE(latch.WaitWithTimeout(fml::TimeDelta::FromSeconds(30)))
      << "no frame reached the compositor";
  engine.reset();
  EXPECT_TRUE(g_vulkan_proc_info.did_call_queue_submit);
}

#endif  // IMPELLER_SUPPORTS_RENDERING

}  // namespace testing
}  // namespace flutter

// NOLINTEND(clang-analyzer-core.StackAddressEscape)
