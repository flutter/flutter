// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <future>
#include <thread>
#include <vector>

#include "flutter/shell/platform/android/android_surface_control.h"
#include "flutter/shell/platform/android/os_library_loader.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"

namespace flutter {
namespace android {
namespace testing {

using ::testing::_;
using ::testing::Return;

namespace {

static int g_mock_sc_release_count = 0;
static int g_mock_tx_delete_count = 0;
static int g_mock_tx_apply_count = 0;

static void* MockCreateFromWindow(void* window, const char* debug_name) {
  if (!window) {
    return nullptr;
  }
  return reinterpret_cast<void*>(0x12340001);
}
static void* MockCreate(void* parent, const char* debug_name) {
  if (!parent) {
    return nullptr;
  }
  return reinterpret_cast<void*>(0x12340002);
}
static void MockAcquire(void* handle) {}
static void MockRelease(void* handle) {
  g_mock_sc_release_count++;
}
static void* MockTransactionCreate() {
  return reinterpret_cast<void*>(0x12340003);
}
static void MockTransactionDelete(void* tx) {
  g_mock_tx_delete_count++;
}
static void MockTransactionApply(void* tx) {
  g_mock_tx_apply_count++;
}
static void MockTransactionReparent(void* tx, void* sc, void* parent) {}
static void MockTransactionSetVisibility(void* tx, void* sc, int8_t vis) {}
static void MockTransactionSetZOrder(void* tx, void* sc, int32_t z) {}
static void MockTransactionSetBuffer(void* tx,
                                     void* sc,
                                     void* buffer,
                                     int fence) {}
static void MockTransactionSetGeometry(void* tx,
                                       void* sc,
                                       const void* src,
                                       const void* dst,
                                       int32_t transform) {}
static void MockTransactionSetDamageRegion(void* tx,
                                           void* sc,
                                           const void* rects,
                                           uint32_t count) {}
static void MockTransactionSetBufferAlpha(void* tx, void* sc, float alpha) {}
static void MockTransactionSetColor(void* tx,
                                    void* sc,
                                    float r,
                                    float g,
                                    float b,
                                    float a,
                                    int32_t dataspace) {}
static void MockTransactionSetOnComplete(void* tx,
                                         void* context,
                                         void (*func)(void*, void*)) {
  if (func) {
    func(context, reinterpret_cast<void*>(0x9999));
  }
}
static int64_t MockStatsGetLatchTime(void* stats) {
  return 123456789LL;
}
static int MockStatsGetPresentFenceFd(void* stats) {
  return -1;
}
static void MockStatsGetASurfaceControls(void* stats,
                                         void*** out_controls,
                                         size_t* out_size) {
  static void* dummy_controls[1] = {reinterpret_cast<void*>(0x12340001)};
  if (out_controls) {
    *out_controls = dummy_controls;
  }
  if (out_size) {
    *out_size = 1;
  }
}
static void MockStatsReleaseASurfaceControls(void** controls) {}
static int MockStatsGetPreviousReleaseFenceFd(void* stats,
                                              void* surface_control) {
  return -1;
}

}  // namespace

// =============================================================================
// Type & Data Structure Tests
// =============================================================================

TEST(AndroidSurfaceControlTest, RectUtilitiesAndEquality) {
  AndroidSurfaceControlRect rect = {10, 20, 110, 220};
  EXPECT_EQ(rect.left, 10);
  EXPECT_EQ(rect.top, 20);
  EXPECT_EQ(rect.right, 110);
  EXPECT_EQ(rect.bottom, 220);
  EXPECT_EQ(rect.Width(), 100);
  EXPECT_EQ(rect.Height(), 200);
  EXPECT_FALSE(rect.IsEmpty());

  AndroidSurfaceControlRect empty_rect = {100, 100, 50, 50};
  EXPECT_TRUE(empty_rect.IsEmpty());

  AndroidSurfaceControlRect same = {10, 20, 110, 220};
  AndroidSurfaceControlRect diff = {10, 20, 110, 221};
  EXPECT_EQ(rect, same);
  EXPECT_NE(rect, diff);
}

TEST(AndroidSurfaceControlTest, StatsEquality) {
  AndroidSurfaceControlStats stats1 = {3, 1000000LL, 900000LL};
  AndroidSurfaceControlStats stats2 = {3, 1000000LL, 900000LL};
  AndroidSurfaceControlStats stats3 = {4, 1000000LL, 900000LL};

  EXPECT_EQ(stats1, stats2);
  EXPECT_NE(stats1, stats3);
}

TEST(AndroidSurfaceControlTest, ColorEquality) {
  AndroidSurfaceControlColor color1 = {1.0f, 0.5f, 0.25f, 1.0f};
  AndroidSurfaceControlColor color2 = {1.0f, 0.5f, 0.25f, 1.0f};
  AndroidSurfaceControlColor color3 = {1.0f, 0.5f, 0.25f, 0.5f};

  EXPECT_EQ(color1, color2);
  EXPECT_NE(color1, color3);
}

TEST(AndroidSurfaceControlTest, StateEquality) {
  AndroidSurfaceControlState state1;
  state1.id = 1;
  state1.debug_name = "test_surface";
  state1.visibility = AndroidSurfaceControlVisibility::kShow;
  state1.z_order = 2;
  state1.alpha = 0.8f;

  AndroidSurfaceControlState state2 = state1;
  EXPECT_EQ(state1, state2);

  state2.z_order = 3;
  EXPECT_NE(state1, state2);
}

// =============================================================================
// InMemory Provider & Surface Control Tests
// =============================================================================

TEST(AndroidSurfaceControlTest, InMemoryProviderAvailabilityAndFailure) {
  auto provider = std::make_shared<InMemoryAndroidSurfaceControlProvider>();
  EXPECT_TRUE(provider->IsAvailable());

  provider->SetAvailable(false);
  EXPECT_FALSE(provider->IsAvailable());
  EXPECT_EQ(provider->CreateFromWindow(reinterpret_cast<void*>(0x1)), nullptr);
  EXPECT_EQ(provider->CreateTransaction(), nullptr);

  provider->SetAvailable(true);
  provider->SetCreationFailure(true);
  EXPECT_EQ(provider->CreateFromWindow(reinterpret_cast<void*>(0x1)), nullptr);
  EXPECT_EQ(provider->CreateTransaction(), nullptr);
}

TEST(AndroidSurfaceControlTest, InMemorySurfaceControlCreationAndHierarchy) {
  auto provider = std::make_shared<InMemoryAndroidSurfaceControlProvider>();

  void* mock_window = reinterpret_cast<void*>(0xCAFE);
  auto root = provider->CreateFromWindow(mock_window, "root_surface");
  ASSERT_NE(root, nullptr);
  EXPECT_TRUE(root->IsValid());
  EXPECT_NE(root->GetHandle(), nullptr);
  EXPECT_EQ(root->GetDebugName(), "root_surface");
  EXPECT_EQ(root->GetParentHandle(), nullptr);
  EXPECT_EQ(root->GetParentId(), 0u);
  EXPECT_EQ(provider->GetActiveSurfaceControlCount(), 1u);

  auto child = provider->Create(root.get(), "child_surface");
  ASSERT_NE(child, nullptr);
  EXPECT_TRUE(child->IsValid());
  EXPECT_EQ(child->GetDebugName(), "child_surface");
  EXPECT_EQ(child->GetParentHandle(), root->GetHandle());
  EXPECT_EQ(child->GetParentId(), root->GetId());
  EXPECT_EQ(provider->GetActiveSurfaceControlCount(), 2u);

  // Test reference counting
  child->Acquire();
  child->Release();
  EXPECT_TRUE(child->IsValid());

  // Test remove from parent
  EXPECT_TRUE(child->RemoveFromParent());
  EXPECT_EQ(child->GetParentHandle(), nullptr);
  EXPECT_EQ(child->GetParentId(), 0u);
}

TEST(AndroidSurfaceControlTest, InMemoryTransactionAtomicCommitAndCallbacks) {
  auto provider = std::make_shared<InMemoryAndroidSurfaceControlProvider>();

  auto root = provider->CreateFromWindow(reinterpret_cast<void*>(0x1000),
                                         "root_control");
  auto child = provider->Create(root.get(), "child_control");
  ASSERT_NE(root, nullptr);
  ASSERT_NE(child, nullptr);

  auto transaction = provider->CreateTransaction();
  ASSERT_NE(transaction, nullptr);
  EXPECT_TRUE(transaction->IsValid());

  EXPECT_TRUE(transaction->SetVisibility(
      child.get(), AndroidSurfaceControlVisibility::kShow));
  EXPECT_TRUE(transaction->SetZOrder(child.get(), 10));

  AndroidSurfaceControlRect src = {0, 0, 1920, 1080};
  AndroidSurfaceControlRect dst = {0, 0, 1280, 720};
  EXPECT_TRUE(transaction->SetGeometry(
      child.get(), src, dst, AndroidSurfaceControlTransform::kRotate90));

  std::vector<AndroidSurfaceControlRect> damage = {{10, 10, 100, 100}};
  EXPECT_TRUE(transaction->SetDamageRegion(child.get(), damage));

  int dummy_buf = 123;
  EXPECT_TRUE(transaction->SetBuffer(child.get(), &dummy_buf, -1));
  EXPECT_TRUE(transaction->SetBufferAlpha(child.get(), 0.65f));
  EXPECT_TRUE(transaction->SetColor(child.get(), 0.1f, 0.2f, 0.3f, 0.9f));

  bool callback_fired = false;
  AndroidSurfaceControlStats captured_stats;
  EXPECT_TRUE(
      transaction->SetOnComplete([&](const AndroidSurfaceControlStats& stats) {
        callback_fired = true;
        captured_stats = stats;
      }));

  EXPECT_EQ(provider->GetApplyCount(), 0u);
  EXPECT_TRUE(transaction->Apply());
  EXPECT_EQ(provider->GetApplyCount(), 1u);
  EXPECT_TRUE(callback_fired);

  auto state_opt = provider->GetSurfaceState(child->GetId());
  ASSERT_TRUE(state_opt.has_value());
  if (state_opt.has_value()) {
    EXPECT_EQ(state_opt->visibility, AndroidSurfaceControlVisibility::kShow);
    EXPECT_EQ(state_opt->z_order, 10);
    EXPECT_EQ(state_opt->source_rect, src);
    EXPECT_EQ(state_opt->destination_rect, dst);
    EXPECT_EQ(state_opt->transform, AndroidSurfaceControlTransform::kRotate90);
    EXPECT_EQ(state_opt->damage_region, damage);
    EXPECT_EQ(state_opt->buffer_handle, &dummy_buf);
    EXPECT_FLOAT_EQ(state_opt->alpha, 0.65f);
    EXPECT_FLOAT_EQ(state_opt->color.r, 0.1f);
    EXPECT_FLOAT_EQ(state_opt->color.g, 0.2f);
    EXPECT_FLOAT_EQ(state_opt->color.b, 0.3f);
    EXPECT_FLOAT_EQ(state_opt->color.a, 0.9f);
  }
}

TEST(AndroidSurfaceControlTest, InMemoryTransactionReparenting) {
  auto provider = std::make_shared<InMemoryAndroidSurfaceControlProvider>();

  auto root1 =
      provider->CreateFromWindow(reinterpret_cast<void*>(0x1), "root1");
  auto root2 =
      provider->CreateFromWindow(reinterpret_cast<void*>(0x2), "root2");
  auto child = provider->Create(root1.get(), "child");
  ASSERT_NE(root1, nullptr);
  ASSERT_NE(root2, nullptr);
  ASSERT_NE(child, nullptr);

  EXPECT_EQ(child->GetParentId(), root1->GetId());

  auto tx = provider->CreateTransaction();
  ASSERT_NE(tx, nullptr);
  EXPECT_TRUE(tx->Reparent(child.get(), root2.get()));
  EXPECT_TRUE(tx->Apply());

  auto state = provider->GetSurfaceState(child->GetId());
  ASSERT_TRUE(state.has_value());
  if (state.has_value()) {
    EXPECT_EQ(state->parent_id, root2->GetId());
    EXPECT_EQ(state->parent_handle, root2->GetHandle());
  }
}

// =============================================================================
// Default Provider & Dynamic Virtualization Tests
// =============================================================================

TEST(AndroidSurfaceControlTest, DefaultProviderWithoutLibandroid) {
  auto mock_loader = std::make_shared<MockOSLibraryLoader>();
  auto provider =
      std::make_shared<DefaultAndroidSurfaceControlProvider>(mock_loader);

  // When libandroid.so is unavailable, provider safely reports unavailable.
  EXPECT_FALSE(provider->IsAvailable());
  EXPECT_EQ(provider->CreateFromWindow(reinterpret_cast<void*>(0x1)), nullptr);
  EXPECT_EQ(provider->Create(nullptr), nullptr);
  EXPECT_EQ(provider->CreateTransaction(), nullptr);
  EXPECT_FALSE(provider->ApplyTransaction(nullptr));
}

TEST(AndroidSurfaceControlTest, DefaultProviderWithMockSymbols) {
  auto mock_loader = std::make_shared<MockOSLibraryLoader>();
  mock_loader->SetSymbol("libandroid.so", "ASurfaceControl_createFromWindow",
                         reinterpret_cast<void*>(MockCreateFromWindow));
  mock_loader->SetSymbol("libandroid.so", "ASurfaceControl_create",
                         reinterpret_cast<void*>(MockCreate));
  mock_loader->SetSymbol("libandroid.so", "ASurfaceControl_acquire",
                         reinterpret_cast<void*>(MockAcquire));
  mock_loader->SetSymbol("libandroid.so", "ASurfaceControl_release",
                         reinterpret_cast<void*>(MockRelease));
  mock_loader->SetSymbol("libandroid.so", "ASurfaceTransaction_create",
                         reinterpret_cast<void*>(MockTransactionCreate));
  mock_loader->SetSymbol("libandroid.so", "ASurfaceTransaction_delete",
                         reinterpret_cast<void*>(MockTransactionDelete));
  mock_loader->SetSymbol("libandroid.so", "ASurfaceTransaction_apply",
                         reinterpret_cast<void*>(MockTransactionApply));
  mock_loader->SetSymbol("libandroid.so", "ASurfaceTransaction_reparent",
                         reinterpret_cast<void*>(MockTransactionReparent));
  mock_loader->SetSymbol("libandroid.so", "ASurfaceTransaction_setVisibility",
                         reinterpret_cast<void*>(MockTransactionSetVisibility));
  mock_loader->SetSymbol("libandroid.so", "ASurfaceTransaction_setZOrder",
                         reinterpret_cast<void*>(MockTransactionSetZOrder));
  mock_loader->SetSymbol("libandroid.so", "ASurfaceTransaction_setBuffer",
                         reinterpret_cast<void*>(MockTransactionSetBuffer));
  mock_loader->SetSymbol("libandroid.so", "ASurfaceTransaction_setGeometry",
                         reinterpret_cast<void*>(MockTransactionSetGeometry));
  mock_loader->SetSymbol(
      "libandroid.so", "ASurfaceTransaction_setDamageRegion",
      reinterpret_cast<void*>(MockTransactionSetDamageRegion));
  mock_loader->SetSymbol(
      "libandroid.so", "ASurfaceTransaction_setBufferAlpha",
      reinterpret_cast<void*>(MockTransactionSetBufferAlpha));
  mock_loader->SetSymbol("libandroid.so", "ASurfaceTransaction_setColor",
                         reinterpret_cast<void*>(MockTransactionSetColor));
  mock_loader->SetSymbol("libandroid.so", "ASurfaceTransaction_setOnComplete",
                         reinterpret_cast<void*>(MockTransactionSetOnComplete));
  mock_loader->SetSymbol(
      "libandroid.so", "ASurfaceTransactionStats_getPreviousReleaseFenceFd",
      reinterpret_cast<void*>(MockStatsGetPreviousReleaseFenceFd));
  mock_loader->SetSymbol("libandroid.so",
                         "ASurfaceTransactionStats_getLatchTime",
                         reinterpret_cast<void*>(MockStatsGetLatchTime));
  mock_loader->SetSymbol("libandroid.so",
                         "ASurfaceTransactionStats_getPresentFenceFd",
                         reinterpret_cast<void*>(MockStatsGetPresentFenceFd));
  mock_loader->SetSymbol("libandroid.so",
                         "ASurfaceTransactionStats_getASurfaceControls",
                         reinterpret_cast<void*>(MockStatsGetASurfaceControls));
  mock_loader->SetSymbol(
      "libandroid.so", "ASurfaceTransactionStats_releaseASurfaceControls",
      reinterpret_cast<void*>(MockStatsReleaseASurfaceControls));

  auto provider =
      std::make_shared<DefaultAndroidSurfaceControlProvider>(mock_loader);
  EXPECT_TRUE(provider->IsAvailable());

  // Null window returns nullptr
  EXPECT_EQ(provider->CreateFromWindow(nullptr), nullptr);

  void* fake_window = reinterpret_cast<void*>(0x55551234);
  auto sc = provider->CreateFromWindow(fake_window, "test_sc");
  ASSERT_NE(sc, nullptr);
  EXPECT_TRUE(sc->IsValid());

  auto tx = provider->CreateTransaction();
  ASSERT_NE(tx, nullptr);
  EXPECT_TRUE(tx->IsValid());

  // Test invalid rect rejection
  EXPECT_FALSE(tx->SetGeometry(sc.get(), {0, 0, 0, 0}, {0, 0, 100, 100}));
  EXPECT_FALSE(tx->SetGeometry(sc.get(), {100, 100, 50, 50}, {0, 0, 100, 100}));
  // Valid rect
  EXPECT_TRUE(tx->SetGeometry(sc.get(), {0, 0, 100, 100}, {0, 0, 100, 100}));

  // Test alpha validation & clamping
  EXPECT_FALSE(
      tx->SetBufferAlpha(sc.get(), std::numeric_limits<float>::quiet_NaN()));
  EXPECT_TRUE(tx->SetBufferAlpha(sc.get(), 1.5f));
  EXPECT_TRUE(tx->SetBufferAlpha(sc.get(), 0.5f));

  EXPECT_TRUE(tx->SetColor(sc.get(), 1.0f, 0.0f, 0.0f, 1.0f));

  bool on_complete_called = false;
  EXPECT_TRUE(tx->SetOnComplete([&](const AndroidSurfaceControlStats& stats) {
    on_complete_called = true;
    EXPECT_EQ(stats.latch_time_nanos, 123456789LL);
    EXPECT_EQ(stats.present_time_nanos, 123456789LL);
  }));

  EXPECT_TRUE(tx->Apply());
  EXPECT_TRUE(on_complete_called);
  // Re-apply fails because handle is invalidated
  EXPECT_FALSE(tx->Apply());
}

TEST(AndroidSurfaceControlTest,
     DefaultSurfaceControlRefCountingAndRemoveFromParent) {
  g_mock_sc_release_count = 0;
  g_mock_tx_delete_count = 0;
  g_mock_tx_apply_count = 0;

  auto mock_loader = std::make_shared<MockOSLibraryLoader>();
  mock_loader->SetSymbol("libandroid.so", "ASurfaceControl_createFromWindow",
                         reinterpret_cast<void*>(MockCreateFromWindow));
  mock_loader->SetSymbol("libandroid.so", "ASurfaceControl_create",
                         reinterpret_cast<void*>(MockCreate));
  mock_loader->SetSymbol("libandroid.so", "ASurfaceControl_acquire",
                         reinterpret_cast<void*>(MockAcquire));
  mock_loader->SetSymbol("libandroid.so", "ASurfaceControl_release",
                         reinterpret_cast<void*>(MockRelease));
  mock_loader->SetSymbol("libandroid.so", "ASurfaceTransaction_create",
                         reinterpret_cast<void*>(MockTransactionCreate));
  mock_loader->SetSymbol("libandroid.so", "ASurfaceTransaction_delete",
                         reinterpret_cast<void*>(MockTransactionDelete));
  mock_loader->SetSymbol("libandroid.so", "ASurfaceTransaction_apply",
                         reinterpret_cast<void*>(MockTransactionApply));
  mock_loader->SetSymbol("libandroid.so", "ASurfaceTransaction_reparent",
                         reinterpret_cast<void*>(MockTransactionReparent));

  auto provider =
      std::make_shared<DefaultAndroidSurfaceControlProvider>(mock_loader);
  void* fake_window = reinterpret_cast<void*>(0x55551234);
  auto sc = provider->CreateFromWindow(fake_window, "parent_sc");
  ASSERT_NE(sc, nullptr);
  auto child = provider->Create(sc.get(), "child_sc");
  ASSERT_NE(child, nullptr);
  EXPECT_EQ(child->GetParentHandle(), sc->GetHandle());

  // Acquire and Release: ref_count_ goes 1 -> 2 -> 1, so no native release yet.
  child->Acquire();
  child->Release();
  EXPECT_TRUE(child->IsValid());
  EXPECT_EQ(g_mock_sc_release_count, 0);

  // Releasing remaining reference (ref_count_ drops to 0): invokes native
  // release.
  child->Release();
  EXPECT_FALSE(child->IsValid());
  EXPECT_EQ(g_mock_sc_release_count, 1);

  // Destructor of already-released surface control does not double-release.
  child.reset();
  EXPECT_EQ(g_mock_sc_release_count, 1);

  // Reparent test with fresh child
  auto child2 = provider->Create(sc.get(), "child2_sc");
  ASSERT_NE(child2, nullptr);
  EXPECT_TRUE(child2->RemoveFromParent());
  EXPECT_EQ(child2->GetParentHandle(), nullptr);
  EXPECT_EQ(child2->GetParentId(), 0u);
}

TEST(AndroidSurfaceControlTest,
     DefaultTransactionDeletedOnApplyAndDestruction) {
  g_mock_tx_delete_count = 0;
  g_mock_tx_apply_count = 0;

  auto mock_loader = std::make_shared<MockOSLibraryLoader>();
  mock_loader->SetSymbol("libandroid.so", "ASurfaceControl_createFromWindow",
                         reinterpret_cast<void*>(MockCreateFromWindow));
  mock_loader->SetSymbol("libandroid.so", "ASurfaceControl_release",
                         reinterpret_cast<void*>(MockRelease));
  mock_loader->SetSymbol("libandroid.so", "ASurfaceTransaction_create",
                         reinterpret_cast<void*>(MockTransactionCreate));
  mock_loader->SetSymbol("libandroid.so", "ASurfaceTransaction_delete",
                         reinterpret_cast<void*>(MockTransactionDelete));
  mock_loader->SetSymbol("libandroid.so", "ASurfaceTransaction_apply",
                         reinterpret_cast<void*>(MockTransactionApply));

  auto provider =
      std::make_shared<DefaultAndroidSurfaceControlProvider>(mock_loader);

  // 1. Transaction is deleted immediately upon Apply()
  {
    auto tx = provider->CreateTransaction();
    ASSERT_NE(tx, nullptr);
    EXPECT_TRUE(tx->Apply());
    EXPECT_EQ(g_mock_tx_apply_count, 1);
    EXPECT_EQ(g_mock_tx_delete_count, 1);
  }
  // Destructor does not double delete
  EXPECT_EQ(g_mock_tx_delete_count, 1);

  // 2. Unapplied transaction is deleted in destructor
  {
    auto tx2 = provider->CreateTransaction();
    ASSERT_NE(tx2, nullptr);
  }
  EXPECT_EQ(g_mock_tx_delete_count, 2);
}

// =============================================================================
// Concurrency & Multi-threading Tests
// =============================================================================

TEST(AndroidSurfaceControlTest, ThreadSafeConcurrentInMemoryOperations) {
  auto provider = std::make_shared<InMemoryAndroidSurfaceControlProvider>();

  constexpr int kThreadCount = 8;
  constexpr int kIterationsPerThread = 25;

  std::vector<std::future<void>> futures;
  futures.reserve(kThreadCount);

  std::vector<std::vector<std::unique_ptr<AndroidSurfaceControl>>> all_controls(
      kThreadCount);

  for (int t = 0; t < kThreadCount; ++t) {
    futures.push_back(std::async(std::launch::async, [provider, t,
                                                      &all_controls]() {
      all_controls[t].reserve(kIterationsPerThread);
      for (int i = 0; i < kIterationsPerThread; ++i) {
        void* window_handle = reinterpret_cast<void*>(0x1000 + (t * 100) + i);
        auto sc = provider->CreateFromWindow(window_handle,
                                             "thread_sc_" + std::to_string(t));
        ASSERT_NE(sc, nullptr);

        auto tx = provider->CreateTransaction();
        ASSERT_NE(tx, nullptr);

        EXPECT_TRUE(tx->SetVisibility(sc.get(),
                                      AndroidSurfaceControlVisibility::kShow));
        EXPECT_TRUE(tx->SetZOrder(sc.get(), t));

        AndroidSurfaceControlRect src = {0, 0, 100, 100};
        AndroidSurfaceControlRect dst = {0, 0, 200, 200};
        EXPECT_TRUE(tx->SetGeometry(sc.get(), src, dst));
        EXPECT_TRUE(tx->Apply());

        auto state = provider->GetSurfaceState(sc->GetId());
        ASSERT_TRUE(state.has_value());
        EXPECT_EQ(state->z_order, t);

        all_controls[t].push_back(std::move(sc));
      }
    }));
  }

  for (auto& f : futures) {
    f.get();
  }

  EXPECT_EQ(provider->GetActiveSurfaceControlCount(),
            static_cast<size_t>(kThreadCount * kIterationsPerThread));
  EXPECT_EQ(provider->GetApplyCount(),
            static_cast<size_t>(kThreadCount * kIterationsPerThread));
}

}  // namespace testing
}  // namespace android
}  // namespace flutter
