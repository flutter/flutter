// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <fuchsia/accessibility/semantics/cpp/fidl.h>
#include <fuchsia/buildinfo/cpp/fidl.h>
#include <fuchsia/component/cpp/fidl.h>
#include <fuchsia/fonts/cpp/fidl.h>
#include <fuchsia/intl/cpp/fidl.h>
#include <fuchsia/kernel/cpp/fidl.h>
#include <fuchsia/memorypressure/cpp/fidl.h>
#include <fuchsia/metrics/cpp/fidl.h>
#include <fuchsia/net/interfaces/cpp/fidl.h>
#include <fuchsia/sysmem/cpp/fidl.h>
#include <fuchsia/tracing/provider/cpp/fidl.h>
#include <fuchsia/ui/app/cpp/fidl.h>
#include <fuchsia/ui/input/cpp/fidl.h>
#include <fuchsia/ui/policy/cpp/fidl.h>
#include <fuchsia/ui/scenic/cpp/fidl.h>
#include <fuchsia/ui/test/input/cpp/fidl.h>
#include <fuchsia/ui/test/scene/cpp/fidl.h>
#include <fuchsia/web/cpp/fidl.h>
#include <lib/async-loop/testing/cpp/real_loop.h>
#include <lib/async/cpp/task.h>
#include <lib/fidl/cpp/binding_set.h>
#include <lib/sys/component/cpp/testing/realm_builder.h>
#include <lib/sys/component/cpp/testing/realm_builder_types.h>
#include <lib/sys/cpp/component_context.h>
#include <lib/ui/scenic/cpp/resources.h>
#include <lib/ui/scenic/cpp/session.h>
#include <lib/ui/scenic/cpp/view_token_pair.h>
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
#include "flutter/shell/platform/fuchsia/flutter/tests/integration/utils/portable_ui_test.h"

// This test exercises the touch input dispatch path from Input Pipeline to a
// Scenic client. It is a multi-component test, and carefully avoids sleeping or
// polling for component coordination.
// - It runs real Root Presenter, Input Pipeline, and Scenic components.
// - It uses a fake display controller; the physical device is unused.
//
// Components involved
// - This test program
// - Input Pipeline
// - Root Presenter
// - Scenic
// - Child view, a Scenic client
//
// Touch dispatch path
// - Test program's injection -> Input Pipeline -> Scenic -> Child view
//
// Setup sequence
// - The test sets up this view hierarchy:
//   - Top level scene, owned by Root Presenter.
//   - Child view, owned by the ui client.
// - The test waits for a Scenic event that verifies the child has UI content in
// the scene graph.
// - The test injects input into Input Pipeline, emulating a display's touch
// report.
// - Input Pipeline dispatches the touch event to Scenic, which in turn
// dispatches it to the child.
// - The child receives the touch event and reports back to the test over a
// custom test-only FIDL.
// - Test waits for the child to report a touch; when the test receives the
// report, the test quits
//   successfully.
//
// This test uses the realm_builder library to construct the topology of
// components and routes services between them. For v2 components, every test
// driver component sits as a child of test_manager in the topology. Thus, the
// topology of a test driver component such as this one looks like this:
//
//     test_manager
//         |
//   touch-input-test.cml (this component)
//
// With the usage of the realm_builder library, we construct a realm during
// runtime and then extend the topology to look like:
//
//    test_manager
//         |
//   touch-input-test.cml (this component)
//         |
//   <created realm root>
//      /      \
//   scenic  input-pipeline
//
// For more information about testing v2 components and realm_builder,
// visit the following links:
//
// Testing: https://fuchsia.dev/fuchsia-src/concepts/testing/v2
// Realm Builder:
// https://fuchsia.dev/fuchsia-src/development/components/v2/realm_builder

namespace touch_input_test::testing {
namespace {
// Types imported for the realm_builder library.
using component_testing::ChildRef;
using component_testing::ConfigValue;
using component_testing::LocalComponent;
using component_testing::LocalComponentHandles;
using component_testing::ParentRef;
using component_testing::Protocol;
using component_testing::Realm;
using component_testing::RealmRoot;
using component_testing::Route;

using fuchsia_test_utils::PortableUITest;

using RealmBuilder = component_testing::RealmBuilder;
// Alias for Component child name as provided to Realm Builder.
using ChildName = std::string;
// Alias for Component Legacy URL as provided to Realm Builder.
using LegacyUrl = std::string;

// Max timeout in failure cases.
// Set this as low as you can that still works across all test platforms.
constexpr zx::duration kTimeout = zx::min(5);

constexpr auto kMockResponseListener = "response_listener";

enum class TapLocation { kTopLeft, kTopRight };

// Combines all vectors in `vecs` into one.
template <typename T>
std::vector<T> merge(std::initializer_list<std::vector<T>> vecs) {
  std::vector<T> result;
  for (auto v : vecs) {
    result.insert(result.end(), v.begin(), v.end());
  }
  return result;
}

bool CompareDouble(double f0, double f1, double epsilon) {
  return std::abs(f0 - f1) <= epsilon;
}

// // This component implements the test.touch.ResponseListener protocol
// // and the interface for a RealmBuilder LocalComponent. A LocalComponent
// // is a component that is implemented here in the test, as opposed to
// elsewhere
// // in the system. When it's inserted to the realm, it will act like a proper
// // component. This is accomplished, in part, because the realm_builder
// // library creates the necessary plumbing. It creates a manifest for the
// // component and routes all capabilities to and from it.
class ResponseListenerServer
    : public fuchsia::ui::test::input::TouchInputListener,
      public LocalComponent {
 public:
  explicit ResponseListenerServer(async_dispatcher_t* dispatcher)
      : dispatcher_(dispatcher) {}

  // |fuchsia::ui::test::input::TouchInputListener|
  void ReportTouchInput(
      fuchsia::ui::test::input::TouchInputListenerReportTouchInputRequest
          request) override {
    events_received_.push_back(std::move(request));
  }

  // |LocalComponent::Start|
  // When the component framework requests for this component to start, this
  // method will be invoked by the realm_builder library.
  void Start(std::unique_ptr<LocalComponentHandles> local_handles) override {
    // When this component starts, add a binding to the
    // test.touch.ResponseListener protocol to this component's outgoing
    // directory.
    ASSERT_EQ(ZX_OK, local_handles->outgoing()->AddPublicService(
                         fidl::InterfaceRequestHandler<
                             fuchsia::ui::test::input::TouchInputListener>(
                             [this](auto request) {
                               bindings_.AddBinding(this, std::move(request),
                                                    dispatcher_);
                             })));
    local_handles_.emplace_back(std::move(local_handles));
  }

  const std::vector<
      fuchsia::ui::test::input::TouchInputListenerReportTouchInputRequest>&
  events_received() {
    return events_received_;
  }

 private:
  async_dispatcher_t* dispatcher_ = nullptr;
  std::vector<std::unique_ptr<LocalComponentHandles>> local_handles_;
  fidl::BindingSet<fuchsia::ui::test::input::TouchInputListener> bindings_;
  std::vector<
      fuchsia::ui::test::input::TouchInputListenerReportTouchInputRequest>
      events_received_;
};

class FlutterTapTest : public PortableUITest,
                       public ::testing::Test,
                       public ::testing::WithParamInterface<std::string> {
 protected:
  ~FlutterTapTest() override {
    FML_CHECK(touch_injection_request_count() > 0)
        << "Injection expected but didn't happen.";
  }

  void SetUp() override {
    PortableUITest::SetUp();

    // Post a "just in case" quit task, if the test hangs.
    async::PostDelayedTask(
        dispatcher(),
        [] {
          FML_LOG(FATAL)
              << "\n\n>> Test did not complete in time, terminating.  <<\n\n";
        },
        kTimeout);

    // Get the display dimensions.
    FML_LOG(INFO) << "Waiting for scenic display info";
    scenic_ = realm_root()->template Connect<fuchsia::ui::scenic::Scenic>();
    scenic_->GetDisplayInfo([this](fuchsia::ui::gfx::DisplayInfo display_info) {
      display_width_ = display_info.width_in_px;
      display_height_ = display_info.height_in_px;
      FML_LOG(INFO) << "Got display_width = " << display_width_
                    << " and display_height = " << display_height_;
    });
    RunLoopUntil(
        [this] { return display_width_ != 0 && display_height_ != 0; });

    // Register input injection device.
    FML_LOG(INFO) << "Registering input injection device";
    RegisterTouchScreen();
  }

  // Routes needed to setup Flutter client.
  static std::vector<Route> GetFlutterRoutes(ChildRef target) {
    return {
        {.capabilities = {Protocol{
             fuchsia::ui::test::input::TouchInputListener::Name_}},
         .source = ChildRef{kMockResponseListener},
         .targets = {target}},
        {.capabilities = {Protocol{fuchsia::logger::LogSink::Name_},
                          Protocol{fuchsia::sysmem::Allocator::Name_},
                          Protocol{
                              fuchsia::tracing::provider::Registry::Name_}},
         .source = ParentRef(),
         .targets = {target}},
        {.capabilities = {Protocol{fuchsia::ui::scenic::Scenic::Name_}},
         .source = kTestUIStackRef,
         .targets = {target}},
    };
  }

  std::vector<Route> GetTestRoutes() {
    return merge(
        {GetFlutterRoutes(ChildRef{kFlutterRealm}),
         {
             {.capabilities = {Protocol{fuchsia::ui::app::ViewProvider::Name_}},
              .source = ChildRef{kFlutterRealm},
              .targets = {ParentRef()}},
         }});
  }

  std::vector<std::pair<ChildName, LegacyUrl>> GetTestV2Components() {
    return {
        std::make_pair(kFlutterRealm, kFlutterRealmUrl),
    };
  };

  bool LastEventReceivedMatches(float expected_x,
                                float expected_y,
                                std::string component_name) {
    const auto& events_received = response_listener_server_->events_received();
    if (events_received.empty()) {
      return false;
    }

    const auto& last_event = events_received.back();

    auto pixel_scale = last_event.has_device_pixel_ratio()
                           ? last_event.device_pixel_ratio()
                           : 1;

    auto actual_x = pixel_scale * last_event.local_x();
    auto actual_y = pixel_scale * last_event.local_y();

    FML_LOG(INFO) << "Expecting event for component " << component_name
                  << " at (" << expected_x << ", " << expected_y << ")";
    FML_LOG(INFO) << "Received event for component " << component_name
                  << " at (" << actual_x << ", " << actual_y
                  << "), accounting for pixel scale of " << pixel_scale;

    return CompareDouble(actual_x, expected_x, pixel_scale) &&
           CompareDouble(actual_y, expected_y, pixel_scale) &&
           last_event.component_name() == component_name;
  }

  void InjectInput(TapLocation tap_location) {
    // The /config/data/display_rotation (90) specifies how many degrees to
    // rotate the presentation child view, counter-clockwise, in a
    // right-handed coordinate system. Thus, the user observes the child
    // view to rotate *clockwise* by that amount (90).
    //
    // Hence, a tap in the center of the display's top-right quadrant is
    // observed by the child view as a tap in the center of its top-left
    // quadrant.
    auto touch = std::make_unique<fuchsia::ui::input::TouchscreenReport>();
    switch (tap_location) {
      case TapLocation::kTopLeft:
        // center of top right quadrant -> ends up as center of top left
        // quadrant
        InjectTap(/* x = */ 500, /* y = */ -500);
        break;
      case TapLocation::kTopRight:
        // center of bottom right quadrant -> ends up as center of top right
        // quadrant
        InjectTap(/* x = */ 500, /* y = */ 500);
        break;
      default:
        FML_CHECK(false) << "Received invalid TapLocation";
    }
  }

  // Guaranteed to be initialized after SetUp().
  uint32_t display_width() const { return display_width_; }
  uint32_t display_height() const { return display_height_; }

  static constexpr auto kFlutterRealm = "flutter-realm";
  static constexpr auto kFlutterRealmUrl =
      "fuchsia-pkg://fuchsia.com/one-flutter#meta/one-flutter-realm.cm";

 private:
  void ExtendRealm() override {
    // Key part of service setup: have this test component vend the
    // |ResponseListener| service in the constructed realm.
    response_listener_server_ =
        std::make_unique<ResponseListenerServer>(dispatcher());
    realm_builder()->AddLocalChild(kMockResponseListener,
                                   response_listener_server_.get());

    realm_builder()->AddRoute(
        {.capabilities = {Protocol{fuchsia::ui::scenic::Scenic::Name_}},
         .source = kTestUIStackRef,
         .targets = {ParentRef()}});

    // Add components specific for this test case to the realm.
    for (const auto& [name, component] : GetTestV2Components()) {
      realm_builder()->AddChild(name, component);
    }

    // Add the necessary routing for each of the extra components added
    // above.
    for (const auto& route : GetTestRoutes()) {
      realm_builder()->AddRoute(route);
    }
  }

  ParamType GetTestUIStackUrl() override { return GetParam(); };

  std::unique_ptr<ResponseListenerServer> response_listener_server_;

  fuchsia::ui::scenic::ScenicPtr scenic_;
  uint32_t display_width_ = 0;
  uint32_t display_height_ = 0;
};

INSTANTIATE_TEST_SUITE_P(
    FlutterTapTestParameterized,
    FlutterTapTest,
    ::testing::Values(
        "fuchsia-pkg://fuchsia.com/gfx-root-presenter-test-ui-stack#meta/"
        "test-ui-stack.cm"));

TEST_P(FlutterTapTest, FlutterTap) {
  // Launch client view, and wait until it's rendering to proceed with the test.
  FML_LOG(INFO) << "Initializing scene";
  LaunchClient();
  FML_LOG(INFO) << "Client launched";

  InjectInput(TapLocation::kTopLeft);
  RunLoopUntil([this] {
    return LastEventReceivedMatches(
        /*expected_x=*/static_cast<float>(display_height()) / 4.f,
        /*expected_y=*/static_cast<float>(display_width()) / 4.f,
        /*component_name=*/"one-flutter");
  });
}

}  // namespace
}  // namespace touch_input_test::testing
