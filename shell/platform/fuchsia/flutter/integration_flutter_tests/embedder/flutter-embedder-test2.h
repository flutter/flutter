// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SRC_UI_TESTS_INTEGRATION_FLUTTER_TESTS_EMBEDDER_flutter_embedder_test2_H_
#define SRC_UI_TESTS_INTEGRATION_FLUTTER_TESTS_EMBEDDER_flutter_embedder_test2_H_

#include <fuchsia/ui/lifecycle/cpp/fidl.h>
#include <fuchsia/ui/policy/cpp/fidl.h>
#include <fuchsia/ui/scenic/cpp/fidl.h>
#include <fuchsia/ui/views/cpp/fidl.h>
#include <gtest/gtest.h>
#include <lib/async/cpp/task.h>
#include <lib/fidl/cpp/binding_set.h>
#include <lib/sys/cpp/component_context.h>
#include <lib/sys/cpp/testing/test_with_environment.h>
#include <lib/ui/scenic/cpp/view_token_pair.h>
#include <lib/zx/clock.h>
#include <zircon/status.h>
#include <zircon/time.h>
#include "flutter/fml/logging.h"

#include <vector>

#include "src/lib/ui/base_view/embedded_view_utils.h"
#include "src/ui/testing/views/color.h"
#include "src/ui/testing/views/embedder_view.h"

namespace flutter_embedder_test2 {

/// Defines a list of services that are injected into the test environment.
/// Unlike the injected-services in CMX which are injected per test package,
/// these are injected per test and result in a more hermetic test environment.
const std::vector<std::pair<const char*, const char*>> GetInjectedServices();

// Timeout when waiting on Scenic API calls like |GetDisplayInfo|.
constexpr zx::duration kCallTimeout = zx::sec(5);
// Timeout for Scenic's |TakeScreenshot| FIDL call.
constexpr zx::duration kScreenshotTimeout = zx::sec(10);
// Timeout to fail the test if it goes beyond this duration.
constexpr zx::duration kTestTimeout = zx::min(1);

class FlutterScenicEmbedderTests : public sys::testing::TestWithEnvironment,
                                   public ::testing::Test {
 public:
  // |testing::Test|
  void SetUp() override {
    Test::SetUp();

    // Create test-specific launchable services.
    auto services = TestWithEnvironment::CreateServices();
    for (const auto& service_info : GetInjectedServices()) {
      zx_status_t status = services->AddServiceWithLaunchInfo(
          {.url = service_info.second}, service_info.first);
      FML_CHECK(status == ZX_OK)
          << "Failed to add service " << service_info.first;
    }

    environment_ = CreateNewEnclosingEnvironment(
        "flutter-embedder-test2s", std::move(services),
        {.inherit_parent_services = true});
    WaitForEnclosingEnvToStart(environment());

    FML_VLOG(fml::LOG_INFO) << "Created test environment.";

    // Connects to scenic lifecycle controller in order to shutdown scenic at
    // the end of the test. This ensures the correct ordering of shutdown under
    // CFv1: first scenic, then the fake display controller.
    //
    // TODO(fxbug.dev/82655): Remove this after migrating to RealmBuilder.
    environment_->ConnectToService<fuchsia::ui::lifecycle::LifecycleController>(
        scenic_lifecycle_controller_.NewRequest());

    environment_->ConnectToService(scenic_.NewRequest());
    scenic_.set_error_handler([](zx_status_t status) {
      FAIL() << "Lost connection to Scenic: " << zx_status_get_string(status);
    });

    // Post a "just in case" quit task, if the test hangs.
    async::PostDelayedTask(
        dispatcher(),
        [] {
          FML_LOG(FATAL)
              << "\n\n>> Test did not complete in time, terminating.  <<\n\n";
        },
        kTestTimeout);
  }

  // |testing::Test|
  void TearDown() override {
    // Avoid spurious errors since we are about to kill scenic.
    //
    // TODO(fxbug.dev/82655): Remove this after migrating to RealmBuilder.
    scenic_.set_error_handler(nullptr);

    zx_status_t terminate_status = scenic_lifecycle_controller_->Terminate();
    FML_CHECK(terminate_status == ZX_OK)
        << "Failed to terminate Scenic with status: "
        << zx_status_get_string(terminate_status);
  }

  sys::testing::EnclosingEnvironment* environment() {
    return environment_.get();
  }

  fuchsia::ui::views::ViewToken CreatePresentationViewToken() {
    auto [view_token, view_holder_token] = scenic::ViewTokenPair::New();

    auto presenter =
        environment()->ConnectToService<fuchsia::ui::policy::Presenter>();
    presenter.set_error_handler([](zx_status_t status) {
      FAIL() << "presenter: " << zx_status_get_string(status);
    });
    presenter->PresentView(std::move(view_holder_token), nullptr);

    return std::move(view_token);
  }

  void RunAppWithArgs(const std::string& component_url,
                      const std::vector<std::string>& component_args = {}) {
    scenic::EmbeddedViewInfo flutter_runner =
        scenic::LaunchComponentAndCreateView(environment()->launcher_ptr(),
                                             component_url, component_args);
    flutter_runner.controller.events().OnTerminated = [](auto...) { FAIL(); };

    // Present the view.
    embedder_view_.emplace(scenic::ViewContext{
        .session_and_listener_request =
            scenic::CreateScenicSessionPtrAndListenerRequest(scenic_.get()),
        .view_token = CreatePresentationViewToken(),
    });

    // Embed the view.
    bool is_rendering = false;
    embedder_view_->EmbedView(
        std::move(flutter_runner),
        [&is_rendering](fuchsia::ui::gfx::ViewState view_state) {
          is_rendering = view_state.is_rendering;
        });
    RunLoopUntil([&is_rendering] { return is_rendering; });
    FML_LOG(INFO) << "Launched component: " << component_url;
  }

  scenic::Screenshot TakeScreenshot() {
    FML_LOG(INFO) << "Taking screenshot... ";
    fuchsia::ui::scenic::ScreenshotData screenshot_out;
    scenic_->TakeScreenshot(
        [this, &screenshot_out](fuchsia::ui::scenic::ScreenshotData screenshot,
                                bool status) {
          EXPECT_TRUE(status) << "Failed to take screenshot";
          screenshot_out = std::move(screenshot);
          QuitLoop();
        });
    EXPECT_FALSE(RunLoopWithTimeout(kScreenshotTimeout))
        << "Timed out waiting for screenshot.";
    FML_LOG(INFO) << "Screenshot captured.";

    return scenic::Screenshot(screenshot_out);
  }

  bool TakeScreenshotUntil(
      scenic::Color color,
      fit::function<void(scenic::Screenshot, std::map<scenic::Color, size_t>)>
          callback = nullptr,
      zx::duration timeout = kTestTimeout) {
    return RunLoopWithTimeoutOrUntil(
        [this, &callback, &color] {
          auto screenshot = TakeScreenshot();
          auto histogram = screenshot.Histogram();

          bool color_found = histogram[color] > 0;
          if (color_found && callback != nullptr) {
            callback(std::move(screenshot), std::move(histogram));
          }
          return color_found;
        },
        timeout);
  }

  // Inject directly into Root Presenter, using fuchsia.ui.input FIDLs.
  void InjectInput() {
    using fuchsia::ui::input::InputReport;
    // Device parameters
    auto parameters = fuchsia::ui::input::TouchscreenDescriptor::New();
    *parameters = {.x = {.range = {.min = -1000, .max = 1000}},
                   .y = {.range = {.min = -1000, .max = 1000}},
                   .max_finger_id = 10};

    FML_LOG(INFO) << "Injecting input... ";
    // Register it against Root Presenter.
    fuchsia::ui::input::DeviceDescriptor device{.touchscreen =
                                                    std::move(parameters)};
    auto registry =
        environment()
            ->ConnectToService<fuchsia::ui::input::InputDeviceRegistry>();
    fuchsia::ui::input::InputDevicePtr connection;
    registry->RegisterDevice(std::move(device), connection.NewRequest());

    {
      // Inject one input report, then a conclusion (empty) report.
      auto touch = fuchsia::ui::input::TouchscreenReport::New();
      *touch = {
          .touches = {{.finger_id = 1, .x = 0, .y = 0}}};  // center of display
      InputReport report{
          .event_time = static_cast<uint64_t>(zx::clock::get_monotonic().get()),
          .touchscreen = std::move(touch)};
      connection->DispatchReport(std::move(report));
    }

    {
      auto touch = fuchsia::ui::input::TouchscreenReport::New();
      InputReport report{
          .event_time = static_cast<uint64_t>(zx::clock::get_monotonic().get()),
          .touchscreen = std::move(touch)};
      connection->DispatchReport(std::move(report));
    }
    FML_LOG(INFO) << "Input dispatched.";
  }

 private:
  const std::unique_ptr<sys::ComponentContext> component_context_;
  std::unique_ptr<sys::testing::EnclosingEnvironment> environment_;

  fuchsia::ui::lifecycle::LifecycleControllerSyncPtr
      scenic_lifecycle_controller_;
  fuchsia::ui::scenic::ScenicPtr scenic_;

  // Wrapped in optional since the view is not created until the middle of SetUp
  std::optional<scenic::EmbedderView> embedder_view_;
};

}  // namespace flutter_embedder_test2

#endif  // SRC_UI_TESTS_INTEGRATION_FLUTTER_TESTS_EMBEDDER_flutter_embedder_test2_H_
