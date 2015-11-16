// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/platform/mojo/platform_view_mojo.h"

#include "base/bind.h"
#include "base/location.h"
#include "base/single_thread_task_runner.h"
#include "sky/shell/gpu/mojo/rasterizer_mojo.h"

namespace sky {
namespace shell {

PlatformView* PlatformView::Create(const Config& config) {
  return new PlatformViewMojo(config);
}

PlatformViewMojo::PlatformViewMojo(const Config& config)
  : PlatformView(config), dispatcher_binding_(this) {
}

PlatformViewMojo::~PlatformViewMojo() {
}

void PlatformViewMojo::Init(mojo::ApplicationImpl* app) {
  app->ConnectToService("mojo:native_viewport_service", &viewport_);

  mojo::NativeViewportEventDispatcherPtr ptr;
  dispatcher_binding_.Bind(GetProxy(&ptr));
  viewport_->SetEventDispatcher(ptr.Pass());

  mojo::SizePtr size = mojo::Size::New();
  size->width = 800;
  size->height = 600;

  viewport_->Create(
      size.Clone(),
      mojo::SurfaceConfiguration::New(),
      [this](mojo::ViewportMetricsPtr metrics) {
        OnMetricsChanged(metrics.Pass());
      });
  viewport_->Show();

  mojo::ContextProviderPtr context_provider;
  viewport_->GetContextProvider(GetProxy(&context_provider));

  mojo::InterfacePtrInfo<mojo::ContextProvider> context_provider_info = context_provider.PassInterface();

  RasterizerMojo* rasterizer = static_cast<RasterizerMojo*>(config_.rasterizer);
  config_.ui_task_runner->PostTask(
      FROM_HERE, base::Bind(&UIDelegate::OnOutputSurfaceCreated,
                            config_.ui_delegate,
                            base::Bind(&RasterizerMojo::OnContextProviderAvailable,
                                       rasterizer->GetWeakPtr(), base::Passed(&context_provider_info))));
}

void PlatformViewMojo::Run(const mojo::String& url,
                           mojo::asset_bundle::AssetBundlePtr bundle) {
  ConnectToEngine(mojo::GetProxy(&sky_engine_));
  sky_engine_->RunFromAssetBundle(url, bundle.Pass());
}

void PlatformViewMojo::OnMetricsChanged(mojo::ViewportMetricsPtr metrics) {
  DCHECK(metrics);
  viewport_->RequestMetrics(
      [this](mojo::ViewportMetricsPtr metrics) {
        OnMetricsChanged(metrics.Pass());
      });

  sky::ViewportMetricsPtr sky_metrics = sky::ViewportMetrics::New();
  sky_metrics->physical_width = metrics->size->width;
  sky_metrics->physical_height = metrics->size->height;
  sky_metrics->device_pixel_ratio = metrics->device_pixel_ratio;
  sky_engine_->OnViewportMetricsChanged(sky_metrics.Pass());
}

void PlatformViewMojo::OnEvent(mojo::EventPtr event,
                               const mojo::Callback<void()>& callback) {
  DCHECK(event);
  callback.Run();
}

}  // namespace shell
}  // namespace sky
