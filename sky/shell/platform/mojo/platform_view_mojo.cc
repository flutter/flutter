// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/platform/mojo/platform_view_mojo.h"

#include "base/bind.h"
#include "base/location.h"
#include "base/single_thread_task_runner.h"
#include "mojo/public/cpp/application/connect.h"
#include "sky/shell/gpu/mojo/rasterizer_mojo.h"

namespace sky {
namespace shell {
namespace {

pointer::PointerType GetTypeFromAction(mojo::EventType type) {
  switch (type) {
    case mojo::EventType::POINTER_CANCEL:
      return pointer::PointerType::CANCEL;
    case mojo::EventType::POINTER_DOWN:
      return pointer::PointerType::DOWN;
    case mojo::EventType::POINTER_MOVE:
      return pointer::PointerType::MOVE;
    case mojo::EventType::POINTER_UP:
      return pointer::PointerType::UP;
    default:
      DCHECK(false);
      return pointer::PointerType::CANCEL;
  }
}

pointer::PointerKind GetKindFromKind(mojo::PointerKind kind) {
  switch (kind) {
    case mojo::PointerKind::TOUCH:
      return pointer::PointerKind::TOUCH;
    case mojo::PointerKind::MOUSE:
      return pointer::PointerKind::MOUSE;
  }
  DCHECK(false);
  return pointer::PointerKind::TOUCH;
}

}  // namespace

PlatformView* PlatformView::Create(const Config& config) {
  return new PlatformViewMojo(config);
}

PlatformViewMojo::PlatformViewMojo(const Config& config)
  : PlatformView(config), dispatcher_binding_(this) {
}

PlatformViewMojo::~PlatformViewMojo() {
}

void PlatformViewMojo::Init(mojo::Shell* shell) {
  mojo::ConnectToService(shell, "mojo:native_viewport_service", &viewport_);

  mojo::NativeViewportEventDispatcherPtr ptr;
  dispatcher_binding_.Bind(GetProxy(&ptr));
  viewport_->SetEventDispatcher(ptr.Pass());

  mojo::SizePtr size = mojo::Size::New();
  size->width = 320;
  size->height = 640;

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

  ConnectToEngine(mojo::GetProxy(&sky_engine_));

}

void PlatformViewMojo::Run(const mojo::String& url,
                           ServicesDataPtr services,
                           mojo::asset_bundle::AssetBundlePtr bundle) {
  sky_engine_->SetServices(services.Pass());
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
  switch (event->action) {
    case mojo::EventType::POINTER_CANCEL:
    case mojo::EventType::POINTER_DOWN:
    case mojo::EventType::POINTER_MOVE:
    case mojo::EventType::POINTER_UP: {
      mojo::PointerDataPtr data = event->pointer_data.Pass();
      if (!data)
        break;
      pointer::PointerPtr pointer = pointer::Pointer::New();
      pointer->time_stamp = event->time_stamp;
      pointer->pointer = data->pointer_id;
      pointer->type = GetTypeFromAction(event->action);
      pointer->kind = GetKindFromKind(data->kind);
      pointer->x = data->x;
      pointer->y = data->y;
      pointer->buttons = static_cast<int32_t>(event->flags);
      pointer->pressure = data->pressure;
      pointer->radius_major = data->radius_major;
      pointer->radius_minor = data->radius_minor;
      pointer->orientation = data->orientation;

      pointer::PointerPacketPtr packet = pointer::PointerPacket::New();
      packet->pointers = mojo::Array<pointer::PointerPtr>::New(1);
      packet->pointers[0] = pointer.Pass();
      sky_engine_->OnPointerPacket(packet.Pass());
      break;
    }
    default:
      break;
  }

  callback.Run();
}

}  // namespace shell
}  // namespace sky
