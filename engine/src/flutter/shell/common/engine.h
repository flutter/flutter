// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_COMMON_ENGINE_H_
#define SHELL_COMMON_ENGINE_H_

#include <memory>
#include <string>

#include "flutter/assets/asset_manager.h"
#include "flutter/common/task_runners.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/lib/ui/semantics/custom_accessibility_action.h"
#include "flutter/lib/ui/semantics/semantics_node.h"
#include "flutter/lib/ui/snapshot_delegate.h"
#include "flutter/lib/ui/text/font_collection.h"
#include "flutter/lib/ui/window/platform_message.h"
#include "flutter/lib/ui/window/viewport_metrics.h"
#include "flutter/runtime/dart_vm.h"
#include "flutter/runtime/runtime_controller.h"
#include "flutter/runtime/runtime_delegate.h"
#include "flutter/shell/common/animator.h"
#include "flutter/shell/common/rasterizer.h"
#include "flutter/shell/common/run_configuration.h"
#include "flutter/shell/common/shell_io_manager.h"
#include "third_party/skia/include/core/SkPicture.h"

namespace flutter {

/// Manager of the root Dart isolate and the relay of platform messages.
///
/// Also setups up dart::ui bindings and handles restarts.
class Engine final : public RuntimeDelegate {
 public:
  // Used by Engine::Run
  enum class RunStatus {
    Success,                // Successful call to Run()
    FailureAlreadyRunning,  // Isolate was already running; may not be
                            // considered a failure by callers
    Failure,  // Isolate could not be started or other unspecified failure
  };

  class Delegate {
   public:
    virtual void OnEngineUpdateSemantics(
        SemanticsNodeUpdates update,
        CustomAccessibilityActionUpdates actions) = 0;

    virtual void OnEngineHandlePlatformMessage(
        fml::RefPtr<PlatformMessage> message) = 0;

    virtual void OnPreEngineRestart() = 0;

    virtual void UpdateIsolateDescription(const std::string isolate_name,
                                          int64_t isolate_port) = 0;

    virtual void SetNeedsReportTimings(bool value) = 0;
  };

  Engine(Delegate& delegate,
         DartVM& vm,
         fml::RefPtr<const DartSnapshot> isolate_snapshot,
         fml::RefPtr<const DartSnapshot> shared_snapshot,
         TaskRunners task_runners,
         Settings settings,
         std::unique_ptr<Animator> animator,
         fml::WeakPtr<SnapshotDelegate> snapshot_delegate,
         fml::WeakPtr<IOManager> io_manager);

  ~Engine() override;

  float GetDisplayRefreshRate() const;

  fml::WeakPtr<Engine> GetWeakPtr() const;

  FML_WARN_UNUSED_RESULT
  RunStatus Run(RunConfiguration configuration);

  // Used to "cold reload" a running application where the shell (along with the
  // platform view and its rasterizer bindings) remains the same but the root
  // isolate is torn down and restarted with the new configuration. Only used in
  // the development workflow.
  FML_WARN_UNUSED_RESULT
  bool Restart(RunConfiguration configuration);

  bool UpdateAssetManager(std::shared_ptr<AssetManager> asset_manager);

  void BeginFrame(fml::TimePoint frame_time);

  void ReportTimings(std::vector<int64_t> timings);

  void NotifyIdle(int64_t deadline);

  Dart_Port GetUIIsolateMainPort();

  std::string GetUIIsolateName();

  bool UIIsolateHasLivePorts();

  tonic::DartErrorHandleType GetUIIsolateLastError();

  std::pair<bool, uint32_t> GetUIIsolateReturnCode();

  void OnOutputSurfaceCreated();

  void OnOutputSurfaceDestroyed();

  void SetViewportMetrics(const ViewportMetrics& metrics);

  void DispatchPlatformMessage(fml::RefPtr<PlatformMessage> message);

  void DispatchPointerDataPacket(const PointerDataPacket& packet,
                                 uint64_t trace_flow_id);

  void DispatchSemanticsAction(int id,
                               SemanticsAction action,
                               std::vector<uint8_t> args);

  void SetSemanticsEnabled(bool enabled);

  void SetAccessibilityFeatures(int32_t flags);

  void ScheduleFrame(bool regenerate_layer_tree = true) override;

  // |RuntimeDelegate|
  FontCollection& GetFontCollection() override;

 private:
  Engine::Delegate& delegate_;
  const Settings settings_;
  std::unique_ptr<Animator> animator_;
  std::unique_ptr<RuntimeController> runtime_controller_;
  std::string initial_route_;
  ViewportMetrics viewport_metrics_;
  std::shared_ptr<AssetManager> asset_manager_;
  bool activity_running_;
  bool have_surface_;
  FontCollection font_collection_;
  fml::WeakPtrFactory<Engine> weak_factory_;

  // |RuntimeDelegate|
  std::string DefaultRouteName() override;

  // |RuntimeDelegate|
  void Render(std::unique_ptr<flutter::LayerTree> layer_tree) override;

  // |RuntimeDelegate|
  void UpdateSemantics(SemanticsNodeUpdates update,
                       CustomAccessibilityActionUpdates actions) override;

  // |RuntimeDelegate|
  void HandlePlatformMessage(fml::RefPtr<PlatformMessage> message) override;

  // |RuntimeDelegate|
  void UpdateIsolateDescription(const std::string isolate_name,
                                int64_t isolate_port) override;

  void SetNeedsReportTimings(bool value) override;

  void StopAnimator();

  void StartAnimatorIfPossible();

  bool HandleLifecyclePlatformMessage(PlatformMessage* message);

  bool HandleNavigationPlatformMessage(fml::RefPtr<PlatformMessage> message);

  bool HandleLocalizationPlatformMessage(PlatformMessage* message);

  void HandleSettingsPlatformMessage(PlatformMessage* message);

  void HandleAssetPlatformMessage(fml::RefPtr<PlatformMessage> message);

  bool GetAssetAsBuffer(const std::string& name, std::vector<uint8_t>* data);

  RunStatus PrepareAndLaunchIsolate(RunConfiguration configuration);

  friend class testing::ShellTest;

  FML_DISALLOW_COPY_AND_ASSIGN(Engine);
};

}  // namespace flutter

#endif  // SHELL_COMMON_ENGINE_H_
