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

  // Grab the application connector so that we can connect to services later
  shell->CreateApplicationConnector(GetProxy(&connector_));

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

  ConnectToEngine(GetProxy(&sky_engine_));

}

void PlatformViewMojo::Run(const mojo::String& url,
                           ServicesDataPtr services,
                           mojo::asset_bundle::AssetBundlePtr bundle) {

  mojo::ServiceProviderPtr services_provided_by_embedder;
  service_provider_.Bind(GetProxy(&services_provided_by_embedder));
  service_provider_.AddService<keyboard::KeyboardService>(this);
  services->services_provided_by_embedder = services_provided_by_embedder.Pass();

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
      pointer::PointerPacketPtr packet;
      int packetIndex = 0;
      if (pointer_positions_.count(data->pointer_id) > 0) {
        if (event->action == mojo::EventType::POINTER_UP ||
            event->action == mojo::EventType::POINTER_CANCEL) {
          std::pair<float, float> last_position = pointer_positions_[data->pointer_id];
          if (last_position.first != data->x || last_position.second != data->y) {
            packet = pointer::PointerPacket::New();
            packet->pointers = mojo::Array<pointer::PointerPtr>::New(2);
            packet->pointers[packetIndex] = CreateEvent(pointer::PointerType::MOVE, event.get(), data.get());
            packetIndex += 1;
          }
          pointer_positions_.erase(data->pointer_id);
        }
      } else {
        // We don't currently support hover moves.
        // If we want to support those, we have to first implement
        // added/removed events for pointers.
        // See: https://github.com/flutter/flutter/issues/720
        if (event->action != mojo::EventType::POINTER_DOWN)
          break;
      }
      if (packetIndex == 0) {
        packet = pointer::PointerPacket::New();
        packet->pointers = mojo::Array<pointer::PointerPtr>::New(1);
      }
      packet->pointers[packetIndex] = CreateEvent(GetTypeFromAction(event->action), event.get(), data.get());
      sky_engine_->OnPointerPacket(packet.Pass());
      break;
    }
    case mojo::EventType::KEY_PRESSED:
    case mojo::EventType::KEY_RELEASED:
      if (key_event_dispatcher_) {
        key_event_dispatcher_->OnEvent(event.Pass(), callback);
        return; // key_event_dispatcher_ will invoke callback
      }
    default:
      break;
  }

  callback.Run();
}

pointer::PointerPtr PlatformViewMojo::CreateEvent(pointer::PointerType type, mojo::Event* event, mojo::PointerData* data) {
  DCHECK(data);
  pointer::PointerPtr pointer = pointer::Pointer::New();
  pointer->time_stamp = event->time_stamp;
  pointer->pointer = data->pointer_id;
  pointer->type = type;
  pointer->kind = GetKindFromKind(data->kind);
  pointer->x = data->x;
  pointer->y = data->y;
  pointer->buttons = static_cast<int32_t>(event->flags);
  pointer->pressure = data->pressure;
  pointer->radius_major = data->radius_major;
  pointer->radius_minor = data->radius_minor;
  pointer->orientation = data->orientation;
  if (event->action != mojo::EventType::POINTER_UP &&
      event->action != mojo::EventType::POINTER_CANCEL)
    pointer_positions_[data->pointer_id] = { data->x, data->y };
  return pointer.Pass();
}

void PlatformViewMojo::Create(
    mojo::ApplicationConnection* connection,
    mojo::InterfaceRequest<keyboard::KeyboardService> request) {

  mojo::ServiceProviderPtr keyboard_service_provider;
  connector_->ConnectToApplication(
    "mojo:keyboard",
    GetProxy(&keyboard_service_provider),
    nullptr);

#if defined(OS_LINUX)
  keyboard::KeyboardServiceFactoryPtr factory;
  mojo::ConnectToService(keyboard_service_provider.get(), &factory);
  factory->CreateKeyboardService(GetProxy(&key_event_dispatcher_), request.Pass());
#else
  keyboard_service_provider->ConnectToService(
    keyboard::KeyboardService::Name_,
    request.PassMessagePipe());
#endif
}

}  // namespace shell
}  // namespace sky
