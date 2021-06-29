// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
#include "flutter/shell/common/context_options.h"
#include "flutter/shell/platform/fuchsia/flutter/platform_view.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"
#include "surface.h"
#include "task_runner_adapter.h"
#include "tests/fakes/focuser.h"
#include "tests/fakes/platform_message.h"
#include "tests/fakes/view_ref_focused.h"

namespace flutter_runner::testing {
namespace {

std::string ToString(const fml::Mapping& mapping) {
  return std::string(mapping.GetMapping(),
                     mapping.GetMapping() + mapping.GetSize());
}

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
                   const std::shared_ptr<const fml::SyncSwitch>&
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
  void Reset() {
    message_ = nullptr;
    metrics_ = flutter::ViewportMetrics{};
    semantics_features_ = 0;
    semantics_enabled_ = false;
  }

  // |flutter::PlatformView::Delegate|
  void OnPlatformViewCreated(std::unique_ptr<flutter::Surface> surface) {
    ASSERT_EQ(surface_.get(), nullptr);

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
      std::unique_ptr<flutter::PlatformMessage> message) {
    message_ = std::move(message);
  }
  // |flutter::PlatformView::Delegate|
  void OnPlatformViewDispatchPointerDataPacket(
      std::unique_ptr<flutter::PointerDataPacket> packet) {}
  // |flutter::PlatformView::Delegate|
  void OnPlatformViewDispatchKeyDataPacket(
      std::unique_ptr<flutter::KeyDataPacket> packet,
      std::function<void(bool)> callback) {}
  // |flutter::PlatformView::Delegate|
  void OnPlatformViewDispatchSemanticsAction(int32_t id,
                                             flutter::SemanticsAction action,
                                             fml::MallocMapping args) {}
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
  // |flutter::PlatformView::Delegate|
  void LoadDartDeferredLibrary(
      intptr_t loading_unit_id,
      std::unique_ptr<const fml::Mapping> snapshot_data,
      std::unique_ptr<const fml::Mapping> snapshot_instructions) {}
  // |flutter::PlatformView::Delegate|
  void LoadDartDeferredLibraryError(intptr_t loading_unit_id,
                                    const std::string error_message,
                                    bool transient) {}
  // |flutter::PlatformView::Delegate|
  void UpdateAssetResolverByType(
      std::unique_ptr<flutter::AssetResolver> updated_asset_resolver,
      flutter::AssetResolver::AssetResolverType type) {}

  flutter::Surface* surface() const { return surface_.get(); }
  flutter::PlatformMessage* message() const { return message_.get(); }
  const flutter::ViewportMetrics& metrics() const { return metrics_; }
  int32_t semantics_features() const { return semantics_features_; }
  bool semantics_enabled() const { return semantics_enabled_; }

 private:
  std::unique_ptr<flutter::Surface> surface_;
  std::unique_ptr<flutter::PlatformMessage> message_;
  flutter::ViewportMetrics metrics_;
  int32_t semantics_features_ = 0;
  bool semantics_enabled_ = false;
};

class MockResponse : public flutter::PlatformMessageResponse {
 public:
  MOCK_METHOD1(Complete, void(std::unique_ptr<fml::Mapping> data));
  MOCK_METHOD0(CompleteEmpty, void());
};

// Used to construct partial instances of PlatformView for testing.  The
// PlatformView constructor has many parameters, not all of which need to
// be filled out for each test.  The builder allows you to initialize only
// those that matter to your specific test.  Not all builder methods are
// provided: if you find some that are missing, feel free to add them.
class PlatformViewBuilder {
 public:
  PlatformViewBuilder(flutter::PlatformView::Delegate& delegate,
                      flutter::TaskRunners task_runners,
                      std::shared_ptr<sys::ServiceDirectory> runner_services)
      : delegate_(delegate),
        debug_label_("test_platform_view"),
        view_ref_(fuchsia::ui::views::ViewRef()),
        task_runners_(task_runners),
        runner_services_(runner_services) {}

  // Add builder methods as required.

  PlatformViewBuilder& SetServiceProvider(
      fidl::InterfaceHandle<fuchsia::sys::ServiceProvider> service_provider) {
    parent_environment_service_provider_ = std::move(service_provider);
    return *this;
  }

  PlatformViewBuilder& SetViewRefFocused(
      fidl::InterfaceHandle<fuchsia::ui::views::ViewRefFocused> vrf) {
    vrf_ = std::move(vrf);
    return *this;
  }

  PlatformViewBuilder& SetFocuser(
      fidl::InterfaceHandle<fuchsia::ui::views::Focuser> focuser) {
    focuser_ = std::move(focuser);
    return *this;
  }

  PlatformViewBuilder& SetDestroyViewCallback(OnDestroyView callback) {
    on_destroy_view_callback_ = std::move(callback);
    return *this;
  }

  PlatformViewBuilder& SetUpdateViewCallback(OnUpdateView callback) {
    on_update_view_callback_ = std::move(callback);
    return *this;
  }

  PlatformViewBuilder& SetEnableWireframeCallback(OnEnableWireframe callback) {
    wireframe_enabled_callback_ = std::move(callback);
    return *this;
  }

  PlatformViewBuilder& SetCreateViewCallback(OnCreateView callback) {
    on_create_view_callback_ = std::move(callback);
    return *this;
  }

  PlatformViewBuilder& SetShaderWarmupCallback(OnShaderWarmup callback) {
    on_shader_warmup_callback_ = std::move(callback);
    return *this;
  }

  PlatformViewBuilder& SetSessionListenerRequest(
      fidl::InterfaceRequest<fuchsia::ui::scenic::SessionListener> request) {
    session_listener_request_ = std::move(request);
    return *this;
  }

  PlatformViewBuilder& SetCreateSurfaceCallback(OnCreateSurface callback) {
    on_create_surface_callback_ = std::move(callback);
    return *this;
  }

  PlatformViewBuilder& SetViewEmbedder(
      std::shared_ptr<flutter::ExternalViewEmbedder> embedder) {
    view_embedder_ = embedder;
    return *this;
  }

  PlatformViewBuilder& SetKeyboardListener(
      fidl::InterfaceRequest<fuchsia::ui::input3::KeyboardListener> listener) {
    keyboard_listener_ = std::move(listener);
    return *this;
  }

  // Once Build is called, the instance is no longer usable.
  PlatformView Build() {
    EXPECT_FALSE(std::exchange(built_, true))
        << "Build() was already called, this buider is good for one use only.";
    return PlatformView(
        delegate_, debug_label_, std::move(view_ref_), task_runners_,
        runner_services_, std::move(parent_environment_service_provider_),
        std::move(session_listener_request_), std::move(vrf_),
        std::move(focuser_), std::move(keyboard_listener_),
        std::move(on_session_listener_error_callback_),
        std::move(wireframe_enabled_callback_),
        std::move(on_create_view_callback_),
        std::move(on_update_view_callback_),
        std::move(on_destroy_view_callback_),
        std::move(on_create_surface_callback_),
        std::move(on_semantics_node_update_callback_),
        std::move(on_request_announce_callback_),
        std::move(on_shader_warmup_callback_), view_embedder_, [](auto...) {},
        [](auto...) {});
  }

 private:
  PlatformViewBuilder() = delete;

  bool built_{false};

  // Required elements.  Make sure to initialize them.
  flutter::PlatformView::Delegate& delegate_;
  std::string debug_label_;
  fuchsia::ui::views::ViewRef view_ref_;
  flutter::TaskRunners task_runners_;
  std::shared_ptr<sys::ServiceDirectory> runner_services_{nullptr};
  fidl::InterfaceHandle<fuchsia::sys::ServiceProvider>
      parent_environment_service_provider_{nullptr};

  // Optional elements.
  fidl::InterfaceRequest<fuchsia::ui::scenic::SessionListener>
      session_listener_request_{nullptr};
  fidl::InterfaceHandle<fuchsia::ui::views::ViewRefFocused> vrf_{nullptr};
  fidl::InterfaceHandle<fuchsia::ui::views::Focuser> focuser_{nullptr};
  fidl::InterfaceRequest<fuchsia::ui::input3::KeyboardListener>
      keyboard_listener_{nullptr};
  fit::closure on_session_listener_error_callback_{nullptr};
  OnEnableWireframe wireframe_enabled_callback_{nullptr};
  OnCreateView on_create_view_callback_{nullptr};
  OnUpdateView on_update_view_callback_{nullptr};
  OnDestroyView on_destroy_view_callback_{nullptr};
  OnCreateSurface on_create_surface_callback_{nullptr};
  OnSemanticsNodeUpdate on_semantics_node_update_callback_{nullptr};
  OnRequestAnnounce on_request_announce_callback_{nullptr};
  OnShaderWarmup on_shader_warmup_callback_{nullptr};
  std::shared_ptr<flutter::ExternalViewEmbedder> view_embedder_{nullptr};
  fml::TimeDelta vsync_offset_{fml::TimeDelta::Zero()};
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

  fuchsia::ui::input3::KeyEvent MakeEvent(
      fuchsia::ui::input3::KeyEventType event_type,
      std::optional<fuchsia::ui::input3::Modifiers> modifiers,
      fuchsia::input::Key key) {
    fuchsia::ui::input3::KeyEvent event;
    event.set_timestamp(++event_timestamp_);
    event.set_type(event_type);
    if (modifiers.has_value()) {
      event.set_modifiers(modifiers.value());
    }
    event.set_key(key);
    return event;
  }

 private:
  async::Loop loop_;

  uint64_t event_timestamp_{42};

  FML_DISALLOW_COPY_AND_ASSIGN(PlatformViewTests);
};

// This test makes sure that the PlatformView always completes a platform
// message request, even for error conditions or if the request is malformed.
TEST_F(PlatformViewTests, InvalidPlatformMessageRequest) {
  sys::testing::ServiceDirectoryProvider services_provider(dispatcher());
  MockPlatformViewDelegate delegate;
  flutter::TaskRunners task_runners =
      flutter::TaskRunners("test_runners", nullptr, nullptr, nullptr, nullptr);

  FakeViewRefFocused vrf;
  fidl::BindingSet<fuchsia::ui::views::ViewRefFocused> vrf_bindings;
  auto vrf_handle = vrf_bindings.AddBinding(&vrf);

  flutter_runner::PlatformView platform_view =
      PlatformViewBuilder(delegate, std::move(task_runners),
                          services_provider.service_directory())
          .SetViewRefFocused(std::move(vrf_handle))
          .Build();

  // Cast platform_view to its base view so we can have access to the public
  // "HandlePlatformMessage" function.
  auto base_view = static_cast<flutter::PlatformView*>(&platform_view);
  EXPECT_TRUE(base_view);

  // Invalid platform channel.
  auto response1 = FakePlatformMessageResponse::Create();
  base_view->HandlePlatformMessage(response1->WithMessage(
      "flutter/invalid", "{\"method\":\"Invalid.invalidMethod\"}"));

  // Invalid json.
  auto response2 = FakePlatformMessageResponse::Create();
  base_view->HandlePlatformMessage(
      response2->WithMessage("flutter/platform_views", "{Invalid JSON"));

  // Invalid method.
  auto response3 = FakePlatformMessageResponse::Create();
  base_view->HandlePlatformMessage(response3->WithMessage(
      "flutter/platform_views", "{\"method\":\"View.focus.invalidMethod\"}"));

  // Missing arguments.
  auto response4 = FakePlatformMessageResponse::Create();
  base_view->HandlePlatformMessage(response4->WithMessage(
      "flutter/platform_views", "{\"method\":\"View.update\"}"));
  auto response5 = FakePlatformMessageResponse::Create();
  base_view->HandlePlatformMessage(
      response5->WithMessage("flutter/platform_views",
                             "{\"method\":\"View.update\",\"args\":{"
                             "\"irrelevantField\":\"irrelevantValue\"}}"));

  // Wrong argument types.
  auto response6 = FakePlatformMessageResponse::Create();
  base_view->HandlePlatformMessage(response6->WithMessage(
      "flutter/platform_views",
      "{\"method\":\"View.update\",\"args\":{\"viewId\":false,\"hitTestable\":"
      "123,\"focusable\":\"yes\"}}"));

  // Run the event loop and check our responses.
  RunLoopUntilIdle();
  response1->ExpectCompleted("");
  response2->ExpectCompleted("");
  response3->ExpectCompleted("");
  response4->ExpectCompleted("");
  response5->ExpectCompleted("");
  response6->ExpectCompleted("");
}

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
  sk_sp<GrDirectContext> gr_context = GrDirectContext::MakeMock(
      nullptr,
      flutter::MakeDefaultContextOptions(flutter::ContextType::kRender));
  std::shared_ptr<MockExternalViewEmbedder> view_embedder =
      std::make_shared<MockExternalViewEmbedder>();
  auto CreateSurfaceCallback = [&view_embedder, gr_context]() {
    return std::make_unique<flutter_runner::Surface>(
        "PlatformViewTest", view_embedder, gr_context.get());
  };

  flutter_runner::PlatformView platform_view =
      PlatformViewBuilder(delegate, std::move(task_runners),
                          services_provider.service_directory())
          .SetCreateSurfaceCallback(CreateSurfaceCallback)
          .SetViewEmbedder(view_embedder)
          .Build();
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
  flutter_runner::PlatformView platform_view =
      PlatformViewBuilder(delegate, std::move(task_runners),
                          services_provider.service_directory())
          .SetSessionListenerRequest(session_listener.NewRequest())
          .Build();
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

  // Test updating with an invalid size. The final metrics should be unchanged.
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

  flutter_runner::PlatformView platform_view =
      PlatformViewBuilder(
          delegate,                              // delegate
          std::move(task_runners),               // task_runners
          services_provider.service_directory()  // runner_services
          )
          .Build();

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

  flutter_runner::PlatformView platform_view =
      PlatformViewBuilder(delegate, std::move(task_runners),
                          services_provider.service_directory())
          .SetEnableWireframeCallback(EnableWireframeCallback)
          .Build();

  // Cast platform_view to its base view so we can have access to the public
  // "HandlePlatformMessage" function.
  auto base_view = static_cast<flutter::PlatformView*>(&platform_view);
  EXPECT_TRUE(base_view);

  // JSON for the message to be passed into the PlatformView.
  const uint8_t txt[] =
      "{"
      "    \"method\":\"View.enableWireframe\","
      "    \"args\": {"
      "       \"enable\":true"
      "    }"
      "}";

  std::unique_ptr<flutter::PlatformMessage> message =
      std::make_unique<flutter::PlatformMessage>(
          "flutter/platform_views", fml::MallocMapping::Copy(txt, sizeof(txt)),
          fml::RefPtr<flutter::PlatformMessageResponse>());
  base_view->HandlePlatformMessage(std::move(message));

  RunLoopUntilIdle();

  EXPECT_TRUE(wireframe_enabled);
}

// This test makes sure that the PlatformView forwards messages on the
// "flutter/platform_views" channel for Createview.
TEST_F(PlatformViewTests, CreateViewTest) {
  sys::testing::ServiceDirectoryProvider services_provider(dispatcher());
  MockPlatformViewDelegate delegate;
  flutter::TaskRunners task_runners =
      flutter::TaskRunners("test_runners",  // label
                           flutter_runner::CreateFMLTaskRunner(
                               async_get_default_dispatcher()),  // platform
                           nullptr,                              // raster
                           nullptr,                              // ui
                           nullptr                               // io
      );

  // Test wireframe callback function. If the message sent to the platform
  // view was properly handled and parsed, this function should be called,
  // setting |wireframe_enabled| to true.
  bool create_view_called = false;
  auto CreateViewCallback = [&create_view_called](
                                int64_t view_id,
                                flutter_runner::ViewCallback on_view_created,
                                flutter_runner::ViewIdCallback on_view_bound,
                                bool hit_testable, bool focusable) {
    create_view_called = true;
    on_view_created();
    on_view_bound(0);
  };

  flutter_runner::PlatformView platform_view =
      PlatformViewBuilder(delegate, std::move(task_runners),
                          services_provider.service_directory())
          .SetCreateViewCallback(CreateViewCallback)
          .Build();

  // Cast platform_view to its base view so we can have access to the public
  // "HandlePlatformMessage" function.
  auto base_view = static_cast<flutter::PlatformView*>(&platform_view);
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

  std::unique_ptr<flutter::PlatformMessage> message =
      std::make_unique<flutter::PlatformMessage>(
          "flutter/platform_views", fml::MallocMapping::Copy(txt, sizeof(txt)),
          fml::RefPtr<flutter::PlatformMessageResponse>());
  base_view->HandlePlatformMessage(std::move(message));

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

  std::optional<SkRect> occlusion_hint_for_test;
  std::optional<bool> hit_testable_for_test;
  std::optional<bool> focusable_for_test;
  auto UpdateViewCallback = [&occlusion_hint_for_test, &hit_testable_for_test,
                             &focusable_for_test](
                                int64_t view_id, SkRect occlusion_hint,
                                bool hit_testable, bool focusable) {
    occlusion_hint_for_test = occlusion_hint;
    hit_testable_for_test = hit_testable;
    focusable_for_test = focusable;
  };

  flutter_runner::PlatformView platform_view =
      PlatformViewBuilder(delegate, std::move(task_runners),
                          services_provider.service_directory())
          .SetUpdateViewCallback(UpdateViewCallback)
          .Build();

  // Cast platform_view to its base view so we can have access to the public
  // "HandlePlatformMessage" function.
  auto base_view = static_cast<flutter::PlatformView*>(&platform_view);
  EXPECT_TRUE(base_view);

  // Send a basic message.
  const uint8_t json[] =
      "{"
      "    \"method\":\"View.update\","
      "    \"args\": {"
      "       \"viewId\":42,"
      "       \"hitTestable\":true,"
      "       \"focusable\":true"
      "    }"
      "}";
  std::unique_ptr<flutter::PlatformMessage> message =
      std::make_unique<flutter::PlatformMessage>(
          "flutter/platform_views",
          fml::MallocMapping::Copy(json, sizeof(json)),
          fml::RefPtr<flutter::PlatformMessageResponse>());
  base_view->HandlePlatformMessage(std::move(message));

  RunLoopUntilIdle();
  ASSERT_TRUE(occlusion_hint_for_test.has_value());
  ASSERT_TRUE(hit_testable_for_test.has_value());
  ASSERT_TRUE(focusable_for_test.has_value());
  EXPECT_EQ(occlusion_hint_for_test.value(), SkRect::MakeEmpty());
  EXPECT_EQ(hit_testable_for_test.value(), true);
  EXPECT_EQ(focusable_for_test.value(), true);

  // Reset for the next message.
  occlusion_hint_for_test.reset();
  hit_testable_for_test.reset();
  focusable_for_test.reset();

  // Send another basic message.
  const uint8_t json_false[] =
      "{"
      "    \"method\":\"View.update\","
      "    \"args\": {"
      "       \"viewId\":42,"
      "       \"hitTestable\":false,"
      "       \"focusable\":false"
      "    }"
      "}";
  std::unique_ptr<flutter::PlatformMessage> message_false =
      std::make_unique<flutter::PlatformMessage>(
          "flutter/platform_views",
          fml::MallocMapping::Copy(json_false, sizeof(json_false)),
          fml::RefPtr<flutter::PlatformMessageResponse>());
  base_view->HandlePlatformMessage(std::move(message_false));
  RunLoopUntilIdle();
  ASSERT_TRUE(occlusion_hint_for_test.has_value());
  ASSERT_TRUE(hit_testable_for_test.has_value());
  ASSERT_TRUE(focusable_for_test.has_value());
  EXPECT_EQ(occlusion_hint_for_test.value(), SkRect::MakeEmpty());
  EXPECT_EQ(hit_testable_for_test.value(), false);
  EXPECT_EQ(focusable_for_test.value(), false);

  // Reset for the next message.
  occlusion_hint_for_test.reset();
  hit_testable_for_test.reset();
  focusable_for_test.reset();

  // Send a message including an occlusion hint.
  const uint8_t json_occlusion_hint[] =
      "{"
      "    \"method\":\"View.update\","
      "    \"args\": {"
      "       \"viewId\":42,"
      "       \"hitTestable\":true,"
      "       \"focusable\":true,"
      "       \"viewOcclusionHintLTRB\":[0.1,0.2,0.3,0.4]"
      "    }"
      "}";
  std::unique_ptr<flutter::PlatformMessage> message_occlusion_hint =
      std::make_unique<flutter::PlatformMessage>(
          "flutter/platform_views",
          fml::MallocMapping::Copy(json_occlusion_hint,
                                   sizeof(json_occlusion_hint)),
          fml::RefPtr<flutter::PlatformMessageResponse>());
  base_view->HandlePlatformMessage(std::move(message_occlusion_hint));
  RunLoopUntilIdle();
  ASSERT_TRUE(occlusion_hint_for_test.has_value());
  ASSERT_TRUE(hit_testable_for_test.has_value());
  ASSERT_TRUE(focusable_for_test.has_value());
  EXPECT_EQ(occlusion_hint_for_test.value(),
            SkRect::MakeLTRB(0.1, 0.2, 0.3, 0.4));
  EXPECT_EQ(hit_testable_for_test.value(), true);
  EXPECT_EQ(focusable_for_test.value(), true);
}

// This test makes sure that the PlatformView forwards messages on the
// "flutter/platform_views" channel for DestroyView.
TEST_F(PlatformViewTests, DestroyViewTest) {
  sys::testing::ServiceDirectoryProvider services_provider(dispatcher());
  MockPlatformViewDelegate delegate;
  flutter::TaskRunners task_runners =
      flutter::TaskRunners("test_runners",  // label
                           flutter_runner::CreateFMLTaskRunner(
                               async_get_default_dispatcher()),  // platform
                           nullptr,                              // raster
                           nullptr,                              // ui
                           nullptr                               // io
      );

  // Test wireframe callback function. If the message sent to the platform
  // view was properly handled and parsed, this function should be called,
  // setting |wireframe_enabled| to true.
  bool destroy_view_called = false;
  auto DestroyViewCallback =
      [&destroy_view_called](int64_t view_id,
                             flutter_runner::ViewIdCallback on_view_unbound) {
        destroy_view_called = true;
        on_view_unbound(0);
      };

  flutter_runner::PlatformView platform_view =
      PlatformViewBuilder(delegate, std::move(task_runners),
                          services_provider.service_directory())
          .SetDestroyViewCallback(DestroyViewCallback)
          .Build();

  // Cast platform_view to its base view so we can have access to the public
  // "HandlePlatformMessage" function.
  auto base_view = static_cast<flutter::PlatformView*>(&platform_view);
  EXPECT_TRUE(base_view);

  // JSON for the message to be passed into the PlatformView.
  const uint8_t txt[] =
      "{"
      "    \"method\":\"View.dispose\","
      "    \"args\": {"
      "       \"viewId\":42"
      "    }"
      "}";

  std::unique_ptr<flutter::PlatformMessage> message =
      std::make_unique<flutter::PlatformMessage>(
          "flutter/platform_views", fml::MallocMapping::Copy(txt, sizeof(txt)),
          fml::RefPtr<flutter::PlatformMessageResponse>());
  base_view->HandlePlatformMessage(std::move(message));

  RunLoopUntilIdle();

  EXPECT_TRUE(destroy_view_called);
}

// This test makes sure that the PlatformView forwards messages on the
// "flutter/platform_views" channel for ViewConnected, ViewDisconnected, and
// ViewStateChanged events.
TEST_F(PlatformViewTests, ViewEventsTest) {
  constexpr int64_t kViewId = 33;
  constexpr scenic::ResourceId kViewHolderId = 42;
  MockPlatformViewDelegate delegate;

  fuchsia::ui::scenic::SessionListenerPtr session_listener;
  std::vector<fuchsia::ui::scenic::Event> events;
  sys::testing::ServiceDirectoryProvider services_provider(dispatcher());
  flutter::TaskRunners task_runners =
      flutter::TaskRunners("test_runners",  // label
                           flutter_runner::CreateFMLTaskRunner(
                               async_get_default_dispatcher()),  // platform
                           flutter_runner::CreateFMLTaskRunner(
                               async_get_default_dispatcher()),  // raster
                           flutter_runner::CreateFMLTaskRunner(
                               async_get_default_dispatcher()),  // ui
                           nullptr                               // io
      );

  auto on_create_view = [kViewId](int64_t view_id,
                                  flutter_runner::ViewCallback on_view_created,
                                  flutter_runner::ViewIdCallback on_view_bound,
                                  bool hit_testable, bool focusable) {
    ASSERT_EQ(view_id, kViewId);
    on_view_created();
    on_view_bound(kViewHolderId);
  };

  flutter_runner::PlatformView platform_view =
      PlatformViewBuilder(delegate, std::move(task_runners),
                          services_provider.service_directory())
          .SetSessionListenerRequest(session_listener.NewRequest())
          .SetCreateViewCallback(on_create_view)
          .Build();
  RunLoopUntilIdle();
  ASSERT_EQ(delegate.message(), nullptr);

  // Create initial view for testing.
  std::ostringstream create_view_message;
  create_view_message << "{"
                      << "  \"method\":\"View.create\","
                      << "  \"args\":{"
                      << "    \"viewId\":" << kViewId << ","
                      << "    \"hitTestable\":true,"
                      << "    \"focusable\":true"
                      << "  }"
                      << "}";
  std::string create_view_call = create_view_message.str();
  static_cast<flutter::PlatformView*>(&platform_view)
      ->HandlePlatformMessage(std::make_unique<flutter::PlatformMessage>(
          "flutter/platform_views",
          fml::MallocMapping::Copy(create_view_call.c_str(),
                                   create_view_call.size()),
          fml::RefPtr<flutter::PlatformMessageResponse>()));
  RunLoopUntilIdle();

  // ViewConnected event.
  delegate.Reset();
  events.clear();
  events.emplace_back(fuchsia::ui::scenic::Event::WithGfx(
      fuchsia::ui::gfx::Event::WithViewConnected(
          fuchsia::ui::gfx::ViewConnectedEvent{
              .view_holder_id = kViewHolderId,
          })));
  session_listener->OnScenicEvent(std::move(events));
  RunLoopUntilIdle();

  flutter::PlatformMessage* view_connected_msg = delegate.message();
  ASSERT_NE(view_connected_msg, nullptr);
  std::ostringstream view_connected_expected_out;
  view_connected_expected_out
      << "{"
      << "\"method\":\"View.viewConnected\","
      << "\"args\":{"
      << "  \"viewId\":" << kViewId  // ViewHolderToken handle
      << "  }"
      << "}";
  EXPECT_EQ(view_connected_expected_out.str(),
            ToString(view_connected_msg->data()));

  // ViewDisconnected event.
  delegate.Reset();
  events.clear();
  events.emplace_back(fuchsia::ui::scenic::Event::WithGfx(
      fuchsia::ui::gfx::Event::WithViewDisconnected(
          fuchsia::ui::gfx::ViewDisconnectedEvent{
              .view_holder_id = kViewHolderId,
          })));
  session_listener->OnScenicEvent(std::move(events));
  RunLoopUntilIdle();

  flutter::PlatformMessage* view_disconnected_msg = delegate.message();
  ASSERT_NE(view_disconnected_msg, nullptr);
  std::ostringstream view_disconnected_expected_out;
  view_disconnected_expected_out
      << "{"
      << "\"method\":\"View.viewDisconnected\","
      << "\"args\":{"
      << "  \"viewId\":" << kViewId  // ViewHolderToken handle
      << "  }"
      << "}";
  EXPECT_EQ(view_disconnected_expected_out.str(),
            ToString(view_disconnected_msg->data()));

  // ViewStateChanged event.
  delegate.Reset();
  events.clear();
  events.emplace_back(fuchsia::ui::scenic::Event::WithGfx(
      fuchsia::ui::gfx::Event::WithViewStateChanged(
          fuchsia::ui::gfx::ViewStateChangedEvent{
              .view_holder_id = kViewHolderId,
              .state =
                  fuchsia::ui::gfx::ViewState{
                      .is_rendering = true,
                  },
          })));
  session_listener->OnScenicEvent(std::move(events));
  RunLoopUntilIdle();

  flutter::PlatformMessage* view_state_changed_msg = delegate.message();
  ASSERT_NE(view_state_changed_msg, nullptr);
  std::ostringstream view_state_changed_expected_out;
  view_state_changed_expected_out
      << "{"
      << "\"method\":\"View.viewStateChanged\","
      << "\"args\":{"
      << "  \"viewId\":" << kViewId << ","  // ViewHolderToken
      << "  \"is_rendering\":true,"         // IsViewRendering
      << "  \"state\":true"                 // IsViewRendering
      << "  }"
      << "}";
  EXPECT_EQ(view_state_changed_expected_out.str(),
            ToString(view_state_changed_msg->data()));
}

// This test makes sure that the PlatformView forwards messages on the
// "flutter/platform_views" channel for View.focus.getCurrent and
// View.focus.getNext.
TEST_F(PlatformViewTests, GetFocusStatesTest) {
  sys::testing::ServiceDirectoryProvider services_provider(dispatcher());
  MockPlatformViewDelegate delegate;
  flutter::TaskRunners task_runners =
      flutter::TaskRunners("test_runners", nullptr, nullptr, nullptr, nullptr);

  FakeViewRefFocused vrf;
  fidl::BindingSet<fuchsia::ui::views::ViewRefFocused> vrf_bindings;
  auto vrf_handle = vrf_bindings.AddBinding(&vrf);

  flutter_runner::PlatformView platform_view =
      PlatformViewBuilder(delegate, std::move(task_runners),
                          services_provider.service_directory())
          .SetViewRefFocused(std::move(vrf_handle))
          .Build();

  // Cast platform_view to its base view so we can have access to the public
  // "HandlePlatformMessage" function.
  auto base_view = static_cast<flutter::PlatformView*>(&platform_view);
  EXPECT_TRUE(base_view);

  std::vector<bool> vrf_states{false, true,  true, false,
                               true,  false, true, true};

  for (std::size_t i = 0; i < vrf_states.size(); ++i) {
    // View.focus.getNext should complete with the next focus state.
    auto response1 = FakePlatformMessageResponse::Create();
    base_view->HandlePlatformMessage(response1->WithMessage(
        "flutter/platform_views", "{\"method\":\"View.focus.getNext\"}"));
    // Duplicate View.focus.getNext requests should complete empty.
    auto response2 = FakePlatformMessageResponse::Create();
    base_view->HandlePlatformMessage(response2->WithMessage(
        "flutter/platform_views", "{\"method\":\"View.focus.getNext\"}"));

    // Post watch events and make sure the hanging get is invoked each time.
    RunLoopUntilIdle();
    EXPECT_EQ(vrf.times_watched, i + 1);

    // Dispatch the next vrf event.
    vrf.ScheduleCallback(vrf_states[i]);
    RunLoopUntilIdle();

    // Make sure View.focus.getCurrent completes with the current focus state.
    auto response3 = FakePlatformMessageResponse::Create();
    base_view->HandlePlatformMessage(response3->WithMessage(
        "flutter/platform_views", "{\"method\":\"View.focus.getCurrent\"}"));
    // Duplicate View.focus.getCurrent are allowed.
    auto response4 = FakePlatformMessageResponse::Create();
    base_view->HandlePlatformMessage(response4->WithMessage(
        "flutter/platform_views", "{\"method\":\"View.focus.getCurrent\"}"));

    // Run event loop and check our results.
    RunLoopUntilIdle();
    response1->ExpectCompleted(vrf_states[i] ? "[true]" : "[false]");
    response2->ExpectCompleted("[null]");
    response3->ExpectCompleted(vrf_states[i] ? "[true]" : "[false]");
    response4->ExpectCompleted(vrf_states[i] ? "[true]" : "[false]");
  }
}

// This test makes sure that the PlatformView forwards messages on the
// "flutter/platform_views" channel for View.focus.request.
TEST_F(PlatformViewTests, RequestFocusTest) {
  sys::testing::ServiceDirectoryProvider services_provider(dispatcher());
  MockPlatformViewDelegate delegate;
  flutter::TaskRunners task_runners =
      flutter::TaskRunners("test_runners", nullptr, nullptr, nullptr, nullptr);

  FakeFocuser focuser;
  fidl::BindingSet<fuchsia::ui::views::Focuser> focuser_bindings;
  auto focuser_handle = focuser_bindings.AddBinding(&focuser);

  flutter_runner::PlatformView platform_view =
      PlatformViewBuilder(delegate, std::move(task_runners),
                          services_provider.service_directory())
          .SetFocuser(std::move(focuser_handle))
          .Build();

  // Cast platform_view to its base view so we can have access to the public
  // "HandlePlatformMessage" function.
  auto base_view = static_cast<flutter::PlatformView*>(&platform_view);
  EXPECT_TRUE(base_view);

  // This "Mock" ViewRef serves as the target for the RequestFocus operation.
  auto mock_view_ref_pair = scenic::ViewRefPair::New();

  // JSON for the message to be passed into the PlatformView.
  std::ostringstream message;
  message << "{"
          << "    \"method\":\"View.focus.request\","
          << "    \"args\": {"
          << "       \"viewRef\":"
          << mock_view_ref_pair.view_ref.reference.get() << "    }"
          << "}";

  // Dispatch the plaform message request.
  auto response = FakePlatformMessageResponse::Create();
  base_view->HandlePlatformMessage(
      response->WithMessage("flutter/platform_views", message.str()));
  RunLoopUntilIdle();

  response->ExpectCompleted("[0]");
  EXPECT_TRUE(focuser.request_focus_called());
}

// This test makes sure that the PlatformView correctly replies with an error
// response when a View.focus.request call fails.
TEST_F(PlatformViewTests, RequestFocusFailTest) {
  sys::testing::ServiceDirectoryProvider services_provider(dispatcher());
  MockPlatformViewDelegate delegate;
  flutter::TaskRunners task_runners =
      flutter::TaskRunners("test_runners", nullptr, nullptr, nullptr, nullptr);

  FakeFocuser focuser;
  focuser.fail_request_focus();
  fidl::BindingSet<fuchsia::ui::views::Focuser> focuser_bindings;
  auto focuser_handle = focuser_bindings.AddBinding(&focuser);

  flutter_runner::PlatformView platform_view =
      PlatformViewBuilder(delegate, std::move(task_runners),
                          services_provider.service_directory())
          .SetFocuser(std::move(focuser_handle))
          .Build();

  // Cast platform_view to its base view so we can have access to the public
  // "HandlePlatformMessage" function.
  auto base_view = static_cast<flutter::PlatformView*>(&platform_view);
  EXPECT_TRUE(base_view);

  // This "Mock" ViewRef serves as the target for the RequestFocus operation.
  auto mock_view_ref_pair = scenic::ViewRefPair::New();

  // JSON for the message to be passed into the PlatformView.
  std::ostringstream message;
  message << "{"
          << "    \"method\":\"View.focus.request\","
          << "    \"args\": {"
          << "       \"viewRef\":"
          << mock_view_ref_pair.view_ref.reference.get() << "    }"
          << "}";

  // Dispatch the plaform message request.
  auto response = FakePlatformMessageResponse::Create();
  base_view->HandlePlatformMessage(
      response->WithMessage("flutter/platform_views", message.str()));
  RunLoopUntilIdle();

  response->ExpectCompleted(
      "[" +
      std::to_string(
          static_cast<std::underlying_type_t<fuchsia::ui::views::Error>>(
              fuchsia::ui::views::Error::DENIED)) +
      "]");
  EXPECT_TRUE(focuser.request_focus_called());
}

// This test makes sure that the PlatformView forwards messages on the
// "flutter/platform_views" channel for GetCurrentFocusState and
// GetNextFocusState.
// TODO(fxbug.dev/79740): Delete after soft transition.
TEST_F(PlatformViewTests, DeprecatedGetFocusStatesTest) {
  sys::testing::ServiceDirectoryProvider services_provider(dispatcher());
  MockPlatformViewDelegate delegate;
  flutter::TaskRunners task_runners =
      flutter::TaskRunners("test_runners", nullptr, nullptr, nullptr, nullptr);

  FakeViewRefFocused vrf;
  fidl::BindingSet<fuchsia::ui::views::ViewRefFocused> vrf_bindings;
  auto vrf_handle = vrf_bindings.AddBinding(&vrf);

  flutter_runner::PlatformView platform_view =
      PlatformViewBuilder(delegate, std::move(task_runners),
                          services_provider.service_directory())
          .SetViewRefFocused(std::move(vrf_handle))
          .Build();

  // Cast platform_view to its base view so we can have access to the public
  // "HandlePlatformMessage" function.
  auto base_view = static_cast<flutter::PlatformView*>(&platform_view);
  EXPECT_TRUE(base_view);

  std::vector<bool> vrf_states{false, true,  true, false,
                               true,  false, true, true};

  for (std::size_t i = 0; i < vrf_states.size(); ++i) {
    // HostView.getNextFocusState should complete with the next focus state.
    auto response1 = FakePlatformMessageResponse::Create();
    base_view->HandlePlatformMessage(
        response1->WithMessage("flutter/platform_views",
                               "{\"method\":\"HostView.getNextFocusState\"}"));
    // Duplicate HostView.getNextFocusState requests should complete empty.
    auto response2 = FakePlatformMessageResponse::Create();
    base_view->HandlePlatformMessage(
        response2->WithMessage("flutter/platform_views",
                               "{\"method\":\"HostView.getNextFocusState\"}"));

    // Post watch events and make sure the hanging get is invoked each time.
    RunLoopUntilIdle();
    EXPECT_EQ(vrf.times_watched, i + 1);

    // Dispatch the next vrf event.
    vrf.ScheduleCallback(vrf_states[i]);
    RunLoopUntilIdle();

    // Make sure HostView.getCurrentFocusState completes with the current focus
    // state.
    auto response3 = FakePlatformMessageResponse::Create();
    base_view->HandlePlatformMessage(response3->WithMessage(
        "flutter/platform_views",
        "{\"method\":\"HostView.getCurrentFocusState\"}"));
    // Duplicate HostView.getCurrentFocusState are allowed.
    auto response4 = FakePlatformMessageResponse::Create();
    base_view->HandlePlatformMessage(response4->WithMessage(
        "flutter/platform_views",
        "{\"method\":\"HostView.getCurrentFocusState\"}"));

    // Run event loop and check our results.
    RunLoopUntilIdle();
    response1->ExpectCompleted(vrf_states[i] ? "[true]" : "[false]");
    response2->ExpectCompleted("");
    response3->ExpectCompleted(vrf_states[i] ? "[true]" : "[false]");
    response4->ExpectCompleted(vrf_states[i] ? "[true]" : "[false]");
  }
}

// This test makes sure that the PlatformView forwards messages on the
// "flutter/platform_views" channel for RequestFocus.
// TODO(fxbug.dev/79740): Delete after soft transition.
TEST_F(PlatformViewTests, DeprecatedRequestFocusTest) {
  sys::testing::ServiceDirectoryProvider services_provider(dispatcher());
  MockPlatformViewDelegate delegate;
  flutter::TaskRunners task_runners =
      flutter::TaskRunners("test_runners", nullptr, nullptr, nullptr, nullptr);

  FakeFocuser focuser;
  fidl::BindingSet<fuchsia::ui::views::Focuser> focuser_bindings;
  auto focuser_handle = focuser_bindings.AddBinding(&focuser);

  flutter_runner::PlatformView platform_view =
      PlatformViewBuilder(delegate, std::move(task_runners),
                          services_provider.service_directory())
          .SetFocuser(std::move(focuser_handle))
          .Build();

  // Cast platform_view to its base view so we can have access to the public
  // "HandlePlatformMessage" function.
  auto base_view = static_cast<flutter::PlatformView*>(&platform_view);
  EXPECT_TRUE(base_view);

  // This "Mock" ViewRef serves as the target for the RequestFocus operation.
  auto mock_view_ref_pair = scenic::ViewRefPair::New();

  // JSON for the message to be passed into the PlatformView.
  std::ostringstream message;
  message << "{"
          << "    \"method\":\"View.requestFocus\","
          << "    \"args\": {"
          << "       \"viewRef\":"
          << mock_view_ref_pair.view_ref.reference.get() << "    }"
          << "}";

  // Dispatch the plaform message request.
  auto response = FakePlatformMessageResponse::Create();
  base_view->HandlePlatformMessage(
      response->WithMessage("flutter/platform_views", message.str()));
  RunLoopUntilIdle();

  response->ExpectCompleted("[0]");
  EXPECT_TRUE(focuser.request_focus_called());
}

// This test makes sure that the PlatformView correctly replies with an error
// response when a RequestFocus call fails.
// TODO(fxbug.dev/79740): Delete after soft transition.
TEST_F(PlatformViewTests, DeprecatedRequestFocusFailTest) {
  sys::testing::ServiceDirectoryProvider services_provider(dispatcher());
  MockPlatformViewDelegate delegate;
  flutter::TaskRunners task_runners =
      flutter::TaskRunners("test_runners", nullptr, nullptr, nullptr, nullptr);

  FakeFocuser focuser;
  focuser.fail_request_focus();
  fidl::BindingSet<fuchsia::ui::views::Focuser> focuser_bindings;
  auto focuser_handle = focuser_bindings.AddBinding(&focuser);

  flutter_runner::PlatformView platform_view =
      PlatformViewBuilder(delegate, std::move(task_runners),
                          services_provider.service_directory())
          .SetFocuser(std::move(focuser_handle))
          .Build();

  // Cast platform_view to its base view so we can have access to the public
  // "HandlePlatformMessage" function.
  auto base_view = static_cast<flutter::PlatformView*>(&platform_view);
  EXPECT_TRUE(base_view);

  // This "Mock" ViewRef serves as the target for the RequestFocus operation.
  auto mock_view_ref_pair = scenic::ViewRefPair::New();

  // JSON for the message to be passed into the PlatformView.
  std::ostringstream message;
  message << "{"
          << "    \"method\":\"View.requestFocus\","
          << "    \"args\": {"
          << "       \"viewRef\":"
          << mock_view_ref_pair.view_ref.reference.get() << "    }"
          << "}";

  // Dispatch the plaform message request.
  auto response = FakePlatformMessageResponse::Create();
  base_view->HandlePlatformMessage(
      response->WithMessage("flutter/platform_views", message.str()));
  RunLoopUntilIdle();

  response->ExpectCompleted(
      "[" +
      std::to_string(
          static_cast<std::underlying_type_t<fuchsia::ui::views::Error>>(
              fuchsia::ui::views::Error::DENIED)) +
      "]");
  EXPECT_TRUE(focuser.request_focus_called());
}

struct EventFlow {
  fuchsia::ui::input3::KeyEvent event;
  fuchsia::ui::input3::KeyEventStatus expected_key_event_status;
  std::string expected_platform_message;
};

// Makes sure that OnKeyEvent is dispatched as a platform message.
TEST_F(PlatformViewTests, OnKeyEvent) {
  sys::testing::ServiceDirectoryProvider services_provider(dispatcher());
  MockPlatformViewDelegate delegate;
  flutter::TaskRunners task_runners =
      flutter::TaskRunners("test_runners", nullptr, nullptr, nullptr, nullptr);

  fidl::InterfacePtr<fuchsia::ui::input3::KeyboardListener> keyboard_listener;

  flutter_runner::PlatformView platform_view =
      PlatformViewBuilder(delegate, std::move(task_runners),
                          services_provider.service_directory())
          .SetKeyboardListener(keyboard_listener.NewRequest(dispatcher()))
          .Build();

  using fuchsia::input::Key;
  using fuchsia::ui::input3::KeyEvent;
  using fuchsia::ui::input3::KeyEventStatus;
  using fuchsia::ui::input3::KeyEventType;
  using fuchsia::ui::input3::Modifiers;

  std::vector<EventFlow> events;
  // Press A.  Get 'a'.
  events.emplace_back(EventFlow{
      MakeEvent(KeyEventType::PRESSED, std::nullopt, Key::A),
      KeyEventStatus::HANDLED,
      R"({"type":"keydown","keymap":"fuchsia","hidUsage":4,"codePoint":97,"modifiers":0})",
  });
  // Release A. Get 'a' release.
  events.emplace_back(EventFlow{
      MakeEvent(KeyEventType::RELEASED, std::nullopt, Key::A),
      KeyEventStatus::HANDLED,
      R"({"type":"keyup","keymap":"fuchsia","hidUsage":4,"codePoint":97,"modifiers":0})",
  });
  // Press CAPS_LOCK.  Modifier now active.
  events.emplace_back(EventFlow{
      MakeEvent(KeyEventType::PRESSED, Modifiers::CAPS_LOCK, Key::CAPS_LOCK),
      KeyEventStatus::HANDLED,
      R"({"type":"keydown","keymap":"fuchsia","hidUsage":57,"codePoint":0,"modifiers":1})",
  });
  // Pres A.  Get 'A'.
  events.emplace_back(EventFlow{
      MakeEvent(KeyEventType::PRESSED, std::nullopt, Key::A),
      KeyEventStatus::HANDLED,
      R"({"type":"keydown","keymap":"fuchsia","hidUsage":4,"codePoint":65,"modifiers":1})",
  });
  // Release CAPS_LOCK.
  events.emplace_back(EventFlow{
      MakeEvent(KeyEventType::RELEASED, Modifiers::CAPS_LOCK, Key::CAPS_LOCK),
      KeyEventStatus::HANDLED,
      R"({"type":"keyup","keymap":"fuchsia","hidUsage":57,"codePoint":0,"modifiers":1})",
  });
  // Press A again.  This time get 'A'.
  // CAPS_LOCK is latched active even if it was just released.
  events.emplace_back(EventFlow{
      MakeEvent(KeyEventType::PRESSED, std::nullopt, Key::A),
      KeyEventStatus::HANDLED,
      R"({"type":"keydown","keymap":"fuchsia","hidUsage":4,"codePoint":65,"modifiers":1})",
  });

  for (const auto& event : events) {
    KeyEvent e;
    event.event.Clone(&e);
    fuchsia::ui::input3::KeyEventStatus key_event_status;
    keyboard_listener->OnKeyEvent(
        std::move(e),
        [&key_event_status](fuchsia::ui::input3::KeyEventStatus status) {
          key_event_status = status;
        });
    RunLoopUntilIdle();
    const fml::MallocMapping data = delegate.message()->releaseData();
    const std::string message = ToString(data);

    EXPECT_EQ(event.expected_platform_message, message);
    EXPECT_EQ(key_event_status, event.expected_key_event_status);
  }
}

// Makes sure that OnKeyEvent is dispatched as a platform message.
TEST_F(PlatformViewTests, OnShaderWarmup) {
  sys::testing::ServiceDirectoryProvider services_provider(dispatcher());
  MockPlatformViewDelegate delegate;
  flutter::TaskRunners task_runners =
      flutter::TaskRunners("test_runners", nullptr, nullptr, nullptr, nullptr);

  uint64_t width = 200;
  uint64_t height = 100;
  std::vector<std::string> shaders = {"foo.skp", "bar.skp", "baz.skp"};

  OnShaderWarmup on_shader_warmup =
      [&](const std::vector<std::string>& shaders_in,
          std::function<void(uint32_t)> completion_callback, uint64_t width_in,
          uint64_t height_in) {
        ASSERT_EQ(shaders.size(), shaders_in.size());
        for (size_t i = 0; i < shaders_in.size(); i++) {
          ASSERT_EQ(shaders[i], shaders_in[i]);
        }
        ASSERT_EQ(width, width_in);
        ASSERT_EQ(height, height_in);

        completion_callback(shaders_in.size());
      };

  flutter_runner::PlatformView platform_view =
      PlatformViewBuilder(delegate, std::move(task_runners),
                          services_provider.service_directory())
          .SetShaderWarmupCallback(on_shader_warmup)
          .Build();

  std::ostringstream shaders_array_ostream;
  shaders_array_ostream << "[ ";
  for (auto it = shaders.begin(); it != shaders.end(); ++it) {
    shaders_array_ostream << "\"" << *it << "\"";
    if (std::next(it) != shaders.end()) {
      shaders_array_ostream << ", ";
    }
  }
  shaders_array_ostream << "]";

  std::string shaders_array_string = shaders_array_ostream.str();

  // Create initial view for testing.
  std::ostringstream warmup_shaders_ostream;
  warmup_shaders_ostream << "{"
                         << "  \"method\":\"WarmupSkps\","
                         << "  \"args\":{"
                         << "    \"shaders\":" << shaders_array_string << ","
                         << "    \"width\":" << width << ","
                         << "    \"height\":" << height << "  }"
                         << "}\n";
  std::string warmup_shaders_string = warmup_shaders_ostream.str();

  class TestPlatformMessageResponse : public flutter::PlatformMessageResponse {
   public:
    TestPlatformMessageResponse() {}
    void Complete(std::unique_ptr<fml::Mapping> data) override {
      result_string = std::string(
          reinterpret_cast<const char*>(data->GetMapping()), data->GetSize());
      is_complete_ = true;
    }
    void CompleteEmpty() override { is_complete_ = true; }
    std::string result_string;
    FML_DISALLOW_COPY_AND_ASSIGN(TestPlatformMessageResponse);
  };

  fml::RefPtr<TestPlatformMessageResponse> response(
      new TestPlatformMessageResponse);
  static_cast<flutter::PlatformView*>(&platform_view)
      ->HandlePlatformMessage(std::make_unique<flutter::PlatformMessage>(
          "fuchsia/shader_warmup",
          fml::MallocMapping::Copy(warmup_shaders_string.c_str(),
                                   warmup_shaders_string.size()),
          response));
  RunLoopUntilIdle();
  ASSERT_TRUE(response->is_complete());

  std::ostringstream expected_result_ostream;
  expected_result_ostream << "[" << shaders.size() << "]";
  std::string expected_result_string = expected_result_ostream.str();
  EXPECT_EQ(expected_result_string, response->result_string);
}

}  // namespace flutter_runner::testing
