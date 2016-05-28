// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/platform/mojo/view_impl.h"

#include "mojo/public/cpp/application/connect.h"
#include "mojo/services/gfx/composition/interfaces/scheduling.mojom.h"
#include "sky/shell/shell.h"

namespace sky {
namespace shell {
namespace {

sky::InputEventPtr ConvertKeyEvent(mojo::EventPtr event) {
  if (!event->key_data || event->key_data->is_char)
    return nullptr;
  sky::InputEventPtr result = sky::InputEvent::New();
  result->time_stamp = event->time_stamp;
  switch (event->action) {
    case mojo::EventType::KEY_PRESSED:
      result->type = sky::EventType::KEY_PRESSED;
      break;
    case mojo::EventType::KEY_RELEASED:
      result->type = sky::EventType::KEY_RELEASED;
      break;
    default:
      return nullptr;
  }
  result->key_data = sky::KeyData::New();
  result->key_data->key_code = static_cast<int>(event->key_data->windows_key_code);
  if (static_cast<int>(event->flags) & static_cast<int>(mojo::EventFlags::SHIFT_DOWN))
    result->key_data->meta_state |= 0x00000001;
  if (static_cast<int>(event->flags) & static_cast<int>(mojo::EventFlags::CONTROL_DOWN))
    result->key_data->meta_state |= 0x00001000;
  if (static_cast<int>(event->flags) & static_cast<int>(mojo::EventFlags::ALT_DOWN))
    result->key_data->meta_state |= 0x00000002;

  return result.Pass();
}

}  // namespace

ViewImpl::ViewImpl(mojo::InterfaceRequest<mojo::ui::ViewOwner> view_owner,
                   ServicesDataPtr services,
                   const std::string& url)
    : binding_(this),
      url_(url),
      listener_binding_(this),
      view_services_binding_(this) {
  DCHECK(services);

  // Once we're done invoking |Shell|, we put it back inside |services| and pass
  // it off.
  mojo::ShellPtr shell = mojo::ShellPtr::Create(services->shell.Pass());

  // Views
  mojo::ConnectToService(
      shell.get(), "mojo:view_manager_service", mojo::GetProxy(&view_manager_));
  mojo::ui::ViewPtr view;
  mojo::ui::ViewListenerPtr view_listener;
  binding_.Bind(mojo::GetProxy(&view_listener));
  view_manager_->CreateView(
      mojo::GetProxy(&view), view_owner.Pass(), view_listener.Pass(), url_);
  view->GetServiceProvider(mojo::GetProxy(&view_service_provider_));

  // Input
  mojo::ConnectToService(view_service_provider_.get(),
                         mojo::GetProxy(&input_connection_));
  mojo::ui::InputListenerPtr listener;
  listener_binding_.Bind(mojo::GetProxy(&listener));
  input_connection_->SetListener(listener.Pass());

  // Compositing
  mojo::gfx::composition::ScenePtr scene;
  view->CreateScene(mojo::GetProxy(&scene));
  scene->GetScheduler(mojo::GetProxy(&services->frame_scheduler));
  services->view = view.Pass();

  // Engine
  shell_view_.reset(new ShellView(Shell::Shared()));
  shell_view_->view()->ConnectToEngine(GetProxy(&engine_));
  mojo::ApplicationConnectorPtr connector;
  shell->CreateApplicationConnector(mojo::GetProxy(&connector));
  platform_view()->InitRasterizer(connector.Pass(), scene.Pass());

  mojo::ServiceProviderPtr view_services;
  view_services_binding_.Bind(mojo::GetProxy(&view_services));

  services->shell = shell.Pass();
  services->view_services = view_services.Pass();
  engine_->SetServices(services.Pass());
}

ViewImpl::~ViewImpl() {
}

void ViewImpl::Run(base::FilePath bundle_path) {
  engine_->RunFromBundle(url_, bundle_path.value());
}

void ViewImpl::OnPropertiesChanged(
    uint32_t scene_version,
    mojo::ui::ViewPropertiesPtr properties,
    const OnPropertiesChangedCallback& callback) {
  auto& display_metrics = properties->display_metrics;
  viewport_metrics_.device_pixel_ratio = display_metrics->device_pixel_ratio;
  auto& size = properties->view_layout->size;
  viewport_metrics_.physical_width = size->width;
  viewport_metrics_.physical_height = size->height;
  viewport_metrics_.scene_version = scene_version;
  engine_->OnViewportMetricsChanged(viewport_metrics_.Clone());
  callback.Run();
}

void ViewImpl::OnEvent(mojo::EventPtr event, const OnEventCallback& callback) {
  DCHECK(event);
  bool consumed = false;
  switch (event->action) {
    case mojo::EventType::POINTER_CANCEL:
    case mojo::EventType::POINTER_DOWN:
    case mojo::EventType::POINTER_MOVE:
    case mojo::EventType::POINTER_UP: {
      auto packet = pointer_converter_.ConvertEvent(event.Pass());
      if (packet) {
        engine_->OnPointerPacket(packet.Pass());
        consumed = true;
      }
      break;
    }
    case mojo::EventType::KEY_PRESSED:
    case mojo::EventType::KEY_RELEASED: {
      auto sky_event = ConvertKeyEvent(event.Pass());
      if (!sky_event)
        break;
      for (auto& listener : raw_keyboard_listeners_)
        listener->OnKey(sky_event.Clone());
      break;
    }
    default:
      break;
  }
  callback.Run(consumed);
}

void ViewImpl::ConnectToService(const mojo::String& service_name,
                                mojo::ScopedMessagePipeHandle handle) {
  if (service_name == raw_keyboard::RawKeyboardService::Name_) {
    raw_keyboard_bindings_.AddBinding(
        this,
        mojo::InterfaceRequest<raw_keyboard::RawKeyboardService>(handle.Pass()));
  }
}

void ViewImpl::AddListener(
    mojo::InterfaceHandle<raw_keyboard::RawKeyboardListener> listener) {
  raw_keyboard_listeners_.push_back(
      raw_keyboard::RawKeyboardListenerPtr::Create(listener.Pass()));
}

}  // namespace shell
}  // namespace sky
