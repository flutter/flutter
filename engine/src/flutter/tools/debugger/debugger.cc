// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/tools/debugger/debugger.h"

#include "services/window_manager/basic_focus_rules.h"

namespace sky {
namespace debugger {

SkyDebugger::SkyDebugger()
    : window_manager_app_(new window_manager::WindowManagerApp(this, this)),
      root_(nullptr),
      content_(nullptr),
      navigator_host_factory_(this),
      weak_factory_(this) {
}

SkyDebugger::~SkyDebugger() {
}

base::WeakPtr<SkyDebugger> SkyDebugger::GetWeakPtr() {
  return weak_factory_.GetWeakPtr();
}

void SkyDebugger::Initialize(mojo::ApplicationImpl* app) {
  window_manager_app_->Initialize(app);
  app->ConnectToApplication("mojo:sky_debugger_prompt");
}

bool SkyDebugger::ConfigureIncomingConnection(
    mojo::ApplicationConnection* connection) {
  window_manager_app_->ConfigureIncomingConnection(connection);
  connection->AddService(this);
  return true;
}

bool SkyDebugger::ConfigureOutgoingConnection(
    mojo::ApplicationConnection* connection) {
  window_manager_app_->ConfigureOutgoingConnection(connection);
  connection->AddService(this);
  return true;
}

void SkyDebugger::OnEmbed(
    mojo::View* root,
    mojo::ServiceProviderImpl* exported_services,
    scoped_ptr<mojo::ServiceProvider> imported_services) {
  root_ = root;
  root_->AddObserver(this);

  window_manager_app_->SetViewportSize(gfx::Size(320, 640));

  content_ = root->view_manager()->CreateView();
  content_->SetBounds(root_->bounds());
  root_->AddChild(content_);
  content_->SetVisible(true);

  window_manager_app_->InitFocus(
      make_scoped_ptr(new window_manager::BasicFocusRules(root_)));

  if (!pending_url_.empty())
    NavigateToURL(pending_url_);
}

void SkyDebugger::Embed(
    const mojo::String& url,
    mojo::InterfaceRequest<mojo::ServiceProvider> service_provider) {
  scoped_ptr<mojo::ServiceProviderImpl> exported_services(
      new mojo::ServiceProviderImpl());
  // exported_services->AddService(TBD) -- no exported services for now.
  content_->Embed(url, exported_services.Pass());
}

void SkyDebugger::OnViewManagerDisconnected(mojo::ViewManager* view_manager) {
  root_ = nullptr;
}

void SkyDebugger::OnViewDestroyed(mojo::View* view) {
  view->RemoveObserver(this);
}

void SkyDebugger::OnViewBoundsChanged(mojo::View* view,
                                      const mojo::Rect& old_bounds,
                                      const mojo::Rect& new_bounds) {
  content_->SetBounds(new_bounds);
}

void SkyDebugger::Create(mojo::ApplicationConnection* connection,
                         mojo::InterfaceRequest<Debugger> request) {
  mojo::WeakBindToRequest(this, &request);
}

void SkyDebugger::NavigateToURL(const mojo::String& url) {
  // We can get Navigate commands before we've actually been
  // embedded into the view and content_ created.
  // Just save the last one.
  if (content_) {
    scoped_ptr<mojo::ServiceProviderImpl> exported_services(
      new mojo::ServiceProviderImpl());
    exported_services->AddService(&navigator_host_factory_);
    viewer_services_ = content_->Embed(url, exported_services.Pass());
  } else {
    pending_url_ = url;
  }
}

void SkyDebugger::Shutdown() {
  // Make sure we shut down mojo before quitting the message loop or things
  // like blink::shutdown() may try to talk to the message loop and crash.
  window_manager_app_.reset();

  // TODO(eseidel): This still hits an X11 error which I don't understand
  // "X Error of failed request:  GLXBadDrawable", crbug.com/430581
  mojo::ApplicationImpl::Terminate();
  // TODO(eseidel): REMOVE THIS, temporarily fast-exit now to stop confusing
  // folks with exit-time crashes due to GLXBadDrawable above.
  exit(0);
}

void SkyDebugger::InjectInspector() {
  InspectorServicePtr inspector_service;
  mojo::ConnectToService(viewer_services_.get(), &inspector_service);
  inspector_service->Inject();
}

}  // namespace debugger
}  // namespace sky
