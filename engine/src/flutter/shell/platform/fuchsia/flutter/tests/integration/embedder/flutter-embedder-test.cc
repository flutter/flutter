// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <fuchsia/logger/cpp/fidl.h>
#include <fuchsia/tracing/provider/cpp/fidl.h>
#include <fuchsia/ui/app/cpp/fidl.h>
#include <fuchsia/ui/composition/cpp/fidl.h>
#include <fuchsia/ui/observation/geometry/cpp/fidl.h>
#include <fuchsia/ui/scenic/cpp/fidl.h>
#include <fuchsia/ui/test/input/cpp/fidl.h>
#include <fuchsia/ui/test/scene/cpp/fidl.h>
#include <lib/async-loop/testing/cpp/real_loop.h>
#include <lib/async/cpp/task.h>
#include <lib/fidl/cpp/binding_set.h>
#include <lib/sys/component/cpp/testing/realm_builder.h>
#include <lib/sys/component/cpp/testing/realm_builder_types.h>
#include <lib/ui/scenic/cpp/view_ref_pair.h>
#include <lib/zx/clock.h>
#include <zircon/status.h>
#include <zircon/time.h>

#include <optional>
#include <vector>

#include "flutter/fml/logging.h"
#include "gtest/gtest.h"

#include "flutter/shell/platform/fuchsia/flutter/tests/integration/utils/check_view.h"
#include "flutter/shell/platform/fuchsia/flutter/tests/integration/utils/color.h"
#include "flutter/shell/platform/fuchsia/flutter/tests/integration/utils/screenshot.h"

namespace flutter_embedder_test {
namespace {

// Types imported for the realm_builder library.
using component_testing::ChildOptions;
using component_testing::ChildRef;
using component_testing::DirectoryContents;
using component_testing::ParentRef;
using component_testing::Protocol;
using component_testing::RealmRoot;
using component_testing::Route;
using component_testing::StartupMode;

using fuchsia_test_utils::CheckViewExistsInUpdates;

// The FIDL bindings for this service are not exposed in the Fuchsia SDK, so we
// must encode the name manually here.
constexpr auto kVulkanLoaderServiceName = "fuchsia.vulkan.loader.Loader";

constexpr auto kFlutterJitRunnerUrl =
    "fuchsia-pkg://fuchsia.com/oot_flutter_jit_runner#meta/"
    "flutter_jit_runner.cm";
constexpr auto kFlutterJitProductRunnerUrl =
    "fuchsia-pkg://fuchsia.com/oot_flutter_jit_product_runner#meta/"
    "flutter_jit_product_runner.cm";
constexpr auto kFlutterAotRunnerUrl =
    "fuchsia-pkg://fuchsia.com/oot_flutter_aot_runner#meta/"
    "flutter_aot_runner.cm";
constexpr auto kFlutterAotProductRunnerUrl =
    "fuchsia-pkg://fuchsia.com/oot_flutter_aot_product_runner#meta/"
    "flutter_aot_product_runner.cm";
constexpr char kChildViewUrl[] =
    "fuchsia-pkg://fuchsia.com/child-view#meta/child-view.cm";
constexpr char kParentViewUrl[] =
    "fuchsia-pkg://fuchsia.com/parent-view#meta/parent-view.cm";
static constexpr auto kTestUiStackUrl =
    "fuchsia-pkg://fuchsia.com/test-ui-stack#meta/test-ui-stack.cm";

constexpr auto kFlutterRunnerEnvironment = "flutter_runner_env";
constexpr auto kFlutterJitRunner = "flutter_jit_runner";
constexpr auto kFlutterJitRunnerRef = ChildRef{kFlutterJitRunner};
constexpr auto kFlutterJitProductRunner = "flutter_jit_product_runner";
constexpr auto kFlutterJitProductRunnerRef = ChildRef{kFlutterJitProductRunner};
constexpr auto kFlutterAotRunner = "flutter_aot_runner";
constexpr auto kFlutterAotRunnerRef = ChildRef{kFlutterAotRunner};
constexpr auto kFlutterAotProductRunner = "flutter_aot_product_runner";
constexpr auto kFlutterAotProductRunnerRef = ChildRef{kFlutterAotProductRunner};
constexpr auto kChildView = "child_view";
constexpr auto kChildViewRef = ChildRef{kChildView};
constexpr auto kParentView = "parent_view";
constexpr auto kParentViewRef = ChildRef{kParentView};
constexpr auto kTestUiStack = "ui";
constexpr auto kTestUiStackRef = ChildRef{kTestUiStack};

constexpr fuchsia_test_utils::Color kParentBackgroundColor = {0x00, 0x00, 0xFF,
                                                              0xFF};  // Blue
constexpr fuchsia_test_utils::Color kChildBackgroundColor = {0xFF, 0x00, 0xFF,
                                                             0xFF};  // Pink

// TODO(fxb/64201): Remove forced opacity colors when Flatland is enabled.
constexpr fuchsia_test_utils::Color kOverlayBackgroundColor1 = {
    0x00, 0xFF, 0x0E, 0xFF};  // Green, blended with blue (FEMU local)
constexpr fuchsia_test_utils::Color kOverlayBackgroundColor2 = {
    0x0E, 0xFF, 0x0E, 0xFF};  // Green, blended with pink (FEMU local)
constexpr fuchsia_test_utils::Color kOverlayBackgroundColor3 = {
    0x00, 0xFF, 0x0D, 0xFF};  // Green, blended with blue (AEMU infra)
constexpr fuchsia_test_utils::Color kOverlayBackgroundColor4 = {
    0x0D, 0xFF, 0x0D, 0xFF};  // Green, blended with pink (AEMU infra)
constexpr fuchsia_test_utils::Color kOverlayBackgroundColor5 = {
    0x00, 0xFE, 0x0D, 0xFF};  // Green, blended with blue (NUC)
constexpr fuchsia_test_utils::Color kOverlayBackgroundColor6 = {
    0x0D, 0xFF, 0x00, 0xFF};  // Green, blended with pink (NUC)

static size_t OverlayPixelCount(
    std::map<fuchsia_test_utils::Color, size_t>& histogram) {
  return histogram[kOverlayBackgroundColor1] +
         histogram[kOverlayBackgroundColor2] +
         histogram[kOverlayBackgroundColor3] +
         histogram[kOverlayBackgroundColor4] +
         histogram[kOverlayBackgroundColor5] +
         histogram[kOverlayBackgroundColor6];
}

// Timeout for Scenic's |TakeScreenshot| FIDL call.
constexpr zx::duration kScreenshotTimeout = zx::sec(10);
// Timeout to fail the test if it goes beyond this duration.
constexpr zx::duration kTestTimeout = zx::min(1);

}  // namespace

class FlutterEmbedderTest : public ::loop_fixture::RealLoop,
                            public ::testing::Test {
 public:
  FlutterEmbedderTest()
      : realm_builder_(component_testing::RealmBuilder::Create()) {
    FML_VLOG(-1) << "Setting up base realm";
    SetUpRealmBase();

    // Post a "just in case" quit task, if the test hangs.
    async::PostDelayedTask(
        dispatcher(),
        [] {
          FML_LOG(FATAL)
              << "\n\n>> Test did not complete in time, terminating.  <<\n\n";
        },
        kTestTimeout);
  }

  bool HasViewConnected(
      const fuchsia::ui::observation::geometry::ViewTreeWatcherPtr&
          view_tree_watcher,
      std::optional<fuchsia::ui::observation::geometry::WatchResponse>&
          watch_response,
      zx_koid_t view_ref_koid);

  void LaunchParentViewInRealm(
      const std::vector<std::string>& component_args = {});

  fuchsia_test_utils::Screenshot TakeScreenshot();

  bool TakeScreenshotUntil(
      fuchsia_test_utils::Color color,
      fit::function<void(std::map<fuchsia_test_utils::Color, size_t>)>
          callback = nullptr,
      zx::duration timeout = kTestTimeout);

 private:
  fuchsia::ui::scenic::Scenic* scenic() { return scenic_.get(); }

  void SetUpRealmBase();

  fuchsia::ui::scenic::ScenicPtr scenic_;
  fuchsia::ui::test::scene::ControllerPtr scene_provider_;
  fuchsia::ui::observation::geometry::ViewTreeWatcherPtr view_tree_watcher_;

  // Wrapped in optional since the view is not created until the middle of SetUp
  component_testing::RealmBuilder realm_builder_;
  std::unique_ptr<component_testing::RealmRoot> realm_;
};

void FlutterEmbedderTest::SetUpRealmBase() {
  FML_LOG(INFO) << "Setting up realm base.";

  // First, add the flutter runner(s) as children.
  realm_builder_.AddChild(kFlutterJitRunner, kFlutterJitRunnerUrl);
  realm_builder_.AddChild(kFlutterJitProductRunner,
                          kFlutterJitProductRunnerUrl);
  realm_builder_.AddChild(kFlutterAotRunner, kFlutterAotRunnerUrl);
  realm_builder_.AddChild(kFlutterAotProductRunner,
                          kFlutterAotProductRunnerUrl);

  // Then, add an environment providing them.
  fuchsia::component::decl::Environment flutter_runner_environment;
  flutter_runner_environment.set_name(kFlutterRunnerEnvironment);
  flutter_runner_environment.set_extends(
      fuchsia::component::decl::EnvironmentExtends::REALM);
  flutter_runner_environment.set_runners({});
  auto environment_runners = flutter_runner_environment.mutable_runners();
  fuchsia::component::decl::RunnerRegistration flutter_jit_runner_reg;
  flutter_jit_runner_reg.set_source(fuchsia::component::decl::Ref::WithChild(
      fuchsia::component::decl::ChildRef{.name = kFlutterJitRunner}));
  flutter_jit_runner_reg.set_source_name(kFlutterJitRunner);
  flutter_jit_runner_reg.set_target_name(kFlutterJitRunner);
  environment_runners->push_back(std::move(flutter_jit_runner_reg));
  fuchsia::component::decl::RunnerRegistration flutter_jit_product_runner_reg;
  flutter_jit_product_runner_reg.set_source(
      fuchsia::component::decl::Ref::WithChild(
          fuchsia::component::decl::ChildRef{.name =
                                                 kFlutterJitProductRunner}));
  flutter_jit_product_runner_reg.set_source_name(kFlutterJitProductRunner);
  flutter_jit_product_runner_reg.set_target_name(kFlutterJitProductRunner);
  environment_runners->push_back(std::move(flutter_jit_product_runner_reg));
  fuchsia::component::decl::RunnerRegistration flutter_aot_runner_reg;
  flutter_aot_runner_reg.set_source(fuchsia::component::decl::Ref::WithChild(
      fuchsia::component::decl::ChildRef{.name = kFlutterAotRunner}));
  flutter_aot_runner_reg.set_source_name(kFlutterAotRunner);
  flutter_aot_runner_reg.set_target_name(kFlutterAotRunner);
  environment_runners->push_back(std::move(flutter_aot_runner_reg));
  fuchsia::component::decl::RunnerRegistration flutter_aot_product_runner_reg;
  flutter_aot_product_runner_reg.set_source(
      fuchsia::component::decl::Ref::WithChild(
          fuchsia::component::decl::ChildRef{.name =
                                                 kFlutterAotProductRunner}));
  flutter_aot_product_runner_reg.set_source_name(kFlutterAotProductRunner);
  flutter_aot_product_runner_reg.set_target_name(kFlutterAotProductRunner);
  environment_runners->push_back(std::move(flutter_aot_product_runner_reg));
  auto realm_decl = realm_builder_.GetRealmDecl();
  if (!realm_decl.has_environments()) {
    realm_decl.set_environments({});
  }
  auto realm_environments = realm_decl.mutable_environments();
  realm_environments->push_back(std::move(flutter_runner_environment));
  realm_builder_.ReplaceRealmDecl(std::move(realm_decl));

  // Add test UI stack component.
  realm_builder_.AddChild(kTestUiStack, kTestUiStackUrl);

  // Add embedded parent and child components.
  realm_builder_.AddChild(kChildView, kChildViewUrl,
                          ChildOptions{
                              .environment = kFlutterRunnerEnvironment,
                          });
  realm_builder_.AddChild(kParentView, kParentViewUrl,
                          ChildOptions{
                              .environment = kFlutterRunnerEnvironment,
                          });

  // Route base system services to flutter runners.
  realm_builder_.AddRoute(
      Route{.capabilities =
                {
                    Protocol{fuchsia::logger::LogSink::Name_},
                    Protocol{fuchsia::sysmem::Allocator::Name_},
                    Protocol{fuchsia::tracing::provider::Registry::Name_},
                    Protocol{kVulkanLoaderServiceName},
                },
            .source = ParentRef{},
            .targets = {kFlutterJitRunnerRef, kFlutterJitProductRunnerRef,
                        kFlutterAotRunnerRef, kFlutterAotProductRunnerRef}});

  // Route base system services to the test UI stack.
  realm_builder_.AddRoute(Route{
      .capabilities = {Protocol{fuchsia::logger::LogSink::Name_},
                       Protocol{fuchsia::sysmem::Allocator::Name_},
                       Protocol{fuchsia::tracing::provider::Registry::Name_},
                       Protocol{kVulkanLoaderServiceName}},
      .source = ParentRef{},
      .targets = {kTestUiStackRef}});

  // Route UI capabilities from test UI stack to flutter runners.
  realm_builder_.AddRoute(Route{
      .capabilities = {Protocol{fuchsia::ui::composition::Flatland::Name_},
                       Protocol{fuchsia::ui::scenic::Scenic::Name_}},
      .source = kTestUiStackRef,
      .targets = {kFlutterJitRunnerRef, kFlutterJitProductRunnerRef,
                  kFlutterAotRunnerRef, kFlutterAotProductRunnerRef}});

  // Route test capabilities from test UI stack to test driver.
  realm_builder_.AddRoute(Route{
      .capabilities = {Protocol{fuchsia::ui::test::input::Registry::Name_},
                       Protocol{fuchsia::ui::test::scene::Controller::Name_},
                       Protocol{fuchsia::ui::scenic::Scenic::Name_}},
      .source = kTestUiStackRef,
      .targets = {ParentRef{}}});

  // Route ViewProvider from child to parent, and parent to test.
  realm_builder_.AddRoute(
      Route{.capabilities = {Protocol{fuchsia::ui::app::ViewProvider::Name_}},
            .source = kParentViewRef,
            .targets = {ParentRef()}});
  realm_builder_.AddRoute(
      Route{.capabilities = {Protocol{fuchsia::ui::app::ViewProvider::Name_}},
            .source = kChildViewRef,
            .targets = {kParentViewRef}});
}

// Checks whether the view with |view_ref_koid| has connected to the view tree.
// The response of a f.u.o.g.Provider.Watch call is stored in |watch_response|
// if it contains |view_ref_koid|.
bool FlutterEmbedderTest::HasViewConnected(
    const fuchsia::ui::observation::geometry::ViewTreeWatcherPtr&
        view_tree_watcher,
    std::optional<fuchsia::ui::observation::geometry::WatchResponse>&
        watch_response,
    zx_koid_t view_ref_koid) {
  std::optional<fuchsia::ui::observation::geometry::WatchResponse> watch_result;
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

void FlutterEmbedderTest::LaunchParentViewInRealm(
    const std::vector<std::string>& component_args) {
  FML_LOG(INFO) << "Launching parent-view";

  if (!component_args.empty()) {
    // Construct a args.csv file containing the specified comma-separated
    // component args.
    std::string csv;
    for (const auto& arg : component_args) {
      csv += arg + ',';
    }
    // Remove last comma.
    csv.pop_back();

    auto config_directory_contents = DirectoryContents();
    config_directory_contents.AddFile("args.csv", csv);
    realm_builder_.RouteReadOnlyDirectory("config-data", {kParentViewRef},
                                          std::move(config_directory_contents));
  }
  realm_ = std::make_unique<RealmRoot>(realm_builder_.Build());

  // Instruct Test UI Stack to present parent-view's View.
  std::optional<zx_koid_t> view_ref_koid;
  scene_provider_ =
      realm_->component().Connect<fuchsia::ui::test::scene::Controller>();
  scene_provider_.set_error_handler(
      [](auto) { FML_LOG(ERROR) << "Error from test scene provider"; });
  fuchsia::ui::test::scene::ControllerAttachClientViewRequest request;
  request.set_view_provider(
      realm_->component().Connect<fuchsia::ui::app::ViewProvider>());
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
  FML_LOG(INFO) << "Waiting for client view to render; koid is "
                << (view_ref_koid.has_value() ? view_ref_koid.value() : 0);
  RunLoopUntil([this, &watch_response, &view_ref_koid] {
    return HasViewConnected(view_tree_watcher_, watch_response, *view_ref_koid);
  });
  FML_LOG(INFO) << "Client view has rendered";

  scenic_ = realm_->component().Connect<fuchsia::ui::scenic::Scenic>();
  FML_LOG(INFO) << "Launched parent-view";
}

fuchsia_test_utils::Screenshot FlutterEmbedderTest::TakeScreenshot() {
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

  return fuchsia_test_utils::Screenshot(screenshot_out);
}

bool FlutterEmbedderTest::TakeScreenshotUntil(
    fuchsia_test_utils::Color color,
    fit::function<void(std::map<fuchsia_test_utils::Color, size_t>)> callback,
    zx::duration timeout) {
  return RunLoopWithTimeoutOrUntil(
      [this, &callback, &color] {
        auto screenshot = TakeScreenshot();
        auto histogram = screenshot.Histogram();

        bool color_found = histogram[color] > 0;
        if (color_found && callback != nullptr) {
          callback(std::move(histogram));
        }
        return color_found;
      },
      timeout);
}

TEST_F(FlutterEmbedderTest, Embedding) {
  LaunchParentViewInRealm();

  // Take screenshot until we see the child-view's embedded color.
  ASSERT_TRUE(TakeScreenshotUntil(
      kChildBackgroundColor,
      [](std::map<fuchsia_test_utils::Color, size_t> histogram) {
        // Expect parent and child background colors, with parent color > child
        // color.
        EXPECT_GT(histogram[kParentBackgroundColor], 0u);
        EXPECT_GT(histogram[kChildBackgroundColor], 0u);
        EXPECT_GT(histogram[kParentBackgroundColor],
                  histogram[kChildBackgroundColor]);
      }));
}

TEST_F(FlutterEmbedderTest, EmbeddingWithOverlay) {
  LaunchParentViewInRealm({"--showOverlay"});

  // Take screenshot until we see the child-view's embedded color.
  ASSERT_TRUE(TakeScreenshotUntil(
      kChildBackgroundColor,
      [](std::map<fuchsia_test_utils::Color, size_t> histogram) {
        // Expect parent, overlay and child background colors.
        // With parent color > child color and overlay color > child color.
        const size_t overlay_pixel_count = OverlayPixelCount(histogram);
        EXPECT_GT(histogram[kParentBackgroundColor], 0u);
        EXPECT_GT(overlay_pixel_count, 0u);
        EXPECT_GT(histogram[kChildBackgroundColor], 0u);
        EXPECT_GT(histogram[kParentBackgroundColor],
                  histogram[kChildBackgroundColor]);
        EXPECT_GT(overlay_pixel_count, histogram[kChildBackgroundColor]);
      }));
}

}  // namespace flutter_embedder_test
