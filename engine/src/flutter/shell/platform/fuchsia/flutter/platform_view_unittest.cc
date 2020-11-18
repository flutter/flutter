// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/fuchsia/flutter/platform_view.h"

#include <fuchsia/ui/gfx/cpp/fidl.h>
#include <fuchsia/ui/scenic/cpp/fidl.h>
#include <fuchsia/ui/views/cpp/fidl.h>
#include <lib/async-loop/cpp/loop.h>
#include <lib/async-loop/default.h>
#include <lib/async/default.h>
#include <lib/fidl/cpp/binding_set.h>
#include <lib/sys/cpp/testing/service_directory_provider.h>
#include <lib/ui/scenic/cpp/view_ref_pair.h>

#include <memory>
#include <ostream>
#include <string>
#include <vector>

#include "flutter/flow/embedded_views.h"
#include "flutter/lib/ui/window/platform_message.h"
#include "flutter/lib/ui/window/viewport_metrics.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"

#include "surface.h"
#include "task_runner_adapter.h"

namespace flutter_runner::testing {
namespace {

class MockExternalViewEmbedder : public flutter::ExternalViewEmbedder {
 public:
  SkCanvas* GetRootCanvas() override { return nullptr; }
  std::vector<SkCanvas*> GetCurrentCanvases() override {
    return std::vector<SkCanvas*>();
  }

  void CancelFrame() override {}
  void BeginFrame(
      SkISize frame_size,
      GrDirectContext* context,
      double device_pixel_ratio,
      fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger) override {}
  void SubmitFrame(GrDirectContext* context,
                   std::unique_ptr<flutter::SurfaceFrame> frame,
                   const std::shared_ptr<fml::SyncSwitch>&
                       gpu_disable_sync_switch) override {
    return;
  }

  void PrerollCompositeEmbeddedView(
      int view_id,
      std::unique_ptr<flutter::EmbeddedViewParams> params) override {}
  SkCanvas* CompositeEmbeddedView(int view_id) override { return nullptr; }
};

class MockPlatformViewDelegate : public flutter::PlatformView::Delegate {
 public:
  // |flutter::PlatformView::Delegate|
  void OnPlatformViewCreated(std::unique_ptr<flutter::Surface> surface) {
    surface_ = std::move(surface);
  }
  // |flutter::PlatformView::Delegate|
  void OnPlatformViewDestroyed() {}
  // |flutter::PlatformView::Delegate|
  void OnPlatformViewSetNextFrameCallback(const fml::closure& closure) {}
  // |flutter::PlatformView::Delegate|
  void OnPlatformViewSetViewportMetrics(
      const flutter::ViewportMetrics& metrics) {
    metrics_ = metrics;
  }
  // |flutter::PlatformView::Delegate|
  void OnPlatformViewDispatchPlatformMessage(
      fml::RefPtr<flutter::PlatformMessage> message) {
    message_ = std::move(message);
  }
  // |flutter::PlatformView::Delegate|
  void OnPlatformViewDispatchPointerDataPacket(
      std::unique_ptr<flutter::PointerDataPacket> packet) {}
  // |flutter::PlatformView::Delegate|
  void OnPlatformViewDispatchSemanticsAction(int32_t id,
                                             flutter::SemanticsAction action,
                                             std::vector<uint8_t> args) {}
  // |flutter::PlatformView::Delegate|
  void OnPlatformViewSetSemanticsEnabled(bool enabled) {
    semantics_enabled_ = enabled;
  }
  // |flutter::PlatformView::Delegate|
  void OnPlatformViewSetAccessibilityFeatures(int32_t flags) {
    semantics_features_ = flags;
  }
  // |flutter::PlatformView::Delegate|
  void OnPlatformViewRegisterTexture(
      std::shared_ptr<flutter::Texture> texture) {}
  // |flutter::PlatformView::Delegate|
  void OnPlatformViewUnregisterTexture(int64_t texture_id) {}
  // |flutter::PlatformView::Delegate|
  void OnPlatformViewMarkTextureFrameAvailable(int64_t texture_id) {}
  // |flutter::PlatformView::Delegate|
  std::unique_ptr<std::vector<std::string>> ComputePlatformViewResolvedLocale(
      const std::vector<std::string>& supported_locale_data) {
    return nullptr;
  }

  flutter::Surface* surface() const { return surface_.get(); }
  flutter::PlatformMessage* message() const { return message_.get(); }
  const flutter::ViewportMetrics& metrics() const { return metrics_; }
  int32_t semantics_features() const { return semantics_features_; }
  bool semantics_enabled() const { return semantics_enabled_; }

 private:
  std::unique_ptr<flutter::Surface> surface_;
  fml::RefPtr<flutter::PlatformMessage> message_;
  flutter::ViewportMetrics metrics_;
  int32_t semantics_features_ = 0;
  bool semantics_enabled_ = false;
};

class MockFocuser : public fuchsia::ui::views::Focuser {
 public:
  MockFocuser(bool fail_request_focus = false)
      : fail_request_focus_(fail_request_focus) {}

  bool request_focus_called() const { return request_focus_called_; }

 private:
  void RequestFocus(fuchsia::ui::views::ViewRef view_ref,
                    RequestFocusCallback callback) override {
    request_focus_called_ = true;
    auto result =
        fail_request_focus_
            ? fuchsia::ui::views::Focuser_RequestFocus_Result::WithErr(
                  fuchsia::ui::views::Error::DENIED)
            : fuchsia::ui::views::Focuser_RequestFocus_Result::WithResponse(
                  fuchsia::ui::views::Focuser_RequestFocus_Response());
    callback(std::move(result));
  }

  bool request_focus_called_ = false;
  bool fail_request_focus_ = false;
};

class MockResponse : public flutter::PlatformMessageResponse {
 public:
  MOCK_METHOD1(Complete, void(std::unique_ptr<fml::Mapping> data));
  MOCK_METHOD0(CompleteEmpty, void());
};

}  // namespace

class PlatformViewTests : public ::testing::Test {
 protected:
  PlatformViewTests() : loop_(&kAsyncLoopConfigAttachToCurrentThread) {}

  async_dispatcher_t* dispatcher() { return loop_.dispatcher(); }

  void RunLoopUntilIdle() {
    loop_.RunUntilIdle();
    loop_.ResetQuit();
  }

 private:
  async::Loop loop_;

  FML_DISALLOW_COPY_AND_ASSIGN(PlatformViewTests);
};

// This test makes sure that the PlatformView correctly returns a Surface
// instance that can surface the provided gr_context and view_embedder.
TEST_F(PlatformViewTests, CreateSurfaceTest) {
  sys::testing::ServiceDirectoryProvider services_provider(dispatcher());
  MockPlatformViewDelegate delegate;

  flutter::TaskRunners task_runners =
      flutter::TaskRunners("test_runners",  // label
                           nullptr,         // platform
                           flutter_runner::CreateFMLTaskRunner(
                               async_get_default_dispatcher()),  // raster
                           nullptr,                              // ui
                           nullptr                               // io
      );

  // Test create surface callback function.
  sk_sp<GrDirectContext> gr_context =
      GrDirectContext::MakeMock(nullptr, GrContextOptions());
  std::shared_ptr<MockExternalViewEmbedder> view_embedder =
      std::make_shared<MockExternalViewEmbedder>();
  auto CreateSurfaceCallback = [&view_embedder, gr_context]() {
    return std::make_unique<flutter_runner::Surface>(
        "PlatformViewTest", view_embedder, gr_context.get());
  };

  auto platform_view = flutter_runner::PlatformView(
      delegate,                               // delegate
      "test_platform_view",                   // label
      fuchsia::ui::views::ViewRef(),          // view_ref
      std::move(task_runners),                // task_runners
      services_provider.service_directory(),  // runner_services
      nullptr,                 // parent_environment_service_provider_handle
      nullptr,                 // session_listener_request
      nullptr,                 // focuser,
      nullptr,                 // on_session_listener_error_callback
      nullptr,                 // on_enable_wireframe_callback,
      nullptr,                 // on_create_view_callback,
      nullptr,                 // on_update_view_callback,
      nullptr,                 // on_destroy_view_callback,
      CreateSurfaceCallback,   // on_create_surface_callback,
      view_embedder,           // external_view_embedder,
      fml::TimeDelta::Zero(),  // vsync_offset
      ZX_HANDLE_INVALID        // vsync_event_handle
  );
  platform_view.NotifyCreated();

  RunLoopUntilIdle();

  EXPECT_EQ(gr_context.get(), delegate.surface()->GetContext());
  EXPECT_EQ(view_embedder.get(),
            platform_view.CreateExternalViewEmbedder().get());
}

// This test makes sure that the PlatformView correctly registers Scenic
// MetricsEvents sent to it via FIDL, correctly parses the metrics it receives,
// and calls the SetViewportMetrics callback with the appropriate parameters.
TEST_F(PlatformViewTests, SetViewportMetrics) {
  constexpr float invalid_pixel_ratio = -0.75f;
  constexpr float valid_pixel_ratio = 0.75f;
  constexpr float invalid_max_bound = -0.75f;
  constexpr float valid_max_bound = 0.75f;

  MockPlatformViewDelegate delegate;
  EXPECT_EQ(delegate.metrics(), flutter::ViewportMetrics());

  fuchsia::ui::scenic::SessionListenerPtr session_listener;
  std::vector<fuchsia::ui::scenic::Event> events;
  sys::testing::ServiceDirectoryProvider services_provider(dispatcher());
  flutter::TaskRunners task_runners("test_runners", nullptr, nullptr, nullptr,
                                    nullptr);
  flutter_runner::PlatformView platform_view(
      delegate,                               // delegate
      "test_platform_view",                   // label
      fuchsia::ui::views::ViewRef(),          // view_ref
      std::move(task_runners),                // task_runners
      services_provider.service_directory(),  // runner_services
      nullptr,  // parent_environment_service_provider_handle
      session_listener.NewRequest(),  // session_listener_request
      nullptr,                        // focuser,
      nullptr,                        // on_session_listener_error_callback
      nullptr,                        // on_enable_wireframe_callback,
      nullptr,                        // on_create_view_callback,
      nullptr,                        // on_update_view_callback,
      nullptr,                        // on_destroy_view_callback,
      nullptr,                        // on_create_surface_callback,
      nullptr,                        // external_view_embedder,
      fml::TimeDelta::Zero(),         // vsync_offset
      ZX_HANDLE_INVALID               // vsync_event_handle
  );
  RunLoopUntilIdle();
  EXPECT_EQ(delegate.metrics(), flutter::ViewportMetrics());

  // Test updating with an invalid pixel ratio.  The final metrics should be
  // unchanged.
  events.clear();
  events.emplace_back(fuchsia::ui::scenic::Event::WithGfx(
      fuchsia::ui::gfx::Event::WithMetrics(fuchsia::ui::gfx::MetricsEvent{
          .node_id = 0,
          .metrics =
              fuchsia::ui::gfx::Metrics{
                  .scale_x = invalid_pixel_ratio,
                  .scale_y = 1.f,
                  .scale_z = 1.f,
              },
      })));
  session_listener->OnScenicEvent(std::move(events));
  RunLoopUntilIdle();
  EXPECT_EQ(delegate.metrics(), flutter::ViewportMetrics());

  // Test updating with an invalid size.  The final metrics should be unchanged.
  events.clear();
  events.emplace_back(
      fuchsia::ui::scenic::Event::WithGfx(
          fuchsia::ui::gfx::Event::WithViewPropertiesChanged(
              fuchsia::ui::gfx::ViewPropertiesChangedEvent{
                  .view_id = 0,
                  .properties =
                      fuchsia::ui::gfx::ViewProperties{
                          .bounding_box =
                              fuchsia::ui::gfx::BoundingBox{
                                  .min =
                                      fuchsia::ui::gfx::vec3{
                                          .x = 0.f,
                                          .y = 0.f,
                                          .z = 0.f,
                                      },
                                  .max =
                                      fuchsia::ui::gfx::vec3{
                                          .x = invalid_max_bound,
                                          .y = invalid_max_bound,
                                          .z = invalid_max_bound,
                                      },
                              },
                      },
              })));
  session_listener->OnScenicEvent(std::move(events));
  RunLoopUntilIdle();
  EXPECT_EQ(delegate.metrics(), flutter::ViewportMetrics());

  // Test updating the size only.  The final metrics should be unchanged until
  // both pixel ratio and size are updated.
  events.clear();
  events.emplace_back(
      fuchsia::ui::scenic::Event::WithGfx(
          fuchsia::ui::gfx::Event::WithViewPropertiesChanged(
              fuchsia::ui::gfx::ViewPropertiesChangedEvent{
                  .view_id = 0,
                  .properties =
                      fuchsia::ui::gfx::ViewProperties{
                          .bounding_box =
                              fuchsia::ui::gfx::BoundingBox{
                                  .min =
                                      fuchsia::ui::gfx::vec3{
                                          .x = 0.f,
                                          .y = 0.f,
                                          .z = 0.f,
                                      },
                                  .max =
                                      fuchsia::ui::gfx::vec3{
                                          .x = valid_max_bound,
                                          .y = valid_max_bound,
                                          .z = valid_max_bound,
                                      },
                              },
                      },
              })));
  session_listener->OnScenicEvent(std::move(events));
  RunLoopUntilIdle();
  EXPECT_EQ(delegate.metrics(), flutter::ViewportMetrics());

  // Test updating the pixel ratio only.  The final metrics should change now.
  events.clear();
  events.emplace_back(fuchsia::ui::scenic::Event::WithGfx(
      fuchsia::ui::gfx::Event::WithMetrics(fuchsia::ui::gfx::MetricsEvent{
          .node_id = 0,
          .metrics =
              fuchsia::ui::gfx::Metrics{
                  .scale_x = valid_pixel_ratio,
                  .scale_y = 1.f,
                  .scale_z = 1.f,
              },
      })));
  session_listener->OnScenicEvent(std::move(events));
  RunLoopUntilIdle();
  EXPECT_EQ(delegate.metrics(),
            flutter::ViewportMetrics(valid_pixel_ratio,
                                     valid_pixel_ratio * valid_max_bound,
                                     valid_pixel_ratio * valid_max_bound));
}

// This test makes sure that the PlatformView correctly registers semantics
// settings changes applied to it and calls the SetSemanticsEnabled /
// SetAccessibilityFeatures callbacks with the appropriate parameters.
TEST_F(PlatformViewTests, ChangesAccessibilitySettings) {
  sys::testing::ServiceDirectoryProvider services_provider(dispatcher());

  MockPlatformViewDelegate delegate;
  flutter::TaskRunners task_runners =
      flutter::TaskRunners("test_runners", nullptr, nullptr, nullptr, nullptr);

  EXPECT_FALSE(delegate.semantics_enabled());
  EXPECT_EQ(delegate.semantics_features(), 0);

  auto platform_view = flutter_runner::PlatformView(
      delegate,                               // delegate
      "test_platform_view",                   // label
      fuchsia::ui::views::ViewRef(),          // view_ref
      std::move(task_runners),                // task_runners
      services_provider.service_directory(),  // runner_services
      nullptr,                 // parent_environment_service_provider_handle
      nullptr,                 // session_listener_request
      nullptr,                 // focuser,
      nullptr,                 // on_session_listener_error_callback
      nullptr,                 // on_enable_wireframe_callback,
      nullptr,                 // on_create_view_callback,
      nullptr,                 // on_update_view_callback,
      nullptr,                 // on_destroy_view_callback,
      nullptr,                 // on_create_surface_callback,
      nullptr,                 // external_view_embedder,
      fml::TimeDelta::Zero(),  // vsync_offset
      ZX_HANDLE_INVALID        // vsync_event_handle
  );

  RunLoopUntilIdle();

  platform_view.SetSemanticsEnabled(true);

  EXPECT_TRUE(delegate.semantics_enabled());
  EXPECT_EQ(delegate.semantics_features(),
            static_cast<int32_t>(
                flutter::AccessibilityFeatureFlag::kAccessibleNavigation));

  platform_view.SetSemanticsEnabled(false);

  EXPECT_FALSE(delegate.semantics_enabled());
  EXPECT_EQ(delegate.semantics_features(), 0);
}

// This test makes sure that the PlatformView forwards messages on the
// "flutter/platform_views" channel for EnableWireframe.
TEST_F(PlatformViewTests, EnableWireframeTest) {
  sys::testing::ServiceDirectoryProvider services_provider(dispatcher());
  MockPlatformViewDelegate delegate;
  flutter::TaskRunners task_runners =
      flutter::TaskRunners("test_runners", nullptr, nullptr, nullptr, nullptr);

  // Test wireframe callback function. If the message sent to the platform
  // view was properly handled and parsed, this function should be called,
  // setting |wireframe_enabled| to true.
  bool wireframe_enabled = false;
  auto EnableWireframeCallback = [&wireframe_enabled](bool should_enable) {
    wireframe_enabled = should_enable;
  };

  auto platform_view = flutter_runner::PlatformView(
      delegate,                               // delegate
      "test_platform_view",                   // label
      fuchsia::ui::views::ViewRef(),          // view_ref
      std::move(task_runners),                // task_runners
      services_provider.service_directory(),  // runner_services
      nullptr,                  // parent_environment_service_provider_handle
      nullptr,                  // session_listener_request
      nullptr,                  // focuser,
      nullptr,                  // on_session_listener_error_callback
      EnableWireframeCallback,  // on_enable_wireframe_callback,
      nullptr,                  // on_create_view_callback,
      nullptr,                  // on_update_view_callback,
      nullptr,                  // on_destroy_view_callback,
      nullptr,                  // on_create_surface_callback,
      nullptr,                  // external_view_embedder,
      fml::TimeDelta::Zero(),   // vsync_offset
      ZX_HANDLE_INVALID         // vsync_event_handle
  );

  // Cast platform_view to its base view so we can have access to the public
  // "HandlePlatformMessage" function.
  auto base_view = dynamic_cast<flutter::PlatformView*>(&platform_view);
  EXPECT_TRUE(base_view);

  // JSON for the message to be passed into the PlatformView.
  const uint8_t txt[] =
      "{"
      "    \"method\":\"View.enableWireframe\","
      "    \"args\": {"
      "       \"enable\":true"
      "    }"
      "}";

  fml::RefPtr<flutter::PlatformMessage> message =
      fml::MakeRefCounted<flutter::PlatformMessage>(
          "flutter/platform_views",
          std::vector<uint8_t>(txt, txt + sizeof(txt)),
          fml::RefPtr<flutter::PlatformMessageResponse>());
  base_view->HandlePlatformMessage(message);

  RunLoopUntilIdle();

  EXPECT_TRUE(wireframe_enabled);
}

// This test makes sure that the PlatformView forwards messages on the
// "flutter/platform_views" channel for Createview.
TEST_F(PlatformViewTests, CreateViewTest) {
  sys::testing::ServiceDirectoryProvider services_provider(dispatcher());
  MockPlatformViewDelegate delegate;
  flutter::TaskRunners task_runners =
      flutter::TaskRunners("test_runners", nullptr, nullptr, nullptr, nullptr);

  // Test wireframe callback function. If the message sent to the platform
  // view was properly handled and parsed, this function should be called,
  // setting |wireframe_enabled| to true.
  int64_t create_view_called = false;
  auto CreateViewCallback = [&create_view_called](
                                int64_t view_id, bool hit_testable,
                                bool focusable) { create_view_called = true; };

  auto platform_view = flutter_runner::PlatformView(
      delegate,                               // delegate
      "test_platform_view",                   // label
      fuchsia::ui::views::ViewRef(),          // view_ref
      std::move(task_runners),                // task_runners
      services_provider.service_directory(),  // runner_services
      nullptr,                 // parent_environment_service_provider_handle
      nullptr,                 // session_listener_request
      nullptr,                 // focuser,
      nullptr,                 // on_session_listener_error_callback
      nullptr,                 // on_enable_wireframe_callback,
      CreateViewCallback,      // on_create_view_callback,
      nullptr,                 // on_update_view_callback,
      nullptr,                 // on_destroy_view_callback,
      nullptr,                 // on_create_surface_callback,
      nullptr,                 // external_view_embedder,
      fml::TimeDelta::Zero(),  // vsync_offset
      ZX_HANDLE_INVALID        // vsync_event_handle
  );

  // Cast platform_view to its base view so we can have access to the public
  // "HandlePlatformMessage" function.
  auto base_view = dynamic_cast<flutter::PlatformView*>(&platform_view);
  EXPECT_TRUE(base_view);

  // JSON for the message to be passed into the PlatformView.
  const uint8_t txt[] =
      "{"
      "    \"method\":\"View.create\","
      "    \"args\": {"
      "       \"viewId\":42,"
      "       \"hitTestable\":true,"
      "       \"focusable\":true"
      "    }"
      "}";

  fml::RefPtr<flutter::PlatformMessage> message =
      fml::MakeRefCounted<flutter::PlatformMessage>(
          "flutter/platform_views",
          std::vector<uint8_t>(txt, txt + sizeof(txt)),
          fml::RefPtr<flutter::PlatformMessageResponse>());
  base_view->HandlePlatformMessage(message);

  RunLoopUntilIdle();

  EXPECT_TRUE(create_view_called);
}

// This test makes sure that the PlatformView forwards messages on the
// "flutter/platform_views" channel for UpdateView.
TEST_F(PlatformViewTests, UpdateViewTest) {
  sys::testing::ServiceDirectoryProvider services_provider(dispatcher());
  MockPlatformViewDelegate delegate;
  flutter::TaskRunners task_runners =
      flutter::TaskRunners("test_runners", nullptr, nullptr, nullptr, nullptr);

  // Test wireframe callback function. If the message sent to the platform
  // view was properly handled and parsed, this function should be called,
  // setting |wireframe_enabled| to true.
  int64_t update_view_called = false;
  auto UpdateViewCallback = [&update_view_called](
                                int64_t view_id, bool hit_testable,
                                bool focusable) { update_view_called = true; };

  auto platform_view = flutter_runner::PlatformView(
      delegate,                               // delegate
      "test_platform_view",                   // label
      fuchsia::ui::views::ViewRef(),          // view_ref
      std::move(task_runners),                // task_runners
      services_provider.service_directory(),  // runner_services
      nullptr,                 // parent_environment_service_provider_handle
      nullptr,                 // session_listener_request
      nullptr,                 // focuser,
      nullptr,                 // on_session_listener_error_callback
      nullptr,                 // on_enable_wireframe_callback,
      nullptr,                 // on_create_view_callback,
      UpdateViewCallback,      // on_update_view_callback,
      nullptr,                 // on_destroy_view_callback,
      nullptr,                 // on_create_surface_callback,
      nullptr,                 // external_view_embedder,
      fml::TimeDelta::Zero(),  // vsync_offset
      ZX_HANDLE_INVALID        // vsync_event_handle
  );

  // Cast platform_view to its base view so we can have access to the public
  // "HandlePlatformMessage" function.
  auto base_view = dynamic_cast<flutter::PlatformView*>(&platform_view);
  EXPECT_TRUE(base_view);

  // JSON for the message to be passed into the PlatformView.
  const uint8_t txt[] =
      "{"
      "    \"method\":\"View.update\","
      "    \"args\": {"
      "       \"viewId\":42,"
      "       \"hitTestable\":true,"
      "       \"focusable\":true"
      "    }"
      "}";

  fml::RefPtr<flutter::PlatformMessage> message =
      fml::MakeRefCounted<flutter::PlatformMessage>(
          "flutter/platform_views",
          std::vector<uint8_t>(txt, txt + sizeof(txt)),
          fml::RefPtr<flutter::PlatformMessageResponse>());
  base_view->HandlePlatformMessage(message);

  RunLoopUntilIdle();

  EXPECT_TRUE(update_view_called);
}

// This test makes sure that the PlatformView forwards messages on the
// "flutter/platform_views" channel for DestroyView.
TEST_F(PlatformViewTests, DestroyViewTest) {
  sys::testing::ServiceDirectoryProvider services_provider(dispatcher());
  MockPlatformViewDelegate delegate;
  flutter::TaskRunners task_runners =
      flutter::TaskRunners("test_runners", nullptr, nullptr, nullptr, nullptr);

  // Test wireframe callback function. If the message sent to the platform
  // view was properly handled and parsed, this function should be called,
  // setting |wireframe_enabled| to true.
  int64_t destroy_view_called = false;
  auto DestroyViewCallback = [&destroy_view_called](int64_t view_id) {
    destroy_view_called = true;
  };

  auto platform_view = flutter_runner::PlatformView(
      delegate,                               // delegate
      "test_platform_view",                   // label
      fuchsia::ui::views::ViewRef(),          // view_ref
      std::move(task_runners),                // task_runners
      services_provider.service_directory(),  // runner_services
      nullptr,                 // parent_environment_service_provider_handle
      nullptr,                 // session_listener_request
      nullptr,                 // focuser,
      nullptr,                 // on_session_listener_error_callback
      nullptr,                 // on_enable_wireframe_callback,
      nullptr,                 // on_create_view_callback,
      nullptr,                 // on_update_view_callback,
      DestroyViewCallback,     // on_destroy_view_callback,
      nullptr,                 // on_create_surface_callback,
      nullptr,                 // external_view_embedder,
      fml::TimeDelta::Zero(),  // vsync_offset
      ZX_HANDLE_INVALID        // vsync_event_handle
  );

  // Cast platform_view to its base view so we can have access to the public
  // "HandlePlatformMessage" function.
  auto base_view = dynamic_cast<flutter::PlatformView*>(&platform_view);
  EXPECT_TRUE(base_view);

  // JSON for the message to be passed into the PlatformView.
  const uint8_t txt[] =
      "{"
      "    \"method\":\"View.dispose\","
      "    \"args\": {"
      "       \"viewId\":42"
      "    }"
      "}";

  fml::RefPtr<flutter::PlatformMessage> message =
      fml::MakeRefCounted<flutter::PlatformMessage>(
          "flutter/platform_views",
          std::vector<uint8_t>(txt, txt + sizeof(txt)),
          fml::RefPtr<flutter::PlatformMessageResponse>());
  base_view->HandlePlatformMessage(message);

  RunLoopUntilIdle();

  EXPECT_TRUE(destroy_view_called);
}

// This test makes sure that the PlatformView forwards messages on the
// "flutter/platform_views" channel for ViewConnected, ViewDisconnected, and
// ViewStateChanged events.
TEST_F(PlatformViewTests, ViewEventsTest) {
  MockPlatformViewDelegate delegate;

  fuchsia::ui::scenic::SessionListenerPtr session_listener;
  std::vector<fuchsia::ui::scenic::Event> events;
  sys::testing::ServiceDirectoryProvider services_provider(dispatcher());

  flutter::TaskRunners task_runners = flutter::TaskRunners(
      "test_runners", nullptr, nullptr,
      flutter_runner::CreateFMLTaskRunner(async_get_default_dispatcher()),
      nullptr);

  auto platform_view = flutter_runner::PlatformView(
      delegate,                               // delegate
      "test_platform_view",                   // label
      fuchsia::ui::views::ViewRef(),          // view_ref
      std::move(task_runners),                // task_runners
      services_provider.service_directory(),  // runner_services
      nullptr,  // parent_environment_service_provider_handle
      session_listener.NewRequest(),  // session_listener_request
      nullptr,                        // focuser,
      nullptr,                        // on_session_listener_error_callback
      nullptr,                        // on_enable_wireframe_callback,
      nullptr,                        // on_create_view_callback,
      nullptr,                        // on_update_view_callback,
      nullptr,                        // on_destroy_view_callback,
      nullptr,                        // on_create_surface_callback,
      nullptr,                        // external_view_embedder,
      fml::TimeDelta::Zero(),         // vsync_offset
      ZX_HANDLE_INVALID               // vsync_event_handle
  );
  RunLoopUntilIdle();

  // ViewConnected event.
  events.clear();
  events.emplace_back(fuchsia::ui::scenic::Event::WithGfx(
      fuchsia::ui::gfx::Event::WithViewConnected(
          fuchsia::ui::gfx::ViewConnectedEvent{
              .view_holder_id = 0,
          })));
  session_listener->OnScenicEvent(std::move(events));
  RunLoopUntilIdle();

  auto data = delegate.message()->data();
  auto call = std::string(data.begin(), data.end());
  std::string expected = "{\"method\":\"View.viewConnected\",\"args\":null}";
  EXPECT_EQ(expected, call);

  // ViewDisconnected event.
  events.clear();
  events.emplace_back(fuchsia::ui::scenic::Event::WithGfx(
      fuchsia::ui::gfx::Event::WithViewDisconnected(
          fuchsia::ui::gfx::ViewDisconnectedEvent{
              .view_holder_id = 0,
          })));
  session_listener->OnScenicEvent(std::move(events));
  RunLoopUntilIdle();

  data = delegate.message()->data();
  call = std::string(data.begin(), data.end());
  expected = "{\"method\":\"View.viewDisconnected\",\"args\":null}";
  EXPECT_EQ(expected, call);

  // ViewStateChanged event.
  events.clear();
  events.emplace_back(fuchsia::ui::scenic::Event::WithGfx(
      fuchsia::ui::gfx::Event::WithViewStateChanged(
          fuchsia::ui::gfx::ViewStateChangedEvent{
              .view_holder_id = 0,
              .state =
                  fuchsia::ui::gfx::ViewState{
                      .is_rendering = true,
                  },
          })));
  session_listener->OnScenicEvent(std::move(events));
  RunLoopUntilIdle();

  data = delegate.message()->data();
  call = std::string(data.begin(), data.end());
  expected = "{\"method\":\"View.viewStateChanged\",\"args\":{\"state\":true}}";
  EXPECT_EQ(expected, call);
}

// This test makes sure that the PlatformView forwards messages on the
// "flutter/platform_views" channel for RequestFocus.
TEST_F(PlatformViewTests, RequestFocusTest) {
  sys::testing::ServiceDirectoryProvider services_provider(dispatcher());
  MockPlatformViewDelegate delegate;
  flutter::TaskRunners task_runners =
      flutter::TaskRunners("test_runners", nullptr, nullptr, nullptr, nullptr);

  MockFocuser mock_focuser;
  fidl::BindingSet<fuchsia::ui::views::Focuser> focuser_bindings;
  auto focuser_handle = focuser_bindings.AddBinding(&mock_focuser);

  auto platform_view = flutter_runner::PlatformView(
      delegate,                               // delegate
      "test_platform_view",                   // label
      fuchsia::ui::views::ViewRef(),          // view_ref
      std::move(task_runners),                // task_runners
      services_provider.service_directory(),  // runner_services
      nullptr,                    // parent_environment_service_provider_handle
      nullptr,                    // session_listener_request
      std::move(focuser_handle),  // focuser,
      nullptr,                    // on_session_listener_error_callback
      nullptr,                    // on_enable_wireframe_callback,
      nullptr,                    // on_create_view_callback,
      nullptr,                    // on_update_view_callback,
      nullptr,                    // on_destroy_view_callback,
      nullptr,                    // on_create_surface_callback,
      nullptr,                    // external_view_embedder,
      fml::TimeDelta::Zero(),     // vsync_offset
      ZX_HANDLE_INVALID           // vsync_event_handle
  );

  // Cast platform_view to its base view so we can have access to the public
  // "HandlePlatformMessage" function.
  auto base_view = dynamic_cast<flutter::PlatformView*>(&platform_view);
  EXPECT_TRUE(base_view);

  // This "Mock" ViewRef serves as the target for the RequestFocus operation.
  auto mock_view_ref_pair = scenic::ViewRefPair::New();

  // JSON for the message to be passed into the PlatformView.
  char buff[254];
  snprintf(buff, sizeof(buff),
           "{"
           "    \"method\":\"View.requestFocus\","
           "    \"args\": {"
           "       \"viewRef\":%u"
           "    }"
           "}",
           mock_view_ref_pair.view_ref.reference.get());

  // Define a custom gmock matcher to capture the response to platform message.
  struct DataArg {
    void Complete(std::unique_ptr<fml::Mapping> data) {
      this->data = std::move(data);
    }
    std::unique_ptr<fml::Mapping> data;
  };
  DataArg data_arg;
  fml::RefPtr<MockResponse> response = fml::MakeRefCounted<MockResponse>();
  EXPECT_CALL(*response, Complete(::testing::_))
      .WillOnce(::testing::Invoke(&data_arg, &DataArg::Complete));

  fml::RefPtr<flutter::PlatformMessage> message =
      fml::MakeRefCounted<flutter::PlatformMessage>(
          "flutter/platform_views",
          std::vector<uint8_t>(buff, buff + sizeof(buff)), response);
  base_view->HandlePlatformMessage(message);

  RunLoopUntilIdle();

  EXPECT_TRUE(mock_focuser.request_focus_called());
  auto result = std::string((const char*)data_arg.data->GetMapping(),
                            data_arg.data->GetSize());
  EXPECT_EQ(std::string("[0]"), result);
}

// This test makes sure that the PlatformView correctly replies with an error
// response when a RequestFocus call fails.
TEST_F(PlatformViewTests, RequestFocusFailTest) {
  sys::testing::ServiceDirectoryProvider services_provider(dispatcher());
  MockPlatformViewDelegate delegate;
  flutter::TaskRunners task_runners =
      flutter::TaskRunners("test_runners", nullptr, nullptr, nullptr, nullptr);

  MockFocuser mock_focuser(true /*fail_request_focus*/);
  fidl::BindingSet<fuchsia::ui::views::Focuser> focuser_bindings;
  auto focuser_handle = focuser_bindings.AddBinding(&mock_focuser);

  auto platform_view = flutter_runner::PlatformView(
      delegate,                               // delegate
      "test_platform_view",                   // label
      fuchsia::ui::views::ViewRef(),          // view_ref
      std::move(task_runners),                // task_runners
      services_provider.service_directory(),  // runner_services
      nullptr,                    // parent_environment_service_provider_handle
      nullptr,                    // session_listener_request
      std::move(focuser_handle),  // focuser,
      nullptr,                    // on_session_listener_error_callback
      nullptr,                    // on_enable_wireframe_callback,
      nullptr,                    // on_create_view_callback,
      nullptr,                    // on_update_view_callback,
      nullptr,                    // on_destroy_view_callback,
      nullptr,                    // on_create_surface_callback,
      nullptr,                    // external_view_embedder,
      fml::TimeDelta::Zero(),     // vsync_offset
      ZX_HANDLE_INVALID           // vsync_event_handle
  );

  // Cast platform_view to its base view so we can have access to the public
  // "HandlePlatformMessage" function.
  auto base_view = dynamic_cast<flutter::PlatformView*>(&platform_view);
  EXPECT_TRUE(base_view);

  // This "Mock" ViewRef serves as the target for the RequestFocus operation.
  auto mock_view_ref_pair = scenic::ViewRefPair::New();

  // JSON for the message to be passed into the PlatformView.
  char buff[254];
  snprintf(buff, sizeof(buff),
           "{"
           "    \"method\":\"View.requestFocus\","
           "    \"args\": {"
           "       \"viewRef\":%u"
           "    }"
           "}",
           mock_view_ref_pair.view_ref.reference.get());

  // Define a custom gmock matcher to capture the response to platform message.
  struct DataArg {
    void Complete(std::unique_ptr<fml::Mapping> data) {
      this->data = std::move(data);
    }
    std::unique_ptr<fml::Mapping> data;
  };
  DataArg data_arg;
  fml::RefPtr<MockResponse> response = fml::MakeRefCounted<MockResponse>();
  EXPECT_CALL(*response, Complete(::testing::_))
      .WillOnce(::testing::Invoke(&data_arg, &DataArg::Complete));

  fml::RefPtr<flutter::PlatformMessage> message =
      fml::MakeRefCounted<flutter::PlatformMessage>(
          "flutter/platform_views",
          std::vector<uint8_t>(buff, buff + sizeof(buff)), response);
  base_view->HandlePlatformMessage(message);

  RunLoopUntilIdle();

  EXPECT_TRUE(mock_focuser.request_focus_called());
  auto result = std::string((const char*)data_arg.data->GetMapping(),
                            data_arg.data->GetSize());
  std::ostringstream out;
  out << "["
      << static_cast<std::underlying_type_t<fuchsia::ui::views::Error>>(
             fuchsia::ui::views::Error::DENIED)
      << "]";
  EXPECT_EQ(out.str(), result);
}

}  // namespace flutter_runner::testing
