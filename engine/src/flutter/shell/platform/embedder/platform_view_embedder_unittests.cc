// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/platform_view_embedder.h"

#include "flutter/flow/frame_timings.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/fml/time/time_delta.h"
#include "flutter/fml/time/time_point.h"
#include "flutter/shell/common/thread_host.h"
#include "flutter/testing/post_task_sync.h"
#include "flutter/testing/testing.h"

#include "gmock/gmock.h"
#include "gtest/gtest.h"

#include <atomic>
#include <chrono>
#include <cstring>
#include <thread>

namespace flutter {
namespace testing {
namespace {
// One frame interval at 60 Hz: 1'000'000 us / 60 frames, rounded. Only used as
// a plausible vsync target time; nothing in these tests waits for it.
constexpr fml::TimeDelta kFrameInterval =
    fml::TimeDelta::FromMicroseconds(16667);

class MockDelegate : public PlatformView::Delegate {
 public:
  MOCK_METHOD(void,
              OnPlatformViewCreated,
              (std::unique_ptr<Surface>),
              (override));
  MOCK_METHOD(void, OnPlatformViewDestroyed, (), (override));
  MOCK_METHOD(void, OnPlatformViewScheduleFrame, (), (override));
  MOCK_METHOD(void,
              OnPlatformViewAddView,
              (int64_t view_id,
               const ViewportMetrics& viewport_metrics,
               AddViewCallback callback),
              (override));
  MOCK_METHOD(void,
              OnPlatformViewRemoveView,
              (int64_t view_id, RemoveViewCallback callback),
              (override));
  MOCK_METHOD(void,
              OnPlatformViewSendViewFocusEvent,
              (const ViewFocusEvent& event),
              (override));
  MOCK_METHOD(void,
              OnPlatformViewSetNextFrameCallback,
              (const fml::closure& closure),
              (override));
  MOCK_METHOD(void,
              OnPlatformViewSetViewportMetrics,
              (int64_t view_id, const ViewportMetrics& metrics),
              (override));
  MOCK_METHOD(void,
              OnPlatformViewDispatchPlatformMessage,
              (std::unique_ptr<PlatformMessage> message),
              (override));
  MOCK_METHOD(void,
              OnPlatformViewDispatchPointerDataPacket,
              (std::unique_ptr<PointerDataPacket> packet),
              (override));
  MOCK_METHOD(HitTestResponse,
              OnPlatformViewHitTest,
              (int64_t view_id, const flutter::PointData offset),
              (override));
  MOCK_METHOD(void,
              OnPlatformViewDispatchSemanticsAction,
              (int64_t view_id,
               int32_t node_id,
               SemanticsAction action,
               fml::MallocMapping args),
              (override));
  MOCK_METHOD(void,
              OnPlatformViewSetSemanticsEnabled,
              (bool enabled),
              (override));
  MOCK_METHOD(void,
              OnPlatformViewSetAccessibilityFeatures,
              (int32_t flags),
              (override));
  MOCK_METHOD(void,
              OnPlatformViewRegisterTexture,
              (std::shared_ptr<Texture> texture),
              (override));
  MOCK_METHOD(void,
              OnPlatformViewUnregisterTexture,
              (int64_t texture_id),
              (override));
  MOCK_METHOD(void,
              OnPlatformViewMarkTextureFrameAvailable,
              (int64_t texture_id),
              (override));
  MOCK_METHOD(void,
              LoadDartDeferredLibrary,
              (intptr_t loading_unit_id,
               std::unique_ptr<const fml::Mapping> snapshot_data,
               std::unique_ptr<const fml::Mapping> snapshot_instructions),
              (override));
  MOCK_METHOD(void,
              LoadDartDeferredLibraryError,
              (intptr_t loading_unit_id,
               const std::string error_message,
               bool transient),
              (override));
  MOCK_METHOD(void,
              UpdateAssetResolverByType,
              (std::unique_ptr<AssetResolver> updated_asset_resolver,
               AssetResolver::AssetResolverType type),
              (override));
  MOCK_METHOD(const Settings&,
              OnPlatformViewGetSettings,
              (),
              (const, override));
  MOCK_METHOD(std::shared_ptr<fml::BasicTaskRunner>,
              OnPlatformViewGetShutdownSafeIOTaskRunner,
              (),
              (const, override));
};

class MockResponse : public PlatformMessageResponse {
 public:
  MOCK_METHOD(void, Complete, (std::unique_ptr<fml::Mapping> data), (override));
  MOCK_METHOD(void, CompleteEmpty, (), (override));
};

// An embedding that renders on its own and takes only the platform callbacks
// from PlatformViewEmbedder, the way the Android embedding does.
class SurfacelessPlatformViewEmbedder : public PlatformViewEmbedder {
 public:
  SurfacelessPlatformViewEmbedder(PlatformView::Delegate& delegate,
                                  const TaskRunners& task_runners,
                                  PlatformDispatchTable platform_dispatch_table)
      : PlatformViewEmbedder(delegate,
                             task_runners,
                             std::move(platform_dispatch_table)) {}
};
}  // namespace

TEST(PlatformViewEmbedderTest, HasPlatformMessageHandler) {
  ThreadHost thread_host("io.flutter.test." + GetCurrentTestName() + ".",
                         ThreadHost::Type::kPlatform);
  flutter::TaskRunners task_runners = flutter::TaskRunners(
      "HasPlatformMessageHandler", thread_host.platform_thread->GetTaskRunner(),
      nullptr, nullptr, nullptr);
  fml::AutoResetWaitableEvent latch;
  task_runners.GetPlatformTaskRunner()->PostTask([&latch, task_runners] {
    MockDelegate delegate;
    EmbedderSurfaceSoftware::SoftwareDispatchTable software_dispatch_table;
    PlatformViewEmbedder::PlatformDispatchTable platform_dispatch_table;
    std::shared_ptr<EmbedderExternalViewEmbedder> external_view_embedder;
    auto embedder = std::make_unique<PlatformViewEmbedder>(
        delegate, task_runners, software_dispatch_table,
        platform_dispatch_table, external_view_embedder);

    ASSERT_TRUE(embedder->GetPlatformMessageHandler());
    latch.Signal();
  });
  latch.Wait();
}

TEST(PlatformViewEmbedderTest, Dispatches) {
  ThreadHost thread_host("io.flutter.test." + GetCurrentTestName() + ".",
                         ThreadHost::Type::kPlatform);
  flutter::TaskRunners task_runners = flutter::TaskRunners(
      "HasPlatformMessageHandler", thread_host.platform_thread->GetTaskRunner(),
      nullptr, nullptr, nullptr);
  bool did_call = false;
  std::unique_ptr<PlatformViewEmbedder> embedder;
  {
    fml::AutoResetWaitableEvent latch;
    task_runners.GetPlatformTaskRunner()->PostTask([&latch, task_runners,
                                                    &did_call, &embedder] {
      MockDelegate delegate;
      EmbedderSurfaceSoftware::SoftwareDispatchTable software_dispatch_table;
      PlatformViewEmbedder::PlatformDispatchTable platform_dispatch_table;
      platform_dispatch_table.platform_message_response_callback =
          [&did_call](std::unique_ptr<PlatformMessage> message) {
            did_call = true;
          };
      std::shared_ptr<EmbedderExternalViewEmbedder> external_view_embedder;
      embedder = std::make_unique<PlatformViewEmbedder>(
          delegate, task_runners, software_dispatch_table,
          platform_dispatch_table, external_view_embedder);
      auto platform_message_handler = embedder->GetPlatformMessageHandler();
      fml::RefPtr<PlatformMessageResponse> response =
          fml::MakeRefCounted<MockResponse>();
      std::unique_ptr<PlatformMessage> message =
          std::make_unique<PlatformMessage>("foo", response);
      platform_message_handler->HandlePlatformMessage(std::move(message));
      latch.Signal();
    });
    latch.Wait();
  }
  {
    fml::AutoResetWaitableEvent latch;
    thread_host.platform_thread->GetTaskRunner()->PostTask([&latch, &embedder] {
      embedder.reset();
      latch.Signal();
    });
    latch.Wait();
  }

  EXPECT_TRUE(did_call);
}

TEST(PlatformViewEmbedderTest, DeletionDisabledDispatch) {
  ThreadHost thread_host("io.flutter.test." + GetCurrentTestName() + ".",
                         ThreadHost::Type::kPlatform);
  flutter::TaskRunners task_runners = flutter::TaskRunners(
      "HasPlatformMessageHandler", thread_host.platform_thread->GetTaskRunner(),
      nullptr, nullptr, nullptr);
  bool did_call = false;
  {
    fml::AutoResetWaitableEvent latch;
    task_runners.GetPlatformTaskRunner()->PostTask([&latch, task_runners,
                                                    &did_call] {
      MockDelegate delegate;
      EmbedderSurfaceSoftware::SoftwareDispatchTable software_dispatch_table;
      PlatformViewEmbedder::PlatformDispatchTable platform_dispatch_table;
      platform_dispatch_table.platform_message_response_callback =
          [&did_call](std::unique_ptr<PlatformMessage> message) {
            did_call = true;
          };
      std::shared_ptr<EmbedderExternalViewEmbedder> external_view_embedder;
      auto embedder = std::make_unique<PlatformViewEmbedder>(
          delegate, task_runners, software_dispatch_table,
          platform_dispatch_table, external_view_embedder);
      auto platform_message_handler = embedder->GetPlatformMessageHandler();
      fml::RefPtr<PlatformMessageResponse> response =
          fml::MakeRefCounted<MockResponse>();
      std::unique_ptr<PlatformMessage> message =
          std::make_unique<PlatformMessage>("foo", response);
      platform_message_handler->HandlePlatformMessage(std::move(message));
      embedder.reset();
      latch.Signal();
    });
    latch.Wait();
  }
  {
    fml::AutoResetWaitableEvent latch;
    thread_host.platform_thread->GetTaskRunner()->PostTask(
        [&latch] { latch.Signal(); });
    latch.Wait();
  }

  EXPECT_FALSE(did_call);
}

TEST(PlatformViewEmbedderTest, SubclassWithoutSurfaceHasNoRenderingResources) {
  ThreadHost thread_host("io.flutter.test." + GetCurrentTestName() + ".",
                         ThreadHost::Type::kPlatform);
  flutter::TaskRunners task_runners = flutter::TaskRunners(
      GetCurrentTestName(), thread_host.platform_thread->GetTaskRunner(),
      nullptr, nullptr, nullptr);
  fml::AutoResetWaitableEvent latch;
  task_runners.GetPlatformTaskRunner()->PostTask([&latch, task_runners] {
    MockDelegate delegate;
    SurfacelessPlatformViewEmbedder embedder(delegate, task_runners, {});
    // Calls go through the base class, the way the shell makes them.
    PlatformView& platform_view = embedder;

    EXPECT_FALSE(platform_view.GetImpellerContext());
    platform_view.SetupImpellerContext();
    EXPECT_FALSE(platform_view.CreateResourceContext());
    platform_view.ReleaseResourceContext();
    EXPECT_FALSE(platform_view.CreateExternalViewEmbedder());
    EXPECT_FALSE(platform_view.CreateSnapshotSurfaceProducer());
    EXPECT_TRUE(platform_view.GetPlatformMessageHandler());
    latch.Signal();
  });
  latch.Wait();
}

TEST(PlatformViewEmbedderTest,
     SubclassWithoutSurfaceDrivesFramesFromVsyncCallback) {
  ThreadHost thread_host("io.flutter.test." + GetCurrentTestName() + ".",
                         ThreadHost::Type::kPlatform | ThreadHost::Type::kUi);
  flutter::TaskRunners task_runners = flutter::TaskRunners(
      GetCurrentTestName(), thread_host.platform_thread->GetTaskRunner(),
      nullptr, thread_host.ui_thread->GetTaskRunner(), nullptr);

  // Written on the UI thread, read after `frame_latch` is signaled from it.
  int vsync_callback_calls = 0;
  std::shared_ptr<VsyncWaiter> vsync_waiter;
  {
    fml::AutoResetWaitableEvent latch;
    task_runners.GetPlatformTaskRunner()->PostTask([&] {
      MockDelegate delegate;
      PlatformViewEmbedder::PlatformDispatchTable platform_dispatch_table;
      platform_dispatch_table.vsync_callback = [&vsync_callback_calls,
                                                task_runners](intptr_t baton) {
        ++vsync_callback_calls;
        // Return the baton right away, as a vsync source would at the
        // next vsync.
        fml::TimePoint frame_start = fml::TimePoint::Now();
        VsyncWaiterEmbedder::OnEmbedderVsync(task_runners, baton, frame_start,
                                             frame_start + kFrameInterval);
      };
      SurfacelessPlatformViewEmbedder embedder(
          delegate, task_runners, std::move(platform_dispatch_table));
      vsync_waiter = static_cast<PlatformView&>(embedder).CreateVSyncWaiter();
      latch.Signal();
    });
    latch.Wait();
  }

  bool frame_fired = false;
  fml::AutoResetWaitableEvent frame_latch;
  task_runners.GetUITaskRunner()->PostTask([&] {
    vsync_waiter->AsyncWaitForVsync(
        [&](std::unique_ptr<FrameTimingsRecorder> recorder) {
          frame_fired = true;
          frame_latch.Signal();
        });
  });
  frame_latch.Wait();

  EXPECT_TRUE(frame_fired);
  // The timer fallback would also fire the frame, so this is what shows that
  // the dispatch table was used.
  EXPECT_EQ(vsync_callback_calls, 1);
}

TEST(PlatformViewEmbedderTest,
     SubclassWithoutSurfaceForwardsCallbacksThroughDispatchTable) {
  ThreadHost thread_host("io.flutter.test." + GetCurrentTestName() + ".",
                         ThreadHost::Type::kPlatform);
  flutter::TaskRunners task_runners = flutter::TaskRunners(
      GetCurrentTestName(), thread_host.platform_thread->GetTaskRunner(),
      nullptr, nullptr, nullptr);
  fml::AutoResetWaitableEvent latch;
  task_runners.GetPlatformTaskRunner()->PostTask([&latch, task_runners] {
    MockDelegate delegate;
    std::string recorded_locale;
    std::vector<bool> recorded_semantics_tree_enabled;
    std::vector<intptr_t> recorded_loading_units;
    // Sample unscaled font size (16 sp), configuration ID (2), and non-linearly
    // scaled font size (20 px) returned by the callback.
    constexpr intptr_t kTestLoadingUnitId = 9;
    constexpr double kUnscaledFontSize = 16.0;
    constexpr int kConfigurationId = 2;
    constexpr double kExpectedScaledFontSize = 20.0;

    PlatformViewEmbedder::PlatformDispatchTable platform_dispatch_table;
    platform_dispatch_table.set_application_locale_callback =
        [&recorded_locale](std::string locale) {
          recorded_locale = std::move(locale);
        };
    platform_dispatch_table.set_semantics_tree_enabled_callback =
        [&recorded_semantics_tree_enabled](bool enabled) {
          recorded_semantics_tree_enabled.push_back(enabled);
        };
    platform_dispatch_table.request_dart_deferred_library_callback =
        [&recorded_loading_units](intptr_t loading_unit_id) {
          recorded_loading_units.push_back(loading_unit_id);
        };
    platform_dispatch_table.get_scaled_font_size_callback =
        [kConfigurationId](double unscaled_font_size, int configuration_id) {
          EXPECT_DOUBLE_EQ(unscaled_font_size, kUnscaledFontSize);
          EXPECT_EQ(configuration_id, kConfigurationId);
          return kExpectedScaledFontSize;
        };

    SurfacelessPlatformViewEmbedder embedder(
        delegate, task_runners, std::move(platform_dispatch_table));
    PlatformView& platform_view = embedder;
    const PlatformView& const_platform_view = embedder;

    platform_view.SetApplicationLocale("ja-JP");
    platform_view.SetSemanticsTreeEnabled(true);
    platform_view.SetSemanticsTreeEnabled(false);
    platform_view.RequestDartDeferredLibrary(kTestLoadingUnitId);
    double scaled = const_platform_view.GetScaledFontSize(kUnscaledFontSize,
                                                          kConfigurationId);

    EXPECT_EQ(recorded_locale, "ja-JP");
    EXPECT_THAT(recorded_semantics_tree_enabled,
                ::testing::ElementsAre(true, false));
    EXPECT_THAT(recorded_loading_units,
                ::testing::ElementsAre(kTestLoadingUnitId));
    EXPECT_DOUBLE_EQ(scaled, kExpectedScaledFontSize);
    latch.Signal();
  });
  latch.Wait();
}

TEST(PlatformViewEmbedderTest,
     SubclassWithoutSurfaceForwardsDeferredLibraryAndAssetResolverToDelegate) {
  ThreadHost thread_host("io.flutter.test." + GetCurrentTestName() + ".",
                         ThreadHost::Type::kPlatform);
  flutter::TaskRunners task_runners = flutter::TaskRunners(
      GetCurrentTestName(), thread_host.platform_thread->GetTaskRunner(),
      nullptr, nullptr, nullptr);
  fml::AutoResetWaitableEvent latch;
  task_runners.GetPlatformTaskRunner()->PostTask([&latch, task_runners] {
    MockDelegate delegate;
    SurfacelessPlatformViewEmbedder embedder(delegate, task_runners, {});
    PlatformView& platform_view = embedder;

    // Sample loading unit IDs for success and error paths.
    constexpr intptr_t kLoadedUnitId = 4;
    constexpr intptr_t kFailedUnitId = 6;
    EXPECT_CALL(delegate, LoadDartDeferredLibrary(kLoadedUnitId, ::testing::_,
                                                  ::testing::_));
    EXPECT_CALL(delegate, LoadDartDeferredLibraryError(kFailedUnitId,
                                                       "missing .so", true));
    EXPECT_CALL(
        delegate,
        UpdateAssetResolverByType(
            ::testing::_, AssetResolver::AssetResolverType::kApkAssetProvider));

    platform_view.LoadDartDeferredLibrary(kLoadedUnitId, nullptr, nullptr);
    platform_view.LoadDartDeferredLibraryError(kFailedUnitId, "missing .so",
                                               true);
    platform_view.UpdateAssetResolverByType(
        nullptr, AssetResolver::AssetResolverType::kApkAssetProvider);
    latch.Signal();
  });
  latch.Wait();
}

TEST(PlatformViewEmbedderTest,
     SubclassWithoutSurfaceForwardsRenderingAndContextCallbacks) {
  ThreadHost thread_host(
      "io.flutter.test." + GetCurrentTestName() + ".",
      ThreadHost::Type::kPlatform | ThreadHost::Type::kRaster);
  flutter::TaskRunners task_runners = flutter::TaskRunners(
      GetCurrentTestName(), thread_host.platform_thread->GetTaskRunner(),
      thread_host.raster_thread->GetTaskRunner(), nullptr, nullptr);
  fml::AutoResetWaitableEvent latch;
  task_runners.GetPlatformTaskRunner()->PostTask([&latch, task_runners] {
    MockDelegate delegate;
    bool create_rendering_surface_called = false;
    bool create_external_view_embedder_called = false;
    bool create_snapshot_surface_producer_called = false;
    bool create_resource_context_called = false;
    bool release_resource_context_called = false;
    bool get_impeller_context_called = false;
    bool setup_impeller_context_called = false;

    PlatformViewEmbedder::PlatformDispatchTable platform_dispatch_table;
    platform_dispatch_table.create_rendering_surface_callback =
        [&create_rendering_surface_called]() -> std::unique_ptr<Surface> {
      create_rendering_surface_called = true;
      return nullptr;
    };
    platform_dispatch_table.create_external_view_embedder_callback =
        [&create_external_view_embedder_called]()
        -> std::shared_ptr<ExternalViewEmbedder> {
      create_external_view_embedder_called = true;
      return nullptr;
    };
    platform_dispatch_table.create_snapshot_surface_producer_callback =
        [&create_snapshot_surface_producer_called]()
        -> std::unique_ptr<SnapshotSurfaceProducer> {
      create_snapshot_surface_producer_called = true;
      return nullptr;
    };
    platform_dispatch_table.create_resource_context_callback =
        [&create_resource_context_called]() -> sk_sp<GrDirectContext> {
      create_resource_context_called = true;
      return nullptr;
    };
    platform_dispatch_table.release_resource_context_callback =
        [&release_resource_context_called]() {
          release_resource_context_called = true;
        };
    platform_dispatch_table.get_impeller_context_callback =
        [&get_impeller_context_called]() -> std::shared_ptr<impeller::Context> {
      get_impeller_context_called = true;
      return nullptr;
    };
    platform_dispatch_table.setup_impeller_context_callback =
        [&setup_impeller_context_called]() {
          setup_impeller_context_called = true;
        };

    SurfacelessPlatformViewEmbedder embedder(
        delegate, task_runners, std::move(platform_dispatch_table));
    PlatformView& platform_view = embedder;
    const PlatformView& const_platform_view = embedder;

    platform_view.NotifyCreated();
    EXPECT_FALSE(platform_view.CreateExternalViewEmbedder());
    EXPECT_FALSE(platform_view.CreateSnapshotSurfaceProducer());
    EXPECT_FALSE(const_platform_view.CreateResourceContext());
    const_platform_view.ReleaseResourceContext();
    EXPECT_FALSE(const_platform_view.GetImpellerContext());
    platform_view.SetupImpellerContext();

    EXPECT_TRUE(create_rendering_surface_called);
    EXPECT_TRUE(create_external_view_embedder_called);
    EXPECT_TRUE(create_snapshot_surface_producer_called);
    EXPECT_TRUE(create_resource_context_called);
    EXPECT_TRUE(release_resource_context_called);
    EXPECT_TRUE(get_impeller_context_called);
    EXPECT_TRUE(setup_impeller_context_called);
    latch.Signal();
  });
  latch.Wait();
}

TEST(PlatformViewEmbedderTest,
     SubclassWithoutSurfaceForwardsMakeResourceCurrentCallback) {
  ThreadHost thread_host("io.flutter.test." + GetCurrentTestName() + ".",
                         ThreadHost::Type::kPlatform);
  flutter::TaskRunners task_runners = flutter::TaskRunners(
      GetCurrentTestName(), thread_host.platform_thread->GetTaskRunner(),
      nullptr, nullptr, nullptr);
  fml::AutoResetWaitableEvent latch;
  task_runners.GetPlatformTaskRunner()->PostTask([&latch, task_runners] {
    MockDelegate delegate;
    bool make_resource_current_called = false;

    PlatformViewEmbedder::PlatformDispatchTable platform_dispatch_table;
    platform_dispatch_table.make_resource_current_callback =
        [&make_resource_current_called]() -> bool {
      make_resource_current_called = true;
      return false;
    };

    SurfacelessPlatformViewEmbedder embedder(
        delegate, task_runners, std::move(platform_dispatch_table));
    const PlatformView& const_platform_view = embedder;

    EXPECT_FALSE(const_platform_view.CreateResourceContext());
    EXPECT_TRUE(make_resource_current_called);
    latch.Signal();
  });
  latch.Wait();
}

namespace {
// Records the arguments of the FlutterProjectArgs callbacks below.
struct ProjectArgsCallbackRecord {
  void* vsync_user_data = nullptr;
  intptr_t vsync_baton = 0;
  void* pre_engine_restart_user_data = nullptr;
  void* deferred_library_user_data = nullptr;
  int64_t deferred_library_loading_unit_id = 0;
};

ProjectArgsCallbackRecord& GetProjectArgsCallbackRecord() {
  static ProjectArgsCallbackRecord record;
  return record;
}
}  // namespace

TEST(PlatformViewEmbedderTest,
     DispatchTableFromProjectArgsForwardsCallbacksWithUserData) {
  GetProjectArgsCallbackRecord() = {};
  FlutterProjectArgs args = {};
  args.struct_size = sizeof(FlutterProjectArgs);
  args.vsync_callback = [](void* user_data, intptr_t baton) {
    GetProjectArgsCallbackRecord().vsync_user_data = user_data;
    GetProjectArgsCallbackRecord().vsync_baton = baton;
  };
  args.on_pre_engine_restart_callback = [](void* user_data) {
    GetProjectArgsCallbackRecord().pre_engine_restart_user_data = user_data;
  };
  args.dart_deferred_library_loader_callback = [](int64_t loading_unit_id,
                                                  void* user_data) {
    GetProjectArgsCallbackRecord().deferred_library_user_data = user_data;
    GetProjectArgsCallbackRecord().deferred_library_loading_unit_id =
        loading_unit_id;
  };
  int user_data = 0;

  fml::StatusOr<PlatformViewEmbedder::PlatformDispatchTable> result =
      PlatformDispatchTableFromProjectArgs(&args, &user_data);

  ASSERT_TRUE(result.ok());
  const PlatformViewEmbedder::PlatformDispatchTable& table = result.value();
  // Arbitrary values that the callbacks must pass through unchanged.
  constexpr intptr_t kBaton = 42;
  constexpr intptr_t kLoadingUnitId = 7;
  ASSERT_TRUE(table.vsync_callback);
  table.vsync_callback(kBaton);
  EXPECT_EQ(GetProjectArgsCallbackRecord().vsync_user_data, &user_data);
  EXPECT_EQ(GetProjectArgsCallbackRecord().vsync_baton, kBaton);
  ASSERT_TRUE(table.on_pre_engine_restart_callback);
  table.on_pre_engine_restart_callback();
  EXPECT_EQ(GetProjectArgsCallbackRecord().pre_engine_restart_user_data,
            &user_data);
  ASSERT_TRUE(table.request_dart_deferred_library_callback);
  table.request_dart_deferred_library_callback(kLoadingUnitId);
  EXPECT_EQ(GetProjectArgsCallbackRecord().deferred_library_user_data,
            &user_data);
  EXPECT_EQ(GetProjectArgsCallbackRecord().deferred_library_loading_unit_id,
            kLoadingUnitId);

  // The rendering entries never come from the project arguments.
  EXPECT_FALSE(table.create_rendering_surface_callback);
  EXPECT_FALSE(table.create_external_view_embedder_callback);
  EXPECT_FALSE(table.create_snapshot_surface_producer_callback);
  EXPECT_FALSE(table.create_resource_context_callback);
  EXPECT_FALSE(table.make_resource_current_callback);
  EXPECT_FALSE(table.release_resource_context_callback);
  EXPECT_FALSE(table.get_impeller_context_callback);
  EXPECT_FALSE(table.setup_impeller_context_callback);
}

TEST(PlatformViewEmbedderTest, DispatchTableFromEmptyProjectArgsIsEmpty) {
  FlutterProjectArgs args = {};
  args.struct_size = sizeof(FlutterProjectArgs);

  fml::StatusOr<PlatformViewEmbedder::PlatformDispatchTable> result =
      PlatformDispatchTableFromProjectArgs(&args, nullptr);

  ASSERT_TRUE(result.ok());
  const PlatformViewEmbedder::PlatformDispatchTable& table = result.value();
  EXPECT_FALSE(table.update_semantics_callback);
  EXPECT_FALSE(table.platform_message_response_callback);
  EXPECT_FALSE(table.vsync_callback);
  EXPECT_FALSE(table.compute_platform_resolved_locale_callback);
  EXPECT_FALSE(table.on_pre_engine_restart_callback);
  EXPECT_FALSE(table.on_channel_update);
  EXPECT_FALSE(table.view_focus_change_request_callback);
  EXPECT_FALSE(table.set_application_locale_callback);
  EXPECT_FALSE(table.set_semantics_tree_enabled_callback);
  EXPECT_FALSE(table.request_dart_deferred_library_callback);
  EXPECT_FALSE(table.get_scaled_font_size_callback);
}

TEST(PlatformViewEmbedderTest,
     DispatchTableFromProjectArgsRejectsTwoSemanticsCallbacks) {
  FlutterProjectArgs args = {};
  args.struct_size = sizeof(FlutterProjectArgs);
  args.update_semantics_callback2 = [](const FlutterSemanticsUpdate2*, void*) {
  };
  args.update_semantics_callback = [](const FlutterSemanticsUpdate*, void*) {};

  fml::StatusOr<PlatformViewEmbedder::PlatformDispatchTable> result =
      PlatformDispatchTableFromProjectArgs(&args, nullptr);

  ASSERT_FALSE(result.ok());
  EXPECT_EQ(result.status().code(), fml::StatusCode::kInvalidArgument);
}

namespace {
// Records the arguments of the platform callbacks below.
struct PlatformCallbackRecord {
  void* application_locale_user_data = nullptr;
  std::string application_locale;
  void* semantics_tree_user_data = nullptr;
  bool semantics_tree_enabled = false;
  void* scaled_font_size_user_data = nullptr;
  double unscaled_font_size = 0;
  int configuration_id = 0;
  void* resolved_locale_user_data = nullptr;
  std::vector<std::string> supported_language_codes;
  // Returned by the resolved-locale callback. It is not one of the supported
  // locales, so the test also shows that the engine copies the result.
  FlutterLocale resolved_locale = {
      .struct_size = sizeof(FlutterLocale),
      .language_code = "iw",
      .country_code = "IL",
      .script_code = "Hebr",
      .variant_code = nullptr,
  };
};

PlatformCallbackRecord& GetPlatformCallbackRecord() {
  static PlatformCallbackRecord record;
  return record;
}

FlutterProjectArgs ProjectArgsWithPlatformCallbacks() {
  FlutterProjectArgs args = {};
  args.struct_size = sizeof(FlutterProjectArgs);
  args.set_application_locale_callback = [](const char* locale,
                                            void* user_data) {
    GetPlatformCallbackRecord().application_locale_user_data = user_data;
    GetPlatformCallbackRecord().application_locale = locale;
  };
  args.set_semantics_tree_enabled_callback = [](bool enabled, void* user_data) {
    GetPlatformCallbackRecord().semantics_tree_user_data = user_data;
    GetPlatformCallbackRecord().semantics_tree_enabled = enabled;
  };
  args.get_scaled_font_size_callback = [](double unscaled_font_size,
                                          int configuration_id,
                                          void* user_data) -> double {
    GetPlatformCallbackRecord().scaled_font_size_user_data = user_data;
    GetPlatformCallbackRecord().unscaled_font_size = unscaled_font_size;
    GetPlatformCallbackRecord().configuration_id = configuration_id;
    // Any deterministic function of the inputs shows the result is returned.
    return unscaled_font_size * 2 + configuration_id;
  };
  args.compute_platform_resolved_locale_callback2 =
      [](const FlutterLocale** supported_locales, size_t locale_count,
         void* user_data) -> const FlutterLocale* {
    GetPlatformCallbackRecord().resolved_locale_user_data = user_data;
    for (size_t i = 0; i < locale_count; ++i) {
      GetPlatformCallbackRecord().supported_language_codes.emplace_back(
          supported_locales[i]->language_code);
    }
    return &GetPlatformCallbackRecord().resolved_locale;
  };
  return args;
}
}  // namespace

TEST(PlatformViewEmbedderTest,
     DispatchTableFromProjectArgsForwardsPlatformCallbacksWithUserData) {
  GetPlatformCallbackRecord() = {};
  FlutterProjectArgs args = ProjectArgsWithPlatformCallbacks();
  int user_data = 0;

  fml::StatusOr<PlatformViewEmbedder::PlatformDispatchTable> result =
      PlatformDispatchTableFromProjectArgs(&args, &user_data);

  ASSERT_TRUE(result.ok());
  const PlatformViewEmbedder::PlatformDispatchTable& table = result.value();

  ASSERT_TRUE(table.set_application_locale_callback);
  table.set_application_locale_callback("de-CH");
  EXPECT_EQ(GetPlatformCallbackRecord().application_locale_user_data,
            &user_data);
  EXPECT_EQ(GetPlatformCallbackRecord().application_locale, "de-CH");

  ASSERT_TRUE(table.set_semantics_tree_enabled_callback);
  table.set_semantics_tree_enabled_callback(true);
  EXPECT_EQ(GetPlatformCallbackRecord().semantics_tree_user_data, &user_data);
  EXPECT_TRUE(GetPlatformCallbackRecord().semantics_tree_enabled);

  // Arbitrary font size and configuration id; the callback doubles the size
  // and adds the id.
  constexpr double kUnscaledFontSize = 14.0;
  constexpr int kConfigurationId = 3;
  ASSERT_TRUE(table.get_scaled_font_size_callback);
  EXPECT_EQ(
      table.get_scaled_font_size_callback(kUnscaledFontSize, kConfigurationId),
      kUnscaledFontSize * 2 + kConfigurationId);
  EXPECT_EQ(GetPlatformCallbackRecord().scaled_font_size_user_data, &user_data);
  EXPECT_EQ(GetPlatformCallbackRecord().unscaled_font_size, kUnscaledFontSize);
  EXPECT_EQ(GetPlatformCallbackRecord().configuration_id, kConfigurationId);

  // Locale data comes in triples: language, country, script.
  ASSERT_TRUE(table.compute_platform_resolved_locale_callback);
  std::unique_ptr<std::vector<std::string>> resolved =
      table.compute_platform_resolved_locale_callback(
          {"en", "US", "", "he", "IL", "Hebr"});
  EXPECT_EQ(GetPlatformCallbackRecord().resolved_locale_user_data, &user_data);
  EXPECT_EQ(GetPlatformCallbackRecord().supported_language_codes,
            (std::vector<std::string>{"en", "he"}));
  ASSERT_TRUE(resolved);
  EXPECT_EQ(*resolved, (std::vector<std::string>{"iw", "IL", "Hebr"}));
}

TEST(PlatformViewEmbedderTest,
     DispatchTableFromProjectArgsPrefersResolvedLocaleCallbackWithUserData) {
  GetPlatformCallbackRecord() = {};
  FlutterProjectArgs args = ProjectArgsWithPlatformCallbacks();
  args.compute_platform_resolved_locale_callback =
      [](const FlutterLocale**, size_t) -> const FlutterLocale* {
    ADD_FAILURE() << "The callback without user_data must not be used when "
                     "compute_platform_resolved_locale_callback2 is set.";
    return nullptr;
  };
  int user_data = 0;

  fml::StatusOr<PlatformViewEmbedder::PlatformDispatchTable> result =
      PlatformDispatchTableFromProjectArgs(&args, &user_data);

  ASSERT_TRUE(result.ok());
  std::unique_ptr<std::vector<std::string>> resolved =
      result.value().compute_platform_resolved_locale_callback(
          {"en", "US", ""});
  EXPECT_EQ(GetPlatformCallbackRecord().resolved_locale_user_data, &user_data);
  ASSERT_TRUE(resolved);
  EXPECT_EQ(resolved->front(), "iw");
}

TEST(PlatformViewEmbedderTest,
     DispatchTableFromProjectArgsCarriesSendingThreadFlag) {
  FlutterProjectArgs args = {};
  args.struct_size = sizeof(FlutterProjectArgs);
  args.platform_message_callback_on_sending_thread = true;

  fml::StatusOr<PlatformViewEmbedder::PlatformDispatchTable> result =
      PlatformDispatchTableFromProjectArgs(&args, nullptr);

  ASSERT_TRUE(result.ok());
  EXPECT_TRUE(result.value().platform_message_callback_on_sending_thread);
}

namespace {

// Owns a platform thread and a surfaceless platform view created on it, with
// `table` as its dispatch table, and destroys the view on that thread.
class SendingThreadHandlerFixture {
 public:
  explicit SendingThreadHandlerFixture(
      PlatformViewEmbedder::PlatformDispatchTable table)
      : thread_host_("io.flutter.test." + GetCurrentTestName() + ".",
                     ThreadHost::Type::kPlatform),
        task_runners_(GetCurrentTestName(),
                      thread_host_.platform_thread->GetTaskRunner(),
                      nullptr,
                      nullptr,
                      nullptr) {
    table.platform_message_callback_on_sending_thread = true;
    PostTaskSync(task_runners_.GetPlatformTaskRunner(), [&] {
      embedder_ = std::make_unique<SurfacelessPlatformViewEmbedder>(
          delegate_, task_runners_, std::move(table));
    });
  }

  ~SendingThreadHandlerFixture() { DestroyPlatformView(); }

  std::shared_ptr<PlatformMessageHandler> handler() const {
    return embedder_->GetPlatformMessageHandler();
  }

  fml::RefPtr<fml::TaskRunner> platform_task_runner() const {
    return task_runners_.GetPlatformTaskRunner();
  }

  void DestroyPlatformView() {
    PostTaskSync(task_runners_.GetPlatformTaskRunner(),
                 [&] { embedder_.reset(); });
  }

  // Hands the platform view to the caller, which must destroy it on the
  // platform thread.
  std::unique_ptr<PlatformViewEmbedder> ReleasePlatformView() {
    return std::move(embedder_);
  }

 private:
  ThreadHost thread_host_;
  TaskRunners task_runners_;
  MockDelegate delegate_;
  std::unique_ptr<PlatformViewEmbedder> embedder_;
};

}  // namespace

TEST(PlatformViewEmbedderTest,
     SendingThreadHandlerCallsCallbackOnTheSendingThread) {
  std::thread::id callback_thread;
  PlatformViewEmbedder::PlatformDispatchTable table;
  table.platform_message_response_callback =
      [&callback_thread](std::unique_ptr<PlatformMessage> message) {
        callback_thread = std::this_thread::get_id();
      };
  SendingThreadHandlerFixture fixture(std::move(table));
  std::shared_ptr<PlatformMessageHandler> handler = fixture.handler();
  ASSERT_TRUE(handler);
  EXPECT_FALSE(handler->DoesHandlePlatformMessageOnPlatformThread());

  handler->HandlePlatformMessage(std::make_unique<PlatformMessage>(
      "foo", fml::MakeRefCounted<MockResponse>()));

  // The callback ran before HandlePlatformMessage returned, on this thread,
  // which is not the platform thread.
  EXPECT_EQ(callback_thread, std::this_thread::get_id());
}

TEST(PlatformViewEmbedderTest,
     SendingThreadHandlerCompletesEmptyWithoutCallback) {
  SendingThreadHandlerFixture fixture({});
  auto response = fml::MakeRefCounted<MockResponse>();
  EXPECT_CALL(*response, CompleteEmpty()).Times(1);

  fixture.handler()->HandlePlatformMessage(
      std::make_unique<PlatformMessage>("foo", response));
}

TEST(PlatformViewEmbedderTest,
     SendingThreadHandlerDropsMessagesAfterPlatformViewIsDestroyed) {
  int callback_calls = 0;
  PlatformViewEmbedder::PlatformDispatchTable table;
  table.platform_message_response_callback =
      [&callback_calls](std::unique_ptr<PlatformMessage> message) {
        ++callback_calls;
      };
  SendingThreadHandlerFixture fixture(std::move(table));
  // A background isolate can keep the handler after the view is gone.
  std::shared_ptr<PlatformMessageHandler> handler = fixture.handler();
  fixture.DestroyPlatformView();
  auto response = fml::MakeRefCounted<MockResponse>();
  EXPECT_CALL(*response, Complete(::testing::_)).Times(0);
  EXPECT_CALL(*response, CompleteEmpty()).Times(0);

  handler->HandlePlatformMessage(
      std::make_unique<PlatformMessage>("foo", response));

  EXPECT_EQ(callback_calls, 0);
}

TEST(PlatformViewEmbedderTest,
     DestroyingPlatformViewWaitsForSendingThreadCallbackInProgress) {
  // Long enough for the platform thread to reach the platform view's
  // destructor while the callback is still blocked, so that a destructor
  // that does not wait finishes before the callback returns.
  constexpr std::chrono::milliseconds kTimeForDestructorToRun(100);
  fml::AutoResetWaitableEvent callback_entered;
  fml::AutoResetWaitableEvent release_callback;
  std::atomic<bool> callback_returned = false;
  PlatformViewEmbedder::PlatformDispatchTable table;
  table.platform_message_response_callback =
      [&](std::unique_ptr<PlatformMessage> message) {
        callback_entered.Signal();
        release_callback.Wait();
        callback_returned = true;
      };
  SendingThreadHandlerFixture fixture(std::move(table));
  std::shared_ptr<PlatformMessageHandler> handler = fixture.handler();
  std::thread sender([&handler] {
    handler->HandlePlatformMessage(std::make_unique<PlatformMessage>(
        "foo", fml::MakeRefCounted<MockResponse>()));
  });
  callback_entered.Wait();

  std::unique_ptr<PlatformViewEmbedder> embedder =
      fixture.ReleasePlatformView();
  bool callback_returned_before_destruction_finished = false;
  fml::AutoResetWaitableEvent destroyed;
  fixture.platform_task_runner()->PostTask([&] {
    embedder.reset();
    callback_returned_before_destruction_finished = callback_returned;
    destroyed.Signal();
  });
  std::this_thread::sleep_for(kTimeForDestructorToRun);
  release_callback.Signal();
  destroyed.Wait();
  sender.join();

  EXPECT_TRUE(callback_returned_before_destruction_finished);
}

}  // namespace testing
}  // namespace flutter
