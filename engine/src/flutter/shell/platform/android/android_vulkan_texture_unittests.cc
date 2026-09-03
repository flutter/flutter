// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <future>
#include <thread>
#include <vector>

#include "flutter/shell/platform/android/android_hardware_buffer.h"
#include "flutter/shell/platform/android/android_vulkan_texture.h"
#include "flutter/shell/platform/android/os_library_loader.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"

namespace flutter {
namespace android {
namespace testing {

using ::testing::_;
using ::testing::Return;

namespace {

// Mock Vulkan symbol addresses
static void* g_mock_vk_get_instance_proc_addr = reinterpret_cast<void*>(0x1111);
static void* g_mock_vk_create_image = reinterpret_cast<void*>(0x2222);
static void* g_mock_vk_destroy_image = reinterpret_cast<void*>(0x3333);
static void* g_mock_vk_get_image_memory_requirements =
    reinterpret_cast<void*>(0x4444);
static void* g_mock_vk_allocate_memory = reinterpret_cast<void*>(0x5555);
static void* g_mock_vk_free_memory = reinterpret_cast<void*>(0x6666);
static void* g_mock_vk_bind_image_memory = reinterpret_cast<void*>(0x7777);
static void* g_mock_vk_create_sampler_ycbcr_conversion =
    reinterpret_cast<void*>(0x8888);
static void* g_mock_vk_destroy_sampler_ycbcr_conversion =
    reinterpret_cast<void*>(0x9999);
static void* g_mock_vk_get_ahb_properties = reinterpret_cast<void*>(0xAAAA);

}  // namespace

TEST(AndroidVulkanTextureTest, FormatAndLayoutEnums) {
  EXPECT_EQ(static_cast<uint32_t>(AndroidVulkanFormat::kUndefined), 0u);
  EXPECT_EQ(static_cast<uint32_t>(AndroidVulkanFormat::kR8G8B8A8Unorm), 37u);
  EXPECT_EQ(static_cast<uint32_t>(AndroidVulkanFormat::kR8G8B8A8Srgb), 43u);
  EXPECT_EQ(static_cast<uint32_t>(AndroidVulkanFormat::kB8G8R8A8Unorm), 44u);
  EXPECT_EQ(static_cast<uint32_t>(AndroidVulkanFormat::kB8G8R8A8Srgb), 50u);
  EXPECT_EQ(static_cast<uint32_t>(AndroidVulkanFormat::kR16G16B16A16Sfloat),
            97u);
  EXPECT_EQ(static_cast<uint32_t>(AndroidVulkanFormat::kG8B8R83Plane420Unorm),
            1000156000u);
  EXPECT_EQ(static_cast<uint32_t>(AndroidVulkanFormat::kG8B8R82Plane420Unorm),
            1000156001u);

  EXPECT_EQ(static_cast<uint32_t>(AndroidVulkanImageLayout::kUndefined), 0u);
  EXPECT_EQ(static_cast<uint32_t>(AndroidVulkanImageLayout::kGeneral), 1u);
  EXPECT_EQ(
      static_cast<uint32_t>(AndroidVulkanImageLayout::kColorAttachmentOptimal),
      2u);
  EXPECT_EQ(
      static_cast<uint32_t>(AndroidVulkanImageLayout::kShaderReadOnlyOptimal),
      5u);
  EXPECT_EQ(
      static_cast<uint32_t>(AndroidVulkanImageLayout::kTransferSrcOptimal), 6u);
  EXPECT_EQ(
      static_cast<uint32_t>(AndroidVulkanImageLayout::kTransferDstOptimal), 7u);
  EXPECT_EQ(static_cast<uint32_t>(AndroidVulkanImageLayout::kPreinitialized),
            8u);
}

TEST(AndroidVulkanTextureTest, ComponentMappingAndSwizzle) {
  auto mapping = AndroidVulkanComponentMapping::MakeIdentity();
  EXPECT_EQ(mapping.r, AndroidVulkanComponentSwizzle::kIdentity);
  EXPECT_EQ(mapping.g, AndroidVulkanComponentSwizzle::kIdentity);
  EXPECT_EQ(mapping.b, AndroidVulkanComponentSwizzle::kIdentity);
  EXPECT_EQ(mapping.a, AndroidVulkanComponentSwizzle::kIdentity);

  FlutterVulkanComponentMapping c_mapping = mapping.ToFlutterComponentMapping();
  EXPECT_EQ(c_mapping.struct_size, sizeof(FlutterVulkanComponentMapping));
  EXPECT_EQ(c_mapping.r, kFlutterVulkanComponentSwizzleIdentity);
  EXPECT_EQ(c_mapping.g, kFlutterVulkanComponentSwizzleIdentity);
  EXPECT_EQ(c_mapping.b, kFlutterVulkanComponentSwizzleIdentity);
  EXPECT_EQ(c_mapping.a, kFlutterVulkanComponentSwizzleIdentity);

  AndroidVulkanComponentMapping custom_mapping;
  custom_mapping.r = AndroidVulkanComponentSwizzle::kB;
  custom_mapping.g = AndroidVulkanComponentSwizzle::kG;
  custom_mapping.b = AndroidVulkanComponentSwizzle::kR;
  custom_mapping.a = AndroidVulkanComponentSwizzle::kOne;

  FlutterVulkanComponentMapping custom_c =
      custom_mapping.ToFlutterComponentMapping();
  EXPECT_EQ(custom_c.r, kFlutterVulkanComponentSwizzleB);
  EXPECT_EQ(custom_c.g, kFlutterVulkanComponentSwizzleG);
  EXPECT_EQ(custom_c.b, kFlutterVulkanComponentSwizzleR);
  EXPECT_EQ(custom_c.a, kFlutterVulkanComponentSwizzleOne);

  auto roundtrip =
      AndroidVulkanComponentMapping::FromFlutterComponentMapping(custom_c);
  EXPECT_EQ(roundtrip, custom_mapping);
  EXPECT_NE(roundtrip, mapping);
}

TEST(AndroidVulkanTextureTest, YcbcrConversionDescCreationAndConversion) {
  constexpr uint64_t external_format_id = 0xABCD1234ULL;
  auto ycbcr = AndroidVulkanYcbcrConversionDesc::MakeExternal(
      external_format_id, AndroidVulkanYcbcrModel::kYcbcr709,
      AndroidVulkanYcbcrRange::kItuFull,
      AndroidVulkanChromaLocation::kCositedEven, AndroidVulkanFilter::kNearest);

  EXPECT_EQ(ycbcr.format, 0u);
  EXPECT_EQ(ycbcr.external_format, external_format_id);
  EXPECT_EQ(ycbcr.ycbcr_model,
            static_cast<uint32_t>(AndroidVulkanYcbcrModel::kYcbcr709));
  EXPECT_EQ(ycbcr.ycbcr_range,
            static_cast<uint32_t>(AndroidVulkanYcbcrRange::kItuFull));
  EXPECT_EQ(ycbcr.x_chroma_offset,
            static_cast<uint32_t>(AndroidVulkanChromaLocation::kCositedEven));
  EXPECT_EQ(ycbcr.y_chroma_offset,
            static_cast<uint32_t>(AndroidVulkanChromaLocation::kCositedEven));
  EXPECT_EQ(ycbcr.chroma_filter,
            static_cast<uint32_t>(AndroidVulkanFilter::kNearest));
  EXPECT_EQ(ycbcr.force_explicit_reconstruction, 0u);

  FlutterVulkanYcbcrConversionInfo c_info =
      ycbcr.ToFlutterYcbcrConversionInfo();
  EXPECT_EQ(c_info.struct_size, sizeof(FlutterVulkanYcbcrConversionInfo));
  EXPECT_EQ(c_info.external_format, external_format_id);
  EXPECT_EQ(c_info.ycbcr_model,
            static_cast<uint32_t>(AndroidVulkanYcbcrModel::kYcbcr709));
  EXPECT_EQ(c_info.ycbcr_range,
            static_cast<uint32_t>(AndroidVulkanYcbcrRange::kItuFull));
  EXPECT_EQ(c_info.components.struct_size,
            sizeof(FlutterVulkanComponentMapping));

  auto roundtrip =
      AndroidVulkanYcbcrConversionDesc::FromFlutterYcbcrConversionInfo(c_info);
  EXPECT_EQ(roundtrip, ycbcr);
}

TEST(AndroidVulkanTextureTest, ImageDescValidationAndEquality) {
  auto desc_rgba = AndroidVulkanImageDesc::MakeRGBA8(1920, 1080);
  EXPECT_TRUE(desc_rgba.IsValid());
  EXPECT_EQ(desc_rgba.width, 1920u);
  EXPECT_EQ(desc_rgba.height, 1080u);
  EXPECT_EQ(desc_rgba.format,
            static_cast<uint32_t>(AndroidVulkanFormat::kR8G8B8A8Unorm));
  EXPECT_EQ(
      desc_rgba.image_layout,
      static_cast<uint32_t>(AndroidVulkanImageLayout::kShaderReadOnlyOptimal));
  EXPECT_FALSE(desc_rgba.ycbcr_conversion.has_value());

  auto ycbcr = AndroidVulkanYcbcrConversionDesc::MakeExternal(0x12345ULL);
  auto desc_ycbcr = AndroidVulkanImageDesc::MakeYcbcr(1280, 720, ycbcr);
  EXPECT_TRUE(desc_ycbcr.IsValid());
  EXPECT_EQ(desc_ycbcr.width, 1280u);
  EXPECT_EQ(desc_ycbcr.height, 720u);
  ASSERT_TRUE(desc_ycbcr.ycbcr_conversion.has_value());
  if (desc_ycbcr.ycbcr_conversion.has_value()) {
    EXPECT_EQ(desc_ycbcr.ycbcr_conversion.value(), ycbcr);
  }

  AndroidVulkanImageDesc invalid_desc = {};
  EXPECT_FALSE(invalid_desc.IsValid());

  EXPECT_NE(desc_rgba, desc_ycbcr);
  EXPECT_EQ(desc_rgba, AndroidVulkanImageDesc::MakeRGBA8(1920, 1080));
}

TEST(AndroidVulkanTextureTest, DefaultProviderWithMockOSLibraryLoader) {
  auto mock_loader = std::make_shared<MockOSLibraryLoader>();
  auto mock_libvulkan = std::make_shared<MockOSLibrary>("libvulkan.so");

  mock_libvulkan->SetSymbol("vkGetInstanceProcAddr",
                            g_mock_vk_get_instance_proc_addr);
  mock_libvulkan->SetSymbol("vkCreateImage", g_mock_vk_create_image);
  mock_libvulkan->SetSymbol("vkDestroyImage", g_mock_vk_destroy_image);
  mock_libvulkan->SetSymbol("vkGetImageMemoryRequirements",
                            g_mock_vk_get_image_memory_requirements);
  mock_libvulkan->SetSymbol("vkAllocateMemory", g_mock_vk_allocate_memory);
  mock_libvulkan->SetSymbol("vkFreeMemory", g_mock_vk_free_memory);
  mock_libvulkan->SetSymbol("vkBindImageMemory", g_mock_vk_bind_image_memory);
  mock_libvulkan->SetSymbol("vkCreateSamplerYcbcrConversion",
                            g_mock_vk_create_sampler_ycbcr_conversion);
  mock_libvulkan->SetSymbol("vkDestroySamplerYcbcrConversion",
                            g_mock_vk_destroy_sampler_ycbcr_conversion);
  mock_libvulkan->SetSymbol("vkGetAndroidHardwareBufferPropertiesANDROID",
                            g_mock_vk_get_ahb_properties);

  mock_loader->RegisterLibrary("libvulkan.so", mock_libvulkan);

  auto provider =
      std::make_shared<DefaultAndroidVulkanTextureProvider>(mock_loader);
  EXPECT_TRUE(provider->IsAvailable());

  EXPECT_EQ(provider->ResolveVulkanSymbol("vkGetInstanceProcAddr"),
            g_mock_vk_get_instance_proc_addr);
  EXPECT_EQ(provider->ResolveVulkanSymbol("vkCreateImage"),
            g_mock_vk_create_image);
  EXPECT_EQ(provider->ResolveVulkanSymbol("vkCreateSamplerYcbcrConversion"),
            g_mock_vk_create_sampler_ycbcr_conversion);

  auto desc = AndroidVulkanImageDesc::MakeRGBA8(800, 600);
  EXPECT_TRUE(provider->IsSupported(desc));

  uint64_t mock_vk_image_handle = 0xFEEDFACEULL;
  auto texture =
      provider->CreateFromNativeImage(mock_vk_image_handle, desc, false);
  ASSERT_NE(texture, nullptr);
  EXPECT_TRUE(texture->IsValid());
  EXPECT_EQ(texture->GetImageHandle(), mock_vk_image_handle);
  EXPECT_EQ(texture->GetDescription().width, 800u);
  EXPECT_EQ(texture->GetDescription().height, 600u);

  FlutterVulkanExternalTexture ext_texture = texture->ToExternalTexture();
  EXPECT_EQ(ext_texture.struct_size, sizeof(FlutterVulkanExternalTexture));
  EXPECT_EQ(ext_texture.image, mock_vk_image_handle);
  EXPECT_EQ(ext_texture.width, 800u);
  EXPECT_EQ(ext_texture.height, 600u);
  EXPECT_EQ(ext_texture.ycbcr_conversion_info, nullptr);

  FlutterVulkanImage vk_image = texture->ToFlutterVulkanImage();
  EXPECT_EQ(vk_image.struct_size, sizeof(FlutterVulkanImage));
  EXPECT_EQ(vk_image.image, mock_vk_image_handle);
}

TEST(AndroidVulkanTextureTest, DefaultProviderFallbackWhenNoLibVulkan) {
  auto empty_loader = std::make_shared<MockOSLibraryLoader>();
  auto provider =
      std::make_shared<DefaultAndroidVulkanTextureProvider>(empty_loader);
  EXPECT_FALSE(provider->IsAvailable());
  EXPECT_EQ(provider->ResolveVulkanSymbol("vkGetInstanceProcAddr"), nullptr);

  auto desc = AndroidVulkanImageDesc::MakeRGBA8(800, 600);
  EXPECT_FALSE(provider->IsSupported(desc));
  EXPECT_EQ(provider->AllocateTexture(desc), nullptr);
  EXPECT_EQ(provider->CreateFromNativeImage(0x1234, desc), nullptr);
}

TEST(AndroidVulkanTextureTest, InMemoryVulkanExternalTextureLifecycle) {
  auto provider = std::make_shared<InMemoryAndroidVulkanTextureProvider>();
  EXPECT_TRUE(provider->IsAvailable());

  auto desc = AndroidVulkanImageDesc::MakeRGBA8(1024, 768);
  auto texture = provider->AllocateTexture(desc);
  ASSERT_NE(texture, nullptr);
  EXPECT_TRUE(texture->IsValid());
  EXPECT_NE(texture->GetImageHandle(), 0u);
  EXPECT_EQ(texture->GetDescription().width, 1024u);
  EXPECT_EQ(texture->GetDescription().height, 768u);
  EXPECT_FALSE(texture->HasYcbcrConversion());
  EXPECT_EQ(texture->GetYcbcrConversionDesc(), nullptr);

  // Layout updates
  EXPECT_EQ(
      texture->GetImageLayout(),
      static_cast<uint32_t>(AndroidVulkanImageLayout::kShaderReadOnlyOptimal));
  texture->SetImageLayout(
      static_cast<uint32_t>(AndroidVulkanImageLayout::kGeneral));
  EXPECT_EQ(texture->GetImageLayout(),
            static_cast<uint32_t>(AndroidVulkanImageLayout::kGeneral));

  // Struct conversion
  bool destruction_called = false;
  auto destruction_cb = [](void* data) {
    *reinterpret_cast<bool*>(data) = true;
  };

  FlutterVulkanExternalTexture ext_texture =
      texture->ToExternalTexture(&destruction_called, destruction_cb);
  EXPECT_EQ(ext_texture.struct_size, sizeof(FlutterVulkanExternalTexture));
  EXPECT_EQ(ext_texture.width, 1024u);
  EXPECT_EQ(ext_texture.height, 768u);
  EXPECT_EQ(ext_texture.image, texture->GetImageHandle());
  EXPECT_EQ(ext_texture.image_layout,
            static_cast<uint32_t>(AndroidVulkanImageLayout::kGeneral));
  EXPECT_EQ(ext_texture.user_data, &destruction_called);
  EXPECT_TRUE(ext_texture.destruction_callback == destruction_cb);

  ext_texture.destruction_callback(ext_texture.user_data);
  EXPECT_TRUE(destruction_called);

  // In-memory data checks
  auto* in_memory_tex =
      static_cast<InMemoryAndroidVulkanExternalTexture*>(texture.get());
  ASSERT_NE(in_memory_tex, nullptr);
  EXPECT_NE(in_memory_tex->GetBackingData(), nullptr);
  EXPECT_EQ(in_memory_tex->GetBackingDataSize(), 1024u * 768u * 4u);
  EXPECT_EQ(in_memory_tex->GetRefCount(), 1);

  in_memory_tex->Acquire();
  EXPECT_EQ(in_memory_tex->GetRefCount(), 2);
  in_memory_tex->Release();
  EXPECT_EQ(in_memory_tex->GetRefCount(), 1);
}

TEST(AndroidVulkanTextureTest, InMemoryVulkanExternalTextureWithYcbcr) {
  auto provider = std::make_shared<InMemoryAndroidVulkanTextureProvider>();
  auto ycbcr_desc =
      AndroidVulkanYcbcrConversionDesc::MakeExternal(0x9876543210ULL);
  auto desc = AndroidVulkanImageDesc::MakeYcbcr(1920, 1080, ycbcr_desc);

  auto texture = provider->AllocateTexture(desc);
  ASSERT_NE(texture, nullptr);
  EXPECT_TRUE(texture->IsValid());
  EXPECT_TRUE(texture->HasYcbcrConversion());
  ASSERT_NE(texture->GetYcbcrConversionDesc(), nullptr);
  EXPECT_EQ(*texture->GetYcbcrConversionDesc(), ycbcr_desc);

  FlutterVulkanExternalTexture ext_texture = texture->ToExternalTexture();
  EXPECT_EQ(ext_texture.struct_size, sizeof(FlutterVulkanExternalTexture));
  EXPECT_EQ(ext_texture.format, 0u);
  ASSERT_NE(ext_texture.ycbcr_conversion_info, nullptr);
  EXPECT_EQ(ext_texture.ycbcr_conversion_info->external_format,
            0x9876543210ULL);
  EXPECT_EQ(ext_texture.ycbcr_conversion_info->struct_size,
            sizeof(FlutterVulkanYcbcrConversionInfo));
}

TEST(AndroidVulkanTextureTest, InMemoryProviderOperationsAndControls) {
  auto provider = std::make_shared<InMemoryAndroidVulkanTextureProvider>();

  EXPECT_EQ(provider->GetAllocationCount(), 0u);
  EXPECT_EQ(provider->GetActiveTextureCount(), 0u);

  auto desc = AndroidVulkanImageDesc::MakeRGBA8(640, 480);
  auto tex1 = provider->AllocateTexture(desc);
  auto tex2 = provider->AllocateTexture(desc);

  EXPECT_EQ(provider->GetAllocationCount(), 2u);
  EXPECT_EQ(provider->GetActiveTextureCount(), 2u);

  tex1.reset();
  EXPECT_EQ(provider->GetReleaseCount(), 1u);
  EXPECT_EQ(provider->GetActiveTextureCount(), 1u);

  tex2.reset();
  EXPECT_EQ(provider->GetReleaseCount(), 2u);
  EXPECT_EQ(provider->GetActiveTextureCount(), 0u);

  // Failure simulation
  provider->SetAllocationFailure(true);
  EXPECT_EQ(provider->AllocateTexture(desc), nullptr);
  provider->SetAllocationFailure(false);

  // Availability control
  provider->SetAvailable(false);
  EXPECT_FALSE(provider->IsAvailable());
  EXPECT_FALSE(provider->IsSupported(desc));
  EXPECT_EQ(provider->AllocateTexture(desc), nullptr);
  provider->SetAvailable(true);

  // Symbol resolution mock
  void* dummy_symbol = reinterpret_cast<void*>(0x8888);
  provider->SetSymbol("vkCustomExtension", dummy_symbol);
  EXPECT_EQ(provider->ResolveVulkanSymbol("vkCustomExtension"), dummy_symbol);
  EXPECT_EQ(provider->ResolveVulkanSymbol("nonexistent"), nullptr);
}

TEST(AndroidVulkanTextureTest, CreateFromAHardwareBufferIntegration) {
  auto ahb_provider = std::make_shared<InMemoryAndroidHardwareBufferProvider>();
  auto vk_provider = std::make_shared<InMemoryAndroidVulkanTextureProvider>();

  // 1. RGBA8 HardwareBuffer -> Vulkan Texture
  auto ahb_rgba_desc = AndroidHardwareBufferDesc::MakeRGBA8(1920, 1080);
  auto ahb_rgba = ahb_provider->Allocate(ahb_rgba_desc);
  ASSERT_NE(ahb_rgba, nullptr);

  auto vk_rgba_tex = vk_provider->CreateFromAHardwareBuffer(ahb_rgba.get());
  ASSERT_NE(vk_rgba_tex, nullptr);
  EXPECT_TRUE(vk_rgba_tex->IsValid());
  EXPECT_EQ(vk_rgba_tex->GetDescription().width, 1920u);
  EXPECT_EQ(vk_rgba_tex->GetDescription().height, 1080u);
  EXPECT_EQ(vk_rgba_tex->GetDescription().format,
            static_cast<uint32_t>(AndroidVulkanFormat::kR8G8B8A8Unorm));
  EXPECT_FALSE(vk_rgba_tex->HasYcbcrConversion());

  // 2. YUV Y8Cb8Cr8_420 HardwareBuffer -> Vulkan Texture with auto-generated
  // YCbCr conversion
  AndroidHardwareBufferDesc ahb_yuv_desc;
  ahb_yuv_desc.width = 1280;
  ahb_yuv_desc.height = 720;
  ahb_yuv_desc.format =
      static_cast<uint32_t>(AndroidHardwareBufferFormat::kY8Cb8Cr8420);
  ahb_yuv_desc.usage = AndroidHardwareBufferUsage::kGpuSampledImage;
  ahb_yuv_desc.stride = 1280;

  auto ahb_yuv = ahb_provider->Allocate(ahb_yuv_desc);
  ASSERT_NE(ahb_yuv, nullptr);

  auto vk_yuv_tex = vk_provider->CreateFromAHardwareBuffer(ahb_yuv.get());
  ASSERT_NE(vk_yuv_tex, nullptr);
  EXPECT_TRUE(vk_yuv_tex->IsValid());
  EXPECT_EQ(vk_yuv_tex->GetDescription().width, 1280u);
  EXPECT_EQ(vk_yuv_tex->GetDescription().height, 720u);
  EXPECT_EQ(vk_yuv_tex->GetDescription().format, 0u);
  EXPECT_TRUE(vk_yuv_tex->HasYcbcrConversion());
  ASSERT_NE(vk_yuv_tex->GetYcbcrConversionDesc(), nullptr);
  EXPECT_EQ(vk_yuv_tex->GetYcbcrConversionDesc()->external_format,
            ahb_yuv->GetId());

  FlutterVulkanExternalTexture ext_yuv = vk_yuv_tex->ToExternalTexture();
  ASSERT_NE(ext_yuv.ycbcr_conversion_info, nullptr);
  EXPECT_EQ(ext_yuv.ycbcr_conversion_info->external_format, ahb_yuv->GetId());
}

TEST(AndroidVulkanTextureTest, ConcurrentMultiThreadedVulkanTextureOperations) {
  auto provider = std::make_shared<InMemoryAndroidVulkanTextureProvider>();
  constexpr int kThreadCount = 8;
  constexpr int kIterationsPerThread = 50;

  std::vector<std::future<void>> futures;
  futures.reserve(kThreadCount);

  for (int t = 0; t < kThreadCount; ++t) {
    futures.push_back(std::async(std::launch::async, [provider, t]() {
      for (int i = 0; i < kIterationsPerThread; ++i) {
        auto desc = AndroidVulkanImageDesc::MakeRGBA8(200 + (t * 10) + i,
                                                      100 + (t * 10) + i);
        auto tex = provider->AllocateTexture(desc);
        ASSERT_NE(tex, nullptr);
        EXPECT_TRUE(tex->IsValid());

        tex->SetImageLayout(
            static_cast<uint32_t>(AndroidVulkanImageLayout::kGeneral));
        EXPECT_EQ(tex->GetImageLayout(),
                  static_cast<uint32_t>(AndroidVulkanImageLayout::kGeneral));

        FlutterVulkanExternalTexture ext = tex->ToExternalTexture();
        EXPECT_EQ(ext.width, static_cast<size_t>(200 + (t * 10) + i));

        tex->Acquire();
        tex->Release();
      }
    }));
  }

  for (auto& f : futures) {
    f.get();
  }

  EXPECT_EQ(provider->GetAllocationCount(),
            static_cast<size_t>(kThreadCount * kIterationsPerThread));
  EXPECT_EQ(provider->GetReleaseCount(),
            static_cast<size_t>(kThreadCount * kIterationsPerThread));
  EXPECT_EQ(provider->GetActiveTextureCount(), 0u);
}

}  // namespace testing
}  // namespace android
}  // namespace flutter
