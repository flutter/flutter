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
               const std::vector<uint8_t>& message,
               int32_t response_id),
              (override));

  MOCK_METHOD(bool,
              HandlePlatformMessageResponse,
              (int32_t response_id, const std::vector<uint8_t>& data),
              (override));

  MOCK_METHOD(bool,
              UpdateSemantics,
              (const std::vector<uint8_t>& buffer,
               const std::vector<std::string>& strings),
              (override));

  MOCK_METHOD(bool, SetSemanticsEnabled, (bool enabled), (override));

  MOCK_METHOD(bool,
              SetApplicationLocale,
              (const std::string& locale),
              (override));

  MOCK_METHOD(bool, OnFirstFrame, (), (override));

  MOCK_METHOD(bool, OnPreEngineRestart, (), (override));

  MOCK_METHOD(bool,
              OnVsync,
              (int64_t frame_time_nanos, int64_t frame_target_time_nanos),
              (override));

  MOCK_METHOD(
      bool,
      DispatchViewportMetrics,
      (int64_t view_id, double width, double height, double pixel_ratio),
      (override));

  MOCK_METHOD(bool,
              RequestDartDeferredLibrary,
              (int64_t loading_unit_id),
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

  bool task_executed = false;
  EXPECT_TRUE(
      invoker->PostJvmTask([&task_executed]() { task_executed = true; }));
  EXPECT_TRUE(task_executed);

  invoker->DetachFromThread();
}

TEST(FlutterEmbedderNativeTest, JniDelegateWithMockInvoker) {
  auto mock_invoker = std::make_shared<MockJvmInvoker>();
  auto delegate = std::make_unique<JniDelegate>(mock_invoker);

  EXPECT_EQ(delegate->GetJvmInvoker(), mock_invoker);

  // 1. HandlePlatformMessage
  std::vector<uint8_t> msg = {'h', 'e', 'l', 'l', 'o'};
  EXPECT_CALL(*mock_invoker, InvokeVoidMethod("handlePlatformMessage",
                                              "(Ljava/lang/String;[BI)V", msg))
      .WillOnce(Return(true));
  EXPECT_TRUE(delegate->HandlePlatformMessage("flutter/test", msg, 42));

  // 2. HandlePlatformMessageResponse
  std::vector<uint8_t> resp = {'o', 'k'};
  EXPECT_CALL(*mock_invoker,
              InvokeVoidMethod("handlePlatformMessageResponse", "(I[B)V", resp))
      .WillOnce(Return(true));
  EXPECT_TRUE(delegate->HandlePlatformMessageResponse(42, resp));

  // 3. UpdateSemantics
  std::vector<uint8_t> semantics_buffer = {0x01, 0x02};
  std::vector<std::string> semantics_strings = {"label1", "label2"};
  EXPECT_CALL(*mock_invoker,
              InvokeVoidMethod("updateSemantics", "([B[Ljava/lang/String;)V",
                               semantics_buffer))
      .WillOnce(Return(true));
  EXPECT_TRUE(delegate->UpdateSemantics(semantics_buffer, semantics_strings));

  // 4. SetSemanticsEnabled
  EXPECT_CALL(*mock_invoker, InvokeVoidMethod("setSemanticsEnabled", "(Z)V",
                                              std::vector<uint8_t>{1}))
      .WillOnce(Return(true));
  EXPECT_TRUE(delegate->SetSemanticsEnabled(true));

  // 5. SetApplicationLocale
  std::string locale = "en_US";
  std::vector<uint8_t> locale_payload(locale.begin(), locale.end());
  EXPECT_CALL(*mock_invoker,
              InvokeVoidMethod("setApplicationLocale", "(Ljava/lang/String;)V",
                               locale_payload))
      .WillOnce(Return(true));
  EXPECT_TRUE(delegate->SetApplicationLocale(locale));

  // 6. OnFirstFrame
  EXPECT_CALL(*mock_invoker, InvokeVoidMethod("onFirstFrame", "()V", _))
      .WillOnce(Return(true));
  EXPECT_TRUE(delegate->OnFirstFrame());

  // 7. OnPreEngineRestart
  EXPECT_CALL(*mock_invoker, InvokeVoidMethod("onPreEngineRestart", "()V", _))
      .WillOnce(Return(true));
  EXPECT_TRUE(delegate->OnPreEngineRestart());

  // 8. OnVsync
  EXPECT_CALL(*mock_invoker, InvokeVoidMethod("onVsync", "(JJ)V", _))
      .WillOnce(Return(true));
  EXPECT_TRUE(delegate->OnVsync(1000000L, 2000000L));

  // 9. DispatchViewportMetrics
  EXPECT_CALL(*mock_invoker,
              InvokeVoidMethod("onViewportMetrics", "(IDDD)V", _))
      .WillOnce(Return(true));
  EXPECT_TRUE(delegate->DispatchViewportMetrics(0, 1080.0, 1920.0, 2.5));

  // 10. RequestDartDeferredLibrary
  EXPECT_CALL(*mock_invoker,
              InvokeBooleanMethod("requestDartDeferredLibrary", "(I)Z", _))
      .WillOnce(Return(true));
  EXPECT_TRUE(delegate->RequestDartDeferredLibrary(101));
}

TEST(FlutterEmbedderNativeTest, JniRouterRoutingFlip) {
  auto mock_invoker = std::make_shared<MockJvmInvoker>();
  auto embedder_delegate = std::make_shared<JniDelegate>(mock_invoker);
  auto legacy_delegate = std::make_shared<MockLegacyJniDelegate>();

  auto router = std::make_unique<JniRouter>(embedder_delegate, legacy_delegate);

  // Initial state: Embedder disabled -> routes to Legacy
  JniRouter::SetEmbedderEnabled(false);
  EXPECT_FALSE(JniRouter::IsEmbedderEnabled());
  EXPECT_EQ(router->GetActiveRoutingPath(), JniRouter::RoutingPath::kLegacy);

  std::vector<uint8_t> payload = {'t', 'e', 's', 't'};

  // Expect legacy delegate call, mock_invoker should not be called
  EXPECT_CALL(*legacy_delegate,
              HandlePlatformMessage("flutter/lifecycle", payload, 1))
      .WillOnce(Return(true));
  EXPECT_CALL(*mock_invoker, InvokeVoidMethod(_, _, _)).Times(0);

  EXPECT_TRUE(router->RoutePlatformMessage("flutter/lifecycle", payload, 1));

  // Legacy OnFirstFrame
  EXPECT_CALL(*legacy_delegate, OnFirstFrame()).WillOnce(Return(true));
  EXPECT_TRUE(router->RouteFirstFrame());

  // Legacy Vsync
  EXPECT_CALL(*legacy_delegate, OnVsync(100L, 200L)).WillOnce(Return(true));
  EXPECT_TRUE(router->RouteVsync(100L, 200L));

  // Legacy Deferred Library
  EXPECT_CALL(*legacy_delegate, RequestDartDeferredLibrary(5))
      .WillOnce(Return(true));
  EXPECT_TRUE(router->RouteRequestDartDeferredLibrary(5));

  // Flip flag to true -> routes to Embedder
  JniRouter::SetEmbedderEnabled(true);
  EXPECT_TRUE(JniRouter::IsEmbedderEnabled());
  EXPECT_EQ(router->GetActiveRoutingPath(), JniRouter::RoutingPath::kEmbedder);

  // Expect mock_invoker call via embedder delegate, legacy should not be called
  EXPECT_CALL(*legacy_delegate, HandlePlatformMessage(_, _, _)).Times(0);
  EXPECT_CALL(*mock_invoker,
              InvokeVoidMethod("handlePlatformMessage",
                               "(Ljava/lang/String;[BI)V", payload))
      .WillOnce(Return(true));

  EXPECT_TRUE(router->RoutePlatformMessage("flutter/lifecycle", payload, 1));

  // Embedder OnFirstFrame
  EXPECT_CALL(*mock_invoker, InvokeVoidMethod("onFirstFrame", "()V", _))
      .WillOnce(Return(true));
  EXPECT_TRUE(router->RouteFirstFrame());

  // Embedder Vsync
  EXPECT_CALL(*mock_invoker, InvokeVoidMethod("onVsync", "(JJ)V", _))
      .WillOnce(Return(true));
  EXPECT_TRUE(router->RouteVsync(100L, 200L));

  // Embedder Deferred Library
  EXPECT_CALL(*mock_invoker,
              InvokeBooleanMethod("requestDartDeferredLibrary", "(I)Z", _))
      .WillOnce(Return(true));
  EXPECT_TRUE(router->RouteRequestDartDeferredLibrary(5));

  // Reset flag back to false for test hygiene
  JniRouter::SetEmbedderEnabled(false);
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

  EXPECT_CALL(*mock_invoker, InvokeVoidMethod("onFirstFrame", "()V", _))
      .WillOnce(Return(true));
  EXPECT_TRUE(native.GetRouter()->RouteFirstFrame());

  FlutterEmbedderNative::SetEmbedderEnabled(false);
  EXPECT_FALSE(FlutterEmbedderNative::IsEmbedderEnabled());
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

}  // namespace testing
}  // namespace android
}  // namespace flutter

int main(int argc, char* argv[]) {
  ::testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
