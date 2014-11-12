// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/tools/debugger/debugger.h"

#include "mojo/services/window_manager/basic_focus_rules.h"

namespace sky {
namespace debugger {

SkyDebugger::SkyDebugger()
    : window_manager_app_(new mojo::WindowManagerApp(this, nullptr)),
      view_manager_(nullptr),
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
    mojo::ViewManager* view_manager,
    mojo::View* root,
    mojo::ServiceProviderImpl* exported_services,
    scoped_ptr<mojo::ServiceProvider> imported_services) {
  view_manager_ = view_manager;

  root_ = root;
  root_->AddObserver(this);

  window_manager_app_->SetViewportSize(gfx::Size(320, 640));

  content_ = mojo::View::Create(view_manager_);
  content_->SetBounds(root_->bounds());
  root_->AddChild(content_);

  window_manager_app_->InitFocus(scoped_ptr<mojo::FocusRules>(
      new mojo::BasicFocusRules(window_manager_app_.get(), content_)));

  if (!pending_url_.empty())
    NavigateToURL(pending_url_);
}

void SkyDebugger::OnViewManagerDisconnected(mojo::ViewManager* view_manager) {
  view_manager_ = nullptr;
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

void SkyDebugger::OnViewInputEvent(
    mojo::View* view, const mojo::EventPtr& event) {
  if (view != root_)
    return;
  // Currently, the event targeting system is broken for mojo::Views, so we
  // blindly forward events from the root to the content view. Once event
  // targeting works, we should be able to rip out this code.
  window_manager_app_->DispatchInputEventToView(content_, event.Clone());
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
