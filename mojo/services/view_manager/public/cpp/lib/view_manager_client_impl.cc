// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "view_manager/public/cpp/lib/view_manager_client_impl.h"

#include "mojo/public/cpp/application/application_impl.h"
#include "mojo/public/cpp/application/connect.h"
#include "mojo/public/cpp/application/service_provider_impl.h"
#include "mojo/public/interfaces/application/service_provider.mojom.h"
#include "mojo/public/interfaces/application/shell.mojom.h"
#include "view_manager/public/cpp/lib/view_private.h"
#include "view_manager/public/cpp/util.h"
#include "view_manager/public/cpp/view_manager_delegate.h"
#include "view_manager/public/cpp/view_observer.h"

namespace mojo {

Id MakeTransportId(ConnectionSpecificId connection_id,
                   ConnectionSpecificId local_id) {
  return (connection_id << 16) | local_id;
}

// Helper called to construct a local view object from transport data.
View* AddViewToViewManager(ViewManagerClientImpl* client,
                           View* parent,
                           const ViewDataPtr& view_data) {
  // We don't use the ctor that takes a ViewManager here, since it will call
  // back to the service and attempt to create a new view.
  View* view = ViewPrivate::LocalCreate();
  ViewPrivate private_view(view);
  private_view.set_view_manager(client);
  private_view.set_id(view_data->view_id);
  private_view.set_visible(view_data->visible);
  private_view.set_drawn(view_data->drawn);
  private_view.LocalSetViewportMetrics(ViewportMetrics(),
                                       *view_data->viewport_metrics);
  private_view.set_properties(
      view_data->properties.To<std::map<std::string, std::vector<uint8_t>>>());
  client->AddView(view);
  private_view.LocalSetBounds(Rect(), *view_data->bounds);
  if (parent)
    ViewPrivate(parent).LocalAddChild(view);
  return view;
}

View* BuildViewTree(ViewManagerClientImpl* client,
                    const Array<ViewDataPtr>& views,
                    View* initial_parent) {
  std::vector<View*> parents;
  View* root = NULL;
  View* last_view = NULL;
  if (initial_parent)
    parents.push_back(initial_parent);
  for (size_t i = 0; i < views.size(); ++i) {
    if (last_view && views[i]->parent_id == last_view->id()) {
      parents.push_back(last_view);
    } else if (!parents.empty()) {
      while (parents.back()->id() != views[i]->parent_id)
        parents.pop_back();
    }
    View* view = AddViewToViewManager(
        client, !parents.empty() ? parents.back() : NULL, views[i]);
    if (!last_view)
      root = view;
    last_view = view;
  }
  return root;
}

// Responsible for removing a root from the ViewManager when that view is
// destroyed.
class RootObserver : public ViewObserver {
 public:
  explicit RootObserver(View* root) : root_(root) {}
  ~RootObserver() override {}

 private:
  // Overridden from ViewObserver:
  void OnViewDestroyed(View* view) override {
    DCHECK_EQ(view, root_);
    static_cast<ViewManagerClientImpl*>(root_->view_manager())
        ->RootDestroyed(root_);
    view->RemoveObserver(this);
    delete this;
  }

  View* root_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(RootObserver);
};

ViewManagerClientImpl::ViewManagerClientImpl(
    ViewManagerDelegate* delegate,
    Shell* shell,
    InterfaceRequest<ViewManagerClient> request,
    bool delete_on_error)
    : connection_id_(0),
      next_id_(1),
      delegate_(delegate),
      root_(nullptr),
      capture_view_(nullptr),
      focused_view_(nullptr),
      activated_view_(nullptr),
      wm_observer_binding_(this),
      binding_(this, request.Pass()) {
  if (delete_on_error)
    binding_.set_connection_error_handler([this]() { delete this; });
}

ViewManagerClientImpl::~ViewManagerClientImpl() {
  std::vector<View*> non_owned;
  while (!views_.empty()) {
    IdToViewMap::iterator it = views_.begin();
    if (OwnsView(it->second->id())) {
      it->second->Destroy();
    } else {
      non_owned.push_back(it->second);
      views_.erase(it);
    }
  }
  // Delete the non-owned views last. In the typical case these are roots. The
  // exception is the window manager, which may know aboutother random views
  // that it doesn't own.
  // NOTE: we manually delete as we're a friend.
  for (size_t i = 0; i < non_owned.size(); ++i)
    delete non_owned[i];

  delegate_->OnViewManagerDisconnected(this);
}

void ViewManagerClientImpl::DestroyView(Id view_id) {
  DCHECK(service_);
  service_->DeleteView(view_id, ActionCompletedCallback());
}

void ViewManagerClientImpl::AddChild(Id child_id, Id parent_id) {
  DCHECK(service_);
  service_->AddView(parent_id, child_id, ActionCompletedCallback());
}

void ViewManagerClientImpl::RemoveChild(Id child_id, Id parent_id) {
  DCHECK(service_);
  service_->RemoveViewFromParent(child_id, ActionCompletedCallback());
}

void ViewManagerClientImpl::Reorder(
    Id view_id,
    Id relative_view_id,
    OrderDirection direction) {
  DCHECK(service_);
  service_->ReorderView(view_id, relative_view_id, direction,
                        ActionCompletedCallback());
}

bool ViewManagerClientImpl::OwnsView(Id id) const {
  return HiWord(id) == connection_id_;
}

void ViewManagerClientImpl::SetBounds(Id view_id, const Rect& bounds) {
  DCHECK(service_);
  service_->SetViewBounds(view_id, bounds.Clone(), ActionCompletedCallback());
}

void ViewManagerClientImpl::SetSurfaceId(Id view_id, SurfaceIdPtr surface_id) {
  DCHECK(service_);
  if (surface_id.is_null())
    return;
  service_->SetViewSurfaceId(
      view_id, surface_id.Pass(), ActionCompletedCallback());
}

void ViewManagerClientImpl::SetFocus(Id view_id) {
  // In order for us to get here we had to have exposed a view, which implies we
  // got a connection.
  DCHECK(service_);
  service_->PerformAction(view_id, "focus", ActionCompletedCallback());
}

void ViewManagerClientImpl::SetVisible(Id view_id, bool visible) {
  DCHECK(service_);
  service_->SetViewVisibility(view_id, visible, ActionCompletedCallback());
}

void ViewManagerClientImpl::SetProperty(
    Id view_id,
    const std::string& name,
    const std::vector<uint8_t>& data) {
  DCHECK(service_);
  service_->SetViewProperty(view_id,
                            String(name),
                            Array<uint8_t>::From(data),
                            ActionCompletedCallback());
}

void ViewManagerClientImpl::Embed(const String& url, Id view_id) {
  Embed(url, view_id, nullptr, nullptr);
}

void ViewManagerClientImpl::Embed(const String& url,
                                  Id view_id,
                                  InterfaceRequest<ServiceProvider> services,
                                  ServiceProviderPtr exposed_services) {
  DCHECK(service_);
  service_->EmbedUrl(url, view_id, services.Pass(), exposed_services.Pass(),
                     ActionCompletedCallback());
}

void ViewManagerClientImpl::Embed(Id view_id, ViewManagerClientPtr client) {
  DCHECK(service_);
  service_->Embed(view_id, client.Pass(), ActionCompletedCallback());
}

void ViewManagerClientImpl::AddView(View* view) {
  DCHECK(views_.find(view->id()) == views_.end());
  views_[view->id()] = view;
}

void ViewManagerClientImpl::RemoveView(Id view_id) {
  if (focused_view_ && focused_view_->id() == view_id)
    OnFocusChanged(0);
  if (capture_view_ && capture_view_->id() == view_id)
    OnCaptureChanged(0);
  if (activated_view_ && activated_view_->id() == view_id)
    OnActiveWindowChanged(0);

  IdToViewMap::iterator it = views_.find(view_id);
  if (it != views_.end())
    views_.erase(it);
}

void ViewManagerClientImpl::SetViewManagerService(
    ViewManagerServicePtr service) {
  DCHECK(!service_);
  DCHECK(service);
  service_ = service.Pass();
}
////////////////////////////////////////////////////////////////////////////////
// ViewManagerClientImpl, ViewManager implementation:

Id ViewManagerClientImpl::CreateViewOnServer() {
  DCHECK(service_);
  const Id view_id = MakeTransportId(connection_id_, ++next_id_);
  service_->CreateView(view_id, [this](ErrorCode code) {
    OnActionCompleted(code == ERROR_CODE_NONE);
  });
  return view_id;
}

const std::string& ViewManagerClientImpl::GetEmbedderURL() const {
  return creator_url_;
}

View* ViewManagerClientImpl::GetRoot() {
  return root_;
}

View* ViewManagerClientImpl::GetViewById(Id id) {
  IdToViewMap::const_iterator it = views_.find(id);
  return it != views_.end() ? it->second : NULL;
}

View* ViewManagerClientImpl::GetFocusedView() {
  return focused_view_;
}

View* ViewManagerClientImpl::CreateView() {
  View* view = new View(this, CreateViewOnServer());
  AddView(view);
  return view;
}

////////////////////////////////////////////////////////////////////////////////
// ViewManagerClientImpl, ViewManagerClient implementation:

void ViewManagerClientImpl::OnEmbed(
    ConnectionSpecificId connection_id,
    const String& creator_url,
    ViewDataPtr root_data,
    ViewManagerServicePtr view_manager_service,
    InterfaceRequest<ServiceProvider> services,
    ServiceProviderPtr exposed_services,
    ScopedMessagePipeHandle window_manager_pipe) {
  if (view_manager_service) {
    DCHECK(!service_);
    service_ = view_manager_service.Pass();
  }
  connection_id_ = connection_id;
  creator_url_ = String::From(creator_url);

  DCHECK(!root_);
  root_ = AddViewToViewManager(this, nullptr, root_data);
  root_->AddObserver(new RootObserver(root_));

  window_manager_.Bind(
      InterfacePtrInfo<WindowManager>(window_manager_pipe.Pass(), 0u));
  WindowManagerObserverPtr observer;
  wm_observer_binding_.Bind(GetProxy(&observer));
  // binding to |this| is safe here as |window_manager_| is bound to our
  // lifetime.
  window_manager_->GetFocusedAndActiveViews(
      observer.Pass(),
      [this](uint32_t capture_view_id, uint32_t focused_view_id,
             uint32_t active_view_id) {
        if (GetViewById(capture_view_id) != capture_view_)
          OnCaptureChanged(capture_view_id);
        if (GetViewById(focused_view_id) != focused_view_)
          OnFocusChanged(focused_view_id);
        if (GetViewById(active_view_id) != activated_view_)
          OnActiveWindowChanged(active_view_id);
      });

  delegate_->OnEmbed(root_, services.Pass(), exposed_services.Pass());
}

void ViewManagerClientImpl::OnEmbeddedAppDisconnected(Id view_id) {
  View* view = GetViewById(view_id);
  if (view) {
    FOR_EACH_OBSERVER(ViewObserver, *ViewPrivate(view).observers(),
                      OnViewEmbeddedAppDisconnected(view));
  }
}

void ViewManagerClientImpl::OnViewBoundsChanged(Id view_id,
                                                RectPtr old_bounds,
                                                RectPtr new_bounds) {
  View* view = GetViewById(view_id);
  ViewPrivate(view).LocalSetBounds(*old_bounds, *new_bounds);
}

namespace {

void SetViewportMetricsOnDecendants(View* root,
                                    const ViewportMetrics& old_metrics,
                                    const ViewportMetrics& new_metrics) {
  ViewPrivate(root).LocalSetViewportMetrics(old_metrics, new_metrics);
  const View::Children& children = root->children();
  for (size_t i = 0; i < children.size(); ++i)
    SetViewportMetricsOnDecendants(children[i], old_metrics, new_metrics);
}
}

void ViewManagerClientImpl::OnViewViewportMetricsChanged(
    ViewportMetricsPtr old_metrics,
    ViewportMetricsPtr new_metrics) {
  View* view = GetRoot();
  if (view)
    SetViewportMetricsOnDecendants(view, *old_metrics, *new_metrics);
}

void ViewManagerClientImpl::OnViewHierarchyChanged(
    Id view_id,
    Id new_parent_id,
    Id old_parent_id,
    mojo::Array<ViewDataPtr> views) {
  View* initial_parent = views.size() ?
      GetViewById(views[0]->parent_id) : NULL;

  BuildViewTree(this, views, initial_parent);

  View* new_parent = GetViewById(new_parent_id);
  View* old_parent = GetViewById(old_parent_id);
  View* view = GetViewById(view_id);
  if (new_parent)
    ViewPrivate(new_parent).LocalAddChild(view);
  else
    ViewPrivate(old_parent).LocalRemoveChild(view);
}

void ViewManagerClientImpl::OnViewReordered(Id view_id,
                                            Id relative_view_id,
                                            OrderDirection direction) {
  View* view = GetViewById(view_id);
  View* relative_view = GetViewById(relative_view_id);
  if (view && relative_view)
    ViewPrivate(view).LocalReorder(relative_view, direction);
}

void ViewManagerClientImpl::OnViewDeleted(Id view_id) {
  View* view = GetViewById(view_id);
  if (view)
    ViewPrivate(view).LocalDestroy();
}

void ViewManagerClientImpl::OnViewVisibilityChanged(Id view_id, bool visible) {
  // TODO(sky): there is a race condition here. If this client and another
  // client change the visibility at the same time the wrong value may be set.
  // Deal with this some how.
  View* view = GetViewById(view_id);
  if (view)
    ViewPrivate(view).LocalSetVisible(visible);
}

void ViewManagerClientImpl::OnViewDrawnStateChanged(Id view_id, bool drawn) {
  View* view = GetViewById(view_id);
  if (view)
    ViewPrivate(view).LocalSetDrawn(drawn);
}

void ViewManagerClientImpl::OnViewSharedPropertyChanged(
    Id view_id,
    const String& name,
    Array<uint8_t> new_data) {
  View* view = GetViewById(view_id);
  if (view) {
    std::vector<uint8_t> data;
    std::vector<uint8_t>* data_ptr = NULL;
    if (!new_data.is_null()) {
      data = new_data.To<std::vector<uint8_t>>();
      data_ptr = &data;
    }

    view->SetSharedProperty(name, data_ptr);
  }
}

void ViewManagerClientImpl::OnViewInputEvent(
    Id view_id,
    EventPtr event,
    const Callback<void()>& ack_callback) {
  View* view = GetViewById(view_id);
  if (view) {
    FOR_EACH_OBSERVER(ViewObserver,
                      *ViewPrivate(view).observers(),
                      OnViewInputEvent(view, event));
  }
  ack_callback.Run();
}

void ViewManagerClientImpl::OnPerformAction(
    Id view_id,
    const String& name,
    const Callback<void(bool)>& callback) {
  View* view = GetViewById(view_id);
  callback.Run(delegate_->OnPerformAction(view, name));
}

////////////////////////////////////////////////////////////////////////////////
// ViewManagerClientImpl, WindowManagerObserver implementation:

void ViewManagerClientImpl::OnCaptureChanged(Id capture_view_id) {
  View* gained_capture = GetViewById(capture_view_id);
  View* lost_capture = capture_view_;
  if (lost_capture) {
    FOR_EACH_OBSERVER(ViewObserver,
                      *ViewPrivate(lost_capture).observers(),
                      OnViewFocusChanged(gained_capture, lost_capture));
  }
  capture_view_ = gained_capture;
  if (gained_capture) {
    FOR_EACH_OBSERVER(ViewObserver,
                      *ViewPrivate(gained_capture).observers(),
                      OnViewFocusChanged(gained_capture, lost_capture));
  }
}

void ViewManagerClientImpl::OnFocusChanged(Id focused_view_id) {
  View* focused = GetViewById(focused_view_id);
  View* blurred = focused_view_;
  if (blurred) {
    FOR_EACH_OBSERVER(ViewObserver,
                      *ViewPrivate(blurred).observers(),
                      OnViewFocusChanged(focused, blurred));
  }
  focused_view_ = focused;
  if (focused) {
    FOR_EACH_OBSERVER(ViewObserver,
                      *ViewPrivate(focused).observers(),
                      OnViewFocusChanged(focused, blurred));
  }
}

void ViewManagerClientImpl::OnActiveWindowChanged(Id active_view_id) {
  View* activated = GetViewById(active_view_id);
  View* deactivated = activated_view_;
  if (deactivated) {
    FOR_EACH_OBSERVER(ViewObserver,
                      *ViewPrivate(deactivated).observers(),
                      OnViewActivationChanged(activated, deactivated));
  }
  activated_view_ = activated;
  if (activated) {
    FOR_EACH_OBSERVER(ViewObserver,
                      *ViewPrivate(activated).observers(),
                      OnViewActivationChanged(activated, deactivated));
  }
}

////////////////////////////////////////////////////////////////////////////////
// ViewManagerClientImpl, private:

void ViewManagerClientImpl::RootDestroyed(View* root) {
  DCHECK_EQ(root, root_);
  root_ = nullptr;
}

void ViewManagerClientImpl::OnActionCompleted(bool success) {
  if (!change_acked_callback_.is_null())
    change_acked_callback_.Run();
}

Callback<void(bool)> ViewManagerClientImpl::ActionCompletedCallback() {
  return [this](bool success) { OnActionCompleted(success); };
}

}  // namespace mojo
