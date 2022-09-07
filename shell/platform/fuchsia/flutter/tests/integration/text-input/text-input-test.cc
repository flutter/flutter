// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <fuchsia/feedback/cpp/fidl.h>
#include <fuchsia/logger/cpp/fidl.h>
#include <fuchsia/sys/cpp/fidl.h>
#include <fuchsia/sysmem/cpp/fidl.h>
#include <fuchsia/tracing/provider/cpp/fidl.h>
#include <fuchsia/ui/app/cpp/fidl.h>
#include <fuchsia/ui/input/cpp/fidl.h>
#include <fuchsia/ui/scenic/cpp/fidl.h>
#include <fuchsia/ui/test/input/cpp/fidl.h>
#include <fuchsia/ui/test/scene/cpp/fidl.h>
#include <lib/async-loop/testing/cpp/real_loop.h>
#include <lib/async/cpp/task.h>
#include <lib/fidl/cpp/binding_set.h>
#include <lib/sys/component/cpp/testing/realm_builder.h>
#include <lib/sys/component/cpp/testing/realm_builder_types.h>
#include <lib/zx/clock.h>
#include <lib/zx/time.h>
#include <zircon/status.h>
#include <zircon/types.h>
#include <zircon/utc.h>

#include <cstddef>
#include <cstdint>
#include <iostream>
#include <memory>
#include <type_traits>
#include <utility>
#include <vector>

#include <gtest/gtest.h>

#include "flutter/fml/logging.h"
#include "flutter/shell/platform/fuchsia/flutter/tests/integration/utils/check_view.h"

namespace {

// Types imported for the realm_builder library.
using component_testing::ChildRef;
using component_testing::LocalComponent;
using component_testing::LocalComponentHandles;
using component_testing::ParentRef;
using component_testing::Protocol;
using component_testing::RealmBuilder;
using component_testing::RealmRoot;
using component_testing::Route;

using fuchsia_test_utils::CheckViewExistsInUpdates;

/// Max timeout in failure cases.
/// Set this as low as you can that still works across all test platforms.
constexpr zx::duration kTimeout = zx::min(5);

// The FIDL bindings for these services are not exposed in the Fuchsia SDK so we
// must encode the names manually here.
constexpr auto kVulkanLoaderServiceName = "fuchsia.vulkan.loader.Loader";
constexpr auto kProfileProviderServiceName = "fuchsia.sheduler.ProfileProvider";

constexpr auto kResponseListener = "test_text_response_listener";
constexpr auto kTextInputView = "text-input-view";
static constexpr auto kTextInputViewUrl =
    "fuchsia-pkg://fuchsia.com/view#meta/view-realm.cm";

constexpr auto kTestUiStack = "ui";
constexpr auto kTestUiStackUrl =
    "fuchsia-pkg://fuchsia.com/test-ui-stack#meta/test-ui-stack.cm";

/// |ResponseListener| is a local test protocol that our test Flutter app uses
/// to let us know what text is being entered into its only text field.
///
/// The text field contents are reported on almost every change, so if you are
/// entering a long text, you will see calls corresponding to successive
/// additions of characters, not just the end result.
class TestResponseListenerServer
    : public fuchsia::ui::test::input::KeyboardInputListener,
      public LocalComponent {
 public:
  explicit TestResponseListenerServer(async_dispatcher_t* dispatcher)
      : dispatcher_(dispatcher) {}

  TestResponseListenerServer(const TestResponseListenerServer&) = delete;
  TestResponseListenerServer& operator=(const TestResponseListenerServer&) =
      delete;

  // |fuchsia::ui::test::input::KeyboardInputListener|
  void ReportTextInput(
      fuchsia::ui::test::input::KeyboardInputListenerReportTextInputRequest
          request) override {
    FML_LOG(INFO) << "Flutter app sent: '" << request.text() << "'";
    response_ = request.text();
  }

  /// Starts this server.
  void Start(std::unique_ptr<LocalComponentHandles> handles) override {
    handles_ = std::move(handles);

    ASSERT_EQ(ZX_OK, handles_->outgoing()->AddPublicService(
                         bindings_.GetHandler(this, dispatcher_)));
  }

  /// Returns true if the last response received matches `expected`.  If a match
  /// is found, the match is consumed, so a next call to HasResponse starts from
  /// scratch.
  bool HasResponse(const std::string& expected) {
    bool match = response_.has_value() && response_.value() == expected;
    if (match) {
      response_ = std::nullopt;
    }
    return match;
  }

 private:
  // Not owned.
  async_dispatcher_t* dispatcher_ = nullptr;
  fidl::BindingSet<fuchsia::ui::test::input::KeyboardInputListener> bindings_;
  std::unique_ptr<LocalComponentHandles> handles_;
  std::optional<std::string> response_;
};

class TextInputTest : public ::loop_fixture::RealLoop, public ::testing::Test {
 protected:
  TextInputTest()
      : test_response_listener_(
            std::make_unique<TestResponseListenerServer>(dispatcher())) {}

  bool HasViewConnected(
      const fuchsia::ui::observation::geometry::ViewTreeWatcherPtr&
          view_tree_watcher,
      std::optional<fuchsia::ui::observation::geometry::WatchResponse>&
          watch_response,
      zx_koid_t view_ref_koid) {
    std::optional<fuchsia::ui::observation::geometry::WatchResponse>
        watch_result;
    view_tree_watcher->Watch(
        [&watch_result](auto response) { watch_result = std::move(response); });
    FML_LOG(INFO) << "Waiting for view tree watch result";
    RunLoopUntil([&watch_result] { return watch_result.has_value(); });
    FML_LOG(INFO) << "Received for view tree watch result";
    if (CheckViewExistsInUpdates(watch_result->updates(), view_ref_koid)) {
      watch_response = std::move(watch_result);
    };
    return watch_response.has_value();
  }

  void RegisterKeyboard() {
    FML_LOG(INFO) << "Registering fake keyboard";
    input_registry_ =
        realm_root_->Connect<fuchsia::ui::test::input::Registry>();
    input_registry_.set_error_handler(
        [](auto) { FML_LOG(ERROR) << "Error from input helper"; });
    bool keyboard_registered = false;
    fuchsia::ui::test::input::RegistryRegisterKeyboardRequest request;
    request.set_device(fake_keyboard_.NewRequest());
    input_registry_->RegisterKeyboard(
        std::move(request),
        [&keyboard_registered]() { keyboard_registered = true; });
    RunLoopUntil([&keyboard_registered] { return keyboard_registered; });
    FML_LOG(INFO) << "Keyboard registered";
  }

  void InitializeScene() {
    // Instruct Scene Manager to present test's View.
    std::optional<zx_koid_t> view_ref_koid;
    scene_provider_ =
        realm_root_->Connect<fuchsia::ui::test::scene::Controller>();
    scene_provider_.set_error_handler(
        [](auto) { FML_LOG(ERROR) << "Error from test scene provider"; });
    fuchsia::ui::test::scene::ControllerAttachClientViewRequest request;
    request.set_view_provider(
        realm_root_->Connect<fuchsia::ui::app::ViewProvider>());
    scene_provider_->RegisterViewTreeWatcher(view_tree_watcher_.NewRequest(),
                                             []() {});
    scene_provider_->AttachClientView(
        std::move(request), [&view_ref_koid](auto client_view_ref_koid) {
          view_ref_koid = client_view_ref_koid;
        });

    FML_LOG(INFO) << "Waiting for client view ref koid";
    RunLoopUntil([&view_ref_koid] { return view_ref_koid.has_value(); });

    // Wait for the client view to get attached to the view tree.
    std::optional<fuchsia::ui::observation::geometry::WatchResponse>
        watch_response;
    FML_LOG(INFO) << "Waiting for client view to render";
    RunLoopUntil([this, &watch_response, &view_ref_koid] {
      return HasViewConnected(view_tree_watcher_, watch_response,
                              *view_ref_koid);
    });
    FML_LOG(INFO) << "Client view has rendered";
  }

  void BuildRealm() {
    FML_LOG(INFO) << "Building realm";
    realm_builder_.AddChild(kTestUiStack, kTestUiStackUrl);
    realm_builder_.AddLocalChild(kResponseListener,
                                 test_response_listener_.get());
    realm_builder_.AddChild(kTextInputView, kTextInputViewUrl);

    // Route base system services to the view and the test UI stack.
    realm_builder_.AddRoute(Route{
        .capabilities = {Protocol{fuchsia::logger::LogSink::Name_},
                         Protocol{fuchsia::sys::Environment::Name_},
                         Protocol{fuchsia::sysmem::Allocator::Name_},
                         Protocol{fuchsia::tracing::provider::Registry::Name_},
                         Protocol{kVulkanLoaderServiceName},
                         Protocol{kProfileProviderServiceName}},
        .source = ParentRef{},
        .targets = {ChildRef{kTestUiStack}, ChildRef{kTextInputView}}});

    // Expose fuchsia.ui.app.ViewProvider from the flutter app.
    realm_builder_.AddRoute(
        Route{.capabilities = {Protocol{fuchsia::ui::app::ViewProvider::Name_}},
              .source = ChildRef{kTextInputView},
              .targets = {ParentRef()}});

    // Route UI capabilities from test-ui-stack to the flutter app.
    realm_builder_.AddRoute(Route{
        .capabilities = {Protocol{fuchsia::ui::composition::Flatland::Name_},
                         Protocol{fuchsia::ui::composition::Allocator::Name_},
                         Protocol{fuchsia::ui::input::ImeService::Name_},
                         Protocol{fuchsia::ui::input3::Keyboard::Name_},
                         Protocol{fuchsia::ui::scenic::Scenic::Name_}},
        .source = ChildRef{kTestUiStack},
        .targets = {ChildRef{kTextInputView}}});

    // Route UI helpers to test driver.
    realm_builder_.AddRoute(Route{
        .capabilities = {Protocol{fuchsia::ui::test::input::Registry::Name_},
                         Protocol{fuchsia::ui::test::scene::Controller::Name_}},
        .source = ChildRef{kTestUiStack},
        .targets = {ParentRef{}}});

    // Route crash reporter service to flutter app.
    realm_builder_.AddRoute(
        {.capabilities =
             {
                 Protocol{fuchsia::feedback::CrashReporter::Name_},
             },
         .source = ParentRef(),
         .targets = {ChildRef{kTextInputView}}});

    // Route text listener from the flutter app to the response listener.
    realm_builder_.AddRoute(Route{
        .capabilities =
            {
                Protocol{
                    fuchsia::ui::test::input::KeyboardInputListener::Name_},
            },
        .source = ChildRef{kResponseListener},
        .targets = {ChildRef{kTextInputView}}});

    realm_root_ = std::make_unique<RealmRoot>(realm_builder_.Build());
  }

  void SetUp() override {
    // Post a "just in case" quit task, if the test hangs.
    async::PostDelayedTask(
        dispatcher(),
        [] {
          FML_LOG(FATAL)
              << "\n\n>> Test did not complete in time, terminating.  <<\n\n";
        },
        kTimeout);

    BuildRealm();

    RegisterKeyboard();

    InitializeScene();
  }

  std::unique_ptr<TestResponseListenerServer> test_response_listener_;

  fuchsia::ui::test::input::RegistryPtr input_registry_;
  fuchsia::ui::test::input::KeyboardPtr fake_keyboard_;
  fuchsia::ui::test::scene::ControllerPtr scene_provider_;
  fuchsia::ui::observation::geometry::ViewTreeWatcherPtr view_tree_watcher_;

  RealmBuilder realm_builder_ = RealmBuilder::Create();
  std::unique_ptr<RealmRoot> realm_root_;
};

TEST_F(TextInputTest, FlutterTextFieldEntry) {
  FML_LOG(INFO) << "Wait for the initial text response";
  RunLoopUntil([&] { return test_response_listener_->HasResponse(""); });

  FML_LOG(INFO) << "Sending a text message";
  bool done = false;
  fuchsia::ui::test::input::KeyboardSimulateUsAsciiTextEntryRequest request;
  request.set_text("Hello\nworld!");
  fake_keyboard_->SimulateUsAsciiTextEntry(std::move(request),
                                           [&done]() { done = true; });
  RunLoopUntil([&] { return done; });
  FML_LOG(INFO) << "Message was sent";

  RunLoopUntil(
      [&] { return test_response_listener_->HasResponse("Hello\nworld!"); });
}

}  // namespace
