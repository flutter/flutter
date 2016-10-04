// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_CONTENT_HANDLER_RUNTIME_HOLDER_H_
#define FLUTTER_CONTENT_HANDLER_RUNTIME_HOLDER_H_

#include "apps/mozart/services/views/interfaces/view_manager.mojom.h"
#include "flutter/assets/unzipper_provider.h"
#include "flutter/assets/zip_asset_store.h"
#include "flutter/flow/layers/layer_tree.h"
#include "flutter/runtime/runtime_controller.h"
#include "flutter/runtime/runtime_delegate.h"
#include "flutter/services/engine/sky_engine.mojom.h"
#include "lib/ftl/functional/closure.h"
#include "lib/ftl/macros.h"
#include "lib/ftl/memory/weak_ptr.h"
#include "mojo/public/cpp/bindings/binding.h"
#include "mojo/public/interfaces/application/application_connector.mojom.h"
#include "mojo/services/asset_bundle/interfaces/asset_bundle.mojom.h"

namespace flutter_content_handler {
class Rasterizer;

class RuntimeHolder : public blink::RuntimeDelegate, mozart::ViewListener {
 public:
  RuntimeHolder();
  ~RuntimeHolder();

  void Init(mojo::ApplicationConnectorPtr connector, std::vector<char> bundle);
  void CreateView(const std::string& script_uri,
                  mojo::InterfaceRequest<mozart::ViewOwner> view_owner_request,
                  mojo::InterfaceRequest<mojo::ServiceProvider> services);

 private:
  // |blink::RuntimeDelegate| implementation:
  void ScheduleFrame() override;
  void Render(std::unique_ptr<flow::LayerTree> layer_tree) override;
  void DidCreateMainIsolate(Dart_Isolate isolate) override;

  // |mozart::ViewListener| implementation:
  void OnInvalidation(mozart::ViewInvalidationPtr invalidation,
                      const OnInvalidationCallback& callback) override;

  ftl::WeakPtr<RuntimeHolder> GetWeakPtr();

  void InitRootBundle(std::vector<char> bundle);
  blink::UnzipperProvider GetUnzipperProviderForRootBundle();

  void BeginFrame();
  void OnFrameComplete();
  void Invalidate();

  std::vector<char> root_bundle_data_;
  ftl::RefPtr<blink::ZipAssetStore> asset_store_;
  mojo::asset_bundle::AssetBundlePtr root_bundle_;

  std::unique_ptr<Rasterizer> rasterizer_;
  std::unique_ptr<blink::RuntimeController> runtime_;
  sky::ViewportMetricsPtr viewport_metrics_;

  mozart::ViewManagerPtr view_manager_;
  mojo::Binding<mozart::ViewListener> view_listener_binding_;
  mozart::ViewPtr view_;
  mozart::ViewPropertiesPtr view_properties_;
  uint32_t scene_version_ = mozart::kSceneVersionNone;

  bool pending_invalidation_ = false;
  OnInvalidationCallback deferred_invalidation_callback_;
  bool is_ready_to_draw_ = false;
  int outstanding_requests_ = 0;

  ftl::WeakPtrFactory<RuntimeHolder> weak_factory_;

  FTL_DISALLOW_COPY_AND_ASSIGN(RuntimeHolder);
};

}  // namespace flutter_content_handler

#endif  // FLUTTER_CONTENT_HANDLER_RUNTIME_HOLDER_H_
