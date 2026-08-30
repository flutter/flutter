// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <future>
#include <thread>
#include <vector>

#include "flutter/shell/platform/android/flutter_embedder_native.h"
#include "flutter/shell/platform/android/jni_delegate.h"
#include "flutter/shell/platform/android/jni_router.h"
#include "flutter/shell/platform/android/jvm_invoker.h"
#include "flutter/shell/platform/android/os_library_loader.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"

namespace flutter {
namespace android {
namespace testing {

using ::testing::_;
using ::testing::DoAll;
using ::testing::Eq;
using ::testing::Return;
using ::testing::SetArgPointee;
using ::testing::StrictMock;

class MockJvmInvoker : public JvmInvoker {
 public:
  MOCK_METHOD(bool, EnsureAttachedToThread, (), (override));
  MOCK_METHOD(void, DetachFromThread, (), (override));
  MOCK_METHOD(bool, HasPendingException, (), (const, override));
  MOCK_METHOD(void, ClearPendingException, (), (override));

  MOCK_METHOD(bool,
              HandlePlatformMessage,
              (const std::string& channel,
               const uint8_t* message,
               size_t message_size,
               int32_t response_id,
               int64_t message_data),
              (override));

  MOCK_METHOD(bool,
              HandlePlatformMessageResponse,
              (int32_t response_id, const uint8_t* data, size_t data_size),
              (override));

  MOCK_METHOD(bool,
              UpdateSemantics,
              (const std::vector<uint8_t>& buffer,
               const std::vector<std::string>& strings,
               const std::vector<std::vector<uint8_t>>& string_attribute_args),
              (override));

  MOCK_METHOD(bool, SetSemanticsTreeEnabled, (bool enabled), (override));
  MOCK_METHOD(bool,
              SetApplicationLocale,
              (const std::string& locale),
              (override));
  MOCK_METHOD(bool, OnFirstFrame, (), (override));
  MOCK_METHOD(bool, OnPreEngineRestart, (), (override));
  MOCK_METHOD(bool,
              RequestDartDeferredLibrary,
              (int loading_unit_id),
              (override));

  MOCK_METHOD(bool,
              InvokeVoidMethod,
              (const std::string& method_name,
               const std::string& signature,
               const std::vector<uint8_t>& payload),
              (override));

  MOCK_METHOD(bool,
              InvokeBooleanMethod,
              (const std::string& method_name,
               const std::string& signature,
               const std::vector<uint8_t>& payload),
              (override));

  MOCK_METHOD(int64_t,
              InvokeIntMethod,
              (const std::string& method_name,
               const std::string& signature,
               const std::vector<uint8_t>& payload),
              (override));

  MOCK_METHOD(double,
              InvokeDoubleMethod,
              (const std::string& method_name,
               const std::string& signature,
               const std::vector<uint8_t>& payload),
              (override));

  MOCK_METHOD(std::string,
              InvokeStringMethod,
              (const std::string& method_name,
               const std::string& signature,
               const std::vector<uint8_t>& payload),
              (override));

  MOCK_METHOD(std::vector<uint8_t>,
              InvokeBytesMethod,
              (const std::string& method_name,
               const std::string& signature,
               const std::vector<uint8_t>& payload),
              (override));

  MOCK_METHOD(bool, PostJvmTask, (std::function<void()> task), (override));
};

class MockLegacyJniDelegate : public LegacyJniDelegate {
 public:
  MOCK_METHOD(bool,
              HandlePlatformMessage,
              (const std::string& channel,
               const uint8_t* message,
               size_t message_size,
               int32_t response_id,
               int64_t message_data),
              (override));

  MOCK_METHOD(bool,
              HandlePlatformMessageResponse,
              (int32_t response_id, const uint8_t* data, size_t data_size),
              (override));

  MOCK_METHOD(bool,
              UpdateSemantics,
              (const std::vector<uint8_t>& buffer,
               const std::vector<std::string>& strings,
               const std::vector<std::vector<uint8_t>>& string_attribute_args),
              (override));

  MOCK_METHOD(bool, SetSemanticsTreeEnabled, (bool enabled), (override));

  MOCK_METHOD(bool,
              SetApplicationLocale,
              (const std::string& locale),
              (override));

  MOCK_METHOD(bool, OnFirstFrame, (), (override));

  MOCK_METHOD(bool, OnPreEngineRestart, (), (override));

  MOCK_METHOD(bool,
              RequestDartDeferredLibrary,
              (int loading_unit_id),
              (override));
};

// =============================================================================
// Embedder Native Core Tests
// =============================================================================

TEST(FlutterEmbedderNativeTest, QuarantineEnforcement) {
  EXPECT_TRUE(FlutterEmbedderNative::IsQuarantineEnforced());
}

TEST(FlutterEmbedderNativeTest, VersionVerification) {
  EXPECT_TRUE(FlutterEmbedderNative::VerifyEmbedderVersion());
  EXPECT_EQ(FlutterEmbedderNative::GetEmbedderVersion(),
            static_cast<size_t>(FLUTTER_ENGINE_VERSION));
}

TEST(FlutterEmbedderNativeTest, LifecycleInstance) {
  auto native_instance = std::make_unique<FlutterEmbedderNative>();
  EXPECT_NE(native_instance, nullptr);
  EXPECT_NE(native_instance->GetRouter(), nullptr);
  EXPECT_NE(native_instance->GetJniDelegate(), nullptr);
  EXPECT_NE(native_instance->GetJvmInvoker(), nullptr);
  EXPECT_NE(native_instance->GetLibraryLoader(), nullptr);
}

TEST(FlutterEmbedderNativeTest, DefaultJvmInvokerOperations) {
  auto invoker = std::make_shared<DefaultJvmInvoker>();
  EXPECT_TRUE(invoker->EnsureAttachedToThread());
  EXPECT_FALSE(invoker->HasPendingException());

  std::vector<uint8_t> payload = {1, 2, 3};
  EXPECT_TRUE(invoker->InvokeVoidMethod("testVoid", "()V", payload));
  EXPECT_TRUE(invoker->InvokeBooleanMethod("testBool", "()Z"));
  EXPECT_EQ(invoker->InvokeIntMethod("testInt", "()I"), 0);
  EXPECT_DOUBLE_EQ(invoker->InvokeDoubleMethod("testDouble", "()D"), 0.0);
  EXPECT_EQ(invoker->InvokeStringMethod("testString", "()Ljava/lang/String;"),
            "");
  EXPECT_TRUE(invoker->InvokeBytesMethod("testBytes", "()[B").empty());

  // PostJvmTask fails safely when no task runner is configured.
  bool task_executed = false;
  EXPECT_FALSE(
      invoker->PostJvmTask([&task_executed]() { task_executed = true; }));
  EXPECT_FALSE(task_executed);

  invoker->DetachFromThread();
}

TEST(FlutterEmbedderNativeTest, JniDelegateWithMockInvoker) {
  auto mock_invoker = std::make_shared<MockJvmInvoker>();
  auto delegate = std::make_unique<JniDelegate>(mock_invoker);

  EXPECT_EQ(delegate->GetJvmInvoker(), mock_invoker);

  // 1. HandlePlatformMessage (preserves all typed parameters)
  std::vector<uint8_t> msg = {'h', 'e', 'l', 'l', 'o'};
  EXPECT_CALL(*mock_invoker, HandlePlatformMessage("flutter/test", msg.data(),
                                                   msg.size(), 42, 1001L))
      .WillOnce(Return(true));
  EXPECT_TRUE(delegate->HandlePlatformMessage("flutter/test", msg, 42, 1001L));

  // 2. HandlePlatformMessageResponse
  std::vector<uint8_t> resp = {'o', 'k'};
  EXPECT_CALL(*mock_invoker,
              HandlePlatformMessageResponse(42, resp.data(), resp.size()))
      .WillOnce(Return(true));
  EXPECT_TRUE(delegate->HandlePlatformMessageResponse(42, resp));

  // 3. UpdateSemantics
  std::vector<uint8_t> semantics_buffer = {0x01, 0x02};
  std::vector<std::string> semantics_strings = {"label1", "label2"};
  std::vector<std::vector<uint8_t>> string_attributes = {{0xAA}};
  EXPECT_CALL(
      *mock_invoker,
      UpdateSemantics(semantics_buffer, semantics_strings, string_attributes))
      .WillOnce(Return(true));
  EXPECT_TRUE(delegate->UpdateSemantics(semantics_buffer, semantics_strings,
                                        string_attributes));

  // 4. SetSemanticsTreeEnabled
  EXPECT_CALL(*mock_invoker, SetSemanticsTreeEnabled(true))
      .WillOnce(Return(true));
  EXPECT_TRUE(delegate->SetSemanticsTreeEnabled(true));

  // 5. SetApplicationLocale
  std::string locale = "en_US";
  EXPECT_CALL(*mock_invoker, SetApplicationLocale(locale))
      .WillOnce(Return(true));
  EXPECT_TRUE(delegate->SetApplicationLocale(locale));

  // 6. OnFirstFrame
  EXPECT_CALL(*mock_invoker, OnFirstFrame()).WillOnce(Return(true));
  EXPECT_TRUE(delegate->OnFirstFrame());

  // 7. OnPreEngineRestart
  EXPECT_CALL(*mock_invoker, OnPreEngineRestart()).WillOnce(Return(true));
  EXPECT_TRUE(delegate->OnPreEngineRestart());

  // 8. RequestDartDeferredLibrary
  EXPECT_CALL(*mock_invoker, RequestDartDeferredLibrary(101))
      .WillOnce(Return(true));
  EXPECT_TRUE(delegate->RequestDartDeferredLibrary(101));
}

TEST(FlutterEmbedderNativeTest, JniRouterRoutingFlip) {
  auto mock_invoker = std::make_shared<MockJvmInvoker>();
  auto embedder_delegate = std::make_shared<JniDelegate>(mock_invoker);
  auto legacy_delegate = std::make_shared<MockLegacyJniDelegate>();

  auto router = std::make_unique<JniRouter>(embedder_delegate, legacy_delegate);

  // Initial state: Embedder disabled globally -> routes to Legacy
  JniRouter::SetGlobalEmbedderEnabled(false);
  EXPECT_FALSE(JniRouter::IsEmbedderEnabled());
  EXPECT_EQ(router->GetActiveRoutingPath(), JniRouter::RoutingPath::kLegacy);

  std::vector<uint8_t> payload = {'t', 'e', 's', 't'};

  // Expect legacy delegate call, mock_invoker should not be called
  EXPECT_CALL(*legacy_delegate,
              HandlePlatformMessage("flutter/lifecycle", payload.data(),
                                    payload.size(), 1, 0))
      .WillOnce(Return(true));
  EXPECT_CALL(*mock_invoker, HandlePlatformMessage(_, _, _, _, _)).Times(0);

  EXPECT_TRUE(router->RoutePlatformMessage("flutter/lifecycle", payload, 1));

  // Legacy OnFirstFrame
  EXPECT_CALL(*legacy_delegate, OnFirstFrame()).WillOnce(Return(true));
  EXPECT_TRUE(router->RouteFirstFrame());

  // Legacy Deferred Library
  EXPECT_CALL(*legacy_delegate, RequestDartDeferredLibrary(5))
      .WillOnce(Return(true));
  EXPECT_TRUE(router->RouteRequestDartDeferredLibrary(5));

  // Flip global flag to true -> routes to Embedder
  JniRouter::SetGlobalEmbedderEnabled(true);
  EXPECT_TRUE(JniRouter::IsEmbedderEnabled());
  EXPECT_EQ(router->GetActiveRoutingPath(), JniRouter::RoutingPath::kEmbedder);

  // Expect mock_invoker call via embedder delegate, legacy should not be called
  EXPECT_CALL(*legacy_delegate, HandlePlatformMessage(_, _, _, _, _)).Times(0);
  EXPECT_CALL(*mock_invoker,
              HandlePlatformMessage("flutter/lifecycle", payload.data(),
                                    payload.size(), 1, 0))
      .WillOnce(Return(true));

  EXPECT_TRUE(router->RoutePlatformMessage("flutter/lifecycle", payload, 1));

  // Embedder OnFirstFrame
  EXPECT_CALL(*mock_invoker, OnFirstFrame()).WillOnce(Return(true));
  EXPECT_TRUE(router->RouteFirstFrame());

  // Embedder Deferred Library
  EXPECT_CALL(*mock_invoker, RequestDartDeferredLibrary(5))
      .WillOnce(Return(true));
  EXPECT_TRUE(router->RouteRequestDartDeferredLibrary(5));

  // Instance override: override global true with instance false
  router->SetInstanceEmbedderEnabled(false);
  EXPECT_FALSE(router->IsInstanceEmbedderEnabled());
  EXPECT_EQ(router->GetActiveRoutingPath(), JniRouter::RoutingPath::kLegacy);

  EXPECT_CALL(*legacy_delegate, OnFirstFrame()).WillOnce(Return(true));
  EXPECT_TRUE(router->RouteFirstFrame());

  // Reset instance override
  router->SetInstanceEmbedderEnabled(std::nullopt);
  EXPECT_TRUE(router->IsInstanceEmbedderEnabled());

  // Reset global flag back to false for test hygiene
  JniRouter::SetGlobalEmbedderEnabled(false);
  EXPECT_FALSE(JniRouter::IsEmbedderEnabled());
}

TEST(FlutterEmbedderNativeTest, DynamicInstanceRouterWithCustomInvoker) {
  auto mock_invoker = std::make_shared<MockJvmInvoker>();
  auto legacy_delegate = std::make_shared<MockLegacyJniDelegate>();

  FlutterEmbedderNative native(mock_invoker, legacy_delegate);
  EXPECT_EQ(native.GetJvmInvoker(), mock_invoker);
  EXPECT_NE(native.GetJniDelegate(), nullptr);
  EXPECT_NE(native.GetRouter(), nullptr);

  FlutterEmbedderNative::SetEmbedderEnabled(true);
  EXPECT_TRUE(FlutterEmbedderNative::IsEmbedderEnabled());

  EXPECT_CALL(*mock_invoker, OnFirstFrame()).WillOnce(Return(true));
  EXPECT_TRUE(native.GetRouter()->RouteFirstFrame());

  FlutterEmbedderNative::SetEmbedderEnabled(false);
}

TEST(FlutterEmbedderNativeTest, NativeWindowManagement) {
  auto native_instance = std::make_unique<FlutterEmbedderNative>();
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  EXPECT_EQ(native_instance->GetNativeWindow(), nullptr);
#pragma clang diagnostic pop
  EXPECT_EQ(native_instance->AcquireNativeWindow(), nullptr);

  // PresentSoftware should fail cleanly when no window is attached.
  uint32_t dummy_pixels[16] = {0};
  EXPECT_FALSE(native_instance->PresentSoftware(dummy_pixels, 16, 4));

  // PresentSoftware should fail cleanly with invalid arguments.
  EXPECT_FALSE(native_instance->PresentSoftware(nullptr, 16, 4));
  EXPECT_FALSE(native_instance->PresentSoftware(dummy_pixels, 0, 4));
  EXPECT_FALSE(native_instance->PresentSoftware(dummy_pixels, 16, 0));
}

TEST(FlutterEmbedderNativeTest, BlitSoftwareRasterRgba8888Exact) {
  // 2x2 source pixels: Red, Green, Blue, White.
  const uint32_t src[4] = {
      0xFF0000FF,  // Red
      0xFF00FF00,  // Green
      0xFFFF0000,  // Blue
      0xFFFFFFFF,  // White
  };

  uint32_t dst[4] = {0};
  FlutterEmbedderNative::SoftwareBuffer dst_buffer;
  dst_buffer.bits = dst;
  dst_buffer.width = 2;
  dst_buffer.height = 2;
  dst_buffer.stride = 2;
  dst_buffer.format = FlutterEmbedderNative::kFormatRgba8888;

  EXPECT_TRUE(
      FlutterEmbedderNative::BlitSoftwareRaster(src, 2 * 4, 2, dst_buffer));
  EXPECT_EQ(dst[0], 0xFF0000FF);
  EXPECT_EQ(dst[1], 0xFF00FF00);
  EXPECT_EQ(dst[2], 0xFFFF0000);
  EXPECT_EQ(dst[3], 0xFFFFFFFF);
}

TEST(FlutterEmbedderNativeTest, BlitSoftwareRasterRgba8888StrideAndMargins) {
  // 2x2 source in a 4x3 destination buffer (stride = 4).
  const uint32_t src[4] = {
      0xFF111111,
      0xFF222222,
      0xFF333333,
      0xFF444444,
  };

  // Pre-fill destination with junk bytes to verify zeroing of margins.
  std::vector<uint32_t> dst(4 * 3, 0xAAAAAAAA);
  FlutterEmbedderNative::SoftwareBuffer dst_buffer;
  dst_buffer.bits = dst.data();
  dst_buffer.width = 4;
  dst_buffer.height = 3;
  dst_buffer.stride = 4;
  dst_buffer.format = FlutterEmbedderNative::kFormatRgba8888;

  EXPECT_TRUE(
      FlutterEmbedderNative::BlitSoftwareRaster(src, 2 * 4, 2, dst_buffer));

  // Row 0: 2 copied pixels, 2 zeroed margins
  EXPECT_EQ(dst[0], 0xFF111111);
  EXPECT_EQ(dst[1], 0xFF222222);
  EXPECT_EQ(dst[2], 0u);
  EXPECT_EQ(dst[3], 0u);

  // Row 1: 2 copied pixels, 2 zeroed margins
  EXPECT_EQ(dst[4], 0xFF333333);
  EXPECT_EQ(dst[5], 0xFF444444);
  EXPECT_EQ(dst[6], 0u);
  EXPECT_EQ(dst[7], 0u);

  // Row 2: Bottom extra row zeroed
  EXPECT_EQ(dst[8], 0u);
  EXPECT_EQ(dst[9], 0u);
  EXPECT_EQ(dst[10], 0u);
  EXPECT_EQ(dst[11], 0u);
}

TEST(FlutterEmbedderNativeTest, BlitSoftwareRasterRgb565ClampingAndUnpremul) {
  // Little-endian RGBA memory layout: byte0=R, byte1=G, byte2=B, byte3=A
  // Test case 1: Opaque red (R=255, G=0, B=0, A=255) -> 0xF800
  // Test case 2: Half-alpha red (R=128, G=0, B=0, A=128) -> un-premul R=255 ->
  // 0xF800 Test case 3: Out-of-bounds roundoff: (R=100, G=0, B=0, A=99) ->
  // (100*255)/99 = 257 -> clamped to 255 -> 0xF800 Test case 4: Fully
  // transparent (0, 0, 0, 0) -> 0x0000
  const uint8_t src_bytes[16] = {
      255, 0, 0, 255,  // px0
      128, 0, 0, 128,  // px1
      100, 0, 0, 99,   // px2
      0,   0, 0, 0,    // px3
  };

  uint16_t dst[4] = {0};
  FlutterEmbedderNative::SoftwareBuffer dst_buffer;
  dst_buffer.bits = dst;
  dst_buffer.width = 4;
  dst_buffer.height = 1;
  dst_buffer.stride = 4;
  dst_buffer.format = FlutterEmbedderNative::kFormatRgb565;

  EXPECT_TRUE(FlutterEmbedderNative::BlitSoftwareRaster(src_bytes, 4 * 4, 1,
                                                        dst_buffer));
  EXPECT_EQ(dst[0], 0xF800);
  EXPECT_EQ(dst[1], 0xF800);
  EXPECT_EQ(dst[2], 0xF800);  // Must NOT wrap around to near-zero!
  EXPECT_EQ(dst[3], 0x0000);
}

TEST(FlutterEmbedderNativeTest, BlitSoftwareRasterInvalidArguments) {
  uint32_t dummy[4] = {0};
  FlutterEmbedderNative::SoftwareBuffer valid_buf;
  valid_buf.bits = dummy;
  valid_buf.width = 2;
  valid_buf.height = 2;
  valid_buf.stride = 2;
  valid_buf.format = FlutterEmbedderNative::kFormatRgba8888;

  // Null or zero source
  EXPECT_FALSE(
      FlutterEmbedderNative::BlitSoftwareRaster(nullptr, 8, 2, valid_buf));
  EXPECT_FALSE(
      FlutterEmbedderNative::BlitSoftwareRaster(dummy, 0, 2, valid_buf));
  EXPECT_FALSE(
      FlutterEmbedderNative::BlitSoftwareRaster(dummy, 8, 0, valid_buf));

  // Null or invalid destination
  FlutterEmbedderNative::SoftwareBuffer invalid_buf = valid_buf;
  invalid_buf.bits = nullptr;
  EXPECT_FALSE(
      FlutterEmbedderNative::BlitSoftwareRaster(dummy, 8, 2, invalid_buf));

  // Stride < width underflow check
  invalid_buf = valid_buf;
  invalid_buf.stride = 1;  // less than width 2!
  EXPECT_FALSE(
      FlutterEmbedderNative::BlitSoftwareRaster(dummy, 8, 2, invalid_buf));

  // Invalid format
  invalid_buf = valid_buf;
  invalid_buf.format = 999;
  EXPECT_FALSE(
      FlutterEmbedderNative::BlitSoftwareRaster(dummy, 8, 2, invalid_buf));
}

TEST(FlutterEmbedderNativeTest, NativeWindowSelfAssignmentAndLifecycle) {
  auto native_instance = std::make_unique<FlutterEmbedderNative>();
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  EXPECT_EQ(native_instance->GetNativeWindow(), nullptr);
  EXPECT_EQ(native_instance->AcquireNativeWindow(), nullptr);

  // Self assignment of nullptr
  native_instance->SetNativeWindow(nullptr);
  EXPECT_EQ(native_instance->GetNativeWindow(), nullptr);
  EXPECT_EQ(native_instance->AcquireNativeWindow(), nullptr);

#if !defined(__ANDROID__)
  // On host, test pointer storage, self-assignment, and clearing
  auto fake_win = reinterpret_cast<ANativeWindow*>(0x1234);
  native_instance->SetNativeWindow(fake_win);
  EXPECT_EQ(native_instance->GetNativeWindow(), fake_win);

  // Self assignment must be a no-op and not crash
  native_instance->SetNativeWindow(fake_win);
  EXPECT_EQ(native_instance->GetNativeWindow(), fake_win);

  native_instance->SetNativeWindow(nullptr);
  EXPECT_EQ(native_instance->GetNativeWindow(), nullptr);
#endif
#pragma clang diagnostic pop
}

// =============================================================================
// OSLibraryLoader & Dynamic Virtualization Unit Tests
// =============================================================================

TEST(OSLibraryLoaderTest, DefaultOSLibraryLoaderMissingLibraryFallback) {
  auto loader = std::make_shared<DefaultOSLibraryLoader>();
  EXPECT_NE(loader, nullptr);

  // Attempting to load non-existent library must not crash or segfault.
  auto lib = loader->LoadDynamicLibrary("lib_nonexistent_dummy_android_lib.so");
  EXPECT_EQ(lib, nullptr);

  EXPECT_FALSE(loader->IsLibraryLoaded("lib_nonexistent_dummy_android_lib.so"));

  // Resolving symbol from nonexistent library returns nullptr safely.
  void* sym = loader->ResolveSymbol("lib_nonexistent_dummy_android_lib.so",
                                    "AHardwareBuffer_allocate");
  EXPECT_EQ(sym, nullptr);

  auto fn = loader->ResolveFunction<int (*)(void*)>(
      "lib_nonexistent_dummy_android_lib.so", "AHardwareBuffer_allocate");
  EXPECT_EQ(fn, nullptr);

  // Second call must return nullptr immediately from negative cache.
  EXPECT_EQ(loader->LoadDynamicLibrary("lib_nonexistent_dummy_android_lib.so"),
            nullptr);
  EXPECT_FALSE(loader->IsLibraryLoaded("lib_nonexistent_dummy_android_lib.so"));

  // Null input handles safely
  EXPECT_EQ(loader->LoadDynamicLibrary(nullptr), nullptr);
  EXPECT_EQ(loader->ResolveSymbol(nullptr, "symbol"), nullptr);
  EXPECT_EQ(loader->ResolveSymbol("lib.so", nullptr), nullptr);
  EXPECT_FALSE(loader->IsLibraryLoaded(nullptr));
}

TEST(OSLibraryLoaderTest, MockOSLibrarySymbolInjectionAndResolution) {
  auto mock_lib = std::make_shared<MockOSLibrary>("libandroid.so");
  EXPECT_EQ(mock_lib->GetName(), "libandroid.so");
  EXPECT_TRUE(mock_lib->IsValid());

  // Define dummy mock function
  auto dummy_func = [](int a, int b) -> int { return a + b; };
  using DummyFuncType = int (*)(int, int);

  mock_lib->SetSymbol("AddNumbers", reinterpret_cast<void*>(+dummy_func));

  void* sym = mock_lib->ResolveSymbol("AddNumbers");
  EXPECT_NE(sym, nullptr);

  auto resolved_fn = mock_lib->ResolveFunction<DummyFuncType>("AddNumbers");
  EXPECT_NE(resolved_fn, nullptr);
  EXPECT_EQ(resolved_fn(10, 20), 30);

  // Query missing symbol
  EXPECT_EQ(mock_lib->ResolveSymbol("NonExistentSymbol"), nullptr);

  // Remove symbol
  mock_lib->RemoveSymbol("AddNumbers");
  EXPECT_EQ(mock_lib->ResolveSymbol("AddNumbers"), nullptr);

  // Invalidate library
  mock_lib->SetSymbol("AddNumbers", reinterpret_cast<void*>(+dummy_func));
  mock_lib->SetValid(false);
  EXPECT_FALSE(mock_lib->IsValid());
  EXPECT_EQ(mock_lib->ResolveSymbol("AddNumbers"), nullptr);

  // Clear symbols
  mock_lib->SetValid(true);
  mock_lib->ClearSymbols();
  EXPECT_EQ(mock_lib->ResolveSymbol("AddNumbers"), nullptr);
}

// Simulated mock Android API signatures
namespace mock_android_apis {
static int g_ahb_allocate_count = 0;
static int g_ahb_release_count = 0;
static int g_choreographer_post_count = 0;

static int Mock_AHardwareBuffer_allocate(const void* desc, void** out_buffer) {
  g_ahb_allocate_count++;
  if (out_buffer) {
    *out_buffer = reinterpret_cast<void*>(0xBAADF00D);
  }
  return 0;  // OK
}

static void Mock_AHardwareBuffer_release(void* buffer) {
  g_ahb_release_count++;
}

static void Mock_AChoreographer_postFrameCallback64(void* choreographer,
                                                    void* callback,
                                                    void* data) {
  g_choreographer_post_count++;
}
}  // namespace mock_android_apis

TEST(OSLibraryLoaderTest, MockOSLibraryLoaderAndroidApiSimulation) {
  mock_android_apis::g_ahb_allocate_count = 0;
  mock_android_apis::g_ahb_release_count = 0;
  mock_android_apis::g_choreographer_post_count = 0;

  auto loader = std::make_shared<MockOSLibraryLoader>();

  // Register mock libandroid.so with Android C-API functions
  auto libandroid = std::make_shared<MockOSLibrary>("libandroid.so");
  libandroid->SetSymbol("AHardwareBuffer_allocate",
                        reinterpret_cast<void*>(
                            &mock_android_apis::Mock_AHardwareBuffer_allocate));
  libandroid->SetSymbol("AHardwareBuffer_release",
                        reinterpret_cast<void*>(
                            &mock_android_apis::Mock_AHardwareBuffer_release));
  libandroid->SetSymbol(
      "AChoreographer_postFrameCallback64",
      reinterpret_cast<void*>(
          &mock_android_apis::Mock_AChoreographer_postFrameCallback64));

  loader->RegisterLibrary("libandroid.so", libandroid);

  EXPECT_TRUE(loader->IsLibraryLoaded("libandroid.so"));
  EXPECT_FALSE(loader->IsLibraryLoaded("libEGL.so"));

  // Resolve AHardwareBuffer_allocate
  using AHardwareBuffer_allocate_fn = int (*)(const void*, void**);
  auto allocate_fn = loader->ResolveFunction<AHardwareBuffer_allocate_fn>(
      "libandroid.so", "AHardwareBuffer_allocate");
  ASSERT_NE(allocate_fn, nullptr);

  void* created_buffer = nullptr;
  int alloc_result = allocate_fn(nullptr, &created_buffer);
  EXPECT_EQ(alloc_result, 0);
  EXPECT_EQ(created_buffer, reinterpret_cast<void*>(0xBAADF00D));
  EXPECT_EQ(mock_android_apis::g_ahb_allocate_count, 1);

  // Resolve AHardwareBuffer_release
  using AHardwareBuffer_release_fn = void (*)(void*);
  auto release_fn = loader->ResolveFunction<AHardwareBuffer_release_fn>(
      "libandroid.so", "AHardwareBuffer_release");
  ASSERT_NE(release_fn, nullptr);
  release_fn(created_buffer);
  EXPECT_EQ(mock_android_apis::g_ahb_release_count, 1);

  // Resolve AChoreographer_postFrameCallback64
  using AChoreographer_postFrameCallback64_fn = void (*)(void*, void*, void*);
  auto post_vsync_fn =
      loader->ResolveFunction<AChoreographer_postFrameCallback64_fn>(
          "libandroid.so", "AChoreographer_postFrameCallback64");
  ASSERT_NE(post_vsync_fn, nullptr);
  post_vsync_fn(nullptr, nullptr, nullptr);
  EXPECT_EQ(mock_android_apis::g_choreographer_post_count, 1);

  // Unregister library
  loader->UnregisterLibrary("libandroid.so");
  EXPECT_FALSE(loader->IsLibraryLoaded("libandroid.so"));
  EXPECT_EQ(loader->ResolveSymbol("libandroid.so", "AHardwareBuffer_allocate"),
            nullptr);
}

TEST(OSLibraryLoaderTest, MockOSLibraryLoaderConvenienceSetSymbol) {
  auto loader = std::make_shared<MockOSLibraryLoader>();

  auto mock_egl_proc = []() -> void* {
    return reinterpret_cast<void*>(0x1234);
  };
  loader->SetSymbol("libEGL.so", "eglGetCurrentContext",
                    reinterpret_cast<void*>(+mock_egl_proc));

  EXPECT_TRUE(loader->IsLibraryLoaded("libEGL.so"));

  using EglGetCurrentContextFn = void* (*)();
  auto egl_fn = loader->ResolveFunction<EglGetCurrentContextFn>(
      "libEGL.so", "eglGetCurrentContext");
  ASSERT_NE(egl_fn, nullptr);
  EXPECT_EQ(egl_fn(), reinterpret_cast<void*>(0x1234));

  loader->ClearLibraries();
  EXPECT_FALSE(loader->IsLibraryLoaded("libEGL.so"));
}

TEST(OSLibraryLoaderTest, FlutterEmbedderNativeLibraryLoaderIntegration) {
  // Test default loader setup
  auto native_default = std::make_unique<FlutterEmbedderNative>();
  EXPECT_NE(native_default->GetLibraryLoader(), nullptr);
  EXPECT_NE(FlutterEmbedderNative::GetDefaultLibraryLoader(), nullptr);

  // Test custom loader injection into FlutterEmbedderNative
  auto mock_loader = std::make_shared<MockOSLibraryLoader>();
  auto mock_invoker = std::make_shared<MockJvmInvoker>();

  auto dummy_vsync_fn = [](void* c, void* cb, void* d) {};
  mock_loader->SetSymbol("libandroid.so", "AChoreographer_postFrameCallback64",
                         reinterpret_cast<void*>(+dummy_vsync_fn));

  FlutterEmbedderNative native_custom(mock_invoker, nullptr, mock_loader);
  EXPECT_EQ(native_custom.GetLibraryLoader(), mock_loader);

  void* vsync_symbol = native_custom.GetLibraryLoader()->ResolveSymbol(
      "libandroid.so", "AChoreographer_postFrameCallback64");
  EXPECT_NE(vsync_symbol, nullptr);
}

TEST(OSLibraryLoaderTest, ThreadSafeConcurrentSymbolResolution) {
  auto mock_loader = std::make_shared<MockOSLibraryLoader>();

  for (int i = 0; i < 50; ++i) {
    std::string sym_name = "MockSymbol_" + std::to_string(i);
    mock_loader->SetSymbol(
        "libconcurrent.so", sym_name,
        reinterpret_cast<void*>(static_cast<uintptr_t>(i + 1)));
  }

  constexpr size_t kThreadCount = 8;
  constexpr size_t kIterationsPerThread = 500;
  std::vector<std::future<bool>> futures;
  futures.reserve(kThreadCount);

  for (size_t t = 0; t < kThreadCount; ++t) {
    futures.push_back(std::async(std::launch::async, [mock_loader, t]() {
      for (size_t iter = 0; iter < kIterationsPerThread; ++iter) {
        int sym_idx = static_cast<int>((t + iter) % 50);
        std::string sym_name = "MockSymbol_" + std::to_string(sym_idx);
        void* ptr =
            mock_loader->ResolveSymbol("libconcurrent.so", sym_name.c_str());
        if (ptr !=
            reinterpret_cast<void*>(static_cast<uintptr_t>(sym_idx + 1))) {
          return false;
        }
      }
      return true;
    }));
  }

  for (auto& f : futures) {
    EXPECT_TRUE(f.get());
  }
}

TEST(OSLibraryLoaderTest, DefaultOSLibraryLoaderRealLibraryLoading) {
  auto loader = std::make_shared<DefaultOSLibraryLoader>();
#if defined(__APPLE__)
  const char* real_lib = "libm.dylib";
#elif defined(_WIN32)
  const char* real_lib = "kernel32.dll";
#else
  const char* real_lib = "libm.so";
#endif
  auto lib = loader->LoadDynamicLibrary(real_lib);
  if (lib) {
    EXPECT_TRUE(lib->IsValid());
    EXPECT_TRUE(loader->IsLibraryLoaded(real_lib));
#if defined(_WIN32)
    using GetTickCountFn = DWORD (*)();
    auto fn = loader->ResolveFunction<GetTickCountFn>(real_lib, "GetTickCount");
    if (fn) {
      EXPECT_GT(fn(), 0u);
    }
#else
    using SinFn = double (*)(double);
    auto fn = loader->ResolveFunction<SinFn>(real_lib, "sin");
    if (fn) {
      EXPECT_DOUBLE_EQ(fn(0.0), 0.0);
    }
#endif
  }

  // Also test process-global scope
  auto global_lib =
      loader->LoadDynamicLibrary(OSLibraryLoader::kProcessGlobalScope);
  if (global_lib) {
    EXPECT_TRUE(global_lib->IsValid());
  }
}

TEST(OSLibraryLoaderTest, MockOSLibraryLoaderDynamicPointerCastAndNullSafety) {
  auto mock_loader = std::make_shared<MockOSLibraryLoader>();

  // Registering null should be rejected safely
  mock_loader->RegisterLibrary("", nullptr);
  EXPECT_FALSE(mock_loader->IsLibraryLoaded(""));
  mock_loader->RegisterLibrary("null_lib", nullptr);
  EXPECT_FALSE(mock_loader->IsLibraryLoaded("null_lib"));

  // Registering valid library under kProcessGlobalScope should succeed
  auto global_mock =
      std::make_shared<MockOSLibrary>(OSLibraryLoader::kProcessGlobalScope);
  mock_loader->RegisterLibrary(OSLibraryLoader::kProcessGlobalScope,
                               global_mock);
  EXPECT_TRUE(
      mock_loader->IsLibraryLoaded(OSLibraryLoader::kProcessGlobalScope));

  // Registering non-MockOSLibrary (e.g. DefaultOSLibrary with mock handle)
  auto default_lib =
      std::make_shared<DefaultOSLibrary>("dummy", nullptr, false);
  mock_loader->RegisterLibrary("default_dummy", default_lib);

  // SetSymbol must use dynamic_pointer_cast and not crash or corrupt memory
  auto dummy_func = []() {};
  mock_loader->SetSymbol("default_dummy", "test_symbol",
                         reinterpret_cast<void*>(+dummy_func));
  EXPECT_NE(mock_loader->ResolveSymbol("default_dummy", "test_symbol"),
            nullptr);
}

TEST(OSLibraryLoaderTest, ThreadSafeConcurrentValidityAndResolution) {
  auto mock_lib = std::make_shared<MockOSLibrary>("lib_validity.so");
  auto dummy_func = []() {};
  mock_lib->SetSymbol("test_fn", reinterpret_cast<void*>(+dummy_func));

  std::atomic<bool> stop_flag{false};
  auto updater = std::async(std::launch::async, [&]() {
    while (!stop_flag.load()) {
      mock_lib->SetValid(false);
      std::this_thread::yield();
      mock_lib->SetValid(true);
      std::this_thread::yield();
    }
  });

  std::vector<std::future<void>> readers;
  for (int i = 0; i < 4; ++i) {
    readers.push_back(std::async(std::launch::async, [&]() {
      for (int j = 0; j < 500; ++j) {
        bool valid = mock_lib->IsValid();
        void* sym = mock_lib->ResolveSymbol("test_fn");
        if (valid && sym == nullptr) {
          // Validity toggled between calls, which is valid.
        }
      }
    }));
  }

  for (auto& r : readers) {
    r.get();
  }
  stop_flag.store(true);
  updater.get();
}

TEST(OSLibraryLoaderTest, ThreadSafeGlobalLoaderAccess) {
  constexpr size_t kThreadCount = 8;
  std::vector<std::future<void>> futures;
  futures.reserve(kThreadCount);

  for (size_t t = 0; t < kThreadCount; ++t) {
    futures.push_back(std::async(std::launch::async, [t]() {
      for (size_t i = 0; i < 100; ++i) {
        if (t % 2 == 0) {
          auto loader = FlutterEmbedderNative::GetDefaultLibraryLoader();
          EXPECT_NE(loader, nullptr);
        } else {
          FlutterEmbedderNative native_inst;
          EXPECT_NE(native_inst.GetLibraryLoader(), nullptr);
        }
      }
    }));
  }

  for (auto& f : futures) {
    f.get();
  }
}

}  // namespace testing
}  // namespace android
}  // namespace flutter

int main(int argc, char* argv[]) {
  ::testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
