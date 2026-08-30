// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <future>
#include <thread>
#include <vector>

#include "flutter/shell/platform/android/android_hardware_buffer.h"
#include "flutter/shell/platform/android/os_library_loader.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"

namespace flutter {
namespace android {
namespace testing {

using ::testing::_;
using ::testing::Return;

namespace {

// Mock C-API symbol targets for libandroid.so dynamic resolution test
static void* g_mock_ahb_handle = reinterpret_cast<void*>(0xBAADF00D);
static uint64_t g_mock_ahb_id = 42ULL;
static bool g_mock_allocate_called = false;
static bool g_mock_release_called = false;
static bool g_mock_acquire_called = false;
static bool g_mock_describe_called = false;
static bool g_mock_lock_called = false;
static bool g_mock_unlock_called = false;

int Mock_AHardwareBuffer_allocate(const void* desc, void** outBuffer) {
  g_mock_allocate_called = true;
  *outBuffer = g_mock_ahb_handle;
  return 0;
}

void Mock_AHardwareBuffer_acquire(void* buffer) {
  g_mock_acquire_called = true;
}

void Mock_AHardwareBuffer_release(void* buffer) {
  g_mock_release_called = true;
}

void Mock_AHardwareBuffer_describe(const void* buffer, void* outDesc) {
  g_mock_describe_called = true;
  auto* desc = static_cast<AndroidHardwareBufferDesc*>(outDesc);
  desc->width = 1920;
  desc->height = 1080;
  desc->layers = 1;
  desc->format = 1;
  desc->usage = AndroidHardwareBufferUsage::kGpuSampledImage;
  desc->stride = 1920;
}

int Mock_AHardwareBuffer_getId(const void* buffer, uint64_t* outId) {
  *outId = g_mock_ahb_id;
  return 0;
}

static uint8_t g_dummy_pixel_memory[4096];

int Mock_AHardwareBuffer_lock(void* buffer,
                              uint64_t usage,
                              int32_t fence,
                              const void* rect,
                              void** outVirtualAddress) {
  g_mock_lock_called = true;
  *outVirtualAddress = g_dummy_pixel_memory;
  return 0;
}

int Mock_AHardwareBuffer_unlock(void* buffer, int32_t* fence) {
  g_mock_unlock_called = true;
  if (fence) {
    *fence = -1;
  }
  return 0;
}

int Mock_AHardwareBuffer_isSupported(const void* desc) {
  return 1;
}

void* Mock_AHardwareBuffer_fromHardwareBuffer(void* env,
                                              void* hardwareBufferObj) {
  return g_mock_ahb_handle;
}

void* Mock_AHardwareBuffer_toHardwareBuffer(void* env, void* hardwareBuffer) {
  return hardwareBuffer;
}

}  // namespace

TEST(AndroidHardwareBufferTest, FormatAndBytesPerPixel) {
  EXPECT_EQ(AndroidHardwareBufferBytesPerPixel(static_cast<uint32_t>(
                AndroidHardwareBufferFormat::kR8G8B8A8Unorm)),
            4u);
  EXPECT_EQ(AndroidHardwareBufferBytesPerPixel(static_cast<uint32_t>(
                AndroidHardwareBufferFormat::kR8G8B8X8Unorm)),
            4u);
  EXPECT_EQ(AndroidHardwareBufferBytesPerPixel(static_cast<uint32_t>(
                AndroidHardwareBufferFormat::kR8G8B8Unorm)),
            3u);
  EXPECT_EQ(AndroidHardwareBufferBytesPerPixel(static_cast<uint32_t>(
                AndroidHardwareBufferFormat::kR5G6B5Unorm)),
            2u);
  EXPECT_EQ(AndroidHardwareBufferBytesPerPixel(static_cast<uint32_t>(
                AndroidHardwareBufferFormat::kR16G16B16A16Float)),
            8u);
  EXPECT_EQ(AndroidHardwareBufferBytesPerPixel(static_cast<uint32_t>(
                AndroidHardwareBufferFormat::kR10G10B10A2Unorm)),
            4u);
  EXPECT_EQ(AndroidHardwareBufferBytesPerPixel(
                static_cast<uint32_t>(AndroidHardwareBufferFormat::kBlob)),
            1u);
  EXPECT_EQ(AndroidHardwareBufferBytesPerPixel(
                static_cast<uint32_t>(AndroidHardwareBufferFormat::kD16Unorm)),
            2u);
  EXPECT_EQ(AndroidHardwareBufferBytesPerPixel(
                static_cast<uint32_t>(AndroidHardwareBufferFormat::kR8Unorm)),
            1u);
  EXPECT_EQ(AndroidHardwareBufferBytesPerPixel(
                static_cast<uint32_t>(AndroidHardwareBufferFormat::kR16Uint)),
            2u);
  EXPECT_EQ(AndroidHardwareBufferBytesPerPixel(static_cast<uint32_t>(
                AndroidHardwareBufferFormat::kR16G16Uint)),
            4u);
}

TEST(AndroidHardwareBufferTest, DescriptorCreationAndEquality) {
  auto desc1 = AndroidHardwareBufferDesc::MakeRGBA8(800, 600);
  EXPECT_TRUE(desc1.IsValid());
  EXPECT_EQ(desc1.width, 800u);
  EXPECT_EQ(desc1.height, 600u);
  EXPECT_EQ(desc1.layers, 1u);
  EXPECT_EQ(desc1.format,
            static_cast<uint32_t>(AndroidHardwareBufferFormat::kR8G8B8A8Unorm));
  EXPECT_EQ(desc1.stride, 800u);

  auto desc2 = AndroidHardwareBufferDesc::MakeRGBA8(800, 600);
  EXPECT_EQ(desc1, desc2);
  EXPECT_FALSE(desc1 != desc2);

  auto desc3 = AndroidHardwareBufferDesc::MakeRGBA8(1024, 768);
  EXPECT_NE(desc1, desc3);

  AndroidHardwareBufferDesc invalid_desc;
  EXPECT_FALSE(invalid_desc.IsValid());
}

TEST(AndroidHardwareBufferTest, RectEquality) {
  AndroidHardwareBufferRect r1{0, 0, 100, 100};
  AndroidHardwareBufferRect r2{0, 0, 100, 100};
  AndroidHardwareBufferRect r3{10, 10, 100, 100};

  EXPECT_EQ(r1, r2);
  EXPECT_NE(r1, r3);
}

TEST(AndroidHardwareBufferTest, InMemoryProviderAllocationAndLifecycle) {
  auto provider = std::make_shared<InMemoryAndroidHardwareBufferProvider>();
  EXPECT_TRUE(provider->IsAvailable());

  auto desc = AndroidHardwareBufferDesc::MakeRGBA8(640, 480);
  EXPECT_TRUE(provider->IsSupported(desc));

  auto buffer = provider->Allocate(desc);
  ASSERT_NE(buffer, nullptr);
  EXPECT_TRUE(buffer->IsValid());
  EXPECT_EQ(buffer->GetDescription().width, 640u);
  EXPECT_EQ(buffer->GetDescription().height, 480u);
  EXPECT_NE(buffer->GetHandle(), nullptr);
  EXPECT_GT(buffer->GetId(), 0u);

  EXPECT_EQ(provider->GetAllocationCount(), 1u);
  EXPECT_EQ(provider->GetActiveBufferCount(), 1u);

  // Convert to FlutterHardwareBufferExternalTexture
  void* test_user_data = reinterpret_cast<void*>(0x1234);
  auto ext_texture = buffer->ToExternalTexture(test_user_data);
  EXPECT_EQ(ext_texture.struct_size,
            sizeof(FlutterHardwareBufferExternalTexture));
  EXPECT_EQ(ext_texture.width, 640u);
  EXPECT_EQ(ext_texture.height, 480u);
  EXPECT_EQ(ext_texture.format, desc.format);
  EXPECT_EQ(ext_texture.buffer, buffer->ToHandle());
  EXPECT_EQ(ext_texture.user_data, test_user_data);

  // Lock and write memory
  void* mapped_address = nullptr;
  int lock_res = buffer->Lock(AndroidHardwareBufferUsage::kCpuWriteOften, -1,
                              nullptr, &mapped_address);
  EXPECT_EQ(lock_res, 0);
  ASSERT_NE(mapped_address, nullptr);

  // Write byte pattern
  uint8_t* byte_ptr = static_cast<uint8_t*>(mapped_address);
  byte_ptr[0] = 0xAA;
  byte_ptr[1] = 0xBB;
  byte_ptr[2] = 0xCC;
  byte_ptr[3] = 0xFF;

  int unlock_res = buffer->Unlock();
  EXPECT_EQ(unlock_res, 0);

  // Lock again to verify persistent contents
  void* read_address = nullptr;
  lock_res = buffer->Lock(AndroidHardwareBufferUsage::kCpuReadOften, -1,
                          nullptr, &read_address);
  EXPECT_EQ(lock_res, 0);
  uint8_t* read_ptr = static_cast<uint8_t*>(read_address);
  EXPECT_EQ(read_ptr[0], 0xAA);
  EXPECT_EQ(read_ptr[1], 0xBB);
  EXPECT_EQ(read_ptr[2], 0xCC);
  EXPECT_EQ(read_ptr[3], 0xFF);
  buffer->Unlock();

  // Test acquire/release
  buffer->Acquire();
  buffer->Release();

  // Destroy buffer and verify release
  void* handle = buffer->GetHandle();
  EXPECT_NE(handle, nullptr);
  buffer.reset();

  EXPECT_EQ(provider->GetReleaseCount(), 1u);
  EXPECT_EQ(provider->GetActiveBufferCount(), 0u);
}

TEST(AndroidHardwareBufferTest, InMemoryProviderErrorAndFailureModes) {
  auto provider = std::make_shared<InMemoryAndroidHardwareBufferProvider>();

  // Allocation failure injection
  provider->SetAllocationFailure(true);
  auto desc = AndroidHardwareBufferDesc::MakeRGBA8(100, 100);
  EXPECT_FALSE(provider->IsSupported(desc));
  EXPECT_EQ(provider->Allocate(desc), nullptr);

  provider->SetAllocationFailure(false);
  EXPECT_TRUE(provider->IsSupported(desc));

  // Provider disabled / unavailable
  provider->SetAvailable(false);
  EXPECT_FALSE(provider->IsAvailable());
  EXPECT_FALSE(provider->IsSupported(desc));
  EXPECT_EQ(provider->Allocate(desc), nullptr);

  provider->SetAvailable(true);

  // Invalid descriptor
  AndroidHardwareBufferDesc invalid_desc;
  EXPECT_EQ(provider->Allocate(invalid_desc), nullptr);
}

TEST(AndroidHardwareBufferTest, InMemoryProviderNativeAndJavaInterop) {
  auto provider = std::make_shared<InMemoryAndroidHardwareBufferProvider>();

  void* mock_java_handle = reinterpret_cast<void*>(0xCAFE);
  void* mock_env = reinterpret_cast<void*>(0xFEED);

  auto buffer =
      provider->CreateFromJavaHardwareBuffer(mock_env, mock_java_handle);
  ASSERT_NE(buffer, nullptr);
  EXPECT_TRUE(buffer->IsValid());
  EXPECT_GT(buffer->GetId(), 0u);
  EXPECT_EQ(buffer->GetHandle(), mock_java_handle);

  AndroidHardwareBufferDesc desc_out = {};
  EXPECT_TRUE(provider->Describe(mock_java_handle, &desc_out));
  EXPECT_GT(desc_out.width, 0u);
  EXPECT_GT(desc_out.height, 0u);

  EXPECT_EQ(provider->GetId(mock_java_handle), buffer->GetId());

  // Test ToJavaHardwareBuffer
  EXPECT_EQ(provider->ToJavaHardwareBuffer(mock_env, mock_java_handle),
            mock_java_handle);
  EXPECT_EQ(provider->ToJavaHardwareBuffer(nullptr, mock_java_handle), nullptr);

  // Test native handle lifecycle and cleanup
  EXPECT_EQ(provider->GetActiveBufferCount(), 1u);
  buffer.reset();
  // Since take_ownership was false in CreateFromJavaHardwareBuffer, mock entry
  // remains
  EXPECT_EQ(provider->GetActiveBufferCount(), 1u);
  provider->Release(mock_java_handle);
  EXPECT_EQ(provider->GetActiveBufferCount(), 0u);
}

TEST(AndroidHardwareBufferTest, DefaultProviderWithMockOSLibrary) {
  auto mock_loader = std::make_shared<MockOSLibraryLoader>();
  auto mock_lib = std::make_shared<MockOSLibrary>("libandroid.so");

  mock_lib->SetSymbol("AHardwareBuffer_allocate",
                      reinterpret_cast<void*>(&Mock_AHardwareBuffer_allocate));
  mock_lib->SetSymbol("AHardwareBuffer_release",
                      reinterpret_cast<void*>(&Mock_AHardwareBuffer_release));
  mock_lib->SetSymbol("AHardwareBuffer_describe",
                      reinterpret_cast<void*>(&Mock_AHardwareBuffer_describe));
  mock_lib->SetSymbol("AHardwareBuffer_acquire",
                      reinterpret_cast<void*>(&Mock_AHardwareBuffer_acquire));
  mock_lib->SetSymbol("AHardwareBuffer_getId",
                      reinterpret_cast<void*>(&Mock_AHardwareBuffer_getId));
  mock_lib->SetSymbol("AHardwareBuffer_lock",
                      reinterpret_cast<void*>(&Mock_AHardwareBuffer_lock));
  mock_lib->SetSymbol("AHardwareBuffer_unlock",
                      reinterpret_cast<void*>(&Mock_AHardwareBuffer_unlock));
  mock_lib->SetSymbol(
      "AHardwareBuffer_isSupported",
      reinterpret_cast<void*>(&Mock_AHardwareBuffer_isSupported));
  mock_lib->SetSymbol(
      "AHardwareBuffer_fromHardwareBuffer",
      reinterpret_cast<void*>(&Mock_AHardwareBuffer_fromHardwareBuffer));
  mock_lib->SetSymbol(
      "AHardwareBuffer_toHardwareBuffer",
      reinterpret_cast<void*>(&Mock_AHardwareBuffer_toHardwareBuffer));

  mock_loader->RegisterLibrary("libandroid.so", mock_lib);

  g_mock_allocate_called = false;
  g_mock_release_called = false;
  g_mock_acquire_called = false;
  g_mock_describe_called = false;
  g_mock_lock_called = false;
  g_mock_unlock_called = false;

  auto provider =
      std::make_shared<DefaultAndroidHardwareBufferProvider>(mock_loader);
  EXPECT_TRUE(provider->IsAvailable());

  auto desc = AndroidHardwareBufferDesc::MakeRGBA8(1920, 1080);
  EXPECT_TRUE(provider->IsSupported(desc));

  auto buffer = provider->Allocate(desc);
  ASSERT_NE(buffer, nullptr);
  EXPECT_TRUE(g_mock_allocate_called);
  EXPECT_TRUE(g_mock_describe_called);
  EXPECT_EQ(buffer->GetHandle(), g_mock_ahb_handle);
  EXPECT_EQ(buffer->GetId(), g_mock_ahb_id);

  void* mock_env = reinterpret_cast<void*>(0x1111);
  EXPECT_EQ(provider->ToJavaHardwareBuffer(mock_env, g_mock_ahb_handle),
            g_mock_ahb_handle);

  // Test lock/unlock
  void* addr = nullptr;
  EXPECT_EQ(buffer->Lock(AndroidHardwareBufferUsage::kCpuWriteOften, -1,
                         nullptr, &addr),
            0);
  EXPECT_TRUE(g_mock_lock_called);
  EXPECT_EQ(addr, g_dummy_pixel_memory);

  EXPECT_EQ(buffer->Unlock(), 0);
  EXPECT_TRUE(g_mock_unlock_called);

  // Test acquire
  buffer->Acquire();
  EXPECT_TRUE(g_mock_acquire_called);

  // Test release upon destruction
  buffer.reset();
  EXPECT_TRUE(g_mock_release_called);
}

TEST(AndroidHardwareBufferTest,
     DefaultProviderMissingLibraryGracefulDegradation) {
  auto mock_loader = std::make_shared<MockOSLibraryLoader>();
  // Don't register libandroid.so

  auto provider =
      std::make_shared<DefaultAndroidHardwareBufferProvider>(mock_loader);
  EXPECT_FALSE(provider->IsAvailable());

  auto desc = AndroidHardwareBufferDesc::MakeRGBA8(800, 600);
  EXPECT_FALSE(provider->IsSupported(desc));
  EXPECT_EQ(provider->Allocate(desc), nullptr);
  EXPECT_EQ(provider->CreateFromNativeHandle(reinterpret_cast<void*>(0x1234)),
            nullptr);
}

TEST(AndroidHardwareBufferTest, MultithreadedConcurrentBufferOperations) {
  auto provider = std::make_shared<InMemoryAndroidHardwareBufferProvider>();
  constexpr size_t kThreadCount = 8;
  constexpr size_t kIterations = 50;

  std::vector<std::future<void>> futures;
  futures.reserve(kThreadCount);
  for (size_t t = 0; t < kThreadCount; ++t) {
    futures.push_back(std::async(std::launch::async, [&provider, t]() {
      for (size_t i = 0; i < kIterations; ++i) {
        auto desc =
            AndroidHardwareBufferDesc::MakeRGBA8(100 + (t * 10), 100 + (i * 2));
        auto buffer = provider->Allocate(desc);
        ASSERT_NE(buffer, nullptr);

        void* addr = nullptr;
        EXPECT_EQ(buffer->Lock(AndroidHardwareBufferUsage::kCpuWriteOften, -1,
                               nullptr, &addr),
                  0);
        ASSERT_NE(addr, nullptr);
        static_cast<uint8_t*>(addr)[0] = static_cast<uint8_t>(t + i);
        EXPECT_EQ(buffer->Unlock(), 0);

        auto ext_tex = buffer->ToExternalTexture();
        EXPECT_EQ(ext_tex.width, desc.width);
        EXPECT_EQ(ext_tex.height, desc.height);
      }
    }));
  }

  for (auto& f : futures) {
    f.get();
  }

  EXPECT_EQ(provider->GetAllocationCount(), kThreadCount * kIterations);
  EXPECT_EQ(provider->GetReleaseCount(), kThreadCount * kIterations);
  EXPECT_EQ(provider->GetActiveBufferCount(), 0u);
}

}  // namespace testing
}  // namespace android
}  // namespace flutter
