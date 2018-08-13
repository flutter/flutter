// Copyright 2015 The Chromium Authors. All rights reserved.
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
#include "flutter/runtime/service_protocol.h"
#include "flutter/shell/common/animator.h"
#include "flutter/shell/common/engine.h"
#include "flutter/shell/common/io_manager.h"
#include "flutter/shell/common/platform_view.h"
#include "flutter/shell/common/rasterizer.h"
#include "flutter/shell/common/surface.h"

namespace shell {

class Shell final : public PlatformView::Delegate,
                    public Animator::Delegate,
                    public Engine::Delegate,
                    public blink::ServiceProtocol::Handler {
 public:
  template <class T>
  using CreateCallback = std::function<std::unique_ptr<T>(Shell&)>;

  // Create a shell with the given task runners and settings. The isolate
  // snapshot will be shared with the snapshot of the service isolate.
  static std::unique_ptr<Shell> Create(
      blink::TaskRunners task_runners,
      blink::Settings settings,
      CreateCallback<PlatformView> on_create_platform_view,
      CreateCallback<Rasterizer> on_create_rasterizer);

  // Creates a shell with the given task runners and settings. The isolate
  // snapshot is specified upfront.
  static std::unique_ptr<Shell> Create(
      blink::TaskRunners task_runners,
      blink::Settings settings,
      fml::RefPtr<blink::DartSnapshot> isolate_snapshot,
      fml::RefPtr<blink::DartSnapshot> shared_snapshot,
      CreateCallback<PlatformView> on_create_platform_view,
      CreateCallback<Rasterizer> on_create_rasterizer);

  ~Shell();

  const blink::Settings& GetSettings() const;

  const blink::TaskRunners& GetTaskRunners() const;

  fml::WeakPtr<Rasterizer> GetRasterizer();

  fml::WeakPtr<Engine> GetEngine();

  fml::WeakPtr<PlatformView> GetPlatformView();

  blink::DartVM& GetDartVM() const;

  bool IsSetup() const;

  Rasterizer::Screenshot Screenshot(Rasterizer::ScreenshotType type,
                                    bool base64_encode);

 private:
  using ServiceProtocolHandler = std::function<bool(
      const blink::ServiceProtocol::Handler::ServiceProtocolMap&,
      rapidjson::Document&)>;

  const blink::TaskRunners task_runners_;
  const blink::Settings settings_;
  fml::RefPtr<blink::DartVM> vm_;
  std::unique_ptr<PlatformView> platform_view_;  // on platform task runner
  std::unique_ptr<Engine> engine_;               // on UI task runner
  std::unique_ptr<Rasterizer> rasterizer_;       // on GPU task runner
  std::unique_ptr<IOManager> io_manager_;        // on IO task runner

  std::unordered_map<std::string,  // method
                     std::pair<fml::RefPtr<fml::TaskRunner>,
                               ServiceProtocolHandler>  // task-runner/function
                                                        // pair
                     >
      service_protocol_handlers_;
  bool is_setup_ = false;

  Shell(blink::TaskRunners task_runners, blink::Settings settings);

  static std::unique_ptr<Shell> CreateShellOnPlatformThread(
      blink::TaskRunners task_runners,
      blink::Settings settings,
      fml::RefPtr<blink::DartSnapshot> isolate_snapshot,
      fml::RefPtr<blink::DartSnapshot> shared_snapshot,
      Shell::CreateCallback<PlatformView> on_create_platform_view,
      Shell::CreateCallback<Rasterizer> on_create_rasterizer);

  bool Setup(std::unique_ptr<PlatformView> platform_view,
             std::unique_ptr<Engine> engine,
             std::unique_ptr<Rasterizer> rasterizer,
             std::unique_ptr<IOManager> io_manager);

  // |shell::PlatformView::Delegate|
  void OnPlatformViewCreated(std::unique_ptr<Surface> surface) override;

  // |shell::PlatformView::Delegate|
  void OnPlatformViewDestroyed() override;

  // |shell::PlatformView::Delegate|
  void OnPlatformViewSetViewportMetrics(
      const blink::ViewportMetrics& metrics) override;

  // |shell::PlatformView::Delegate|
  void OnPlatformViewDispatchPlatformMessage(
      fml::RefPtr<blink::PlatformMessage> message) override;

  // |shell::PlatformView::Delegate|
  void OnPlatformViewDispatchPointerDataPacket(
      std::unique_ptr<blink::PointerDataPacket> packet) override;

  // |shell::PlatformView::Delegate|
  void OnPlatformViewDispatchSemanticsAction(
      int32_t id,
      blink::SemanticsAction action,
      std::vector<uint8_t> args) override;

  // |shell::PlatformView::Delegate|
  void OnPlatformViewSetSemanticsEnabled(bool enabled) override;

  // |shell:PlatformView::Delegate|
  void OnPlatformViewSetAccessibilityFeatures(int32_t flags) override;

  // |shell::PlatformView::Delegate|
  void OnPlatformViewRegisterTexture(
      std::shared_ptr<flow::Texture> texture) override;

  // |shell::PlatformView::Delegate|
  void OnPlatformViewUnregisterTexture(int64_t texture_id) override;

  // |shell::PlatformView::Delegate|
  void OnPlatformViewMarkTextureFrameAvailable(int64_t texture_id) override;

  // |shell::PlatformView::Delegate|
  void OnPlatformViewSetNextFrameCallback(fml::closure closure) override;

  // |shell::Animator::Delegate|
  void OnAnimatorBeginFrame(fml::TimePoint frame_time) override;

  // |shell::Animator::Delegate|
  void OnAnimatorNotifyIdle(int64_t deadline) override;

  // |shell::Animator::Delegate|
  void OnAnimatorDraw(
      fml::RefPtr<flutter::Pipeline<flow::LayerTree>> pipeline) override;

  // |shell::Animator::Delegate|
  void OnAnimatorDrawLastLayerTree() override;

  // |shell::Engine::Delegate|
  void OnEngineUpdateSemantics(
      blink::SemanticsNodeUpdates update,
      blink::CustomAccessibilityActionUpdates actions) override;

  // |shell::Engine::Delegate|
  void OnEngineHandlePlatformMessage(
      fml::RefPtr<blink::PlatformMessage> message) override;

  // |shell::Engine::Delegate|
  void OnPreEngineRestart() override;

  // |blink::ServiceProtocol::Handler|
  fml::RefPtr<fml::TaskRunner> GetServiceProtocolHandlerTaskRunner(
      fml::StringView method) const override;

  // |blink::ServiceProtocol::Handler|
  bool HandleServiceProtocolMessage(
      fml::StringView method,  // one if the extension names specified above.
      const ServiceProtocolMap& params,
      rapidjson::Document& response) override;

  // |blink::ServiceProtocol::Handler|
  blink::ServiceProtocol::Handler::Description GetServiceProtocolDescription()
      const override;

  // Service protocol handler
  bool OnServiceProtocolScreenshot(
      const blink::ServiceProtocol::Handler::ServiceProtocolMap& params,
      rapidjson::Document& response);

  // Service protocol handler
  bool OnServiceProtocolScreenshotSKP(
      const blink::ServiceProtocol::Handler::ServiceProtocolMap& params,
      rapidjson::Document& response);

  // Service protocol handler
  bool OnServiceProtocolRunInView(
      const blink::ServiceProtocol::Handler::ServiceProtocolMap& params,
      rapidjson::Document& response);

  // Service protocol handler
  bool OnServiceProtocolFlushUIThreadTasks(
      const blink::ServiceProtocol::Handler::ServiceProtocolMap& params,
      rapidjson::Document& response);

  // Service protocol handler
  bool OnServiceProtocolSetAssetBundlePath(
      const blink::ServiceProtocol::Handler::ServiceProtocolMap& params,
      rapidjson::Document& response);

  FML_DISALLOW_COPY_AND_ASSIGN(Shell);
};

}  // namespace shell

#endif  // SHELL_COMMON_SHELL_H_
