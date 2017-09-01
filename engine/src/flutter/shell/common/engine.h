// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_COMMON_ENGINE_H_
#define SHELL_COMMON_ENGINE_H_

#include "flutter/assets/zip_asset_store.h"
#include "flutter/lib/ui/window/platform_message.h"
#include "flutter/lib/ui/window/viewport_metrics.h"
#include "flutter/runtime/runtime_controller.h"
#include "flutter/runtime/runtime_delegate.h"
#include "flutter/shell/common/rasterizer.h"
#include "lib/ftl/macros.h"
#include "lib/ftl/memory/weak_ptr.h"
#include "third_party/skia/include/core/SkPicture.h"

namespace blink {
class DirectoryAssetBundle;
class ZipAssetBundle;
}  // namespace blink

namespace shell {
class PlatformView;
class Animator;
using PointerDataPacket = blink::PointerDataPacket;

class Engine : public blink::RuntimeDelegate {
 public:
  explicit Engine(PlatformView* platform_view);

  ~Engine() override;

  ftl::WeakPtr<Engine> GetWeakPtr();

  static void Init();

  void RunBundle(const std::string& bundle_path);

  // Uses the given snapshot instead of looking inside the bundle for the
  // snapshot. If |snapshot_override| is empty, this function looks for the
  // snapshot in the bundle itself.
  void RunBundleAndSnapshot(const std::string& bundle_path,
                            const std::string& snapshot_override);

  // Uses the given source code instead of looking inside the bindle for the
  // source code.
  void RunBundleAndSource(const std::string& bundle_path,
                          const std::string& main,
                          const std::string& packages);

  void BeginFrame(ftl::TimePoint frame_time);
  void NotifyIdle(int64_t deadline);

  void RunFromSource(const std::string& main,
                     const std::string& packages,
                     const std::string& bundle);

  Dart_Port GetUIIsolateMainPort();
  std::string GetUIIsolateName();
  bool UIIsolateHasLivePorts();
  tonic::DartErrorHandleType GetUIIsolateLastError();
  tonic::DartErrorHandleType GetLoadScriptError();

  void OnOutputSurfaceCreated(const ftl::Closure& gpu_continuation);
  void OnOutputSurfaceDestroyed(const ftl::Closure& gpu_continuation);
  void SetViewportMetrics(const blink::ViewportMetrics& metrics);
  void DispatchPlatformMessage(ftl::RefPtr<blink::PlatformMessage> message);
  void DispatchPointerDataPacket(const PointerDataPacket& packet);
  void DispatchSemanticsAction(int id, blink::SemanticsAction action);
  void SetSemanticsEnabled(bool enabled);

 private:
  // RuntimeDelegate methods:
  std::string DefaultRouteName() override;
  void ScheduleFrame() override;
  void Render(std::unique_ptr<flow::LayerTree> layer_tree) override;
  void UpdateSemantics(std::vector<blink::SemanticsNode> update) override;
  void HandlePlatformMessage(
      ftl::RefPtr<blink::PlatformMessage> message) override;
  void DidCreateMainIsolate(Dart_Isolate isolate) override;
  void DidCreateSecondaryIsolate(Dart_Isolate isolate) override;

  void StopAnimator();
  void StartAnimatorIfPossible();

  void ConfigureAssetBundle(const std::string& path);
  void ConfigureRuntime(const std::string& script_uri,
      const std::vector<uint8_t>& platform_kernel = std::vector<uint8_t>());

  bool HandleLifecyclePlatformMessage(blink::PlatformMessage* message);
  bool HandleNavigationPlatformMessage(
      ftl::RefPtr<blink::PlatformMessage> message);
  bool HandleLocalizationPlatformMessage(
      ftl::RefPtr<blink::PlatformMessage> message);

  void HandleAssetPlatformMessage(ftl::RefPtr<blink::PlatformMessage> message);
  bool GetAssetAsBuffer(const std::string& name, std::vector<uint8_t>* data);

  std::weak_ptr<PlatformView> platform_view_;
  std::unique_ptr<Animator> animator_;
  std::unique_ptr<blink::RuntimeController> runtime_;
  tonic::DartErrorHandleType load_script_error_;
  std::string initial_route_;
  blink::ViewportMetrics viewport_metrics_;
  std::string language_code_;
  std::string country_code_;
  bool semantics_enabled_ = false;
  // TODO(abarth): Unify these two behind a common interface.
  ftl::RefPtr<blink::ZipAssetStore> asset_store_;
  std::unique_ptr<blink::DirectoryAssetBundle> directory_asset_bundle_;
  // TODO(eseidel): This should move into an AnimatorStateMachine.
  bool activity_running_;
  bool have_surface_;
  ftl::WeakPtrFactory<Engine> weak_factory_;

  FTL_DISALLOW_COPY_AND_ASSIGN(Engine);
};

}  // namespace shell

#endif  // SHELL_COMMON_ENGINE_H_
