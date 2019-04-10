// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_COMMON_SHELL_H_
#define SHELL_COMMON_SHELL_H_

#include <functional>
#include <unordered_map>

#include "flutter/common/settings.h"
#include "flutter/common/task_runners.h"
#include "flutter/flow/texture.h"
#include "flutter/fml/closure.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/memory/ref_ptr.h"
#include "flutter/fml/memory/thread_checker.h"
#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/fml/string_view.h"
#include "flutter/fml/synchronization/thread_annotations.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/fml/thread.h"
#include "flutter/lib/ui/semantics/custom_accessibility_action.h"
#include "flutter/lib/ui/semantics/semantics_node.h"
#include "flutter/lib/ui/window/platform_message.h"
#include "flutter/runtime/dart_vm_lifecycle.h"
#include "flutter/runtime/service_protocol.h"
#include "flutter/shell/common/animator.h"
#include "flutter/shell/common/engine.h"
#include "flutter/shell/common/platform_view.h"
#include "flutter/shell/common/rasterizer.h"
#include "flutter/shell/common/shell_io_manager.h"
#include "flutter/shell/common/surface.h"

namespace flutter {

class Shell final : public PlatformView::Delegate,
                    public Animator::Delegate,
                    public Engine::Delegate,
                    public flutter::ServiceProtocol::Handler {
 public:
  template <class T>
  using CreateCallback = std::function<std::unique_ptr<T>(Shell&)>;

  // Create a shell with the given task runners and settings. The isolate
  // snapshot will be shared with the snapshot of the service isolate.
  static std::unique_ptr<Shell> Create(
      flutter::TaskRunners task_runners,
      flutter::Settings settings,
      CreateCallback<PlatformView> on_create_platform_view,
      CreateCallback<Rasterizer> on_create_rasterizer);

  // Creates a shell with the given task runners and settings. The isolate
  // snapshot is specified upfront.
  static std::unique_ptr<Shell> Create(
      flutter::TaskRunners task_runners,
      flutter::Settings settings,
      fml::RefPtr<const flutter::DartSnapshot> isolate_snapshot,
      fml::RefPtr<const flutter::DartSnapshot> shared_snapshot,
      CreateCallback<PlatformView> on_create_platform_view,
      CreateCallback<Rasterizer> on_create_rasterizer,
      flutter::DartVMRef vm);

  ~Shell();

  const flutter::Settings& GetSettings() const;

  const flutter::TaskRunners& GetTaskRunners() const;

  fml::WeakPtr<Rasterizer> GetRasterizer();

  fml::WeakPtr<Engine> GetEngine();

  fml::WeakPtr<PlatformView> GetPlatformView();

  flutter::DartVM* GetDartVM();

  bool IsSetup() const;

  Rasterizer::Screenshot Screenshot(Rasterizer::ScreenshotType type,
                                    bool base64_encode);

 private:
  using ServiceProtocolHandler = std::function<bool(
      const flutter::ServiceProtocol::Handler::ServiceProtocolMap&,
      rapidjson::Document&)>;

  const flutter::TaskRunners task_runners_;
  const flutter::Settings settings_;
  flutter::DartVMRef vm_;
  std::unique_ptr<PlatformView> platform_view_;  // on platform task runner
  std::unique_ptr<Engine> engine_;               // on UI task runner
  std::unique_ptr<Rasterizer> rasterizer_;       // on GPU task runner
  std::unique_ptr<ShellIOManager> io_manager_;   // on IO task runner

  std::unordered_map<std::string,  // method
                     std::pair<fml::RefPtr<fml::TaskRunner>,
                               ServiceProtocolHandler>  // task-runner/function
                                                        // pair
                     >
      service_protocol_handlers_;
  bool is_setup_ = false;
  uint64_t next_pointer_flow_id_ = 0;

  Shell(flutter::TaskRunners task_runners, flutter::Settings settings);
  Shell(flutter::DartVMRef vm,
        flutter::TaskRunners task_runners,
        flutter::Settings settings);

  static std::unique_ptr<Shell> CreateShellOnPlatformThread(
      flutter::DartVMRef vm,
      flutter::TaskRunners task_runners,
      flutter::Settings settings,
      fml::RefPtr<const flutter::DartSnapshot> isolate_snapshot,
      fml::RefPtr<const flutter::DartSnapshot> shared_snapshot,
      Shell::CreateCallback<PlatformView> on_create_platform_view,
      Shell::CreateCallback<Rasterizer> on_create_rasterizer);

  bool Setup(std::unique_ptr<PlatformView> platform_view,
             std::unique_ptr<Engine> engine,
             std::unique_ptr<Rasterizer> rasterizer,
             std::unique_ptr<ShellIOManager> io_manager);

  // |PlatformView::Delegate|
  void OnPlatformViewCreated(std::unique_ptr<Surface> surface) override;

  // |PlatformView::Delegate|
  void OnPlatformViewDestroyed() override;

  // |PlatformView::Delegate|
  void OnPlatformViewSetViewportMetrics(
      const flutter::ViewportMetrics& metrics) override;

  // |PlatformView::Delegate|
  void OnPlatformViewDispatchPlatformMessage(
      fml::RefPtr<flutter::PlatformMessage> message) override;

  // |PlatformView::Delegate|
  void OnPlatformViewDispatchPointerDataPacket(
      std::unique_ptr<flutter::PointerDataPacket> packet) override;

  // |PlatformView::Delegate|
  void OnPlatformViewDispatchSemanticsAction(
      int32_t id,
      flutter::SemanticsAction action,
      std::vector<uint8_t> args) override;

  // |PlatformView::Delegate|
  void OnPlatformViewSetSemanticsEnabled(bool enabled) override;

  // |shell:PlatformView::Delegate|
  void OnPlatformViewSetAccessibilityFeatures(int32_t flags) override;

  // |PlatformView::Delegate|
  void OnPlatformViewRegisterTexture(
      std::shared_ptr<flow::Texture> texture) override;

  // |PlatformView::Delegate|
  void OnPlatformViewUnregisterTexture(int64_t texture_id) override;

  // |PlatformView::Delegate|
  void OnPlatformViewMarkTextureFrameAvailable(int64_t texture_id) override;

  // |PlatformView::Delegate|
  void OnPlatformViewSetNextFrameCallback(fml::closure closure) override;

  // |Animator::Delegate|
  void OnAnimatorBeginFrame(fml::TimePoint frame_time) override;

  // |Animator::Delegate|
  void OnAnimatorNotifyIdle(int64_t deadline) override;

  // |Animator::Delegate|
  void OnAnimatorDraw(
      fml::RefPtr<flutter::Pipeline<flow::LayerTree>> pipeline) override;

  // |Animator::Delegate|
  void OnAnimatorDrawLastLayerTree() override;

  // |Engine::Delegate|
  void OnEngineUpdateSemantics(
      flutter::SemanticsNodeUpdates update,
      flutter::CustomAccessibilityActionUpdates actions) override;

  // |Engine::Delegate|
  void OnEngineHandlePlatformMessage(
      fml::RefPtr<flutter::PlatformMessage> message) override;

  void HandleEngineSkiaMessage(fml::RefPtr<flutter::PlatformMessage> message);

  // |Engine::Delegate|
  void OnPreEngineRestart() override;

  // |Engine::Delegate|
  void UpdateIsolateDescription(const std::string isolate_name,
                                int64_t isolate_port) override;

  // |flutter::ServiceProtocol::Handler|
  fml::RefPtr<fml::TaskRunner> GetServiceProtocolHandlerTaskRunner(
      fml::StringView method) const override;

  // |flutter::ServiceProtocol::Handler|
  bool HandleServiceProtocolMessage(
      fml::StringView method,  // one if the extension names specified above.
      const ServiceProtocolMap& params,
      rapidjson::Document& response) override;

  // |flutter::ServiceProtocol::Handler|
  flutter::ServiceProtocol::Handler::Description GetServiceProtocolDescription()
      const override;

  // Service protocol handler
  bool OnServiceProtocolScreenshot(
      const flutter::ServiceProtocol::Handler::ServiceProtocolMap& params,
      rapidjson::Document& response);

  // Service protocol handler
  bool OnServiceProtocolScreenshotSKP(
      const flutter::ServiceProtocol::Handler::ServiceProtocolMap& params,
      rapidjson::Document& response);

  // Service protocol handler
  bool OnServiceProtocolRunInView(
      const flutter::ServiceProtocol::Handler::ServiceProtocolMap& params,
      rapidjson::Document& response);

  // Service protocol handler
  bool OnServiceProtocolFlushUIThreadTasks(
      const flutter::ServiceProtocol::Handler::ServiceProtocolMap& params,
      rapidjson::Document& response);

  // Service protocol handler
  bool OnServiceProtocolSetAssetBundlePath(
      const flutter::ServiceProtocol::Handler::ServiceProtocolMap& params,
      rapidjson::Document& response);

  // Service protocol handler
  bool OnServiceProtocolGetDisplayRefreshRate(
      const flutter::ServiceProtocol::Handler::ServiceProtocolMap& params,
      rapidjson::Document& response);

  FML_DISALLOW_COPY_AND_ASSIGN(Shell);
};

}  // namespace flutter

#endif  // SHELL_COMMON_SHELL_H_
