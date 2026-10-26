// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <array>
#include <cstring>
#include <memory>
#include <string>

#include "flutter/shell/platform/android/android_hardware_buffer.h"
#include "flutter/shell/platform/android/android_vulkan_external_texture.h"
#include "gtest/gtest.h"

namespace flutter {
namespace android {
namespace testing {

namespace {

// Named constants for test dimensions, handles, and Vulkan formats.
constexpr uint32_t kTestTextureWidth = 640;
constexpr uint32_t kTestTextureHeight = 480;
constexpr uint32_t kGlTextureName = 42;
constexpr uint32_t kGlTextureExternalOesTarget = 0x8D65;
constexpr int64_t kTestTextureId = 101;

constexpr uintptr_t kDummyAhbRawHandle = 0xA001;
constexpr uintptr_t kDummyVkDevice = 0xB003;

constexpr uint64_t kExternalYcbcrFormat = 0x55AA1234ULL;
constexpr uint32_t kAllocatedMemoryTypeBits = 0x00000004u;
constexpr uint64_t kAllocationByteSize = 1024 * 1024;
constexpr uint32_t kVkFilterNearest = 0u;
constexpr uint32_t kVkFilterLinear = 1u;

struct MockNdkAhbEnv {
  int allocate_calls = 0;
  int acquire_calls = 0;
  int release_calls = 0;
  int lock_calls = 0;
  int unlock_calls = 0;
  uint8_t pixel_storage[256] = {};
};

MockNdkAhbEnv* g_ahb_env = nullptr;

int StubAHardwareBufferAllocate(const AndroidHardwareBufferDesc* desc,
                                void** out_buffer) {
  if (desc == nullptr || out_buffer == nullptr || !desc->IsValid()) {
    return -1;
  }
  if (g_ahb_env != nullptr) {
    ++g_ahb_env->allocate_calls;
  }
  *out_buffer = reinterpret_cast<void*>(kDummyAhbRawHandle);
  return 0;
}

void StubAHardwareBufferAcquire(void* /*buffer*/) {
  if (g_ahb_env != nullptr) {
    ++g_ahb_env->acquire_calls;
  }
}

void StubAHardwareBufferRelease(void* /*buffer*/) {
  if (g_ahb_env != nullptr) {
    ++g_ahb_env->release_calls;
  }
}

void StubAHardwareBufferDescribe(const void* /*buffer*/,
                                 AndroidHardwareBufferDesc* out_desc) {
  if (out_desc != nullptr) {
    *out_desc = AndroidHardwareBufferDesc::MakeRGBA8(kTestTextureWidth,
                                                     kTestTextureHeight);
  }
}

int StubAHardwareBufferLock(void* /*buffer*/,
                            uint64_t /*usage*/,
                            int32_t /*fence*/,
                            const AndroidHardwareBufferRect* /*rect*/,
                            void** out_virtual_address) {
  if (g_ahb_env != nullptr) {
    ++g_ahb_env->lock_calls;
    if (out_virtual_address != nullptr) {
      *out_virtual_address = g_ahb_env->pixel_storage;
    }
  }
  return 0;
}

int StubAHardwareBufferUnlock(void* /*buffer*/, int32_t* fence) {
  if (g_ahb_env != nullptr) {
    ++g_ahb_env->unlock_calls;
  }
  if (fence != nullptr) {
    *fence = -1;
  }
  return 0;
}

int StubAHardwareBufferSendHandle(const void* /*buffer*/, int /*socket_fd*/) {
  return 0;
}

int StubAHardwareBufferRecvHandle(int /*socket_fd*/, void** out_buffer) {
  if (out_buffer != nullptr) {
    *out_buffer = reinterpret_cast<void*>(kDummyAhbRawHandle);
  }
  return 0;
}

std::shared_ptr<MockOSLibrary> CreateMockAhbAndroidLibrary() {
  auto lib = std::make_shared<MockOSLibrary>();
  lib->RegisterSymbol("AHardwareBuffer_allocate",
                      reinterpret_cast<void*>(&StubAHardwareBufferAllocate));
  lib->RegisterSymbol("AHardwareBuffer_acquire",
                      reinterpret_cast<void*>(&StubAHardwareBufferAcquire));
  lib->RegisterSymbol("AHardwareBuffer_release",
                      reinterpret_cast<void*>(&StubAHardwareBufferRelease));
  lib->RegisterSymbol("AHardwareBuffer_describe",
                      reinterpret_cast<void*>(&StubAHardwareBufferDescribe));
  lib->RegisterSymbol("AHardwareBuffer_lock",
                      reinterpret_cast<void*>(&StubAHardwareBufferLock));
  lib->RegisterSymbol("AHardwareBuffer_unlock",
                      reinterpret_cast<void*>(&StubAHardwareBufferUnlock));
  lib->RegisterSymbol("AHardwareBuffer_sendHandleToUnixSocket",
                      reinterpret_cast<void*>(&StubAHardwareBufferSendHandle));
  lib->RegisterSymbol("AHardwareBuffer_recvHandleFromUnixSocket",
                      reinterpret_cast<void*>(&StubAHardwareBufferRecvHandle));
  return lib;
}

// =============================================================================
// Mock Vulkan AHB Import Environment
// =============================================================================

struct MockVulkanStructHeader {
  uint32_t sType;
  const void* pNext;
};

struct MockVkExternalFormatANDROID {
  uint32_t sType;
  const void* pNext;
  uint64_t externalFormat;
};

struct MockVulkanAhbEnv {
  uint32_t reported_vk_format = 0;  // 0 = VK_FORMAT_UNDEFINED (external YCbCr)
  uint64_t reported_external_format = kExternalYcbcrFormat;
  uint32_t reported_format_features =
      0x00000001u;  // Lacks LINEAR_BIT (0x10000) -> clamps to NEAREST
  size_t create_image_calls = 0;
  size_t allocate_memory_calls = 0;
  size_t bind_image_memory_calls = 0;
  size_t destroy_image_calls = 0;
  size_t free_memory_calls = 0;
  uint32_t last_import_ahb_stype = 0;
  uint32_t last_external_format_stype = 0;
  bool last_external_format_chained = false;
  uint64_t last_external_format_value = 0;
};

MockVulkanAhbEnv* g_vk_ahb_env = nullptr;

int32_t StubVkGetAndroidHardwareBufferPropertiesANDROID(
    void* /*device*/,
    const void* /*buffer*/,
    VkAndroidHardwareBufferPropertiesANDROIDCompat* properties) {
  if (properties == nullptr) {
    return -1;
  }
  properties->allocationSize = kAllocationByteSize;
  properties->memoryTypeBits = kAllocatedMemoryTypeBits;

  auto* format_props =
      static_cast<VkAndroidHardwareBufferFormatPropertiesANDROIDCompat*>(
          properties->pNext);
  if (format_props != nullptr) {
    format_props->format =
        g_vk_ahb_env != nullptr ? g_vk_ahb_env->reported_vk_format : 0u;
    format_props->externalFormat = g_vk_ahb_env != nullptr
                                       ? g_vk_ahb_env->reported_external_format
                                       : kExternalYcbcrFormat;
    format_props->formatFeatures = g_vk_ahb_env != nullptr
                                       ? g_vk_ahb_env->reported_format_features
                                       : 0x00000001u;
    format_props->samplerYcbcrConversionComponents = {0, 0, 0, 0};
    format_props->suggestedYcbcrModel =
        static_cast<uint32_t>(AndroidVulkanYcbcrModel::kYcbcr709);
    format_props->suggestedYcbcrRange =
        static_cast<uint32_t>(AndroidVulkanYcbcrRange::kItuNarrow);
    format_props->suggestedXChromaOffset =
        static_cast<uint32_t>(AndroidVulkanChromaLocation::kMidpoint);
    format_props->suggestedYChromaOffset =
        static_cast<uint32_t>(AndroidVulkanChromaLocation::kMidpoint);
  }
  return 0;
}

int32_t StubVkCreateImageForAhb(void* /*device*/,
                                const void* create_info,
                                const void* /*allocator*/,
                                uint64_t* image_out) {
  if (g_vk_ahb_env != nullptr) {
    ++g_vk_ahb_env->create_image_calls;
    g_vk_ahb_env->last_external_format_chained = false;
    g_vk_ahb_env->last_external_format_stype = 0;
    g_vk_ahb_env->last_external_format_value = 0;
    if (create_info != nullptr) {
      const auto* image_header =
          static_cast<const MockVulkanStructHeader*>(create_info);
      const auto* ext_mem_header =
          static_cast<const MockVulkanStructHeader*>(image_header->pNext);
      if (ext_mem_header != nullptr && ext_mem_header->pNext != nullptr) {
        const auto* ext_fmt = static_cast<const MockVkExternalFormatANDROID*>(
            ext_mem_header->pNext);
        g_vk_ahb_env->last_external_format_chained = true;
        g_vk_ahb_env->last_external_format_stype = ext_fmt->sType;
        g_vk_ahb_env->last_external_format_value = ext_fmt->externalFormat;
      }
    }
  }
  *image_out =
      0xC001 + (g_vk_ahb_env != nullptr ? g_vk_ahb_env->create_image_calls : 0);
  return 0;
}

void StubVkDestroyImageForAhb(void* /*device*/,
                              uint64_t /*image*/,
                              const void* /*allocator*/) {
  if (g_vk_ahb_env != nullptr) {
    ++g_vk_ahb_env->destroy_image_calls;
  }
}

int32_t StubVkAllocateMemoryForAhb(void* /*device*/,
                                   const void* allocate_info,
                                   const void* /*allocator*/,
                                   void** memory_out) {
  if (g_vk_ahb_env != nullptr) {
    ++g_vk_ahb_env->allocate_memory_calls;
    if (allocate_info != nullptr) {
      const auto* alloc_header =
          static_cast<const MockVulkanStructHeader*>(allocate_info);
      const auto* import_header =
          static_cast<const MockVulkanStructHeader*>(alloc_header->pNext);
      if (import_header != nullptr) {
        g_vk_ahb_env->last_import_ahb_stype = import_header->sType;
      }
    }
  }
  *memory_out = reinterpret_cast<void*>(0xC002);
  return 0;
}

void StubVkFreeMemoryForAhb(void* /*device*/,
                            void* /*memory*/,
                            const void* /*allocator*/) {
  if (g_vk_ahb_env != nullptr) {
    ++g_vk_ahb_env->free_memory_calls;
  }
}

int32_t StubVkBindImageMemoryForAhb(void* /*device*/,
                                    uint64_t /*image*/,
                                    void* /*memory*/,
                                    uint64_t /*memory_offset*/) {
  if (g_vk_ahb_env != nullptr) {
    ++g_vk_ahb_env->bind_image_memory_calls;
  }
  return 0;
}

void* StubVkGetInstanceProcAddrForAhb(void* /*instance*/, const char* name) {
  if (name == nullptr) {
    return nullptr;
  }
  if (std::strcmp(name, "vkGetInstanceProcAddr") == 0) {
    return reinterpret_cast<void*>(&StubVkGetInstanceProcAddrForAhb);
  }
  return nullptr;
}

std::shared_ptr<MockOSLibrary> CreateMockVulkanAhbLibrary() {
  auto vk_lib = std::make_shared<MockOSLibrary>();
  vk_lib->RegisterSymbol(
      "vkGetInstanceProcAddr",
      reinterpret_cast<void*>(&StubVkGetInstanceProcAddrForAhb));
  vk_lib->RegisterSymbol("vkGetAndroidHardwareBufferPropertiesANDROID",
                         reinterpret_cast<void*>(
                             &StubVkGetAndroidHardwareBufferPropertiesANDROID));
  vk_lib->RegisterSymbol("vkCreateImage",
                         reinterpret_cast<void*>(&StubVkCreateImageForAhb));
  vk_lib->RegisterSymbol("vkDestroyImage",
                         reinterpret_cast<void*>(&StubVkDestroyImageForAhb));
  vk_lib->RegisterSymbol("vkAllocateMemory",
                         reinterpret_cast<void*>(&StubVkAllocateMemoryForAhb));
  vk_lib->RegisterSymbol("vkFreeMemory",
                         reinterpret_cast<void*>(&StubVkFreeMemoryForAhb));
  vk_lib->RegisterSymbol("vkBindImageMemory",
                         reinterpret_cast<void*>(&StubVkBindImageMemoryForAhb));
  return vk_lib;
}

}  // namespace

// =============================================================================
// AndroidHardwareBuffer & OpenGL External Texture Tests
// =============================================================================

TEST(AndroidExternalTextureTest,
     InMemoryAndDefaultHardwareBufferProvidersManageLifecycle) {
  // 1. InMemoryAndroidHardwareBufferProvider
  auto mem_provider = std::make_shared<InMemoryAndroidHardwareBufferProvider>();
  EXPECT_TRUE(mem_provider->IsAvailable());

  auto desc = AndroidHardwareBufferDesc::MakeRGBA8(kTestTextureWidth,
                                                   kTestTextureHeight);
  EXPECT_TRUE(desc.IsValid());

  auto mem_buf = mem_provider->Allocate(desc);
  ASSERT_NE(mem_buf, nullptr);
  EXPECT_TRUE(mem_buf->IsValid());
  EXPECT_EQ(mem_buf->GetDescription(), desc);

  void* locked_addr = nullptr;
  EXPECT_EQ(mem_buf->Lock(AndroidHardwareBufferUsage::kCpuWriteOften, -1,
                          nullptr, &locked_addr),
            0);
  EXPECT_NE(locked_addr, nullptr);
  int32_t unlock_fence = -1;
  EXPECT_EQ(mem_buf->Unlock(&unlock_fence), 0);

  // 2. DefaultAndroidHardwareBufferProvider with mocked libandroid.so
  MockNdkAhbEnv ahb_env;
  g_ahb_env = &ahb_env;

  auto loader = std::make_shared<MockOSLibraryLoader>();
  loader->RegisterLibrary("libandroid.so", CreateMockAhbAndroidLibrary());

  auto default_provider =
      std::make_shared<DefaultAndroidHardwareBufferProvider>(loader);
  EXPECT_TRUE(default_provider->IsAvailable());

  auto ndk_buf = default_provider->Allocate(desc);
  ASSERT_NE(ndk_buf, nullptr);
  EXPECT_TRUE(ndk_buf->IsValid());
  EXPECT_EQ(ahb_env.allocate_calls, 1);

  void* ndk_locked = nullptr;
  EXPECT_EQ(ndk_buf->Lock(AndroidHardwareBufferUsage::kCpuReadOften, -1,
                          nullptr, &ndk_locked),
            0);
  EXPECT_EQ(ndk_locked, ahb_env.pixel_storage);
  EXPECT_EQ(ndk_buf->Unlock(nullptr), 0);

  ndk_buf.reset();
  EXPECT_EQ(ahb_env.release_calls, 1);
  g_ahb_env = nullptr;
}

TEST(AndroidExternalTextureTest,
     OpenGLExternalTexturePopulatesSurfaceTextureUvTransformAndAhbTarget) {
  // 1. SurfaceProducer AHB on OpenGL ES -> `has_uv_transform = false`, identity
  // matrix.
  auto mem_provider = std::make_shared<InMemoryAndroidHardwareBufferProvider>();
  auto ahb = mem_provider->Allocate(AndroidHardwareBufferDesc::MakeRGBA8(
      kTestTextureWidth, kTestTextureHeight));
  ASSERT_NE(ahb, nullptr);

  FlutterOpenGLExternalTexture gl_tex_ahb = {};
  EXPECT_TRUE(PopulateFlutterOpenGLExternalTextureFromHardwareBuffer(
      ahb.get(), kGlTextureName, &gl_tex_ahb));
  EXPECT_EQ(gl_tex_ahb.target, kGlTextureExternalOesTarget);
  EXPECT_EQ(gl_tex_ahb.name, kGlTextureName);
  EXPECT_EQ(gl_tex_ahb.width, kTestTextureWidth);
  EXPECT_EQ(gl_tex_ahb.height, kTestTextureHeight);
  EXPECT_FALSE(gl_tex_ahb.has_uv_transform);
  EXPECT_FLOAT_EQ(gl_tex_ahb.uv_transform[0], 1.0f);
  EXPECT_FLOAT_EQ(gl_tex_ahb.uv_transform[5], 1.0f);

  // 2. SurfaceTexture on OpenGL ES -> `has_uv_transform = true` and copies the
  // 4x4 column-major transform matrix from `SurfaceTexture.getTransformMatrix`.
  const std::array<float, 16> vertical_flip_matrix = {
      1.0f, 0.0f,  0.0f, 0.0f,  // col 0
      0.0f, -1.0f, 0.0f, 0.0f,  // col 1 (flip V)
      0.0f, 0.0f,  1.0f, 0.0f,  // col 2
      0.0f, 1.0f,  0.0f, 1.0f,  // col 3 (translate V by +1)
  };

  FlutterOpenGLExternalTexture gl_tex_st = {};
  EXPECT_TRUE(PopulateFlutterOpenGLExternalTextureFromSurfaceTexture(
      kGlTextureName, kTestTextureWidth, kTestTextureHeight,
      vertical_flip_matrix.data(), &gl_tex_st));
  EXPECT_EQ(gl_tex_st.target, kGlTextureExternalOesTarget);
  EXPECT_EQ(gl_tex_st.name, kGlTextureName);
  EXPECT_TRUE(gl_tex_st.has_uv_transform);
  for (size_t i = 0; i < vertical_flip_matrix.size(); ++i) {
    EXPECT_FLOAT_EQ(gl_tex_st.uv_transform[i], vertical_flip_matrix[i]);
  }
}

// =============================================================================
// AndroidVulkanExternalTexture & SurfaceTexture GL-to-AHB Blit Tests
// =============================================================================

TEST(AndroidExternalTextureTest,
     DefaultVulkanTextureProviderImportsAhbWithYcbcrConversionAndClampsFilter) {
  MockVulkanAhbEnv vk_ahb_env;
  g_vk_ahb_env = &vk_ahb_env;

  auto loader = std::make_shared<MockOSLibraryLoader>();
  loader->RegisterLibrary("libvulkan.so", CreateMockVulkanAhbLibrary());

  auto provider = std::make_shared<DefaultAndroidVulkanTextureProvider>(
      loader, reinterpret_cast<void*>(kDummyVkDevice));
  ASSERT_TRUE(provider->IsAvailable());

  auto ahb_provider = std::make_shared<InMemoryAndroidHardwareBufferProvider>();
  auto ahb = ahb_provider->Allocate(AndroidHardwareBufferDesc::MakeRGBA8(
      kTestTextureWidth, kTestTextureHeight));
  ASSERT_NE(ahb, nullptr);

  // Import AHardwareBuffer with external YCbCr format (format == 0) whose
  // formatFeatures lack
  // VK_FORMAT_FEATURE_SAMPLED_IMAGE_YCBCR_CONVERSION_LINEAR_BIT.
  auto vk_tex = provider->CreateFromAHardwareBuffer(ahb.get());
  ASSERT_NE(vk_tex, nullptr);
  EXPECT_TRUE(vk_tex->IsValid());
  EXPECT_TRUE(vk_tex->HasYcbcrConversion());
  EXPECT_EQ(vk_ahb_env.create_image_calls, 1u);
  EXPECT_EQ(vk_ahb_env.allocate_memory_calls, 1u);
  EXPECT_EQ(vk_ahb_env.bind_image_memory_calls, 1u);
  // VK_STRUCTURE_TYPE_IMPORT_ANDROID_HARDWARE_BUFFER_INFO_ANDROID = 1000129003
  EXPECT_EQ(vk_ahb_env.last_import_ahb_stype, 1000129003u);
  // VK_STRUCTURE_TYPE_EXTERNAL_FORMAT_ANDROID = 1000129005
  EXPECT_TRUE(vk_ahb_env.last_external_format_chained);
  EXPECT_EQ(vk_ahb_env.last_external_format_stype, 1000129005u);
  EXPECT_EQ(vk_ahb_env.last_external_format_value, kExternalYcbcrFormat);

  FlutterVulkanExternalTexture embedder_tex = {};
  ASSERT_TRUE(vk_tex->PopulateExternalTexture(&embedder_tex));
  EXPECT_EQ(embedder_tex.struct_size, sizeof(FlutterVulkanExternalTexture));
  EXPECT_NE(embedder_tex.image, 0u);
  EXPECT_EQ(embedder_tex.width, kTestTextureWidth);
  EXPECT_EQ(embedder_tex.height, kTestTextureHeight);
  ASSERT_NE(embedder_tex.ycbcr_conversion_info, nullptr);
  EXPECT_EQ(embedder_tex.ycbcr_conversion_info->format, 0u);
  EXPECT_EQ(embedder_tex.ycbcr_conversion_info->external_format,
            kExternalYcbcrFormat);
  // Because `reported_format_features` did not include the linear YCbCr bit,
  // `chroma_filter` must be clamped to `VK_FILTER_NEAREST` (0).
  EXPECT_EQ(embedder_tex.ycbcr_conversion_info->chroma_filter,
            kVkFilterNearest);

  vk_tex.reset();
  EXPECT_EQ(vk_ahb_env.destroy_image_calls, 1u);
  EXPECT_EQ(vk_ahb_env.free_memory_calls, 1u);

  // When the driver reports a defined Vulkan format (e.g.,
  // VK_FORMAT_R8G8B8A8_UNORM = 37) alongside a non-zero externalFormat (as on
  // Mali GPUs), VkExternalFormatANDROID must NOT be chained per
  // VUID-VkImageCreateInfo-pNext-02396.
  vk_ahb_env.reported_vk_format =
      static_cast<uint32_t>(AndroidVulkanFormat::kR8G8B8A8Unorm);
  vk_ahb_env.reported_external_format = kExternalYcbcrFormat;
  auto rgba_tex = provider->CreateFromAHardwareBuffer(ahb.get());
  ASSERT_NE(rgba_tex, nullptr);
  EXPECT_TRUE(rgba_tex->IsValid());
  EXPECT_FALSE(rgba_tex->HasYcbcrConversion());
  EXPECT_FALSE(vk_ahb_env.last_external_format_chained);
  EXPECT_EQ(vk_ahb_env.last_import_ahb_stype, 1000129003u);
  rgba_tex.reset();

  g_vk_ahb_env = nullptr;
}

TEST(AndroidExternalTextureTest,
     SurfaceTextureGlToAhbBlitterBakesUvTransformIntoAhbForVulkanImport) {
  auto ahb_provider = std::make_shared<InMemoryAndroidHardwareBufferProvider>();
  auto vk_provider = std::make_shared<InMemoryAndroidVulkanTextureProvider>();
  SurfaceTextureGlToAhbBlitter blitter(ahb_provider, vk_provider);

  // Vertical flip matrix: (u, v) -> (u, 1 - v).
  const std::array<float, 16> vertical_flip_matrix = {
      1.0f, 0.0f,  0.0f, 0.0f,  // col 0
      0.0f, -1.0f, 0.0f, 0.0f,  // col 1
      0.0f, 0.0f,  1.0f, 0.0f,  // col 2
      0.0f, 1.0f,  0.0f, 1.0f,  // col 3
  };

  float out_u = 0.0f;
  float out_v = 0.0f;
  TransformSurfaceTextureUv(vertical_flip_matrix.data(), 0.25f, 0.0f, &out_u,
                            &out_v);
  EXPECT_FLOAT_EQ(out_u, 0.25f);
  EXPECT_FLOAT_EQ(out_v, 1.0f);

  auto vk_tex =
      blitter.BlitAndImport(kTestTextureId, kGlTextureName, kTestTextureWidth,
                            kTestTextureHeight, vertical_flip_matrix.data());
  ASSERT_NE(vk_tex, nullptr);
  EXPECT_TRUE(vk_tex->IsValid());

  auto baked_uv = blitter.GetLastBakedUvTransform(kTestTextureId);
  ASSERT_TRUE(baked_uv.has_value());
  for (size_t i = 0; i < vertical_flip_matrix.size(); ++i) {
    EXPECT_FLOAT_EQ((*baked_uv)[i], vertical_flip_matrix[i]);
  }

  const AndroidHardwareBuffer* cached_ahb =
      blitter.GetCachedHardwareBuffer(kTestTextureId);
  ASSERT_NE(cached_ahb, nullptr);
  EXPECT_EQ(cached_ahb->GetDescription().width, kTestTextureWidth);
  EXPECT_EQ(cached_ahb->GetDescription().height, kTestTextureHeight);

  FlutterVulkanExternalTexture embedder_tex = {};
  EXPECT_TRUE(vk_tex->PopulateExternalTexture(&embedder_tex));
  EXPECT_NE(embedder_tex.image, 0u);
  EXPECT_EQ(embedder_tex.width, kTestTextureWidth);
  EXPECT_EQ(embedder_tex.height, kTestTextureHeight);
  EXPECT_EQ(embedder_tex.ycbcr_conversion_info, nullptr);

  // Also verify YCbCr conversion filter remains VK_FILTER_LINEAR when
  // format_features == 0 (unconstrained) or includes LINEAR_BIT.
  AndroidVulkanYcbcrConversionDesc linear_ycbcr;
  linear_ycbcr.chroma_filter =
      static_cast<uint32_t>(AndroidVulkanFilter::kLinear);
  linear_ycbcr.format_features = 0;
  FlutterVulkanYcbcrConversionInfo info =
      linear_ycbcr.ToFlutterYcbcrConversionInfo();
  EXPECT_EQ(info.chroma_filter, kVkFilterLinear);

  blitter.ReleaseTexture(kTestTextureId);
  EXPECT_EQ(blitter.GetCachedHardwareBuffer(kTestTextureId), nullptr);
}

}  // namespace testing
}  // namespace android
}  // namespace flutter
