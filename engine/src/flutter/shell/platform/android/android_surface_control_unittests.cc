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

// Mock ASurfaceControl C function pointer signatures
static void* g_mock_asurface_control_create_from_window =
    reinterpret_cast<void*>(0x1111);
static void* g_mock_asurface_control_create = reinterpret_cast<void*>(0x2222);
static void* g_mock_asurface_control_acquire = reinterpret_cast<void*>(0x3333);
static void* g_mock_asurface_control_release = reinterpret_cast<void*>(0x4444);
static void* g_mock_asurface_transaction_create =
    reinterpret_cast<void*>(0x5555);
static void* g_mock_asurface_transaction_delete =
    reinterpret_cast<void*>(0x6666);
static void* g_mock_asurface_transaction_apply =
    reinterpret_cast<void*>(0x7777);
static void* g_mock_asurface_transaction_reparent =
    reinterpret_cast<void*>(0x8888);
static void* g_mock_asurface_transaction_set_visibility =
    reinterpret_cast<void*>(0x9999);
static void* g_mock_asurface_transaction_set_z_order =
    reinterpret_cast<void*>(0xAAAA);
static void* g_mock_asurface_transaction_set_buffer =
    reinterpret_cast<void*>(0xBBBB);
static void* g_mock_asurface_transaction_set_geometry =
    reinterpret_cast<void*>(0xCCCC);
static void* g_mock_asurface_transaction_set_damage_region =
    reinterpret_cast<void*>(0xDDDD);
static void* g_mock_asurface_transaction_set_buffer_alpha =
    reinterpret_cast<void*>(0xEEEE);
static void* g_mock_asurface_transaction_set_color =
    reinterpret_cast<void*>(0xFFFF);
static void* g_mock_asurface_transaction_set_on_complete =
    reinterpret_cast<void*>(0x1234);
static void* g_mock_asurface_transaction_stats_get_release_fence =
    reinterpret_cast<void*>(0x5678);

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
                         g_mock_asurface_control_create_from_window);
  mock_loader->SetSymbol("libandroid.so", "ASurfaceControl_create",
                         g_mock_asurface_control_create);
  mock_loader->SetSymbol("libandroid.so", "ASurfaceControl_acquire",
                         g_mock_asurface_control_acquire);
  mock_loader->SetSymbol("libandroid.so", "ASurfaceControl_release",
                         g_mock_asurface_control_release);
  mock_loader->SetSymbol("libandroid.so", "ASurfaceTransaction_create",
                         g_mock_asurface_transaction_create);
  mock_loader->SetSymbol("libandroid.so", "ASurfaceTransaction_delete",
                         g_mock_asurface_transaction_delete);
  mock_loader->SetSymbol("libandroid.so", "ASurfaceTransaction_apply",
                         g_mock_asurface_transaction_apply);
  mock_loader->SetSymbol("libandroid.so", "ASurfaceTransaction_reparent",
                         g_mock_asurface_transaction_reparent);
  mock_loader->SetSymbol("libandroid.so", "ASurfaceTransaction_setVisibility",
                         g_mock_asurface_transaction_set_visibility);
  mock_loader->SetSymbol("libandroid.so", "ASurfaceTransaction_setZOrder",
                         g_mock_asurface_transaction_set_z_order);
  mock_loader->SetSymbol("libandroid.so", "ASurfaceTransaction_setBuffer",
                         g_mock_asurface_transaction_set_buffer);
  mock_loader->SetSymbol("libandroid.so", "ASurfaceTransaction_setGeometry",
                         g_mock_asurface_transaction_set_geometry);
  mock_loader->SetSymbol("libandroid.so", "ASurfaceTransaction_setDamageRegion",
                         g_mock_asurface_transaction_set_damage_region);
  mock_loader->SetSymbol("libandroid.so", "ASurfaceTransaction_setBufferAlpha",
                         g_mock_asurface_transaction_set_buffer_alpha);
  mock_loader->SetSymbol("libandroid.so", "ASurfaceTransaction_setColor",
                         g_mock_asurface_transaction_set_color);
  mock_loader->SetSymbol("libandroid.so", "ASurfaceTransaction_setOnComplete",
                         g_mock_asurface_transaction_set_on_complete);
  mock_loader->SetSymbol("libandroid.so",
                         "ASurfaceTransactionStats_getPreviousReleaseFenceFd",
                         g_mock_asurface_transaction_stats_get_release_fence);

  auto provider =
      std::make_shared<DefaultAndroidSurfaceControlProvider>(mock_loader);
  EXPECT_TRUE(provider->IsAvailable());
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
