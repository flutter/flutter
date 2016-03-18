// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/platform/mojo/view_impl.h"

#include "mojo/public/cpp/application/connect.h"
#include "mojo/services/gfx/composition/interfaces/scheduling.mojom.h"
#include "sky/shell/shell.h"

namespace sky {
namespace shell {

ViewImpl::ViewImpl(mojo::InterfaceRequest<mojo::ui::ViewOwner> view_owner,
                   ServicesDataPtr services,
                   const std::string& url)
    : binding_(this), url_(url), listener_binding_(this) {
  DCHECK(services);

  // Once we're done invoking |Shell|, we put it back inside |services| and pass
  // it off.
  mojo::ShellPtr shell = mojo::ShellPtr::Create(services->shell.Pass());

  // Views
  mojo::ConnectToService(
      shell.get(), "mojo:view_manager_service", &view_manager_);
  mojo::ui::ViewPtr view;
  mojo::ui::ViewListenerPtr view_listener;
  binding_.Bind(mojo::GetProxy(&view_listener));
  view_manager_->CreateView(
      mojo::GetProxy(&view), view_owner.Pass(), view_listener.Pass(), url_);
  view->GetServiceProvider(mojo::GetProxy(&view_service_provider_));

  // Input
  mojo::ConnectToService(view_service_provider_.get(), &input_connection_);
  mojo::ui::InputListenerPtr listener;
  listener_binding_.Bind(mojo::GetProxy(&listener));
  input_connection_->SetListener(listener.Pass());

  // Compositing
  mojo::gfx::composition::ScenePtr scene;
  view->CreateScene(mojo::GetProxy(&scene));
  scene->GetScheduler(mojo::GetProxy(&services->scene_scheduler));
  services->view = view.Pass();

  // Engine
  shell_view_.reset(new ShellView(Shell::Shared()));
  shell_view_->view()->ConnectToEngine(GetProxy(&engine_));
  mojo::ApplicationConnectorPtr connector;
  shell->CreateApplicationConnector(mojo::GetProxy(&connector));
  platform_view()->InitRasterizer(connector.Pass(), scene.Pass());

  services->shell = shell.Pass();
  engine_->SetServices(services.Pass());
}

ViewImpl::~ViewImpl() {
}

void ViewImpl::Run(base::FilePath bundle_path) {
  engine_->RunFromBundle(url_, bundle_path.value());
}

void ViewImpl::OnLayout(mojo::ui::ViewLayoutParamsPtr layout_params,
                        mojo::Array<uint32_t> children_needing_layout,
                        const OnLayoutCallback& callback) {
  viewport_metrics_.device_pixel_ratio = layout_params->device_pixel_ratio;
  viewport_metrics_.physical_width = layout_params->constraints->max_width;
  viewport_metrics_.physical_height = layout_params->constraints->max_height;
  engine_->OnViewportMetricsChanged(viewport_metrics_.Clone());

  auto info = mojo::ui::ViewLayoutResult::New();
  info->size = mojo::Size::New();
  info->size->width = viewport_metrics_.physical_width;
  info->size->height = viewport_metrics_.physical_height;
  callback.Run(info.Pass());
}

void ViewImpl::OnChildUnavailable(uint32_t child_key,
                                  const OnChildUnavailableCallback& callback) {
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
    default:
      break;
  }
  callback.Run(consumed);
}

}  // namespace shell
}  // namespace sky
