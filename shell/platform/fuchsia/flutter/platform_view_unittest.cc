// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/fuchsia/flutter/platform_view.h"

#include <gtest/gtest.h>
#include <lib/async-loop/cpp/loop.h>
#include <lib/async-loop/default.h>
#include <lib/async/default.h>
#include <lib/fidl/cpp/binding_set.h>
#include <lib/fidl/cpp/interface_request.h>
#include <lib/sys/cpp/testing/service_directory_provider.h>

#include <memory>
#include <vector>

#include "flutter/flow/scene_update_context.h"
#include "flutter/lib/ui/window/platform_message.h"
#include "flutter/lib/ui/window/window.h"
#include "fuchsia/ui/views/cpp/fidl.h"
#include "gtest/gtest.h"
#include "task_runner_adapter.h"

namespace flutter_runner_test::flutter_runner_a11y_test {

class PlatformViewTests : public testing::Test {
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
      const flutter::ViewportMetrics& metrics) {}
  // |flutter::PlatformView::Delegate|
  void OnPlatformViewDispatchPlatformMessage(
      fml::RefPtr<flutter::PlatformMessage> message) {}
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
    std::unique_ptr<std::vector<std::string>> out =
        std::make_unique<std::vector<std::string>>();
    return out;
  }

  bool SemanticsEnabled() const { return semantics_enabled_; }
  int32_t SemanticsFeatures() const { return semantics_features_; }
  flutter::ExternalViewEmbedder* get_view_embedder() {
    return surface_->GetExternalViewEmbedder();
  }
  GrDirectContext* get_gr_context() { return surface_->GetContext(); }

 private:
  std::unique_ptr<flutter::Surface> surface_;
  bool semantics_enabled_ = false;
  int32_t semantics_features_ = 0;
};

class MockSurfaceProducer
    : public flutter::SceneUpdateContext::SurfaceProducer {
 public:
  std::unique_ptr<flutter::SceneUpdateContext::SurfaceProducerSurface>
  ProduceSurface(const SkISize& size,
                 const flutter::LayerRasterCacheKey& layer_key,
                 std::unique_ptr<scenic::EntityNode> entity_node) override {
    return nullptr;
  }

  bool HasRetainedNode(const flutter::LayerRasterCacheKey& key) const override {
    return false;
  }

  scenic::EntityNode* GetRetainedNode(
      const flutter::LayerRasterCacheKey& key) override {
    return nullptr;
  }

  void SubmitSurface(
      std::unique_ptr<flutter::SceneUpdateContext::SurfaceProducerSurface>
          surface) override {}
};

class MockFocuser : public fuchsia::ui::views::Focuser {
 public:
  MockFocuser() = default;
  ~MockFocuser() override = default;

  bool request_focus_called = false;

 private:
  void RequestFocus(fuchsia::ui::views::ViewRef view_ref,
                    RequestFocusCallback callback) override {
    request_focus_called = true;
  }
};

TEST_F(PlatformViewTests, ChangesAccessibilitySettings) {
  sys::testing::ServiceDirectoryProvider services_provider(dispatcher());

  MockPlatformViewDelegate delegate;
  zx::eventpair a, b;
  zx::eventpair::create(/* flags */ 0u, &a, &b);
  auto view_ref = fuchsia::ui::views::ViewRef({
      .reference = std::move(a),
  });
  flutter::TaskRunners task_runners =
      flutter::TaskRunners("test_runners", nullptr, nullptr, nullptr, nullptr);

  EXPECT_FALSE(delegate.SemanticsEnabled());
  EXPECT_EQ(delegate.SemanticsFeatures(), 0);

  auto platform_view = flutter_runner::PlatformView(
      delegate,                               // delegate
      "test_platform_view",                   // label
      std::move(view_ref),                    // view_ref
      std::move(task_runners),                // task_runners
      services_provider.service_directory(),  // runner_services
      nullptr,  // parent_environment_service_provider_handle
      nullptr,  // session_listener_request
      nullptr,  // focuser,
      nullptr,  // on_session_listener_error_callback
      nullptr,  // session_metrics_did_change_callback
      nullptr,  // session_size_change_hint_callback
      nullptr,  // on_enable_wireframe_callback,
      nullptr,  // on_create_view_callback,
      nullptr,  // on_destroy_view_callback,
      nullptr,  // on_get_view_embedder_callback,
      nullptr,  // on_get_gr_context_callback,
      0u,       // vsync_event_handle
      {}        // product_config
  );

  RunLoopUntilIdle();

  platform_view.SetSemanticsEnabled(true);

  EXPECT_TRUE(delegate.SemanticsEnabled());
  EXPECT_EQ(delegate.SemanticsFeatures(),
            static_cast<int32_t>(
                flutter::AccessibilityFeatureFlag::kAccessibleNavigation));

  platform_view.SetSemanticsEnabled(false);

  EXPECT_FALSE(delegate.SemanticsEnabled());
  EXPECT_EQ(delegate.SemanticsFeatures(), 0);
}

// Test to make sure that PlatformView correctly registers messages sent on
// the "flutter/platform_views" channel, correctly parses the JSON it receives
// and calls the EnableWireframeCallback with the appropriate args.
TEST_F(PlatformViewTests, EnableWireframeTest) {
  sys::testing::ServiceDirectoryProvider services_provider(dispatcher());
  MockPlatformViewDelegate delegate;
  zx::eventpair a, b;
  zx::eventpair::create(/* flags */ 0u, &a, &b);
  auto view_ref = fuchsia::ui::views::ViewRef({
      .reference = std::move(a),
  });
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
      std::move(view_ref),                    // view_refs
      std::move(task_runners),                // task_runners
      services_provider.service_directory(),  // runner_services
      nullptr,                  // parent_environment_service_provider_handle
      nullptr,                  // session_listener_request
      nullptr,                  // focuser,
      nullptr,                  // on_session_listener_error_callback
      nullptr,                  // session_metrics_did_change_callback
      nullptr,                  // session_size_change_hint_callback
      EnableWireframeCallback,  // on_enable_wireframe_callback,
      nullptr,                  // on_create_view_callback,
      nullptr,                  // on_destroy_view_callback,
      nullptr,                  // on_get_view_embedder_callback,
      nullptr,                  // on_get_gr_context_callback,
      0u,                       // vsync_event_handle
      {}                        // product_config
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

// Test to make sure that PlatformView correctly registers messages sent on
// the "flutter/platform_views" channel, correctly parses the JSON it receives
// and calls the CreateViewCallback with the appropriate args.
TEST_F(PlatformViewTests, CreateViewTest) {
  sys::testing::ServiceDirectoryProvider services_provider(dispatcher());
  MockPlatformViewDelegate delegate;
  zx::eventpair a, b;
  zx::eventpair::create(/* flags */ 0u, &a, &b);
  auto view_ref = fuchsia::ui::views::ViewRef({
      .reference = std::move(a),
  });
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
      std::move(view_ref),                    // view_refs
      std::move(task_runners),                // task_runners
      services_provider.service_directory(),  // runner_services
      nullptr,             // parent_environment_service_provider_handle
      nullptr,             // session_listener_request
      nullptr,             // focuser,
      nullptr,             // on_session_listener_error_callback
      nullptr,             // session_metrics_did_change_callback
      nullptr,             // session_size_change_hint_callback
      nullptr,             // on_enable_wireframe_callback,
      CreateViewCallback,  // on_create_view_callback,
      nullptr,             // on_destroy_view_callback,
      nullptr,             // on_get_view_embedder_callback,
      nullptr,             // on_get_gr_context_callback,
      0u,                  // vsync_event_handle
      {}                   // product_config
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

// Test to make sure that PlatformView correctly registers messages sent on
// the "flutter/platform_views" channel, correctly parses the JSON it receives
// and calls the DestroyViewCallback with the appropriate args.
TEST_F(PlatformViewTests, DestroyViewTest) {
  sys::testing::ServiceDirectoryProvider services_provider(dispatcher());
  MockPlatformViewDelegate delegate;
  zx::eventpair a, b;
  zx::eventpair::create(/* flags */ 0u, &a, &b);
  auto view_ref = fuchsia::ui::views::ViewRef({
      .reference = std::move(a),
  });
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
      std::move(view_ref),                    // view_refs
      std::move(task_runners),                // task_runners
      services_provider.service_directory(),  // runner_services
      nullptr,              // parent_environment_service_provider_handle
      nullptr,              // session_listener_request
      nullptr,              // focuser,
      nullptr,              // on_session_listener_error_callback
      nullptr,              // session_metrics_did_change_callback
      nullptr,              // session_size_change_hint_callback
      nullptr,              // on_enable_wireframe_callback,
      nullptr,              // on_create_view_callback,
      DestroyViewCallback,  // on_destroy_view_callback,
      nullptr,              // on_get_view_embedder_callback,
      nullptr,              // on_get_gr_context_callback,
      0u,                   // vsync_event_handle
      {}                    // product_config
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

// Test to make sure that PlatformView correctly registers messages sent on
// the "flutter/platform_views" channel, correctly parses the JSON it receives
// and calls the focuser's RequestFocus with the appropriate args.
TEST_F(PlatformViewTests, RequestFocusTest) {
  sys::testing::ServiceDirectoryProvider services_provider(dispatcher());
  MockPlatformViewDelegate delegate;
  zx::eventpair a, b;
  zx::eventpair::create(/* flags */ 0u, &a, &b);
  auto view_ref = fuchsia::ui::views::ViewRef({
      .reference = std::move(a),
  });
  flutter::TaskRunners task_runners =
      flutter::TaskRunners("test_runners", nullptr, nullptr, nullptr, nullptr);

  MockFocuser mock_focuser;
  fidl::BindingSet<fuchsia::ui::views::Focuser> focuser_bindings;
  auto focuser_handle = focuser_bindings.AddBinding(&mock_focuser);

  auto platform_view = flutter_runner::PlatformView(
      delegate,                               // delegate
      "test_platform_view",                   // label
      std::move(view_ref),                    // view_refs
      std::move(task_runners),                // task_runners
      services_provider.service_directory(),  // runner_services
      nullptr,                    // parent_environment_service_provider_handle
      nullptr,                    // session_listener_request
      std::move(focuser_handle),  // focuser,
      nullptr,                    // on_session_listener_error_callback
      nullptr,                    // session_metrics_did_change_callback
      nullptr,                    // session_size_change_hint_callback
      nullptr,                    // on_enable_wireframe_callback,
      nullptr,                    // on_create_view_callback,
      nullptr,                    // on_destroy_view_callback,
      nullptr,                    // on_get_gr_context_callback,
      nullptr,                    // on_get_view_embedder_callback,
      0u,                         // vsync_event_handle
      {}                          // product_config
  );

  // Cast platform_view to its base view so we can have access to the public
  // "HandlePlatformMessage" function.
  auto base_view = dynamic_cast<flutter::PlatformView*>(&platform_view);
  EXPECT_TRUE(base_view);

  // JSON for the message to be passed into the PlatformView.
  char buff[254];
  snprintf(buff, sizeof(buff),
           "{"
           "    \"method\":\"View.requestFocus\","
           "    \"args\": {"
           "       \"viewRef\":%u"
           "    }"
           "}",
           b.get());

  fml::RefPtr<flutter::PlatformMessage> message =
      fml::MakeRefCounted<flutter::PlatformMessage>(
          "flutter/platform_views",
          std::vector<uint8_t>(buff, buff + sizeof(buff)),
          fml::RefPtr<flutter::PlatformMessageResponse>());
  base_view->HandlePlatformMessage(message);

  RunLoopUntilIdle();

  EXPECT_TRUE(mock_focuser.request_focus_called);
}

// Test to make sure that PlatformView correctly returns a Surface instance
// that can surface the view_embedder provided from GetViewEmbedderCallback.
TEST_F(PlatformViewTests, GetViewEmbedderTest) {
  sys::testing::ServiceDirectoryProvider services_provider(dispatcher());
  MockPlatformViewDelegate delegate;
  zx::eventpair a, b;
  zx::eventpair::create(/* flags */ 0u, &a, &b);
  auto view_ref = fuchsia::ui::views::ViewRef({
      .reference = std::move(a),
  });
  flutter::TaskRunners task_runners =
      flutter::TaskRunners("test_runners",  // label
                           nullptr,         // platform
                           flutter_runner::CreateFMLTaskRunner(
                               async_get_default_dispatcher()),  // raster
                           nullptr,                              // ui
                           nullptr                               // io
      );

  // Test get view embedder callback function.
  MockSurfaceProducer surfaceProducer;
  flutter::SceneUpdateContext scene_update_context(nullptr, &surfaceProducer);
  flutter::ExternalViewEmbedder* view_embedder =
      reinterpret_cast<flutter::ExternalViewEmbedder*>(&scene_update_context);
  auto GetViewEmbedderCallback = [view_embedder]() { return view_embedder; };

  auto platform_view = flutter_runner::PlatformView(
      delegate,                               // delegate
      "test_platform_view",                   // label
      std::move(view_ref),                    // view_refs
      std::move(task_runners),                // task_runners
      services_provider.service_directory(),  // runner_services
      nullptr,                  // parent_environment_service_provider_handle
      nullptr,                  // session_listener_request
      nullptr,                  // focuser,
      nullptr,                  // on_session_listener_error_callback
      nullptr,                  // session_metrics_did_change_callback
      nullptr,                  // session_size_change_hint_callback
      nullptr,                  // on_enable_wireframe_callback,
      nullptr,                  // on_create_view_callback,
      nullptr,                  // on_destroy_view_callback,
      GetViewEmbedderCallback,  // on_get_view_embedder_callback,
      nullptr,                  // on_get_gr_context_callback,
      0u,                       // vsync_event_handle
      {}                        // product_config
  );

  RunLoopUntilIdle();

  platform_view.NotifyCreated();

  RunLoopUntilIdle();

  EXPECT_EQ(view_embedder, delegate.get_view_embedder());
}

// Test to make sure that PlatformView correctly returns a Surface instance
// that can surface the GrContext provided from GetGrContextCallback.
TEST_F(PlatformViewTests, GetGrContextTest) {
  sys::testing::ServiceDirectoryProvider services_provider(dispatcher());
  MockPlatformViewDelegate delegate;
  zx::eventpair a, b;
  zx::eventpair::create(/* flags */ 0u, &a, &b);
  auto view_ref = fuchsia::ui::views::ViewRef({
      .reference = std::move(a),
  });
  flutter::TaskRunners task_runners =
      flutter::TaskRunners("test_runners",  // label
                           nullptr,         // platform
                           flutter_runner::CreateFMLTaskRunner(
                               async_get_default_dispatcher()),  // raster
                           nullptr,                              // ui
                           nullptr                               // io
      );

  // Test get GrContext callback function.
  sk_sp<GrDirectContext> gr_context =
      GrDirectContext::MakeMock(nullptr, GrContextOptions());
  auto GetGrContextCallback = [gr_context = gr_context.get()]() {
    return gr_context;
  };

  auto platform_view = flutter_runner::PlatformView(
      delegate,                               // delegate
      "test_platform_view",                   // label
      std::move(view_ref),                    // view_refs
      std::move(task_runners),                // task_runners
      services_provider.service_directory(),  // runner_services
      nullptr,               // parent_environment_service_provider_handle
      nullptr,               // session_listener_request
      nullptr,               // focuser
      nullptr,               // on_session_listener_error_callback
      nullptr,               // session_metrics_did_change_callback
      nullptr,               // session_size_change_hint_callback
      nullptr,               // on_enable_wireframe_callback,
      nullptr,               // on_create_view_callback,
      nullptr,               // on_destroy_view_callback,
      nullptr,               // on_get_view_embedder_callback,
      GetGrContextCallback,  // on_get_gr_context_callback,
      0u,                    // vsync_event_handle
      {}                     // product_config
  );

  RunLoopUntilIdle();

  platform_view.NotifyCreated();

  RunLoopUntilIdle();

  EXPECT_EQ(gr_context.get(), delegate.get_gr_context());
}

}  // namespace flutter_runner_test::flutter_runner_a11y_test
