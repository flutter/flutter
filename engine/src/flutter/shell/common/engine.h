// Copyright 2015 The Chromium Authors. All rights reserved.
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
#include "third_party/skia/include/core/SkPicture.h"

namespace shell {

class Engine final : public blink::RuntimeDelegate {
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
        blink::SemanticsNodeUpdates update,
        blink::CustomAccessibilityActionUpdates actions) = 0;

    virtual void OnEngineHandlePlatformMessage(
        fml::RefPtr<blink::PlatformMessage> message) = 0;

    virtual void OnPreEngineRestart() = 0;
  };

  Engine(Delegate& delegate,
         blink::DartVM& vm,
         fml::RefPtr<blink::DartSnapshot> isolate_snapshot,
         fml::RefPtr<blink::DartSnapshot> shared_snapshot,
         blink::TaskRunners task_runners,
         blink::Settings settings,
         std::unique_ptr<Animator> animator,
         fml::WeakPtr<blink::SnapshotDelegate> snapshot_delegate,
         fml::WeakPtr<GrContext> resource_context,
         fml::RefPtr<flow::SkiaUnrefQueue> unref_queue);

  ~Engine() override;

  fml::WeakPtr<Engine> GetWeakPtr() const;

  FML_WARN_UNUSED_RESULT
  RunStatus Run(RunConfiguration configuration);

  // Used to "cold reload" a running application where the shell (along with the
  // platform view and its rasterizer bindings) remains the same but the root
  // isolate is torn down and restarted with the new configuration. Only used in
  // the development workflow.
  FML_WARN_UNUSED_RESULT
  bool Restart(RunConfiguration configuration);

  bool UpdateAssetManager(fml::RefPtr<blink::AssetManager> asset_manager);

  void BeginFrame(fml::TimePoint frame_time);

  void NotifyIdle(int64_t deadline);

  Dart_Port GetUIIsolateMainPort();

  std::string GetUIIsolateName();

  bool UIIsolateHasLivePorts();

  tonic::DartErrorHandleType GetUIIsolateLastError();

  std::pair<bool, uint32_t> GetUIIsolateReturnCode();

  void OnOutputSurfaceCreated();

  void OnOutputSurfaceDestroyed();

  void SetViewportMetrics(const blink::ViewportMetrics& metrics);

  void DispatchPlatformMessage(fml::RefPtr<blink::PlatformMessage> message);

  void DispatchPointerDataPacket(const blink::PointerDataPacket& packet);

  void DispatchSemanticsAction(int id,
                               blink::SemanticsAction action,
                               std::vector<uint8_t> args);

  void SetSemanticsEnabled(bool enabled);

  void SetAccessibilityFeatures(int32_t flags);

  void ScheduleFrame(bool regenerate_layer_tree = true) override;

  // |blink::RuntimeDelegate|
  blink::FontCollection& GetFontCollection() override;

 private:
  Engine::Delegate& delegate_;
  const blink::Settings settings_;
  std::unique_ptr<Animator> animator_;
  std::unique_ptr<blink::RuntimeController> runtime_controller_;
  std::string initial_route_;
  blink::ViewportMetrics viewport_metrics_;
  fml::RefPtr<blink::AssetManager> asset_manager_;
  bool activity_running_;
  bool have_surface_;
  blink::FontCollection font_collection_;
  fml::WeakPtrFactory<Engine> weak_factory_;

  // |blink::RuntimeDelegate|
  std::string DefaultRouteName() override;

  // |blink::RuntimeDelegate|
  void Render(std::unique_ptr<flow::LayerTree> layer_tree) override;

  // |blink::RuntimeDelegate|
  void UpdateSemantics(
      blink::SemanticsNodeUpdates update,
      blink::CustomAccessibilityActionUpdates actions) override;

  // |blink::RuntimeDelegate|
  void HandlePlatformMessage(
      fml::RefPtr<blink::PlatformMessage> message) override;

  void StopAnimator();

  void StartAnimatorIfPossible();

  bool HandleLifecyclePlatformMessage(blink::PlatformMessage* message);

  bool HandleNavigationPlatformMessage(
      fml::RefPtr<blink::PlatformMessage> message);

  bool HandleLocalizationPlatformMessage(blink::PlatformMessage* message);

  void HandleSettingsPlatformMessage(blink::PlatformMessage* message);

  void HandleAssetPlatformMessage(fml::RefPtr<blink::PlatformMessage> message);

  bool GetAssetAsBuffer(const std::string& name, std::vector<uint8_t>* data);

  RunStatus PrepareAndLaunchIsolate(RunConfiguration configuration);

  FML_DISALLOW_COPY_AND_ASSIGN(Engine);
};

}  // namespace shell

#endif  // SHELL_COMMON_ENGINE_H_
