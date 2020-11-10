// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_COMMON_SHELL_TEST_H_
#define FLUTTER_SHELL_COMMON_SHELL_TEST_H_

#include "flutter/shell/common/shell.h"

#include <memory>

#include "flutter/common/graphics/persistent_cache.h"
#include "flutter/common/settings.h"
#include "flutter/flow/layers/container_layer.h"
#include "flutter/fml/build_config.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/time/time_point.h"
#include "flutter/lib/ui/window/platform_message.h"
#include "flutter/shell/common/run_configuration.h"
#include "flutter/shell/common/shell_test_external_view_embedder.h"
#include "flutter/shell/common/thread_host.h"
#include "flutter/shell/common/vsync_waiters_test.h"
#include "flutter/testing/elf_loader.h"
#include "flutter/testing/fixture_test.h"
#include "flutter/testing/test_dart_native_resolver.h"

namespace flutter {
namespace testing {

class ShellTest : public FixtureTest {
 public:
  ShellTest();

  Settings CreateSettingsForFixture() override;
  std::unique_ptr<Shell> CreateShell(Settings settings,
                                     bool simulate_vsync = false);
  std::unique_ptr<Shell> CreateShell(
      Settings settings,
      TaskRunners task_runners,
      bool simulate_vsync = false,
      std::shared_ptr<ShellTestExternalViewEmbedder>
          shell_test_external_view_embedder = nullptr);
  void DestroyShell(std::unique_ptr<Shell> shell);
  void DestroyShell(std::unique_ptr<Shell> shell, TaskRunners task_runners);
  TaskRunners GetTaskRunnersForFixture();

  fml::TimePoint GetLatestFrameTargetTime(Shell* shell) const;

  void SendEnginePlatformMessage(Shell* shell,
                                 fml::RefPtr<PlatformMessage> message);

  static void PlatformViewNotifyCreated(
      Shell* shell);  // This creates the surface
  static void PlatformViewNotifyDestroyed(
      Shell* shell);  // This destroys the surface
  static void RunEngine(Shell* shell, RunConfiguration configuration);
  static void RestartEngine(Shell* shell, RunConfiguration configuration);

  /// Issue as many VSYNC as needed to flush the UI tasks so far, and reset
  /// the `will_draw_new_frame` to true.
  static void VSyncFlush(Shell* shell, bool& will_draw_new_frame);

  /// Given the root layer, this callback builds the layer tree to be rasterized
  /// in PumpOneFrame.
  using LayerTreeBuilder =
      std::function<void(std::shared_ptr<ContainerLayer> root)>;

  static void SetViewportMetrics(Shell* shell, double width, double height);
  static void NotifyIdle(Shell* shell, int64_t deadline);

  static void PumpOneFrame(Shell* shell,
                           double width = 1,
                           double height = 1,
                           LayerTreeBuilder = {});
  static void PumpOneFrame(Shell* shell,
                           flutter::ViewportMetrics viewport_metrics,
                           LayerTreeBuilder = {});
  static void DispatchFakePointerData(Shell* shell);
  static void DispatchPointerData(Shell* shell,
                                  std::unique_ptr<PointerDataPacket> packet);
  // Declare |UnreportedTimingsCount|, |GetNeedsReportTimings| and
  // |SetNeedsReportTimings| inside |ShellTest| mainly for easier friend class
  // declarations as shell unit tests and Shell are in different name spaces.

  static bool GetNeedsReportTimings(Shell* shell);
  static void SetNeedsReportTimings(Shell* shell, bool value);

  // Declare |StorePersistentCache| inside |ShellTest| so |PersistentCache| can
  // friend |ShellTest| and allow us to call private |PersistentCache::store| in
  // unit tests.
  static void StorePersistentCache(PersistentCache* cache,
                                   const SkData& key,
                                   const SkData& value);

  enum ServiceProtocolEnum {
    kGetSkSLs,
    kEstimateRasterCacheMemory,
    kSetAssetBundlePath,
    kRunInView,
  };

  // Helper method to test private method Shell::OnServiceProtocolGetSkSLs.
  // (ShellTest is a friend class of Shell.) We'll also make sure that it is
  // running on the correct task_runner.
  static void OnServiceProtocol(
      Shell* shell,
      ServiceProtocolEnum some_protocol,
      fml::RefPtr<fml::TaskRunner> task_runner,
      const ServiceProtocol::Handler::ServiceProtocolMap& params,
      rapidjson::Document* response);

  std::shared_ptr<txt::FontCollection> GetFontCollection(Shell* shell);

  // Do not assert |UnreportedTimingsCount| to be positive in any tests.
  // Otherwise those tests will be flaky as the clearing of unreported timings
  // is unpredictive.
  static int UnreportedTimingsCount(Shell* shell);

 private:
  ThreadHost thread_host_;

  FML_DISALLOW_COPY_AND_ASSIGN(ShellTest);
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_SHELL_COMMON_SHELL_TEST_H_
