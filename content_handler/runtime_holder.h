// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_CONTENT_HANDLER_RUNTIME_HOLDER_H_
#define FLUTTER_CONTENT_HANDLER_RUNTIME_HOLDER_H_

#include <mx/channel.h>

#include <unordered_set>

#include "application/services/application_environment.fidl.h"
#include "application/services/service_provider.fidl.h"
#include "apps/mozart/services/input/input_connection.fidl.h"
#include "apps/mozart/services/views/view_manager.fidl.h"
#include "flutter/assets/unzipper_provider.h"
#include "flutter/assets/zip_asset_store.h"
#include "flutter/flow/layers/layer_tree.h"
#include "flutter/lib/ui/window/viewport_metrics.h"
#include "flutter/runtime/runtime_controller.h"
#include "flutter/runtime/runtime_delegate.h"
#include "lib/fidl/cpp/bindings/binding.h"
#include "lib/ftl/functional/closure.h"
#include "lib/ftl/macros.h"
#include "lib/ftl/memory/weak_ptr.h"

#if FLUTTER_ENABLE_VULKAN && FLUTTER_USE_VULKAN_NATIVE_SURFACE
#include "flutter/content_handler/direct_input.h"
#endif  // FLUTTER_ENABLE_VULKAN && FLUTTER_USE_VULKAN_NATIVE_SURFACE

namespace flutter_runner {
class Rasterizer;

class RuntimeHolder : public blink::RuntimeDelegate,
                      public mozart::ViewListener,
                      public mozart::InputListener {
 public:
  RuntimeHolder();
  ~RuntimeHolder();

  void Init(fidl::InterfaceHandle<app::ApplicationEnvironment> environment,
            fidl::InterfaceRequest<app::ServiceProvider> outgoing_services,
            std::vector<char> bundle);
  void CreateView(const std::string& script_uri,
                  fidl::InterfaceRequest<mozart::ViewOwner> view_owner_request,
                  fidl::InterfaceRequest<app::ServiceProvider> services);

  Dart_Port GetUIIsolateMainPort();
  std::string GetUIIsolateName();

 private:
  // |blink::RuntimeDelegate| implementation:
  void ScheduleFrame() override;
  void Render(std::unique_ptr<flow::LayerTree> layer_tree) override;
  void UpdateSemantics(std::vector<blink::SemanticsNode> update) override;
  void HandlePlatformMessage(
      ftl::RefPtr<blink::PlatformMessage> message) override;
  void DidCreateMainIsolate(Dart_Isolate isolate) override;

  // |mozart::InputListener| implementation:
  void OnEvent(mozart::InputEventPtr event,
               const OnEventCallback& callback) override;

  // |mozart::ViewListener| implementation:
  void OnInvalidation(mozart::ViewInvalidationPtr invalidation,
                      const OnInvalidationCallback& callback) override;

  ftl::WeakPtr<RuntimeHolder> GetWeakPtr();

  void InitRootBundle(std::vector<char> bundle);
  blink::UnzipperProvider GetUnzipperProviderForRootBundle();
  void HandleAssetPlatformMessage(ftl::RefPtr<blink::PlatformMessage> message);

  void InitFidlInternal();
  void InitMozartInternal();

  void BeginFrame();
  void OnFrameComplete();
  void Invalidate();

  app::ApplicationEnvironmentPtr environment_;
  app::ServiceProviderPtr environment_services_;
  fidl::InterfaceRequest<app::ServiceProvider> outgoing_services_;

  std::vector<char> root_bundle_data_;
  ftl::RefPtr<blink::ZipAssetStore> asset_store_;
  void* dylib_handle_ = nullptr;

  std::unique_ptr<Rasterizer> rasterizer_;
  std::unique_ptr<blink::RuntimeController> runtime_;
  blink::ViewportMetrics viewport_metrics_;

  mozart::ViewManagerPtr view_manager_;
  fidl::Binding<mozart::ViewListener> view_listener_binding_;
  fidl::Binding<mozart::InputListener> input_listener_binding_;
#if FLUTTER_ENABLE_VULKAN && FLUTTER_USE_VULKAN_NATIVE_SURFACE
  std::unique_ptr<DirectInput> direct_input_;
#endif  // FLUTTER_ENABLE_VULKAN && FLUTTER_USE_VULKAN_NATIVE_SURFACE
  mozart::InputConnectionPtr input_connection_;
  mozart::ViewPtr view_;
  mozart::ViewPropertiesPtr view_properties_;
  uint32_t scene_version_ = mozart::kSceneVersionNone;

  std::unordered_set<int> down_pointers_;

  bool pending_invalidation_ = false;
  OnInvalidationCallback deferred_invalidation_callback_;
  bool is_ready_to_draw_ = false;
  int outstanding_requests_ = 0;

  ftl::WeakPtrFactory<RuntimeHolder> weak_factory_;

  FTL_DISALLOW_COPY_AND_ASSIGN(RuntimeHolder);
};

}  // namespace flutter_runner

#endif  // FLUTTER_CONTENT_HANDLER_RUNTIME_HOLDER_H_
