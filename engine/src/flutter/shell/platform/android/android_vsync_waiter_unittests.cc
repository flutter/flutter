// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <cmath>
#include <future>
#include <thread>
#include <vector>

#include "flutter/shell/platform/android/android_vsync_waiter.h"
#include "flutter/shell/platform/android/jvm_invoker.h"
#include "flutter/shell/platform/android/os_library_loader.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"

namespace flutter {
namespace android {
namespace testing {

using ::testing::_;
using ::testing::Return;

namespace {

class MockVsyncJvmInvoker : public JvmInvoker {
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

  MOCK_METHOD(bool,
              UpdateCustomAccessibilityActions,
              (const std::vector<uint8_t>& actions_buffer,
               const std::vector<std::string>& action_strings),
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
              DecodeImage,
              (const uint8_t* data, size_t size, int64_t generator_handle),
              (override));
  MOCK_METHOD(bool,
              PushPlatformViewMutators,
              (int64_t view_id,
               int32_t x,
               int32_t y,
               int32_t width,
               int32_t height,
               int32_t view_width,
               int32_t view_height,
               const std::vector<uint8_t>& payload),
              (override));

  MOCK_METHOD(bool, PostJvmTask, (std::function<void()> task), (override));
};

static AChoreographer* g_mock_choreographer_ptr =
    reinterpret_cast<AChoreographer*>(0xABCD1234);

static AChoreographer_frameCallback64 g_last_callback64 = nullptr;
static void* g_last_data64 = nullptr;

static AChoreographer_frameCallback g_last_callback32 = nullptr;
static void* g_last_data32 = nullptr;

static uint32_t g_last_delay_ms64 = 0;
static int64_t g_last_delay_ms32 = 0;

AChoreographer* Mock_AChoreographer_getInstance() {
  return g_mock_choreographer_ptr;
}

void Mock_AChoreographer_postFrameCallback64(
    AChoreographer* choreographer,
    AChoreographer_frameCallback64 callback,
    void* data) {
  g_last_callback64 = callback;
  g_last_data64 = data;
}

void Mock_AChoreographer_postFrameCallback(
    AChoreographer* choreographer,
    AChoreographer_frameCallback callback,
    void* data) {
  g_last_callback32 = callback;
  g_last_data32 = data;
}

void Mock_AChoreographer_postFrameCallbackDelayed64(
    AChoreographer* choreographer,
    AChoreographer_frameCallback64 callback,
    void* data,
    uint32_t delayMillis) {
  g_last_callback64 = callback;
  g_last_data64 = data;
  g_last_delay_ms64 = delayMillis;
}

void Mock_AChoreographer_postFrameCallbackDelayed(
    AChoreographer* choreographer,
    AChoreographer_frameCallback callback,
    void* data,
    long delayMillis) {
  g_last_callback32 = callback;
  g_last_data32 = data;
  g_last_delay_ms32 = delayMillis;
}

void ResetMockFunctions() {
  g_last_callback64 = nullptr;
  g_last_data64 = nullptr;
  g_last_callback32 = nullptr;
  g_last_data32 = nullptr;
  g_last_delay_ms64 = 0;
  g_last_delay_ms32 = 0;
}

}  // namespace

// =============================================================================
// AndroidChoreographerProvider Tests
// =============================================================================

TEST(AndroidChoreographerProviderTest,
     DefaultAndroidChoreographerProviderMissingLibraryFallback) {
  auto mock_loader = std::make_shared<MockOSLibraryLoader>();
  // No libandroid.so registered -> loading fails
  DefaultAndroidChoreographerProvider provider(mock_loader);

  EXPECT_FALSE(provider.IsAvailable());
  EXPECT_FALSE(provider.Has64BitSupport());

  bool callback_invoked = false;
  EXPECT_FALSE(provider.PostFrameCallback(
      [&callback_invoked](int64_t time) { callback_invoked = true; }));
  EXPECT_FALSE(callback_invoked);

  EXPECT_FALSE(provider.PostFrameCallbackDelayed(
      [&callback_invoked](int64_t time) { callback_invoked = true; }, 16));
}

TEST(AndroidChoreographerProviderTest,
     DefaultAndroidChoreographerProvider64BitResolutionAndExecution) {
  ResetMockFunctions();
  auto mock_loader = std::make_shared<MockOSLibraryLoader>();
  auto mock_lib = std::make_shared<MockOSLibrary>("libandroid.so");

  mock_lib->SetSymbol(
      "AChoreographer_getInstance",
      reinterpret_cast<void*>(&Mock_AChoreographer_getInstance));
  mock_lib->SetSymbol(
      "AChoreographer_postFrameCallback64",
      reinterpret_cast<void*>(&Mock_AChoreographer_postFrameCallback64));
  mock_lib->SetSymbol(
      "AChoreographer_postFrameCallbackDelayed64",
      reinterpret_cast<void*>(&Mock_AChoreographer_postFrameCallbackDelayed64));
  mock_loader->RegisterLibrary("libandroid.so", mock_lib);

  DefaultAndroidChoreographerProvider provider(mock_loader);
  EXPECT_TRUE(provider.IsAvailable());
  EXPECT_TRUE(provider.Has64BitSupport());

  int64_t received_frame_time = 0;
  bool posted = provider.PostFrameCallback(
      [&received_frame_time](int64_t frame_time_nanos) {
        received_frame_time = frame_time_nanos;
      });
  EXPECT_TRUE(posted);
  ASSERT_NE(g_last_callback64, nullptr);
  ASSERT_NE(g_last_data64, nullptr);

  // Trigger 64-bit native callback
  g_last_callback64(9876543210123LL, g_last_data64);
  EXPECT_EQ(received_frame_time, 9876543210123LL);

  // Test delayed 64-bit callback
  ResetMockFunctions();
  bool posted_delayed = provider.PostFrameCallbackDelayed(
      [&received_frame_time](int64_t frame_time_nanos) {
        received_frame_time = frame_time_nanos;
      },
      32);
  EXPECT_TRUE(posted_delayed);
  EXPECT_EQ(g_last_delay_ms64, 32u);
  ASSERT_NE(g_last_callback64, nullptr);
  g_last_callback64(5555555555LL, g_last_data64);
  EXPECT_EQ(received_frame_time, 5555555555LL);
}

TEST(AndroidChoreographerProviderTest,
     DefaultAndroidChoreographerProvider32BitResolutionAndExecution) {
  ResetMockFunctions();
  auto mock_loader = std::make_shared<MockOSLibraryLoader>();
  auto mock_lib = std::make_shared<MockOSLibrary>("libandroid.so");

  mock_lib->SetSymbol(
      "AChoreographer_getInstance",
      reinterpret_cast<void*>(&Mock_AChoreographer_getInstance));
  mock_lib->SetSymbol(
      "AChoreographer_postFrameCallback",
      reinterpret_cast<void*>(&Mock_AChoreographer_postFrameCallback));
  mock_lib->SetSymbol(
      "AChoreographer_postFrameCallbackDelayed",
      reinterpret_cast<void*>(&Mock_AChoreographer_postFrameCallbackDelayed));
  mock_loader->RegisterLibrary("libandroid.so", mock_lib);

  DefaultAndroidChoreographerProvider provider(mock_loader);
  EXPECT_TRUE(provider.IsAvailable());
  EXPECT_FALSE(provider.Has64BitSupport());

  int64_t received_frame_time = 0;
  bool posted = provider.PostFrameCallback(
      [&received_frame_time](int64_t frame_time_nanos) {
        received_frame_time = frame_time_nanos;
      });
  EXPECT_TRUE(posted);
  ASSERT_NE(g_last_callback32, nullptr);
  ASSERT_NE(g_last_data32, nullptr);

  // Trigger 32-bit native callback
  g_last_callback32(12345678L, g_last_data32);
  EXPECT_EQ(received_frame_time, 12345678LL);

  // Test delayed 32-bit callback
  ResetMockFunctions();
  bool posted_delayed = provider.PostFrameCallbackDelayed(
      [&received_frame_time](int64_t frame_time_nanos) {
        received_frame_time = frame_time_nanos;
      },
      16);
  EXPECT_TRUE(posted_delayed);
  EXPECT_EQ(g_last_delay_ms32, 16L);
  ASSERT_NE(g_last_callback32, nullptr);
  g_last_callback32(87654321L, g_last_data32);
  EXPECT_EQ(received_frame_time, 87654321LL);
}

TEST(AndroidChoreographerProviderTest,
     InMemoryAndroidChoreographerProviderOperations) {
  InMemoryAndroidChoreographerProvider provider;
  EXPECT_TRUE(provider.IsAvailable());
  EXPECT_TRUE(provider.Has64BitSupport());
  EXPECT_EQ(provider.GetPendingCallbackCount(), 0u);
  EXPECT_FALSE(provider.HasPendingCallbacks());

  std::vector<int64_t> received_times;
  EXPECT_TRUE(provider.PostFrameCallback(
      [&received_times](int64_t time) { received_times.push_back(time); }));
  EXPECT_TRUE(provider.PostFrameCallback([&received_times](int64_t time) {
    received_times.push_back(time + 100);
  }));

  EXPECT_EQ(provider.GetPendingCallbackCount(), 2u);
  EXPECT_TRUE(provider.HasPendingCallbacks());

  provider.TriggerPendingCallbacks(1000000LL);
  EXPECT_EQ(provider.GetPendingCallbackCount(), 0u);
  ASSERT_EQ(received_times.size(), 2u);
  EXPECT_EQ(received_times[0], 1000000LL);
  EXPECT_EQ(received_times[1], 1000100LL);

  // Clear callbacks
  received_times.clear();
  EXPECT_TRUE(provider.PostFrameCallback(
      [&received_times](int64_t time) { received_times.push_back(time); }));
  EXPECT_EQ(provider.GetPendingCallbackCount(), 1u);
  provider.ClearPendingCallbacks();
  EXPECT_EQ(provider.GetPendingCallbackCount(), 0u);

  // Set unavailable
  provider.SetAvailable(false);
  EXPECT_FALSE(provider.IsAvailable());
  EXPECT_FALSE(provider.PostFrameCallback(
      [&received_times](int64_t time) { received_times.push_back(time); }));

  // Set 64-bit support flag
  provider.Set64BitSupport(false);
  EXPECT_FALSE(provider.Has64BitSupport());
}

TEST(AndroidChoreographerProviderTest,
     ThreadSafeConcurrentChoreographerOperations) {
  auto provider = std::make_shared<InMemoryAndroidChoreographerProvider>();

  constexpr int kThreads = 8;
  constexpr int kOpsPerThread = 100;
  std::atomic<int> callbacks_executed = 0;

  std::vector<std::thread> threads;
  threads.reserve(kThreads);

  for (int t = 0; t < kThreads; ++t) {
    threads.emplace_back([provider, &callbacks_executed]() {
      for (int i = 0; i < kOpsPerThread; ++i) {
        provider->PostFrameCallback([&callbacks_executed](int64_t time) {
          callbacks_executed.fetch_add(1, std::memory_order_relaxed);
        });
      }
    });
  }

  for (auto& t : threads) {
    t.join();
  }

  EXPECT_EQ(provider->GetPendingCallbackCount(),
            static_cast<size_t>(kThreads * kOpsPerThread));

  provider->TriggerPendingCallbacks(2000000LL);
  EXPECT_EQ(callbacks_executed.load(), kThreads * kOpsPerThread);
  EXPECT_EQ(provider->GetPendingCallbackCount(), 0u);
}

// =============================================================================
// AndroidVsyncWaiter Tests
// =============================================================================

TEST(AndroidVsyncWaiterTest,
     FramePacingCalculations120HzAndVariableRefreshRates) {
  int64_t frame_time = 1000000000LL;

  // 120 Hz: period = 1e9 / 120 = 8,333,333 ns (8.33 ms)
  auto info120 = AndroidVsyncWaiter::ComputeFramePacing(frame_time, 120.0);
  EXPECT_DOUBLE_EQ(info120.refresh_rate_hz, 120.0);
  EXPECT_EQ(info120.refresh_period_nanos, 8333333LL);
  EXPECT_EQ(info120.frame_target_time_nanos - info120.frame_start_time_nanos,
            8333333LL);

  // 90 Hz: period = 1e9 / 90 = 11,111,111 ns (11.11 ms)
  auto info90 = AndroidVsyncWaiter::ComputeFramePacing(frame_time, 90.0);
  EXPECT_DOUBLE_EQ(info90.refresh_rate_hz, 90.0);
  EXPECT_EQ(info90.refresh_period_nanos, 11111111LL);
  EXPECT_EQ(info90.frame_target_time_nanos - info90.frame_start_time_nanos,
            11111111LL);

  // 60 Hz: period = 1e9 / 60 = 16,666,666 ns (16.66 ms)
  auto info60 = AndroidVsyncWaiter::ComputeFramePacing(frame_time, 60.0);
  EXPECT_DOUBLE_EQ(info60.refresh_rate_hz, 60.0);
  EXPECT_EQ(info60.refresh_period_nanos, 16666666LL);
  EXPECT_EQ(info60.frame_target_time_nanos - info60.frame_start_time_nanos,
            16666666LL);

  // 144 Hz: period = 1e9 / 144 = 6,944,444 ns (6.94 ms)
  auto info144 = AndroidVsyncWaiter::ComputeFramePacing(frame_time, 144.0);
  EXPECT_DOUBLE_EQ(info144.refresh_rate_hz, 144.0);
  EXPECT_EQ(info144.refresh_period_nanos, 6944444LL);

  // Fallback for invalid <= 0 Hz defaults to 60 Hz
  auto info_default = AndroidVsyncWaiter::ComputeFramePacing(frame_time, 0.0);
  EXPECT_DOUBLE_EQ(info_default.refresh_rate_hz, 60.0);
  EXPECT_EQ(info_default.refresh_period_nanos, 16666666LL);
}

TEST(AndroidVsyncWaiterTest, FramePacingClampingFutureAndNegativeTimestamps) {
  // Future timestamp (way in the future) should be clamped to now
  int64_t future_time = 999999999999999999LL;
  auto info_future = AndroidVsyncWaiter::ComputeFramePacing(future_time, 60.0);
  EXPECT_LT(info_future.frame_start_time_nanos, future_time);
  EXPECT_GT(info_future.frame_start_time_nanos, 0LL);
  EXPECT_EQ(
      info_future.frame_target_time_nanos - info_future.frame_start_time_nanos,
      16666666LL);

  // Negative/zero timestamp should be normalized to now
  auto info_zero = AndroidVsyncWaiter::ComputeFramePacing(0, 60.0);
  EXPECT_GT(info_zero.frame_start_time_nanos, 0LL);

  auto info_neg = AndroidVsyncWaiter::ComputeFramePacing(-500, 60.0);
  EXPECT_GT(info_neg.frame_start_time_nanos, 0LL);
}

TEST(AndroidVsyncWaiterTest, AsyncWaitForVsyncWithChoreographerAnd120HzPacing) {
  auto mock_choreographer =
      std::make_shared<InMemoryAndroidChoreographerProvider>();
  auto waiter = std::make_shared<AndroidVsyncWaiter>(mock_choreographer);

  waiter->UpdateRefreshRate(120.0);
  EXPECT_DOUBLE_EQ(waiter->GetRefreshRate(), 120.0);
  EXPECT_EQ(waiter->GetRefreshPeriodNanos(), 8333333LL);

  intptr_t received_baton = 0;
  int64_t received_start_time = 0;
  int64_t received_target_time = 0;

  waiter->SetVsyncResultCallback(
      [&](intptr_t baton, int64_t start_time, int64_t target_time) {
        received_baton = baton;
        received_start_time = start_time;
        received_target_time = target_time;
      });

  EXPECT_EQ(waiter->GetVsyncRequestCount(), 0u);
  EXPECT_EQ(waiter->GetVsyncDeliveredCount(), 0u);

  // Request vsync with baton 42
  EXPECT_TRUE(waiter->AsyncWaitForVsync(42));
  EXPECT_EQ(waiter->GetVsyncRequestCount(), 1u);
  EXPECT_EQ(waiter->GetVsyncDeliveredCount(), 0u);
  EXPECT_TRUE(mock_choreographer->HasPendingCallbacks());

  // Trigger choreographer signal at timestamp 10,000,000 ns
  mock_choreographer->TriggerPendingCallbacks(10000000LL);

  EXPECT_EQ(waiter->GetVsyncDeliveredCount(), 1u);
  EXPECT_EQ(received_baton, 42);
  EXPECT_EQ(received_start_time, 10000000LL);
  EXPECT_EQ(received_target_time, 10000000LL + 8333333LL);
}

TEST(AndroidVsyncWaiterTest, StaticOnVsyncCallback) {
  auto mock_choreographer =
      std::make_shared<InMemoryAndroidChoreographerProvider>();
  auto waiter = std::make_shared<AndroidVsyncWaiter>(mock_choreographer);

  intptr_t delivered_baton = 0;
  waiter->SetVsyncResultCallback(
      [&](intptr_t baton, int64_t start, int64_t target) {
        delivered_baton = baton;
      });

  // Call static C-API compatible callback
  AndroidVsyncWaiter::OnVsyncCallback(waiter.get(), 999);
  EXPECT_EQ(waiter->GetVsyncRequestCount(), 1u);

  mock_choreographer->TriggerPendingCallbacks(20000000LL);
  EXPECT_EQ(delivered_baton, 999);
}

TEST(AndroidVsyncWaiterTest,
     AsyncWaitForVsyncFallbackToJvmWhenNoChoreographer) {
  auto mock_choreographer =
      std::make_shared<InMemoryAndroidChoreographerProvider>();
  mock_choreographer->SetAvailable(false);

  auto mock_invoker = std::make_shared<MockVsyncJvmInvoker>();
  auto waiter =
      std::make_shared<AndroidVsyncWaiter>(mock_choreographer, mock_invoker);

  EXPECT_CALL(*mock_invoker, InvokeVoidMethod("asyncWaitForVsync", "(J)V", _))
      .WillOnce(Return(true));

  EXPECT_TRUE(waiter->AsyncWaitForVsync(12345));
  EXPECT_EQ(waiter->GetVsyncRequestCount(), 1u);
}

TEST(AndroidVsyncWaiterTest, DynamicRefreshRateSwitching) {
  auto mock_choreographer =
      std::make_shared<InMemoryAndroidChoreographerProvider>();
  auto waiter = std::make_shared<AndroidVsyncWaiter>(mock_choreographer);

  int64_t target1 = 0;
  int64_t target2 = 0;

  waiter->SetVsyncResultCallback(
      [&](intptr_t baton, int64_t start, int64_t target) {
        if (baton == 1) {
          target1 = target;
        } else {
          target2 = target;
        }
      });

  // Start at 60 Hz
  waiter->UpdateRefreshRate(60.0);
  EXPECT_DOUBLE_EQ(waiter->GetRefreshRate(), 60.0);
  waiter->AsyncWaitForVsync(1);
  mock_choreographer->TriggerPendingCallbacks(100000000LL);
  EXPECT_EQ(target1, 100000000LL + 16666666LL);

  // Switch to 120 Hz
  waiter->UpdateRefreshRate(120.0);
  EXPECT_DOUBLE_EQ(waiter->GetRefreshRate(), 120.0);
  waiter->AsyncWaitForVsync(2);
  mock_choreographer->TriggerPendingCallbacks(200000000LL);
  EXPECT_EQ(target2, 200000000LL + 8333333LL);
}

TEST(AndroidVsyncWaiterTest, ThreadSafeConcurrentVsyncRequests) {
  auto mock_choreographer =
      std::make_shared<InMemoryAndroidChoreographerProvider>();
  auto waiter = std::make_shared<AndroidVsyncWaiter>(mock_choreographer);

  std::atomic<int> completed_count = 0;
  waiter->SetVsyncResultCallback(
      [&](intptr_t baton, int64_t start, int64_t target) {
        completed_count.fetch_add(1, std::memory_order_relaxed);
      });

  constexpr int kThreads = 8;
  constexpr int kRequestsPerThread = 50;

  std::vector<std::thread> threads;
  threads.reserve(kThreads);

  for (int t = 0; t < kThreads; ++t) {
    threads.emplace_back([waiter, t]() {
      for (int i = 0; i < kRequestsPerThread; ++i) {
        intptr_t baton = (t * 1000) + i;
        waiter->AsyncWaitForVsync(baton);
      }
    });
  }

  for (auto& t : threads) {
    t.join();
  }

  EXPECT_EQ(waiter->GetVsyncRequestCount(),
            static_cast<size_t>(kThreads * kRequestsPerThread));
  EXPECT_EQ(mock_choreographer->GetPendingCallbackCount(),
            static_cast<size_t>(kThreads * kRequestsPerThread));

  mock_choreographer->TriggerPendingCallbacks(300000000LL);
  EXPECT_EQ(completed_count.load(), kThreads * kRequestsPerThread);
  EXPECT_EQ(waiter->GetVsyncDeliveredCount(),
            static_cast<size_t>(kThreads * kRequestsPerThread));
}

TEST(AndroidVsyncWaiterTest, FramePacingNaNAndInfiniteRefreshRates) {
  // Quiet NaN should default to 60Hz
  double nan_hz = std::numeric_limits<double>::quiet_NaN();
  auto info_nan = AndroidVsyncWaiter::ComputeFramePacing(1000000LL, nan_hz);
  EXPECT_DOUBLE_EQ(info_nan.refresh_rate_hz, 60.0);
  EXPECT_EQ(info_nan.refresh_period_nanos, 16666666LL);

  // Positive infinity should default to 60Hz
  double inf_hz = std::numeric_limits<double>::infinity();
  auto info_inf = AndroidVsyncWaiter::ComputeFramePacing(1000000LL, inf_hz);
  EXPECT_DOUBLE_EQ(info_inf.refresh_rate_hz, 60.0);
  EXPECT_EQ(info_inf.refresh_period_nanos, 16666666LL);

  // Negative infinity should default to 60Hz
  double neg_inf_hz = -std::numeric_limits<double>::infinity();
  auto info_neg_inf =
      AndroidVsyncWaiter::ComputeFramePacing(1000000LL, neg_inf_hz);
  EXPECT_DOUBLE_EQ(info_neg_inf.refresh_rate_hz, 60.0);
  EXPECT_EQ(info_neg_inf.refresh_period_nanos, 16666666LL);

  // Negative values should default to 60Hz
  auto info_neg = AndroidVsyncWaiter::ComputeFramePacing(1000000LL, -144.0);
  EXPECT_DOUBLE_EQ(info_neg.refresh_rate_hz, 60.0);

  // Unreasonably large rate should clamp to 1000.0Hz
  auto info_extreme =
      AndroidVsyncWaiter::ComputeFramePacing(1000000LL, 1000000.0);
  EXPECT_DOUBLE_EQ(info_extreme.refresh_rate_hz, 1000.0);
  EXPECT_EQ(info_extreme.refresh_period_nanos, 1000000LL);
}

TEST(AndroidVsyncWaiterTest, NotifyVsyncTestingHookAndEnginePropagation) {
  auto mock_choreographer =
      std::make_shared<InMemoryAndroidChoreographerProvider>();
  auto waiter = std::make_shared<AndroidVsyncWaiter>(mock_choreographer);

  auto dummy_engine =
      reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(0xABCD);
  waiter->SetEngine(dummy_engine);
  EXPECT_EQ(waiter->GetEngine(), dummy_engine);

  bool hook_invoked = false;
  intptr_t received_baton = 0;
  uint64_t received_start = 0;
  uint64_t received_target = 0;

  waiter->SetNotifyVsyncFnForTesting(
      [&](FLUTTER_API_SYMBOL(FlutterEngine) engine, intptr_t baton,
          uint64_t start, uint64_t target) {
        EXPECT_EQ(engine, dummy_engine);
        hook_invoked = true;
        received_baton = baton;
        received_start = start;
        received_target = target;
        return kSuccess;
      });

  EXPECT_TRUE(waiter->AsyncWaitForVsync(4321));
  mock_choreographer->TriggerPendingCallbacks(20000000LL);

  EXPECT_TRUE(hook_invoked);
  EXPECT_EQ(received_baton, 4321);
  EXPECT_EQ(received_start, 20000000ULL);
  EXPECT_EQ(received_target, 20000000ULL + 16666666ULL);
}

TEST(AndroidVsyncWaiterTest, SharedFromThisSafetyWithoutSharedPtr) {
  // Stack allocation without shared_ptr should not crash with bad_weak_ptr
  auto mock_choreographer =
      std::make_shared<InMemoryAndroidChoreographerProvider>();
  AndroidVsyncWaiter stack_waiter(mock_choreographer);

  // AsyncWaitForVsync catches std::bad_weak_ptr and falls back safely
  EXPECT_TRUE(stack_waiter.AsyncWaitForVsync(9999));
  EXPECT_EQ(stack_waiter.GetVsyncDeliveredCount(), 1u);
}

TEST(AndroidVsyncWaiterTest, ConcurrentProviderReplacementInWaiter) {
  auto waiter = std::make_shared<AndroidVsyncWaiter>();
  constexpr int kThreads = 8;
  constexpr int kOpsPerThread = 500;
  std::vector<std::thread> threads;
  threads.reserve(kThreads);

  for (int i = 0; i < kThreads; ++i) {
    threads.emplace_back([waiter, i]() {
      for (int j = 0; j < kOpsPerThread; ++j) {
        if (i % 2 == 0) {
          auto mock_provider =
              std::make_shared<InMemoryAndroidChoreographerProvider>();
          waiter->SetChoreographerProvider(mock_provider);
        } else {
          auto provider = waiter->GetChoreographerProvider();
          EXPECT_NE(provider, nullptr);
        }
      }
    });
  }

  for (auto& t : threads) {
    t.join();
  }
}

TEST(AndroidVsyncWaiterTest, NDKCallback32BitCompatibility) {
  // Verify that AChoreographer_frameCallback accepts long frameTimeNanos
  // matching Android NDK API 24-28 specification on 32-bit and 64-bit
  // platforms.
  static_assert(
      std::is_same_v<AChoreographer_frameCallback, void (*)(long, void*)>);
  static_assert(
      std::is_same_v<AChoreographer_frameCallback64, void (*)(int64_t, void*)>);

  // Verify that long frame times (e.g. 32-bit long integer) promote safely
  long sample_frame_time = 12345678L;
  int64_t promoted = static_cast<int64_t>(sample_frame_time);
  EXPECT_EQ(promoted, 12345678LL);
}

TEST(AndroidVsyncWaiterTest, UpdateRefreshRateClampingAndNaNValidation) {
  auto waiter = std::make_shared<AndroidVsyncWaiter>();

  // NaN should clamp to 60.0
  waiter->UpdateRefreshRate(std::numeric_limits<double>::quiet_NaN());
  EXPECT_DOUBLE_EQ(waiter->GetRefreshRate(), 60.0);
  EXPECT_EQ(waiter->GetRefreshPeriodNanos(), 16666666LL);

  // Positive infinity should clamp to 60.0
  waiter->UpdateRefreshRate(std::numeric_limits<double>::infinity());
  EXPECT_DOUBLE_EQ(waiter->GetRefreshRate(), 60.0);
  EXPECT_EQ(waiter->GetRefreshPeriodNanos(), 16666666LL);

  // Negative infinity should clamp to 60.0
  waiter->UpdateRefreshRate(-std::numeric_limits<double>::infinity());
  EXPECT_DOUBLE_EQ(waiter->GetRefreshRate(), 60.0);
  EXPECT_EQ(waiter->GetRefreshPeriodNanos(), 16666666LL);

  // Zero should clamp to 60.0
  waiter->UpdateRefreshRate(0.0);
  EXPECT_DOUBLE_EQ(waiter->GetRefreshRate(), 60.0);

  // Negative rate should clamp to 60.0
  waiter->UpdateRefreshRate(-120.0);
  EXPECT_DOUBLE_EQ(waiter->GetRefreshRate(), 60.0);

  // Unreasonably large rate should clamp to 1000.0Hz
  waiter->UpdateRefreshRate(1000000.0);
  EXPECT_DOUBLE_EQ(waiter->GetRefreshRate(), 1000.0);
  EXPECT_EQ(waiter->GetRefreshPeriodNanos(), 1000000LL);

  // Unreasonably small positive rate should clamp to 1.0Hz
  waiter->UpdateRefreshRate(0.0001);
  EXPECT_DOUBLE_EQ(waiter->GetRefreshRate(), 1.0);
  EXPECT_EQ(waiter->GetRefreshPeriodNanos(), 1000000000LL);
}

TEST(AndroidVsyncWaiterTest, NotifyVsyncToEngineValidation) {
  auto dummy_engine =
      reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(0xBEEF);

  // Null engine rejected
  EXPECT_EQ(AndroidVsyncWaiter::NotifyVsyncToEngine(nullptr, 1, 1000, 2000),
            kInvalidArguments);

  // Zero start time rejected
  EXPECT_EQ(AndroidVsyncWaiter::NotifyVsyncToEngine(dummy_engine, 1, 0, 2000),
            kInvalidArguments);

  // Target <= start rejected
  EXPECT_EQ(
      AndroidVsyncWaiter::NotifyVsyncToEngine(dummy_engine, 1, 2000, 1000),
      kInvalidArguments);
  EXPECT_EQ(
      AndroidVsyncWaiter::NotifyVsyncToEngine(dummy_engine, 1, 2000, 2000),
      kInvalidArguments);
}

TEST(AndroidVsyncWaiterTest, ConsumePendingVsyncNotifiesJvmInvoker) {
  auto mock_choreographer =
      std::make_shared<InMemoryAndroidChoreographerProvider>();
  auto mock_invoker = std::make_shared<MockVsyncJvmInvoker>();
  auto waiter =
      std::make_shared<AndroidVsyncWaiter>(mock_choreographer, mock_invoker);

  bool jvm_on_vsync_called = false;
  int64_t received_start = 0;
  int64_t received_target = 0;

  EXPECT_CALL(*mock_invoker,
              InvokeVoidMethod(::testing::StrEq("onVsync"),
                               ::testing::StrEq("(JJ)V"), ::testing::_))
      .WillOnce([&](const std::string& method, const std::string& sig,
                    const std::vector<uint8_t>& payload) {
        jvm_on_vsync_called = true;
        EXPECT_EQ(payload.size(), 16u);
        std::memcpy(&received_start, payload.data(), sizeof(int64_t));
        std::memcpy(&received_target, payload.data() + sizeof(int64_t),
                    sizeof(int64_t));
        return true;
      });

  EXPECT_TRUE(waiter->AsyncWaitForVsync(1234));
  mock_choreographer->TriggerPendingCallbacks(50000000LL);

  EXPECT_TRUE(jvm_on_vsync_called);
  EXPECT_EQ(received_start, 50000000LL);
  EXPECT_EQ(received_target, 50000000LL + 16666666LL);
}

}  // namespace testing
}  // namespace android
}  // namespace flutter
