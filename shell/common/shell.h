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
#include "flutter/fml/memory/thread_checker.h"
#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/fml/thread.h"
#include "flutter/lib/ui/semantics/semantics_node.h"
#include "flutter/lib/ui/window/platform_message.h"
#include "flutter/runtime/service_protocol.h"
#include "flutter/shell/common/animator.h"
#include "flutter/shell/common/engine.h"
#include "flutter/shell/common/io_manager.h"
#include "flutter/shell/common/platform_view.h"
#include "flutter/shell/common/rasterizer.h"
#include "flutter/shell/common/surface.h"
#include "lib/fxl/functional/closure.h"
#include "lib/fxl/macros.h"
#include "lib/fxl/memory/ref_ptr.h"
#include "lib/fxl/memory/weak_ptr.h"
#include "lib/fxl/strings/string_view.h"
#include "lib/fxl/synchronization/thread_annotations.h"
#include "lib/fxl/synchronization/thread_checker.h"
#include "lib/fxl/synchronization/waitable_event.h"

namespace shell {

class Shell final : public PlatformView::Delegate,
                    public Animator::Delegate,
                    public Engine::Delegate,
                    public blink::ServiceProtocol::Handler {
 public:
  template <class T>
  using CreateCallback = std::function<std::unique_ptr<T>(Shell&)>;
  static std::unique_ptr<Shell> Create(
      blink::TaskRunners task_runners,
      blink::Settings settings,
      CreateCallback<PlatformView> on_create_platform_view,
      CreateCallback<Rasterizer> on_create_rasterizer);

  ~Shell();

  const blink::Settings& GetSettings() const;

  const blink::TaskRunners& GetTaskRunners() const;

  fml::WeakPtr<Rasterizer> GetRasterizer();

  fml::WeakPtr<Engine> GetEngine();

  fml::WeakPtr<PlatformView> GetPlatformView();

  const blink::DartVM& GetDartVM() const;

  bool IsSetup() const;

  Rasterizer::Screenshot Screenshot(Rasterizer::ScreenshotType type,
                                    bool base64_encode);

 private:
  using ServiceProtocolHandler = std::function<bool(
      const blink::ServiceProtocol::Handler::ServiceProtocolMap&,
      rapidjson::Document&)>;

  const blink::TaskRunners task_runners_;
  const blink::Settings settings_;
  fxl::RefPtr<blink::DartVM> vm_;
  std::unique_ptr<PlatformView> platform_view_;  // on platform task runner
  std::unique_ptr<Engine> engine_;               // on UI task runner
  std::unique_ptr<Rasterizer> rasterizer_;       // on GPU task runner
  std::unique_ptr<IOManager> io_manager_;        // on IO task runner

  std::unordered_map<std::string,  // method
                     std::pair<fxl::RefPtr<fxl::TaskRunner>,
                               ServiceProtocolHandler>  // task-runner/function
                                                        // pair
                     >
      service_protocol_handlers_;
  bool is_setup_ = false;

  Shell(blink::TaskRunners task_runners, blink::Settings settings);

  static std::unique_ptr<Shell> CreateShellOnPlatformThread(
      blink::TaskRunners task_runners,
      blink::Settings settings,
      Shell::CreateCallback<PlatformView> on_create_platform_view,
      Shell::CreateCallback<Rasterizer> on_create_rasterizer);

  bool Setup(std::unique_ptr<PlatformView> platform_view,
             std::unique_ptr<Engine> engine,
             std::unique_ptr<Rasterizer> rasterizer,
             std::unique_ptr<IOManager> io_manager);

  // |shell::PlatformView::Delegate|
  void OnPlatformViewCreated(const PlatformView& view,
                             std::unique_ptr<Surface> surface) override;

  // |shell::PlatformView::Delegate|
  void OnPlatformViewDestroyed(const PlatformView& view) override;

  // |shell::PlatformView::Delegate|
  void OnPlatformViewSetViewportMetrics(
      const PlatformView& view,
      const blink::ViewportMetrics& metrics) override;

  // |shell::PlatformView::Delegate|
  void OnPlatformViewDispatchPlatformMessage(
      const PlatformView& view,
      fxl::RefPtr<blink::PlatformMessage> message) override;

  // |shell::PlatformView::Delegate|
  void OnPlatformViewDispatchPointerDataPacket(
      const PlatformView& view,
      std::unique_ptr<blink::PointerDataPacket> packet) override;

  // |shell::PlatformView::Delegate|
  void OnPlatformViewDispatchSemanticsAction(
      const PlatformView& view,
      int32_t id,
      blink::SemanticsAction action,
      std::vector<uint8_t> args) override;

  // |shell::PlatformView::Delegate|
  void OnPlatformViewSetSemanticsEnabled(const PlatformView& view,
                                         bool enabled) override;

  // |shell::PlatformView::Delegate|
  void OnPlatformViewRegisterTexture(
      const PlatformView& view,
      std::shared_ptr<flow::Texture> texture) override;

  // |shell::PlatformView::Delegate|
  void OnPlatformViewUnregisterTexture(const PlatformView& view,
                                       int64_t texture_id) override;

  // |shell::PlatformView::Delegate|
  void OnPlatformViewMarkTextureFrameAvailable(const PlatformView& view,
                                               int64_t texture_id) override;

  // |shell::PlatformView::Delegate|
  void OnPlatformViewSetNextFrameCallback(const PlatformView& view,
                                          fxl::Closure closure) override;

  // |shell::Animator::Delegate|
  void OnAnimatorBeginFrame(const Animator& animator,
                            fxl::TimePoint frame_time) override;

  // |shell::Animator::Delegate|
  void OnAnimatorNotifyIdle(const Animator& animator,
                            int64_t deadline) override;

  // |shell::Animator::Delegate|
  void OnAnimatorDraw(
      const Animator& animator,
      fxl::RefPtr<flutter::Pipeline<flow::LayerTree>> pipeline) override;

  // |shell::Animator::Delegate|
  void OnAnimatorDrawLastLayerTree(const Animator& animator) override;

  // |shell::Engine::Delegate|
  void OnEngineUpdateSemantics(const Engine& engine,
                               blink::SemanticsNodeUpdates update) override;

  // |shell::Engine::Delegate|
  void OnEngineHandlePlatformMessage(
      const Engine& engine,
      fxl::RefPtr<blink::PlatformMessage> message) override;

  // |blink::ServiceProtocol::Handler|
  fxl::RefPtr<fxl::TaskRunner> GetServiceProtocolHandlerTaskRunner(
      fxl::StringView method) const override;

  // |blink::ServiceProtocol::Handler|
  bool HandleServiceProtocolMessage(
      fxl::StringView method,  // one if the extension names specified above.
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

  FXL_DISALLOW_COPY_AND_ASSIGN(Shell);
};

}  // namespace shell

#endif  // SHELL_COMMON_SHELL_H_
