// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_CONTENT_HANDLER_RUNTIME_HOLDER_H_
#define FLUTTER_CONTENT_HANDLER_RUNTIME_HOLDER_H_

#include "flutter/assets/unzipper_provider.h"
#include "flutter/assets/zip_asset_store.h"
#include "flutter/flow/layers/layer_tree.h"
#include "flutter/runtime/runtime_controller.h"
#include "flutter/runtime/runtime_delegate.h"
#include "flutter/services/engine/sky_engine.mojom.h"
#include "lib/ftl/functional/closure.h"
#include "lib/ftl/macros.h"
#include "lib/ftl/memory/weak_ptr.h"
#include "mojo/public/interfaces/application/application_connector.mojom.h"
#include "mojo/services/asset_bundle/interfaces/asset_bundle.mojom.h"
#include "mojo/services/framebuffer/interfaces/framebuffer.mojom.h"

namespace flutter_content_handler {
class Rasterizer;

class RuntimeHolder : public blink::RuntimeDelegate {
 public:
  RuntimeHolder();
  ~RuntimeHolder();

  void Init(mojo::ApplicationConnectorPtr connector);
  void Run(const std::string& script_uri, std::vector<char> bundle);

 private:
  // |blink::RuntimeDelegate| implementation:
  void ScheduleFrame() override;
  void Render(std::unique_ptr<flow::LayerTree> layer_tree) override;
  void DidCreateMainIsolate(Dart_Isolate isolate) override;

  ftl::WeakPtr<RuntimeHolder> GetWeakPtr();

  void InitRootBundle(std::vector<char> bundle);
  blink::UnzipperProvider GetUnzipperProviderForRootBundle();

  void DidCreateFramebuffer(
      mojo::InterfaceHandle<mojo::Framebuffer> framebuffer,
      mojo::FramebufferInfoPtr info);

  void ScheduleDelayedFrame();
  void BeginFrame();
  void OnFrameComplete();

  std::vector<char> root_bundle_data_;
  ftl::RefPtr<blink::ZipAssetStore> asset_store_;
  mojo::asset_bundle::AssetBundlePtr root_bundle_;

  mojo::FramebufferProviderPtr framebuffer_provider_;
  std::unique_ptr<Rasterizer> rasterizer_;
  std::unique_ptr<blink::RuntimeController> runtime_;
  sky::ViewportMetricsPtr viewport_metrics_;

  bool runtime_requested_frame_ = false;
  bool did_defer_frame_request_ = false;
  bool is_ready_to_draw_ = false;
  int outstanding_requests_ = 0;

  ftl::WeakPtrFactory<RuntimeHolder> weak_factory_;

  FTL_DISALLOW_COPY_AND_ASSIGN(RuntimeHolder);
};

}  // namespace flutter_content_handler

#endif  // FLUTTER_CONTENT_HANDLER_RUNTIME_HOLDER_H_
